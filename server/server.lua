local activeCrafting = {}

-- Register a callback for crafting attempts
BCCCallbacks.Register('bcc-crafting:attemptCraft', function(source, cb, item)
    local Character = VORPcore.getUser(source).getUsedCharacter
    local playerId = Character.charIdentifier
    local playerJob = Character.job
    local jobGrade = Character.jobGrade

    local inputAmount = item.itemAmount or 1 -- Input amount from the player, default to 1 if not provided
    local itemConfigAmount = getConfigItemAmount(item.itemName) * inputAmount

    -- Check job requirements
    if item.requiredJobs and #item.requiredJobs > 0 then
        devPrint("Checking job requirements for: " .. item.itemLabel)
        local hasValidJob = false
        for _, allowedJob in pairs(item.requiredJobs) do
            devPrint("Allowed job: " .. allowedJob.name .. ", Grade required: " .. allowedJob.grade)
            devPrint("Player job: " .. playerJob .. ", Player job grade: " .. jobGrade)

            if playerJob == allowedJob.name and jobGrade >= allowedJob.grade then
                hasValidJob = true
                devPrint("Player meets the job requirements for: " .. allowedJob.name)
                break
            end
        end

        if not hasValidJob then
            devPrint("Player does not meet the job requirements for: " .. item.itemLabel)
            VORPcore.NotifyObjective(source, _U('InvalidJobForCrafting') .. item.itemLabel, 4000)
            cb(false)
            return
        end
    else
        devPrint("No job requirements for: " .. item.itemLabel)
    end

    -- Check if player has required items
    local hasItems = true
    for _, reqItem in pairs(item.requiredItems) do
        devPrint(_U('CheckingRequiredItem') .. reqItem.itemName)
        local requiredItemCount = reqItem.itemCount
        local count = exports.vorp_inventory:getItemCount(source, nil, reqItem.itemName)
        devPrint(_U('PlayerHas') .. count .. _U('Of') .. reqItem.itemName .. _U('Requires') .. requiredItemCount .. ")")

        if count < requiredItemCount then
            hasItems = false
            devPrint(_U('MissingItem') .. reqItem.itemName)
            break
        end
    end

    if not hasItems then
        VORPcore.NotifyRightTip(source, _U('MissingMaterials') .. item.itemLabel .. ".", 4000)
        cb(false)
        return
    end

    -- Check player's crafting level
    GetPlayerCraftingData(playerId, function(xp, level)
        if level < item.requiredLevel then
            VORPcore.NotifyRightTip(source, _U('RequiredLevel') .. item.requiredLevel .. ".", 4000)
            cb(false)
            return
        end

        local totalDuration = item.duration * inputAmount
        local isWeapon = string.find(item.itemName, "^WEAPON_")
        if isWeapon then
            -- Retrieve the player's weapon inventory and limit the weapon count
            exports.vorp_inventory:getUserInventoryWeapons(source, function(weapons)
                local currentWeaponCount = #weapons
                local maxWeaponsAllowed = 5 -- Adjust this based on your server's maximum allowed weapon count
            end)
        else
            -- Regular item limit check for non-weapon items
            local itemDBData = exports.vorp_inventory:getItemDB(item.itemName)
            local itemLimit = itemDBData and itemDBData.limit
            devPrint("[DEBUG] Non-weapon item: " ..
                tostring(item.itemName) ..
                " - Item limit: " .. tostring(itemLimit) .. ", Requested amount: " .. tostring(itemConfigAmount))
            if itemLimit and itemConfigAmount > itemLimit then
                VORPcore.NotifyRightTip(source, _U('CannotCraftOverLimit') .. item.itemLabel, 4000)
                cb(false)
                return
            end
        end
        -- Remove required items from inventory
        for _, reqItem in pairs(item.requiredItems) do
            if reqItem.removeItem then
                local requiredItemCount = reqItem.itemCount * inputAmount
                devPrint("[DEBUG] Attempting to remove item:" .. reqItem.itemName)
                local subItem = exports.vorp_inventory:subItem(source, reqItem.itemName, requiredItemCount,
                    reqItem.metadata or {})
                if not subItem then
                    devPrint("[ERROR] Failed to remove item:" .. reqItem.itemName .. "Required:" .. inputAmount)
                    VORPcore.NotifyRightTip(source, _U('RemoveItemFailed', reqItem.itemLabel), 4000)
                    cb(false)
                    return
                else
                    devPrint("[DEBUG] Successfully removed item:" ..
                        reqItem.itemName .. " | Amount removed:" .. requiredItemCount)
                end
            else
                devPrint("[DEBUG] Item not removed as 'removeItem' is set to false for item:" .. reqItem.itemLabel)
                devPrint("Item not removed as 'removeItem' is false: " .. reqItem.itemLabel)
            end
        end

        -- Prepare data for database insertion
        local craftingData = {
            ['charidentifier'] = playerId,
            ['itemName'] = item.itemName,
            ['itemLabel'] = item.itemLabel,
            ['itemAmount'] = itemConfigAmount, -- Use the calculated amount
            ['requiredItems'] = json.encode(item.requiredItems),
            ['status'] = 'in_progress',
            ['duration'] = totalDuration,
            ['rewardXP'] = item.rewardXP,
            ['timestamp'] = os.time()
        }

        -- Insert crafting attempt into database
        MySQL.insert(
            'INSERT INTO bcc_crafting_log (charidentifier, itemName, itemLabel, itemAmount, requiredItems, status, duration, rewardXP, timestamp) VALUES (@charidentifier, @itemName, @itemLabel, @itemAmount, @requiredItems, @status, @duration, @rewardXP, @timestamp)',
            craftingData, function(insertId)
                if insertId then
                    item.craftingId = insertId
                    activeCrafting[source] = {
                        item = item,
                        startTime = os.time(),
                        duration = totalDuration
                    }
                    TriggerClientEvent('bcc-crafting:startCrafting', source, item)
                    Discord:sendMessage("Player ID: " ..
                        tostring(source) ..
                        " started crafting " ..
                        tostring(item.itemLabel) ..
                        ". Amount: " ..
                        tostring(itemConfigAmount) .. ". Total Duration: " .. tostring(totalDuration) .. "s")
                    cb(true)
                else
                    VORPcore.NotifyRightTip(source, _U('CraftingAttemptFailed'), 4000)
                    cb(false)
                end
            end)
    end)
end)

-- Server-side function to retrieve ongoing crafting items and remaining times
RegisterNetEvent('bcc-crafting:getOngoingCrafting')
AddEventHandler('bcc-crafting:getOngoingCrafting', function()
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local charIdentifier = Character.charIdentifier -- Unique character identifier
    MySQL.query("SELECT * FROM bcc_crafting_log WHERE charidentifier = @charidentifier AND status = 'in_progress'",
        { ['@charidentifier'] = charIdentifier }, function(result)
            local ongoingCraftingList = {}
            if result and #result > 0 then
                for _, craftingLog in ipairs(result) do
                    local startTime = craftingLog.timestamp
                    local currentTime = os.time()
                    local elapsedTime = currentTime - startTime
                    local remainingTime = craftingLog.duration - elapsedTime
                    if remainingTime <= 0 then
                        MySQL.update.await(
                            "UPDATE bcc_crafting_log SET status = 'completed', completed_at = NOW() WHERE id = @id",
                            { ['@id'] = craftingLog.id })
                        remainingTime = 0
                    end
                    table.insert(ongoingCraftingList, { craftingLog = craftingLog, remainingTime = remainingTime })
                end
            end
            TriggerClientEvent('bcc-crafting:sendOngoingCraftingList', _source, ongoingCraftingList)
        end)
end)

-- Server-side function to retrieve completed crafting items
RegisterNetEvent('bcc-crafting:getCompletedCrafting')
AddEventHandler('bcc-crafting:getCompletedCrafting', function()
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local charIdentifier = Character.charIdentifier -- Character identifier

    MySQL.query("SELECT * FROM bcc_crafting_log WHERE charidentifier = @charidentifier AND status = 'completed'",
        { ['@charidentifier'] = charIdentifier }, function(completedResult)
            if completedResult then
                local resultLength = 0
                for k, v in pairs(completedResult) do
                    resultLength = resultLength + 1
                end
                if resultLength > 0 then
                    -- Send the completed crafting list to the client
                    TriggerClientEvent('bcc-crafting:sendCompletedCraftingList', _source, completedResult)
                else
                    devPrint("completedResult length is not greater than 0")
                end
            else
                --devPrint("completedResult is nil")
                devPrint(_U('NoCompletedCrafting') .. charIdentifier)
            end
        end)
end)

-- Register the callback for collecting crafted items
BCCCallbacks.Register('bcc-crafting:collectCraftedItem', function(source, cb, craftingLog)
    -- Get Character Information
    local Character = VORPcore.getUser(source).getUsedCharacter
    local playerId = Character.charIdentifier
    local firstname = Character.firstname
    local lastname = Character.lastname

    -- Validate craftingLog and itemName
    if not craftingLog or not craftingLog.itemName then
        devPrint("[ERROR] craftingLog or itemName is missing.")
        cb(false)
        return
    end

    -- Basic item details
    local itemName = craftingLog.itemName
    local itemLabel = craftingLog.itemLabel
    local rewardXP = craftingLog.rewardXP
    local amountToAdd = craftingLog.itemAmount

    -- Determine if the crafted item is a weapon
    local isWeapon = string.sub(itemName:lower(), 1, string.len("weapon_")) == "weapon_"
    devPrint("[DEBUG] Item name:" .. itemName .. " Is weapon:" .. tostring(isWeapon))

    if isWeapon then
        -- Retrieve the player's weapon inventory and limit the weapon count
        exports.vorp_inventory:getUserInventoryWeapons(source, function(weapons)
            local currentWeaponCount = #weapons

            if currentWeaponCount >= Config.maxWeaponsAllowed then
                VORPcore.NotifyRightTip(source, _U('CannotCarryMoreWeapons'), 4000)
                cb(false)
                return
            end

            -- Add weapon to inventory
            local weaponAdded = exports.vorp_inventory:createWeapon(source, itemName, {})
            if weaponAdded then
                MySQL.execute('DELETE FROM bcc_crafting_log WHERE id = @id', { ['@id'] = craftingLog.id })
                VORPcore.NotifyRightTip(source, _U('CollectedWeapon') .. itemLabel, 4000)

                -- Award XP for crafting a weapon
                local totalXP = rewardXP
                AddPlayerCraftingXP(playerId, totalXP, function(newLevel)
                    if newLevel then
                        TriggerClientEvent('bcc-crafting:levelUp', source, newLevel)
                    end
                end)

                -- Send a message to Discord
                local discordMessage = string.format(
                    "**Crafting Completion**\n\n" ..
                    "**Player:** %s %s (ID: %s)\n" ..
                    "**Crafted Weapon:** %s\n" ..
                    "**XP Gained:** %d XP\n" ..
                    "**Weapon Collected Successfully**",
                    firstname, lastname, playerId, itemLabel, totalXP
                )
                Discord:sendMessage(discordMessage)
                cb(true)
            else
                VORPcore.NotifyRightTip(source, _U('FailedToAddWeapon'), 4000)
                cb(false)
            end
        end)
        return
    else
        -- Handle regular items
        local itemData = exports.vorp_inventory:getItemDB(itemName)
        devPrint("[ERROR] Item name: " .. itemName)
        if not itemData then
            devPrint("[ERROR] Item data not found: " .. itemName)
            VORPcore.NotifyRightTip(source, "Item data not found for item: " .. itemLabel, 4000)
            cb(false)
            return
        end

        -- Calculate available space using the new function
        local availableSpace = getAvailableSpace(source, itemName)
        local addableAmount = math.min(amountToAdd, availableSpace)
        local remainingAmount = amountToAdd - addableAmount

        -- Check if the player can carry the full addableAmount
        local canCarry = exports.vorp_inventory:canCarryItem(source, itemName, addableAmount)
        if canCarry and addableAmount > 0 then
            -- Player can carry the full amount, proceed to add it
            local addItemResult = exports.vorp_inventory:addItem(source, itemName, addableAmount, {})
            if addItemResult then
                -- Update or delete crafting log based on remaining amount
                if remainingAmount > 0 then
                    MySQL.execute('UPDATE bcc_crafting_log SET itemAmount = @remainingAmount WHERE id = @id', {
                        ['@remainingAmount'] = remainingAmount,
                        ['@id'] = craftingLog.id
                    })
                    devPrint("[DEBUG] Updated crafting log with remaining amount: " .. remainingAmount)
                    VORPcore.NotifyRightTip(source, _U('CollectedPartially') .. addableAmount .. "x " .. itemLabel .. ".", 4000)
                else
                    MySQL.execute('DELETE FROM bcc_crafting_log WHERE id = @id', { ['@id'] = craftingLog.id })
                    devPrint("[DEBUG] Crafting log entry deleted for item: " .. itemName)
                    VORPcore.NotifyRightTip(source, _U('CollectedCraftedItem') .. addableAmount .. "x " .. itemLabel .. ".", 4000)
                end

                -- Award XP for crafting items
                local totalXP = rewardXP * addableAmount
                AddPlayerCraftingXP(playerId, totalXP, function(newLevel)
                    if newLevel then
                        devPrint("[DEBUG] Player leveled up to: " .. newLevel)
                        TriggerClientEvent('bcc-crafting:levelUp', source, newLevel)
                    end
                end)

                -- Send a message to Discord
                local discordMessage = string.format(
                    "**Crafting Completion**\n\n" ..
                    "**Player:** %s %s (ID: %s)\n" ..
                    "**Crafted Item:** %s x%d\n" ..
                    "**XP Gained:** %d XP\n" ..
                    "**Item Collected Successfully**",
                    firstname, lastname, playerId, itemLabel, addableAmount, totalXP
                )
                Discord:sendMessage(discordMessage)
                cb(true)
            else
                devPrint("[ERROR] Failed to add crafted item to inventory: " .. itemName)
                VORPcore.NotifyRightTip(source, _U('FailedToAddItem'), 4000)
                cb(false)
            end
        else
            -- Player cannot carry the full amount, find a partial amount that fits
            local partialAmount = addableAmount
            local foundCarryableAmount = false

            -- Loop to decrease amount until we find one that can be carried
            while partialAmount > 0 and not foundCarryableAmount do
                local canCarryPartial = exports.vorp_inventory:canCarryItem(source, itemName, partialAmount)
                if canCarryPartial then
                    foundCarryableAmount = true
                else
                    partialAmount = partialAmount - 1
                end
            end

            if partialAmount > 0 then
                -- Proceed to add the partial amount
                local addItemResult = exports.vorp_inventory:addItem(source, itemName, partialAmount, {})
                if addItemResult then
                    -- Update crafting log with remaining amount if some items were left
                    local remainingAmount = amountToAdd - partialAmount
                    if remainingAmount > 0 then
                        MySQL.execute('UPDATE bcc_crafting_log SET itemAmount = @remainingAmount WHERE id = @id', {
                            ['@remainingAmount'] = remainingAmount,
                            ['@id'] = craftingLog.id
                        })
                        devPrint("[DEBUG] Updated crafting log with remaining amount: " .. remainingAmount)
                        VORPcore.NotifyRightTip(source, _U('CollectedPartially') .. partialAmount .. "x " .. itemLabel .. ".", 4000)
                    else
                        MySQL.execute('DELETE FROM bcc_crafting_log WHERE id = @id', { ['@id'] = craftingLog.id })
                        devPrint("[DEBUG] Crafting log entry deleted for item: " .. itemName)
                        VORPcore.NotifyRightTip(source, _U('CollectedCraftedItem') .. partialAmount .. "x " .. itemLabel .. ".", 4000)
                    end

                    -- Award XP for crafting items
                    local totalXP = rewardXP * partialAmount
                    AddPlayerCraftingXP(playerId, totalXP, function(newLevel)
                        if newLevel then
                            devPrint("[DEBUG] Player leveled up to: " .. newLevel)
                            TriggerClientEvent('bcc-crafting:levelUp', source, newLevel)
                        end
                    end)

                    -- Send a message to Discord
                    local discordMessage = string.format(
                        "**Crafting Completion**\n\n" ..
                        "**Player:** %s %s (ID: %s)\n" ..
                        "**Crafted Item:** %s x%d\n" ..
                        "**XP Gained:** %d XP\n" ..
                        "**Item Collected Successfully**",
                        firstname, lastname, playerId, itemLabel, partialAmount, totalXP
                    )
                    Discord:sendMessage(discordMessage)
                    cb(true)
                else
                    devPrint("[ERROR] Failed to add crafted item to inventory: " .. itemName)
                    VORPcore.NotifyRightTip(source, _U('FailedToAddItem'), 4000)
                    cb(false)
                end
            else
                -- No space available even for a partial amount
                VORPcore.NotifyRightTip(source, _U('NotEnoughSpace') .. amountToAdd .. "x " .. itemLabel .. ".", 4000)
                cb(false)
            end
        end
    end
end)

-- Function to get available space for an item in player's inventory
function getAvailableSpace(source, itemName)
    -- Fetch item data from the inventory database
    local itemData = exports.vorp_inventory:getItemDB(itemName)
    if not itemData then
        devPrint("[ERROR] Item data not found for item: " .. itemName)
        return 0 -- No space available if item data doesn't exist
    end

    -- Calculate available space based on item limit and current count
    local itemLimit = itemData.limit
    local currentCount = exports.vorp_inventory:getItemCount(source, nil, itemName)
    local spaceAvailable = math.max(itemLimit - currentCount, 0)

    return spaceAvailable
end

RegisterNetEvent('bcc-crafting:requestCraftingData')
AddEventHandler('bcc-crafting:requestCraftingData', function(categories)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local playerId = Character.charIdentifier

    GetPlayerCraftingData(playerId, function(xp, level)
        -- Calculate required XP for the next level based on the level range in Config
        local requiredXPForNextLevel = 0
        for _, threshold in ipairs(Config.LevelThresholds) do
            if level >= threshold.minLevel and level <= threshold.maxLevel then
                requiredXPForNextLevel = (level - threshold.minLevel + 1) * threshold.xpPerLevel
                break
            end
        end

        local xpToNextLevel = requiredXPForNextLevel - xp

        -- Send data to the client
        TriggerClientEvent('bcc-crafting:sendCraftingData', _source, level, xpToNextLevel, categories)
    end)
end)

-- Function to update player's XP and level incrementally
function AddPlayerCraftingXP(playerId, amount, callback)
    devPrint("Adding XP for player:" .. playerId .. "Amount:" .. amount)

    GetPlayerCraftingData(playerId, function(xp, lastLevel)
        devPrint("Current XP:", xp, "Last Level:" .. lastLevel)

        xp = xp + amount
        local newLevel, remainingXP = CalculateIncrementalLevel(xp, lastLevel)

        devPrint("New XP after addition:" .. xp)
        devPrint("Calculated New Level:" .. newLevel)
        devPrint("Remaining XP after leveling:" .. remainingXP)

        local param = {
            ['charidentifier'] = playerId,
            ['currentXP'] = remainingXP, -- Store remaining XP
            ['currentLevel'] = newLevel,
            ['lastLevel'] = newLevel
        }

        -- Update the database with the new remaining XP and level
        MySQL.execute(
            'UPDATE bcc_craft_progress SET currentXP = @currentXP, currentLevel = @currentLevel, lastLevel = @lastLevel WHERE charidentifier = @charidentifier',
            param, function(rowsAffected)
                devPrint("Database Update Result:" .. json.encode(rowsAffected) .. "rows affected")
            end)

        -- Notify callback only if there is a level increase
        if newLevel > lastLevel then
            devPrint("Level increased! New Level:", newLevel)
            callback(newLevel)
        else
            devPrint("No level increase.")
            callback(nil)
        end
    end)
end

-- Function to get player crafting data (XP and level)
function GetPlayerCraftingData(playerId, callback)
    local param = { ['charidentifier'] = playerId }
    MySQL.query('SELECT currentXP, currentLevel FROM bcc_craft_progress WHERE charidentifier = @charidentifier', param,
        function(result)
            if #result > 0 then
                local xp = result[1].currentXP
                local level = result[1].currentLevel
                callback(xp, level)
            else
                MySQL.execute(
                    'INSERT INTO bcc_craft_progress (charidentifier, currentXP, currentLevel) VALUES (@charidentifier, 0, 1)',
                    param)
                callback(0, 1)
            end
        end)
end

-- Calculate the player's level and remaining XP based on dynamic LevelThresholds
function CalculateLevelFromXP(xp)
    local level = 1
    local remainingXP = xp

    for _, threshold in ipairs(Config.LevelThresholds) do
        local xpForRange = (threshold.maxLevel - threshold.minLevel + 1) * threshold.xpPerLevel
        if remainingXP >= xpForRange then
            -- Move to the next range
            remainingXP = remainingXP - xpForRange
            level = threshold.maxLevel + 1
        else
            -- Calculate level within the current range
            level = threshold.minLevel + math.floor(remainingXP / threshold.xpPerLevel)
            remainingXP = remainingXP % threshold.xpPerLevel -- Update to the remaining XP after level calculation
            break
        end
    end

    return level, remainingXP
end

-- Calculate incremental levels based on added XP and lastLevel
function CalculateIncrementalLevel(xp, lastLevel)
    local level = lastLevel
    local remainingXP = xp

    for _, threshold in ipairs(Config.LevelThresholds) do
        if level >= threshold.minLevel and level <= threshold.maxLevel then
            -- Calculate required XP for current range
            local xpPerLevel = threshold.xpPerLevel
            while remainingXP >= xpPerLevel and level < threshold.maxLevel do
                remainingXP = remainingXP - xpPerLevel
                level = level + 1
            end
        end
    end

    return level, remainingXP
end

-- Register each craftbook as a usable item
for _, location in ipairs(CraftingLocations) do
    devPrint("Registering craftbooks for location: " .. json.encode(location.coords))

    for _, category in ipairs(location.categories) do
        local craftBookItem = category.craftBookItem

        -- Check if the craftBookItem is not an empty string
        if craftBookItem and craftBookItem ~= "" then
            --devPrint("Registering craftbook item: " .. craftBookItem .. " for category: " .. category.name)

            exports.vorp_inventory:registerUsableItem(craftBookItem, function(data)
                local src = data.source -- The player's server ID
                exports.vorp_inventory:closeInventory(src)

                TriggerClientEvent('bcc-crafting:openCategoryMenu', src, category.name, true)
            end)
        else
            --devPrint("Skipping registration for empty craftBookItem in category: " .. category.name)
        end
    end
end

-- Server-side callback to retrieve the item limit
BCCCallbacks.Register("bcc-crafting:getItemLimit", function(source, cb, itemName)
    devPrint("Received request to fetch item limit for item:" .. tostring(itemName or "No Item Name Provided"))

    if not itemName then
        devPrint("Error: No itemName provided to getItemLimit callback")
        cb("N/A")
        return
    end

    -- Using direct concatenation in devPrint
    devPrint("Fetching item limit from database for item: " .. itemName)

    -- Retrieve item data using vorp_inventory export
    local itemDBData = exports.vorp_inventory:getItemDB(itemName)

    if itemDBData then
        devPrint("Item data found for: " .. itemName .. " with limit: " .. tostring(itemDBData.limit))
        local itemLimit = itemDBData.limit -- Capture the limit directly if found
        cb(itemLimit)                      -- Respond with the item limit
    else
        devPrint("No data found for item: " .. itemName)
        cb() -- Return "N/A" if no data is found
    end
end)

-- Function to update crafting status
function updateCraftingStatus(craftingId, status)
    local params = {
        ['id'] = craftingId,
        ['status'] = status,
        ['completed_at'] = status == 'completed' and os.date('%Y-%m-%d %H:%M:%S') or nil
    }

    MySQL.update.await('UPDATE bcc_crafting_log SET status = @status, completed_at = @completed_at WHERE id = @id',
        params)
end

-- Function to get itemAmount from CraftingLocations based on itemName
function getConfigItemAmount(itemName)
    for _, location in ipairs(CraftingLocations) do
        for _, category in ipairs(location.categories) do
            for _, item in ipairs(category.items) do
                if item.itemName == itemName then
                    return item.itemAmount
                end
            end
        end
    end
    devPrint("[ERROR] Item not found in CraftingLocations: " .. itemName)
    return nil -- Return nil if item is not found
end

--devPrint(_U('VersionCheck') .. GetCurrentResourceName())
BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-craft')

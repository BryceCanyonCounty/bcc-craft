local activeCrafting = {}

-- Register a callback for crafting attempts
BCCCallbacks.Register('bcc-crafting:attemptCraft', function(source, cb, item)
    local Character = VORPcore.getUser(source).getUsedCharacter
    local playerId = Character.charIdentifier
    local playerJob = Character.job
    local jobGrade = Character.jobGrade

    -- Check job requirements
    if item.requiredJobs and #item.requiredJobs > 0 then
        local hasValidJob = false
        for _, allowedJob in pairs(item.requiredJobs) do
            if playerJob == allowedJob.name and jobGrade >= allowedJob.grade then
                hasValidJob = true
                break
            end
        end
        if not hasValidJob then
            VORPcore.NotifyObjective(source, _U('InvalidJobForCrafting') .. item.itemLabel, 4000)
            cb(false)
            return
        end
    end

    -- Check if player has required items
    local hasItems = true
    for _, reqItem in pairs(item.requiredItems) do
        local count = exports.vorp_inventory:getItemCount(source, nil, reqItem.itemName)
        if count < reqItem.itemCount * item.itemAmount then
            hasItems = false
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

        local totalDuration = item.duration * item.itemAmount
        local isWeapon = string.find(item.itemName, "^WEAPON_")

        if not isWeapon then
            -- Regular item limit check
            local itemDBData = exports.vorp_inventory:getItemDB(item.itemName)
            local itemLimit = itemDBData and itemDBData.limit
            if item.itemAmount > itemLimit then
                VORPcore.NotifyRightTip(source, _U('CannotCraftOverLimit') .. item.itemLabel, 4000)
                cb(false)
                return
            end
        end

        -- Remove required items from inventory
        for _, reqItem in pairs(item.requiredItems) do
            if reqItem.removeItem then
                local subItem = exports.vorp_inventory:subItem(source, reqItem.itemName,
                    reqItem.itemCount * item.itemAmount, reqItem.metadata or {})
                if not subItem then
                    VORPcore.NotifyRightTip(source, _U('RemoveItemFailed', reqItem.itemLabel), 4000)
                    cb(false)
                    return
                end
            end
        end

        -- Insert crafting attempt into database
        local craftingData = {
            ['charidentifier'] = playerId,
            ['itemName'] = item.itemName,
            ['itemLabel'] = item.itemLabel,
            ['itemAmount'] = item.itemAmount,
            ['requiredItems'] = json.encode(item.requiredItems),
            ['status'] = 'in_progress',
            ['duration'] = totalDuration,
            ['rewardXP'] = item.rewardXP,
            ['timestamp'] = os.time()
        }

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
                source ..
                " started crafting " ..
                item.itemLabel .. ". Amount: " .. item.itemAmount .. ". Total Duration: " .. totalDuration .. "s")
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
                --print("completedResult is nil")
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
    print("[DEBUG] Item name:", itemName, "Is weapon:", tostring(isWeapon))

    if isWeapon then
        -- Retrieve the player's weapon inventory and limit the weapon count
        exports.vorp_inventory:getUserInventoryWeapons(source, function(weapons)
            local currentWeaponCount = #weapons
            local maxWeaponsAllowed = 5 -- Adjust this based on your server's maximum allowed weapon count

            if currentWeaponCount >= maxWeaponsAllowed then
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
        print("[ERROR] Item name: ", itemName)
        if not itemData then
            print("[ERROR] Item data not found: ", itemName)
            VORPcore.NotifyRightTip(source, "Item data not found for item: " .. itemLabel, 4000)
            cb(false)
            return
        end

        -- Check inventory space
        local itemLimit = itemData.limit
        print("[ERROR] Item limit: ", itemLimit)
        local currentCount = exports.vorp_inventory:getItemCount(source, nil, itemName)
        local spaceAvailable = itemLimit - currentCount
        if spaceAvailable <= 0 then
            VORPcore.NotifyRightTip(source, _U('NotEnoughSpace') .. amountToAdd .. "x " .. itemLabel .. ".", 4000)
            cb(false)
            return
        end

        -- Calculate the amount to add based on space available
        local addableAmount = math.min(amountToAdd, spaceAvailable)
        local remainingAmount = amountToAdd - addableAmount

        -- Add the crafted items to the player's inventory
        local addItemResult = exports.vorp_inventory:addItem(source, itemName, addableAmount, {})
        if addItemResult then
            -- Update or delete crafting log based on remaining amount
            if remainingAmount > 0 then
                MySQL.execute('UPDATE bcc_crafting_log SET itemAmount = @remainingAmount WHERE id = @id', {
                    ['@remainingAmount'] = remainingAmount,
                    ['@id'] = craftingLog.id
                })
                print("[DEBUG] Updated crafting log with remaining amount:", remainingAmount)
                VORPcore.NotifyRightTip(source,
                    _U('CollectedPartially') .. amountToAdd .. "x " .. itemLabel .. ".", 4000)
            else
                MySQL.execute('DELETE FROM bcc_crafting_log WHERE id = @id', { ['@id'] = craftingLog.id })
                print("[DEBUG] Crafting log entry deleted for item:", itemName)
                VORPcore.NotifyRightTip(source,
                    _U('CollectedCraftedItem') .. amountToAdd .. "x " .. itemLabel .. ".", 4000)
            end

            local totalXP = rewardXP * amountToAdd
            AddPlayerCraftingXP(playerId, totalXP, function(newLevel)
                if newLevel then
                    print("[DEBUG] Player leveled up to:", newLevel)
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
                firstname, lastname, playerId, craftingLog.itemLabel, amountToAdd, totalXP
            )
            Discord:sendMessage(discordMessage)
            cb(true)
        else
            print("[ERROR] Failed to add crafted item to inventory:", craftingLog.itemName)
            VORPcore.NotifyRightTip(source, _U('FailedToAddItem'), 4000)
            cb(false)
        end
    end
end)

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

-- Function to update player's XP and level
function AddPlayerCraftingXP(playerId, amount, callback)
    GetPlayerCraftingData(playerId, function(currentXP, level)
        local xp = currentXP + amount
        local newLevel = CalculateLevelFromXP(xp)

        -- Update the player's level and XP in the database
        local param = {
            ['charidentifier'] = playerId,
            ['currentXP'] = xp,
            ['currentLevel'] = newLevel
        }
        MySQL.update.await(
        'UPDATE bcc_craft_progress SET currentXP = @currentXP, currentLevel = @currentLevel WHERE charidentifier = @charidentifier',
            param)

        -- Check for level-up
        if newLevel > level then
            callback(newLevel)
        else
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
    devPrint("Fetching item limit from database for item:", tostring(itemName))

    -- Retrieve item data using vorp_inventory export
    local itemDBData = exports.vorp_inventory:getItemDB(itemName)

    if itemDBData then
        devPrint("Item data found for:", tostring(itemName), "with limit:", tostring(itemDBData.limit))
        local itemLimit = itemDBData.limit -- Capture the limit directly if found
        cb(itemLimit)                      -- Respond with the item limit
    else
        devPrint("No data found for item:", tostring(itemName))
        cb("N/A") -- Return "N/A" if no data is found
    end
end)


-- Start the crafting progress check loop when the resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        --CheckCraftingProgress()
    end
end)

-- XP to level calculation based on new Config.LevelThresholds
function CalculateLevelFromXP(xp)
    local cumulativeXP = 0
    for _, threshold in ipairs(Config.LevelThresholds) do
        local rangeXP = (threshold.maxLevel - threshold.minLevel + 1) * threshold.xpPerLevel
        if xp < cumulativeXP + rangeXP then
            return threshold.minLevel + math.floor((xp - cumulativeXP) / threshold.xpPerLevel)
        end
        cumulativeXP = cumulativeXP + rangeXP
    end
    return 1 -- Default to level 1 if not within any threshold
end

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

--devPrint(_U('VersionCheck') .. GetCurrentResourceName())
BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-craft')

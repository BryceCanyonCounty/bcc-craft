local activeCrafting = {}

-- Handle crafting requests from client
BCCCallbacks.Register('bcc-crafting:attemptCraft', function(source, cb, item)
    local Character = VORPcore.getUser(source).getUsedCharacter
    local playerId = Character.charIdentifier -- Unique character identifier
    local playerJob = Character.job -- Get player job
    local jobGrade = Character.jobGrade -- Get player's job grade

    -- Check if the item has job requirements
    if item.requiredJobs and #item.requiredJobs > 0 then
        devPrint("Checking job requirements for: " .. item.itemLabel)
        local hasValidJob = false
    
        -- Validate the player's job
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
        local count = exports.vorp_inventory:getItemCount(source, nil, reqItem.itemName)
        devPrint(_U('PlayerHas') .. count .. _U('Of') .. reqItem.itemName .. _U('Requires') .. reqItem.itemCount .. ")")
        if count < reqItem.itemCount then
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

        -- Calculate total crafting duration based on the number of items
        local totalDuration = item.duration * item.itemAmount
        devPrint("Crafting " .. item.itemAmount .. " items will take " .. totalDuration .. " seconds")

        -- Remove the required items from the player's inventory if removeItem is true
        for _, reqItem in pairs(item.requiredItems) do
            if reqItem.removeItem == true then -- Check if the item should be removed
                exports.vorp_inventory:subItem(source, reqItem.itemName, reqItem.itemCount, reqItem.metadata or {}, function(success)
                    if not success then
                        VORPcore.NotifyRightTip(source, _U('RemoveItemFailed', reqItem.itemLabel), 4000)
                        cb(false)
                        return
                    end
                    devPrint(_U('RemovedItem', reqItem.itemCount, reqItem.itemLabel))
                end)
            else
                devPrint("Item not removed as 'removeItem' is false: " .. reqItem.itemLabel)
            end
        end

        -- Insert crafting attempt into the database with updated duration
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

        MySQL.insert('INSERT INTO bcc_crafting_log (charidentifier, itemName, itemLabel, itemAmount, requiredItems, status, duration, rewardXP, timestamp) VALUES (@charidentifier, @itemName, @itemLabel, @itemAmount, @requiredItems, @status, @duration, @rewardXP, @timestamp)', craftingData, function(insertId)
            if insertId then
                item.craftingId = insertId
                activeCrafting[source] = {
                    item = item,
                    startTime = os.time(),
                    duration = totalDuration
                }
                TriggerClientEvent('bcc-crafting:startCrafting', source, item)

                Discord:sendMessage("Player ID: " .. source .. " started crafting " .. item.itemLabel .. ". Amount: " .. item.itemAmount .. ". Total Duration: " .. totalDuration .. "s")
                cb(true) -- Crafting started successfully
            else
                VORPcore.NotifyRightTip(source, _U('CraftingAttemptFailed'), 4000)
                cb(false) -- Crafting attempt failed
            end
        end)
    end)
end)

-- Handle crafting completion
RegisterServerEvent('bcc-crafting:completeCrafting')
AddEventHandler('bcc-crafting:completeCrafting', function(item)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local playerId = Character.charIdentifier

    if not item.craftingId then
        VORPcore.NotifyRightTip(_source, _U('InvalidCraftingData'), 4000)
        return
    end

    local craftingSession = activeCrafting[_source]
    if not craftingSession or craftingSession.item.craftingId ~= item.craftingId then
        VORPcore.NotifyRightTip(_source, _U('NoActiveCraftingSession'), 4000)
        return
    end

    local elapsedTime = os.time() - craftingSession.startTime
    if elapsedTime < craftingSession.duration then
        VORPcore.NotifyRightTip(_source, _U('CraftingNotComplete'), 4000)
        return
    end

    activeCrafting[_source] = nil

    exports.vorp_inventory:canCarryItem(_source, item.itemName, item.itemAmount, function(canCarry)
        if not canCarry then
            VORPcore.NotifyRightTip(_source, _U('CannotCarryItem'), 4000)
            updateCraftingStatus(item.craftingId, 'failed')
            return
        end

        removeRequiredItemsAsync(_source, item.requiredItems, function(success)
            if success then
                exports.vorp_inventory:addItem(_source, item.itemName, item.itemAmount, item.metadata or {}, function(addItemResult)
                    if addItemResult then
                        AddPlayerCraftingXP(playerId, item.rewardXP, function(newLevel)
                            if newLevel then
                                TriggerClientEvent('bcc-crafting:levelUp', _source, newLevel)
                            end
                        end)

                        updateCraftingStatus(item.craftingId, 'completed')
                        VORPcore.NotifyRightTip(_source, _U('YouCrafted') .. item.itemAmount .. "x " .. item.itemLabel .. ".", 4000)
                        Discord:sendMessage("Player ID: " .. _source .. " successfully crafted " .. item.itemAmount .. "x " .. item.itemLabel .. ".")
                    else
                        VORPcore.NotifyRightTip(_source, _U('FailedToAddCraftedItem'), 4000)
                        refundRequiredItems(_source, item.requiredItems)
                        updateCraftingStatus(item.craftingId, 'failed')
                    end
                end)
            else
                VORPcore.NotifyRightTip(_source, _U('FailedToRemoveRequiredItems'), 4000)
                updateCraftingStatus(item.craftingId, 'failed')
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

    -- Log for debugging and Discord message
    devPrint(_U('CharacterIdentifier') .. charIdentifier)
    
    -- Query the database for ongoing crafting logs
    exports.oxmysql:execute("SELECT * FROM bcc_crafting_log WHERE charidentifier = @charidentifier AND status = 'in_progress'", {
        ['@charidentifier'] = charIdentifier
    }, function(result)
        if result and #result > 0 then
            local ongoingCraftingList = {}

            -- Loop through each crafting log result
            for _, craftingLog in ipairs(result) do
                local startTime = craftingLog.timestamp
                local currentTime = os.time()
                local elapsedTime = currentTime - startTime
                local remainingTime = craftingLog.duration - elapsedTime

                -- Debugging prints
                devPrint(_U('CraftingLogID') .. craftingLog.id)
                devPrint(_U('StartTime') .. startTime)
                devPrint(_U('CurrentTime') .. currentTime)
                devPrint(_U('ElapsedTime') .. elapsedTime)
                devPrint(_U('RemainingTime') .. remainingTime)

                -- If the crafting has been completed, update the status to 'completed'
                if remainingTime <= 0 then
                    devPrint(_U('MarkAsCompleted') .. craftingLog.id)
                    exports.oxmysql:execute("UPDATE bcc_crafting_log SET status = 'completed', completed_at = NOW() WHERE id = @id", {
                        ['@id'] = craftingLog.id
                    })
                    remainingTime = 0
                end

                -- Insert crafting log details and remaining time into the list
                table.insert(ongoingCraftingList, {
                    craftingLog = craftingLog,
                    remainingTime = remainingTime
                })
            end

            -- Send the list of ongoing crafting items to the client
            TriggerClientEvent('bcc-crafting:sendOngoingCraftingList', _source, ongoingCraftingList)
        else
            -- If no ongoing crafting found, send an empty list
            devPrint("No ongoing crafting processes found for character ID: " .. charIdentifier)
            TriggerClientEvent('bcc-crafting:sendOngoingCraftingList', _source, {})
        end
    end)
end)

-- Server-side function to retrieve completed crafting items
RegisterNetEvent('bcc-crafting:getCompletedCrafting')
AddEventHandler('bcc-crafting:getCompletedCrafting', function()
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local charIdentifier = Character.charIdentifier -- Character identifier
    
    exports.oxmysql:execute("SELECT * FROM bcc_crafting_log WHERE charidentifier = @charidentifier AND status = 'completed'", {
        ['@charidentifier'] = charIdentifier
    }, function(completedResult)
        --devPrint(_U('CompletedCraftingQuery') .. json.encode(completedResult))

        if completedResult and #completedResult > 0 then
            TriggerClientEvent('bcc-crafting:sendCompletedCraftingList', _source, completedResult)
        else
            devPrint(_U('NoCompletedCrafting') .. charIdentifier)
            TriggerClientEvent('bcc-crafting:noOngoingCrafting', _source)
        end
    end)
end)

-- Register the callback for collecting crafted items
BCCCallbacks.Register('bcc-crafting:collectCraftedItem', function(source, cb, craftingLog)
    local Character = VORPcore.getUser(source).getUsedCharacter
    local playerId = Character.charIdentifier -- Unique character identifier
    local firstname = Character.firstname -- Player's first name
    local lastname = Character.lastname   -- Player's last name

    -- Check if the player can carry the crafted items
    exports.vorp_inventory:canCarryItem(source, craftingLog.itemName, craftingLog.itemAmount, function(canCarry)
        if not canCarry then
            VORPcore.NotifyRightTip(source, _U('NotEnoughSpace') .. craftingLog.itemAmount .. "x " .. craftingLog.itemLabel .. ".", 4000)
            cb(false) -- Callback with failure status
            return
        end

        -- Add the crafted item to the player's inventory
        exports.vorp_inventory:addItem(source, craftingLog.itemName, craftingLog.itemAmount, {}, function(success)
            if success then
                -- Remove the crafting log entry from the database
                MySQL.execute('DELETE FROM bcc_crafting_log WHERE id = @id', { ['@id'] = craftingLog.id })

                -- Notify the player that they collected the item
                VORPcore.NotifyRightTip(source, _U('CollectedCraftedItem') .. craftingLog.itemAmount .. "x " .. craftingLog.itemLabel .. ".", 4000)

                -- Calculate the total XP earned
                local totalXP = craftingLog.rewardXP * craftingLog.itemAmount

                -- Add the crafting XP to the player
                AddPlayerCraftingXP(playerId, totalXP, function(newLevel)
                    if newLevel then
                        -- Notify the client of the level-up
                        TriggerClientEvent('bcc-crafting:levelUp', source, newLevel)
                    end
                end)

                -- Send a prettified Discord message with more character details
                local discordMessage = string.format(
                    "**Crafting Completion**\n\n" ..
                    "**Player:** %s %s (ID: %s)\n" ..
                    "**Crafted Item:** %s x%d\n" ..
                    "**XP Gained:** %d XP\n" ..
                    "**Item Collected Successfully**",
                    firstname, lastname, playerId, craftingLog.itemLabel, craftingLog.itemAmount, totalXP
                )

                Discord:sendMessage(discordMessage)
                cb(true) -- Callback with success status
            else
                -- Notify the player of the failure to add the crafted item
                VORPcore.NotifyRightTip(source, _U('FailedToAddItem'), 4000)
                cb(false) -- Callback with failure status
            end
        end)
    end)
end)

-- Get player's crafting data and send it to the client
RegisterNetEvent('bcc-crafting:requestCraftingData')
AddEventHandler('bcc-crafting:requestCraftingData', function()
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local playerId = Character.charIdentifier -- Unique character identifier

    GetPlayerCraftingData(playerId, function(xp, level)
        -- Correct formula to calculate XP needed for next level
        local requiredXPForNextLevel = (level * 1000) -- Assume each level requires 1000 XP
        local xpToNextLevel = requiredXPForNextLevel - xp

        -- Trigger the event to send the data to the client
        TriggerClientEvent('bcc-crafting:sendCraftingData', _source, level, xp, xpToNextLevel)
    end)
end)

-- Function to update player's XP and level
function AddPlayerCraftingXP(playerId, amount, callback)
    GetPlayerCraftingData(playerId, function(xp, level)
        xp = xp + amount
        local newLevel = CalculateLevelFromXP(xp)

        local param = {
            ['charidentifier'] = playerId,
            ['currentXP'] = xp,
            ['currentLevel'] = newLevel
        }
        MySQL.execute('UPDATE bcc_craft_progress SET currentXP = @currentXP, currentLevel = @currentLevel WHERE charidentifier = @charidentifier', param)

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
    MySQL.query('SELECT currentXP, currentLevel FROM bcc_craft_progress WHERE charidentifier = @charidentifier', param, function(result)
        if #result > 0 then
            local xp = result[1].currentXP
            local level = result[1].currentLevel
            callback(xp, level)
        else
        
            MySQL.execute('INSERT INTO bcc_craft_progress (charidentifier, currentXP, currentLevel) VALUES (@charidentifier, 0, 1)', param)
            callback(0, 1)
        end
    end)
end

-- Register each craftbook as a usable item
for _, category in ipairs(Config.CraftingCategories) do
    local craftBookItem = category.craftBookItem  -- Unique identifier for each category's craftbook

    exports.vorp_inventory:registerUsableItem(craftBookItem, function(data)
        local src = data.source  -- The player's server ID
        Discord:sendMessage("Player ID: " .. src .. " used craftbook for category: " .. category.name)

        -- Optionally close inventory or perform other pre-menu actions here
        exports.vorp_inventory:closeInventory(src)
        -- Trigger a client event to handle the crafting menu display
        TriggerClientEvent('bcc-crafting:openCategoryMenu', src, category.name)
    end)
end

-- XP to level calculation function
function CalculateLevelFromXP(xp)
    return math.floor(xp / 1000) + 1
end

-- Function to update crafting status
function updateCraftingStatus(craftingId, status)
    local params = {
        ['id'] = craftingId,
        ['status'] = status,
        ['completed_at'] = status == 'completed' and os.date('%Y-%m-%d %H:%M:%S') or nil
    }
    Discord:sendMessage("Crafting ID: " .. craftingId .. " status updated to " .. status)
    
    MySQL.execute('UPDATE bcc_crafting_log SET status = @status, completed_at = @completed_at WHERE id = @id', params)
end

devPrint(_U('VersionCheck') .. GetCurrentResourceName())
BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-craft')

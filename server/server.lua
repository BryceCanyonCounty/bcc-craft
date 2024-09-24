local VORPcore = exports.vorp_core:GetCore()
BccUtils = exports['bcc-utils'].initiate()
Discord = BccUtils.Discord.setup(Config.WebhookLink, Config.WebhookTitle, Config.WebhookAvatar) -- Setup Discord webhook

-- Helper function for debugging in DevMode
if Config.devMode then
    function devPrint(message)
        print("^1[DEV MODE] ^4" .. message)
    end
else
    function devPrint(message) end -- No-op if DevMode is disabled
end

local activeCrafting = {}

-- Handle crafting requests from client
RegisterServerEvent('bcc-crafting:attemptCraft')
AddEventHandler('bcc-crafting:attemptCraft', function(item)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local playerId = Character.charIdentifier -- Unique character identifier

    -- Check if player has required items
    local hasItems = true
    for _, reqItem in pairs(item.requiredItems) do
        devPrint(_U('CheckingRequiredItem') .. reqItem.itemName)
        local count = exports.vorp_inventory:getItemCount(_source, nil, reqItem.itemName)
        devPrint(_U('PlayerHas') .. count .. _U('Of') .. reqItem.itemName .. _U('Requires') .. reqItem.itemCount .. ")")
        if count < reqItem.itemCount then
            hasItems = false
            devPrint(_U('MissingItem') .. reqItem.itemName)
            break
        end
    end

    if not hasItems then
        VORPcore.NotifyRightTip(_source, _U('MissingMaterials') .. item.itemLabel .. ".", 4000)
        Discord:sendMessage("Player ID: " .. _source .. " failed crafting attempt. Missing materials for " .. item.itemLabel)
        return
    end

    -- Check player's crafting level
    GetPlayerCraftingData(playerId, function(xp, level)
        if level < item.requiredLevel then
            VORPcore.NotifyRightTip(_source, _U('RequiredLevel') .. item.requiredLevel .. ".", 4000)
            Discord:sendMessage("Player ID: " .. _source .. " attempted crafting " .. item.itemLabel .. " but lacked required level (" .. level .. " < " .. item.requiredLevel .. ")")
            return
        end
        
        -- Remove the required items from the player's inventory
        for _, reqItem in pairs(item.requiredItems) do
            exports.vorp_inventory:subItem(_source, reqItem.itemName, reqItem.itemCount, reqItem.metadata or {}, function(success)
                if not success then
                    VORPcore.NotifyRightTip(_source, _U('RemoveItemFailed', reqItem.itemLabel), 4000)
                    Discord:sendMessage("Failed to remove required item: " .. reqItem.itemLabel .. " from Player ID: " .. _source)
                    return
                end
                devPrint(_U('RemovedItem', reqItem.itemCount, reqItem.itemLabel))
            end)
        end

        -- Insert crafting attempt into the database
        local craftingData = {
            ['charidentifier'] = playerId,
            ['itemName'] = item.itemName,
            ['itemLabel'] = item.itemLabel,
            ['itemAmount'] = item.itemAmount,
            ['requiredItems'] = json.encode(item.requiredItems),
            ['status'] = 'in_progress',
            ['duration'] = item.duration,
            ['rewardXP'] = item.rewardXP,
            ['timestamp'] = os.time()
        }

        MySQL.insert('INSERT INTO bcc_crafting_log (charidentifier, itemName, itemLabel, itemAmount, requiredItems, status, duration, rewardXP, timestamp) VALUES (@charidentifier, @itemName, @itemLabel, @itemAmount, @requiredItems, @status, @duration, @rewardXP, @timestamp)', craftingData, function(insertId)
            if insertId then
                item.craftingId = insertId
                activeCrafting[_source] = {
                    item = item,
                    startTime = os.time(),
                    duration = item.duration
                }
                TriggerClientEvent('bcc-crafting:startCrafting', _source, item)
                
                Discord:sendMessage("Player ID: " .. _source .. " started crafting " .. item.itemLabel .. ". Amount: " .. item.itemAmount .. ". Duration: " .. item.duration .. "s")
            else
                VORPcore.NotifyRightTip(_source, _U('CraftingAttemptFailed'), 4000)
                Discord:sendMessage("Player ID: " .. _source .. " failed to start crafting " .. item.itemLabel .. ".")
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
            Discord:sendMessage("Player ID: " .. _source .. " failed to complete crafting " .. item.itemLabel .. ". Inventory full.")
            return
        end

        removeRequiredItemsAsync(_source, item.requiredItems, function(success)
            if success then
                exports.vorp_inventory:addItem(_source, item.itemName, item.itemAmount, item.metadata or {}, function(addItemResult)
                    if addItemResult then
                        AddPlayerCraftingXP(playerId, item.rewardXP, function(newLevel)
                            if newLevel then
                                TriggerClientEvent('bcc-crafting:levelUp', _source, newLevel)
                                Discord:sendMessage("Player ID: " .. _source .. " leveled up! New level: " .. newLevel)
                            end
                        end)

                        updateCraftingStatus(item.craftingId, 'completed')
                        VORPcore.NotifyRightTip(_source, _U('YouCrafted') .. item.itemAmount .. "x " .. item.itemLabel .. ".", 4000)
                        Discord:sendMessage("Player ID: " .. _source .. " successfully crafted " .. item.itemAmount .. "x " .. item.itemLabel .. ".")
                    else
                        VORPcore.NotifyRightTip(_source, _U('FailedToAddCraftedItem'), 4000)
                        refundRequiredItems(_source, item.requiredItems)
                        updateCraftingStatus(item.craftingId, 'failed')
                        Discord:sendMessage("Player ID: " .. _source .. " failed to add crafted item " .. item.itemLabel .. " to inventory.")
                    end
                end)
            else
                VORPcore.NotifyRightTip(_source, _U('FailedToRemoveRequiredItems'), 4000)
                updateCraftingStatus(item.craftingId, 'failed')
                Discord:sendMessage("Player ID: " .. _source .. " failed to remove required items for " .. item.itemLabel)
            end
        end)
    end)
end)

-- Server-side function to retrieve ongoing crafting items and remaining times
RegisterNetEvent('bcc-crafting:getOngoingCrafting')
AddEventHandler('bcc-crafting:getOngoingCrafting', function()
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local charIdentifier = Character.charIdentifier -- Character identifier

    devPrint(_U('CharacterIdentifier') .. charIdentifier)
    Discord:sendMessage("Player ID: " .. _source .. " is retrieving ongoing crafting items.")

    exports.oxmysql:execute("SELECT * FROM bcc_crafting_log WHERE charidentifier = @charidentifier AND status = 'in_progress'", {
        ['@charidentifier'] = charIdentifier
    }, function(result)
        devPrint(_U('OngoingCraftingQuery') .. json.encode(result))

        local ongoingCraftingList = {}

        if result and #result > 0 then
            for _, craftingLog in ipairs(result) do
                local startTime = craftingLog.timestamp
                local currentTime = os.time()
                local elapsedTime = currentTime - startTime
                local remainingTime = craftingLog.duration - elapsedTime

                devPrint(_U('CraftingLogID') .. craftingLog.id)
                devPrint(_U('StartTime') .. startTime)
                devPrint(_U('CurrentTime') .. currentTime)
                devPrint(_U('ElapsedTime') .. elapsedTime)
                devPrint(_U('RemainingTime') .. remainingTime)

                if remainingTime <= 0 then
                    devPrint(_U('MarkAsCompleted') .. craftingLog.id)
                    Discord:sendMessage("Crafting Log ID: " .. craftingLog.id .. " marked as completed.")

                    exports.oxmysql:execute("UPDATE bcc_crafting_log SET status = 'completed', completed_at = NOW() WHERE id = @id", {
                        ['@id'] = craftingLog.id
                    })
                    remainingTime = 0
                end

                table.insert(ongoingCraftingList, { craftingLog = craftingLog, remainingTime = remainingTime })
            end
            Discord:sendMessage("Player ID: " .. _source .. " has ongoing crafting items.")
            else
                Discord:sendMessage("Player ID: " .. _source .. " has no ongoing crafting items.")
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

    devPrint(_U('CharacterIdentifier') .. charIdentifier)
    Discord:sendMessage("Player ID: " .. _source .. " is retrieving completed crafting items.")

    exports.oxmysql:execute("SELECT * FROM bcc_crafting_log WHERE charidentifier = @charidentifier AND status = 'completed'", {
        ['@charidentifier'] = charIdentifier
    }, function(completedResult)
        devPrint(_U('CompletedCraftingQuery') .. json.encode(completedResult))

        if completedResult and #completedResult > 0 then
            Discord:sendMessage("Player ID: " .. _source .. " has completed crafting items.")
            TriggerClientEvent('bcc-crafting:sendCompletedCraftingList', _source, completedResult)
        else
            devPrint(_U('NoCompletedCrafting') .. charIdentifier)
            Discord:sendMessage("Player ID: " .. _source .. " has no completed crafting items.")
            TriggerClientEvent('bcc-crafting:noOngoingCrafting', _source)
        end
    end)
end)

-- Server-side event to collect crafted items
RegisterServerEvent('bcc-crafting:collectCraftedItem')
AddEventHandler('bcc-crafting:collectCraftedItem', function(craftingLog)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local playerId = Character.charIdentifier -- Unique character identifier

    exports.vorp_inventory:canCarryItem(_source, craftingLog.itemName, craftingLog.itemAmount, function(canCarry)
        if not canCarry then
            VORPcore.NotifyRightTip(_source, _U('NotEnoughSpace') .. craftingLog.itemAmount .. "x " .. craftingLog.itemLabel .. ".", 4000)
            Discord:sendMessage("Player ID: " .. _source .. " failed to collect crafted item " .. craftingLog.itemLabel .. ". Not enough space.")
            return
        end

        exports.vorp_inventory:addItem(_source, craftingLog.itemName, craftingLog.itemAmount, {}, function(success)
            if success then
                MySQL.execute('DELETE FROM bcc_crafting_log WHERE id = @id', { ['@id'] = craftingLog.id })

                VORPcore.NotifyRightTip(_source, _U('CollectedCraftedItem') .. craftingLog.itemAmount .. "x " .. craftingLog.itemLabel .. ".", 4000)

                local totalXP = craftingLog.rewardXP * craftingLog.itemAmount

                AddPlayerCraftingXP(playerId, totalXP, function(newLevel)
                    if newLevel then
                        TriggerClientEvent('bcc-crafting:levelUp', _source, newLevel)
                    end
                end)
                
                Discord:sendMessage("Player ID: " .. _source .. " collected crafted item " .. craftingLog.itemAmount .. "x " .. craftingLog.itemLabel)
            else
                VORPcore.NotifyRightTip(_source, _U('FailedToAddItem'), 4000)
                Discord:sendMessage("Player ID: " .. _source .. " failed to collect crafted item " .. craftingLog.itemLabel)
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
        local xpToNextLevel = ((level * 100) - xp)
        
        Discord:sendMessage("Player ID: " .. _source .. " requested crafting data. Current Level: " .. level .. ", XP to next level: " .. xpToNextLevel)

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
            -- Log level-up to Discord
            Discord:sendMessage("Player ID: " .. playerId .. " leveled up! New Level: " .. newLevel)

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
            -- Log new crafting data entry to Discord
            Discord:sendMessage("New player crafting data entry created for Player ID: " .. playerId)
            
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

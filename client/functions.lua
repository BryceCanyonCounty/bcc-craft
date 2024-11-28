-- Pulling Essentials
VORPcore = exports.vorp_core:GetCore()

FeatherMenu = exports["feather-menu"].initiate()
BccUtils = exports["bcc-utils"].initiate()
MiniGame = exports["bcc-minigames"].initiate()

BCCCraftingMenu = FeatherMenu:RegisterMenu("bcc:crafting:mainmenu",
    {
        top = '3%',
        left = '3%',
        ['720width'] = '400px',
        ['1080width'] = '500px',
        ['2kwidth'] = '600px',
        ['4kwidth'] = '800px',
        style = {},
        contentslot = {
            style = {
                ['height'] = '450px',
                ['min-height'] = '250px'
            }
        },
    },
    {
        opened = function()
            DisplayRadar(false)
        end,
        closed = function()
            DisplayRadar(true)
        end
    }
)

-- Helper function for debugging in DevMode
if Config.devMode then
    function devPrint(message)
        print("^1[DEV MODE] ^4" .. message)
    end
else
    function devPrint(message) end -- No-op if DevMode is disabled
end

-- Handle player death and close menu
function HandlePlayerDeathAndCloseMenu()
    local playerPed = PlayerPedId()

    -- Check if the player is already dead
    if IsEntityDead(playerPed) then
        devPrint("Player is dead, closing the crafting menu.")
        BCCCraftingMenu:Close() -- Close the menu if the player is dead
        return true             -- Return true to indicate the player is dead and the menu was closed
    end

    -- If the player is not dead, start monitoring for death while the menu is open
    CreateThread(function()
        while true do
            if IsEntityDead(playerPed) then
                devPrint("Player died while in the menu, closing the crafting menu.")
                BCCCraftingMenu:Close() -- Close the menu if the player dies while in the menu
                break                   -- Stop the loop since the player is dead and the menu is closed
            end
            Wait(1000)                  -- Check every second
        end
    end)

    devPrint("Player is alive, crafting menu can be opened.")
    return false -- Return false to indicate the player is alive and the menu can open
end

function attemptCraftItem(item, amount)
    item.itemAmount = tonumber(amount) -- Set the amount to craft

    -- Make the RPC call to attempt crafting
    BccUtils.RPC:Call("bcc-crafting:AttemptCraft", { item = item }, function(success, message)
        if success then
            devPrint("Crafting started successfully for item: " .. item.itemLabel)
            VORPcore.NotifyRightTip("Crafting started successfully for " .. item.itemLabel, 4000)
        else
            devPrint("[ERROR] Failed to start crafting for item: " .. item.itemLabel .. ". Reason: " .. tostring(message))
            VORPcore.NotifyRightTip(message or "Failed to start crafting.", 4000)
        end
    end)
end

-- Function to fetch item limit using RPC
function fetchItemLimit(itemName, callback)
    devPrint("Requesting item limit for:", tostring(itemName)) -- Debug the itemName

    -- Validate the itemName
    if not itemName or itemName == "" then
        devPrint("[ERROR] itemName is nil or empty in fetchItemLimit")
        callback("N/A") -- Immediately return "N/A" if no valid itemName
        return
    end

    -- Make the RPC call to fetch the item limit
    BccUtils.RPC:Call("bcc-crafting:getItemLimit", { itemName = itemName }, function(itemLimit)
        if not itemLimit then
            devPrint("[ERROR] Failed to retrieve item limit for item:", tostring(itemName))
            callback("N/A")
            return
        end

        devPrint("[DEBUG] Item limit received for", tostring(itemName), ":", tostring(itemLimit))
        callback(itemLimit) -- Pass the item limit to the provided callback
    end)
end

function GetRemainingXP(currentXP, currentLevel)
    local xpForNextLevel = 0
    local totalXPAtCurrentLevel = 0

    -- Find the XP per level for the current level range
    for _, threshold in ipairs(Config.LevelThresholds) do
        if currentLevel >= threshold.minLevel and currentLevel <= threshold.maxLevel then
            xpForNextLevel = threshold.xpPerLevel
            -- Calculate total XP required to reach the current level's start
            totalXPAtCurrentLevel = (currentLevel - threshold.minLevel) * threshold.xpPerLevel
            break
        end
    end

    if xpForNextLevel == 0 then
        devPrint("[DEBUG] No matching XP range found for level: " .. tostring(currentLevel))
        return 0
    end

    -- Calculate remaining XP for the next level
    local xpInCurrentLevel = currentXP - totalXPAtCurrentLevel
    local remainingXP = xpForNextLevel - xpInCurrentLevel

    devPrint("[DEBUG] Current XP: " .. tostring(currentXP))
    devPrint("[DEBUG] XP per level: " .. tostring(xpForNextLevel))
    devPrint("[DEBUG] XP within current level: " .. tostring(xpInCurrentLevel))
    devPrint("[DEBUG] Remaining XP to next level: " .. tostring(remainingXP))

    return math.max(0, remainingXP)
end

-- Helper function to format time into days, hours, minutes, and seconds
function formatTime(remainingTime)
    local days = math.floor(remainingTime / (24 * 3600))
    local hours = math.floor((remainingTime % (24 * 3600)) / 3600)
    local minutes = math.floor((remainingTime % 3600) / 60)
    local seconds = remainingTime % 60

    local formattedTime = ""
    if days > 0 then
        formattedTime = string.format("%d days, %d hours, %d minutes, %d seconds", days, hours, minutes, seconds)
    elseif hours > 0 then
        formattedTime = string.format("%d hours, %d minutes, %d seconds", hours, minutes, seconds)
    elseif minutes > 0 then
        formattedTime = string.format("%d minutes, %d seconds", minutes, seconds)
    else
        formattedTime = string.format("%d seconds", seconds)
    end
    return formattedTime
end

-- Handle level up notification
RegisterNetEvent('bcc-crafting:levelUp')
AddEventHandler('bcc-crafting:levelUp', function(newLevel)
    devPrint("Player leveled up! New crafting level: " .. newLevel)
    VORPcore.NotifyRightTip("Congratulations! You have reached crafting level " .. newLevel)
end)

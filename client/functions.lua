-- Pulling Essentials
VORPcore = exports.vorp_core:GetCore()

FeatherMenu = exports["feather-menu"].initiate()
BccUtils = exports["bcc-utils"].initiate()
MiniGame = exports["bcc-minigames"].initiate()

BCCCraftingMenu = FeatherMenu:RegisterMenu("bcc:crafting:mainmenu",
    {
        top = "5%",
        left = "5%",
        ["720width"] = "500px",
        ["1080width"] = "600px",
        ["2kwidth"] = "700px",
        ["4kwidth"] = "900px",
        style = {},
        contentslot = {
            style = {
                ["height"] = "450px",
                ["min-height"] = "250px"
            }
        },
        draggable = true
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

-- Define the BCCCallbacks table
BCCCallbacks = {
    callbacks = {}
}

-- Generate a unique ID for each callback request
local function generateRequestId()
    -- Use GetGameTimer() instead of os.time()
    return math.random(10000, 99999) .. GetGameTimer()
end

-- Table to map requestIds to callbacks
local callbackMap = {}

BCCCallbacks.Trigger = function(name, cb, ...)
    local requestId = generateRequestId()
    callbackMap[requestId] = cb -- Map the requestId to the callback

    local args = { ... }
    --print("[DEBUG] Triggering callback with name:", name, "Request ID:", requestId, "Data:", json.encode(args))

    -- Send the request to the server with the request ID
    TriggerServerEvent('BCCCallbacks:Request', name, requestId, ...)
end

-- Generic handler for all responses
RegisterNetEvent('BCCCallbacks:Response')
AddEventHandler('BCCCallbacks:Response', function(requestId, response)
    if callbackMap[requestId] then
        callbackMap[requestId](response) -- Execute the callback
        callbackMap[requestId] = nil     -- Clean up the callback after use
    end
end)


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

-- Function to trigger the crafting attempt
function attemptCraftItem(item, amount)
    item.itemAmount = tonumber(amount) -- Set the amount to craft
    BCCCallbacks.Trigger('bcc-crafting:attemptCraft', function(success)
        if success then
            devPrint("Crafting started successfully.")
        else
            devPrint("Failed to start crafting.")
        end
    end, item)
end

-- Function to fetch item limit
function fetchItemLimit(itemName, callback)
    devPrint("Requesting item limit for:", tostring(itemName)) -- Check `itemName` before sending

    if not itemName or itemName == "" then
        devPrint("Error: itemName is nil or empty in fetchItemLimit")
        callback("N/A") -- Immediately return "N/A" if no valid itemName
        return
    end

    -- Use a wrapped callback to add intermediate debugging
    local wrappedCallback = function(itemLimit)
        devPrint("Wrapped callback received item limit for", tostring(itemName), ":", tostring(itemLimit))
        callback(itemLimit)
    end

    -- Trigger the server callback
    BCCCallbacks.Trigger("bcc-crafting:getItemLimit", wrappedCallback, itemName)
end

-- Function to calculate the remaining XP needed for the next level based on the level thresholds
function GetRemainingXP(currentXP, level)
    local totalXPForNextLevel = 0

    for _, threshold in ipairs(Config.LevelThresholds) do
        -- Find the correct level range
        if level >= threshold.minLevel and level <= threshold.maxLevel then
            -- Calculate the required XP for the next level in the current range
            totalXPForNextLevel = (level - threshold.minLevel + 1) * threshold.xpPerLevel
            break
        end
    end

    -- Return the difference between required XP for next level and current XP
    return math.max(0, totalXPForNextLevel - currentXP)
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

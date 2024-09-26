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

-- Function to trigger the callback from the client-side
BCCCallbacks.Trigger = function(name, cb, ...)
    local requestId = generateRequestId()

    -- Register the event listener for receiving the response
    RegisterNetEvent('BCCCallbacks:Response')
    AddEventHandler('BCCCallbacks:Response', function(respRequestId, response)
        if requestId == respRequestId then
            cb(response) -- Execute the callback with the server response
        end
    end)

    -- Send the request to the server with the request ID
    TriggerServerEvent('BCCCallbacks:Request', name, requestId, ...)
end

-- Handle player death and close menu
function HandlePlayerDeathAndCloseMenu()
    local playerPed = PlayerPedId()

    -- Check if the player is already dead
    if IsEntityDead(playerPed) then
        devPrint("Player is dead, closing the crafting menu.")
        BCCCraftingMenu:Close() -- Close the menu if the player is dead
        return true            -- Return true to indicate the player is dead and the menu was closed
    end

    -- If the player is not dead, start monitoring for death while the menu is open
    CreateThread(function()
        while true do
            if IsEntityDead(playerPed) then
                devPrint("Player died while in the menu, closing the crafting menu.")
                BCCCraftingMenu:Close() -- Close the menu if the player dies while in the menu
                break                 -- Stop the loop since the player is dead and the menu is closed
            end
            Wait(1000)                 -- Check every second
        end
    end)

    devPrint("Player is alive, crafting menu can be opened.")
    return false -- Return false to indicate the player is alive and the menu can open
end

-- On the client, you can now trigger the crafting attempt with a callback
function attemptCraftItem(item)
    BCCCallbacks.Trigger('bcc-crafting:attemptCraft', function(success)
        if success then
            print("Crafting started successfully.")
        else
            print("Failed to start crafting.")
        end
    end, item)
end

-- Function to calculate the remaining XP needed for the next level
function GetRemainingXP(currentXP, level)
    local totalXPForNextLevel = (level * 1000) -- Assuming 1000 XP is needed per level
    return totalXPForNextLevel - currentXP
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

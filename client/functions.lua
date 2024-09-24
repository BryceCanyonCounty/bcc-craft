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

function attemptCraftItem(item)
    devPrint("Attempting to craft item: " .. item.itemLabel)
    -- Trigger server event to attempt crafting
    TriggerServerEvent('bcc-crafting:attemptCraft', item)
end

-- Handle level up notification
RegisterNetEvent('bcc-crafting:levelUp')
AddEventHandler('bcc-crafting:levelUp', function(newLevel)
    devPrint("Player leveled up! New crafting level: " .. newLevel)
    VORPcore.NotifyRightTip("Congratulations! You have reached crafting level " .. newLevel)
end)

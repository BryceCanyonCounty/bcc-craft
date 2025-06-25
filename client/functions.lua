-- Pulling Essentials
VORPcore = exports.vorp_core:GetCore()

FeatherMenu = exports["feather-menu"].initiate()
BccUtils = exports["bcc-utils"].initiate()
progressbar = exports["feather-progressbar"]:initiate()

BCCCraftingMenu = FeatherMenu:RegisterMenu("bcc:crafting:mainmenu",
    {
        top = '3%',
        left = '3%',
        ['720width'] = '400px',
        ['1080width'] = '500px',
        ['2kwidth'] = '600px',
        ['4kwidth'] = '800px',
        style = {
            --['background-image'] = 'url("nui://bcc-craft/assets/background.png")',
            --['background-size'] = 'cover',  
            --['background-repeat'] = 'no-repeat',
                --['background-position'] = 'center',
                --['background-color'] = 'rgba(55, 33, 14, 0.7)', -- A leather-like brown
                --['border'] = '1px solid #654321', 
                --['font-family'] = 'Times New Roman, serif', 
                --['font-size'] = '38px',
                --['color'] = '#ffffff', 
                --['padding'] = '10px 20px',
                --['margin-top'] = '5px',
                --['cursor'] = 'pointer', 
                --['box-shadow'] = '3px 3px #333333', 
                --['text-transform'] = 'uppercase', 
        },
        contentslot = {
            style = {
                ['height'] = '450px',
                ['min-height'] = '300px'
            }
        },
    },
    {
        opened = function()
            DisplayRadar(false)
        end,
        closed = function()
            DisplayRadar(true)
            cleanupCampfireIfExists()
        end
    }
)

-- Helper function for debugging in DevMode
if Config.devMode then
    function devPrint(message)
       print("^1[DEV MODE]^3 " .. message .. "^0")
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
    item.itemAmount = tonumber(amount)
    local ped = PlayerPedId()
    local durationMs = (tonumber(item.duration)) * item.itemAmount * 1000
    devPrint("[CRAFTING] Total crafting duration in milliseconds: " .. tostring(durationMs))
    devPrint("[CLIENT] Sending item to CanCraft: " .. json.encode(item))
    BccUtils.RPC:Call("bcc-crafting:CanCraft", { item = item, locationId = currentCraftingLocationId }, function(canCraft, message)
        if not canCraft then
            --VORPcore.NotifyRightTip("Cannot start crafting.", 4000)
            return
        end

        isCrafting = true

        if item.playAnimation then
            PlayAnim("mech_inventory@crafting@fallbacks@in_hand@male_a", "craft_trans_hold", durationMs)

            progressbar.onCancel(function()
                isCrafting = false
                ClearPedTasks(ped)
                SetNuiFocus(false, false)
                FeatherMenu:Notify({
                    message = _U("CraftingCanceled"),
                    type = "error",
                    autoClose = 4000,
                    position = "bottom-center",
                    icon = false,
                    hideProgressBar = false,
                    rtl = false,
                    transition = "slide",
                    style = {},
                    toastStyle = {},
                    progressStyle = {}
                })
                TriggerEvent('bcc-crafting:openmenu', currentLocationCategories)
            end)

            progressbar.start(
                _U("craftingItem") .. item.itemLabel .. " x" .. item.itemAmount ..". ESC pentru a anula",
                durationMs,
                function()
                    if not isCrafting then return end
                    isCrafting = false
                    ClearPedTasks(ped)

                    -- Now do the real crafting
                    BccUtils.RPC:Call("bcc-crafting:AttemptCraft", { item = item, locationId = currentCraftingLocationId }, function(success, err)
                        if success then
                            FeatherMenu:Notify({
                                message = _U("CraftingComplete"),
                                type = "success",
                                autoClose = 4000,
                                position = "bottom-center",
                                icon = false,
                                hideProgressBar = false,
                                rtl = false,
                                transition = "slide",
                                style = {},
                                toastStyle = {},
                                progressStyle = {}
                            })
                        else
                            FeatherMenu:Notify({
                                message = _U("CraftingFailed"),
                                type = "error",
                                autoClose = 4000,
                                position = "bottom-center",
                                icon = false,
                                hideProgressBar = false,
                                rtl = false,
                                transition = "slide",
                                style = {},
                                toastStyle = {},
                                progressStyle = {}
                            })
                        end
                        TriggerEvent('bcc-crafting:openmenu', currentLocationCategories)
                    end)
                end,
                'innercircle',
                '#bb8844',
                '22vw',
                true
            )

            SetNuiFocus(true, true)
            Wait(50)
            SetNuiFocus(false, false)
        else
            -- No animation, do crafting immediately
            BccUtils.RPC:Call("bcc-crafting:AttemptCraft", { item = item, locationId = currentCraftingLocationId }, function(success, err)
                if success then
                    FeatherMenu:Notify({
                        message = "Crafting started successfully for " .. item.itemLabel,
                        type = "success",
                        autoClose = 4000,
                        position = "bottom-center",
                        icon = false,
                        hideProgressBar = false,
                        rtl = false,
                        transition = "slide",
                        style = {},
                        toastStyle = {},
                        progressStyle = {}
                    })
                else
                    FeatherMenu:Notify({
                        message = "Failed to start crafting",
                        type = "error",
                        autoClose = 4000,
                        position = "bottom-center",
                        icon = false,
                        hideProgressBar = false,
                        rtl = false,
                        transition = "slide",
                        style = {},
                        toastStyle = {},
                        progressStyle = {}
                    })  
                end
                TriggerEvent('bcc-crafting:openmenu', currentLocationCategories)
            end)
        end
    end)
end

-- Function to fetch item limit using RPC
function fetchItemLimit(itemName, cb)
    devPrint("Requesting item limit for:", tostring(itemName)) -- Debug the itemName

    -- Validate the itemName
    if not itemName or itemName == "" then
        devPrint("[ERROR] itemName is nil or empty in fetchItemLimit")
        cb("N/A") -- Immediately return "N/A" if no valid itemName
        return
    end

    -- Check if the item is a weapon
    if string.sub(itemName:lower(), 1, string.len("weapon_")) == "weapon_" then
        devPrint("[DEBUG] Item is a weapon, fetching weapon limit for:", tostring(itemName))

        -- Make the RPC call to fetch the weapon limit
        BccUtils.RPC:Call("bcc-crafting:getWeaponLimit", {}, function(canCarry)
            if canCarry then
                devPrint("[DEBUG] Weapon limit check passed for:", tostring(itemName))
                cb("Unlimited") -- Weapons have no limit
            else
                devPrint("[ERROR] Weapon limit reached for:", tostring(itemName))
                cb("LimitReached") -- Indicate that the weapon limit is reached
            end
        end)
        return
    end

    -- Make the RPC call to fetch the item limit for non-weapons
    BccUtils.RPC:Call("bcc-crafting:getItemLimit", { itemName = itemName }, function(itemLimit)
        if not itemLimit then
            devPrint("[ERROR] Failed to retrieve item limit for item:", tostring(itemName))
            cb("N/A")
            return
        end

        devPrint("[DEBUG] Item limit received for", tostring(itemName), ":", tostring(itemLimit))
        cb(itemLimit) -- Pass the item limit to the provided callback
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
    FeatherMenu:Notify({
        message = "Congratulations! You have reached crafting level " .. newLevel,
        type = "success",
        autoClose = 4000,
        position = "bottom-center",
        icon = false,
        hideProgressBar = false,
        rtl = false,
        transition = "slide",
        style = {},
        toastStyle = {},
        progressStyle = {}
    })
end)

function PlayAnim(dict, anim, duration)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, -8.0, duration or -1, 1, 0, false, false, false)
end

function cleanupCampfireIfExists()
    if myCampfire and DoesEntityExist(myCampfire) then
        NetworkRequestControlOfEntity(myCampfire)
        while not NetworkHasControlOfEntity(myCampfire) do
            Wait(10)
        end
        DeleteObject(myCampfire)
        myCampfire = nil
        devPrint("Campfire cleaned up")
        ClearPedTasksImmediately(PlayerPedId())
    end
end

local CreatedBlip = {}
local CreatedNpc = {}

CreateThread(function()
    devPrint("Thread started")  -- Devprint

    local CraftingMenuPrompt = BccUtils.Prompts:SetupPromptGroup()

    local craftingprompt = CraftingMenuPrompt:RegisterPrompt(_U('PromptName'), 0x760A9C6F, 1, 1, true, 'hold', { timedeventhash = 'MEDIUM_TIMED_EVENT' })
    if Config.CraftingBlips then
        devPrint("Config.CraftingBlips is enabled")  -- Devprint
        for _, v in pairs(Config.CraftingLocations) do
            local CraftingBlip = BccUtils.Blips:SetBlip(_U('BlipName'), 'blip_job_board', 3.2, v.coords.x, v.coords.y, v.coords.z)
            if CraftingBlip then
                devPrint("NPC created successfully at: " .. tostring(v.coords))
            else
                devPrint("Failed to create NPC at: " .. tostring(v.coords))
            end
            CreatedBlip[#CreatedBlip + 1] = CraftingBlip
        end
    else
        devPrint("Config.CraftingBlips is disabled")  -- Devprint
    end

    if Config.CraftingNPC then
        devPrint("Config.CraftingNPC is enabled")  -- Devprint
        for _, v in pairs(Config.CraftingLocations) do
            local craftingped = BccUtils.Ped:Create('MP_POST_RELAY_MALES_01', v.coords.x, v.coords.y, v.coords.z - 1.0, 0, 'world', false)
            if craftingped then
                devPrint("NPC created successfully at: " .. tostring(v.coords))
            else
                devPrint("Failed to create NPC at: " .. tostring(v.coords))
            end
            CreatedNpc[#CreatedNpc + 1] = craftingped
            craftingped:Freeze()
            craftingped:SetHeading(v.NpcHeading)
            craftingped:Invincible()
        end
        
    else
        devPrint("Config.CraftingNPC is disabled")  -- Devprint
    end

    while true do
        Wait(1)
        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, v in pairs(Config.CraftingLocations) do
            local dist = #(playerCoords - v.coords)
            if dist < 2 then
                CraftingMenuPrompt:ShowGroup(_U('CraftBook'))
                if craftingprompt:HasCompleted() then
                    devPrint("Crafting prompt has been completed")  -- Devprint
                    TriggerEvent('bcc-crafting:openmenu')
                end
            end
        end
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        for _, v in pairs(CreatedBlip) do
            v:Remove()
        end
        for _, v in pairs(CreatedNpc) do
            v:Remove()
        end
    end
end)


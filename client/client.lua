CreatedBlip = {}
CreatedNpc = {}

CreateThread(function()
    devPrint("Thread started") -- Devprint

    local CraftingMenuPrompt = BccUtils.Prompts:SetupPromptGroup()

    local craftingprompt = CraftingMenuPrompt:RegisterPrompt(_U('PromptName'), 0x760A9C6F, 1, 1, true, 'hold',
        { timedeventhash = 'MEDIUM_TIMED_EVENT' })

    -- Iterate over CraftingLocations from the config
    for _, location in pairs(CraftingLocations) do
        -- Ensure the 'coords' and 'NpcHeading' are arrays, so we can loop over multiple locations
        if type(location.coords) == "table" and type(location.NpcHeading) == "table" then
            for i, coord in ipairs(location.coords) do
                local heading = location.NpcHeading[i] -- Get the corresponding NPC heading

                -- Handle Crafting Blips
                if location.blip and location.blip.show then
                    local CraftingBlip = BccUtils.Blips:SetBlip(location.blip.label, location.blip.sprite,
                    location.blip.scale, coord.x, coord.y, coord.z)
                    local blipModifier = BccUtils.Blips:AddBlipModifier(CraftingBlip, location.blip.color)
                    blipModifier:ApplyModifier()
                    CreatedBlip[#CreatedBlip + 1] = CraftingBlip
                else
                    devPrint("Blips disabled for location: " .. tostring(coord))
                end

                -- Handle Crafting NPCs
                if location.npc and location.npc.show then
                    craftingped = BccUtils.Ped:Create(location.npc.model, coord.x, coord.y, coord.z -1, 0, 'world',false)
                    CreatedNpc[#CreatedNpc + 1] = craftingped
                    craftingped:Freeze()
                    craftingped:SetHeading(heading)
                    craftingped:Invincible()
                else
                    devPrint("NPCs disabled for location: " .. tostring(coord))
                end
            end
        else
            devPrint("Error: 'coords' or 'NpcHeading' is not a table for location.")
        end
    end

    while true do
        Wait(1)
        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, location in pairs(CraftingLocations) do
            -- Loop through all coordinates for this location
            if type(location.coords) == "table" then
                for _, coord in ipairs(location.coords) do
                    local dist = #(playerCoords - coord)
                    if dist < 2 then
                        -- Show the crafting prompt with the label from the blip table
                        CraftingMenuPrompt:ShowGroup(location.blip.label) -- Show prompt with the dynamic label

                        if craftingprompt:HasCompleted() then
                            devPrint("Crafting prompt has been completed") -- Devprint
                            -- Trigger the menu with location-specific categories
                            TriggerEvent('bcc-crafting:openmenu', location.categories)
                        end
                    end
                end
            end
        end
    end
end)

-- Cleanup when the resource stops
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

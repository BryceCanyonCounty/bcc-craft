CraftingLocations = CraftingLocations or {}

local others = {
    ---- OIL REFINERY - OIL LANDS ----
    {
        locationId = "refinery",
		craftbookCategory = "refinery_craftbook",
        coords = {
            vector3(488.98, 671.69, 117.34)
        },
        NpcHeading = {
            311.52
        },
        blip = {
            show = false,
            sprite = 669307703,
            color = "BLIP_MODIFIER_MP_COLOR_32",
            scale = 0.6,
            label = "Refinery",
        },
        npc = {
            model = "S_M_M_StrLumberjack_01",
            name = "Refinery Worker",
            show = true,
        },
        categories = {
            {
                name = "refinery",
                label = "Refinery",
                craftBookItem = "",
                campfireModel = "p_campfire03x",
                setupAnimDict = "mini_games@story@beechers@build_floor@john",
                setupAnimName = "hammer_loop_good",
                setupScenario = "WORLD_HUMAN_WRITE_NOTEBOOK",
                setupTime = 5000,
                items = {
                    {
                        itemName = "trainoil",
                        itemLabel = "Train Oil",
                        requiredJobs = false,
                        rewardXP = 10,
                        requiredLevel = 3,
                        itemAmount = 1,
                        duration = 40,
                        requiredItems = {
                            { itemName = "petroleum", itemLabel = "Crude Oil", itemCount = 10, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "petrol",
                        itemLabel = "Petrol",
                        requiredJobs = false,
                        rewardXP = 10,
                        requiredLevel = 3,
                        itemAmount = 1,
                        duration = 40,
                        requiredItems = {
                            { itemName = "petroleum", itemLabel = "Crude Oil", itemCount = 10, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    }
                }
            }
        }
    },
    ---- TOBACCO ----
    {
        locationId = "tobacco",
        coords = {
            vector3(-1822.61, -2425.92, 42.42)
        },
        NpcHeading = {
            50.12
        },
        blip = {
            show = true,
            sprite = 1192138201,
            color = "BLIP_MODIFIER_MP_COLOR_32",
            scale = 1.0,
            label = "Tobacco",
        },
        npc = {
            model = "CS_Magnifico",
            name = "Tobacco Vendor",
            show = true,
        },
        categories = {
            {
                name = "loose_tobacco",
                label = "Tobacco",
                craftBookItem = "",
                campfireModel = "p_campfire03x",
                setupAnimDict = "mini_games@story@beechers@build_floor@john",
                setupAnimName = "hammer_loop_good",
                setupScenario = "WORLD_HUMAN_WRITE_NOTEBOOK",
                setupTime = 5000,
                items = {
                    {
                        itemName = "tobaccopipe",
                        itemLabel = "Dried Tobacco",
                        requiredJobs = false,
                        rewardXP = 5,
                        requiredLevel = 5,
                        itemAmount = 3,
                        duration = 30,
                        requiredItems = {
                            { itemName = "tobacco_leafs", itemLabel = "Tobacco Leaves", itemCount = 1, removeItem = true }
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "cigar",
                        itemLabel = "Cigar",
                        requiredJobs = false,
                        rewardXP = 10,
                        requiredLevel = 10,
                        itemAmount = 1,
                        duration = 40,
                        requiredItems = {
                            { itemName = "tobaccopipe", itemLabel = "Dried Tobacco", itemCount = 3, removeItem = true }
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "cigarette",
                        itemLabel = "Cigarette",
                        requiredJobs = false,
                        rewardXP = 10,
                        requiredLevel = 3,
                        itemAmount = 5,
                        duration = 40,
                        requiredItems = {
                            { itemName = "tobaccopipe",  itemLabel = "Dried Tobacco", itemCount = 5, removeItem = true },
                            { itemName = "rollingpaper", itemLabel = "Rolling Paper", itemCount = 5, removeItem = true }
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "cigaret",
                        itemLabel = "Cigarette Pack",
                        requiredJobs = false,
                        rewardXP = 10,
                        requiredLevel = 3,
                        itemAmount = 1,
                        duration = 40,
                        requiredItems = {
                            { itemName = "cigarette", itemLabel = "Cigarette", itemCount = 10, removeItem = true },
                            { itemName = "paper",     itemLabel = "Paper",     itemCount = 1,  removeItem = true }
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    }
                }
            }
        }
    },
}

-- Add all locations from this list to the global CraftingLocations
for _, location in ipairs(others) do
    table.insert(CraftingLocations, location)
end

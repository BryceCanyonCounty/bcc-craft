CraftingLocations = CraftingLocations or {}

local weapons = {
    {
        locationId = "weapons",
		craftbookCategory = "weapons_craftbook",
        craftbookprice = true,
        craftbookpricegold = 150,
        craftbookpricemoney = 15000,
        craftbookpricexp = 90000,
        coords = {
            vector3(414.96, -1275.21, 41.76)
        },
        NpcHeading = {
            281.73,
        },
        blip = {
            show = false,
            sprite = 549686661,
            color = "BLIP_MODIFIER_MP_COLOR_16",
            scale = 0.6,
            label = "Weapon Assembly",
        },
        npc = {
            model = "S_M_M_StrLumberjack_01",
            name = "Weapon Assembler",
            show = false,
        },
        categories = {
            {
                name = "melee",
                label = "Melee Weapons",
                craftBookItem = "",
                campfireModel = "p_campfire03x",
                craftbookprice = true,
                craftbookpricegold = 75,
                craftbookpricemoney = 9000,
                craftbookpricexp = 60000,
                setupAnimDict = "mini_games@story@beechers@build_floor@john",
                setupAnimName = "hammer_loop_good",
                setupScenario = "WORLD_HUMAN_WRITE_NOTEBOOK",
                setupTime = 5000,
                items = {
                    {
                        itemName = "WEAPON_MELEE_KNIFE",
                        itemLabel = "Knife",
                        requiredJobs = false,
                        rewardXP = 10,
                        requiredLevel = 1,
                        itemAmount = 1,
                        duration = 15,
			neededItems = {     -- or false
                            { itemName = "hammer", itemLabel = "Hammer" },
                        },
                        requiredItems = {
                            { itemName = "knivehandle", itemLabel = "Knife Handle", itemCount = 1, removeItem = true },
                            { itemName = "ironbar", itemLabel = "Iron Ingot", itemCount = 1, removeItem = true },
                            { itemName = "nails", itemLabel = "Nails", itemCount = 1, removeItem = true },
                            { itemName = "ironhammer", itemLabel = "Iron Hammer", itemCount = 1, removeItem = false },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "WEAPON_MELEE_LANTERN",
                        itemLabel = "Lantern",
                        requiredJobs = false,
                        rewardXP = 10,
                        requiredLevel = 1,
                        itemAmount = 1,
                        duration = 15,
			neededItems = {     -- or false
                            { itemName = "hammer", itemLabel = "Hammer" },
                        },
                        requiredItems = {
                            { itemName = "ironbar", itemLabel = "Iron Ingot", itemCount = 1, removeItem = true },
                            { itemName = "copperbar", itemLabel = "Copper Ingot", itemCount = 1, removeItem = true },
                            { itemName = "rope", itemLabel = "Rope", itemCount = 1, removeItem = true },
                            { itemName = "trainoil", itemLabel = "Oil", itemCount = 1, removeItem = true },
                            { itemName = "pliers", itemLabel = "Pliers", itemCount = 1, removeItem = false }
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "WEAPON_MELEE_DAVY_LANTERN",
                        itemLabel = "Davy Lantern",
                        requiredJobs = false,
                        rewardXP = 10,
                        requiredLevel = 1,
                        itemAmount = 1,
                        duration = 15,
			neededItems = {     -- or false
                            { itemName = "hammer", itemLabel = "Hammer" },
                        },
                        requiredItems = {
                            { itemName = "ironbar", itemLabel = "Iron Ingot", itemCount = 2, removeItem = true },
                            { itemName = "copperbar", itemLabel = "Copper Ingot", itemCount = 2, removeItem = true },
                            { itemName = "rope", itemLabel = "Rope", itemCount = 1, removeItem = true },
                            { itemName = "trainoil", itemLabel = "Oil", itemCount = 1, removeItem = true },
                            { itemName = "pliers", itemLabel = "Pliers", itemCount = 1, removeItem = false }
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    }
                }
            },
            {
                name = "revolvers",
                label = "Revolvers",
                craftBookItem = "",
                campfireModel = "p_campfire03x",
                craftbookprice = true,
                craftbookpricegold = 75,
                craftbookpricemoney = 9000,
                craftbookpricexp = 60000,
                setupAnimDict = "mini_games@story@beechers@build_floor@john",
                setupAnimName = "hammer_loop_good",
                setupScenario = "WORLD_HUMAN_WRITE_NOTEBOOK",
                setupTime = 5000,
                items = {
                    {
                        itemName = "WEAPON_REVOLVER_NAVY",
                        itemLabel = "Navy Revolver",
                        requiredJobs = false,
                        rewardXP = 20,
                        requiredLevel = 5,
                        itemAmount = 1,
                        duration = 15,
			neededItems = {     -- or false
                            { itemName = "hammer", itemLabel = "Hammer" },
                        },
                        requiredItems = {
                            { itemName = "revolverbarrel", itemLabel = "Revolver Barrel", itemCount = 1, removeItem = true },
                            { itemName = "revolvercylinder", itemLabel = "Revolver Cylinder", itemCount = 1, removeItem = true },
                            { itemName = "revolverhandle", itemLabel = "Revolver Handle", itemCount = 1, removeItem = true },
                            { itemName = "screwdriver", itemLabel = "Screwdriver", itemCount = 1, removeItem = false },
                            { itemName = "pliers", itemLabel = "Pliers", itemCount = 1, removeItem = false },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "WEAPON_REVOLVER_LEMAT",
                        itemLabel = "LeMat Revolver",
                        requiredJobs = false,
                        rewardXP = 20,
                        requiredLevel = 5,
                        itemAmount = 1,
                        duration = 15,
			neededItems = {     -- or false
                            { itemName = "hammer", itemLabel = "Hammer" },
                        },
                        requiredItems = {
                            { itemName = "revolverbarrel", itemLabel = "Revolver Barrel", itemCount = 1, removeItem = true },
                            { itemName = "revolvercylinder", itemLabel = "Revolver Cylinder", itemCount = 1, removeItem = true },
                            { itemName = "revolverhandle", itemLabel = "Revolver Handle", itemCount = 1, removeItem = true },
                            { itemName = "screwdriver", itemLabel = "Screwdriver", itemCount = 1, removeItem = false },
                            { itemName = "pliers", itemLabel = "Pliers", itemCount = 1, removeItem = false },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "WEAPON_REVOLVER_SCHOFIELD",
                        itemLabel = "Schofield Revolver",
                        requiredJobs = false,
                        rewardXP = 10,
                        requiredLevel = 3,
                        itemAmount = 1,
                        duration = 15,
			neededItems = {     -- or false
                            { itemName = "hammer", itemLabel = "Hammer" },
                        },
                        requiredItems = {
                            { itemName = "revolverbarrel", itemLabel = "Revolver Barrel", itemCount = 1, removeItem = true },
                            { itemName = "revolvercylinder", itemLabel = "Revolver Cylinder", itemCount = 1, removeItem = true },
                            { itemName = "revolverhandle", itemLabel = "Revolver Handle", itemCount = 1, removeItem = true },
                            { itemName = "screwdriver", itemLabel = "Screwdriver", itemCount = 1, removeItem = false },
                            { itemName = "pliers", itemLabel = "Pliers", itemCount = 1, removeItem = false },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "WEAPON_REVOLVER_CATTLEMAN",
                        itemLabel = "Cattleman Revolver",
                        requiredJobs = false,
                        rewardXP = 10,
                        requiredLevel = 5,
                        itemAmount = 1,
                        duration = 15,
			neededItems = {     -- or false
                            { itemName = "hammer", itemLabel = "Hammer" },
                        },
                        requiredItems = {
                            { itemName = "revolverbarrel", itemLabel = "Revolver Barrel", itemCount = 1, removeItem = true },
                            { itemName = "revolvercylinder", itemLabel = "Revolver Cylinder", itemCount = 1, removeItem = true },
                            { itemName = "revolverhandle", itemLabel = "Revolver Handle", itemCount = 1, removeItem = true },
                            { itemName = "screwdriver", itemLabel = "Screwdriver", itemCount = 1, removeItem = false },
                            { itemName = "pliers", itemLabel = "Pliers", itemCount = 1, removeItem = false },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    }
                }
            }
        }
    }
}

for _, location in ipairs(weapons) do
    table.insert(CraftingLocations, location)
end

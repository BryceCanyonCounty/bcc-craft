CraftingLocations = CraftingLocations or {}

local food = {
    {
        locationId = "food",
        coords = {
            vector3(-2396.4, -2387.94, 61.46),
            vector3(2543.07, 800.81, 76.37),
            vector3(-359.41, 735.95, 116.87)
        },
        NpcHeading = {
            133.65,
            13.63,
            120.53
        },
        blip = {
            show = true,
            sprite = -1852063472,
            color = "BLIP_MODIFIER_MP_COLOR_14",
            scale = 0.8,
            label = "Cook Food",
        },
        npc = {
            model = "S_M_M_StrLumberjack_01",
            name = "Food Vendor",
            show = true,
            scenario = "WORLD_HUMAN_WRITE_NOTEBOOK",
            anim = {
                dict = '',
                name = ''
            }
        },
        categories = {
            {
                name = "meat",
                label = "Meat Dishes",
                craftBookItem = "food_craftbook",
                campfireModel = "p_campfire03x",
                setupAnimDict = "mini_games@story@beechers@build_floor@john",
                setupAnimName = "hammer_loop_good",
                setupScenario = "WORLD_HUMAN_WRITE_NOTEBOOK",
                setupTime = 5000,
                items = {
                    {
                        itemName = "consumable_breakfast",
                        itemLabel = "Breakfast",
                        rewardXP = 1,
                        requiredLevel = 1,
                        itemAmount = 1,
                        duration = 10,
                        requiredItems = {
                            { itemName = "meat", itemLabel = "Meat", itemCount = 1, removeItem = true },
                            { itemName = "egg", itemLabel = "Egg", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false
                    },
                    {
                        itemName = "steak",
                        itemLabel = "Grilled Meat",
                        rewardXP = 1,
                        requiredLevel = 1,
                        itemAmount = 1,
                        duration = 10,
                        requiredItems = {
                            { itemName = "meat", itemLabel = "Meat", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false
                    },
                    {
                        itemName = "cooked_biggame",
                        itemLabel = "Salted Big Game Dish",
                        rewardXP = 1,
                        requiredLevel = 1,
                        itemAmount = 1,
                        duration = 10,
                        requiredItems = {
                            { itemName = "biggame", itemLabel = "Big Game Meat", itemCount = 1, removeItem = true },
                            { itemName = "salt", itemLabel = "Salt", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false,
                    },
                    {
                        itemName = "cooked_game",
                        itemLabel = "Salted Game Dish",
                        rewardXP = 1,
                        requiredLevel = 1,
                        itemAmount = 1,
                        duration = 10,
                        requiredItems = {
                            { itemName = "game", itemLabel = "Game Meat", itemCount = 1, removeItem = true },
                            { itemName = "salt", itemLabel = "Salt", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false
                    },
                    {
                        itemName = "cooked_venison",
                        itemLabel = "Venison Dish",
                        rewardXP = 1,
                        requiredLevel = 1,
                        itemAmount = 1,
                        duration = 10,
                        requiredItems = {
                            { itemName = "venison", itemLabel = "Venison", itemCount = 1, removeItem = true },
                            { itemName = "salt", itemLabel = "Salt", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false
                    },
                    {
                        itemName = "cooked_mutton",
                        itemLabel = "Mutton Dish",
                        rewardXP = 1,
                        requiredLevel = 1,
                        itemAmount = 1,
                        duration = 10,
                        requiredItems = {
                            { itemName = "Mutton", itemLabel = "Mutton", itemCount = 1, removeItem = true },
                            { itemName = "salt", itemLabel = "Salt", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false
                    },
                    {
                        itemName = "cooked_pork",
                        itemLabel = "Pork Dish",
                        rewardXP = 1,
                        requiredLevel = 1,
                        itemAmount = 1,
                        duration = 10,
                        requiredItems = {
                            { itemName = "pork", itemLabel = "Pork", itemCount = 1, removeItem = true },
                            { itemName = "salt", itemLabel = "Salt", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false
                    },
                    {
                        itemName = "cooked_bird",
                        itemLabel = "Bird Meat Dish",
                        rewardXP = 1,
                        requiredLevel = 1,
                        itemAmount = 1,
                        duration = 10,
                        requiredItems = {
                            { itemName = "bird", itemLabel = "Bird Meat", itemCount = 1, removeItem = true },
                            { itemName = "salt", itemLabel = "Salt", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false
                    },
                    {
                        itemName = "consumable_bluegil",
                        itemLabel = "Fish Dish",
                        rewardXP = 1,
                        requiredLevel = 1,
                        itemAmount = 1,
                        duration = 10,
                        requiredItems = {
                            { itemName = "fish", itemLabel = "Fish", itemCount = 1, removeItem = true },
                            { itemName = "salt", itemLabel = "Salt", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false
                    }
                }
            }
        }
    },
}

-- Use table unpacking to add multiple locations
for _, location in ipairs(food) do
    table.insert(CraftingLocations, location)
end

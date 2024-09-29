CraftingLocations = CraftingLocations or {}

local food = {
    {
        coords = {
            vector3(231.87, 530.09, 116.27)
        },
        NpcHeading = {
            168.10
        },
        blip = {
            show = true,                         -- Toggle the blip on/off
            sprite = -1954662204,                -- Blip sprite (icon)
            color = 2,                           -- Blip color
            scale = 0.8,                         -- Blip scale
            label = "Food Crafting Station",     -- Blip label
        },
        npc = {
            model = "A_M_M_Rancher_01",     -- NPC model
            name = "Crafting Vendor",
            show = true                     -- Toggle the NPC on/off
        },
        categories = {                      -- Categories available at this location
            {
                name = "food",
                label = "Food",
                craftBookItem = "food_craftbook",     -- Unique craftbook item for the Food category
                items = {
                    {
                        itemName = "consumable_meal",
                        itemLabel = "Consumable Meal",
                        requiredJobs = {     -- Define the required jobs for this item
                            --{ name = "butcher", grade = 1 },
                            --{ name = "chef", grade = 2 }
                        },
                        rewardXP = 5,
                        requiredLevel = 0,
                        itemAmount = 1,
                        duration = 1200,
                        requiredItems = {
                            { itemName = "sugarcube",  itemLabel = "Sugar Cube",   itemCount = 2, removeItem = true },
                            { itemName = "bagofflour", itemLabel = "Bag of Flour", itemCount = 1, removeItem = true },
                            { itemName = "salt",       itemLabel = "Salt",         itemCount = 2, removeItem = false },
                            { itemName = "milk",       itemLabel = "Milk",         itemCount = 1, removeItem = true }
                        }
                    },
                }
            },
            {
                name = "weapons",
                label = "Weapons",
                craftBookItem = "weapons_craftbook",     -- Unique craftbook item for the Weapons category
                items = {
                    -- Weapon crafting items would be defined here
                }
            }
        }
    },
}
-- Use table unpacking to add multiple locations
for _, location in ipairs(food) do
    table.insert(CraftingLocations, location)
end

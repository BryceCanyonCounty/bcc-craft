Config = {
    -- Language setting
    defaultlang = 'en_lang',

    -- Development mode toggle
    devMode = true,  -- Set to false on a live server
    
    -- Discord Webhooks
    WebhookLink = 'https://discord.com/api/webhooks/1287854127518453874/_5Ni9v8SkhmC0CcZvdUkq2qAqovRb4iFUkLMxaMtCNUEAvD2xtS6oWGfwtpHkoUOz1BW', --insert your webhook link here if you want webhooks
    WebhookTitle = 'BCC-Craft',
    WebhookAvatar = '',

    -- Toggle visibility of crafting related blips
    CraftingBlips = true,

    -- Toggle NPCs for crafting stations
    CraftingNPC = true,

    -- Crafting location coordinates and NPC heading
    CraftingLocations = {
        {
            coords = vector3(231.87, 530.09, 116.27),
            NpcHeading = 168.10,
        },
    },

    -- Image settings for the crafting menu
    UseImageAtBottomMenu = false,
    craftImageURL = "",  -- Add your desired image URL here

    -- Crafting categories with unique craftbook identifiers
    CraftingCategories = {
        {
            name = "food",
            label = "Food",
            craftBookItem = "food_craftbook",  -- Unique craftbook item for the Food category
            items = {
                {
                    itemName = "consumable_plumcake",
                    itemLabel = "Consumable Plumcake",
                    requiredJobs = false,
                    rewardXP = 5,
                    requiredLevel = 0,
                    itemAmount = 10,
                    duration = 1200,
                    lucky = 100,
                    requiredItems = {
                        { itemName = "sugarcube", itemLabel = "Sugar Cube", itemCount = 2, dontremove = false },
                        { itemName = "bagofflour", itemLabel = "Bag of Flour", itemCount = 1, dontremove = false },
                        { itemName = "salt", itemLabel = "Salt", itemCount = 2, dontremove = false },
                        { itemName = "milk", itemLabel = "Milk", itemCount = 1, dontremove = false }
                    }
                },
                -- Additional items can be added here...
            }
        },
        {
            name = "weapons",
            label = "Weapons",
            craftBookItem = "weapons_craftbook",  -- Unique craftbook item for the Weapons category
            items = {
                -- Weapon crafting items would be defined here
            }
        },
        {
            name = "items",
            label = "Items",
            craftBookItem = "items_craftbook",  -- Unique craftbook item for general items
            items = {
                -- General item crafting definitions go here
            }
        },
        {
            name = "others",
            label = "Others",
            craftBookItem = "others_craftbook",  -- Unique craftbook item for miscellaneous items
            items = {
                -- Miscellaneous crafting items would be defined here
            }
        }
    }
}

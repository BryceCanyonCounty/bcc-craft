Config = {
    -- Language setting
    defaultlang = 'en_lang',

    -- Development mode toggle
    devMode = false, -- Set to false on a live server

    -- Discord Webhooks
    WebhookLink = '',               --insert your webhook link here if you want webhooks
    WebhookTitle = 'BCC-Crafting',
    WebhookAvatar = '',

    LevelThresholds = {
        { minLevel = 1,   maxLevel = 10,  xpPerLevel = 1000 },
        { minLevel = 11,  maxLevel = 20,  xpPerLevel = 2000 },
        { minLevel = 21,  maxLevel = 30,  xpPerLevel = 3000 },
        { minLevel = 31,  maxLevel = 40,  xpPerLevel = 4000 },
        { minLevel = 41,  maxLevel = 50,  xpPerLevel = 5000 },
        { minLevel = 51,  maxLevel = 60,  xpPerLevel = 6000 },
        { minLevel = 61,  maxLevel = 70,  xpPerLevel = 7000 },
        { minLevel = 71,  maxLevel = 80,  xpPerLevel = 8000 },
        { minLevel = 81,  maxLevel = 90,  xpPerLevel = 9000 },
        { minLevel = 91,  maxLevel = 100, xpPerLevel = 10000 },
        { minLevel = 101, maxLevel = 110, xpPerLevel = 11000 },
        { minLevel = 111, maxLevel = 120, xpPerLevel = 12000 },
        { minLevel = 121, maxLevel = 130, xpPerLevel = 13000 },
        { minLevel = 131, maxLevel = 140, xpPerLevel = 14000 },
        { minLevel = 141, maxLevel = 150, xpPerLevel = 15000 },
        { minLevel = 151, maxLevel = 160, xpPerLevel = 16000 },
        { minLevel = 161, maxLevel = 170, xpPerLevel = 17000 },
        { minLevel = 171, maxLevel = 180, xpPerLevel = 18000 },
        { minLevel = 181, maxLevel = 190, xpPerLevel = 19000 },
        { minLevel = 191, maxLevel = 200, xpPerLevel = 20000 },
        { minLevel = 201, maxLevel = 210, xpPerLevel = 22000 },
        { minLevel = 211, maxLevel = 220, xpPerLevel = 24000 },
        { minLevel = 221, maxLevel = 230, xpPerLevel = 26000 },
        { minLevel = 231, maxLevel = 240, xpPerLevel = 28000 },
        { minLevel = 241, maxLevel = 250, xpPerLevel = 30000 },
        { minLevel = 251, maxLevel = 260, xpPerLevel = 32000 },
        { minLevel = 261, maxLevel = 270, xpPerLevel = 34000 },
        { minLevel = 271, maxLevel = 280, xpPerLevel = 36000 },
        { minLevel = 281, maxLevel = 290, xpPerLevel = 38000 },
        { minLevel = 291, maxLevel = 300, xpPerLevel = 40000 }
    },
	
    -- Adjust this based on your server's maximum allowed weapon count
    WeaponsLimit = 1,      -- Maximum weapons to craft at the time
    maxWeaponsAllowed = 5, -- Maximum weapons to collect when craft finished

    -- Image settings for the crafting menu
    UseImageAtBottomMenu = false,
    craftImageURL = "",            -- Add your desired image URL here

    allowGlobalCollection = false, -- true = can collect crafted items from anywhere
	
    HasCraftBooks = false,    --This will show a button to every location so they can buy craftbook from there

    -- If you want to use BCC-UserLog API's
    -- Global toggle for using playtime restrictions
    useBccUserlog = false

}

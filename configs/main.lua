Config = {
    -- Language setting
    defaultlang = 'en_lang',

    -- Development mode toggle
    devMode = false,  -- Set to false on a live server
    
    -- Discord Webhooks
    WebhookLink = '', --insert your webhook link here if you want webhooks
    WebhookTitle = 'BCC-Crafting',
    WebhookAvatar = '',

    LevelThresholds = {
        { minLevel = 1, maxLevel = 10, xpPerLevel = 1000 },
        { minLevel = 11, maxLevel = 20, xpPerLevel = 2000 },
        { minLevel = 21, maxLevel = 30, xpPerLevel = 3000 },
        { minLevel = 31, maxLevel = 40, xpPerLevel = 4000 },
        { minLevel = 41, maxLevel = 50, xpPerLevel = 5000 },
        { minLevel = 51, maxLevel = 60, xpPerLevel = 6000 },
        { minLevel = 61, maxLevel = 70, xpPerLevel = 7000 },
        { minLevel = 71, maxLevel = 80, xpPerLevel = 8000 },
        { minLevel = 81, maxLevel = 90, xpPerLevel = 9000 },
        { minLevel = 91, maxLevel = 100, xpPerLevel = 10000 },
        { minLevel = 101, maxLevel = 110, xpPerLevel = 11000 },
        { minLevel = 111, maxLevel = 120, xpPerLevel = 12000 },
        { minLevel = 121, maxLevel = 130, xpPerLevel = 13000 },
        { minLevel = 131, maxLevel = 140, xpPerLevel = 14000 },
        { minLevel = 141, maxLevel = 150, xpPerLevel = 15000 },
        { minLevel = 151, maxLevel = 160, xpPerLevel = 16000 },
        { minLevel = 161, maxLevel = 170, xpPerLevel = 17000 },
        { minLevel = 171, maxLevel = 180, xpPerLevel = 18000 },
        { minLevel = 181, maxLevel = 190, xpPerLevel = 19000 },
        { minLevel = 191, maxLevel = 200, xpPerLevel = 20000 }
    },    
    
    -- Image settings for the crafting menu
    UseImageAtBottomMenu = false,
    craftImageURL = "",  -- Add your desired image URL here

}

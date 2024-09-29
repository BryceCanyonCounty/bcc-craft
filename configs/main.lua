Config = {
    -- Language setting
    defaultlang = 'en_lang',

    -- Development mode toggle
    devMode = false,  -- Set to false on a live server
    
    -- Discord Webhooks
    WebhookLink = '', --insert your webhook link here if you want webhooks
    WebhookTitle = 'BCC-Crafting',
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

}

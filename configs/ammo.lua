-- Guide for Adding New Crafting Locations
-- You can create a new crafting location by copying and modifying an existing template such as for food or weapons.

-- Step-by-step Instructions:

-- 1. Define a new local variable for the crafting location.
--    This will hold all the necessary data for the location, including coordinates, NPC details, blip settings, 
--    and the crafting categories and items available at that location.
-- 

-- 2. After defining the new location, use table unpacking to add it to the `Config.CraftingLocations`.
--    This ensures that the new location is inserted properly into the existing crafting system.
-- 

-- 3. Copy and customize this structure as needed. Be sure to update all the relevant details such as item names, coordinates, NPCs, blips, and crafting requirements.


-- 4. You can create as many configuration files as you need inside a configs folder. 
--		This approach helps to avoid having one large Config file, making it easier to manage and organize the settings. 
--		Each file can contain specific configurations (e.g., crafting locations, categories) and will automatically add to the main Config.CraftingLocations table without overriding other settings.
--		This allows for a cleaner and more modular setup.

CraftingLocations = CraftingLocations or {}

local ammunitions = {
    {
        locationId = "ammunitions",
        craftbookCategory = "ammo_craftbook",
        coords = {
            vector3(410.35, -1283.62, 41.66)
        },
        NpcHeading = {
            132.82
        },
        blip = {
            show = false,
            sprite = 1576459965,
            color = "BLIP_MODIFIER_MP_COLOR_2",
            scale = 0.6,
            label = "Ammo Crafting",
        },
        npc = {
            model = "S_M_M_StrLumberjack_01",
            name = "Ammo Crafter",
            show = false,
        },
        categories = {
            {
                name = "ammunition",
                label = "Ammunition",
                craftBookItem = "",
                campfireModel = "p_campfire03x",
                setupAnimDict = "mini_games@story@beechers@build_floor@john",
                setupAnimName = "hammer_loop_good",
                setupScenario = "WORLD_HUMAN_WRITE_NOTEBOOK",
                setupTime = 5000,
                items = {
                    {
                        itemName = "lockpick",
                        itemLabel = "Lockpick",
                        requiredJobs = false,
                        rewardXP = 10,
                        requiredLevel = 15,
                        itemAmount = 2,
                        duration = 120,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "lockpickmold", itemLabel = "Lockpick Mold", itemCount = 1, removeItem = false },
                            { itemName = "ironbar", itemLabel = "Iron Ingot", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "ammoshotgunnormal",
                        itemLabel = "Shotgun Ammo (Regular)",
                        requiredJobs = false,
                        rewardXP = 20,
                        requiredLevel = 5,
                        itemAmount = 1,
                        duration = 20,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "bulletscase", itemLabel = "Bullet Casings", itemCount = 10, removeItem = true },
                            { itemName = "bulletsmould", itemLabel = "Bullet Mold", itemCount = 1, removeItem = false },
                            { itemName = "powdergun", itemLabel = "Gunpowder", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "ammoshotgunslug",
                        itemLabel = "Shotgun Ammo (Slug)",
                        requiredJobs = false,
                        rewardXP = 60,
                        requiredLevel = 10,
                        itemAmount = 1,
                        duration = 20,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "bulletscase", itemLabel = "Bullet Casings", itemCount = 10, removeItem = true },
                            { itemName = "bulletsmould", itemLabel = "Bullet Mold", itemCount = 1, removeItem = false },
                            { itemName = "powdergun", itemLabel = "Gunpowder", itemCount = 2, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "ammorevolvernormal",
                        itemLabel = "Revolver Ammo (Regular)",
                        requiredJobs = false,
                        rewardXP = 20,
                        requiredLevel = 5,
                        itemAmount = 1,
                        duration = 15,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "bulletscase", itemLabel = "Bullet Casings", itemCount = 10, removeItem = true },
                            { itemName = "bulletsmould", itemLabel = "Bullet Mold", itemCount = 1, removeItem = false },
                            { itemName = "powdergun", itemLabel = "Gunpowder", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "ammorevolverexpress",
                        itemLabel = "Revolver Ammo (Express)",
                        requiredJobs = false,
                        rewardXP = 60,
                        requiredLevel = 14,
                        itemAmount = 1,
                        duration = 20,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "bulletscase", itemLabel = "Bullet Casings", itemCount = 10, removeItem = true },
                            { itemName = "bulletsmould", itemLabel = "Bullet Mold", itemCount = 1, removeItem = false },
                            { itemName = "powdergun", itemLabel = "Gunpowder", itemCount = 2, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "ammorevolvervelocity",
                        itemLabel = "Revolver Ammo (Velocity)",
                        requiredJobs = false,
                        rewardXP = 60,
                        requiredLevel = 10,
                        itemAmount = 1,
                        duration = 20,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "bulletscase", itemLabel = "Bullet Casings", itemCount = 10, removeItem = true },
                            { itemName = "bulletsmould", itemLabel = "Bullet Mold", itemCount = 1, removeItem = false },
                            { itemName = "powdergun", itemLabel = "Gunpowder", itemCount = 3, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "ammopistolnormal",
                        itemLabel = "Pistol Ammo (Regular)",
                        requiredJobs = false,
                        rewardXP = 20,
                        requiredLevel = 5,
                        itemAmount = 1,
                        duration = 15,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "bulletscase", itemLabel = "Bullet Casings", itemCount = 10, removeItem = true },
                            { itemName = "bulletsmould", itemLabel = "Bullet Mold", itemCount = 1, removeItem = false },
                            { itemName = "powdergun", itemLabel = "Gunpowder", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "ammopistolexpress",
                        itemLabel = "Pistol Ammo (Express)",
                        requiredJobs = false,
                        rewardXP = 60,
                        requiredLevel = 14,
                        itemAmount = 1,
                        duration = 20,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "bulletscase", itemLabel = "Bullet Casings", itemCount = 10, removeItem = true },
                            { itemName = "bulletsmould", itemLabel = "Bullet Mold", itemCount = 1, removeItem = false },
                            { itemName = "powdergun", itemLabel = "Gunpowder", itemCount = 2, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "ammorepeaternormal",
                        itemLabel = "Repeater Ammo (Regular)",
                        requiredJobs = false,
                        rewardXP = 20,
                        requiredLevel = 5,
                        itemAmount = 1,
                        duration = 15,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "bulletscase", itemLabel = "Bullet Casings", itemCount = 10, removeItem = true },
                            { itemName = "bulletsmould", itemLabel = "Bullet Mold", itemCount = 1, removeItem = false },
                            { itemName = "powdergun", itemLabel = "Gunpowder", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "ammorepeatervelocity",
                        itemLabel = "Repeater Ammo (Velocity)",
                        requiredJobs = false,
                        rewardXP = 60,
                        requiredLevel = 10,
                        itemAmount = 1,
                        duration = 20,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "bulletscase", itemLabel = "Bullet Casings", itemCount = 10, removeItem = true },
                            { itemName = "bulletsmould", itemLabel = "Bullet Mold", itemCount = 1, removeItem = false },
                            { itemName = "powdergun", itemLabel = "Gunpowder", itemCount = 3, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "ammorepeaterexpress",
                        itemLabel = "Repeater Ammo (Express)",
                        requiredJobs = false,
                        rewardXP = 60,
                        requiredLevel = 14,
                        itemAmount = 1,
                        duration = 20,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "bulletscase", itemLabel = "Bullet Casings", itemCount = 10, removeItem = true },
                            { itemName = "bulletsmould", itemLabel = "Bullet Mold", itemCount = 1, removeItem = false },
                            { itemName = "powdergun", itemLabel = "Gunpowder", itemCount = 2, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "ammoriflenormal",
                        itemLabel = "Rifle Ammo (Regular)",
                        requiredJobs = false,
                        rewardXP = 20,
                        requiredLevel = 5,
                        itemAmount = 1,
                        duration = 15,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "bulletscase", itemLabel = "Bullet Casings", itemCount = 10, removeItem = true },
                            { itemName = "bulletsmould", itemLabel = "Bullet Mold", itemCount = 1, removeItem = false },
                            { itemName = "powdergun", itemLabel = "Gunpowder", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "ammorifleexpress",
                        itemLabel = "Rifle Ammo (Express)",
                        requiredJobs = false,
                        rewardXP = 60,
                        requiredLevel = 14,
                        itemAmount = 1,
                        duration = 20,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "bulletscase", itemLabel = "Bullet Casings", itemCount = 10, removeItem = true },
                            { itemName = "bulletsmould", itemLabel = "Bullet Mold", itemCount = 1, removeItem = false },
                            { itemName = "powdergun", itemLabel = "Gunpowder", itemCount = 2, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "ammoriflevelocity",
                        itemLabel = "Rifle Ammo (Velocity)",
                        requiredJobs = false,
                        rewardXP = 60,
                        requiredLevel = 10,
                        itemAmount = 1,
                        duration = 20,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "bulletscase", itemLabel = "Bullet Casings", itemCount = 10, removeItem = true },
                            { itemName = "bulletsmould", itemLabel = "Bullet Mold", itemCount = 1, removeItem = false },
                            { itemName = "powdergun", itemLabel = "Gunpowder", itemCount = 3, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "ammoelephant",
                        itemLabel = "Elephant Rifle Ammo",
                        requiredJobs = false,
                        rewardXP = 20,
                        requiredLevel = 5,
                        itemAmount = 1,
                        duration = 15,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "bulletscase", itemLabel = "Bullet Casings", itemCount = 10, removeItem = true },
                            { itemName = "bulletsmould", itemLabel = "Bullet Mold", itemCount = 1, removeItem = false },
                            { itemName = "powdergun", itemLabel = "Gunpowder", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    },
                    {
                        itemName = "ammovarmint",
                        itemLabel = "Varmint Ammo",
                        requiredJobs = false,
                        rewardXP = 10,
                        requiredLevel = 2,
                        itemAmount = 1,
                        duration = 15,
                        lucky = 100,
                        requiredItems = {
                            { itemName = "bulletscase", itemLabel = "Bullet Casings", itemCount = 10, removeItem = true },
                            { itemName = "bulletsmould", itemLabel = "Bullet Mold", itemCount = 1, removeItem = false },
                            { itemName = "powdergun", itemLabel = "Gunpowder", itemCount = 1, removeItem = true },
                        },
                        playAnimation = false,
                        requiredPlaytimeMinutes = 0
                    }
                }
            }
        }
    }
}

for _, location in ipairs(ammunitions) do
    table.insert(CraftingLocations, location)
end

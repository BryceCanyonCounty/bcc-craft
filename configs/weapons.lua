-- Guide for Adding New Crafting Locations
-- You can create a new crafting location by copying and modifying an existing template such as for food or weapons.

-- Step-by-step Instructions:

-- 1. Define a new local variable for the crafting location.
--    This will hold all the necessary data for the location, including coordinates, NPC details, blip settings, 
--    and the crafting categories and items available at that location.
-- 
--    Example:
--    local newLocation = {
--      coords = {
--        vector3(x, y, z)  -- Define the X, Y, Z coordinates for your new location
--      },
--      NpcHeading = {
--        headingValue  -- Define the heading (rotation) for the NPC that appears at the location
--      },
--      blip = {
--        show = true,          -- Show or hide the blip on the map
--        sprite = spriteID,    -- Define the sprite ID for the blip (icon)
--        color = colorID,      -- Blip color ID
--        scale = scaleValue,   -- Set the size of the blip
--        label = "Blip Label", -- The label that appears when you hover over the blip on the map
--      },
--      npc = {
--        model = "npcModel",    -- The NPC model that will appear at the crafting location
--        name = "NPC Name",     -- Name of the NPC
--        show = true,           -- Whether or not the NPC should be shown
--      },
--      categories = {
--        -- Add crafting categories such as 'food', 'weapons', 'clothing', etc.
--        -- Each category contains the items available for crafting.
--        {
--          name = "CategoryName",     -- The name of the category (e.g., 'food', 'weapons', etc.)
--          label = "Category Label",  -- The label displayed for the category in the crafting menu
--          craftBookItem = "",  -- Whether or not a crafting book is required (use craftBookItem = "" if not required)
--          items = {
--            -- Add the items available in this category
--            {
--              itemName = "ItemName",        -- The internal name of the item
--              itemLabel = "Item Label",      -- The label displayed in the crafting menu
--              requiredJobs = false,          -- Whether specific jobs are required to craft the item
--              rewardXP = 10,                 -- The amount of XP rewarded for crafting the item
--              requiredLevel = 1,             -- The minimum level required to craft the item
--              itemAmount = 1,                -- How many items are produced from crafting
--              duration = 15,                 -- Time (in seconds) required to craft the item
--              requiredItems = {
--                -- List of items required for crafting
--                {
--                  itemName = "RequiredItem1",   -- Internal name of the required item
--                  itemLabel = "Required Item 1",-- Label displayed for the required item
--                  itemCount = 1,                -- Number of this item required for crafting
--                  removeItem = true             -- Whether the item should be removed from inventory upon crafting
--                },
--                {
--                  itemName = "RequiredItem2",
--                  itemLabel = "Required Item 2",
--                  itemCount = 1,
--                  removeItem = true
--                },
--                -- Add more required items as necessary
--              }
--            },
--            -- Add more craftable items as necessary
--          }
--        },
--        -- Add more categories as necessary
--      }
--    }

-- 2. After defining the new location, use table unpacking to add it to the `Config.CraftingLocations`.
--    This ensures that the new location is inserted properly into the existing crafting system.
-- 
--    Example:
--    for _, location in ipairs(newLocation) do
--      table.insert(Config.CraftingLocations, location)
--    end

-- 3. Copy and customize this structure as needed. Be sure to update all the relevant details such as item names, coordinates, NPCs, blips, and crafting requirements.


-- 4. You can create as many configuration files as you need inside a configs folder. 
--		This approach helps to avoid having one large Config file, making it easier to manage and organize the settings. 
--		Each file can contain specific configurations (e.g., crafting locations, categories) and will automatically add to the main Config.CraftingLocations table without overriding other settings.
--		This allows for a cleaner and more modular setup.
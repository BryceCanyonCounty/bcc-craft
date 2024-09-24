# bcc-crafting

> This crafting system brings a dynamic and immersive crafting experience for players! With features like category-specific *Craft Books*, XP-based progression, and detailed crafting summaries, this script will enhance the crafting journey for all players!

# Features
- **Craft Books for Categories**: Each crafting category is unlocked by using a specific *Craft Book*, offering a unique progression system based on discovery and crafting expertise.
- **XP-Based Crafting System**: Players earn XP for every item they craft, with higher-tier items granting more XP. Leveling up unlocks new recipes and abilities.
- **Detailed Inventory Checks**: Before crafting, the system checks if players have the necessary materials and enough inventory space. Crafted items are added after the process completes.
- **Comprehensive Crafting Summary**: Players receive a detailed summary of items crafted, XP gained, and any level progression after every crafting session.
- **Dynamic Categories**: Each category has its own set of items and recipes, which can be expanded easily via the config.
- **Player-Friendly Interface**: A simple and intuitive menu system ensures easy navigation through crafting options using Feather Menu.
- **In-Depth Webhooks**: Easily track player progress, crafting attempts, and more with built-in webhook functionality using BCC Utils.
- **Version Checking**: Automatic version checking keeps the script up to date with the latest features and fixes using BCC Utils.

# How it works
- Players must find and use *Craft Books* to unlock specific crafting categories.
- Once unlocked, they can choose recipes from a menu and craft items using the materials they gather in-game.
- XP is rewarded based on the items crafted, and leveling up unlocks new recipes and abilities.
- A detailed summary of each crafting session is provided, including materials used, XP earned, and any level changes.

# How to install
- Make sure dependencies are installed and updated
- Simply ensure the script in your server! 
- The database will automatically update, and you're ready to go!

# Side Notes
- The script uses *Craft Books* for each category. Players must use these in-game items to unlock different crafting categories, enhancing progression and exploration.
- Want more customization? You can easily add more categories, recipes, and features via the config file.
- Keep in mind: Always ensure there is enough inventory space and materials before crafting.
- Need more help? Join the bcc discord here: https://discord.gg/VrZEEpBgZJ

# Requirements
- [vorp_core](https://github.com/VORPCORE/vorp-core-lua)
- [vorp_inventory](https://github.com/VORPCORE/vorp_inventory-lua)
- [vorp_character](https://github.com/VORPCORE/vorp_character-lua)
- [feather-menu](https://github.com/FeatherFramework/feather-menu)
- [bcc-utils](https://github.com/BryceCanyonCounty/bcc-utils)
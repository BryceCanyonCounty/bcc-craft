CreateThread(function()
    -- Create the bcc_crafting_log table if it doesn't exist
    MySQL.query.await([[ 
        CREATE TABLE IF NOT EXISTS `bcc_crafting_log` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `charidentifier` varchar(50) NOT NULL,
            `itemName` varchar(100) NOT NULL,
            `itemLabel` varchar(100) NOT NULL,
            `itemAmount` int(11) NOT NULL,
            `requiredItems` text NOT NULL,
            `timestamp` bigint(20) NOT NULL,
            `status` varchar(20) NOT NULL,
            `duration` int(11) NOT NULL,
            `rewardXP` int(11) NOT NULL,
            `completed_at` datetime DEFAULT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Create the bcc_craft_progress table if it doesn't exist
    MySQL.query.await([[ 
        CREATE TABLE IF NOT EXISTS `bcc_craft_progress` (
            `charidentifier` varchar(50) NOT NULL,
            `currentXP` int(11) NOT NULL DEFAULT 0,
            `currentLevel` int(11) NOT NULL DEFAULT 1,
            PRIMARY KEY (`charidentifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Add the lastLevel column if it doesn't already exist
    MySQL.query.await([[ 
        ALTER TABLE `bcc_craft_progress`
        ADD COLUMN IF NOT EXISTS `lastLevel` int(11) NOT NULL DEFAULT 1;
    ]])

    -- Update lastLevel to match currentLevel for all existing records
    MySQL.query.await([[ 
        UPDATE `bcc_craft_progress`
        SET `lastLevel` = `currentLevel`;
    ]])

    -- Inserting craftbooks into the items table only if they do not exist
    MySQL.query.await([[ 
        INSERT INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `desc`) 
        VALUES 
        ('food_craftbook', 'Food Craftbook', 1, 1, 'item_standard', 1, 'Used to open the food crafting menu.'),
        ('weapons_craftbook', 'Weapons Craftbook', 1, 1, 'item_standard', 1, 'Used to open the weapons crafting menu.'),
        ('items_craftbook', 'Items Craftbook', 1, 1, 'item_standard', 1, 'Used to open the items crafting menu.'),
        ('others_craftbook', 'Others Craftbook', 1, 1, 'item_standard', 1, 'Used to open the miscellaneous items crafting menu.')
        ON DUPLICATE KEY UPDATE 
        `label`=VALUES(`label`), `limit`=VALUES(`limit`), `can_remove`=VALUES(`can_remove`), `type`=VALUES(`type`), `usable`=VALUES(`usable`), `desc`=VALUES(`desc`);
    ]])

    -- Print a success message to the console
    print("Database tables for \x1b[35m\x1b[1m*bcc-crafting*\x1b[0m created or updated \x1b[32msuccessfully\x1b[0m.")
end)

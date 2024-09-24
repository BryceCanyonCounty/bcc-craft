local showAllCategories = true

-- Function to open crafting category menu (can either show all or just one)
function openCraftingCategoryMenu(categoryName)
    devPrint("Opening crafting category menu: " .. tostring(categoryName))

    -- Find the category data
    local category = nil
    for _, categoryData in ipairs(Config.CraftingCategories) do
        devPrint("Checking category: " .. categoryData.name)
        if categoryData.name == categoryName then
            category = categoryData
            break
        end
    end

    if not category then
        devPrint("Invalid category: " .. tostring(categoryName))
        return
    end

    devPrint("Category found: " .. category.label)

    local categoryMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:" .. categoryName)
    categoryMenu:RegisterElement('header', {
        value = category.label,
        slot = 'header',
        style = {}
    })

    categoryMenu:RegisterElement('line', {
        style = {}
    })

    -- Loop through items in the category or show a message if there are none
    if #category.items > 0 then
        for _, item in ipairs(category.items) do
            devPrint("Adding item to menu: " .. item.itemLabel)
            categoryMenu:RegisterElement('button', {
                label = item.itemLabel,
                style = {}
            }, function()
                openCraftingItemMenu(item, categoryName)
            end)
        end
    else
        devPrint("No items available in category: " .. categoryName)
        categoryMenu:RegisterElement('textdisplay', {
            value = _U('NotAvailable'),
            style = { fontSize = '18px', bold = true }
        })
    end

    categoryMenu:RegisterElement('line', {
        style = {},
        slot = "footer",
    })

    -- If in single-category mode, we go back to the same category; otherwise, open the main menu
    categoryMenu:RegisterElement('button', {
        label = _U('BackButton'),
        slot = "footer",
        style = {}
    }, function()
        if showAllCategories then
            TriggerEvent('bcc-crafting:openmenu')  -- Open the main menu with all categories
        else
            openCraftingCategoryMenu(categoryName)  -- Re-open the same category (stay in single-category mode)
        end
    end)

    categoryMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    devPrint("Opening category menu: " .. categoryName)
    BCCCraftingMenu:Open({ startupPage = categoryMenu })
end

-- Event to open a specific category menu (single-category mode)
RegisterNetEvent('bcc-crafting:openCategoryMenu')
AddEventHandler('bcc-crafting:openCategoryMenu', function(categoryName)
    devPrint("Triggered event to open specific category: " .. tostring(categoryName))
    showAllCategories = false  -- We are in single-category mode
    openCraftingCategoryMenu(categoryName)  -- Open the specific category
end)

function openCraftingItemMenu(item, categoryName)
    devPrint("Opening crafting item menu: " .. tostring(item.itemLabel) .. " in category: " .. tostring(categoryName))

    local itemMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:item:" .. item.itemName)
    itemMenu:RegisterElement('header', {
        value = item.itemLabel,
        slot = 'header',
        style = {}
    })

    itemMenu:RegisterElement('line', {
        style = {}
    })

    -- Display required level
    devPrint("Required Level: " .. tostring(item.requiredLevel))
    itemMenu:RegisterElement('textdisplay', {
        value = _U('RequiredLevel') .. item.requiredLevel,
        style = {}
    })

    -- Display crafting duration
    devPrint("Crafting Duration: " .. tostring(item.duration) .. " seconds")
    itemMenu:RegisterElement('textdisplay', {
        value = _U('CraftTimeRemains') .. item.duration .. _U('seconds'),
        style = {}
    })

    -- Display reward XP
    devPrint("Reward XP: " .. tostring(item.rewardXP))
    itemMenu:RegisterElement('textdisplay', {
        value = _U('RewardXp') .. item.rewardXP,
        style = {}
    })

    -- Display required items
    devPrint("Listing required items:")
    itemMenu:RegisterElement('text', {
        value = _U('RequiredItems'),
        style = { bold = true }
    })

    for _, reqItem in ipairs(item.requiredItems) do
        devPrint(" - " .. reqItem.itemLabel .. " x" .. reqItem.itemCount)
        itemMenu:RegisterElement('textdisplay', {
            value = "- " .. reqItem.itemLabel .. " x" .. reqItem.itemCount,
            style = {}
        })
    end

    itemMenu:RegisterElement('line', {
        style = {},
        slot = "footer"
    })

    -- Option to craft the item
    devPrint("Adding craft button for: " .. item.itemLabel)
    itemMenu:RegisterElement('button', {
        label = _U('CraftButton') .. item.itemLabel,
        slot = "footer",
        style = {}
    }, function()
        devPrint("Attempting to craft item: " .. item.itemLabel)
        attemptCraftItem(item)
        openCraftingCategoryMenu(categoryName)
    end)

    -- Option to go back to the category menu
    itemMenu:RegisterElement('button', {
        label = _U('BackButton'),
        slot = "footer",
        style = {}
    }, function()
        openCraftingCategoryMenu(categoryName)
    end)

    itemMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    devPrint("Opening item menu for: " .. item.itemLabel)
    BCCCraftingMenu:Open({ startupPage = itemMenu })
end

-- Function to open the main crafting menu (shows all categories)
AddEventHandler('bcc-crafting:openmenu', function()
    devPrint("Opening main crafting menu with all categories")
    showAllCategories = true  -- We are in all-categories mode now

    if HandlePlayerDeathAndCloseMenu() then
        devPrint("Player is dead, closing the menu")
        return -- Skip opening the menu if the player is dead
    end

    -- Request crafting data from the server
    devPrint("Requesting crafting data from the server")
    TriggerServerEvent('bcc-crafting:requestCraftingData')
end)

-- Function that gets triggered after receiving crafting data from the server
RegisterNetEvent('bcc-crafting:sendCraftingData')
AddEventHandler('bcc-crafting:sendCraftingData', function(level, xpToNextLevel)
    devPrint("Received crafting data from the server")
    devPrint("Crafting level: " .. tostring(level) .. ", XP to next level: " .. tostring(xpToNextLevel))

    -- Now create the menu with the received data
    local craftingMainMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:MainPage")

    craftingMainMenu:RegisterElement('header', {
        value = _U('Crafting'),
        slot = 'header',
        style = {}
    })

    craftingMainMenu:RegisterElement('line', {
        style = {},
        slot = 'header'
    })

    craftingMainMenu:RegisterElement('subheader', {
        value = string.format(_U('CraftingLevel') .. "%d | " .. _U('XpToNextLvl') .. " %d", level, xpToNextLevel),
        slot = "header",
        style = {}
    })

    devPrint("Crafting main menu initialized")

    craftingMainMenu:RegisterElement('line', {
        style = {}
    })

    -- Iterate over the categories in order, only if showAllCategories is true
    if showAllCategories then
        for _, categoryData in ipairs(Config.CraftingCategories) do
            devPrint("Adding crafting category: " .. categoryData.label)
            craftingMainMenu:RegisterElement('button', {
                label = categoryData.label,
                style = {},
            }, function()
                openCraftingCategoryMenu(categoryData.name)
            end)
        end
    end

    craftingMainMenu:RegisterElement('line', {
        style = {},
        slot = "footer"
    })

    craftingMainMenu:RegisterElement('button', {
        label = _U('checkOngoing'),
        style = {},
        slot = "footer"
    }, function()
        devPrint("Checking ongoing crafting processes")
        -- Request the server for ongoing crafting processes
        TriggerServerEvent('bcc-crafting:getOngoingCrafting')
    end)

    craftingMainMenu:RegisterElement('button', {
        label = _U('checkCompleted'),
        style = {},
        slot = "footer"
    }, function()
        devPrint("Checking completed crafting processes")
        -- Request the server for completed crafting processes
        TriggerServerEvent('bcc-crafting:getCompletedCrafting')
    end)

    craftingMainMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    if Config.UseImageAtBottomMenu then
        devPrint("Adding image to the bottom of the crafting menu")
        craftingMainMenu:RegisterElement("html", {
            value = {
                string.format([[<img width="750px" height="108px" style="margin: 0 auto;" src="%s" />]], Config.CraftImageURL)
            },
            slot = "footer"
        })
    end

    -- Finally, open the menu
    devPrint("Opening crafting main menu")
    BCCCraftingMenu:Open({ startupPage = craftingMainMenu })
end)

function startCrafting(item)
    devPrint("Crafting started for item: " .. item.itemLabel .. ", duration: " .. item.duration)

    local duration = item.duration -- Duration in seconds
    local endTime = GetGameTimer() + (duration * 1000) -- Calculate end time in milliseconds

    -- Create ongoing crafting list format to match the server data structure
    local ongoingCraftingList = {
        {
            craftingLog = {
                itemLabel = item.itemLabel,
                itemAmount = item.itemAmount,
                requiredItems = json.encode(item.requiredItems)
            },
            remainingTime = duration
        }
    }

    -- Open the crafting progress menu with the ongoing item
    devPrint("Opening crafting progress menu for item: " .. item.itemLabel)
    openCraftingProgressMenu(ongoingCraftingList)

    -- Start the countdown timer
    CreateThread(function()
        while true do
            local remainingTime = math.ceil((endTime - GetGameTimer()) / 1000)
            devPrint("Remaining time for " .. item.itemLabel .. ": " .. remainingTime .. " seconds")
            
            if remainingTime <= 0 then
                remainingTime = 0
                devPrint("Crafting completed for item: " .. item.itemLabel)
            end

            -- Update the progress menu with the remaining time
            updateCraftingProgressMenu(item, remainingTime)

            if remainingTime <= 0 then
                -- Crafting complete
                devPrint("Exiting crafting timer thread for item: " .. item.itemLabel)
                break
            end

            Wait(1000) -- Update every second
        end
    end)
end

-- Function to display the list of ongoing crafting processes
function openCraftingProgressMenu(ongoingCraftingList)
    devPrint("Opening progress menu for ongoing crafting processes.")

    local progressMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:progress:list")

    progressMenu:RegisterElement('header', {
        value = _U('ongoingProgress'),
        slot = 'header',
        style = {}
    })

    progressMenu:RegisterElement('line', {
        style = {}
    })

    if #ongoingCraftingList > 0 then
        -- Loop through each ongoing crafting item
        for _, craftingData in ipairs(ongoingCraftingList) do
            local craftingLog = craftingData.craftingLog
            local remainingTime = craftingData.remainingTime
    
            -- Display the item label, amount, and remaining time
            devPrint("Ongoing crafting: " .. craftingLog.itemLabel .. " x" .. craftingLog.itemAmount .. ", Remaining Time: " .. remainingTime)
            TextDisplay = progressMenu:RegisterElement('textdisplay', {
                value = string.format("%s x%d - " .. remainingTime .. _U('seconds'), craftingLog.itemLabel, craftingLog.itemAmount),
                style = { fontSize = '18px' }
            })
        end
    else
        -- Display the message for no ongoing crafting processes
        devPrint("No ongoing crafting processes.")
        pTextDisplay = progressMenu:RegisterElement('textdisplay', {
            value = _U('NoOngoingProccess'),
            style = { fontSize = '18px' }
        })
    end

    progressMenu:RegisterElement('line', {
        style = {},
        slot = "footer"
    })

    progressMenu:RegisterElement('button', {
        label = _U('BackButton'),
        style = {},
        slot = "footer"
    }, function()
        devPrint("Returning to main menu from progress menu.")
        BCCCraftingMenu:Close()
        TriggerEvent('bcc-crafting:openmenu')
    end)

    progressMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    devPrint("Opening progress menu.")
    BCCCraftingMenu:Open({ startupPage = progressMenu })
end

-- Function to handle progress for individual crafting items
function openCraftingItemProgressMenu(item, remainingTime)
    devPrint("Opening progress menu for item: " .. item.itemLabel .. ", Remaining Time: " .. remainingTime)

    local itemProgressMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:progress:" .. item.itemName)

    itemProgressMenu:RegisterElement('header', {
        value = _U('craftProgress') .. item.itemLabel,
        slot = 'header',
        style = {}
    })

    itemProgressMenu:RegisterElement('text', {
        value = _U('craftRemaining') .. remainingTime .. _U('seconds'),
        style = { fontSize = '20px' }
    })

    itemProgressMenu:RegisterElement('line', {
        style = {},
        slot = "footer"
    })

    itemProgressMenu:RegisterElement('button', {
        label = _U('BackButton'),
        style = {},
        slot = "footer"
    }, function()
        devPrint("Returning to progress menu from item progress.")
        openCraftingProgressMenu(ongoingCraftingList)
    end)

    devPrint("Opening item progress menu for: " .. item.itemLabel)
    BCCCraftingMenu:Open({ startupPage = itemProgressMenu })
end

-- Function to display the list of completed crafting processes
function openCompletedCraftingMenu(completedCraftingList)
    devPrint("Opening completed crafting menu.")

    local completedMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:completed:list")

    completedMenu:RegisterElement('header', {
        value = _U('craftCompleted'),
        slot = 'header',
        style = {}
    })

    completedMenu:RegisterElement('line', {
        style = {}
    })

    if #completedCraftingList > 0 then
        -- Loop through each completed crafting item
        for index, craftingLog in ipairs(completedCraftingList) do
            -- Button to collect the completed item, with numbering
            devPrint("Adding completed item to menu: " .. craftingLog.itemLabel .. " x" .. craftingLog.itemAmount)
            completedMenu:RegisterElement('button', {
                label = index .. _U('craftCollect') .. craftingLog.itemLabel .. " x " .. craftingLog.itemAmount,
                style = {},
            }, function()
                devPrint("Collecting crafted item: " .. craftingLog.itemLabel)
                BCCCraftingMenu:Close()
                TriggerServerEvent('bcc-crafting:collectCraftedItem', craftingLog)
                TriggerServerEvent('bcc-crafting:getCompletedCrafting')
            end)
        end
    else
        -- No completed crafting processes
        devPrint("No completed crafting processes.")
        TextDisplay = completedMenu:RegisterElement('textdisplay', {
            value = _U('NoCompletedProccess'),
            style = { fontSize = '18px' }
        })
    end

    completedMenu:RegisterElement('line', {
        style = {},
        slot = "footer"
    })

    completedMenu:RegisterElement('button', {
        label = _U('BackButton'),
        style = {},
        slot = "footer"
    }, function()
        devPrint("Returning to main menu from completed crafting.")
        BCCCraftingMenu:Close()
        TriggerEvent('bcc-crafting:openmenu')
    end)

    completedMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    devPrint("Opening completed crafting menu.")
    BCCCraftingMenu:Open({ startupPage = completedMenu })
end

-- Client-side event handler for starting crafting
RegisterNetEvent('bcc-crafting:startCrafting')
AddEventHandler('bcc-crafting:startCrafting', function(item)
    devPrint("Received event: startCrafting for item: " .. item.itemLabel)
    startCrafting(item)
end)

-- Listen for the list of ongoing crafting processes from the server
RegisterNetEvent('bcc-crafting:sendOngoingCraftingList')
AddEventHandler('bcc-crafting:sendOngoingCraftingList', function(ongoingCraftingList)
    devPrint("Received ongoing crafting list from server.")
    openCraftingProgressMenu(ongoingCraftingList)
end)

-- Listen for the list of completed crafting processes from the server
RegisterNetEvent('bcc-crafting:sendCompletedCraftingList')
AddEventHandler('bcc-crafting:sendCompletedCraftingList', function(completedCraftingList)
    devPrint("Received completed crafting list from server.")
    openCompletedCraftingMenu(completedCraftingList)
end)
-- Client-side function to request ongoing crafting data from the server
function GetOngoingCraftingItem()
    TriggerServerEvent('bcc-crafting:getOngoingCrafting')
end


function GetCraftingRemainingTime()
    return remainingTime
end

function updateCraftingProgressMenu(item, remainingTime)
    local progressMenu = BCCCraftingMenu:GetPage("bcc-crafting:progress:" .. item.itemName)
    if progressMenu then
        -- Update the remaining time text
        progressMenu:UpdateElement('remainingTime', {
            value = _U('remainingTime') .. remainingTime .. _U('seconds')
        })

        -- Optionally, update the progress bar
        -- local elapsedTime = item.duration - remainingTime
        -- progressMenu:UpdateElement('progressBar', {
        --     value = elapsedTime
        -- })
    end
end


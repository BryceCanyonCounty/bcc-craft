local showCraftBookcategory = false

-- Function to open crafting category menu (can either show all or just one)
function openCraftingCategoryMenu(categoryName, currentLocationCategories)
    devPrint("Opening crafting category menu: " .. tostring(categoryName))

    -- Find the category data in the crafting locations
    local category = nil
    for _, location in ipairs(Config.CraftingLocations) do
        for _, categoryData in ipairs(location.categories) do
            devPrint("Checking category: " .. categoryData.name)
            if categoryData.name == categoryName then
                category = categoryData
                break
            end
        end
        if category then break end
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

    -- Function to generate HTML content for each item
    local function generateHtmlContent(item, imgPath)
        local label = item.itemLabel
        return '<div style="display: flex; align-items: center; width: 100%;">' ..
            '<img src="' .. imgPath .. '" style="width: 50px; height: 50px; margin-right: 10px;">' ..
            '<div style="text-align: center; flex-grow: 1;">' .. label .. '</div>' ..
            '</div>'
    end

    -- Loop through items in the category or show a message if there are none
    if #category.items > 0 then
        for _, item in ipairs(category.items) do
            devPrint("Adding item to menu: " .. item.itemLabel)
            devPrint("Item name: " .. item.itemName)

            local imgPath = 'nui://vorp_inventory/html/img/items/' .. item.itemName .. '.png'
            local htmlContent = generateHtmlContent(item, imgPath)

            categoryMenu:RegisterElement('button', {
                html = htmlContent,
                slot = "content"
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

    -- If in single-category mode, we go back to the same category; otherwise, open the specific location menu
    categoryMenu:RegisterElement('button', {
        label = _U('BackButton'),
        slot = "footer",
        style = {}
    }, function()
        -- Only show the categories for the current location
        if currentLocationCategories then
            TriggerEvent('bcc-crafting:openmenu', currentLocationCategories)  -- Go back to the location-specific category list
        else
            devPrint("Error: No currentLocationCategories available.")
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
    currentLocationCategories = categoryName
    openCraftingCategoryMenu(categoryName)  -- Open the specific category
end)

-- Function to open crafting item menu
function openCraftingItemMenu(item, categoryName)
    devPrint("Opening crafting item menu: " .. tostring(item.itemLabel) .. " in category: " .. tostring(categoryName))

    -- Generate the list of required items
    local requiredItemsHTML = ""
    for _, reqItem in ipairs(item.requiredItems) do
        requiredItemsHTML = requiredItemsHTML .. string.format("<li>- %s x%d</li>", reqItem.itemLabel, tonumber(reqItem.itemCount or 0))
    end

    -- Assuming item.itemName contains the name of the item image
    local imgPath = 'nui://vorp_inventory/html/img/items/' .. item.itemName .. '.png'

    -- Create the HTML content for the crafting item details with centered image
    local htmlContent = string.format([[
        <div style="text-align:center; margin: 20px; font-family: 'Georgia', serif; color: #5A3A29;">
            <!-- Centered item image -->
            <img src="%s" style="width: 100px; height: 100px; margin-bottom: 15px; display: block; margin-left: auto; margin-right: auto;" alt="%s">

            <!-- Item details -->
            <p style="font-size:20px; margin-bottom: 10px; font-style: italic;">%s <strong style="color:#8B4513;">%d</strong></p>
            <p style="font-size:20px; margin-bottom: 10px; font-style: italic;">%s <strong style="color:#B22222;">%d %s</strong></p>
            <p style="font-size:20px; margin-bottom: 10px; font-weight: bold; color:#8A2BE2;">%s <strong style="color:#FFD700;">%d XP</strong></p>

            <!-- Required items -->
            <div style="font-size:20px; margin-bottom: 10px; font-weight: bold; text-transform: uppercase;">%s</div>
            <ul style="list-style-type:square; font-size:18px; text-align:left; display:inline-block; padding: 0; margin: 0;">
                %s
            </ul>
        </div>
    ]],
        imgPath, item.itemLabel, -- Image source and alt text (item label)
        _U('RequiredLevel'), tonumber(item.requiredLevel or 1), -- Required level
        _U('CraftTimeRemains'), tonumber(item.duration or 0), _U('seconds'), -- Crafting duration
        _U('RewardXp'), tonumber(item.rewardXP or 0), -- Reward XP
        _U('RequiredItems'), -- Required items header
        requiredItemsHTML -- The generated list of required items
    )

    -- Create the crafting menu page
    local itemMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:item:" .. item.itemName)
    itemMenu:RegisterElement('header', {
        value = item.itemLabel,
        slot = 'header',
        style = {}
    })

    itemMenu:RegisterElement("html", {
        value = { htmlContent },
        slot = 'content',
        style = {}
    })

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
        devPrint("Triggering input menu for crafting amount of: " .. item.itemLabel)
        openCraftingAmountInput(item, categoryName, currentLocationCategories) -- Open the input page for the crafting amount
    end)

    -- Option to go back to the category menu
    itemMenu:RegisterElement('button', {
        label = _U('BackButton'),
        slot = "footer",
        style = {}
    }, function()
        openCraftingCategoryMenu(categoryName, currentLocationCategories) -- Pass the categories to go back to the category menu
    end)

    itemMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    devPrint("Opening item menu for: " .. item.itemLabel)
    BCCCraftingMenu:Open({ startupPage = itemMenu })
end

-- Function to open the main crafting menu (shows only location-specific categories)
AddEventHandler('bcc-crafting:openmenu', function(categories)
    devPrint("Opening main crafting menu with specific categories for the location")
    currentLocationCategories = categories  -- Store the categories so we can use them later
    showCraftBookcategory = false -- We are in location-specific categories mode now

    if HandlePlayerDeathAndCloseMenu() then
        devPrint("Player is dead, closing the menu")
        return -- Skip opening the menu if the player is dead
    end

    -- Request crafting data from the server
    devPrint("Requesting crafting data from the server")
    TriggerServerEvent('bcc-crafting:requestCraftingData', categories)
end)

-- Open crafting amount input menu
function openCraftingAmountInput(item)
    local inputValue = nil
    local craftingAmountMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:amountInput")

    -- Header
    craftingAmountMenu:RegisterElement('header', {
        value = item.itemLabel,
        slot = 'header',
        style = {}
    })
    
    craftingAmountMenu:RegisterElement('line', {
        style = {},
        slot = "content"
    })
    
    -- Input field
    craftingAmountMenu:RegisterElement('input', {
        label = _U('EnterAmount'),
        placeholder = _U('AmountPlaceholder'),
        slot = 'content',
        style = {}
    }, function(data)
        inputValue = tonumber(data.value) or 0  -- Update the input value
    end)
    
    craftingAmountMenu:RegisterElement('line', {
        style = {},
        slot = "footer"
    })
    
    -- Confirm button
    craftingAmountMenu:RegisterElement('button', {
        label = _U('ConfirmCraft') .. item.itemLabel,
        slot = 'footer',
        style = {}
    }, function()
        if inputValue > 0 then
            attemptCraftItem(item, inputValue)  -- Pass the input value as amount
        else
            devPrint("Invalid amount entered.")
            VORPcore.NotifyRightTip(source, _U('InvalidAmount'), 4000)
        end
    end)

    -- Back button
    craftingAmountMenu:RegisterElement('button', {
        label = _U('BackButton'),
        slot = 'footer',
        style = {}
    }, function()
        openCraftingCategoryMenu(item.categoryName, currentLocationCategories)  -- Return to the category menu
    end)

    craftingAmountMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    BCCCraftingMenu:Open({ startupPage = craftingAmountMenu })
end

-- Function that gets triggered after receiving crafting data from the server
RegisterNetEvent('bcc-crafting:sendCraftingData')
AddEventHandler('bcc-crafting:sendCraftingData', function(level, currentXP, categories)
    devPrint("Received crafting data from the server")
    devPrint("Crafting level: " .. tostring(level) .. ", Current XP: " .. tostring(currentXP))

    -- Calculate remaining XP to reach the next level
    local xpToNextLevel = GetRemainingXP(currentXP, level)
    devPrint("XP to next level: " .. tostring(xpToNextLevel))

    -- Now create the menu with the received data
    local craftingMainMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:MainPage")

    -- Add crafting header
    craftingMainMenu:RegisterElement('header', {
        value = _U('Crafting'),
        slot = 'header',
        style = {}
    })

    -- Line break after the header
    craftingMainMenu:RegisterElement('line', {
        style = {},
        slot = 'header'
    })

    -- Display player's crafting level and XP
    local subheaderHTML = string.format([[        
        <div style="text-align:center; margin: 20px; font-family: 'Georgia', serif; color: #5A3A29;">
            <p style="font-size:24px; font-weight:bold; margin-bottom: 10px;">
                <span style="color:#8B4513;">%s</span> 
                <strong style="color:#B8860B; text-transform:uppercase;">%d</strong> 
            </p>
            <p style="font-size:20px; margin-bottom: 5px;">
                <span style="color:#8A2BE2; font-weight:bold;">%s</span>
                <strong style="color:#FFD700;">%d XP</strong>
            </p>
        </div>
    ]],
        _U('CraftingLevel'), tonumber(level), -- Display crafting level
        _U('XpToNextLvl'), tonumber(xpToNextLevel) -- Correctly calculate XP to next level
    )

    -- Insert the subheader HTML into the crafting menu
    craftingMainMenu:RegisterElement("html", {
        value = { subheaderHTML },
        slot = "header",
        style = {}
    })

    devPrint("Crafting main menu initialized")

    -- Line after the XP info
    craftingMainMenu:RegisterElement('line', {
        style = {}
    })

    -- Check if we're displaying the menu from a craftbook interaction
    if showCraftBookcategory then
        devPrint("Displaying single craftbook category")
        -- Assuming 'categories' contains only one category when opened via craftbook
        if categories and categories[1] then
            local categoryData = categories[1]
            craftingMainMenu:RegisterElement('button', {
                label = categoryData.label,
                style = {},
            }, function()
                openCraftingCategoryMenu(categoryData.name, currentLocationCategories)
            end)
        else
            devPrint("No valid category for the craftbook")
            craftingMainMenu:RegisterElement('textdisplay', {
                value = _U('NoAvailableCategories'),
                style = { fontSize = '18px' }
            })
        end
    else
        -- Otherwise, show all categories
        devPrint("Displaying all available categories")
        if type(categories) == "table" and #categories > 0 then
            for index, categoryData in ipairs(categories) do
                devPrint("Category Index: " .. index .. ", Category Data: " .. json.encode(categoryData))

                if categoryData.label and categoryData.name then
                    craftingMainMenu:RegisterElement('button', {
                        label = categoryData.label,
                        style = {},
                    }, function()
                        openCraftingCategoryMenu(categoryData.name, currentLocationCategories)
                    end)
                else
                    devPrint("Invalid category data at index: " .. index .. ", Missing 'label' or 'name'")
                end
            end
        else
            devPrint("No crafting categories available or 'categories' is not a table.")
            craftingMainMenu:RegisterElement('textdisplay', {
                value = _U('NoAvailableCategories'),
                style = { fontSize = '18px' }
            })
        end
    end

    -- Footer line and buttons
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
        TriggerServerEvent('bcc-crafting:getOngoingCrafting')
    end)

    craftingMainMenu:RegisterElement('button', {
        label = _U('checkCompleted'),
        style = {},
        slot = "footer"
    }, function()
        devPrint("Checking completed crafting processes")
        TriggerServerEvent('bcc-crafting:getCompletedCrafting')
    end)

    -- Optional footer image
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

    openCraftingProgressMenu(ongoingCraftingList, currentLocationCategories)
end

-- Function to display the list of ongoing crafting processes
function openCraftingProgressMenu(ongoingCraftingList, currentLocationCategories)
    devPrint("Opening progress menu for ongoing crafting processes.")

    local progressMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:progress:list")

    progressMenu:RegisterElement("header", {
        value = _U('ongoingProgress'),
        slot = "header",
        style = {}
    })

    progressMenu:RegisterElement('line', {
        style = {}
    })

    -- Create a list of ongoing crafting items
    if #ongoingCraftingList > 0 then
        local craftingListHtml = ""

        -- Loop through each ongoing crafting item
        for _, craftingData in ipairs(ongoingCraftingList) do
            local craftingLog = craftingData.craftingLog
            local remainingTime = craftingData.remainingTime
            local formattedTime = formatTime(remainingTime)

            -- Generate the HTML content for each crafting item
            craftingListHtml = craftingListHtml .. string.format([[
                <div style="text-align:center; margin: 20px 0; font-family: 'Crimson Text', serif; color: #4E342E;">
                    <p style="font-size:20px; font-weight: bold;">%s <strong>x%d</strong></p>
                    <p style="font-size:18px; color: #8A2BE2;">%s <strong>%s</strong></p>
                </div>
            ]],
            craftingLog.itemLabel, craftingLog.itemAmount, _U('remainingTime'), formattedTime)

            devPrint("Ongoing crafting: " .. craftingLog.itemLabel .. " x" .. craftingLog.itemAmount .. ", Remaining Time: " .. formattedTime)
        end

        -- Register the HTML with the menu
        progressMenu:RegisterElement("html", {
            value = { craftingListHtml },
            slot = "content",
            style = {}
        })

    else
        -- If there are no ongoing crafting processes, display a message
        local noCraftingHtml = [[
            <div style="text-align:center; font-family: 'Crimson Text', serif; color: #4E342E;">
                <p style="font-size:20px; color: #B22222;">]] .. _U('NoOngoingProccess') .. [[</p>
            </div>
        ]]
        progressMenu:RegisterElement("html", {
            value = { noCraftingHtml },
            slot = "content",
            style = {}
        })

        devPrint("No ongoing crafting processes.")
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
        devPrint("currentLocationCategories: " .. json.encode(currentLocationCategories))  -- Debug print for categories
        BCCCraftingMenu:Close()
    
        TriggerEvent('bcc-crafting:openmenu', currentLocationCategories) -- Go back to the category list
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
        openCraftingProgressMenu(ongoingCraftingList, currentLocationCategories)
    end)

    devPrint("Opening item progress menu for: " .. item.itemLabel)
    BCCCraftingMenu:Open({ startupPage = itemProgressMenu })
end

-- Function to display the list of completed crafting processes
function openCompletedCraftingMenu(completedCraftingList, currentLocationCategories)
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
                BCCCallbacks.Trigger('bcc-crafting:collectCraftedItem', function(success)
                    if success then
                        print("Crafting item collected successfully!")
                    else
                        print("Failed to collect the crafted item.")
                    end
                end, craftingLog)
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
        devPrint("currentLocationCategories: " .. json.encode(currentLocationCategories))  -- Debug print for categories
        BCCCraftingMenu:Close()
        TriggerEvent('bcc-crafting:openmenu', currentLocationCategories) -- Go back to the category list
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

RegisterNetEvent('bcc-crafting:sendOngoingCraftingList')
AddEventHandler('bcc-crafting:sendOngoingCraftingList', function(ongoingCraftingList)
    devPrint("Received ongoing crafting list from server.")
    -- Ensure that 'currentLocationCategories' is passed when opening the menu
    openCraftingProgressMenu(ongoingCraftingList, currentLocationCategories)
end)

RegisterNetEvent('bcc-crafting:sendCompletedCraftingList')
AddEventHandler('bcc-crafting:sendCompletedCraftingList', function(completedCraftingList)
    devPrint("Received completed crafting list from server.")
    -- Ensure that 'currentLocationCategories' is passed when opening the menu
    openCompletedCraftingMenu(completedCraftingList, currentLocationCategories)
end)

-- Client-side function to request ongoing crafting data from the server
function GetOngoingCraftingItem()
    TriggerServerEvent('bcc-crafting:getOngoingCrafting')
end

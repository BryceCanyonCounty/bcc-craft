local showCraftBookcategory = false

-- Function to open crafting category menu (can either show all or just one)
function openCraftingCategoryMenu(categoryName, currentLocationCategories)
    devPrint("Opening crafting category menu: " .. tostring(categoryName))

    -- Find the category data in the crafting locations
    local category = nil
    for _, location in ipairs(CraftingLocations) do
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

    -- Loop through items in the category
    if #category.items > 0 then
        for _, item in ipairs(category.items) do
            devPrint("Adding item to menu: " .. item.itemLabel)
            devPrint("Item name: '" .. item.itemName .. "'")

            local imgPath = 'nui://vorp_inventory/html/img/items/' .. item.itemName .. '.png'
            local htmlContent = generateHtmlContent(item, imgPath)

            categoryMenu:RegisterElement('button', {
                html = htmlContent,
                slot = "content"
            }, function()
                -- Capture itemName and fetch item limit
                local currentItemName = item.itemName
                devPrint("Preparing to fetch limit for item:", currentItemName)

                fetchItemLimit(currentItemName, function(itemLimit)
                    devPrint("Item limit for " .. currentItemName .. " received: " .. tostring(itemLimit))
                    openCraftingItemMenu(item, categoryName, itemLimit) -- Pass item limit to the menu
                end)
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

    categoryMenu:RegisterElement('button', {
        label = _U('BackButton'),
        slot = "footer",
        style = {}
    }, function()
        if currentLocationCategories then
            TriggerEvent('bcc-crafting:openmenu', currentLocationCategories)
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
    openCraftingCategoryMenu(categoryName)
end)

-- Function to open crafting item menu with item limit
function openCraftingItemMenu(item, categoryName, itemLimit)
    devPrint("Opening crafting item menu: " .. tostring(item.itemLabel) .. " in category: " .. tostring(categoryName))

    local imgPath = 'nui://vorp_inventory/html/img/items/' .. item.itemName .. '.png'

    local requiredItemsHTML = ""
    for _, reqItem in ipairs(item.requiredItems) do
        local reqImgPath = 'nui://vorp_inventory/html/img/items/' .. reqItem.itemName .. '.png'
        requiredItemsHTML = requiredItemsHTML .. string.format([[
            <li style="display: flex; align-items: center; margin-bottom: 8px;">
                <img src="%s" style="width: 48px; height: 48px; margin-right: 8px; border: 1px solid #8B4513; border-radius: 4px;" alt="%s">
                <span>%s x%d</span>
            </li>
        ]], reqImgPath, reqItem.itemLabel, reqItem.itemLabel, tonumber(reqItem.itemCount) or 0)
    end
    
    local htmlContent = string.format([[
        <div style="padding: 20px; font-family: 'Georgia', serif; color: #4E342E; max-width: 500px; margin: 0 auto;">
            <div style="display: flex; align-items: center; gap: 15px;">
                <!-- Image Section -->
                <div style="flex-shrink: 0; text-align: center;">
                    <img src="%s" style="width: 120px; height: 120px; border: 1px solid #8B4513; border-radius: 3%%;" alt="%s">
                </div>
                <!-- Details Section -->
                <div style="flex-grow: 1;">
                    <p style="font-size: 18px; margin-bottom: 10px;"><strong style="color: #8B4513;">%s</strong> %d</p>
                    <p style="font-size: 18px; margin-bottom: 10px;"><strong style="color: #B22222;">%s</strong> %d %s</p>
                    <p style="font-size: 18px; margin-bottom: 10px;"><strong style="color: #FFD700;">%s</strong> %d XP</p>
                    <p style="font-size: 18px; margin-bottom: 10px;"><strong style="color: #FF6347;">%s</strong> %s</p>
                    <p style="font-size: 18px; margin-bottom: 10px;"><strong style="color: #DA70D6;">%s</strong> %d</p>
                </div>
            </div>
            <!-- Required Items Section -->
            <div style="border-top: 2px solid #8B4513; padding-top: 15px; margin-top: 20px;">
                <h3 style="font-size: 20px; color: #4B0082; text-transform: uppercase; font-weight: bold; margin-bottom: 10px;">%s</h3>
                <ul style="padding: 0; margin: 0; font-size: 16px; line-height: 1.6;">
                    %s
                </ul>
            </div>
        </div>
    ]],
        imgPath, item.itemLabel,
        _U('RequiredLevel'), tonumber(item.requiredLevel) or 1,
        _U('CraftTimeRemains'), tonumber(item.duration) or 0, _U('seconds'),
        _U('RewardXp'), tonumber(item.rewardXP) or 0,
        _U('CraftingLimit'), itemLimit or "N/A",
        _U('CraftAmount'), tonumber(item.itemAmount) or 1,
        _U('RequiredItems'),
        requiredItemsHTML
    )

    local itemMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:item:" .. item.itemName)
    itemMenu:RegisterElement('header', {
        value = item.itemLabel,
        slot = 'header',
        style = {}
    })

    itemMenu:RegisterElement('line', {
        style = {},
        slot = "header"
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
        label = _U('CraftButton'),
        slot = "footer",
        style = {}
    }, function()
        devPrint("Attempting to craft item: " .. item.itemLabel)

        -- Check if the item is a weapon
        local isWeapon = string.find(item.itemName, "^WEAPON_") ~= nil

        if isWeapon then
            -- If the item is a weapon, trigger crafting directly with a default amount of 1
            devPrint("Crafting weapon directly:", item.itemName)
            attemptCraftItem(item, Config.WeaponLimit or 1)
        else
            -- For regular items, open the crafting amount input menu
            devPrint("Opening amount input for regular item:", item.itemName)
            openCraftingAmountInput(item, categoryName, currentLocationCategories)
        end
    end)

    itemMenu:RegisterElement('button', {
        label = _U('BackButton'),
        slot = "footer",
        style = {}
    }, function()
        openCraftingCategoryMenu(categoryName, currentLocationCategories)
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
    currentLocationCategories = categories -- Store the categories so we can use them later
    showCraftBookcategory = false          -- We are in location-specific categories mode now

    if HandlePlayerDeathAndCloseMenu() then
        devPrint("Player is dead, closing the menu")
        return -- Skip opening the menu if the player is dead
    end

    -- Request crafting data from the server
    devPrint("Requesting crafting data from the server")
    TriggerServerEvent('bcc-crafting:requestCraftingData', categories)
end)

-- Open crafting amount input menu
function openCraftingAmountInput(item, categoryName, currentLocationCategories) -- Add categoryName as a parameter
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
        inputValue = tonumber(data.value) or 0 -- Update the input value
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
        -- Ensure inputValue is a valid number and greater than 0
        if inputValue and tonumber(inputValue) > 0 then
            attemptCraftItem(item, tonumber(inputValue)) -- Convert inputValue to a number and pass it as amount
        else
            devPrint("Invalid amount entered.")
            VORPcore.NotifyObjective(_U('InvalidAmount'), 4000)
        end
    end)

    -- Back button
    craftingAmountMenu:RegisterElement('button', {
        label = _U('BackButton'),
        slot = 'footer',
        style = {}
    }, function()
        openCraftingItemMenu(item, categoryName) -- Pass the categoryName here
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
        _U('CraftingLevel'), tonumber(level),      -- Display crafting level
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
            craftingMainMenu:RegisterElement('textdisplay', {
                value = _U('NoAvailableCategories'),
                style = { fontSize = '18px' }
            })
        end
    else
        if type(categories) == "table" and #categories > 0 then
            for index, categoryData in ipairs(categories) do
                --devPrint("Category Index: " .. index .. ", Category Data: " .. json.encode(categoryData))

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
        TriggerServerEvent('bcc-crafting:getOngoingCrafting')
    end)

    craftingMainMenu:RegisterElement('button', {
        label = _U('checkCompleted'),
        style = {},
        slot = "footer"
    }, function()
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
                string.format([[<img width="750px" height="108px" style="margin: 0 auto;" src="%s" />]],
                    Config.CraftImageURL)
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

    local duration = item.duration                     -- Duration in seconds
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

--- Function to display the list of ongoing crafting processes
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
            local craftingLog = craftingData.craftingLog or {}
            local remainingTime = craftingData.remainingTime or 0
            local itemAmount = craftingLog.itemAmount or 0
            local formattedTime = formatTime(remainingTime)

            -- Generate the HTML content for each crafting item, with default values if nil
            craftingListHtml = craftingListHtml .. string.format([[
                <div style="text-align:center; margin: 20px 0; font-family: 'Crimson Text', serif; color: #4E342E;">
                    <p style="font-size:20px; font-weight: bold;">%s <strong>x%d</strong></p>
                    <p style="font-size:18px; color: #8A2BE2;">%s <strong>%s</strong></p>
                </div>
            ]],
                craftingLog.itemLabel or "Unknown Item", itemAmount, _U('remainingTime'), formattedTime)

            devPrint("Ongoing crafting: " .. (craftingLog.itemLabel or "Unknown Item") .. " x" .. itemAmount .. ", Remaining Time: " .. formattedTime)
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
        devPrint("currentLocationCategories: " .. json.encode(currentLocationCategories)) -- Debug print for categories
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
    devPrint("completedCraftingList: " .. json.encode(completedCraftingList))
    local completedMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:completed:list")

    -- Header for the completed crafting menu
    completedMenu:RegisterElement('header', {
        value = _U('craftCompleted'),
        slot = 'header',
        style = {}
    })
    completedMenu:RegisterElement('line', { style = {} })

    -- Check if the completed crafting list has items
    if #completedCraftingList > 0 then
        -- Loop through each completed crafting log
        for index, craftingLog in ipairs(completedCraftingList) do
            -- Log that we're adding a completed item to the menu
            devPrint("Adding completed item to menu: " .. (craftingLog.itemLabel) .. " x" .. (craftingLog.itemAmount))
            -- Register button for each crafted item in the list
            completedMenu:RegisterElement('button', {
                label = index .. _U('craftCollect') .. (craftingLog.itemLabel) .. " x " .. (craftingLog.itemAmount),
                style = {}
            }, function()
                -- Log that we're collecting a crafted item
                devPrint("Collecting crafted item: " .. (craftingLog.itemLabel))

                -- Close the menu
                BCCCraftingMenu:Close()

                -- Trigger callback to collect crafted item
                BCCCallbacks.Trigger('bcc-crafting:collectCraftedItem', function(success)
                    if success then
                        devPrint("Crafting item collected successfully!")
                    else
                        devPrint("Failed to collect the crafted item.")
                    end

                    -- Request completed crafting data again
                    TriggerServerEvent('bcc-crafting:getCompletedCrafting')
                end, craftingLog)
            end)
        end
    else
        devPrint("No completed crafting processes.")
        -- Display message when there are no completed items
        completedMenu:RegisterElement('textdisplay', {
            value = _U('NoCompletedProccess'),
            style = { fontSize = '18px' }
        })
    end

    -- Footer elements
    completedMenu:RegisterElement('line', { style = {}, slot = "footer" })
    completedMenu:RegisterElement('button', {
        label = _U('BackButton'),
        style = {},
        slot = "footer"
    }, function()
        devPrint("Returning to main menu from completed crafting.")
        devPrint("currentLocationCategories: " .. json.encode(currentLocationCategories))
        BCCCraftingMenu:Close()
    end)
    completedMenu:RegisterElement('bottomline', { style = {}, slot = "footer" })

    -- Open the menu
    devPrint("Opening completed crafting menu.")
    BCCCraftingMenu:Open({ startupPage = completedMenu })
end

-- Client-side event handler for starting crafting
RegisterNetEvent('bcc-crafting:startCrafting')
AddEventHandler('bcc-crafting:startCrafting', function(item)
    devPrint("Received event: startCrafting for item: '" .. item.itemLabel .. "' with name: '" .. item.itemName .. "'")
    startCrafting(item)
end)

RegisterNetEvent('bcc-crafting:sendOngoingCraftingList')
AddEventHandler('bcc-crafting:sendOngoingCraftingList', function(ongoingCraftingList)
    devPrint("Received ongoing crafting list from server.")
    -- Ensure that 'currentLocationCategories' is passed when opening the menu
    openCraftingProgressMenu(ongoingCraftingList, currentLocationCategories)
end)

-- Client-side event handler for the 'bcc-crafting:sendCompletedCraftingList' event
RegisterNetEvent('bcc-crafting:sendCompletedCraftingList')
AddEventHandler('bcc-crafting:sendCompletedCraftingList', function(completedCraftingList)
    devPrint("Received completed crafting list from server.")
    -- Ensure that 'currentLocationCategories' is passed when opening the menu
    openCompletedCraftingMenu(completedCraftingList, currentLocationCategories)
end)

local showCraftBookcategory = false

BccUtils.RPC:Register("bcc-crafting:OpenCategoryMenu", function(params, cb)
	local categoryName = params.categoryName
	if not categoryName then
		devPrint("[ERROR] Category name is missing!")
		return cb(false)
	end

	-- Fetch formatted category list from the server
	local craftingData = BccUtils.RPC:CallAsync("bcc-crafting:GetCraftingData", { categories = { categoryName } })
	if not craftingData or not craftingData.categories or #craftingData.categories == 0 then
		devPrint("[ERROR] No valid crafting categories returned from server.")
		return cb(false)
	end

	currentLocationCategories = craftingData.categories
	TriggerEvent("bcc-crafting:openmenu", currentLocationCategories)

	cb(true)
end)

-- Function to open crafting item menu with item limit
function openCraftingItemMenu(item, categoryName, itemLimit)
	devPrint("Opening crafting item menu: " .. tostring(item.itemLabel) .. " in category: " .. tostring(categoryName))

	local imgPath = "nui://vorp_inventory/html/img/items/" .. item.itemName .. ".png"

	local requiredItemsHTML = ""
	for _, reqItem in ipairs(item.requiredItems) do
		local reqImgPath = "nui://vorp_inventory/html/img/items/" .. reqItem.itemName .. ".png"
		local label = reqItem.itemLabel
		local count = tonumber(reqItem.itemCount)

		requiredItemsHTML = requiredItemsHTML
			.. '<div style="display: flex; flex-direction: column; align-items: center; width: 90px; padding: 8px; border: 1px solid #ccc; border-radius: 6px;">'
			.. '<img src="'
			.. reqImgPath
			.. '" style="width: 48px; height: 48px; margin-bottom: 6px;" alt="'
			.. label
			.. '">'
			.. '<span style="text-align: center; font-size: 14px;">'
			.. label
			.. "</span>"
			.. '<span style="font-size: 13px; color: #666;">x'
			.. count
			.. "</span>"
			.. "</div>"
	end

	local requiredJobsHTML = ""
	if item.requiredJobs and #item.requiredJobs > 0 then
		for _, job in ipairs(item.requiredJobs) do
			requiredJobsHTML = requiredJobsHTML .. job
		end
	else
		requiredJobsHTML = "N/A"
	end

	local htmlContent = [[
	<div style="margin: auto; padding: 30px 30px 30px 30px;">

		<!-- Header: Image + Item Info Table -->
		<div style="display: flex; gap: 20px; align-items: flex-start; margin-bottom: 20px;">
			<div style="flex-shrink: 0;">
				<img src="]] .. imgPath .. [[" alt="]] .. item.itemLabel .. [[" style="width: 100px; height: 100px; border: 1px solid #bbb; border-radius: 6px;">
			</div>

			<table style="flex-grow: 1; width: 100%; border-collapse: collapse; font-size: 16px;">
				<tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 6px 10px;">]] .. _U("RequiredLevel") .. [[</td>
                    <td style="padding: 6px 10px; color: #2a9d8f;">]] .. (tonumber(item.requiredLevel)) .. [[</td>
                </tr>
                <tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 6px 10px;">]] .. _U("CraftTimeRemains") .. [[</td>
                    <td style="padding: 6px 10px; color: #e76f51;">]] .. (tonumber(item.duration)) .. " " .. _U("seconds") .. [[</td>
                </tr>
                <tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 6px 10px;">]] .. _U("RewardXp") .. [[</td>
                    <td style="padding: 6px 10px; color: #f4a261;">]] .. (tonumber(item.rewardXP)) .. [[ XP</td>
                </tr>
                <tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 6px 10px;">]] .. _U("CraftingLimit") .. [[</td>
                    <td style="padding: 6px 10px; color: #6c757d;">]] .. (itemLimit or "N/A") .. [[</td>
                </tr>
                <tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 6px 10px;">]] .. _U("CraftAmount") .. [[</td>
                    <td style="padding: 6px 10px; color: #264653;">]] .. (tonumber(item.itemAmount)) .. [[</td>
                </tr>
                <tr>
                    <td style="padding: 6px 10px;">]] .. _U("RequiredJobs") .. [[</td>
                    <td style="padding: 6px 10px; color: #6c5ce7;">]] .. requiredJobsHTML .. [[</td>
                </tr>

			</table>
		</div>

		<hr style="border: none; border-top: 1px solid #ccc; margin: 20px 0;">

		<!-- Required Items Grid -->
		<div>
			<h4 style="margin-bottom: 10px; font-size: 18px; font-weight: bold;">]] .. _U("RequiredItems") .. [[</h4>
			<div style="display: flex; flex-wrap: wrap; gap: 12px;">
				]] .. requiredItemsHTML .. [[
			</div>
		</div>
	</div>
]]

	-- Remaining logic unchanged...
	local itemMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:item:" .. item.itemName)
	itemMenu:RegisterElement("header", {
		value = item.itemLabel,
		slot = "header",
		style = {},
	})

	itemMenu:RegisterElement("line", {
		style = {},
		slot = "header",
	})

	itemMenu:RegisterElement("html", {
		value = { htmlContent },
		slot = "content",
		style = {},
	})

	itemMenu:RegisterElement("line", {
		style = {},
		slot = "footer",
	})

	-- Option to craft the item
	devPrint("Adding craft button for: " .. item.itemLabel)
	itemMenu:RegisterElement("button", {
		label = _U("CraftButton"),
		slot = "footer",
		style = {},
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
			openCraftingAmountInput(item, categoryName, currentLocationCategories, itemLimit)
        end
	end)

	itemMenu:RegisterElement("button", {
		label = _U("BackButton"),
		slot = "footer",
		style = {},
	}, function()
		TriggerEvent("bcc-crafting:openmenu", currentLocationCategories)
	end)

	itemMenu:RegisterElement("bottomline", {
		style = {},
		slot = "footer",
	})

	devPrint("Opening item menu for: " .. item.itemLabel)
	BCCCraftingMenu:Open({ startupPage = itemMenu })
end

-- Open crafting amount input menu

function openCraftingAmountInput(item, categoryName, currentLocationCategories, itemLimit)
    local inputValue = nil
	local craftingAmountMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:amountInput")

	-- Header
	craftingAmountMenu:RegisterElement("header", {
		value = item.itemLabel,
		slot = "header",
		style = {},
	})

	craftingAmountMenu:RegisterElement("line", {
		style = {},
		slot = "content",
	})

	-- Input field
	craftingAmountMenu:RegisterElement("input", {
		label = _U("EnterAmount"),
		placeholder = _U("AmountPlaceholder"),
		slot = "content",
		style = {},
	}, function(data)
		inputValue = tonumber(data.value) or 0 -- Update the input value
	end)

	craftingAmountMenu:RegisterElement("line", {
		style = {},
		slot = "footer",
	})

	-- Confirm button
	craftingAmountMenu:RegisterElement("button", {
		label = _U("ConfirmCraft") .. item.itemLabel,
		slot = "footer",
		style = {},
	}, function()
		-- Ensure inputValue is a valid number and greater than 0
		if inputValue and tonumber(inputValue) > 0 then
			attemptCraftItem(item, tonumber(inputValue))
		else
			devPrint("Invalid amount entered.")
			VORPcore.NotifyObjective(_U("InvalidAmount"), 4000)
		end
	end)

	-- Back button
	craftingAmountMenu:RegisterElement("button", {
		label = _U("BackButton"),
		slot = "footer",
		style = {},
	}, function()
		openCraftingItemMenu(item, categoryName, itemLimit)
	end)

	craftingAmountMenu:RegisterElement("bottomline", {
		style = {},
		slot = "footer",
	})

	BCCCraftingMenu:Open({ startupPage = craftingAmountMenu })
end

RegisterNetEvent("bcc-crafting:openmenu") -- ✅ Make it network-safe
AddEventHandler("bcc-crafting:openmenu", function(categories)
	devPrint("Opening main crafting menu with specific categories for the location")
	currentLocationCategories = categories
	showCraftBookcategory = false

	if HandlePlayerDeathAndCloseMenu() then
		devPrint("Player is dead, closing the menu")
		return
	end

	devPrint("Requesting crafting data from the server")
	local craftingData = BccUtils.RPC:CallAsync("bcc-crafting:GetCraftingData", { categories = categories })
	if not craftingData then
		VORPcore.NotifyRightTip("Failed to retrieve crafting data from the server.", 4000)
		devPrint("Failed to retrieve crafting data from the server.")
		return
	end

	local level = craftingData.level
	local xpToNextLevel = craftingData.xpToNextLevel
	local categories = craftingData.categories or {}

	devPrint("Crafting level: " .. tostring(level) .. ", XP to next level: " .. tostring(xpToNextLevel))

	local craftingMainMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:MainPage")

	craftingMainMenu:RegisterElement("header", {
		value = _U("Crafting"),
		slot = "header",
		style = {},
	})

	-- HTML Generator
	local function generateHtmlContent(item, imgPath)
		local label = item.itemLabel
		return '<div style="display: flex; align-items: center; width: 100%;">'
			.. '<img src="'
			.. imgPath
			.. '" style="width: 38px; height: 38px; margin-right: 10px;">'
			.. '<div style="text-align: center; flex-grow: 1;">'
			.. label
			.. "</div>"
			.. "</div>"
	end

	if type(categories) == "table" and #categories > 0 then
		for _, categoryData in ipairs(categories) do
			if categoryData.label and categoryData.name then
				-- Category Subheader
				craftingMainMenu:RegisterElement("subheader", {
					value = categoryData.label,
					style = { fontSize = "20px", bold = true, marginBottom = "5px", textAlign = "center" },
					slot = "content",
				})

				craftingMainMenu:RegisterElement("line", {
					style = {},
					slot = "content",
				})

				-- Find items for this category
				local matchedCategory = nil
				for _, loc in ipairs(CraftingLocations) do
					for _, cat in ipairs(loc.categories) do
						if cat.name == categoryData.name then
							matchedCategory = cat
							break
						end
					end
					if matchedCategory then
						break
					end
				end

				if matchedCategory and #matchedCategory.items > 0 then
					for _, item in ipairs(matchedCategory.items) do
						devPrint("Adding item to menu: " .. item.itemLabel)
						local imgPath = "nui://vorp_inventory/html/img/items/" .. item.itemName .. ".png"
						local htmlContent = generateHtmlContent(item, imgPath)

						craftingMainMenu:RegisterElement("button", {
							html = htmlContent,
							slot = "content",
						}, function()
							local currentItemName = item.itemName
							devPrint("Preparing to fetch limit for item:", currentItemName)
							fetchItemLimit(currentItemName, function(itemLimit)
								openCraftingItemMenu(item, categoryData.name, itemLimit)
							end)
						end)
					end
				else
					craftingMainMenu:RegisterElement("textdisplay", {
						value = _U("NotAvailable"),
						style = { fontSize = "16px", italic = true, marginBottom = "10px" },
						slot = "content",
					})
				end

				-- Spacer line between categories
				craftingMainMenu:RegisterElement("line", {
					style = {},
					slot = "content",
				})
			else
				devPrint("Invalid category data: Missing 'label' or 'name'")
			end
		end
	else
		devPrint("No crafting categories available or 'categories' is not a table.")
		craftingMainMenu:RegisterElement("textdisplay", {
			value = _U("NoAvailableCategories"),
			style = { fontSize = "18px" },
			slot = "content",
		})
	end

	-- Footer buttons
	craftingMainMenu:RegisterElement("line", {
		style = {},
		slot = "footer",
	})

	craftingMainMenu:RegisterElement("button", {
		label = _U("checkOngoing"),
		style = {},
		slot = "footer",
	}, function()
		TriggerServerEvent("bcc-crafting:getOngoingCrafting")
	end)

	craftingMainMenu:RegisterElement("button", {
		label = _U("checkCompleted"),
		style = {},
		slot = "footer",
	}, function()
		BccUtils.RPC:Call("bcc-crafting:GetCompletedCrafting", {}, function(completedCraftingData)
			if completedCraftingData then
				TriggerEvent("bcc-crafting:sendCompletedCraftingList", completedCraftingData)
			else
				VORPcore.NotifyRightTip(_U("NoCompletedCrafting"), 4000)
			end
		end)
	end)

	craftingMainMenu:RegisterElement("bottomline", {
		style = {},
		slot = "footer",
	})

	local subheaderHTML = [[
    <div style="margin: 15px auto; padding: 12px; max-width: 90%; background-color: rgba(10, 10, 10, 0.8); border: 1px solid #444; border-radius: 5px; box-shadow: 0 0 8px rgba(0,0,0,0.6);">
        <p style="text-align: center; font-weight: normal; color: #e0e0e0; text-shadow: 1px 1px 0 #000;">
            ]] .. _U("CraftingLevel"):lower() .. [[
            <span style="color: #FFD700; font-weight: bold;">]] .. tostring(level) .. [[</span>
        </p>
        <p style="text-align: center; font-weight: normal; color: #cccccc;">
            ]] .. _U("XpToNextLvl"):lower() .. [[
            <span style="color: #ADFF2F;">]] .. tostring(xpToNextLevel) .. [[ xp</span>
        </p>
    </div>
]]

	craftingMainMenu:RegisterElement("html", {
		value = { subheaderHTML },
		slot = "footer",
		style = {},
	})

	if Config.UseImageAtBottomMenu then
		devPrint("Adding image to the bottom of the crafting menu")
		craftingMainMenu:RegisterElement("html", {
			value = {
				'<img width="750px" height="108px" style="margin: 0 auto;" src="' .. Config.CraftImageURL .. '" />',
			},
			slot = "footer",
		})
	end

	devPrint("Opening crafting main menu")
	BCCCraftingMenu:Open({ startupPage = craftingMainMenu })
end)

local isCrafting = false

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
				requiredItems = json.encode(item.requiredItems),
			},
			remainingTime = duration,
		},
	}

	openCraftingProgressMenu(ongoingCraftingList, currentLocationCategories)
end

--- Function to display the list of ongoing crafting processes
function openCraftingProgressMenu(ongoingCraftingList, currentLocationCategories)
	devPrint("Opening progress menu for ongoing crafting processes.")

	local progressMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:progress:list")

	progressMenu:RegisterElement("header", {
		value = _U("ongoingProgress"),
		slot = "header",
		style = {},
	})

	progressMenu:RegisterElement("line", {
		style = {},
	})

	-- Create a list of ongoing crafting items
	if #ongoingCraftingList > 0 then
		local craftingListHtml = ""

		-- Loop through each ongoing crafting item
		for _, craftingData in ipairs(ongoingCraftingList) do
			local craftingLog = craftingData.craftingLog
			local remainingTime = craftingData.remainingTime
			local itemAmount = craftingLog.itemAmount
			local formattedTime = formatTime(remainingTime)

			-- Generate the HTML content for each crafting item, with default values if nil
			craftingListHtml = craftingListHtml
				.. string.format(
					[[
                <div style="text-align:center; margin: 20px 0; font-family: 'Crimson Text', serif; color: #4E342E;">
                    <p style="font-size:20px; font-weight: bold;">%s x%d</p>
                    <p style="font-size:18px; color: #8A2BE2;">%s %s</p>
                </div>
            ]],
					craftingLog.itemLabel or "Unknown Item",
					itemAmount,
					_U("remainingTime"),
					formattedTime
				)

			devPrint(
				"Ongoing crafting: "
					.. (craftingLog.itemLabel or "Unknown Item")
					.. " x"
					.. itemAmount
					.. ", Remaining Time: "
					.. formattedTime
			)
		end

		-- Register the HTML with the menu
		progressMenu:RegisterElement("html", {
			value = { craftingListHtml },
			slot = "content",
			style = {},
		})
	else
		-- If there are no ongoing crafting processes, display a message
		local noCraftingHtml = [[
            <div style="text-align:center; font-family: 'Crimson Text', serif; color: #4E342E;">
                <p style="font-size:20px; color: #B22222;">]] .. _U("NoOngoingProccess") .. [[</p>
            </div>
        ]]
		progressMenu:RegisterElement("html", {
			value = { noCraftingHtml },
			slot = "content",
			style = {},
		})

		devPrint("No ongoing crafting processes.")
	end

	progressMenu:RegisterElement("line", {
		style = {},
		slot = "footer",
	})

	progressMenu:RegisterElement("button", {
		label = _U("BackButton"),
		style = {},
		slot = "footer",
	}, function()
		devPrint("Returning to main menu from progress menu.")
		devPrint("currentLocationCategories: " .. json.encode(currentLocationCategories)) -- Debug print for categories
		BCCCraftingMenu:Close()

		TriggerEvent("bcc-crafting:openmenu", currentLocationCategories) -- Go back to the category list
	end)

	progressMenu:RegisterElement("bottomline", {
		style = {},
		slot = "footer",
	})

	devPrint("Opening progress menu.")
	BCCCraftingMenu:Open({ startupPage = progressMenu })
end

-- Function to handle progress for individual crafting items
function openCraftingItemProgressMenu(item, remainingTime)
	devPrint("Opening progress menu for item: " .. item.itemLabel .. ", Remaining Time: " .. remainingTime)

	local itemProgressMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:progress:" .. item.itemName)

	itemProgressMenu:RegisterElement("header", {
		value = _U("craftProgress") .. item.itemLabel,
		slot = "header",
		style = {},
	})

	itemProgressMenu:RegisterElement("text", {
		value = _U("craftRemaining") .. remainingTime .. _U("seconds"),
		style = { fontSize = "20px" },
	})

	itemProgressMenu:RegisterElement("line", {
		style = {},
		slot = "footer",
	})

	itemProgressMenu:RegisterElement("button", {
		label = _U("BackButton"),
		style = {},
		slot = "footer",
	}, function()
		devPrint("Returning to progress menu from item progress.")
		openCraftingProgressMenu(ongoingCraftingList, currentLocationCategories)
	end)

	devPrint("Opening item progress menu for: " .. item.itemLabel)
	BCCCraftingMenu:Open({ startupPage = itemProgressMenu })
end

-- Function to display the list of completed crafting processes for current location only
function openCompletedCraftingMenu(completedCraftingList, currentLocationCategories)
	devPrint("Completed crafting list (raw): " .. json.encode(completedCraftingList))

	local filteredList = {}
	for _, log in ipairs(completedCraftingList) do
		if log.locationId == currentCraftingLocationId or log.locationId == nil then
			table.insert(filteredList, log)
		end
	end

	devPrint("Filtered completed crafting list (for current location): " .. json.encode(filteredList))

	local completedMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:completed:list")

	-- Header for the completed crafting menu
	completedMenu:RegisterElement("header", {
		value = _U("craftCompleted"),
		slot = "header",
		style = {},
	})
	completedMenu:RegisterElement("line", { style = {} })

	-- Show items only if they exist after filtering
	if #filteredList > 0 then
		for index, craftingLog in ipairs(filteredList) do
			devPrint("Adding completed item to menu: " .. craftingLog.itemLabel .. " x" .. craftingLog.itemAmount)

			completedMenu:RegisterElement("button", {
				label = index .. _U("craftCollect") .. craftingLog.itemLabel .. " x " .. craftingLog.itemAmount,
				style = {},
			}, function()
				devPrint("Collecting crafted item: " .. craftingLog.itemLabel)

				BCCCraftingMenu:Close()
				BccUtils.RPC:Call("bcc-crafting:collectCraftedItem", {
					craftingLog = craftingLog,
					locationId = currentCraftingLocationId,
				}, function(success)
					if success then
						devPrint("Crafting item collected successfully!")
					else
						devPrint("Failed to collect the crafted item.")
					end

					BccUtils.RPC:Call("bcc-crafting:GetCompletedCrafting", {}, function(completedCraftingData)
						if completedCraftingData then
							devPrint("[DEBUG] Completed crafting data retrieved successfully.")
							TriggerEvent("bcc-crafting:sendCompletedCraftingList", completedCraftingData)
						else
							devPrint("[DEBUG] No completed crafting data found.")
							VORPcore.NotifyRightTip(_U("NoCompletedCrafting"), 4000)
						end
					end)
				end)
			end)
		end
	else
		devPrint("No completed crafting processes at current location.")
		completedMenu:RegisterElement("textdisplay", {
			value = _U("NoCompletedProccess"),
			style = { fontSize = "18px" },
		})
	end

	-- Footer
	completedMenu:RegisterElement("line", { style = {}, slot = "footer" })
	completedMenu:RegisterElement("button", {
		label = _U("BackButton"),
		style = {},
		slot = "footer",
	}, function()
		devPrint("Returning to main menu from completed crafting.")
		devPrint("currentLocationCategories: " .. json.encode(currentLocationCategories))
		TriggerEvent("bcc-crafting:openmenu", currentLocationCategories)
	end)
	completedMenu:RegisterElement("bottomline", { style = {}, slot = "footer" })

	devPrint("Opening filtered completed crafting menu.")
	BCCCraftingMenu:Open({ startupPage = completedMenu })
end

-- Client-side RPC to handle starting crafting
BccUtils.RPC:Register("bcc-crafting:StartCrafting", function(params, cb)
	local item = params.item
	if not item or not item.itemLabel or not item.itemName then
		devPrint("[ERROR] Missing or invalid item data for starting crafting.")
		return cb(false)
	end

	devPrint("Received RPC: StartCrafting for item: '" .. item.itemLabel .. "' with name: '" .. item.itemName .. "'")
	startCrafting(item)

	-- Indicate success
	cb(true)
end)

RegisterNetEvent("bcc-crafting:sendOngoingCraftingList")
AddEventHandler("bcc-crafting:sendOngoingCraftingList", function(ongoingCraftingList)
	devPrint("Received ongoing crafting list from server.")
	-- Ensure that 'currentLocationCategories' is passed when opening the menu
	openCraftingProgressMenu(ongoingCraftingList, currentLocationCategories)
end)

-- Client-side event handler for the 'bcc-crafting:sendCompletedCraftingList' event
RegisterNetEvent("bcc-crafting:sendCompletedCraftingList")
AddEventHandler("bcc-crafting:sendCompletedCraftingList", function(completedCraftingList)
	devPrint("Received completed crafting list from server.")
	-- Ensure that 'currentLocationCategories' is passed when opening the menu
	openCompletedCraftingMenu(completedCraftingList, currentLocationCategories)
end)

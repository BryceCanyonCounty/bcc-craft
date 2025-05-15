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
			..
			'<div style="display: flex; flex-direction: column; align-items: center; width: 90px; padding: 8px; border: 1px solid #ccc; border-radius: 6px;">'
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
				<img src="]] ..
		imgPath ..
		[[" alt="]] ..
		item.itemLabel .. [[" style="width: 100px; height: 100px; border: 1px solid #bbb; border-radius: 6px;">
			</div>

			<table style="flex-grow: 1; width: 100%; border-collapse: collapse; font-size: 16px;">
				<tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 6px 10px;">]] .. _U("RequiredLevel") .. [[</td>
                    <td style="padding: 6px 10px; color: #2a9d8f;">]] .. (tonumber(item.requiredLevel)) .. [[</td>
                </tr>
                <tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 6px 10px;">]] .. _U("CraftTimeRemains") .. [[</td>
                    <td style="padding: 6px 10px; color: #e76f51;">]] ..
		(tonumber(item.duration)) .. " " .. _U("seconds") .. [[</td>
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

function openCraftingAmountInput(item, categoryName, currentLocationCategories)
	local inputValue = nil
	-- First request max craftable amount
	BccUtils.RPC:Call("bcc-crafting:GetMaxCraftAmount", { item = item }, function(maxCraftable)
		if not maxCraftable then
			devPrint("[ERROR] Failed to get max craftable amount.")
			FeatherMenu:Notify({
				message = "Cannot determine how many items you can craft.",
				4000,
				type = "error",
				autoClose = 4000,
				position = "bottom-center",
				icon = false,
				hideProgressBar = false,
				rtl = false,
				transition = "slide",
				style = {},
				toastStyle = {},
				progressStyle = {}
			})
			return
		end

		-- Now continue to build the crafting amount menu
		local craftingAmountMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:amountInput")

		craftingAmountMenu:RegisterElement("header", {
			value = item.itemLabel,
			slot = "header",
			style = {},
		})

		craftingAmountMenu:RegisterElement("line", {
			style = {},
			slot = "content",
		})

		local htmlContent = '<div style="text-align: center; margin: 10px 0;">' ..
			'<span style="font-size: 18px; font-weight: bold; color: #4CAF50;">' ..
			_U('maxCraftAmount') .. maxCraftable ..
			'</span></div>'

		craftingAmountMenu:RegisterElement("html", {
			value = { htmlContent },
			slot = "content",
			style = {},
		})

		craftingAmountMenu:RegisterElement("input", {
			label = _U("EnterAmount"),
			placeholder = _U("AmountPlaceholder"),
			slot = "content",
			style = {},
		}, function(data)
			inputValue = tonumber(data.value) or 0
		end)

		craftingAmountMenu:RegisterElement("line", {
			style = {},
			slot = "footer",
		})

		craftingAmountMenu:RegisterElement("button", {
			label = _U("ConfirmCraft") .. item.itemLabel,
			slot = "footer",
			style = {},
		}, function()
			if inputValue and tonumber(inputValue) > 0 then
				attemptCraftItem(item, tonumber(inputValue))
			else
				devPrint("Invalid amount entered.")
				--[[FeatherMenu:Notify({
					message = _U("InvalidAmount"),
					type = "error",
					autoClose = 4000,
					position = "bottom-center",
					icon = false,
					hideProgressBar = false,
					rtl = false,
					transition = "slide",
					style = {},
					toastStyle = {},
					progressStyle = {}
				})]]
			end
		end)

		craftingAmountMenu:RegisterElement("button", {
			label = _U("BackButton"),
			slot = "footer",
			style = {},
		}, function()
			openCraftingItemMenu(item, categoryName)
		end)

		craftingAmountMenu:RegisterElement("bottomline", {
			style = {},
			slot = "footer",
		})

		-- Finally open the menu
		BCCCraftingMenu:Open({ startupPage = craftingAmountMenu })
	end)
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
		FeatherMenu:Notify({
			message = "Failed to retrieve crafting data from the server.",
			type = "error",
			autoClose = 4000,
			position = "bottom-center",
			icon = false,
			hideProgressBar = false,
			rtl = false,
			transition = "slide",
			style = {},
			toastStyle = {},
			progressStyle = {}
		})
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
				FeatherMenu:Notify({
					message = _U("NoCompletedCrafting"),
					type = "error",
					autoClose = 4000,
					position = "bottom-center",
					icon = false,
					hideProgressBar = false,
					rtl = false,
					transition = "slide",
					style = {},
					toastStyle = {},
					progressStyle = {}
				})
			end
		end)
	end)

	if Config.HasCraftBooks then
		craftingMainMenu:RegisterElement("button", {
			label = "📖 I-ati cartea de craftat",
			style = {},
			slot = "footer",
		}, function()
			openCraftbookSelectionMenu()
		end)
	end

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

local currentCraftbookPage = 1
local booksPerPage = 10

function openCraftbookSelectionMenu(page)
    local totalPages = math.ceil(#CraftingLocations / booksPerPage)
    currentCraftbookPage = page or 1

    local CraftBookMenu = BCCCraftingMenu:RegisterPage("bcc-crafting:craftbook:select:" .. currentCraftbookPage)

    CraftBookMenu:RegisterElement("header", {
        value = "📚 Alege o categorie",
        slot = "header",
        style = {}
    })

    local startIndex = (currentCraftbookPage - 1) * booksPerPage + 1
    local endIndex = math.min(startIndex + booksPerPage - 1, #CraftingLocations)

    for i = startIndex, endIndex do
        local location = CraftingLocations[i]
        local locationLabel = location.blip and location.blip.label or location.locationId or "Locatie necunoscuta"

        CraftBookMenu:RegisterElement("button", {
            label = " 📚  " .. locationLabel,
            style = {}
        }, function()
            openCraftbookLocationPage(location)
        end)
    end

    CraftBookMenu:RegisterElement("line", { 
		slot = "footer",
		style = {} 
	})

	CraftBookMenu:RegisterElement("pagearrows", {
		slot = "footer",
		total = totalPages,
		current = currentCraftbookPage,
		style = {}
	}, function(data)
		print("[DEBUG] Arrow pressed:", data.value)

		if data.value == "forward" and currentCraftbookPage < totalPages then
			openCraftbookSelectionMenu(currentCraftbookPage + 1)
		elseif data.value == "back" and currentCraftbookPage > 1 then
			openCraftbookSelectionMenu(currentCraftbookPage - 1)
		end
	end)

    -- Divider
    CraftBookMenu:RegisterElement("line", { 
		slot = "footer",
		style = {} 
	})

    CraftBookMenu:RegisterElement("button", {
        label = "⬅️ Inapoi",
        slot = "footer",
        style = {}
    }, function()
        TriggerEvent("bcc-crafting:openmenu", currentLocationCategories)
    end)

    CraftBookMenu:RegisterElement("bottomline", {
        slot = "footer",
        style = {}
    })

    BCCCraftingMenu:Open({ startupPage = CraftBookMenu })
end

function openCraftbookLocationPage(location)
    local locationLabel = location.blip and location.blip.label or location.locationId or "Locatie necunoscuta"
    local LocationPage = BCCCraftingMenu:RegisterPage("bcc-crafting:location:" .. location.locationId)

    -- Header
    LocationPage:RegisterElement("header", {
        value = "Carti - " .. locationLabel,
        slot = "header",
        style = { fontSize = "19px", fontWeight = "bold", marginBottom = "10px" }
    })

    -- 🔔 Requirements display
	LocationPage:RegisterElement("html", {
		value = { [[
			<div style="background: #1a1a1a;">
				<div style="font-size: 16px; font-weight: bold; color: #ffcc00;">🔒 Cerinte pentru a obtine o carte:</div>
				<ul style="margin-top: 5px; padding-left: 18px; color: #cccccc; font-size: 15px;">
					<li>💰 15.000$ bani</li>
					<li>🪙 100 AUR</li>
					<li>🧠 10.000 XP minim</li>
				</ul>
			</div>
		]] }
	})

    -- Location-wide book
    if location.craftbookCategory and location.craftbookCategory ~= "" then
        LocationPage:RegisterElement("button", {
            label = "📖 Cartea cu toate categoriile",
            style = { padding = "5px" },
        }, function()
            BccUtils.RPC:Call("bcc-crafting:giveBook", {
                item = location.craftbookCategory,
                label = locationLabel
            })
        end)
    end

    -- Divider
    LocationPage:RegisterElement("line", { style = { marginTop = "6px", marginBottom = "6px" } })

    -- Category books
    for _, category in ipairs(location.categories) do
        if category.craftBookItem and category.craftBookItem ~= "" then
            LocationPage:RegisterElement("button", {
                label = "📙 " .. (category.label or category.name),
                style = { padding = "4px" }
            }, function()
                BccUtils.RPC:Call("bcc-crafting:giveBook", {
                    item = category.craftBookItem,
                    label = category.label or category.name
                })
            end)
        end
    end

    -- Footer separator
    LocationPage:RegisterElement("line", {
        slot = "footer",
        style = {}
    })

    -- Back to locations
    LocationPage:RegisterElement("button", {
        label = "⬅️ Inapoi la locatii",
        slot = "footer",
        style = { marginTop = "10px", fontWeight = "bold" }
    }, function()
        openCraftbookSelectionMenu(currentCraftbookPage)
    end)

    LocationPage:RegisterElement("bottomline", { slot = "footer", style = {} })

    BCCCraftingMenu:Open({ startupPage = LocationPage })
end

local isCrafting = false

function startCrafting(item)
	devPrint("Crafting started for item: " .. item.itemLabel .. ", duration: " .. item.duration)

	local duration = item.duration                  -- Duration in seconds
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

			craftingListHtml = craftingListHtml .. [[
				<div style="text-align:center; margin: 20px 0; font-family: 'Crimson Text', serif; color: #4E342E;">
					<p style="font-size:20px; font-weight: bold;">]] ..
				(craftingLog.itemLabel or "Unknown Item") .. [[ x]] .. tostring(itemAmount) .. [[</p>
					<p style="font-size:18px; color: #8A2BE2;">]] .. _U("remainingTime") .. [[ ]] .. formattedTime .. [[</p>
				</div>
			]]

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
		devPrint("currentLocationCategories: " .. json.encode(currentLocationCategories)) -- Debug print for categories
		TriggerEvent("bcc-crafting:openmenu", currentLocationCategories)            -- Go back to the category list
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
							FeatherMenu:Notify({
								message = _U("NoCompletedCrafting"),
								type = "error",
								autoClose = 4000,
								position = "bottom-center",
								icon = false,
								hideProgressBar = false,
								rtl = false,
								transition = "slide",
								style = {},
								toastStyle = {},
								progressStyle = {}
							})
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

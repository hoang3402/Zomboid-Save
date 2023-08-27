function EasyLiterature:TakeAllNotFoundItemsFromContainer(container)

	local duplicates = {}

	local inventory = getPlayerInventory(0).inventoryPane.inventory

	local items = container:getItems()

	for i = 0, items:size() - 1 do

		local item = items:get(i)

		local literature_type = self:GetLiteratureItemType(item)

		if literature_type then

			local item_id = self:GetLiteratureItemID(item, literature_type)

			if not self.ModData.Data[item_id] and not duplicates[item_id] then

				duplicates[item_id] = true

				ISTimedActionQueue.add(ISInventoryTransferAction:new(getPlayer(), item, container, inventory))

			end

		end

	end

end

function EasyLiterature:MarkAllItemsAsFound(container)

	local items = container:getItems()

	for i = 0, items:size() - 1 do

		local item = items:get(i)

		local literature_type = self:GetLiteratureItemType(item)

		if literature_type then

			self.ModData.Data[self:GetLiteratureItemID(item, literature_type)] = true

		end

	end

	EasyLiteratureMenu:Refresh()

end

function EasyLiterature:MarkAllItemsAsNotFound(container)

	local items = container:getItems()

	for i = 0, items:size() - 1 do

		local item = items:get(i)

		local literature_type = self:GetLiteratureItemType(item)

		if literature_type then

			self.ModData.Data[self:GetLiteratureItemID(item, literature_type)] = nil

		end

	end

	EasyLiteratureMenu:Refresh()

end

function EasyLiterature:DropDuplicateItems(container, player_num)

	local duplicates = {}

	local items = container:getItems()

	for i = 0, items:size() - 1 do

		local item = items:get(i)

		local literature_type = self:GetLiteratureItemType(item)

		if literature_type then

			local item_id = self:GetLiteratureItemID(item, literature_type)

			if duplicates[item_id] then

				ISInventoryPaneContextMenu.dropItem(item, player_num)

			else

				duplicates[item_id] = true

			end

		end

	end

end

local function fill_available_literature_list_by_inventory(player, items, available_literature)

	for i = 0, items:size() - 1 do

		local item = items:get(i)
		
		if instanceof(item, 'Literature') then

			local skill_book = SkillBook[item:getSkillTrained()]

			if skill_book then

				if EasyLiterature:GetLiteratureItemKnownStatus(item, "SkillBook", player, skill_book.perk) == 2 then

					available_literature.SkillBooks[#available_literature.SkillBooks + 1] = item

				end
		
			else
			
				local teached_recipes = item:getTeachedRecipes()

				if teached_recipes then

					if EasyLiterature:GetLiteratureItemKnownStatus(item, "RecipesMagazine", player, teached_recipes) == 2 then

						available_literature.RecipesMagazines[#available_literature.RecipesMagazines + 1] = item
	
					end
			
				end

			end

		end

	end

end

local function getAvailableLiterature(player_num)

	local player = getSpecificPlayer(player_num)
	
	local available_literature = {
		SkillBooks = {},
		RecipesMagazines = {},
	}

	local player_inventory = getPlayerInventory(player_num).inventoryPane.inventoryPage.backpacks

	for i = 1, #player_inventory do

		fill_available_literature_list_by_inventory(player, player_inventory[i].inventory:getItems(), available_literature)

	end

	local player_loot = getPlayerLoot(player_num).inventoryPane.inventoryPage.backpacks

	for i = 1, #player_loot do

		fill_available_literature_list_by_inventory(player, player_loot[i].inventory:getItems(), available_literature)

	end

	return available_literature

end
EasyLiterature.GetAvailableLiterature = getAvailableLiterature

function EasyLiterature:ReadAvailableLiterature(player_num)

	local player = getSpecificPlayer(player_num)
	
	local player_inventory = player:getInventory()

	local available_literature = getAvailableLiterature(player_num)

	local available_skill_books = available_literature.SkillBooks

	for i = 1, #available_skill_books do

		local item = available_skill_books[i]

		local container = item:getContainer()
		
		if player_inventory ~= container then

			ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, player_inventory, container))

		end

		ISInventoryPaneContextMenu.readItem(item, player_num)

		if player_inventory ~= container then

			ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, container, player_inventory))

		end

	end

	local available_recipes_magazines = available_literature.RecipesMagazines

	for i = 1, #available_recipes_magazines do
		
		local item = available_recipes_magazines[i]

		local container = item:getContainer()
		
		if player_inventory ~= container then

			ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, player_inventory, container))

		end

		ISInventoryPaneContextMenu.readItem(item, player_num)

		if player_inventory ~= container then

			ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, container, player_inventory))

		end

	end

end

local function createSubMenu(player_num, context, items)

	local item = items[1].items and items[1].items[1] or items[1]

	local literature_type = EasyLiterature:GetLiteratureItemType(item)

	if not literature_type then
		return
	end

	local literature_id = EasyLiterature:GetLiteratureItemID(item, literature_type)

	local container = item:getContainer()

	local sub_menu = ISContextMenu:getNew(context)

	context:addSubMenu(
		context:addOption(getText("ContextMenu_Easy_Literature")),
		sub_menu
	)

	sub_menu:addOption(getText("ContextMenu_Easy_Literature_Open_Menu"), nil, function()

		EasyLiteratureMenu:Open()
	
	end)

	sub_menu:addOption(getText("ContextMenu_Easy_Literature_Take_Not_Found_Items"), container, function(container)

		EasyLiterature:TakeAllNotFoundItemsFromContainer(container)

	end)

	local found_sub_menu = ISContextMenu:getNew(sub_menu)

	sub_menu:addSubMenu(
		sub_menu:addOption(getText("ContextMenu_Easy_Literature_Mark_As_Found")),
		found_sub_menu
	)

	found_sub_menu:addOption(getText("ContextMenu_Easy_Literature_Mark_As_Found_Selected"), container, function(container)

		EasyLiterature.ModData.Data[literature_id] = true

		EasyLiteratureMenu:Refresh()

	end)

	found_sub_menu:addOption(getText("ContextMenu_Easy_Literature_Mark_As_Found_All"), container, function(container)

		EasyLiterature:MarkAllItemsAsFound(container)

	end)

	local not_found_sub_menu = ISContextMenu:getNew(sub_menu)

	sub_menu:addSubMenu(
		sub_menu:addOption(getText("ContextMenu_Easy_Literature_Mark_As_Not_Found")),
		not_found_sub_menu
	)

	not_found_sub_menu:addOption(getText("ContextMenu_Easy_Literature_Mark_As_Not_Found_Selected"), container, function(container)

		EasyLiterature.ModData.Data[literature_id] = nil

		EasyLiteratureMenu:Refresh()

	end)

	not_found_sub_menu:addOption(getText("ContextMenu_Easy_Literature_Mark_As_Not_Found_All"), container, function(container)

		EasyLiterature:MarkAllItemsAsNotFound(container)

	end)

	sub_menu:addOption(getText("ContextMenu_Easy_Literature_Drop_Duplicate_Items"), container, function(container)

		EasyLiterature:DropDuplicateItems(container, player_num)

	end)

	sub_menu:addOption(getText("ContextMenu_Easy_Literature_Read_Available_Literature"), container, function()

		EasyLiterature:ReadAvailableLiterature(player_num)

	end)

end

Events.OnFillInventoryObjectContextMenu.Add(createSubMenu)
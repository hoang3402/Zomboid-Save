require("ISUI/ISPanel")
local timer = require("easy_literature_lua_timers.lua")

local EasyLiterature = EasyLiterature

local pairs = pairs
local getText = getText
local getWidth = ISUIElement.getWidth
local getHeight = ISUIElement.getHeight
local drawRect = ISUIElement.drawRect
local drawRectStatic = ISUIElement.drawRectStatic
local drawRectBorder = ISUIElement.drawRectBorder
local drawRectBorderStatic = ISUIElement.drawRectBorderStatic
local drawText = ISUIElement.drawText
local drawTextCentre = ISUIElement.drawTextCentre
local isVisible = ISUIElement.isVisible
local getYScroll = ISScrollingListBox.getYScroll
local addItem = ISScrollingListBox.addItem
local string_find = string.find
local string_lower = string.lower
local string_trim = string.trim
local getItemNameFromFullType = getItemNameFromFullType
local getInternalText = ISTextEntryBox.getInternalText
local ISTextEntryBox_getText = ISTextEntryBox.getText

if EasyLiteratureMenu and EasyLiteratureMenu.Panel then

	EasyLiteratureMenu.Panel:setVisible(false)
	EasyLiteratureMenu.Panel:removeFromUIManager()
	EasyLiteratureMenu.Panel = nil

end

EasyLiteratureMenu = ISPanel:derive("EasyLiteratureMenu")

EasyLiteratureMenu.FontSize = {
	Small = getTextManager():getFontHeight(UIFont.Small),
	Medium = getTextManager():getFontHeight(UIFont.Medium),
	Large = getTextManager():getFontHeight(UIFont.Large),
}

local function getTextWidth(font, text)

	return getTextManager():MeasureStringX(font or UIFont.Small, text or "")

end

function EasyLiteratureMenu:new()

	self.width = 900
	self.height = 500
	
	local panel = ISPanel:new(
		(getCore():getScreenWidth() - self.width) / 2,
		(getCore():getScreenHeight() - self.height) / 2,
		self.width,
		self.height
	)
	setmetatable(panel, self)
	self.__index = self

	panel.moveWithMouse = true
	
	panel.borderColor = {r = .4, g = .4, b = .4, a = 1}
	panel.backgroundColor = {r = 0, g = 0, b = 0, a = .85}

	return panel

end

function EasyLiteratureMenu:Open()

	if self.Panel then

		self.Panel:setVisible(true)
		self.Panel:addToUIManager()
		self:Refresh()

	else

		self.Panel = self:new()
		self.Panel:initialise()
		self.Panel:addToUIManager()
	
	end

end

function EasyLiteratureMenu:prerender()
	
	drawRect(self, 0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
	
	drawRectBorder(self, 0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
	
	drawTextCentre(self, self.HeaderText, self:getCentreX(), 10, 1, 1, 1, 1, UIFont.Large)

end

function EasyLiteratureMenu:initialise()
	
	ISPanel.initialise(self)

	self.HeaderText = getText("IGUI_Easy_Literature_Menu_Header")

	self.SettingsButton = ISButton:new(10, 10, 100, 2 + self.FontSize.Medium + 2, getText("IGUI_Easy_Literature_Menu_Settings"), self, function(pnl)

		self.SettingsButton.Opened = not self.SettingsButton.Opened
	
		if self.SettingsButton.Opened then

			self.HeaderText = getText("IGUI_Easy_Literature_Menu_Settings")

			self.SettingsButton:setTitle(getText("IGUI_Easy_Literature_Menu_Back"))

			self:HideFoundLiteraturePage()
			self:ShowFoundLiteratureSettingsPage()

		else
			
			self.HeaderText = getText("IGUI_Easy_Literature_Menu_Header")

			self.SettingsButton:setTitle(getText("IGUI_Easy_Literature_Menu_Settings"))

			self:HideFoundLiteratureSettingsPage()
			self:ShowFoundLiteraturePage()

			if self.NeedRefresh then

				self:Refresh()

			end

		end
		
	end)
	self.SettingsButton:initialise()
	self.SettingsButton:instantiate()
	self.SettingsButton.borderColor = {r = 1, g = 1, b = 1, a = 1}
	self.SettingsButton:setFont(UIFont.Medium)
	self.SettingsButton:setWidth(
		3 + math.max(
			getTextWidth(UIFont.Medium, getText("IGUI_Easy_Literature_Menu_Settings")),
			getTextWidth(UIFont.Medium, getText("IGUI_Easy_Literature_Menu_Back"))
		) + 10 + 3
	)
	self.SettingsButton.Opened = false
	self:addChild(self.SettingsButton)

	local close_button_text = getText("IGUI_Easy_Literature_Menu_Close")
	local close_button_text_width = getTextWidth(UIFont.Small, close_button_text)

	self.CloseButton = ISButton:new(self:getWidth() - close_button_text_width - 20,	10,	0, 2 + self.FontSize.Medium + 2, close_button_text, self,	function()

		self.Panel:setVisible(false)
		self.Panel:removeFromUIManager()
	
	end)
	self.CloseButton:initialise()
	self.CloseButton:instantiate()
	self.CloseButton.borderColor = {r = 1, g = 1, b = 1, a = 1}
	self.CloseButton:setFont(UIFont.Medium)
	self.CloseButton:setWidthToTitle()
	self.CloseButton:setWidth(3 + self.CloseButton:getWidth() + 3)
	self.CloseButton:setX(self:getWidth() - self.CloseButton:getWidth() - 10)
	self:addChild(self.CloseButton)

	self:CreateFoundLiteratureSettingsPage()
	self:HideFoundLiteratureSettingsPage()

	self:CreateFoundLiteraturePage()

end

function EasyLiteratureMenu:update()

	if self.SearchBar.LastText ~= getInternalText(self.SearchBar) then

		local text = getInternalText(self.SearchBar)

		self.SearchBar.LastText = text

		text = string_trim(text)

		self:FillLists(text ~= "" and string_lower(text))

	end

end

function EasyLiteratureMenu:Refresh()

	local panel = self.Panel

	if panel and isVisible(panel) then

		local text = string_trim(getInternalText(panel.SearchBar))

		panel:FillLists(text ~= "" and string_lower(text))

	end

	self.NeedRefresh = false

end

function EasyLiteratureMenu:CreateFoundLiteraturePage()

	self.SelectCategory = EasyLiteratureCategorySelectComboBoxButton:new(10, self.SettingsButton:getBottom() + 10, 0, 2 + self.FontSize.Medium + 2)
	self.SelectCategory:initialise()
	self:addChild(self.SelectCategory)

	self.SearchBar = ISTextEntryBox:new("", self.SelectCategory:getRight() + 10, self.SelectCategory:getY(), - 10 + self:getWidth() - 10 - self.SelectCategory:getWidth() - 10, self.SelectCategory:getHeight())
	self.SearchBar:initialise()
	self.SearchBar.font = UIFont.Medium
	self.SearchBar.borderColor = {r = 1, g = 1, b = 1, a = 1}
	self.SearchBar:instantiate()
	self.SearchBar:setMaxTextLength(100)
	self.SearchBar.Placeholder = getText("IGUI_Easy_Literature_Menu_Literature_Name_Filter")
	self.SearchBar._prerender = self.SearchBar.prerender
	self.SearchBar.prerender = function(pnl)

		pnl:_prerender()

		if ISTextEntryBox_getText(pnl) == "" then

			drawText(pnl, pnl.Placeholder, 2, 2, .4, .4, .4, 1, pnl.font)

		end

	end
	self.SearchBar.LastText = ""

	self:addChild(self.SearchBar)

	self.NotFoundLiteratureListHeader = ISUIElement:new(
		10,
		self.SearchBar:getBottom() + 10,
		-10 + self:getWidth() / 2 - 10 - 25 - 5,
		28
	)
	self.NotFoundLiteratureListHeader.render = function(pnl)

		drawRectBorder(pnl, 0, 0, pnl.width, pnl.height, 1, 1, 1, 1);
		
		drawTextCentre(pnl, pnl.Title, pnl:getCentreX(), 4, 1, 1, 1, 1, UIFont.Medium)

	end
	self.NotFoundLiteratureListHeader.Title = getText("IGUI_Easy_Literature_Menu_Not_Found")
	self:addChild(self.NotFoundLiteratureListHeader)

	self.NotFoundLiteratureList = ISScrollingListBox:new(
		10,
		self.NotFoundLiteratureListHeader:getBottom(),
		-10 + self:getWidth() / 2 - 10 - 25 - 5,
		self:getHeight() - self.NotFoundLiteratureListHeader:getBottom() - 10
	)
	self.NotFoundLiteratureList:initialise()
	self.NotFoundLiteratureList:instantiate()
	self.NotFoundLiteratureList.drawBorder = true
	self.NotFoundLiteratureList:setFont(UIFont.Medium, 2)
	self.NotFoundLiteratureList.itemwidth = self.NotFoundLiteratureList:getWidth()
	self.NotFoundLiteratureList.itemheight = self.FontSize.Medium + 10
	self.NotFoundLiteratureList.textOffsetX = 5
	self.NotFoundLiteratureList.textOffsetY = (self.NotFoundLiteratureList.itemheight - getTextManager():MeasureStringY(self.NotFoundLiteratureList.font, "A")) / 2
	self.NotFoundLiteratureList.selected = 0
	self.NotFoundLiteratureList.doDrawItem = function(pnl, y, item)

		local y_scroll = getYScroll(pnl)

		if y + y_scroll + pnl.itemheight < 0 or y + y_scroll > pnl.height then
			
			return y + pnl.itemheight

		end

		drawRectBorder(pnl, 0, y, pnl.itemwidth, pnl.itemheight, 0.9, .4, .4, .4)
		
		drawText(pnl, item.text, pnl.textOffsetX, y + pnl.textOffsetY, 1, 1, 1, 0.9, pnl.font)
		
		if pnl.selected == item.index then

			drawRect(pnl, 0, y, pnl.itemwidth, pnl.itemheight, 0.3, 0.7, 0.35, 0.15)

		end

		return y + pnl.itemheight

	end
	self.NotFoundLiteratureList.AddItemBySharedIndex = function(pnl, text, item, shared_index)

		for i = 1, #pnl.items do

			local iter_item = pnl.items[i]

			if iter_item.shared_index > shared_index then

				return pnl:insertItem(i, text, item)

			end
			
		end

		return pnl:addItem(text, item)

	end
	self.NotFoundLiteratureList.onmousedblclick = function()

		local selected_id = self.NotFoundLiteratureList.selected

		if selected_id == 0 then
			return
		end

		local selected = self.NotFoundLiteratureList.items[selected_id]

		local id = selected.item.ID

		EasyLiterature.ModData.Data[id] = true

		local removed_item = self.NotFoundLiteratureList:removeItem(selected.text)

		local added_item = self.FoundLiteratureList:AddItemBySharedIndex(removed_item.text, removed_item.item, removed_item.shared_index)
		
		added_item.tooltip = removed_item.text
		added_item.shared_index = removed_item.shared_index

	end
	self:addChild(self.NotFoundLiteratureList)

	self.FoundLiteratureListHeader = ISUIElement:new(
		self.NotFoundLiteratureList:getRight() + 10 + 25 + 10 + 25 + 10,
		self.SearchBar:getBottom() + 10,
		-10 + self:getWidth() / 2 - 10 - 25 - 5,
		28
	)
	self.FoundLiteratureListHeader.render = function(pnl)

		drawRectBorder(pnl, 0, 0, pnl.width, pnl.height, 1, 1, 1, 1);
		
		drawTextCentre(pnl, pnl.Title, pnl:getCentreX(), 4, 1, 1, 1, 1, UIFont.Medium)

	end
	self.FoundLiteratureListHeader.Title = getText("IGUI_Easy_Literature_Menu_Found")
	self:addChild(self.FoundLiteratureListHeader)

	self.FoundLiteratureList = ISScrollingListBox:new(
		self.NotFoundLiteratureList:getRight() + 10 + 25 + 10 + 25 + 10,
		self.FoundLiteratureListHeader:getBottom(),
		-10 + self:getWidth() / 2 - 10 - 25 - 5,
		self:getHeight() - self.FoundLiteratureListHeader:getBottom() - 10
	)
	self.FoundLiteratureList:initialise()
	self.FoundLiteratureList:instantiate()
	self.FoundLiteratureList.drawBorder = true
	self.FoundLiteratureList:setFont(UIFont.Medium, 2)
	self.FoundLiteratureList.itemwidth = self.FoundLiteratureList:getWidth()
	self.FoundLiteratureList.itemheight = self.FontSize.Medium + 10
	self.FoundLiteratureList.textOffsetX = 5
	self.FoundLiteratureList.textOffsetY = (self.FoundLiteratureList.itemheight - getTextManager():MeasureStringY(self.FoundLiteratureList.font, "A")) / 2
	self.FoundLiteratureList.selected = 0
	self.FoundLiteratureList.doDrawItem = function(pnl, y, item)

		local y_scroll = getYScroll(pnl)

		if y + y_scroll + pnl.itemheight < 0 or y + y_scroll > pnl.height then
			
			return y + pnl.itemheight

		end

		drawRectBorder(pnl, 0, y, pnl.itemwidth, pnl.itemheight, 0.9, .4, .4, .4)
		
		drawText(pnl, item.text, pnl.textOffsetX, y + pnl.textOffsetY, 1, 1, 1, 0.9, pnl.font)
		
		if pnl.selected == item.index then

			drawRect(pnl, 0, y, pnl.itemwidth, pnl.itemheight, 0.3, 0.7, 0.35, 0.15)

		end

		return y + pnl.itemheight

	end
	self.FoundLiteratureList.AddItemBySharedIndex = function(pnl, text, item, shared_index)

		for i = 1, #pnl.items do

			local iter_item = pnl.items[i]

			if iter_item.shared_index > shared_index then

				return pnl:insertItem(i, text, item)

			end
			
		end

		return pnl:addItem(text, item)

	end
	self.FoundLiteratureList.onmousedblclick = function()

		local selected_id = self.FoundLiteratureList.selected

		if selected_id == 0 then
			return
		end

		local selected = self.FoundLiteratureList.items[selected_id]

		local id = selected.item.ID

		EasyLiterature.ModData.Data[id] = nil

		local text = selected.text

		local removed_item = self.FoundLiteratureList:removeItem(selected.text)

		local added_item = self.NotFoundLiteratureList:AddItemBySharedIndex(removed_item.text, removed_item.item, removed_item.shared_index)
		
		added_item.tooltip = removed_item.text
		added_item.shared_index = removed_item.shared_index

	end
	self:addChild(self.FoundLiteratureList)

	self.MoveToFoundLiterature = ISButton:new(self.NotFoundLiteratureList:getRight() + 10, self.NotFoundLiteratureList:getY(), 25, self.NotFoundLiteratureList:getHeight(), ">", self, self.NotFoundLiteratureList.onmousedblclick)
	self.MoveToFoundLiterature:initialise()
	self.MoveToFoundLiterature:instantiate()
	self.MoveToFoundLiterature.borderColor = {r = 1, g = 1, b = 1, a = 1}
	self.MoveToFoundLiterature:setFont(UIFont.Large)
	self:addChild(self.MoveToFoundLiterature)

	self.MoveToNotFoundLiterature = ISButton:new(self.MoveToFoundLiterature:getRight() + 10, self.MoveToFoundLiterature:getY(), 25, self.MoveToFoundLiterature:getHeight(), "<", self, self.FoundLiteratureList.onmousedblclick)
	self.MoveToNotFoundLiterature:initialise()
	self.MoveToNotFoundLiterature:instantiate()
	self.MoveToNotFoundLiterature.borderColor = {r = 1, g = 1, b = 1, a = 1}
	self.MoveToNotFoundLiterature:setFont(UIFont.Large)
	self:addChild(self.MoveToNotFoundLiterature)

	self:FillLists()

end

function EasyLiteratureMenu:AddLiteratureItem(list, name, sort_order, id, shared_index)

	local added_item = addItem(list, name, {
		SortOrder = sort_order,
		ID = id,
	})

	added_item.tooltip = name
	added_item.shared_index = shared_index

end

function EasyLiteratureMenu:FillLists(filter)
	
	local not_found_literature_list = self.NotFoundLiteratureList
	local found_literature_list = self.FoundLiteratureList

	not_found_literature_list:clear()
	found_literature_list:clear()

	local shared_index = 0

	local literature_lists_items_data = {
		{},
		{},
	}

	if EasyLiterature.ModData.Settings.Categories["SkillBooks"] then

		for _, skill_book_names in pairs(EasyLiterature.LiteratureList.SkillBooks) do

			for _, item_id in pairs(skill_book_names) do

				shared_index = shared_index + 1

				local item_name = getItemNameFromFullType(item_id)
				
				if not filter or string_find(string_lower(item_name), filter) then

					if not EasyLiterature.ModData.Data[item_id] then

						literature_lists_items_data[1][#literature_lists_items_data[1] + 1] = {
							Name = item_name,
							SortOrder = 1,
							ID = item_id,
							SharedIndex = shared_index,
						}
			
					else

						literature_lists_items_data[2][#literature_lists_items_data[2] + 1] = {
							Name = item_name,
							SortOrder = 1,
							ID = item_id,
							SharedIndex = shared_index,
						}
			
					end

				end

			end

		end

	end

	if EasyLiterature.ModData.Settings.Categories["RecipesMagazines"] then

		for _, item_id in pairs(EasyLiterature.LiteratureList.RecipeMagazines) do

			shared_index = shared_index + 1

			local item_name = getItemNameFromFullType(item_id)
			
			if not filter or string_find(string_lower(item_name), filter) then

				if not EasyLiterature.ModData.Data[item_id] then

					literature_lists_items_data[1][#literature_lists_items_data[1] + 1] = {
						Name = item_name,
						SortOrder = 2,
						ID = item_id,
						SharedIndex = shared_index,
					}
		
				else

					literature_lists_items_data[2][#literature_lists_items_data[2] + 1] = {
						Name = item_name,
						SortOrder = 2,
						ID = item_id,
						SharedIndex = shared_index,
					}
		
				end

			end

		end

	end

	local recorded_media = getZomboidRadio():getRecordedMedia()

	if EasyLiterature.ModData.Settings.Categories["VHS"] then

		for _, item_id in pairs(EasyLiterature.LiteratureList.VHS) do

			shared_index = shared_index + 1

			local item_name = recorded_media:getMediaData(item_id):getTranslatedItemDisplayName()

			if not filter or string_find(string_lower(item_name), filter) then

				if not EasyLiterature.ModData.Data[item_id] then

					literature_lists_items_data[1][#literature_lists_items_data[1] + 1] = {
						Name = item_name,
						SortOrder = 3,
						ID = item_id,
						SharedIndex = shared_index,
					}
		
				else

					literature_lists_items_data[2][#literature_lists_items_data[2] + 1] = {
						Name = item_name,
						SortOrder = 3,
						ID = item_id,
						SharedIndex = shared_index,
					}
		
				end

			end

		end

	end

	if EasyLiterature.ModData.Settings.Categories["HomeVHS"] then

		for _, item_id in pairs(EasyLiterature.LiteratureList.HomeVHS) do

			shared_index = shared_index + 1

			local item_name = recorded_media:getMediaData(item_id):getTranslatedItemDisplayName()

			if not filter or string_find(string_lower(item_name), filter) then

				if not EasyLiterature.ModData.Data[item_id] then

					literature_lists_items_data[1][#literature_lists_items_data[1] + 1] = {
						Name = item_name,
						SortOrder = 4,
						ID = item_id,
						SharedIndex = shared_index,
					}
		
				else

					literature_lists_items_data[2][#literature_lists_items_data[2] + 1] = {
						Name = item_name,
						SortOrder = 4,
						ID = item_id,
						SharedIndex = shared_index,
					}
		
				end

			end

		end

	end

	if EasyLiterature.ModData.Settings.Categories["CD"] then

		for _, item_id in pairs(EasyLiterature.LiteratureList.CD) do

			shared_index = shared_index + 1

			local item_name = recorded_media:getMediaData(item_id):getTranslatedItemDisplayName()

			if not filter or string_find(string_lower(item_name), filter) then

				if not EasyLiterature.ModData.Data[item_id] then

					literature_lists_items_data[1][#literature_lists_items_data[1] + 1] = {
						Name = item_name,
						SortOrder = 5,
						ID = item_id,
						SharedIndex = shared_index,
					}
		
				else

					literature_lists_items_data[2][#literature_lists_items_data[2] + 1] = {
						Name = item_name,
						SortOrder = 5,
						ID = item_id,
						SharedIndex = shared_index,
					}
		
				end

			end

		end

	end

	if EasyLiterature:NeedModSupport("TrueActionsDancing") then

		if EasyLiterature.ModData.Settings.Categories["TrueActionsDancingMagazines"] then

			for _, item_id in pairs(EasyLiterature.LiteratureList.TrueActionsDancingMagazines) do

				shared_index = shared_index + 1

				local item_name = getItemNameFromFullType(item_id)
				
				if not filter or string_find(string_lower(item_name), filter) then

					if not EasyLiterature.ModData.Data[item_id] then

						literature_lists_items_data[1][#literature_lists_items_data[1] + 1] = {
							Name = item_name,
							SortOrder = 6,
							ID = item_id,
							SharedIndex = shared_index,
						}
			
					else

						literature_lists_items_data[2][#literature_lists_items_data[2] + 1] = {
							Name = item_name,
							SortOrder = 6,
							ID = item_id,
							SharedIndex = shared_index,
						}
			
					end

				end

			end

		end

		if EasyLiterature.ModData.Settings.Categories["TrueActionsDancingCards"] then

			for _, item_id in pairs(EasyLiterature.LiteratureList.TrueActionsDancingCards) do

				shared_index = shared_index + 1

				local item_name = getItemNameFromFullType(item_id)

				if not filter or string_find(string_lower(item_name), filter) then

					if not EasyLiterature.ModData.Data[item_id] then

						literature_lists_items_data[1][#literature_lists_items_data[1] + 1] = {
							Name = item_name,
							SortOrder = 7,
							ID = item_id,
							SharedIndex = shared_index,
						}
			
					else

						literature_lists_items_data[2][#literature_lists_items_data[2] + 1] = {
							Name = item_name,
							SortOrder = 7,
							ID = item_id,
							SharedIndex = shared_index,
						}
			
					end

				end

			end

		end

	end

	if EasyLiterature:NeedModSupport("SpiffoTradingCards") then

		if EasyLiterature.ModData.Settings.Categories["SpiffoTradingCards"] then

			for _, item_id in pairs(EasyLiterature.LiteratureList.SpiffoTradingCards) do

				shared_index = shared_index + 1

				local item_name = getItemNameFromFullType(item_id)

				if not filter or string_find(string_lower(item_name), filter) then

					if not EasyLiterature.ModData.Data[item_id] then

						literature_lists_items_data[1][#literature_lists_items_data[1] + 1] = {
							Name = item_name,
							SortOrder = 8,
							ID = item_id,
							SharedIndex = shared_index,
						}
			
					else

						literature_lists_items_data[2][#literature_lists_items_data[2] + 1] = {
							Name = item_name,
							SortOrder = 8,
							ID = item_id,
							SharedIndex = shared_index,
						}
			
					end

				end

			end

		end

	end

	if EasyLiterature:NeedModSupport("ATCGbyWulf") then

		if EasyLiterature.ModData.Settings.Categories["ATCGbyWulfCards"] then

			for _, item_id in pairs(EasyLiterature.LiteratureList.ATCGbyWulfCards) do

				shared_index = shared_index + 1

				local item_name = getItemNameFromFullType(item_id)

				if not filter or string_find(string_lower(item_name), filter) then

					if not EasyLiterature.ModData.Data[item_id] then

						literature_lists_items_data[1][#literature_lists_items_data[1] + 1] = {
							Name = item_name,
							SortOrder = 9,
							ID = item_id,
							SharedIndex = shared_index,
						}
			
					else

						literature_lists_items_data[2][#literature_lists_items_data[2] + 1] = {
							Name = item_name,
							SortOrder = 9,
							ID = item_id,
							SharedIndex = shared_index,
						}
			
					end

				end

			end

		end

	end

	if EasyLiterature:GetSettingsValue("LazyListsFill") then

		do

			local leave_count = #literature_lists_items_data[1]

			local len = #literature_lists_items_data[1]
			local start_from = 1

			timer:Create("EasyLiterature:LazyListsFill:NotFoundList", 0, 0, function()

				for i = start_from, math.min(len, start_from + 150) do
					
					local literature_lists_item_data = literature_lists_items_data[1][i]
					
					self:AddLiteratureItem(not_found_literature_list, literature_lists_item_data.Name, literature_lists_item_data.SortOrder, literature_lists_item_data.ID, literature_lists_item_data.SharedIndex)
		
					start_from = i

				end

				if start_from == len then

					timer:Remove("EasyLiterature:LazyListsFill:NotFoundList")

				end

			end)

		end

		do
	
			local leave_count = #literature_lists_items_data[2]

			local len = #literature_lists_items_data[2]
			local start_from = 1

			timer:Create("EasyLiterature:LazyListsFill:FoundList", 0, 0, function()

				for i = start_from, math.min(len, start_from + 150) do
					
					local literature_lists_item_data = literature_lists_items_data[2][i]
					
					self:AddLiteratureItem(found_literature_list, literature_lists_item_data.Name, literature_lists_item_data.SortOrder, literature_lists_item_data.ID, literature_lists_item_data.SharedIndex)
		
					start_from = i

				end

				if start_from == len then

					timer:Remove("EasyLiterature:LazyListsFill:FoundList")

				end

			end)

		end

	else
			
		for i = 1, #literature_lists_items_data[1] do
			
			local literature_lists_item_data = literature_lists_items_data[1][i]
			
			self:AddLiteratureItem(not_found_literature_list, literature_lists_item_data.Name, literature_lists_item_data.SortOrder, literature_lists_item_data.ID, literature_lists_item_data.SharedIndex)

		end

		for i = 1, #literature_lists_items_data[2] do
			
			local literature_lists_item_data = literature_lists_items_data[2][i]
			
			self:AddLiteratureItem(found_literature_list, literature_lists_item_data.Name, literature_lists_item_data.SortOrder, literature_lists_item_data.ID, literature_lists_item_data.SharedIndex)

		end

	end

end

function EasyLiteratureMenu:HideFoundLiteraturePage()
	
	self.SelectCategory:setVisible(false)
	self.SearchBar:setVisible(false)

	self.NotFoundLiteratureList:setVisible(false)
	self.NotFoundLiteratureListHeader:setVisible(false)
	self.FoundLiteratureList:setVisible(false)
	self.FoundLiteratureListHeader:setVisible(false)

	self.MoveToFoundLiterature:setVisible(false)
	self.MoveToNotFoundLiterature:setVisible(false)

end

function EasyLiteratureMenu:ShowFoundLiteraturePage()

	self.SelectCategory:setVisible(true)
	self.SearchBar:setVisible(true)

	self.NotFoundLiteratureList:setVisible(true)
	self.NotFoundLiteratureListHeader:setVisible(true)
	self.FoundLiteratureList:setVisible(true)
	self.FoundLiteratureListHeader:setVisible(true)

	self.MoveToFoundLiterature:setVisible(true)
	self.MoveToNotFoundLiterature:setVisible(true)
	
end

function EasyLiteratureMenu:CreateSettingsCategory(name, check_boxes)

	local font = UIFont.Medium

	local panel = ISPanel:new(self.SettingsPanelsNextX, self.SettingsPanelsNextY, 0, 25)
	panel:initialise()
	panel.CheckBoxes = {}
	panel.prerender = function(pnl)

		drawRectStatic(pnl, 0, 0, pnl.width, pnl.height, .85, 0, 0, 0)
		drawRectBorderStatic(pnl, 0, 0, pnl.width, pnl.height, 1, 1, 1, 1)

		drawText(pnl, name, 6, 3, 1, 1, 1, 1, font)
		
	end
	self:addChild(panel)

	local max_width = 0

	for i = 1, #check_boxes do
		
		local check_boxes_info = check_boxes[i]

		if not check_boxes_info.ModSupport or EasyLiterature:NeedModSupport(check_boxes_info.ModSupport) then

			local check_box = ISTickBox:new(6, 25 + (i - 1) * 22, 0, self.FontSize.Small, "", self, function(_, index, selected)

				EasyLiterature.ModData.Settings[check_boxes_info.SettingsKey] = selected
		
				if check_boxes_info.CategoryName and selected ~= EasyLiterature.ModData.Settings.Categories[check_boxes_info.CategoryName] then
			
					EasyLiterature.ModData.Settings.Categories[check_boxes_info.CategoryName] = selected
		
					self.NeedRefresh = true
		
				end
			
			end)
			check_box:initialise()
			check_box:addOption(check_boxes_info.Text)
			check_box:setFont(UIFont.Medium)
			check_box:setWidthToFit()
			check_box.choicesColor = {r = 1, g = 1, b = 1, a = 1}
			check_box:setSelected(1, EasyLiterature.ModData.Settings[check_boxes_info.SettingsKey])
			panel:addChild(check_box)

			max_width = math.max(max_width, check_box:getWidth())

			table.insert(panel.CheckBoxes, check_box)

		end
	
	end

	if #panel.CheckBoxes == 0 then

		panel:setVisible(false)
		panel:removeFromUIManager()
		self:removeChild(panel)

		return

	end

	panel:setWidth(math.max(max_width, getTextWidth(UIFont.Medium, name)) + 6 + 6)
	panel:setHeight(panel.CheckBoxes[#panel.CheckBoxes]:getBottom() + 6)

	if self.SettingsPanelsNextX + panel:getWidth() <= self:getWidth() - 10 then

		panel:setX(self.SettingsPanelsNextX)
		panel:setY(self.SettingsPanelsNextY)

		self.SettingsPanelsNextX = self.SettingsPanelsNextX + panel:getWidth() + 10

		self.SettingsPanelsMaxHeightInPrevRow = math.max(self.SettingsPanelsMaxHeightInPrevRow, panel:getHeight())

	else

		self.SettingsPanelsNextY = self.SettingsPanelsNextY + self.SettingsPanelsMaxHeightInPrevRow + 10
		self.SettingsPanelsMaxHeightInPrevRow = panel:getHeight()

		panel:setX(self.SettingsPanelsBaseNextX)
		panel:setY(self.SettingsPanelsNextY)

		self.SettingsPanelsNextX = self.SettingsPanelsBaseNextX + panel:getWidth() + 10

	end

	self.SettingsPanels[panel] = true

end

function EasyLiteratureMenu:CreateFoundLiteratureSettingsPage()

	self.SettingsPanels = {}
	self.SettingsPanelsBaseNextX = 10
	self.SettingsPanelsNextX = self.SettingsPanelsBaseNextX
	self.SettingsPanelsNextY = 45
	self.SettingsPanelsMaxHeightInPrevRow = 0

	self:CreateSettingsCategory(getText("IGUI_Easy_Literature_Menu_Settings_Base"), {
		{
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Base_Auto_Mark_Transfered_Literature_As_Found"),
			SettingsKey = "AutoMarkTransferedLiterature",
		},
		{
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Base_Show_Not_Found_Mark"),
			SettingsKey = "ShowNotFoundMark",
		},
		{
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Base_Show_Found_Mark"),
			SettingsKey = "ShowFoundMark",
		},
		{
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Base_Lazy_Lists_Fill"),
			SettingsKey = "LazyListsFill",
		},
		{
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Base_Show_Known_Mark"),
			SettingsKey = "ShowKnownMark",
		},
	})

	self.SettingsPanelsNextX = self.SettingsPanelsBaseNextX
	self.SettingsPanelsNextY = self.SettingsPanelsNextY + self.SettingsPanelsMaxHeightInPrevRow + 10
	self.SettingsPanelsMaxHeightInPrevRow = 0

	self:CreateSettingsCategory(getText("IGUI_Easy_Literature_Menu_Settings_Skill_Books"), {
		{
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Found_Status"),
			SettingsKey = "FoundStatusForSkillBooks",
			CategoryName = "SkillBooks",
		},
		{
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Known_Status"),
			SettingsKey = "KnownStatusForSkillBooks",
		},
	})

	self:CreateSettingsCategory(getText("IGUI_Easy_Literature_Menu_Settings_Recipes_Magazines"), {
		{
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Found_Status"),
			SettingsKey = "FoundStatusForRecipesMagazines",
			CategoryName = "RecipesMagazines",
		},
		{
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Known_Status"),
			SettingsKey = "KnownStatusForRecipesMagazines",
		},
	})

	self:CreateSettingsCategory(getText("IGUI_Easy_Literature_Menu_Settings_VHS"), {
		{
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Found_Status"),
			SettingsKey = "FoundStatusForVHS",
			CategoryName = "VHS",
		},
		{
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Known_Status"),
			SettingsKey = "KnownStatusForVHS",
		},
	})

	self:CreateSettingsCategory(getText("IGUI_Easy_Literature_Menu_Settings_Home_VHS"), {
		{
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Found_Status"),
			SettingsKey = "FoundStatusForHomeVHS",
			CategoryName = "HomeVHS",
		},
		{
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Known_Status"),
			SettingsKey = "KnownStatusForHomeVHS",
		},
	})

	self:CreateSettingsCategory(getText("IGUI_Easy_Literature_Menu_Settings_CD"), {
		{
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Found_Status"),
			SettingsKey = "FoundStatusForCD",
			CategoryName = "CD",
		},
		{
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Known_Status"),
			SettingsKey = "KnownStatusForCD",
		},
	})

	self:CreateSettingsCategory(getText("IGUI_Easy_Literature_Menu_Settings_TrueActionsDancing_Magazines"), {
		{
			ModSupport = "TrueActionsDancing",
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Found_Status"),
			SettingsKey = "FoundStatusForTrueActionsDancingMagazines",
			CategoryName = "TrueActionsDancingMagazines",
		},
		{
			ModSupport = "TrueActionsDancing",
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Known_Status"),
			SettingsKey = "KnownStatusForTrueActionsDancingMagazines",
		},
	})

	self:CreateSettingsCategory(getText("IGUI_Easy_Literature_Menu_Settings_TrueActionsDancing_Cards"), {
		{
			ModSupport = "TrueActionsDancing",
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Found_Status"),
			SettingsKey = "FoundStatusForTrueActionsDancingCards",
			CategoryName = "TrueActionsDancingCards",
		},
	})

	self:CreateSettingsCategory(getText("IGUI_Easy_Literature_Menu_Settings_SpiffoTradingCards"), {
		{
			ModSupport = "SpiffoTradingCards",
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Found_Status"),
			SettingsKey = "FoundStatusForSpiffoTradingCards",
			CategoryName = "SpiffoTradingCards",
		},
	})

	self:CreateSettingsCategory(getText("IGUI_Easy_Literature_Menu_Settings_WulfTradingCards"), {
		{
			ModSupport = "ATCGbyWulf",
			Text = getText("IGUI_Easy_Literature_Menu_Settings_Found_Status"),
			SettingsKey = "FoundStatusForATCGbyWulfCards",
			CategoryName = "ATCGbyWulfCards",
		},
	})

	self.ClearFoundLiteratureData = ISButton:new(
		0,
		0,
		0,
		2 + self.FontSize.Medium + 2,
		getText("IGUI_Easy_Literature_Menu_Settings_Clear_Found_Literature_Data"),
		self,
		function()

			EasyLiterature.ModData.Data = {}

			self:FillLists()
		
		end
	)
	self.ClearFoundLiteratureData:initialise()
	self.ClearFoundLiteratureData:instantiate()
	self.ClearFoundLiteratureData.borderColor = {r = 1, g = 1, b = 1, a = 1}
	self.ClearFoundLiteratureData:setFont(UIFont.Medium)
	self.ClearFoundLiteratureData:setWidthToTitle()
	self.ClearFoundLiteratureData:setWidth(3 + self.ClearFoundLiteratureData:getWidth() + 3)
	self.ClearFoundLiteratureData:setX(self:getWidth() - self.ClearFoundLiteratureData:getWidth() - 10)
	self.ClearFoundLiteratureData:setY(self:getHeight() - self.ClearFoundLiteratureData:getHeight() - 10)
	self:addChild(self.ClearFoundLiteratureData)

end

function EasyLiteratureMenu:HideFoundLiteratureSettingsPage()
	
	self.ClearFoundLiteratureData:setVisible(false)

	for check_box in pairs(self.SettingsPanels) do

		check_box:setVisible(false)
		
	end
	
end

function EasyLiteratureMenu:ShowFoundLiteratureSettingsPage()

	self.ClearFoundLiteratureData:setVisible(true)

	for check_box in pairs(self.SettingsPanels) do

		check_box:setVisible(true)
		
	end
	
end
local EasyLiterature = EasyLiterature

local getSpecificPlayer = getSpecificPlayer
local getPlayerHotbar = getPlayerHotbar
local getMouseX = ISUIElement.getMouseX
local getMouseY = ISUIElement.getMouseY
local getYScroll = ISScrollingListBox.getYScroll
local getHeight = ISUIElement.getHeight
local drawRect = ISUIElement.drawRect
local drawTextureScaledAspect = ISUIElement.drawTextureScaledAspect

local getLiteratureItemInfo
local showNotFoundMark
local showFoundMark
local showKnownMark
local needModSupport

local function cacheSettingsFunctions()

	local EasyLiterature = EasyLiterature

	local _getLiteratureItemInfo = EasyLiterature.GetLiteratureItemInfo
	getLiteratureItemInfo = function(...)
		return _getLiteratureItemInfo(EasyLiterature, ...)
	end

	local getSettingsValue = EasyLiterature.GetSettingsValue

	showNotFoundMark = function()
		return getSettingsValue(EasyLiterature, "ShowNotFoundMark")
	end
	
	showFoundMark = function()
		return getSettingsValue(EasyLiterature, "ShowFoundMark")
	end

	showKnownMark = function()
		return getSettingsValue(EasyLiterature, "ShowKnownMark")
	end

	local _needModSupport = EasyLiterature.NeedModSupport
	needModSupport = function(...)
		return _needModSupport(EasyLiterature, ...)
	end

end

Events["EasyLiterature:OnReadySettingsFunctions"].Add(cacheSettingsFunctions)

local known_status_to_texture = {
	[1] = getTexture("media/ui/easy_literature/unavailable.png"),
	[2] = getTexture("media/ui/easy_literature/not_started.png"),
	[3] = getTexture("media/ui/easy_literature/completed.png"),
	[4] = getTexture("media/ui/easy_literature/skill_media.png"),
}

local function itemStackIteration(self, do_dragged, item, player, hotbar, y, mouse_x, mouse_y, y_scroll, height)

	local item = item
	local xoff = 0

	local yoff = 0

	local do_draw = true

	local is_dragging = false

	if self.dragging and self.selected[y + 1] and self.dragStarted then

		xoff = mouse_x - self.draggingX
		yoff = mouse_y - self.draggingY

		if not do_dragged then

			do_draw = false

		else

			is_dragging = true

		end

	else

		if do_dragged then

			do_draw = false

		end

	end

	if not do_draw then
		
		return

	end

	local item_y = y * self.itemHgt + y_scroll

	if not is_dragging and ((item_y + self.itemHgt < 0) or (item_y > height)) then

		return

	end

	local is_literature, found_status, known_status, is_skill_media = getLiteratureItemInfo(item, player)

	if not is_literature then

		return

	end

	if not found_status and not known_status then

		return

	end

	if needModSupport("AlternativeInventoryRendering") then

		if found_status == 1 and showFoundMark() then

			drawRect(self, xoff, (y + .1) * self.itemHgt + self.headerHgt + yoff, 4, self.itemHgt * .9, 1, .2, .8, .2)

		elseif found_status == 0 and showNotFoundMark() then

			drawRect(self, xoff, (y + .1) * self.itemHgt + self.headerHgt + yoff, 4, self.itemHgt * .9, 1, 1, .88, .2)

		end
		
		if known_status and showKnownMark() then

			local texture_size = self.itemHgt / 2.3

			drawTextureScaledAspect(self, known_status_to_texture[known_status], self.column2 - texture_size * 0.7 + xoff, y * self.itemHgt + self.headerHgt + 2 + yoff, texture_size, texture_size, 1, 1, 1, 1)
	
			if is_skill_media then
	
				drawTextureScaledAspect(self, known_status_to_texture[4], self.column2 - texture_size * 0.7 + xoff, y * self.itemHgt + self.headerHgt + 2 + yoff, texture_size, texture_size, 1, 1, 1, 1)
	
			end
	
		end

	else

		if found_status == 1 and showFoundMark() then

			drawRect(self, xoff, (y + .55) * self.itemHgt + self.headerHgt + yoff, 6, self.itemHgt * .35, 1, .2, .8, .2)

		elseif found_status == 0 and showNotFoundMark() then

			drawRect(self, xoff, (y + .55) * self.itemHgt + self.headerHgt + yoff, 6, self.itemHgt * .35, 1, 1, .88, .2)

		end

		if known_status and showKnownMark() then

			local texture_size = self.itemHgt / 2.3

			drawTextureScaledAspect(self, known_status_to_texture[known_status], self.column2 - texture_size + xoff, y * self.itemHgt + self.headerHgt + 2 + yoff, texture_size, texture_size, 1, 1, 1, 1)

			if is_skill_media then

				drawTextureScaledAspect(self, known_status_to_texture[4], self.column2 - texture_size + xoff, y * self.itemHgt + self.headerHgt + 2 + yoff, texture_size, texture_size, 1, 1, 1, 1)

			end

		end

	end

	return

end

EasyLiterature.renderdetails = function(self, do_dragged)

	EasyLiterature.ISInventoryPane_renderdetails(self, do_dragged)

	local player = getSpecificPlayer(self.player)

	local hotbar = getPlayerHotbar(self.player)

	local y = 0

	local mouse_x = getMouseX(self)
	local mouse_y = getMouseY(self)
	local y_scroll = getYScroll(self)
	local height = getHeight(self)

	local items_list = self.itemslist

	for i = 1, #items_list do

		local item_item = items_list[i]

		local item = item_item.items[1]

		itemStackIteration(self, do_dragged, item, player, hotbar, y, mouse_x, mouse_y, y_scroll, height)

		if not self.collapsed[item_item.name] then

			y = y - 1 + #item_item.items

		end

		y = y + 1

	end
	
end

local function onLoad()

	EasyLiterature.ISInventoryPane_renderdetails =
		EasyLiterature.ISInventoryPane_renderdetails or ISInventoryPane.renderdetails
	ISInventoryPane.renderdetails = EasyLiterature.renderdetails

end

Events.OnLoad.Add(onLoad)
EasyLiteratureCategorySelectComboBoxButton = ISButton:derive("EasyLiteratureCategorySelectComboBoxButton")

function EasyLiteratureCategorySelectComboBoxButton:new(x, y, w, h)

	local panel = ISButton:new(x, y, w, h, getText("IGUI_Easy_Literature_Menu_Category"))
	setmetatable(panel, self)
	self.__index = self

	panel.borderColor = {r = 1, g = 1, b = 1, a = 1}
	panel.Expanded = false

	return panel

end

function EasyLiteratureCategorySelectComboBoxButton:initialise()
	
	ISButton.initialise(self)

	self:setFont(UIFont.Medium)
	self:setWidthToTitle()
	self:setWidth(self:getWidth() + 6)

	self:CreatePopup()

end

function EasyLiteratureCategorySelectComboBoxButton:CreatePopup()

	self.PopupPanel = EasyLiteratureCategorySelectComboBoxPopup:new(self:getX(), self:getBottom(), 0, 110)
	self.PopupPanel:initialise()
	self.PopupPanel.parent = self

end

function EasyLiteratureCategorySelectComboBoxButton:ShowPopup()

	getSoundManager():playUISound("UIToggleComboBox")

	self.PopupPanel:addToUIManager()
	self.PopupPanel:setX(self:getAbsoluteX())
	self.PopupPanel:setY(self:getAbsoluteY() + self:getHeight())
	self.PopupPanel.CheckBoxPanel:RefreshStates()

end

function EasyLiteratureCategorySelectComboBoxButton:HidePopup()

	getSoundManager():playUISound("UIToggleComboBox")
		
	self.Expanded = false
	self.PopupPanel:removeFromUIManager()

end

function EasyLiteratureCategorySelectComboBoxButton:onMouseDown()

	self.sawMouseDown = true

	return true

end

function EasyLiteratureCategorySelectComboBoxButton:onMouseUp()

	if not self.sawMouseDown then return end

	self.sawMouseDown = false

	self.Expanded = not self.Expanded

	if self.Expanded then

		self:ShowPopup()

	else

		self:HidePopup()

		self.mouseOver = self:isMouseOver()

	end

end

function EasyLiteratureCategorySelectComboBoxButton:onMouseDownOutside()

	self.sawMouseDown = false

	if self.Expanded then

		self:HidePopup()

	end

end

function EasyLiteratureCategorySelectComboBoxButton:onMouseMove()

	self.mouseOver = true

end

function EasyLiteratureCategorySelectComboBoxButton:onMouseMoveOutside()

	self.mouseOver = false

end
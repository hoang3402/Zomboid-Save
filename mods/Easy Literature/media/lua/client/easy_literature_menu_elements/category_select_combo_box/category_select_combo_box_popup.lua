EasyLiteratureCategorySelectComboBoxPopup = ISPanel:derive("EasyLiteratureCategorySelectComboBoxPopup")

function EasyLiteratureCategorySelectComboBoxPopup:new(x, y, w, h)

	local panel = ISPanel:new(x, y, w, h)
	setmetatable(panel, self)
	self.__index = self

	panel.drawBorder = true
	panel.borderColor = {r = 1, g = 1, b = 1, a = 1}
	panel.backgroundColor = {r = 0, g = 0, b = 0, a = 1}

	return panel

end

function EasyLiteratureCategorySelectComboBoxPopup:initialise()
	
	ISPanel.initialise(self)

	self:setAlwaysOnTop(true)
	self:setCapture(true)

	self.CheckBoxPanel = EasyLiteratureCategorySelectComboBoxCheckBoxPanel:new(0, 5, 0, self:getHeight())
	self.CheckBoxPanel:initialise()
	self:addChild(self.CheckBoxPanel)
	self:setWidth(self.CheckBoxPanel:getWidth())
	self:setHeight(self.CheckBoxPanel:getHeight() + 10)
	
end

function EasyLiteratureCategorySelectComboBoxPopup:onMouseDown()

	if not self:isMouseOver() then

		self.parent:HidePopup()

		return

	end

	return true

end

function EasyLiteratureCategorySelectComboBoxPopup:onMouseUp()

	if not self:isMouseOver() then

		self.parent:HidePopup()

		return

	end

end
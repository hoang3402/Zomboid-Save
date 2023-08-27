EasyLiteratureCategorySelectComboBoxCheckBoxPanel = ISTickBox:derive("EasyLiteratureCategorySelectComboBoxCheckBoxPanel")

function EasyLiteratureCategorySelectComboBoxCheckBoxPanel:new(x, y, w, h)

	local panel = ISTickBox:new(x, y, w, h, "", self, self.OnChecked)
	setmetatable(panel, self)
	self.__index = self

	panel.borderColor = {r = 1, g = 1, b = 1, a = 1}
	panel.backgroundColor = {r = 0, g = 0, b = 0, a = 1}
	panel.choicesColor = {r = 1, g = 1, b = 1, a = 1}
	panel.leftMargin = 6
	panel:setFont(UIFont.Medium)

	return panel

end

function EasyLiteratureCategorySelectComboBoxCheckBoxPanel:initialise()
	
	ISTickBox.initialise(self)

	self:addOption(getText("IGUI_Easy_Literature_Menu_Category_Skill_Books"), "SkillBooks")
	self:addOption(getText("IGUI_Easy_Literature_Menu_Category_Recipes_Magazines"), "RecipesMagazines")
	self:addOption(getText("IGUI_Easy_Literature_Menu_Category_VHS"), "VHS")
	self:addOption(getText("IGUI_Easy_Literature_Menu_Category_Home_VHS"), "HomeVHS")
	self:addOption(getText("IGUI_Easy_Literature_Menu_Category_CD"), "CD")
	
	if EasyLiterature:NeedModSupport("TrueActionsDancing") then

		self:addOption(getText("IGUI_Easy_Literature_Menu_Category_TrueActionsDancing_Magazines"), "TrueActionsDancingMagazines")
		self:addOption(getText("IGUI_Easy_Literature_Menu_Category_TrueActionsDancing_Cards"), "TrueActionsDancingCards")
	end

	if EasyLiterature:NeedModSupport("SpiffoTradingCards") then

		self:addOption(getText("IGUI_Easy_Literature_Menu_Category_SpiffoTradingCards"), "SpiffoTradingCards")
	end

	if EasyLiterature:NeedModSupport("ATCGbyWulf") then

		self:addOption(getText("IGUI_Easy_Literature_Menu_Category_WulfTradingCards"), "ATCGbyWulfCards")
	
	end


	self:setWidthToFit()
	self:setWidth(self:getWidth() + 7)

end

function EasyLiteratureCategorySelectComboBoxCheckBoxPanel:SetStateByData(data, selected)
	
	for index, option_data in pairs(self.optionData) do
		
		if option_data == data then

			self.selected[index] = selected

			return

		end

	end

end

function EasyLiteratureCategorySelectComboBoxCheckBoxPanel:RefreshStates()

	self:SetStateByData("SkillBooks", EasyLiterature.ModData.Settings.Categories["SkillBooks"])
	self:SetStateByData("RecipesMagazines", EasyLiterature.ModData.Settings.Categories["RecipesMagazines"])
	self:SetStateByData("VHS", EasyLiterature.ModData.Settings.Categories["VHS"])
	self:SetStateByData("HomeVHS", EasyLiterature.ModData.Settings.Categories["HomeVHS"])
	self:SetStateByData("CD", EasyLiterature.ModData.Settings.Categories["CD"])

	if EasyLiterature:NeedModSupport("TrueActionsDancing") then

		self:SetStateByData("TrueActionsDancingMagazines", EasyLiterature.ModData.Settings.Categories["TrueActionsDancingMagazines"])
		self:SetStateByData("TrueActionsDancingCards", EasyLiterature.ModData.Settings.Categories["TrueActionsDancingCards"])

	end

	if EasyLiterature:NeedModSupport("SpiffoTradingCards") then

		self:SetStateByData("SpiffoTradingCards", EasyLiterature.ModData.Settings.Categories["SpiffoTradingCards"])

	end

	if EasyLiterature:NeedModSupport("ATCGbyWulf") then

		self:SetStateByData("ATCGbyWulfCards", EasyLiterature.ModData.Settings.Categories["ATCGbyWulfCards"])

	end
	
end

function EasyLiteratureCategorySelectComboBoxCheckBoxPanel:OnChecked(index, selected, _, _, pnl)

	EasyLiterature.ModData.Settings.Categories[pnl:getOptionData(index)] = selected

	pnl:getParent().parent:getParent():Refresh()

end
--[[

MapLegendUI
by NikGamer#1008
Version: 2.0.11

This is my first mod ever. If you are reading this - I wish you all the best.
Thanks to all who downloaded and liked the mod and the PZ Discord community for your support.

Special thanks:
- Wipe#8785 for implementing a compatibility between this mod and the "Extra Map Symbols UI" mod
- MrBounty#5616 for a bunch of useful information on building a UI and being a huge help with the code

]]--

require "ISUI/ISMouseDrag"
require "ISUI/ISPanel"
require "ISUI/ISResizeWidget"
require "ISUI/ISButton"
require "ISUI/Maps/ISWorldMap"

mapLegendWindow = ISPanel:derive("mapLegendWindow")
mapLegendButton = ISButton:derive("mapLegendButton")
local private = {}
private.createChildren = ISWorldMap.createChildren

--Adding the legend window and button to the world map
function ISWorldMap:createChildren()

    private.createChildren(self)

	self.legendButton = mapLegendButton:new(10, 10, 10, 10, "", self, self.LegendToggle)
	self.legendButton.parent = self
	self.legendButton:initialise()
	self:addChild(self.legendButton)
	
	self.mapLegend = mapLegendWindow:new(10, 10, 0, 0)
	self.mapLegend.parent = self
	self.mapLegend:initialise()
	self.legendButton:addChild(self.mapLegend)

end

function mapLegendButton:initialise()	

	ISButton.initialise(self)
	
end

function mapLegendButton:prerender()

	ISButton.prerender(self)
	--button size and coordinates
	local buttonSize = self.imageButton:getWidthOrig()
	self:setHeight(buttonSize)
	self:setWidth(buttonSize)
	self:setX(20)
	self:setY(getCore():getScreenHeight() - buttonSize - 20)
	self:drawTexture(self.imageButton, 0, 0, 1, 1, 1, 1)
	
end

function mapLegendWindow:initialise()

	ISPanel.initialise(self)
	
end

function mapLegendWindow:prerender()

	ISPanel.prerender(self)
	
	--calculating columns
	--very crude solution, but I can't be asked to figure out and implement a better way to do this (tables, you say? eww, gross!)
	local iconSize = self.colorCommunity:getWidthOrig()
	
	local tsizeCommunity = getTextManager():MeasureStringX(UIFont.Small, getText("UI_legendCommunity"))
	local tsizeRetail = getTextManager():MeasureStringX(UIFont.Small, getText("UI_legendRetail"))
	local tsizeIndustrial = getTextManager():MeasureStringX(UIFont.Small, getText("UI_legendIndustrial"))
	local tsizeResidential = getTextManager():MeasureStringX(UIFont.Small, getText("UI_legendResidential"))
	local tsizeRestaurants = getTextManager():MeasureStringX(UIFont.Small, getText("UI_legendRestaurants"))
	local tsizeHospitality = getTextManager():MeasureStringX(UIFont.Small, getText("UI_legendHospitality"))
	local tsizeMedical = getTextManager():MeasureStringX(UIFont.Small, getText("UI_legendMedical"))
	local tsizeParks = getTextManager():MeasureStringX(UIFont.Small, getText("UI_legendParks"))
	
	local maxTextWidth = math.max(tsizeCommunity, tsizeRetail, tsizeIndustrial,  tsizeResidential, tsizeRestaurants, tsizeHospitality, tsizeMedical, tsizeParks)
	
	self.iconColumn = iconSize
	self.textColumn = self.iconColumn + 25
	
	--padding for the first row
	self.iconPadding = 10
	
	--padding for text rows + adjustments for non-standard fonts and font scaling (all except x4 because I don't have a 4K monitor to test it)
	--font height adjustment for different font scaling is done very rudimentary
	--if anyone can do it better and wants to improve my mod for free just for lulz - go ahead, I'll take any help I can get
	local font = UIFont[getCore():getOptionTooltipFont()]
	local textHeight = getTextManager():MeasureStringY(font, "HEIGHT")
	local langText = Translator.getLanguage():name()
	
	if langText == "TH" then --for some reason Thai has the most arbitrary font scaling, so I have to adjust it manually
		if textHeight == 28 then -- TH 1x
		self.dynamicTextPadding = 8
		elseif textHeight == 34 then -- TH 2x
		self.dynamicTextPadding = 5
		elseif textHeight == 41 then -- TH 3x
		self.dynamicTextPadding = 1
		else -- TH Default
		self.dynamicTextPadding = 15
		end
	else
		if textHeight == 14 then -- EN Default
		self.dynamicTextPadding = 11
		elseif textHeight == 19 then -- EN 1x
		self.dynamicTextPadding = 8
		elseif textHeight == 24 then -- EN 2x
		self.dynamicTextPadding = 5
		elseif textHeight == 29 then -- EN 3x
		self.dynamicTextPadding = 2
		else -- amything else
		self.dynamicTextPadding = 8
		end
	end
		
	if langText == "CN" then --H Const 16
	self.textPadding = self.dynamicTextPadding + 1
	elseif langText == "RU" and not ActiveMods.getById("currentGame"):isModActive("RussianLanguagePack41") then --H Const 15
	self.textPadding = self.dynamicTextPadding + 2
	elseif langText == "TH" then --H D-17 1x-28 2x-34 3x-41
	self.textPadding = self.dynamicTextPadding - 5
	elseif langText == "KO" then --H Const 16
	self.textPadding = self.dynamicTextPadding + 2
	elseif langText == "CH" then --H Const 12
	self.textPadding = self.dynamicTextPadding + 4
	elseif langText == "JP" then --H Const 13
	self.textPadding = self.dynamicTextPadding + 3
	else
	self.textPadding = self.dynamicTextPadding
	end
	
	--padding for the subsequent rows
	self.itemPadding = 25
	
	--calculating and applying legend window size & position
	LegendWindowWidth = self.textColumn + maxTextWidth + (iconSize - 1)
	LegendWindowHeight = self.iconPadding + (self.itemPadding * 8) + 1
	self:setWidth(LegendWindowWidth)
	self:setHeight(LegendWindowHeight)
	
	self:setX(0)
	--compat for Shared Annotations mod
	--maybe will make it better one day
	--or just wait for the 3.0 with a movable legend window? sometime in the next decade, probably
	if ActiveMods.getById("currentGame"):isModActive("BLTAnnotations") then
	self:setY(0 - LegendWindowHeight - 20)
	else
	self:setY(20 - (getCore():getScreenHeight() - 48 - 20))
	end
	
	--Templates (for reference)
		--drawText(str, x, y, r, g, b, a, font)
		--drawTexture(texture, x, y, a, r, g, b)
	
	--creating icons
	self:drawTexture(self.colorCommunity, self.iconColumn, self.iconPadding, 1, 1, 1, 1)
	self:drawTexture(self.colorRetail, self.iconColumn, self.iconPadding + self.itemPadding, 1, 1, 1, 1)
	self:drawTexture(self.colorIndustrial, self.iconColumn, self.iconPadding + (self.itemPadding * 2), 1, 1, 1, 1)
	self:drawTexture(self.colorResidential, self.iconColumn, self.iconPadding + (self.itemPadding * 3), 1, 1, 1, 1)
	self:drawTexture(self.colorRestaurants, self.iconColumn, self.iconPadding + (self.itemPadding * 4), 1, 1, 1, 1)
	self:drawTexture(self.colorHospitality, self.iconColumn, self.iconPadding + (self.itemPadding * 5), 1, 1, 1, 1)
	self:drawTexture(self.colorMedical, self.iconColumn, self.iconPadding + (self.itemPadding * 6), 1, 1, 1, 1)
	self:drawTexture(self.colorParks, self.iconColumn, self.iconPadding + (self.itemPadding * 7), 1, 1, 1, 1)
	
	--creating text
	self:drawText(getText("UI_legendCommunity"), self.textColumn, self.textPadding, 1, 1, 1, 1, UIFont.Small)
	self:drawText(getText("UI_legendRetail"), self.textColumn, self.textPadding + self.itemPadding, 1, 1, 1, 1, UIFont.Small)
	self:drawText(getText("UI_legendIndustrial"), self.textColumn, self.textPadding + (self.itemPadding * 2), 1, 1, 1, 1, UIFont.Small)
	self:drawText(getText("UI_legendResidential"), self.textColumn, self.textPadding + (self.itemPadding * 3), 1, 1, 1, 1, UIFont.Small)
	self:drawText(getText("UI_legendRestaurants"), self.textColumn, self.textPadding + (self.itemPadding * 4), 1, 1, 1, 1, UIFont.Small)
	self:drawText(getText("UI_legendHospitality"), self.textColumn, self.textPadding + (self.itemPadding * 5), 1, 1, 1, 1, UIFont.Small)
	self:drawText(getText("UI_legendMedical"), self.textColumn, self.textPadding + (self.itemPadding * 6), 1, 1, 1, 1, UIFont.Small)
	self:drawText(getText("UI_legendParks"), self.textColumn, self.textPadding + (self.itemPadding * 7), 1, 1, 1, 1, UIFont.Small)
	
	--DEBUG FOR FONT SIZE & WHATEVER ELSE I MAY NEED
	--keep it here in case I forget how to do it and need to do it again
	--self:drawText(tostring(textHeight), self.textColumn, self.textPadding + (self.itemPadding * 8), 1, 1, 1, 1, UIFont.Small)
	
end

--closing & opening of the legend window
function ISWorldMap:LegendToggle()
	
	local isHidden = not self.mapLegend:isVisible() 
	self.mapLegend:setVisible(isHidden)

end

--legend window
function mapLegendWindow:new(x, y, width, height)

	local o = {}
	o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=0.8}
	o.colorCommunity = getTexture("media/ui/MapLegendUI/community.png")
	o.colorRetail = getTexture("media/ui/MapLegendUI/retail.png")
	o.colorIndustrial = getTexture("media/ui/MapLegendUI/industrial.png")
	o.colorResidential = getTexture("media/ui/MapLegendUI/residential.png")
	o.colorRestaurants = getTexture("media/ui/MapLegendUI/restaurants.png")
	o.colorHospitality = getTexture("media/ui/MapLegendUI/hospitality.png")
	o.colorMedical = getTexture("media/ui/MapLegendUI/medical.png")
	o.colorParks = getTexture("media/ui/MapLegendUI/parks.png")
	return o
	
end

--legend ON\OFF button
function mapLegendButton:new(x, y, width, height, title, clicktarget, onclick)

	local o = {}
	o = ISButton:new (x, y, width, height, title, clicktarget, onclick)
	setmetatable(o, self)
	self.__index = self
	o.imageButton = getTexture("media/ui/MapLegendUI/button.png")
	return o
	
end
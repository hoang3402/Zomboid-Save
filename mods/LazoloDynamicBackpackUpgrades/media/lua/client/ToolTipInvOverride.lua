require "ISUI/ISToolTipInv"
require "DynamicBackpackUpgrades"

local Old_Render = ISToolTipInv.render
local UpgradeSlotsString = "Upgrade Slots: "

--[[function InitBackpack(Item) -- this function exists in here and in TooltipOverride.lua
	local imd = Item:getModData()
	imd.LUpgrades = imd.LUpgrades or {}
	imd.LCapacity = imd.LCapacity or Item:getCapacity()
	imd.LWeightReduction = imd.LWeightReduction or Item:getWeightReduction()
	imd.LDynamicBackpacksInit = true
	imd.LMaxUpgrades = GetMaxUpgrades(Item)
end]]--

function ISToolTipInv:render() -- Stolen method from Show Weapon Stats
	local numRows = 0
	local IsValid = false
	local IsBag = false
	local IsUpgrade = false
	local Item
	local imd
	local Upgrades
	local BonusCapacity = false
	local BonusReduction = false
	if self.item ~= nil then
		IsValid = true
		Item = self.item
		imd = Item:getModData()
		if Item:IsInventoryContainer() then
			IsBag = true
			if Item and not imd.LDynamicBackpacksInit then
				InitBackpack(Item)
			end
			Upgrades = imd.LUpgrades
			for i,v in pairs(Upgrades) do
				if getUpgradeItemValue(v) >= 1 then
					BonusCapacity = true
				elseif getUpgradeItemValue(v) < 1 then
					BonusReduction = true
				end
			end
			if imd.LMaxUpgrades > 0 then numRows = numRows + 1 end
			if BonusCapacity then numRows = numRows + 1 end
			if BonusReduction then numRows = numRows + 1 end
		elseif getUpgradeItemValue(Item:getType()) then
			IsUpgrade = true
			numRows = 1
		end
	end
	
	local stage = 1
	local old_y = 0
	local fontSize = 0
	local tooltipFontSize = 0
	local lineSpacing = self.tooltip:getLineSpacing()
	local old_setHeight = self.setHeight
	self.setHeight = function(self, num, ...)
		if stage == 1 then
			stage = 2
			old_y = num
			num = num + (0.5+numRows) * lineSpacing
		else 
			stage = -1 --error
		end
		return old_setHeight(self, num, ...)
	end
	local old_drawRectBorder = self.drawRectBorder
	self.drawRectBorder = function(self, ...)
		if IsValid and numRows > 0 then
			
			local font = UIFont[getCore():getOptionTooltipFont()];
			if Item then
				if IsBag then
					local color = {0.68, 0.64, 0.96}
					local TailoringModifier = SandboxVars.DynamicBackpacks.TailoringModifier
					if TailoringModifier == 0 then TailoringModifier = 11 end -- easier to make the math function do this than to make a whole set of "if" statements.
					local MaxUpgrades = imd.LMaxUpgrades + math.floor(getPlayer():getPerkLevel(Perks.Tailoring)/TailoringModifier)
					local i = 0
					if imd.LMaxUpgrades > 0 then
						self.tooltip:DrawText(font, UpgradeSlotsString..math.max(0,(MaxUpgrades-#Upgrades)), 5, old_y + lineSpacing*i, color[1], color[2], color[3], 1);
						i = i + 1
					end
					if BonusCapacity then
						self.tooltip:DrawText(font, "+"..Item:getCapacity()-imd.LCapacity.." Base Capacity", 5, old_y + lineSpacing*i, color[1], color[2], color[3], 1);
						i = i + 1
					end
					if BonusReduction then
						self.tooltip:DrawText(font, "+"..Item:getWeightReduction()-imd.LWeightReduction.."% Weight Reduction", 5, old_y + lineSpacing*i, color[1], color[2], color[3], 1);
					end
				elseif IsUpgrade then
					local color = {0.95, 0.95, 0.2}
					local String = ""
					if getUpgradeItemValue(Item:getType()) >= 1 then
						String = getText("UI_UpgradeCapacity")
						
						if Item:getType() == "UpgradeCapacityCloth" and SandboxVars.DynamicBackpacks.ClothCapacityBonus > 0 then
							String = String..SandboxVars.DynamicBackpacks.ClothCapacityBonus.." "
						elseif Item:getType() == "UpgradeCapacityJean" and SandboxVars.DynamicBackpacks.JeanCapacityBonus > 0 then
							String = String..SandboxVars.DynamicBackpacks.JeanCapacityBonus.." "
						elseif Item:getType() == "UpgradeCapacityLeather" and SandboxVars.DynamicBackpacks.LeatherCapacityBonus > 0 then
							String = String..SandboxVars.DynamicBackpacks.LeatherCapacityBonus.." "
						elseif Item:getType() == "UpgradeCapacityMilitary" and SandboxVars.DynamicBackpacks.MilitaryCapacityBonus > 0 then
							String = String..SandboxVars.DynamicBackpacks.MilitaryCapacityBonus.." "
						end
						if getUpgradeItemValue(Item:getType()) > 1 then
							String = String.."+".. math.floor(0.5+((getUpgradeItemValue(Item:getType())-1)*100)) .."%"
						end
					else
						String = getText("UI_UpgradeWeightReduction").. math.floor(0.5+(1-getUpgradeItemValue(Item:getType()))*100) .."%"
					end
					self.tooltip:DrawText(font, String, 5, old_y, color[1], color[2], color[3], 1);
				end
			end
			stage = 3
		else
			stage = -1 --error
		end
		return old_drawRectBorder(self, ...)
	end
	Old_Render(self)
	self.setHeight = old_setHeight
	self.drawRectBorder = old_drawRectBorder
end
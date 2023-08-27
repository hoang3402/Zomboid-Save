local BannedItemTypes = {"KeyRing"} -- list of banned containers.

local SandboxInit = false
local KnivesCanRemove = SandboxVars.DynamicBackpacks.KnivesCanRemove or false
local BaseUpgrades = SandboxVars.DynamicBackpacks.BaseUpgradeSlots or 1
local BackModifier = SandboxVars.DynamicBackpacks.BackSlotModifier or 1
local FannyModifier = SandboxVars.DynamicBackpacks.FannySlotModifier or 0
local OtherModifier = SandboxVars.DynamicBackpacks.OtherSlotModifier or 0
local TailoringModifier = SandboxVars.DynamicBackpacks.TailoringModifier or 10
if TailoringModifier == 0 then TailoringModifier = 11 end -- easier to make the math function do this than to make a whole set of "if" statements.

local CapacityBonusCloth = SandboxVars.DynamicBackpacks.ClothCapacityBonus or 1
local CapacityBonusJean = SandboxVars.DynamicBackpacks.JeanCapacityBonus or 1
local CapacityBonusLeather = SandboxVars.DynamicBackpacks.LeatherCapacityBonus or 2
local CapacityBonusMilitary = SandboxVars.DynamicBackpacks.MilitaryCapacityBonus or 2


local UpgradeItemValues = {
["UpgradeCapacityCloth"] = 1 + (SandboxVars.DynamicBackpacks.ClothCapacityPercentage or 0.1),
["UpgradeWeightReductionCloth"] = 1 - (SandboxVars.DynamicBackpacks.ClothReductionPercentage or 0.15),

["UpgradeCapacityJean"] = 1 + (SandboxVars.DynamicBackpacks.JeanCapacityPercentage or 0.2),
["UpgradeWeightReductionJean"] = 1 - (SandboxVars.DynamicBackpacks.JeanReductionPercentage or 0.25),

["UpgradeCapacityLeather"] = 1 + (SandboxVars.DynamicBackpacks.LeatherCapacityPercentage or 0.25),
["UpgradeWeightReductionLeather"] = 1 - (SandboxVars.DynamicBackpacks.LeatherReductionPercentage or 0.35),

["UpgradeCapacityMilitary"] = 1 + (SandboxVars.DynamicBackpacks.MilitaryCapacityPercentage or 0.35),
["UpgradeWeightReductionMilitary"] = 1 - (SandboxVars.DynamicBackpacks.MilitaryReductionPercentage or 0.5),
}

function getUpgradeItemValue(ItemType) -- for use in other scripts.
	return UpgradeItemValues[ItemType]
end

function UpdateSandboxSettings()
	SandboxInit = true
	KnivesCanRemove = SandboxVars.DynamicBackpacks.KnivesCanRemove or false
	BaseUpgrades = SandboxVars.DynamicBackpacks.BaseUpgradeSlots or 1
	BackModifier = SandboxVars.DynamicBackpacks.BackSlotModifier or 1
	FannyModifier = SandboxVars.DynamicBackpacks.FannySlotModifier or 0
	OtherModifier = SandboxVars.DynamicBackpacks.OtherSlotModifier or 0
	TailoringModifier = SandboxVars.DynamicBackpacks.TailoringModifier or 10
	if TailoringModifier == 0 then TailoringModifier = 11 end -- easier to make the math function do this than to make a whole set of "if" statements.

	CapacityBonusCloth = SandboxVars.DynamicBackpacks.ClothCapacityBonus or 1
	CapacityBonusJean = SandboxVars.DynamicBackpacks.JeanCapacityBonus or 1
	CapacityBonusLeather = SandboxVars.DynamicBackpacks.LeatherCapacityBonus or 2
	CapacityBonusMilitary = SandboxVars.DynamicBackpacks.MilitaryCapacityBonus or 2


	UpgradeItemValues = {
	["UpgradeCapacityCloth"] = 1 + (SandboxVars.DynamicBackpacks.ClothCapacityPercentage or 0.1),
	["UpgradeWeightReductionCloth"] = 1 - (SandboxVars.DynamicBackpacks.ClothReductionPercentage or 0.15),

	["UpgradeCapacityJean"] = 1 + (SandboxVars.DynamicBackpacks.JeanCapacityPercentage or 0.2),
	["UpgradeWeightReductionJean"] = 1 - (SandboxVars.DynamicBackpacks.JeanReductionPercentage or 0.25),

	["UpgradeCapacityLeather"] = 1 + (SandboxVars.DynamicBackpacks.LeatherCapacityPercentage or 0.25),
	["UpgradeWeightReductionLeather"] = 1 - (SandboxVars.DynamicBackpacks.LeatherReductionPercentage or 0.35),

	["UpgradeCapacityMilitary"] = 1 + (SandboxVars.DynamicBackpacks.MilitaryCapacityPercentage or 0.35),
	["UpgradeWeightReductionMilitary"] = 1 - (SandboxVars.DynamicBackpacks.MilitaryReductionPercentage or 0.5),
	}
end

function ItemBanCheck(Item)
	local Type = Item:getType()
	for i,v in pairs(BannedItemTypes) do
		if Type == v then
			return true
		end
	end
	return false
end
function ItemValid(Item)
	if Item and Item:IsInventoryContainer() and not ItemBanCheck(Item) then
		return true
	else
		return false
	end
end

function TableCheck(Table,For,UseIndex)
	for i,v in pairs(Table) do
		if UseIndex then
			if i == For then return true end
		else
			if v == For then return true end
		end
		
	end
	return false
end
function TableShallowCopy(Table)
	local Copy = {}
	for i,v in pairs(Table) do
		Copy[i] = v
	end
	return Copy
end
function Round(Num,DecimalPlaces)
	return math.floor((Num*10^DecimalPlaces)+0.5)/10^DecimalPlaces
end

function GetUpgradeItems(Container,ReturnTable)
	local Inventory = Container:getInventory()
	for i = 0, Inventory:getItems():size() - 1 do
		local Item = Inventory:getItems():get(i);
		if Item and Item:getType() then
			if Item:IsInventoryContainer() and Item:isEquipped() then 
				ReturnTable = GetUpgradeItems(Item,ReturnTable)
			elseif UpgradeItemValues[Item:getType()] then 
				table.insert(ReturnTable,Item)
				--print("Item Found")
			end
		end
	end
	return ReturnTable
end

function GetTheoreticalStats(BaseCapacity,BaseWR,UpgradesTable)
	local CapacityBonus = 0
	local WeightMod = 1
	for i,v in pairs(UpgradesTable) do
		if UpgradeItemValues[v] >= 1 then
			CapacityBonus = CapacityBonus + math.floor(BaseCapacity*(UpgradeItemValues[v]-1))
			if v == "UpgradeCapacityCloth" then
				CapacityBonus = CapacityBonus + CapacityBonusCloth
			elseif v == "UpgradeCapacityJean" then
				CapacityBonus = CapacityBonus + CapacityBonusJean
			elseif v == "UpgradeCapacityLeather" then
				CapacityBonus = CapacityBonus + CapacityBonusLeather
			elseif v == "UpgradeCapacityMilitary" then
				CapacityBonus = CapacityBonus + CapacityBonusMilitary
			end
		end
		if UpgradeItemValues[v] < 1 then
			WeightMod = WeightMod*UpgradeItemValues[v]
		end
	end
	return math.floor(BaseCapacity+CapacityBonus+0.5),math.floor(100.5-(100-BaseWR)*WeightMod)
end

function GetUpgradedStats(Bag)
	local imd = Bag:getModData()
	local CapacityBonus = 0
	local WeightMod = 1
	for i,v in pairs(imd.LUpgrades) do
		if UpgradeItemValues[v] >= 1 then
			CapacityBonus = CapacityBonus + math.floor(imd.LCapacity*(UpgradeItemValues[v]-1))
			if v == "UpgradeCapacityCloth" then
				CapacityBonus = CapacityBonus + CapacityBonusCloth
			elseif v == "UpgradeCapacityJean" then
				CapacityBonus = CapacityBonus + CapacityBonusJean
			elseif v == "UpgradeCapacityLeather" then
				CapacityBonus = CapacityBonus + CapacityBonusLeather
			elseif v == "UpgradeCapacityMilitary" then
				CapacityBonus = CapacityBonus + CapacityBonusMilitary
			end
		end
		if UpgradeItemValues[v] < 1 then
			WeightMod = WeightMod*UpgradeItemValues[v]
		end
	end
	return Round(imd.LCapacity+CapacityBonus,0),Round(100-(100-imd.LWeightReduction)*WeightMod,0)
end

function GetMaxUpgrades(Item)
	if Item["canBeEquipped"](Item) == "Back" then --FannyPackBack FannyPackFront
		return BaseUpgrades + BackModifier
	elseif Item["canBeEquipped"](Item) == "FannyPackBack" or Item["canBeEquipped"](Item) == "FannyPackFront" then
		return BaseUpgrades + FannyModifier
	else
		return BaseUpgrades + OtherModifier
	end
end

function InitBackpack(Item) -- this function exists in here and in TooltipOverride.lua
	local imd = Item:getModData()
	imd.LUpgrades = imd.LUpgrades or {}
	imd.LCapacity = imd.LCapacity or Item:getCapacity()
	imd.LWeightReduction = imd.LWeightReduction or Item:getWeightReduction()
	imd.LFixState = "Show"
	imd.LDynamicBackpacksInit = true
	imd.LMaxUpgrades = GetMaxUpgrades(Item)
end

function UpdateBag(Bag)
	local imd = Bag:getModData()
	local CapacityBonus = 0
	local WeightMod = 1
	
	imd.LMaxUpgrades = GetMaxUpgrades(Bag)
	
	local UpgradedCapacity, UpgradedWeightReduction = GetUpgradedStats(Bag)
	
	Bag:setCapacity(UpgradedCapacity)
	Bag:setWeightReduction(UpgradedWeightReduction)
end

function AddUpgrade(Bag,Item,Player)
	if not Bag or not Bag:IsInventoryContainer() or not Item or not Item:getContainer() then return end
	local imd = Bag:getModData()
	if imd.LMaxUpgrades > 0 and #imd.LUpgrades >= imd.LMaxUpgrades + math.floor(Player:getPerkLevel(Perks.Tailoring)/TailoringModifier) then return end
	
	if UpgradeItemValues[Item:getType()] then
		table.insert(imd.LUpgrades,Item:getType())
		Item:getContainer():Remove(Item)
		UpdateBag(Bag)
	else
		print("Upgrade Not In List?")
	end
end

function RemoveUpgrade(Bag,ItemType,Player)
	if not Bag or not Bag:IsInventoryContainer() or not ItemType then return end
	local imd = Bag:getModData()
	
	for i,v in pairs(imd.LUpgrades) do
		if v == ItemType then
			local Inventory = Bag:getContainer()
			local Item = Inventory:AddItem("DynamicBackpacks."..ItemType)
			Inventory:addItemOnServer(Item)
			table.remove(imd.LUpgrades,i)
			UpdateBag(Bag)
			break
		end
	end
	
	if #imd.LUpgrades <= 0 then
		imd.LFixState = "Show"
	end
end
--local NewAction = ISInventoryTransferAction:new(Player, I, FromContainer, ToContainer, Time)
function HasDurability(Item)
	if not Item:getCondition() or Item:getCondition() > 0 then 
		return true 
	end
	return false
end
function CheckForAndGetUpgradeItems(Player,Fetch)
	local inv = Player:getInventory()
	local Needle = inv:getFirstTagRecurse("SewingNeedle")
	local Thread = inv:getFirstTypeEvalRecurse("Thread",function(item) return item:getRemainingUses() > 0 end)
	if not Needle or not Thread then return false end
	if Fetch and not inv:contains(Needle) then
		ISTimedActionQueue.add(ISInventoryTransferAction:new(Player, Needle, Needle:getContainer(), inv, Needle:getWeight()*60)) 
	end
	if Fetch and not inv:contains(Thread) then
		ISTimedActionQueue.add(ISInventoryTransferAction:new(Player, Thread, Thread:getContainer(), inv, Thread:getWeight()*60))
	end
	return Needle, Thread
end
function CheckForAndGetRemoveItems(Player,Fetch)
	local inv = Player:getInventory()
	local Scissors = inv:getFirstTagEvalRecurse("Scissors",HasDurability)
	--for i,v in pairs(ScissorsItemTypes) do
		--Scissors = inv:getFirstTypeRecurse(v)
	--end
	if KnivesCanRemove and not Scissors then Scissors = inv:getFirstTagEvalRecurse("SharpKnife",HasDurability) end
	
	if not Scissors then return false end
	if Fetch and not inv:contains(Scissors) then
		ISTimedActionQueue.add(ISInventoryTransferAction:new(Player, Scissors, Scissors:getContainer(), inv, Scissors:getWeight()*60))
	end
	return Scissors, Damaged
end



function RemoveValid(Bag,UpgradeItemType)
	if UpgradeItemValues[UpgradeItemType] < 1 then
		return true -- Weight Reduction upgrades dont matter.
	else
		local FakeUpgrades = TableShallowCopy(Bag:getModData().LUpgrades)
		for i,v in pairs(FakeUpgrades) do
			if v == UpgradeItemType then
				table.remove(FakeUpgrades,i)
			end
		end
		
		local imd = Bag:getModData()
		local CurrentWeight = Bag:getContentsWeight()
		local BaseCapacity = imd.LCapacity
		local BaseWR = imd.LWeightReduction
		local NewCapacity, NewReduction = GetTheoreticalStats(BaseCapacity,BaseWR,FakeUpgrades)
		
		if CurrentWeight <= NewCapacity then
			return true
		else
			return false, "Bag is too full \nRemoval results in "..Round(CurrentWeight,2).."/"..Round(NewCapacity,2).." Capacity"
		end
	end
end

function OnMenuOptionSelected(Player, OnComplete, Bag, ItemInfo, JobType)
	local ExtraItems = {}
	if instanceof(ItemInfo,"InventoryItem") then --ItemInfo is a bag when adding an upgrade, making it an Inventory Item, ItemInfo is a string of the item type when removing upgrades.
		local Needle, Thread = CheckForAndGetUpgradeItems(Player,true)
		if not Needle then return false end
		table.insert(ExtraItems,ItemInfo)
		table.insert(ExtraItems,Needle)
		table.insert(ExtraItems,Thread)
		
		if not Player:getInventory():contains(ItemInfo) then 
			ISTimedActionQueue.add(ISInventoryTransferAction:new(Player, ItemInfo, ItemInfo:getContainer(), Player:getInventory(), ItemInfo:getWeight()*60)) 
		end
	else
		local Scissors = CheckForAndGetRemoveItems(Player, true)
		if not Scissors then return end
		local IsValid = RemoveValid(Bag,ItemInfo)
		if not IsValid then return end
		table.insert(ExtraItems,Scissors)
	end
	if Bag and not Player:getInventory():contains(Bag) then --make sure we have the bag and upgrade item if we dont already.
		ISTimedActionQueue.add(ISInventoryTransferAction:new(Player, Bag, Bag:getContainer(), Player:getInventory(), Bag:getWeight()*50)) 
	end
	
	ISTimedActionQueue.add(ISDynamicBackpacksAction:new(Player, OnComplete, Bag, ItemInfo, JobType, ExtraItems))
end


function OnInventoryContextMenu(playernum, Context, Items)
	local Player = getSpecificPlayer(playernum)
	for i,v in pairs(Items) do
		local Item = v
		if not instanceof(v,"InventoryItem") then
			Item = v.items[1]
		end
		
		local tags = Item:getTags()
		for i=0, tags:size() - 1 do
			print(tags:get(i))
		end
		
		if ItemValid(Item) then -- player clicked on a bag
			local imd = Item:getModData()
			
			if not imd.LDynamicBackpacksInit then
				InitBackpack(Item)
			end
			
			if imd.LMaxUpgrades > 0 and #imd.LUpgrades < imd.LMaxUpgrades + math.floor(Player:getPerkLevel(Perks.Tailoring)/TailoringModifier) then
				local UpgradeItems = GetUpgradeItems(Player,{})
				local UpgradeMenu
				local Needle, Thread = CheckForAndGetUpgradeItems(Player, false)
				if #UpgradeItems > 0 then
					if Needle then
						for i2,v2 in pairs(UpgradeItems) do
							if not UpgradeMenu then
								UpgradeMenu = ISContextMenu:getNew(Context)
								Context:addSubMenu(Context:insertOptionBefore(getText("ContextMenu_Drop"),"Add Upgrade"),UpgradeMenu)
							end
							--addOption(name, target, onSelect, ...)
							--onSelect(target, ...)
							UpgradeMenu:addOption(v2:getDisplayName(),Player,OnMenuOptionSelected,AddUpgrade,Item,v2,"Add Upgrade")
						end
					else
						local Option = Context:insertOptionBefore(getText("ContextMenu_Drop"),"Add Upgrade")
						local Tooltip = ISInventoryPaneContextMenu.addToolTip() -- this is such a mess to add tooltips jesus.
						Option.toolTip = Tooltip
						Tooltip.description = "Requires: Needle & Thread"
						Option.notAvailable = true
					end
				end
			end
			
			--Context:insertOptionBefore(getText("ContextMenu_Drop"),"Break",Player,function() Item:setCapacity(5) end) -- used for testing the fix system.
			
			if #imd.LUpgrades >= 1 then -- add remove optoins.
				
				local Scissors = CheckForAndGetRemoveItems(Player, false)
				if Scissors then
					local RemoveMenu
					RemoveMenu = ISContextMenu:getNew(Context)
					Context:addSubMenu(Context:insertOptionBefore(getText("ContextMenu_Drop"),"Remove Upgrade"),RemoveMenu)
					
					for i2,v2 in pairs(imd.LUpgrades) do
						local IsValid, Message = RemoveValid(Item,v2)
						if IsValid then
							RemoveMenu:addOption(getText("UI_"..v2),Player,OnMenuOptionSelected,RemoveUpgrade,Item,v2,"Remove Upgrade")
						else
							local Option = RemoveMenu:addOption(getText("UI_"..v2))
							local Tooltip = ISInventoryPaneContextMenu:addToolTip()
							Option.toolTip = Tooltip
							Tooltip.description = Message
							Option.notAvailable = true
						end
					end
				else
					local Option = Context:insertOptionBefore(getText("ContextMenu_Drop"),"Remove Upgrade")
					local Tooltip = ISInventoryPaneContextMenu.addToolTip()
					Option.toolTip = Tooltip
					if not KnivesCanRemove then
						Tooltip.description = "Requires: Scissors"
					else
						Tooltip.description = "Requires: Scissors or Sharp Knife"
					end
					Option.notAvailable = true
				end
				
				
				-- check if item needs updating
				if imd.LFixState ~= "Hide" then
					local UpgradedCapacity, UpgradedWeightReduction = GetUpgradedStats(Item)
					if UpgradedCapacity and UpgradedWeightReduction and (Item:getCapacity() ~= UpgradedCapacity or Item:getWeightReduction() ~= UpgradedWeightReduction) then
						if imd.LFixState == "Auto" then
							local OnceButton = Context:insertOptionBefore(getText("ContextMenu_Drop"),"Manual Fix",Item,UpdateBag)
							local Tooltip = ISInventoryPaneContextMenu.addToolTip()
							OnceButton.toolTip = Tooltip 
							Tooltip.description = "Update this bag's stats manually. \n".."(Capacity: "..UpgradedCapacity..", Weight Reduction: "..UpgradedWeightReduction..")"
						else
							local UpdateMenu = ISContextMenu:getNew(Context)
							Context:addSubMenu(Context:insertOptionBefore(getText("ContextMenu_Drop"),"Fix Upgrades"),UpdateMenu)
							
							local OnceButton = UpdateMenu:addOption("Once",Item,UpdateBag)
							local Tooltip = ISInventoryPaneContextMenu.addToolTip()
							OnceButton.toolTip = Tooltip 
							Tooltip.description = "Set this items stats to the expected stats from Dynamic Backpack Upgrades. \n".."(Capacity: "..UpgradedCapacity..", Weight Reduction: "..UpgradedWeightReduction..")"
							
							local AlwaysButton = UpdateMenu:addOption("Always",Item,function(Item) 
								UpdateBag(Item)
								Item:getModData().LFixState = "Auto"
							end)
							local Tooltip = ISInventoryPaneContextMenu.addToolTip()
							AlwaysButton.toolTip = Tooltip 
							Tooltip.description = "Flag this item to automatically update to Dynamic Backpack Upgrade values if it changes. \n (Automatic updates only apply to items in a player inventory)"
							
							local NeverButton = UpdateMenu:addOption("Never",Item,function(Item)
								Item:getModData().LFixState = "Hide"
							end)
							local Tooltip = ISInventoryPaneContextMenu.addToolTip()
							NeverButton.toolTip = Tooltip 
							Tooltip.description = "Permanently hide this menu without doing anything, remove all upgrades to re-enable it"
						end
					end
				end
				
			end
			
			break
		elseif UpgradeItemValues[Item:getType()] then --Player clicked on an upgrade
			local UpgradeMenu
			local Inventory = Player:getInventory()
			local Needle, Thread = CheckForAndGetUpgradeItems(Player)
			if Needle then
				for i = 0, Inventory:getItems():size() - 1 do
					local BagItem = Inventory:getItems():get(i);
					if BagItem and Item:getType() then
						if ItemValid(BagItem) then 
							if not BagItem:getModData().LDynamicBackpacksInit then
								InitBackpack(BagItem)
							end
							if BagItem:getModData().LMaxUpgrades > 0 and #BagItem:getModData().LUpgrades < BagItem:getModData().LMaxUpgrades + math.floor(Player:getPerkLevel(Perks.Tailoring)/TailoringModifier) then
								if not UpgradeMenu then
									UpgradeMenu = ISContextMenu:getNew(Context)
									Context:addSubMenu(Context:insertOptionBefore(getText("ContextMenu_Drop"),"Upgrade Bag"),UpgradeMenu)
								end
								UpgradeMenu:addOption(BagItem:getDisplayName(),Player,OnMenuOptionSelected,AddUpgrade,BagItem,Item,"Add Upgrade")
							end
						end
					end
				end
			else
				local Option = Context:insertOptionBefore(getText("ContextMenu_Drop"),"Add Upgrade")
				local Tooltip = ISInventoryPaneContextMenu.addToolTip()
				Option.toolTip = Tooltip
				Tooltip.description = "Requires Needle & Thread"
				Option.notAvailable = true
			end
		end
	end
end
function InvCheck()
	local Inventory = getPlayer():getInventory()
	for i = 0, Inventory:getItems():size() - 1 do
		local Item = Inventory:getItems():get(i)
		if Item and Item:IsInventoryContainer() and Item:getModData().LFixState and Item:getModData().LFixState == "Auto" then
			local Capacity, Reduction = GetUpgradedStats(Item)
			if Capacity and Reduction and (Item:getCapacity() ~= Capacity or Item:getWeightReduction() ~= Reduction) then
				UpdateBag(Item)
				--print("Auto Updating Bag")
			end
		end
	end
end

Events.OnFillInventoryObjectContextMenu.Add(OnInventoryContextMenu)
Events.OnGameStart.Add(UpdateSandboxSettings)
Events.EveryOneMinute.Add(InvCheck)
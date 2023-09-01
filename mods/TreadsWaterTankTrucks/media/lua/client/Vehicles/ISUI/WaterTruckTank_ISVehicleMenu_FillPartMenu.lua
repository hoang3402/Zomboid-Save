---------------------Code by Tread ----- (Trealak on Steam) ---------------------------------
-- inspired by FuelAPI, Water Dispenser and Coco Liquid Overhaul by Konijima, Fuel Trailers and Trucks by Filibuster Rhymes and TMC (Tsar's Modding Company) ----------

require "Vehicles/ISUI/ISVehicleMenu"

local old_ISVehicleMenu_FillPartMenu = ISVehicleMenu.FillPartMenu

------------- copy of TIS function -------------------------------
local function formatWaterAmount(setX, amount, max)
	-- Water tiles have waterAmount=9999
	-- Piped water has waterAmount=10000
	if max >= 9999 then
		return string.format("%s: <SETX:%d> %s", getText("ContextMenu_WaterName"), setX, getText("Tooltip_WaterUnlimited"))
	end
	return string.format("%s: <SETX:%d> %d / %d", getText("ContextMenu_WaterName"), setX, amount, max)
end

------------- copy of TIS function -------------------------------
local function getMoveableDisplayName(obj)
	if not obj then return nil end
	if not obj:getSprite() then return nil end
	local props = obj:getSprite():getProperties()
	if props:Is("CustomName") then
		local name = props:Val("CustomName")
		if props:Is("GroupName") then
			name = props:Val("GroupName") .. " " .. name
		end
		return Translator.getMoveableDisplayName(name)
	end
	return nil
end

function ISVehicleMenu.FillPartMenu(playerIndex, context, slice, vehicle)

	local playerObj = getSpecificPlayer(playerIndex);
	
	if playerObj:DistToProper(vehicle) >= 8 then
        return
    end
	
--	local typeToItem = VehicleUtils.getItems(playerIndex)
	local playerInv = playerObj:getInventory()
	
----!! Finding filter part (if any) and its condition - Tread ----------------------
	local filter = nil
	local filterCondition = nil
	for i=1,vehicle:getPartCount() do
		local part = vehicle:getPartByIndex(i-1)
		
		if part:getId() == "RS_WaterFilter" and part:getInventoryItem() then -- if part matches Water Filter ID and IS installed
			filter = part
			filterCondition = part:getCondition()
			--print('Filter Condition=' .. filterCondition)
		end	
	end
-------------------- Generating context menu - Tread ------------------------------------	
	for i=1,vehicle:getPartCount() do
		local part = vehicle:getPartByIndex(i-1)
		--!! check below allows any operations on my Water Tanks - Tread, can be mimicked to create other tank functionality --------------------------------
		if part:isContainer() and (part:getContainerContentType() == "Water" or part:getContainerContentType() == "WaterTainted") then 
			local waterTankContent = part:getContainerContentAmount()
			local waterTankCapacity = part:getContainerCapacity()
			----------modData for WaterTank (to store tainted water information) - Tread ------------------
		--	local	partData = part:getModData()
			if waterTankContent == 0 then -- reset tainted flag for empty water tanks - Tread
				sendClientCommand(playerObj, 'RS_Server', 'RS_UntaintPartModDataServer', { vehicle = vehicle:getId(), part = part:getId() })
			end
			if part:getContainerContentType() == "WaterTainted" then -- always taint water in "sewage" trucks - Tread
				sendClientCommand(playerObj, 'RS_Server', 'RS_TaintPartModDataServer', { vehicle = vehicle:getId(), part = part:getId() })
			end
			local partData = part:getModData()
			
			if waterTankContent > 0 then -- menu options for when there is water in the tank - Tread
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			--Fill Containers --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				local fillableBottles = CLO_Inventory_RS.GetAllFillableWaterItemInInventory(playerInv) --- using copied Konijima's function from Coco Liquid Overhaul - Thanks once more - Tread
				if #fillableBottles > 0 then
					if slice then
						local item = fillableBottles[1]
					--	slice:addSlice((getText("ContextMenu_Fill") .. " " .. item:getName()), item:getTex(), ISVehiclePartMenu.onTakeWater, playerObj, part, item) -- For reference, grabbing items sprite - Tread
						slice:addSlice((getText("ContextMenu_Fill") .. "\n" .. item:getName()), getTexture("media/ui/vehicles/RS_Water_Fill2.png"), ISVehiclePartMenu.onTakeWater, playerObj, part, item, filter)
					else
						local subMenuFill = ISContextMenu:getNew(context);  
						local fillMenu = context:addOption(getText("ContextMenu_Fill"))
						
						--[[ ---------- Not working without extra changes in called function - commenting out since I don't need it and don't want to bother - Tread ---------------------
						if #fillableBottles > 1 then
							local optionFillAll = subMenuFill:addOption(getText("ContextMenu_FillAll"), playerObj, ISVehiclePartMenu.onTakeWater, part, fillableBottles)
						end
						]]--
						for i = 1, #fillableBottles do
							local item = fillableBottles[i]
							local option = subMenuFill:addOption(item:getName(), playerObj, ISVehiclePartMenu.onTakeWater, part, item, filter)
							
							--------------------------- tainted water tooltip ------------------------------------------
							local tooltip = ISToolTip:new();
							tooltip:setName(item:getName());
							local tx = getTextManager():MeasureStringX(tooltip.font, getText("ContextMenu_WaterName") .. ":") + 20
							
							if not item:IsDrainable() then -- workaround to get capacity of empty containers (their filled equivalents really) - Tread
								local newItemType = item:getReplaceOnUseOn()
								newItemType = string.sub(newItemType,13)
								newItemType = item:getModule() .. "." .. newItemType;
								newItemType = ScriptManager.instance:getItem(newItemType)
								tooltip.description = string.format("%s: <SETX:%d> %d / %d", getText("ContextMenu_WaterName"), tx, 0, 1.0 / newItemType:getUseDelta() + 0.0001);
								newItemType = nil
							else
							tooltip.description = string.format("%s: <SETX:%d> %d / %d", getText("ContextMenu_WaterName"), tx, item:getDrainableUsesInt(), 1.0 / item:getUseDelta() + 0.0001);	
							end
							tooltip.description = tooltip.description .. " <BR>" .. getText("IGUI_RS_Source") .. getText("IGUI_VehiclePart" .. part:getId())
							---- \n in line below (standard lua string operator) works better than <line> or <br> I found elsewher in Zomboid code (both gave some kind of issue with tooltip I wanted - Tread -----
							tooltip.description = tooltip.description .. "\n" .. string.format("%s: <SETX:%d> %d / %d", getText("ContextMenu_WaterName"), tx, waterTankContent, waterTankCapacity);
							if filter ~= nil then	-- tainted tooltip if Filter installed - Tread
								if filterCondition >=70 then
									tooltip.description = tooltip.description .. "\n" .. "<RGB:0.1,0.5,0> " .. getText("IGUI_RS_FilterGood")
								elseif filterCondition >= 30 and filterCondition < 70 then
									tooltip.description = tooltip.description .. "\n" .. "<RGB:0.9,0.8,0> " .. getText("IGUI_RS_FilterOK")
									if partData.tainted == 1 then
										tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater");
									end
								else
									tooltip.description = tooltip.description .. "\n" .. "<RGB:1,0.5,0.5> " .. getText("IGUI_RS_FilterBad")
									tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater");
								end
							end
							if partData.tainted == 1 and filter == nil then -- tainted tooltip if no filter installed - Tread
								tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater");
							end
							
							tooltip.maxLineWidth = 512;
							option.toolTip = tooltip
						
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
						end 
						context:addSubMenu(fillMenu, subMenuFill);
					end
				end
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			--Drink --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				if slice then -- needed even if empty, otherwise this menu crashes, workaround surely exists - Tread
				--	slice:addSlice(getText("ContextMenu_Drink"), getTexture("media/ui/vehicles/vehicle_refuel_from_pump.png"), ISVehiclePartMenu.doDrinkWater, playerObj, part) 
				else
					local drinkMenu = context:addOption(getText("ContextMenu_Drink"), playerObj, ISVehiclePartMenu.doDrinkWater, part, filter)
						----------tainted water tooltip
					local tooltip = ISToolTip:new();
					tooltip:setName(getText("IGUI_VehiclePart" .. part:getId()));
					local tx1 = getTextManager():MeasureStringX(tooltip.font, getText("Tooltip_food_Thirst") .. ":") + 20
					local tx2 = getTextManager():MeasureStringX(tooltip.font, getText("ContextMenu_WaterName") .. ":") + 20
					local tx = math.max(tx1, tx2)
					
					local thirst = playerObj:getStats():getThirst()
					local units = math.min(math.ceil(thirst / 0.1), 10)
					units = math.min(units, waterTankContent)
					
					tooltip.description = string.format("%s: <SETX:%d> -%d / %d", getText("Tooltip_food_Thirst"), tx, math.min(units * 10, thirst * 100), thirst * 100)
					tooltip.description = tooltip.description .. "\n" .. string.format("%s: <SETX:%d> %d / %d", getText("ContextMenu_WaterName"), tx, waterTankContent, waterTankCapacity);
					if filter ~= nil then	-- tainted tooltip if Filter installed - Tread
						if filterCondition >=70 then
							tooltip.description = tooltip.description .. "\n" .. "<RGB:0.1,0.5,0> " .. getText("IGUI_RS_FilterGood")
						elseif filterCondition >= 30 and filterCondition < 70 then
							tooltip.description = tooltip.description .. "\n" .. "<RGB:0.9,0.8,0> " .. getText("IGUI_RS_FilterOK")
							if partData.tainted == 1 then
								tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater");
							end
						else
							tooltip.description = tooltip.description .. "\n" .. "<RGB:1,0.5,0.5> " .. getText("IGUI_RS_FilterBad")
							tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater");
						end
					end
					if partData.tainted == 1 and filter == nil then -- tainted tooltip if no filter installed - Tread
						tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater");
					end
					tooltip.maxLineWidth = 512;
					drinkMenu.toolTip = tooltip;
					
				end

			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			--Pump into water object ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
				
				-- IGUI_RS_PumpWaterTo
				local waterStations = ISVehiclePartMenu.getNotFullNearbyWaterBarrels(part)
				if #waterStations > 0 then
					if slice then
						local pump = waterStations[1]
						local pumpName = getMoveableDisplayName(pump)
						if pumpName == nil and instanceof(pump, "IsoWorldInventoryObject") and pump:getItem() then
							pumpName = pump:getItem():getDisplayName()
						end
						slice:addSlice(getText("IGUI_RS_PumpWaterTo") .. "\n" .. pumpName, getTexture("media/ui/vehicles/RS_Water_PumpTo1.png"), ISVehiclePartMenu.pumpWaterTo, playerObj, part, pump, filter)
					else
						local subMenuPumpWater = ISContextMenu:getNew(context);  
						local pumpWaterMenu = context:addOption(getText("IGUI_RS_PumpWaterTo"))
						
						for i = 1, #waterStations do
							local pump = waterStations[i]
							--local pumpName = pump:getName()
							local pumpName = getMoveableDisplayName(pump)
							if pumpName == nil and instanceof(pump, "IsoWorldInventoryObject") and pump:getItem() then
								pumpName = pump:getItem():getDisplayName()
							end
							
							local option = subMenuPumpWater:addOption(pumpName, playerObj, ISVehiclePartMenu.pumpWaterTo, part, pump, filter)

							local tooltip = ISToolTip:new();
							tooltip:setName(pumpName);
							local tx = getTextManager():MeasureStringX(tooltip.font, getText("ContextMenu_WaterName") .. ":") + 20
							tooltip.description = formatWaterAmount(tx, pump:getWaterAmount(), pump:getWaterMax())	
							tooltip.description = tooltip.description .. " <BR>" .. (getText("IGUI_RS_Source") .. getText("IGUI_VehiclePart" .. part:getId()))
							tooltip.description = tooltip.description .. "\n" .. string.format("%s: <SETX:%d> %d / %d", getText("ContextMenu_WaterName"), tx, waterTankContent, waterTankCapacity)
							if filter ~= nil then	-- tainted tooltip if Filter installed - Tread
								if filterCondition >=70 then
									tooltip.description = tooltip.description .. "\n" .. "<RGB:0.1,0.5,0> " .. getText("IGUI_RS_FilterGood")
								elseif filterCondition >= 30 and filterCondition < 70 then
									tooltip.description = tooltip.description .. "\n" .. "<RGB:0.9,0.8,0> " .. getText("IGUI_RS_FilterOK")
									if partData.tainted == 1 then
										tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater");
									end
								else
									tooltip.description = tooltip.description .. "\n" .. "<RGB:1,0.5,0.5> " .. getText("IGUI_RS_FilterBad")
									tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater");
								end
							end
							if partData.tainted == 1 and filter == nil then -- tainted tooltip if no filter installed - Tread
								tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater");
							end
							tooltip.maxLineWidth = 512;
							option.toolTip = tooltip
						end
						context:addSubMenu(pumpWaterMenu, subMenuPumpWater);
					end
				end
				
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			--Empty the Water tank---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				if slice then
					slice:addSlice(getText("IGUI_RS_EmptyWaterTank"), getTexture("media/ui/vehicles/RS_Water_Empty2.png"), ISVehiclePartMenu.emptyWaterTank, playerObj, part) 
				else
					local emptyTank = context:addOption(getText("IGUI_RS_EmptyWaterTank"), playerObj, ISVehiclePartMenu.emptyWaterTank, part)
					
					local tooltip = ISToolTip:new();
					tooltip:setName(getText("IGUI_VehiclePart" .. part:getId()));
					local tx = getTextManager():MeasureStringX(tooltip.font, getText("ContextMenu_WaterName") .. ":") + 20
					tooltip.description = string.format("%s: <SETX:%d> %d / %d", getText("ContextMenu_WaterName"), tx, waterTankContent, waterTankCapacity);
					if partData.tainted == 1 then
						tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater");
					end
					tooltip.maxLineWidth = 512;
					emptyTank.toolTip = tooltip;
				end
			end
			
			if waterTankContent < waterTankCapacity then -- menu options for when the tank is not full - Tread
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			--Add Water to tank----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			 
			
				local waterSources = {}			
				--- code based on TIS, ISInventoryPaneContextMenu, pourInto -----------------------		
				for i = 0, playerObj:getInventory():getItems():size() -1 do
					local item = playerObj:getInventory():getItems():get(i);
					if item:isWaterSource() and instanceof(item, "DrainableComboItem") then
						table.insert(waterSources, item)
					end
				end
				-------------------------------------------------------------------------------
				
				if #waterSources > 0 then
					if slice then
						local item = waterSources[1]
					--	slice:addSlice((getText("IGUI_RS_AddWaterFrom") .. " " .. item:getName()), item:getTex(), ISVehiclePartMenu.addWaterToTank, playerObj, part, item)
						slice:addSlice((getText("IGUI_RS_AddWaterFrom") .. "\n" .. item:getName()), getTexture("media/ui/vehicles/RS_Water_Add2.png"), ISVehiclePartMenu.addWaterToTank, playerObj, part, item)
					else
						local subMenuAddWater = ISContextMenu:getNew(context);  
						local addWaterMenu = context:addOption(getText("ContextMenu_AddWaterFromItem"))
						
						for i = 1, #waterSources do
							local item = waterSources[i]
							local option = subMenuAddWater:addOption(item:getName(), playerObj, ISVehiclePartMenu.addWaterToTank, part, item)
						
							local tooltip = ISToolTip:new();
							tooltip:setName(getText("IGUI_VehiclePart" .. part:getId()));
							local tx = getTextManager():MeasureStringX(tooltip.font, getText("ContextMenu_WaterName") .. ":") + 20
							tooltip.description = string.format("%s: <SETX:%d> %d / %d", getText("ContextMenu_WaterName"), tx, waterTankContent, waterTankCapacity)	
							tooltip.description = tooltip.description .. " <BR>" .. getText("IGUI_RS_Source") .. item:getName()
							tooltip.description = tooltip.description .. "\n" .. string.format("%s: <SETX:%d> %d / %d", getText("ContextMenu_WaterName"), tx, item:getDrainableUsesInt(), 1.0 / item:getUseDelta() + 0.0001);
							if item:isTaintedWater() then
								tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater")
							end
							tooltip.maxLineWidth = 512;
							option.toolTip = tooltip
						
						end
						context:addSubMenu(addWaterMenu, subMenuAddWater);
					end
				end
			---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			--Tank Water from river/lake (with source choice)------------------------------------------------------------------------------------------------------------------------------------------------		
				local waterStations = ISVehiclePartMenu.getAllNearbyWaterTiles(part)
				if #waterStations > 0 then
					if slice then
						local pump = waterStations[1]
						local pumpName = getMoveableDisplayName(pump)
						if pumpName == nil and instanceof(pump, "IsoWorldInventoryObject") and pump:getItem() then
							pumpName = pump:getItem():getDisplayName()
						end
						if pumpName == nil then
							pumpName = getText("ContextMenu_NaturalWaterSource")
						end
						slice:addSlice(getText("IGUI_RS_TankWaterFromSource") .. "\n" .. pumpName, getTexture("media/ui/vehicles/RS_Water_PumpFrom1.png"), ISVehiclePartMenu.onPumpWater, playerObj, part, pump)
					else
						local subMenuPumpWater = ISContextMenu:getNew(context);  
						local pumpWaterMenu = context:addOption(getText("IGUI_RS_TankWaterFromSource"))
						
						for i = 1, #waterStations do
							local pump = waterStations[i]
							local pumpName = getMoveableDisplayName(pump)
							if pumpName == nil and instanceof(pump, "IsoWorldInventoryObject") and pump:getItem() then
								pumpName = pump:getItem():getDisplayName()
							end
							if pumpName == nil then
								pumpName = getText("ContextMenu_NaturalWaterSource")
							end
							
							local option = subMenuPumpWater:addOption(pumpName, playerObj, ISVehiclePartMenu.onPumpWater, part, pump)
							
							local tooltip = ISToolTip:new();
							tooltip:setName(getText("IGUI_VehiclePart" .. part:getId()));
							local tx = getTextManager():MeasureStringX(tooltip.font, getText("ContextMenu_WaterName") .. ":") + 20
							tooltip.description = string.format("%s: <SETX:%d> %d / %d", getText("ContextMenu_WaterName"), tx, waterTankContent, waterTankCapacity)	
							tooltip.description = tooltip.description .. " <BR>" .. getText("IGUI_RS_Source") .. pumpName
							tooltip.description = tooltip.description .. "\n" .. formatWaterAmount(tx, pump:getWaterAmount(), pump:getWaterMax())
							if pump:isTaintedWater() then
								tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater")
							end
							tooltip.maxLineWidth = 512;
							option.toolTip = tooltip
							
						end
						context:addSubMenu(pumpWaterMenu, subMenuPumpWater);
					end
				end
				
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			--Tank Water from other Truck------------------------------------------------------------------------------------------------------------------------------------------------------------------	
				local water_truck_sources = ISVehiclePartMenu.FindVehicleWaterRS(playerObj, vehicle)
				if water_truck_sources and #water_truck_sources > 0 then
					local pump
					if slice then
						pump = water_truck_sources[1]
						local pumpVeh = pump:getVehicle()
						local pumpName = pumpVeh:getScript():getName()
						local sourceFilter = pumpVeh:getPartById("RS_WaterFilter")
						if not sourceFilter or not sourceFilter:getInventoryItem() then sourceFilter = nil end --- if no part installed then treat veh like one without filter
						
						slice:addSlice(getText("IGUI_RS_TankWaterFromSource") .." ".. getText("IGUI_VehicleName" .. pumpName), getTexture("media/ui/vehicles/RS_PumpWaterFromVehicle.png"), ISVehiclePartMenu.onPumpWaterFromTruckRS, playerObj, part, pump, sourceFilter)
					else
						local subMenuPumpWater = ISContextMenu:getNew(context);  
						local pumpWaterMenu = context:addOption(getText("IGUI_RS_TankWaterFromVehicle"))
						for i = 1, #water_truck_sources do
							pump = water_truck_sources[i]
							local pumpVeh = pump:getVehicle()
							local pumpName = getText("IGUI_VehicleName" .. pumpVeh:getScript():getName())
							local sourceFilter = pumpVeh:getPartById("RS_WaterFilter")
							if not sourceFilter or not sourceFilter:getInventoryItem() then sourceFilter = nil end --- if no part installed then treat veh like one without filter
							local tankData = pump:getModData()
							
							local option = subMenuPumpWater:addOption(pumpName, playerObj, ISVehiclePartMenu.onPumpWaterFromTruckRS, part, pump, sourceFilter)
							
							local tooltip = ISToolTip:new();
							tooltip:setName(getText("IGUI_VehiclePart" .. part:getId()));
							local tx = getTextManager():MeasureStringX(tooltip.font, getText("ContextMenu_WaterName") .. ":") + 20
							tooltip.description = string.format("%s: <SETX:%d> %d / %d", getText("ContextMenu_WaterName"), tx, waterTankContent, waterTankCapacity)	
							tooltip.description = tooltip.description .. " <BR>" .. getText("IGUI_RS_Source") .. pumpName
							tooltip.description = tooltip.description .. "\n" .. string.format("%s: <SETX:%d> %d / %d", getText("ContextMenu_WaterName"), tx, pump:getContainerContentAmount(), pump:getContainerCapacity())
							if sourceFilter ~= nil and sourceFilter:getInventoryItem() then	-- tainted tooltip if Filter installed - Tread
								local sourceFilterCondition = sourceFilter:getCondition()
								if sourceFilterCondition >=70 then
									tooltip.description = tooltip.description .. "\n" .. "<RGB:0.1,0.5,0> " .. getText("IGUI_RS_FilterGood")
								elseif sourceFilterCondition >= 30 and sourceFilterCondition < 70 then
									tooltip.description = tooltip.description .. "\n" .. "<RGB:0.9,0.8,0> " .. getText("IGUI_RS_FilterOK")
									if tankData.tainted == 1 then
										tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater");
									end
								else
									tooltip.description = tooltip.description .. "\n" .. "<RGB:1,0.5,0.5> " .. getText("IGUI_RS_FilterBad")
									tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater");
								end
							end
							if tankData.tainted == 1 and sourceFilter == nil then -- tainted tooltip if no filter installed - Tread
								tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater");
							end
							tooltip.maxLineWidth = 512;
							option.toolTip = tooltip

						end
						context:addSubMenu(pumpWaterMenu, subMenuPumpWater);
					end
				end
				
			end
		end
	end
	old_ISVehicleMenu_FillPartMenu(playerIndex, context, slice, vehicle)
end
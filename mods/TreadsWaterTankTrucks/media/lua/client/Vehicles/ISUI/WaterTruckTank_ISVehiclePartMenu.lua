---------------------Code by Tread ----- (Trealak on Steam) ---------------------------------
-- inspired by FuelAPI, Water Dispenser and Coco Liquid Overhaul by Konijima, Fuel Trailers and Trucks by Filibuster Rhymes and TMC (Tsar's Modding Company) ----------

require "Vehicle/ISUI/ISVehiclePartMenu"
require "Vehicles/TimedActions/RS_TakeWaterFromTank"

function ISVehiclePartMenu.onTakeWater(playerObj, part, item, filter)
	if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end
	------------- go to "water inlet" of a car, say it cannot be reached if blocked - Tread ----
	action = ISPathFindAction:pathToVehicleArea(playerObj, part:getVehicle(), part:getArea())
	action:setOnFail(ISVehiclePartMenu.onPumpWaterPathFail, playerObj)
	ISTimedActionQueue.add(action)
	--------------------------------------------------------------------------------------------
	
	ISInventoryPaneContextMenu.equipWeapon(item, false, false, playerObj:getPlayerNum()) -- equip filled item - Tread
	
	ISTimedActionQueue.add(ISTakeWaterActionFromTank:new(playerObj, part, item, 1, filter))

	return
end

function ISVehiclePartMenu.doDrinkWater(playerObj, part, filter)
    if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end
	
	action = ISPathFindAction:pathToVehicleArea(playerObj, part:getVehicle(), part:getArea())
	action:setOnFail(ISVehiclePartMenu.onPumpWaterPathFail, playerObj)
	ISTimedActionQueue.add(action)

	ISTimedActionQueue.add(ISDrinkWaterActionFromTank:new(playerObj, part, 120, filter))

end

function ISVehiclePartMenu.addWaterToTank(playerObj, part, item)
    if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end

	action = ISPathFindAction:pathToVehicleArea(playerObj, part:getVehicle(), part:getArea())
	action:setOnFail(ISVehiclePartMenu.onPumpWaterPathFail, playerObj)
	ISTimedActionQueue.add(action)
	
	
	ISInventoryPaneContextMenu.equipWeapon(item, false, false, playerObj:getPlayerNum())

	ISTimedActionQueue.add(ISAddWaterToTank:new(playerObj, part, item, 1))
	
	return
end


function ISVehiclePartMenu.emptyWaterTank(playerObj, part)
    if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end
	
	action = ISPathFindAction:pathToVehicleArea(playerObj, part:getVehicle(), part:getArea())
	action:setOnFail(ISVehiclePartMenu.onPumpWaterPathFail, playerObj)
	ISTimedActionQueue.add(action)

	ISTimedActionQueue.add(ISEmptyWaterTank:new(playerObj, part, 120))

end



--------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Code for tanking water from rivers/lakes etc. -------------------------------------------

--[[ -- not used ATM, needs adjustments (like functions below) to make work properly (filter out puddles, allow wells, check for walls etc.) - Tread
function ISVehiclePartMenu.getNearbyWaterTile(part) --- one, first found - copied or based off TIS function - Tread
	local vehicle = part:getVehicle()
	local areaCenter = vehicle:getAreaCenter(part:getArea())
	if not areaCenter then return nil end
	local square = getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
	if not square then return nil end
	for dy=-2,2 do
		for dx=-2,2 do
			-- TODO: check line-of-sight between 2 squares
			local square2 = getCell():getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
			
		
			for i=0, square2:getObjects():size()-1 do
				local obj = square2:getObjects():get(i);
				local hasWaterFlag = (obj:getProperties() ~= nil) and obj:getProperties():Is(IsoFlagType.water)
				if (instanceof(obj, "IsoThumpable") and obj:hasWater()) or hasWaterFlag then
					return obj

				end
			end
		end
	end
end
]]--

--------------------------------------Tread: AUX functions from and inspired by AdjacentFreeTileFinder functions by TIS ---------------------------------------------------------------------------------
ISVehiclePartMenu.RS_checkPathForWalls = function(src, test, vehicle) --  - Tread
    if src == nil or test == nil then return false; end
	
	local aX = src:getX()
	local aY = src:getY()
	local bX = test:getX()
	local bY = test:getY()
	local z = test:getZ()
	
	local diffX = math.abs(bX - aX)
	local diffY = math.abs(bY - aY)
	local stepX = ((bX-aX) / diffX) 
	local stepY = ((bY-aY) / diffY) 
	
	if stepX ~= stepX then stepX = 0 end -- check if stepX is NaN (from possible 0/0 above), change into 0 in such case - Tread
	if stepY ~= stepY then stepY = 0 end -- check if stepY is NaN (from possible 0/0 above), change into 0 in such case - Tread
	
	---------------code for checking vehicle tile -> water inlet tile blockades (parking against the wall and having "water inlet" on its other side ----------------
	local vehicleTile = vehicle:getSquare()
	local vX = vehicleTile:getX()
	local vY = vehicleTile:getY()
	local VdiffX = math.abs(vX - aX)
	local VdiffY = math.abs(vY - aY)
	local VstepX = ((vX-aX) / VdiffX) 
	local VstepY = ((vY-aY) / VdiffY) 
	if VstepX ~= VstepX then VstepX = 0 end -- check if stepX is NaN (from possible 0/0 above), change into 0 in such case - Tread
	if VstepY ~= VstepY then VstepY = 0 end -- check if stepY is NaN (from possible 0/0 above), change into 0 in such case - Tread
	------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--print('DiffNR= ' .. diffX + diffY .. " aX, aY= " .. aX .. ", " .. aY .. " aX+1, aY+1= " .. aX + stepX .. ", " .. aY + stepY .. " bX, bY= " .. bX .. ", " .. bY)
	
	local t1 = getCell():getGridSquare(aX + VstepX, aY + VstepY, z) -- 1 tile towards vehicle (from water inlet) - Tread
	
	if src == test then -- If inlet over the world object then check whether car is not on the other side of some obstacle (than the inlet tile) - Tread
		--print('OneTile  ' .. 'DiffNR= ' .. diffX + diffY .. " aX, aY= " .. aX .. ", " .. aY .. " aX+1, aY+1= " .. aX + VstepX .. ", " .. aY + VstepY .. " test= " .. test:getX() .. ", " .. test:getY())
		if ISVehiclePartMenu.RS_privTrySquareForWalls(t1, src) then return true; else return false; end
	elseif diffX + diffY < 2 then -- if water object is just by the water inlet
		if ISVehiclePartMenu.RS_privTrySquare(test, src) and ISVehiclePartMenu.RS_privTrySquareForWalls(t1, src) then return true; end
	elseif diffX + diffY == 2 and diffX == diffY then -- same as above but diagonally
		if ISVehiclePartMenu.RS_privTrySquare(test, src) and ISVehiclePartMenu.RS_privTrySquareForWalls(t1, src) then return true; end
	elseif diffX + diffY >= 2 then -- if object is further, I never have more then 2, 2 vector from water inlet (limit in "getAllNearbyWaterTiles" function). Needs rewrite for bigger check zones - Tread
		local t2 = getCell():getGridSquare(aX + stepX, aY + stepY, z) -- "transit tile" 
		if not ISVehiclePartMenu.RS_privTrySquareForWalls(src, t1) then return false; end -- inlet -> car check (otherwise parking against wall allowed pumping)
		if not ISVehiclePartMenu.RS_privTrySquareForWalls(src, t2) then return false; end -- inlet -> "transit tile" check
		if not ISVehiclePartMenu.RS_privTrySquareForWalls(t2, test) then return false; end -- "transit tile" -> water object check
		return true;
	end
	return false;
end	


ISVehiclePartMenu.RS_privTrySquareForWalls = function(src, test) -- redone TIS native function (so it allows open/smashed widows): AdjacentFreeTileFinder.privTrySquareForWalls    
   if src:getX() < test:getX() and src:getY() == test:getY() then
        if test:Is(IsoFlagType.HoppableW) then return true; end								-- added "hoppable" check (low fences) - Tread
		if test:Is("DoorWallW") and not test:isDoorBlockedTo(src) then return true; end
		if test:Is("DoorW") and not test:isDoorBlockedTo(src) then return true; end			-- added other door check (fence gates etc.) - Tread
		if test:Is("WindowW") and not test:isWindowBlockedTo(src) then return true; end 	-- added window check - Tread
		if test:Is(IsoFlagType.windowW) and not test:isWindowBlockedTo(src) then return true; end -- "wall" (window and wall in one object) Window check - Tread
        if test:Is(IsoFlagType.cutW) or test:Is(IsoFlagType.collideW) then return false; end
    end
    if src:getX() > test:getX() and src:getY() == test:getY()  then
        if src:Is(IsoFlagType.HoppableW) then return true; end								-- added "hoppable" check (low fences) - Tread
		if src:Is("DoorWallW") and not src:isDoorBlockedTo(test) then return true; end
		if src:Is("DoorW") and not src:isDoorBlockedTo(test) then return true; end			-- added other door check (fence gates etc.) - Tread
		if src:Is("WindowW") and not src:isWindowBlockedTo(test) then return true; end 		-- added window check - Tread
		if src:Is(IsoFlagType.windowW) and not src:isWindowBlockedTo(test) then return true; end -- "wall" (window and wall in one object) Window check - Tread
        if src:Is(IsoFlagType.cutW)  or src:Is(IsoFlagType.collideW) then return false; end
    end

    if src:getY() < test:getY() and src:getX() == test:getX()  then
        if test:Is(IsoFlagType.HoppableN) then return true; end								-- added "hoppable" check (low fences) - Tread
		if test:Is("DoorWallN") and not test:isDoorBlockedTo(src) then return true; end
		if test:Is("DoorN") and not test:isDoorBlockedTo(src) then return true; end			-- added other door check (fence gates etc.) - Tread
		if test:Is("WindowN") and not test:isWindowBlockedTo(src) then return true; end 	-- added window check - Tread
		if test:Is(IsoFlagType.WindowN) and not test:isWindowBlockedTo(src) then return true; end -- "wall" (window and wall in one object) Window check - Tread
        if test:Is(IsoFlagType.cutN)  or test:Is(IsoFlagType.collideN)  then return false; end
    end
    if src:getY() > test:getY() and src:getX() == test:getX()  then
		if src:Is(IsoFlagType.HoppableN) then return true; end								-- added "hoppable" check (low fences) - Tread 
		if src:Is("DoorWallN") and not src:isDoorBlockedTo(test) then return true; end
		if src:Is("DoorN") and not src:isDoorBlockedTo(test) then return true; end			-- added other door check (fence gates etc.) - Tread
		if src:Is("WindowN") and not src:isWindowBlockedTo(test) then return true; end 		-- added window check - Tread
		if src:Is(IsoFlagType.WindowN) and not src:isWindowBlockedTo(test) then return true; end -- "wall" (window and wall in one object) Window check - Tread
        if src:Is(IsoFlagType.cutN)  or src:Is(IsoFlagType.collideN) then return false; end
    end

    if src:getX() ~= test:getX() and src:getY() ~= test:getY() then
        if not ISVehiclePartMenu.RS_privTrySquareForWalls2(src, test:getX(), src:getY(), src:getZ()) or -- in TIS code one ) was missing here - Tread
            not ISVehiclePartMenu.RS_privTrySquareForWalls2(src, src:getX(), test:getY(), src:getZ()) or
            not ISVehiclePartMenu.RS_privTrySquareForWalls2(test, test:getX(), src:getY(), src:getZ()) or
            not ISVehiclePartMenu.RS_privTrySquareForWalls2(test, src:getX(), test:getY(), src:getZ()) then -- in TIS code one extra ) was here - Tread
            return false;
        end
    end

    return true;
end

ISVehiclePartMenu.RS_privTrySquareForWalls2 = function(src, x, y, z) -- redone native function (so it allows open/smashed widows): AdjacentFreeTileFinder.privTrySquareForWalls2
    return ISVehiclePartMenu.RS_privTrySquareForWalls(src, getCell():getGridSquare(x, y, z))
end

ISVehiclePartMenu.RS_privTrySquare = function(src, test) -- redone native function (so it allows open/smashed widows): AdjacentFreeTileFinder.privTrySquare
     -- if either is null, its not adjacent.
     if(src == nil or test == nil) then return false; end
     -- if either are on a different floor, not adjacent.
     if src:getZ() ~= test:getZ() then return false; end
     -- if there is a wall between the two tiles, not adjacent.
     if not ISVehiclePartMenu.RS_privTrySquareForWalls(src, test) then
         return false;
    end
     -- if the test one is solid / not walkable, not adjacent.
    -- if there is no floor on test, not adjacent.
    if not AdjacentFreeTileFinder.privCanStand(test) then
       return false;
    end
     -- adjacent!
    return true;
end
-------------------------------------- End AUX functions from AdjacentFreeTileFinder ---------------------------------------------------------

function ISVehiclePartMenu.getAllNearbyWaterTiles(part) --- adjusted TIS function to get a table of all valid water sources - Tread
	local vehicle = part:getVehicle()
	local areaCenter = vehicle:getAreaCenter(part:getArea())
	if not areaCenter then return nil end
	
	local square = getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
	if not square then return nil end
	
	local result = {}
	local openWaterInTable = false -- flag if any "water tile" was already added to table - Tread
	
	for dy=-2,2 do
		for dx=-2,2 do
			
			local square2 = getCell():getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
			
			for i=0, square2:getObjects():size()-1 do
				local obj = square2:getObjects():get(i);
				local hasWaterFlag = (obj:getProperties() ~= nil) and obj:getProperties():Is(IsoFlagType.water) -- is water tile? - Tread
				local isSolidTrans = obj:getProperties():Is(IsoFlagType.solidtrans) -- solid transparent - I use the check to filter out puddles - Tread
				local isSolidFloor = (obj:getSprite():getProperties():Is(IsoFlagType.solidfloor)) or obj:getSprite():getProperties():Is(IsoFlagType.attachedFloor) -- "floor object" - used to filter out water tiles and puddles
				if obj:hasWater() or hasWaterFlag then
					if not instanceof(obj, "IsoClothingDryer") and not instanceof(obj, "IsoClothingWasher") then
						if  hasWaterFlag and isSolidTrans and not openWaterInTable then
							if ISVehiclePartMenu.RS_checkPathForWalls(square, square2, vehicle) then -- check if line between pump and water object is not blocked by wall - Tread
								table.insert(result, obj) -- add only one "water tile" to results - Tread
								openWaterInTable = true
							end
						elseif not hasWaterFlag and not isSolidFloor then	-- add all no "water tile" sources to results - Tread
							if ISVehiclePartMenu.RS_checkPathForWalls(square, square2, vehicle) then -- check if line between pump and water object is not blocked by wall - Tread
								table.insert(result, obj)
							end
						end	
					end	
				end
			end
		end
	end
	return result
end

function ISVehiclePartMenu.getNotFullNearbyWaterBarrels(part) -- mimicking functions above in order to detect not full barrels - Tread
	local vehicle = part:getVehicle()
	local areaCenter = vehicle:getAreaCenter(part:getArea())
	if not areaCenter then return nil end
	
	local square = getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
	if not square then return nil end
	
	local result = {}
	
	for dy=-2,2 do
		for dx=-2,2 do
			-- TODO: check line-of-sight between 2 squares
			local square2 = getCell():getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
			
			for i=0, square2:getObjects():size()-1 do
				local obj = square2:getObjects():get(i);
				local waterMax = obj:getWaterMax()

				if waterMax < 9999 then --Water tiles, wells, piped installations etc. have  water max >=9999 - Tread
					if not instanceof(obj, "IsoClothingDryer") and not instanceof(obj, "IsoClothingWasher") then -- ignore water tiles and some devices
						if obj:getProperties() ~= nil and obj:getProperties():Val("GroupName") == "Water" and obj:getProperties():Val("CustomName") == "Dispenser" then -- check for water dispenser (in order to ignore it) - Tread
						elseif obj:getWaterAmount() < waterMax then -- check if barrel is not full - Tread
							if ISVehiclePartMenu.RS_checkPathForWalls(square, square2, vehicle) then -- check if line between pump and water object is not blocked by wall - Tread
								table.insert(result, obj)
							end
						end	
					end	
				end
			end
		end
	end
	return result
end

	----------------- Code for tanking from water sources - Tread -----------------------
function ISVehiclePartMenu.onPumpWater(playerObj, part, pump)
	if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end
  --[[------------------ not needed anymore - search for water source moved to vehicle menu functions - Tread -----------------------
	local waterStation = ISVehiclePartMenu.getNearbyWaterTile(part)
	if waterStation then
	]]--
		local square = pump:getSquare();
		if square then
			local action = ISPathFindAction:pathToVehicleArea(playerObj, part:getVehicle(), part:getArea())
			action:setOnFail(ISVehiclePartMenu.onPumpWaterPathFail, playerObj)
			ISTimedActionQueue.add(action)

			ISTimedActionQueue.add(ISPumpWaterFromSource:new(playerObj, part, pump, 1))
		end
	--end
end
	
	----------------- Code for filling barrels etc. from Vehicle Water Tank - Tread -----------------------
function ISVehiclePartMenu.pumpWaterTo(playerObj, part, pump, filter)
    if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end
	
	action = ISPathFindAction:pathToVehicleArea(playerObj, part:getVehicle(), part:getArea())
	action:setOnFail(ISVehiclePartMenu.onPumpWaterPathFail, playerObj)
	ISTimedActionQueue.add(action)

	ISTimedActionQueue.add(ISPumpWaterToBarrel:new(playerObj, part, pump, 1, filter))

end

	------ say when water tank can not be reached - Tread ------------------
function ISVehiclePartMenu.onPumpWaterPathFail(playerObj)
	playerObj:Say(getText("IGUI_PlayerText_NoWayToWaterTankInlet"));
end

	----------------- Code for pumping from other Water Truck - Tread -----------------------
function ISVehiclePartMenu.FindVehicleWaterRS(playerObj, playerVehicle) --- based on Blair Algol (PlanetAlgol) code
	local radius = 5
	local cell = playerObj:getCell()
	local vehicleList = cell:getVehicles()
	local result = {}
	for index=0, vehicleList:size()-1 do
		local vehicle = vehicleList:get(index)
		for i=1,vehicle:getPartCount() do
			local part = vehicle:getPartByIndex(i-1)
			--- We want only containers which are not Tires or Gas Tank of a vehicle (so only Storage Tanks)
			local partContentType = part:getContainerContentType()
			if part:isContainer() and (part:getContainerContentType() == "Water" or part:getContainerContentType() == "WaterTainted") then
				if part:getContainerContentAmount() > 0 and vehicle ~= playerVehicle then
					local square = vehicle:getSquare()
					x = math.abs(vehicle:getX()-playerObj:getX())
					y = math.abs(vehicle:getY()-playerObj:getY())
					if x < radius and y < radius then
						print('RS Water Tank Veh Found')
						table.insert(result, part)
					end
				end
			end
		end
	end
	if #result >= 1 then return result end
	return false
end
		------
function ISVehiclePartMenu.onPumpWaterFromTruckRS(playerObj, part, source_Tank, filter) --- based on Blair Algol (PlanetAlgol) code
	if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end
	local square = source_Tank:getVehicle():getSquare()
	if square then
		local action = ISPathFindAction:pathToVehicleArea(playerObj, part:getVehicle(), part:getArea())
		action:setOnFail(ISVehiclePartMenu.onPumpWaterPathFail, playerObj)
		ISTimedActionQueue.add(action)
		ISTimedActionQueue.add(ISPumpWaterFromTruckRS:new(playerObj, part, square, 100, source_Tank, filter))
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------
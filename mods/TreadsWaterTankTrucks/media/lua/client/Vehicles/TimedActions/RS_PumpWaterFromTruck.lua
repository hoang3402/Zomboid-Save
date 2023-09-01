--------------------------------- Code by Tread ----- (Trealak on Steam) ---------------------------------
-------------------------------- Developed For Tread's Water Tank Trucks ---------------------------------
-------------------------------------- Remade Blair Algol function ---------------------------------------

require "TimedActions/ISBaseTimedAction"

ISPumpWaterFromTruckRS = ISBaseTimedAction:derive("ISRefuelFromFuelTruck")

function ISPumpWaterFromTruckRS:isValid()
	return true
end

function ISPumpWaterFromTruckRS:waitToStart()
	self.character:faceThisObject(self.vehicle)
	return self.character:shouldBeTurning()
end

function ISPumpWaterFromTruckRS:update()
	local litres = self.tankStart + (self.tankTarget - self.tankStart) * self:getJobDelta()
	litres = math.floor(litres)
	local pumpUnits = self.pumpStart + (self.pumpTarget - self.pumpStart) * self:getJobDelta()
	pumpUnits = math.ceil(pumpUnits)
	if litres ~= self.amountSent then
		local args = { vehicle = self.vehicle:getId(), part = self.part:getId(), amount = litres }
		sendClientCommand(self.character, 'vehicle', 'setContainerContentAmount', args)
		self.amountSent = litres

		local args2 = { vehicle = self.tank:getVehicle():getId(), part = self.tank:getId(), amount = pumpUnits }
		sendClientCommand(self.character, 'vehicle', 'setContainerContentAmount', args2)
	end

    self.character:setMetabolicTarget(Metabolics.HeavyDomestic);
end

function ISPumpWaterFromTruckRS:start()
	
	self.partData = self.part:getModData()
	self.tankData = self.tank:getModData()
	
	self.tankStart = self.part:getContainerContentAmount()
	self.pumpStart = self.tank:getContainerContentAmount()
	local pumpLitresAvail = self.pumpStart
	local tankLitresFree = self.part:getContainerCapacity() - self.tankStart
	local takeLitres = math.min(tankLitresFree, pumpLitresAvail)
	self.tankTarget = self.tankStart + takeLitres
	self.pumpTarget = self.pumpStart - takeLitres
	self.amountSent = self.tankStart

	self.action:setTime(takeLitres * 50)

	self:setActionAnim("fill_container_tap")
	self:setOverrideHandModels(nil, nil)
		
	if self.tankData.tainted == 1 and self.filter == nil  then
		sendClientCommand(self.character, 'RS_Server', 'RS_TaintPartModDataServer', { vehicle = self.vehicle:getId(), part = self.part:getId() })
	end
	
	if self.filter ~= nil then	-- tainting functions if Filter installed - Tread
		local filterCondition = self.filter:getCondition()
		if filterCondition >=70 then
			-- DO NOT taint water - Tread
		elseif filterCondition >= 30 and filterCondition < 70 and self.tankData.tainted == 1 then
			sendClientCommand(self.character, 'RS_Server', 'RS_TaintPartModDataServer', { vehicle = self.vehicle:getId(), part = self.part:getId() })
		elseif filterCondition < 30 then
			sendClientCommand(self.character, 'RS_Server', 'RS_TaintPartModDataServer', { vehicle = self.vehicle:getId(), part = self.part:getId() })
		end
	end

	self.sound = self.character:playSound("GeneratorLoop")
	self.sound2 = self.character:playSound("GetWaterFromTapMetalBig")
	addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 1)

end

---stopSound
function ISPumpWaterFromTruckRS:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound);
		self.character:stopOrTriggerSound(self.sound2);
	end
end

function ISPumpWaterFromTruckRS:stop()
	self:stopSound()
	
	-------damage the water filter after use -------------
	if self.filter ~= nil then
		local waterFlow = math.floor(self.pumpStart - self.tank:getContainerContentAmount())
		local filterDmgMultiplier = 1	-- dmg per unit of clean water (1/50000 of total filter "health") - Tread
		if self.tankData.tainted == 1 then filterDmgMultiplier = 5 end -- dmg per unit of dirty water (5/50000 of total filter "health") - Tread
		
		self.filterData = self.filter:getInventoryItem():getModData()
		if self.filterData.filterDmgFraction == nil then self.filterData.filterDmgFraction = 0 end -- set start value if empty - Tread
	--	print('Filter moddata=' .. self.filterData.filterDmgFraction)
		local filterDmg = (waterFlow * filterDmgMultiplier + self.filterData.filterDmgFraction)/500 -- 500 stands for 1% of filter condition - Tread
		local filterDmgFr
		filterDmg, filterDmgFr = math.modf(filterDmg) -- divide result into int and fraction values, int equals % damage to thee filter - Tread
		filterDmgFr = math.floor(filterDmgFr * 500) -- de-fraction the fraction value (in order to store as int - cannot apply fractional damage so w store it for later) - Tread
	--	print('Filter Dmg int=' .. filterDmg .. ' Filter Dmg Fraction=' .. filterDmgFr)
		self.filter:setCondition(self.filter:getCondition() - filterDmg) -- damage the filter - Tread
		self.vehicle:transmitPartCondition(self.filter); -- save condition change (for MP games) - Tread
		sendClientCommand(self.character, 'RS_Server', 'RS_FilterFractionDamage', { vehicle = self.filter:getVehicle():getId(), part = self.filter:getId(), value = filterDmgFr })
	end
	------------------------------------------------------

	ISBaseTimedAction.stop(self)
end

function ISPumpWaterFromTruckRS:perform()
	-- needed to remove from queue / start next.
	self:stopSound()
	
	
	-------damage the water filter after use -------------
	if self.filter ~= nil then
		local waterFlow = math.floor(self.pumpStart - self.tank:getContainerContentAmount())
		local filterDmgMultiplier = 1	-- dmg per unit of clean water (1/50000 of total filter "health") - Tread
		if self.tankData.tainted == 1 then filterDmgMultiplier = 5 end -- dmg per unit of dirty water (5/50000 of total filter "health") - Tread
		
		self.filterData = self.filter:getInventoryItem():getModData()
		if self.filterData.filterDmgFraction == nil then self.filterData.filterDmgFraction = 0 end -- set start value if empty - Tread
	--	print('Filter moddata=' .. self.filterData.filterDmgFraction)
		local filterDmg = (waterFlow * filterDmgMultiplier + self.filterData.filterDmgFraction)/500 -- 500 stands for 1% of filter condition - Tread
		local filterDmgFr
		filterDmg, filterDmgFr = math.modf(filterDmg) -- divide result into int and fraction values, int equals % damage to thee filter - Tread
		filterDmgFr = math.floor(filterDmgFr * 500) -- de-fraction the fraction value (in order to store as int - cannot apply fractional damage so w store it for later) - Tread
	--	print('Filter Dmg int=' .. filterDmg .. ' Filter Dmg Fraction=' .. filterDmgFr)
		self.filter:setCondition(self.filter:getCondition() - filterDmg) -- damage the filter - Tread
		self.vehicle:transmitPartCondition(self.filter); -- save condition change (for MP games) - Tread
		sendClientCommand(self.character, 'RS_Server', 'RS_FilterFractionDamage', { vehicle = self.filter:getVehicle():getId(), part = self.filter:getId(), value = filterDmgFr })
	end

	ISBaseTimedAction.perform(self)
end

function ISPumpWaterFromTruckRS:new(character, part, square, time, source_Tank, filter)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.vehicle = part:getVehicle()
	o.part = part
	o.square = square
	o.maxTime = math.max(time, 50)
	o.tank = source_Tank
	o.filter = filter
	return o
end


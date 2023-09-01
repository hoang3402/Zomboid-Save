---------------------Code by Tread ----- (Trealak on Steam) ---------------------------------
-- inspired by FuelAPI, Water Dispenser and Coco Liquid Overhaul by Konijima, Fuel Trailers and Trucks by Filibuster Rhymes and TMC (Tsar's Modding Company) ----------

require "TimedActions/ISBaseTimedAction"

ISPumpWaterToBarrel = ISBaseTimedAction:derive("ISRefuelFromGasPump")

function ISPumpWaterToBarrel:isValid()
	--return self.vehicle:isInArea(self.part:getArea(), self.character)
	return true;
end

function ISPumpWaterToBarrel:waitToStart()
	self.character:faceThisObject(self.vehicle)
	return self.character:shouldBeTurning()
end

-- Note to self -- Modify?? If waterStation not full AND Water tank not empty ....., litres (without barrelStart) -> add = litres - self.PreviousLitres (0 at start) -> setWaterAmount = waterStation:getWaterAmount + add
function ISPumpWaterToBarrel:update() 
	local litres = self.barrelStart + self.giveLitres * self:getJobDelta()
	local drain = self.tankStart - self.giveLitres * self:getJobDelta()
	litres = math.ceil(litres)
	drain = math.floor(drain)
	if self.waterStation:getWaterAmount() ~= self.barrelTarget and self.part:getContainerContentAmount() > 0 then
		local args = { vehicle = self.vehicle:getId(), part = self.part:getId(), amount = drain }
		sendClientCommand(self.character, 'vehicle', 'setContainerContentAmount', args)
		--self.waterStation:setWaterAmount(litres)
		local args = { x = self.waterStation:getX(), y = self.waterStation:getY(), z = self.waterStation:getZ(), index = self.waterStation:getObjectIndex(), amount = litres }
		sendClientCommand(self.character, 'object', 'setWaterAmount', args)
	end
	
   -- self.character:setMetabolicTarget(Metabolics.HeavyDomestic);
end

function ISPumpWaterToBarrel:start()
	self.partData = self.part:getModData()

	self.tankStart = self.part:getContainerContentAmount()
	self.barrelStart = self.waterStation:getWaterAmount();
	local barrelLitresFree = self.waterStation:getWaterMax() - self.barrelStart
	self.giveLitres = math.min(barrelLitresFree, self.tankStart)
	self.barrelTarget = self.barrelStart + self.giveLitres

	self.action:setTime(self.giveLitres * 10)

	self:setActionAnim("fill_container_tap")
	self:setOverrideHandModels(nil, nil)
	
	self.sound = self.character:playSound("GeneratorLoop")
	self.sound2 = self.character:playSound("GetWaterFromTapPlasticBig")
	addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 1)

	-----------taint water if source is tainted -------------
	if self.partData.tainted == 1 and self.waterStation:getProperties():Val("CustomName") ~= "Sink" and self.filter == nil then
		self.waterStation:setTaintedWater(true)
		self.waterStation:transmitModData()
	end
	
	if self.filter ~= nil and self.waterStation:getProperties():Val("CustomName") ~= "Sink" then	-- tainting functions if Filter installed - Tread
		local filterCondition = self.filter:getCondition()
		if filterCondition >=70 then
			-- DO NOT taint water - Tread
		elseif filterCondition >= 30 and filterCondition < 70 and self.partData.tainted == 1 then
			self.waterStation:setTaintedWater(true)
			self.waterStation:transmitModData()
		elseif filterCondition < 30 then
			self.waterStation:setTaintedWater(true)
			self.waterStation:transmitModData()
		end
	end
	

end

---stopSound
function ISPumpWaterToBarrel:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound);
		self.character:stopOrTriggerSound(self.sound2);
    end
end

function ISPumpWaterToBarrel:stop()
	self:stopSound()
	
	-------damage the water filter after use -------------
	if self.filter ~= nil then
		local waterFlow = math.floor(self.tankStart - self.part:getContainerContentAmount())+1
		local filterDmgMultiplier = 1	-- dmg per unit of clean water (1/50000 of total filter "health") - Tread
		if self.partData.tainted == 1 then filterDmgMultiplier = 5 end -- dmg per unit of dirty water (5/50000 of total filter "health") - Tread
		
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
		sendClientCommand(self.character, 'RS_Server', 'RS_FilterFractionDamage', { vehicle = self.vehicle:getId(), part = self.filter:getId(), value = filterDmgFr })
	end
	------------------------------------------------------

	ISBaseTimedAction.stop(self)
end

function ISPumpWaterToBarrel:perform()
	self:stopSound()
	
	-------damage the water filter after use -------------
	if self.filter ~= nil then
		local waterFlow = math.floor(self.tankStart - self.part:getContainerContentAmount())+1
		local filterDmgMultiplier = 1	-- dmg per unit of clean water (1/50000 of total filter "health") - Tread
		if self.partData.tainted == 1 then filterDmgMultiplier = 5 end -- dmg per unit of dirty water (5/50000 of total filter "health") - Tread
		
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
		sendClientCommand(self.character, 'RS_Server', 'RS_FilterFractionDamage', { vehicle = self.vehicle:getId(), part = self.filter:getId(), value = filterDmgFr })
	end
	------------------------------------------------------
	
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISPumpWaterToBarrel:new(character, part, waterStation, time, filter)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.vehicle = part:getVehicle()
	o.part = part
	o.waterStation = waterStation;
	o.maxTime = time
	o.filter = filter
	return o
end


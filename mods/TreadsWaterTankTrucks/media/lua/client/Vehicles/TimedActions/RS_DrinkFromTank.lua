---------------------Code by Tread ----- (Trealak on Steam) ---------------------------------
-- inspired by FuelAPI, Water Dispenser and Coco Liquid Overhaul by Konijima, Fuel Trailers and Trucks by Filibuster Rhymes and TMC (Tsar's Modding Company) ----------

require "TimedActions/ISBaseTimedAction"

ISDrinkWaterActionFromTank = ISBaseTimedAction:derive("ISDrinkFromDispenser")

function ISDrinkWaterActionFromTank:isValid()
	return true;
end

function ISDrinkWaterActionFromTank:waitToStart()
	self.character:faceThisObject(self.vehicle)
	return self.character:shouldBeTurning()
end


function ISDrinkWaterActionFromTank:start()
	self.partData = self.part:getModData()

	self:setActionAnim("drink_tap")
    

    self.tankStart = self.part:getContainerContentAmount()
    local thirst = self.character:getStats():getThirst()
    local waterNeeded = math.min(math.ceil(thirst / 0.1), 10)
    self.waterUnit = math.min(waterNeeded, self.tankStart)
    self.action:setTime(self.waterUnit * 30)
	
	if thirst > 0 then
		self.sound = self.character:getEmitter():playSound("DrinkingFromTap")
		addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 1)
	end
end

---stopSound
function ISDrinkWaterActionFromTank:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound);
    end
end

function ISDrinkWaterActionFromTank:stop()
    self:stopSound()

    local percentage = self.action:getJobDelta()
    self:drink(percentage)
	
	-------damage the water filter after use -------------
	if self.filter ~= nil then
		local waterFlow = math.floor(self.tankStart - self.part:getContainerContentAmount())
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

function ISDrinkWaterActionFromTank:perform()
    self:stopSound()

    local percentage = self.action:getJobDelta()
    self:drink(percentage)
	
	-------damage the water filter after use -------------
	if self.filter ~= nil then
		local waterFlow = math.floor(self.tankStart - self.part:getContainerContentAmount())
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

    ISBaseTimedAction.perform(self)
end

---update
function ISDrinkWaterActionFromTank:update()

end

---drink
function ISDrinkWaterActionFromTank:drink(percentage)
    -- calc percentage drank
    if percentage > 0.95 then
        percentage = 1.0;
    end
    local uses = math.floor(self.waterUnit * percentage + 0.001);

    local waterAmount = self.part:getContainerContentAmount()
    for i=1,uses do
        if waterAmount <= 0 then break end

        if self.character:getStats():getThirst() > 0 then
            self.character:getStats():setThirst(self.character:getStats():getThirst() - 0.1)
            if self.character:getStats():getThirst() < 0 then
                self.character:getStats():setThirst(0)
            end
			
			-------------------------if tainted water -------------------------
            if self.partData.tainted == 1 and self.filter == nil then
               self.character:getBodyDamage():setPoisonLevel(self.character:getBodyDamage():getPoisonLevel() + 10)
            end
			
			if self.filter ~= nil then	-- tainting functions if Filter installed - Tread
				local filterCondition = self.filter:getCondition()
				if filterCondition >=70 then
					-- DO NOT taint water - Tread
				elseif filterCondition >= 30 and filterCondition < 70 and self.partData.tainted == 1 then
					self.character:getBodyDamage():setPoisonLevel(self.character:getBodyDamage():getPoisonLevel() + 10)
				elseif filterCondition < 30 then
					self.character:getBodyDamage():setPoisonLevel(self.character:getBodyDamage():getPoisonLevel() + 10)
				end
			end
			

            waterAmount = self.part:getContainerContentAmount()
            self.part:setContainerContentAmount(waterAmount - 1)
        end
    end
end

function ISDrinkWaterActionFromTank:new(character, part, time, filter)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.vehicle = part:getVehicle()
	o.part = part
	o.maxTime = time
	o.filter = filter
	return o
end
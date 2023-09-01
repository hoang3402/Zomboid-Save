---------------------Code by Tread ----- (Trealak on Steam) ---------------------------------
-- inspired by FuelAPI, Water Dispenser and Coco Liquid Overhaul by Konijima, Fuel Trailers and Trucks by Filibuster Rhymes and TMC (Tsar's Modding Company) ----------

require "TimedActions/ISBaseTimedAction"

ISTakeWaterActionFromTank = ISBaseTimedAction:derive("ISTakeGasolineFromVehicle")

function ISTakeWaterActionFromTank:isValid()
	return true;
end

function ISTakeWaterActionFromTank:waitToStart()
	self.character:faceThisObject(self.vehicle)
	return self.character:shouldBeTurning()
end

function ISTakeWaterActionFromTank:update()
	self.character:faceThisObject(self.vehicle)
	self.item:setJobDelta(self:getJobDelta())
	self.item:setJobType(getText("ContextMenu_Fill") .. self.item:getName())
	local litres = self.tankStart + (self.tankTarget - self.tankStart) * self:getJobDelta()
	litres = math.floor(litres + 0.5)
	if litres ~= self.amountSent then
		local args = { vehicle = self.vehicle:getId(), part = self.part:getId(), amount = litres }
		sendClientCommand(self.character, 'vehicle', 'setContainerContentAmount', args)
		self.amountSent = litres
	end
	
	local litresTaken = self.tankStart - litres
	
	local usedDelta = self.startUsedDelta + litresTaken * self.item:getUseDelta()
	self.item:setUsedDelta(usedDelta);
	
    self.character:setMetabolicTarget(Metabolics.HeavyDomestic);
end

function ISTakeWaterActionFromTank:start()
	self.partData = self.part:getModData()

	if self.item:canStoreWater() and not self.item:isWaterSource() then -- replace empty item with matching "water source" item - Tread 
		
		-- we create the item which contain our water - Tread --
		local wasPrimary = self.character:getPrimaryHandItem() == self.item
		local wasSecondary = self.character:getSecondaryHandItem() == self.item
		local oldItem = self.item
		local newItemType = oldItem:getReplaceOnUseOn()
		newItemType = string.sub(newItemType,13)
		newItemType = oldItem:getModule() .. "." .. newItemType;
		local newItem = InventoryItemFactory.CreateItem(newItemType,0)
		newItem:setCondition(oldItem:getCondition())
		newItem:setFavorite(oldItem:isFavorite())
		oldItem = nil		
		self.character:getInventory():DoRemoveItem(self.item)
		self.item = self.character:getInventory():AddItem(newItem)
		self.item:setUsedDelta(0)

		if wasPrimary then
			self.character:setPrimaryHandItem(self.item)
		end
		if wasSecondary then
			self.character:setSecondaryHandItem(self.item)
		end
	end		
	
	self.tankStart = self.part:getContainerContentAmount()
	self.item:setBeingFilled(true)
	self.startUsedDelta = self.item:getUsedDelta()
	self.itemCapacity = math.floor(1.0 / self.item:getUseDelta() + 0.0001)
	
	self.itemAvSpace = self.itemCapacity - self.item:getDrainableUsesInt()
	self.waterUnit = math.min(self.itemAvSpace, self.tankStart)
	self.endUsedDelta = math.min(self.startUsedDelta + self.waterUnit * self.item:getUseDelta(), 1.0)
	
	local take = math.min(self.waterUnit, self.tankStart)
	self.tankTarget = self.tankStart - take

	--print('Item Capacity=' .. self.itemCapacity ..'take=' .. take .. ' Av Space=' .. self.itemAvSpace)
	self.amountSent = math.ceil(self.tankStart)
	self.action:setTime((self.waterUnit * 15) + 30)

	self:setActionAnim("fill_container_tap")
	self:setOverrideHandModels(nil, self.item:getStaticModel())
	
	self.sound = self.character:playSound("GetWaterFromTap")
    addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 1)	
	
	if self.partData.tainted == 1 and self.filter == nil  then
		self.item:setTaintedWater(true)
	end
	
	if self.filter ~= nil then	-- tainting functions if Filter installed - Tread
		local filterCondition = self.filter:getCondition()
		if filterCondition >=70 then
			-- DO NOT taint water - Tread
		elseif filterCondition >= 30 and filterCondition < 70 and self.partData.tainted == 1 then
			self.item:setTaintedWater(true)
		elseif filterCondition < 30 then
			self.item:setTaintedWater(true)
		end
	end
	
end

---stopSound
function ISTakeWaterActionFromTank:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound);
    end
end

function ISTakeWaterActionFromTank:stop()
	self:stopSound()
	self.item:setJobDelta(0)
	self.item:setBeingFilled(false)
	local currentDelta = self.item:getUsedDelta()
	
	if currentDelta <= 0 then -- makes bottle empty again if not filled with any water units
		self.item:Use()
	elseif  currentDelta < 1 and currentDelta > (1 - self.item:getUseDelta()) then
		self.item:setUsedDelta(1);
	end 
	
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

function ISTakeWaterActionFromTank:perform()
	self:stopSound()
	self.item:setJobDelta(0)
	self.item:setBeingFilled(false)
	local currentDelta = self.item:getUsedDelta()
	
	if currentDelta <= 0 then -- makes bottle empty again if not filled with any water units
		self.item:Use()
	elseif  currentDelta < 1 and currentDelta > (1 - self.item:getUseDelta()) then
		self.item:setUsedDelta(1);
	end
	
		--[[-----damage the water filter after use -------------
	if self.filter ~= nil then
		local waterFlow = math.floor(self.tankStart - self.part:getContainerContentAmount())
		local filterDmgMultiplier = 0.004	-- % dmg per unit of clean water - Tread
		if self.partData.tainted == 1 then filterDmgMultiplier = 0.02 end -- % dmg per unit of dirty water - Tread
		self.filter:setCondition(self.filter:getCondition() - waterFlow * filterDmgMultiplier) -- damage the filter - Tread
	end
	]]------------------------------------------------------
	
	
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
	
	
--	self.tankTarget = math.floor(self.tankTarget)
	
--	local args = { vehicle = self.vehicle:getId(), part = self.part:getId(), amount = self.tankTarget }
--	sendClientCommand(self.character, 'vehicle', 'setContainerContentAmount', args)
--	print('take fluid level=' .. self.part:getContainerContentAmount() .. ' usedDelta=' .. self.item:getUsedDelta())
	
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISTakeWaterActionFromTank:new(character, part, item, time, filter)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.vehicle = part:getVehicle()
	o.part = part
	o.item = item
	o.maxTime = time
	o.filter = filter
	return o
end
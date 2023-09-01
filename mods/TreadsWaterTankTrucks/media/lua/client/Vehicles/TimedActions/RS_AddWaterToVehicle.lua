---------------------Code by Tread ----- (Trealak on Steam) ---------------------------------
-- inspired by FuelAPI, Water Dispenser and Coco Liquid Overhaul by Konijima, Fuel Trailers and Trucks by Filibuster Rhymes and TMC (Tsar's Modding Company) ----------

require "TimedActions/ISBaseTimedAction"

ISAddWaterToTank = ISBaseTimedAction:derive("ISAddGasolineToVehicle")

function ISAddWaterToTank:isValid()
	return true;
end

function ISAddWaterToTank:waitToStart()
	self.character:faceThisObject(self.vehicle)
	return self.character:shouldBeTurning()
end

function ISAddWaterToTank:update()
	self.character:faceThisObject(self.vehicle)
	self.item:setJobDelta(self:getJobDelta())
	
	self.item:setJobType(getText("IGUI_JobType_PourIn") .. " " .. getText("IGUI_VehiclePart" .. self.part:getId()))

	local litres = self.tankStart + (self.tankTarget - self.tankStart) * self:getJobDelta()
	litres = math.floor(litres)
	if litres ~= self.amountSent then
		local args = { vehicle = self.vehicle:getId(), part = self.part:getId(), amount = litres }
		sendClientCommand(self.character, 'vehicle', 'setContainerContentAmount', args)
		self.amountSent = litres
		
		local litresTaken = litres - self.tankStart
		local usedDelta = self.itemStart - litresTaken / self.itemCapacity
		self.item:setUsedDelta(usedDelta)
	end
	


    self.character:setMetabolicTarget(Metabolics.HeavyDomestic);
end

function ISAddWaterToTank:start()
	self.partData = self.part:getModData()
	
	self.tankStart = self.part:getContainerContentAmount()
	self.itemStart = self.item:getUsedDelta()
	self.itemCapacity = math.floor(1.0 / self.item:getUseDelta() + 0.0001)
	

	local add = self.part:getContainerCapacity() - self.tankStart
	local take = math.min(add, self.itemStart * self.itemCapacity)
	self.tankTarget = self.tankStart + take
	self.tankTarget = math.floor(self.tankTarget + 0.5) -- rounding workaround - Tread
	self.itemTarget = self.itemStart - take / self.itemCapacity
	--print('Item Capacity=' .. self.itemCapacity ..'take=' .. take .. ' itmTarget=' .. self.itemTarget)

	self.amountSent = self.tankTarget

	self.action:setTime((take * 20) + 30)

	self:setActionAnim("refuelgascan")
	self:setOverrideHandModels(self.item:getStaticModel(), nil)
	
	self.sound = self.character:playSound("GetWaterFromTapMetalBig")
	addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 1)

	-----------taint water if source is tainted -------------	
	if self.item:isTaintedWater() then
		sendClientCommand(self.character, 'RS_Server', 'RS_TaintPartModDataServer', { vehicle = self.vehicle:getId(), part = self.part:getId() })
	--	RS_UpdateVehicleModData.RS_TaintPartModDataServer(self.vehicle, self.part)
	--	self.partData.tainted = 1 
	--		self.part:transmitModData(); 
	--		self.vehicle:transmitPartModData(self.part);

	end
	
end

---stopSound
function ISAddWaterToTank:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound);
    end
end

function ISAddWaterToTank:stop()
	self:stopSound()
	self.item:setJobDelta(0)
	
	local currentDelta = self.item:getUsedDelta()
	
	if currentDelta <= 0 then
		self.item:Use()
	end
	ISBaseTimedAction.stop(self)
end

function ISAddWaterToTank:perform()
	self:stopSound()
	self.item:setJobDelta(0)
	self.item:setUsedDelta(self.itemTarget)
	
	
--	self.tankTarget = math.ceil(self.tankTarget)
	
	local args = { vehicle = self.vehicle:getId(), part = self.part:getId(), amount = self.tankTarget }
	sendClientCommand(self.character, 'vehicle', 'setContainerContentAmount', args)
	if self.item:getUsedDelta() <= 0 then
		self.item:Use()
	end
--	print('add gasoline level=' .. self.part:getContainerContentAmount())
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISAddWaterToTank:new(character, part, item, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.vehicle = part:getVehicle()
	o.part = part
	o.item = item
	o.maxTime = time
	return o
end


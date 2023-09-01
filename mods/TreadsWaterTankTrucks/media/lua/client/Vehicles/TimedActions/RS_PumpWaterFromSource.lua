---------------------Code by Tread ----- (Trealak on Steam) ---------------------------------
-- inspired by FuelAPI, Water Dispenser and Coco Liquid Overhaul by Konijima, Fuel Trailers and Trucks by Filibuster Rhymes and TMC (Tsar's Modding Company) ----------

require "TimedActions/ISBaseTimedAction"

ISPumpWaterFromSource = ISBaseTimedAction:derive("ISRefuelFromGasPump")

function ISPumpWaterFromSource:isValid()
	--return self.vehicle:isInArea(self.part:getArea(), self.character)
	return true;
end

function ISPumpWaterFromSource:waitToStart()
	self.character:faceThisObject(self.vehicle)
	return self.character:shouldBeTurning()
end

function ISPumpWaterFromSource:update()
	local litres = self.tankStart + self.takeLitres * self:getJobDelta()
	litres = math.ceil(litres)
	--if litres ~= self.tankTarget then
	if self.part:getContainerContentAmount() ~= self.tankTarget and self.waterStation:getWaterAmount() > 0 then
		local args = { vehicle = self.vehicle:getId(), part = self.part:getId(), amount = litres }
		sendClientCommand(self.character, 'vehicle', 'setContainerContentAmount', args)

		if self.sourceIsWaterTile == 0 then  
			local drain = self.pumpStart - self.takeLitres * self:getJobDelta()
			drain = math.floor(drain)
			--self.waterStation:setWaterAmount(drain);
			local args = { x = self.waterStation:getX(), y = self.waterStation:getY(), z = self.waterStation:getZ(), index = self.waterStation:getObjectIndex(), amount = drain }
			sendClientCommand(self.character, 'object', 'setWaterAmount', args)
		end			
	end
	
   -- self.character:setMetabolicTarget(Metabolics.HeavyDomestic);
end

function ISPumpWaterFromSource:start()
	self.partData = self.part:getModData()
	-- Check if source is not "water tile" (in order to avoid unnecessary draining of infinite source), drain all others --
	self.sourceIsWaterTile = 1
	if not self.waterStation:getProperties() ~= nil and not self.waterStation:getProperties():Is(IsoFlagType.water) then  
		self.sourceIsWaterTile = 0
	end
	------------------------------
	self.tankStart = self.part:getContainerContentAmount()
	self.pumpStart = self.waterStation:getWaterAmount();
	local tankLitresFree = self.part:getContainerCapacity() - self.tankStart
	self.takeLitres = math.min(tankLitresFree, self.pumpStart)
	self.tankTarget = self.tankStart + self.takeLitres
	self.pumpTarget = self.pumpStart - self.takeLitres

	self.action:setTime(self.takeLitres * 10)

	self:setActionAnim("fill_container_tap")
	self:setOverrideHandModels(nil, nil)
	
	self.sound = self.character:playSound("GeneratorLoop")
	self.sound2 = self.character:playSound("GetWaterFromTapMetalBig")
	addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 1)

	-----------taint water if source is tainted -------------
	if self.waterStation:isTaintedWater() then
		sendClientCommand(self.character, 'RS_Server', 'RS_TaintPartModDataServer', { vehicle = self.vehicle:getId(), part = self.part:getId() })
	--	RS_UpdateVehicleModData.RS_TaintPartModDataServer(self.vehicle, self.part)
	--	self.partData.tainted = 1
	--	self.part:transmitModData();
	end

	--self.character:reportEvent("EventTakeWater");
end

---stopSound
function ISPumpWaterFromSource:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound);
		self.character:stopOrTriggerSound(self.sound2);
    end
end

function ISPumpWaterFromSource:stop()
	self:stopSound()

	ISBaseTimedAction.stop(self)
end

function ISPumpWaterFromSource:perform()
	self:stopSound()
	
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISPumpWaterFromSource:new(character, part, waterStation, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.vehicle = part:getVehicle()
	o.part = part
	o.waterStation = waterStation;
	--o.maxTime = math.max(time, 50)
	o.maxTime = time
	return o
end


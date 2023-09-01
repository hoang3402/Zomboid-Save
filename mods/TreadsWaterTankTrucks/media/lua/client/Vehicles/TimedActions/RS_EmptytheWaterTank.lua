---------------------Code by Tread ----- (Trealak on Steam) ---------------------------------
-- inspired by FuelAPI, Water Dispenser and Coco Liquid Overhaul by Konijima, Fuel Trailers and Trucks by Filibuster Rhymes and TMC (Tsar's Modding Company) ----------

require "TimedActions/ISBaseTimedAction"

ISEmptyWaterTank = ISBaseTimedAction:derive("ISRefuelFromGasPump")

function ISEmptyWaterTank:isValid()
	return true;
end

function ISEmptyWaterTank:waitToStart()
	self.character:faceThisObject(self.vehicle)
	return self.character:shouldBeTurning()
end


function ISEmptyWaterTank:start()

	self:setActionAnim("fill_container_tap")
	self:setOverrideHandModels(nil, nil)
	
    self.sound = self.character:getEmitter():playSound("GeneratorLoop")
	self.sound2 = self.character:playSound("PourLiquidOnGround")
    addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 1)

    self.tankStart = self.part:getContainerContentAmount()
	self.amountSent = math.ceil(self.tankStart)
    self.action:setTime(self.tankStart * 7)
	
end

---stopSound
function ISEmptyWaterTank:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound);
		self.character:stopOrTriggerSound(self.sound2);
    end
end

function ISEmptyWaterTank:stop()
    self:stopSound()

    ISBaseTimedAction.stop(self)
end

function ISEmptyWaterTank:perform()
    self:stopSound()

    ISBaseTimedAction.perform(self)
end

---update
function ISEmptyWaterTank:update()
	self.character:faceThisObject(self.vehicle)


	local litres = self.tankStart + (0 - self.tankStart) * self:getJobDelta()
	litres = math.ceil(litres)
	if litres ~= self.amountSent then
		local args = { vehicle = self.vehicle:getId(), part = self.part:getId(), amount = litres }
		sendClientCommand(self.character, 'vehicle', 'setContainerContentAmount', args)
		self.amountSent = litres
	end
end

function ISEmptyWaterTank:new(character, part, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.vehicle = part:getVehicle()
	o.part = part
	o.maxTime = time
	return o
end
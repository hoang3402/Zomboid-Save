--***********************************************************
--**                       BitBraven                       **
--***********************************************************

require "TimedActions/ISBaseTimedAction"
CSISTimedAction = ISBaseTimedAction:derive("CSISTimedAction")

CSISTimedAction.TryReturnTool = function (self)
    if self.container == nil then return end
    local tool = self.character:getPrimaryHandItem(); if not tool then return end
    local currentToolContainer = tool:getContainer(); if not currentToolContainer then return end
    if self.container ~= currentToolContainer then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, tool, currentToolContainer, self.container))
    elseif tool:isEquipped() then
        ISTimedActionQueue.add(ISUnequipAction:new(self.character, tool, 50))
    end
end

CSISTimedAction.isValid = function(self)
    return true
end

CSISTimedAction.update = function(self)

end

CSISTimedAction.start = function(self)

    if self.typeTimeAction == "pryDoor" then

        self:setActionAnim("RemoveBarricade")
        self:setAnimVariable("RemoveBarricade", "CrowbarMid")

        BravensUtilsO1.DelayFunction(function()
            BravensUtilsO1.TryPlaySoundClip(self.character, BravensUtilsO1.GetProperSound(self.priableObject, false))
        end, 35)
    end

    if self.typeTimeAction == "pryVehicleDoor" then

        self:setActionAnim("RemoveBarricade")
        self:setAnimVariable("RemoveBarricade", "CrowbarMid")

        BravensUtilsO1.DelayFunction(function()
            BravensUtilsO1.TryPlaySoundClip(self.character, "MetalBarHit")
        end, 35)
    end
end

CSISTimedAction.stop = function(self)
    ISBaseTimedAction.stop(self)

    if self.typeTimeAction == "pryDoor" then
        BravensUtilsO1.TryStopSoundClip(self.character, BravensUtilsO1.GetProperSound(self.priableObject, false))
    end

    if self.typeTimeAction == "pryVehicleDoor" then
        BravensUtilsO1.TryStopSoundClip(self.character, "MetalBarHit")
    end
end

CSISTimedAction.perform = function(self)

    if self.typeTimeAction == "pryDoor" then

        BravensUtilsO1.TirePlayer(self.character, 0.07)
        BravensUtilsO1.TryStopSoundClip(self.character, BravensUtilsO1.GetProperSound(self.priableObject, false))

        if CSUtils.PrySuccessfully(self.character, 0) == true then
            CSServer.PryDoorOpen(self.worldObjects, self.priableObject, self.character)
            CSISTimedAction.TryReturnTool(self)
        else
            self.character:Say(getText("IGUI_Pry_fail"))
            self.character:getXp():AddXP(Perks.Strength, 40)

            if BravensUtilsO1.GetProperSound(self.priableObject, true) == "Wooden" then
                BravensUtilsO1.TryPlaySoundClip(self.character, "BreakLockOnWindow")
            else
                BravensUtilsO1.TryPlaySoundClip(self.character, "MetalBarBreak")
            end
        end
    end

    if self.typeTimeAction == "pryVehicleDoor" then

        BravensUtilsO1.TirePlayer(self.character, 0.1)
        BravensUtilsO1.TryStopSoundClip(self.character, "MetalBarHit")

        if CSUtils.PrySuccessfully(self.character, 1) == true then

            local args = { vehicle = self.vehicleID, part = self.priableObjectID, locked = false, open = true }
            sendClientCommand(self.character, 'vehicle', 'setDoorLocked', args)
	        sendClientCommand(self.character, 'vehicle', 'setDoorOpen', args)

            local isTrunk = self.priableObjectID == "TrunkDoor" or self.priableObjectID == "DoorRear"
            if not (isTrunk) then
                BravensUtilsO1.TryPlaySoundClip(self.character, "VehicleDoorOpen")
            else
                BravensUtilsO1.TryPlaySoundClip(self.character, "VehicleTrunkOpen")
            end

            self.character:getXp():AddXP(Perks.Strength, 100)
            CSISTimedAction.TryReturnTool(self)
        else
            self.character:Say(getText("IGUI_Pry_fail"))
            BravensUtilsO1.TryPlaySoundClip(self.character, "MetalBarBreak")
            self.character:getXp():AddXP(Perks.Strength, 25)
        end
    end

    ISBaseTimedAction.perform(self)
end

CSISTimedAction.PryDoor = function(self, worldObjects, priableObject, character, container, time)

    local action = ISBaseTimedAction.new(self, character)
    action.typeTimeAction = "pryDoor"
    action.worldObjects = worldObjects
    action.priableObject = priableObject
    action.character = character
    action.container = container
    action.stopOnWalk = true
    action.stopOnRun = true
    action.maxTime = time
    action.fromHotbar = false

    if action.character:isTimedActionInstant() then action.maxTime = 1 end
    return action
end

CSISTimedAction.PryVehicleDoor = function(self, vehicle, priableObject, character, container, time)

    local action = ISBaseTimedAction.new(self, character)
    action.typeTimeAction = "pryVehicleDoor"
    action.vehicleID = vehicle:getId()
    action.priableObjectID = priableObject:getId()
    action.character = character
    action.container = container
    action.stopOnWalk = true
    action.stopOnRun = true
    action.maxTime = time
    action.fromHotbar = false

    if action.character:isTimedActionInstant() then o.maxTime = 1 end
    return action
end

return TimeAction
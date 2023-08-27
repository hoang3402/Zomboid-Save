require "AutoMechanics"

--hook timed actions
local vanilla_ISUninstallVehiclePart_stop = ISUninstallVehiclePart.stop
function ISUninstallVehiclePart:stop()
    vanilla_ISUninstallVehiclePart_stop(self)
    
    if AutoMechanics.onAutoMechanicsTrain_started then
        AutoMechanics.StopMechanicsTrain()
        if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics stop from ISUninstallVehiclePart:stop");end
    end
end

local vanilla_ISUninstallVehiclePart_perform = ISUninstallVehiclePart.perform
function ISUninstallVehiclePart:perform()
    vanilla_ISUninstallVehiclePart_perform(self)
    
    if AutoMechanics.onAutoMechanicsTrain_started then
        if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics continue from ISUninstallVehiclePart:perform"); end
        AutoMechanics.jobOrganisation.pendingJob = "Uninstall";
        AutoMechanics.jobOrganisation.pendingPart = self.part
        AutoMechanics.jobOrganisation.pendingTimeSpeed = getGameTime():getTrueMultiplier();
        if AutoMechanics.OPTIONS.VerboseTimeSpeed then print ("AutoMechanics.ISUninstallVehiclePart timespeed = "..getGameTime():getTrueMultiplier()) end
    elseif AutoMechanics.doUntilSuccess() then
        AutoMechanics.untilSuccess.timeSpeed = getGameTime():getTrueMultiplier();
        AutoMechanics.untilSuccess.part = self.part
        AutoMechanics.untilSuccess.player = self.character
        AutoMechanics.untilSuccess.item = nil
    end
end


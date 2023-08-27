require "AutoMechanics"

local vanilla_ISInstallVehiclePart_stop = ISInstallVehiclePart.stop
function ISInstallVehiclePart:stop()
    vanilla_ISInstallVehiclePart_stop(self)
    
    if AutoMechanics.onAutoMechanicsTrain_started then
        AutoMechanics.StopMechanicsTrain()
        if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics stop from ISInstallVehiclePart:stop"); end
    end
end

local vanilla_ISInstallVehiclePart_perform = ISInstallVehiclePart.perform
function ISInstallVehiclePart:perform()
    vanilla_ISInstallVehiclePart_perform(self)
    
    if AutoMechanics.onAutoMechanicsTrain_started then
        if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics continue from ISInstallVehiclePart:perform"); end
        AutoMechanics.jobOrganisation.pendingJob = "Install";
        AutoMechanics.jobOrganisation.pendingPart = self.part
        AutoMechanics.jobOrganisation.pendingTimeSpeed = getGameTime():getTrueMultiplier();
        if AutoMechanics.OPTIONS.VerboseTimeSpeed then print ("AutoMechanics.ISInstallVehiclePart timespeed = "..getGameTime():getTrueMultiplier()) end
    elseif AutoMechanics.doUntilSuccess() then
        AutoMechanics.untilSuccess.timeSpeed = getGameTime():getTrueMultiplier();
        AutoMechanics.untilSuccess.part = self.part
        AutoMechanics.untilSuccess.player = self.character
        AutoMechanics.untilSuccess.item = self.item
    end
end


--***********************************************************
--**                       BitBraven                       **
--***********************************************************

local Settings = CommonSense.Settings
local OnVehicleDashboardPreRender = ISVehicleDashboard.prerender

local function ApplyColorDynamically(amount, alpha)

    local color = {r=0, g=0, b=0, a=0}

    if not SandboxVars.CommonSense.ColorFilter then

        if amount > 0.75 then
            color = {r=0, g=1, b=0, a=alpha}
        elseif amount > 0.50 then
            color = {r=1, g=1, b=0, a=alpha}
        elseif amount > 0.25 then
            color = {r=1, g=0.5, b=0, a=alpha}
        elseif amount > 0.10 then
            color = {r=1, g=0, b=0, a=alpha}
        else
            color = {r=0.5, g=0, b=0, a=alpha}
        end
    else
        if amount > 0.75 then
            color = {r=1, g=1, b=0, a=alpha}
        elseif amount > 0.50 then
            color = {r=1, g=0.5, b=0, a=alpha}
        elseif amount > 0.25 then
            color = {r=1, g=0.3, b=0, a=alpha}
        elseif amount > 0.10 then
            color = {r=1, g=0, b=0, a=alpha}
        else
            color = {r=0.5, g=0, b=0, a=alpha}
        end
    end

    return color
end

function ISVehicleDashboard:prerender()

    OnVehicleDashboardPreRender(self)

    if not SandboxVars.CommonSense.PartsHighlighter then return end
    if not self.vehicle then return end
	if not (self.vehicle:isKeysInIgnition() or self.vehicle:isHotwired()) then return end
	if not self.vehicle:isEngineRunning() then return end

    local alpha = self:getAlphaFlick(0.65)
    self.batteryTex.backgroundColor = ApplyColorDynamically(self.vehicle:getBatteryCharge(), alpha)

    local engine = self.vehicle:getPartById("Engine")
    if engine then
    self.engineTex.backgroundColor = ApplyColorDynamically(engine:getCondition() / 100, alpha)
    end

    local heater = self.vehicle:getPartById("Heater")
    if heater and heater:getModData().active then
    self.heaterTex.backgroundColor = ApplyColorDynamically(heater:getCondition() / 100, alpha)
    end
end
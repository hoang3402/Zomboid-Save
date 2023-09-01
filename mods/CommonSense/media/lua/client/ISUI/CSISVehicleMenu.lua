--***********************************************************
--**                       BitBraven                       **
--***********************************************************

local OnShowRadialMenuOutside = ISVehicleMenu.showRadialMenuOutside

ISVehicleMenu.showRadialMenuOutside = function(playerObj)

	if playerObj:getVehicle() then return end

	OnShowRadialMenuOutside(playerObj)
    CSUtils.showRadialMenuOutsideCrowbar(playerObj)
end
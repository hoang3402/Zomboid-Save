--***********************************************************
--**                   KI5 / bikinihorst                   **
--***********************************************************

M911 = {
	parts = {
		DoorFrontLeftArmor = {
			M911DoorFrontLeftArmor = {
				DoorFrontLeftArmor = "M911CarFrontDoorArmor",
			},
		},
		DoorFrontRightArmor = {
			M911DoorFrontRightArmor = {
				DoorFrontRightArmor = "M911CarFrontDoorArmor",
			},
		},
		Bullbar = {
			M911Bullbar = {
				Bullbar0 = "M911Bullbar0",
				Bullbar1 = "M911Bullbar1",
			},
			default = "random",
		},
		WindshieldArmor = {
			M911WindshieldArmor = {
				WindshieldArmor = "M911WindshieldArmor",
			},
		},
		WindshieldRearArmor = {
			M911WindshieldRearArmor = {
				WindshieldRearArmor = "M911WindshieldRearArmor",
			},
		},
		SpareTire = {
			M911SpareTire = {
				SpareTire = "V100Tire2",
			},
			default = "trve_random",
			noPartChance = 10,
		},
		Muffler = {
			M911Muffler = {
				Muffler = "M911Muffler",
			},
			default = "first",
		},
		Mudflaps = {
			M911Mudflaps = {
				Mudflaps = "M911Mudflaps",
			},
			default = "trve_random",
			noPartChance = 35,
		},
	},
};

KI5:createVehicleConfig(M911);

function M911.ContainerAccess.TruckBed2(vehicle, part, chr)
	if chr:getVehicle() then return false end
	if not vehicle:isInArea(part:getArea(), chr) then return false end
	local TruckBed2 = vehicle:getPartById("TrunkDoor2")
	if TruckBed2 and TruckBed2:getDoor() then
		if not TruckBed2:getInventoryItem() then return true end
		if not TruckBed2:getDoor():isOpen() then return false end
	end
	--
	return true
end

function M911.ContainerAccess.TruckBed3(vehicle, part, chr)
	if chr:getVehicle() then return false end
	if not vehicle:isInArea(part:getArea(), chr) then return false end
	local TruckBed3 = vehicle:getPartById("TrunkDoor3")
	if TruckBed3 and TruckBed3:getDoor() then
		if not TruckBed3:getInventoryItem() then return true end
		if not TruckBed3:getDoor():isOpen() then return false end
	end
	--
	return true
end
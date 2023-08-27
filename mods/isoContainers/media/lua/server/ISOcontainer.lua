ISO = ISO or {};
ISO.ContainerAccess = {}

function ISO.ContainerAccess.TruckBed2(vehicle, part, chr)
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
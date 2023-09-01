--------------------------------- Code by Tread ----- (Trealak on Steam) ---------------------------------
-------------------------------- Developed For Tread's Water Tank Trucks ---------------------------------
local function info()

--------------------------------------------- Init tables --------------------------------------------
    ISCarMechanicsOverlay.PartList["DoorFrontLeft"].vehicles = ISCarMechanicsOverlay.PartList["DoorFrontLeft"].vehicles or {}
    ISCarMechanicsOverlay.PartList["DoorFrontRight"].vehicles = ISCarMechanicsOverlay.PartList["DoorFrontRight"].vehicles or {}
    ISCarMechanicsOverlay.PartList["EngineDoor"].vehicles = ISCarMechanicsOverlay.PartList["EngineDoor"].vehicles or {}
    ISCarMechanicsOverlay.PartList["TireFrontLeft"].vehicles = ISCarMechanicsOverlay.PartList["TireFrontLeft"].vehicles or {}
    ISCarMechanicsOverlay.PartList["TireFrontRight"].vehicles = ISCarMechanicsOverlay.PartList["TireFrontRight"].vehicles or {}
    ISCarMechanicsOverlay.PartList["TireRearLeft"].vehicles = ISCarMechanicsOverlay.PartList["TireRearLeft"].vehicles or {}
    ISCarMechanicsOverlay.PartList["TireRearRight"].vehicles = ISCarMechanicsOverlay.PartList["TireRearRight"].vehicles or {}
    ISCarMechanicsOverlay.PartList["WindowFrontLeft"].vehicles = ISCarMechanicsOverlay.PartList["WindowFrontLeft"].vehicles or {}
    ISCarMechanicsOverlay.PartList["WindowFrontRight"].vehicles = ISCarMechanicsOverlay.PartList["WindowFrontRight"].vehicles or {}
    ISCarMechanicsOverlay.PartList["Windshield"].vehicles = ISCarMechanicsOverlay.PartList["Windshield"].vehicles or {}
    ISCarMechanicsOverlay.PartList["TruckBed"].vehicles = ISCarMechanicsOverlay.PartList["TruckBed"].vehicles or {}

    ----------------------------------- Custom Liquid / Gas Truck zones ----------------------------------
    ISCarMechanicsOverlay.PartList["DoorFrontLeft"].vehicles["fueltruck_"] = {x=83,y=244,x2=91,y2=300};
    ISCarMechanicsOverlay.PartList["DoorFrontRight"].vehicles["fueltruck_"] = {x=202,y=244,x2=209,y2=300};
    ISCarMechanicsOverlay.PartList["EngineDoor"].vehicles["fueltruck_"] = {x=92,y=146,x2=197,y2=221};
    ISCarMechanicsOverlay.PartList["TireFrontLeft"].vehicles["fueltruck_"] = {x=78,y=182,x2=85,y2=238};
    ISCarMechanicsOverlay.PartList["TireFrontRight"].vehicles["fueltruck_"] = {x=208,y=182,x2=215,y2=238};
    ISCarMechanicsOverlay.PartList["TireRearLeft"].vehicles["fueltruck_"] = {x=78,y=366,x2=85,y2=422};
    ISCarMechanicsOverlay.PartList["TireRearRight"].vehicles["fueltruck_"] = {x=208,y=366,x2=215,y2=422};
    ISCarMechanicsOverlay.PartList["WindowFrontLeft"].vehicles["fueltruck_"] = {x=92,y=256,x2=101,y2=298};
    ISCarMechanicsOverlay.PartList["WindowFrontRight"].vehicles["fueltruck_"] = {x=190,y=256,x2=199,y2=298};
    ISCarMechanicsOverlay.PartList["Windshield"].vehicles["fueltruck_"] = {x=99,y=226,x2=187,y2=245};
    ISCarMechanicsOverlay.PartList["TruckBed"].vehicles["fueltruck_"] = {x=173,y=308,x2=206,y2=351};  --- Changed coordinates here
	---------------------------------- Custom Liquid / Gas Storage tank ----------------------------------
    ISCarMechanicsOverlay.PartList["FuelStorageTankRS"] = {img="liquidtank", vehicles = {}};
    ISCarMechanicsOverlay.PartList["FuelStorageTankRS"].vehicles = ISCarMechanicsOverlay.PartList["FuelStorageTankRS"].vehicles or {};
    ISCarMechanicsOverlay.PartList["FuelStorageTankRS"].vehicles["fueltruck_"] = {x=95,y=303,x2=197,y2=467};
	----------------- Compatibility with other liquid tank parts I know (Water Tanks) ----------------
    ISCarMechanicsOverlay.PartList["1500WaterTruckTank"] = ISCarMechanicsOverlay.PartList["FuelStorageTankRS"]
	ISCarMechanicsOverlay.PartList["3000WaterTruckTank"] = ISCarMechanicsOverlay.PartList["FuelStorageTankRS"]
	ISCarMechanicsOverlay.PartList["10000WaterTruckTank"] = ISCarMechanicsOverlay.PartList["FuelStorageTankRS"]
	ISCarMechanicsOverlay.PartList["3000WaterTruckTankTainted"] = ISCarMechanicsOverlay.PartList["FuelStorageTankRS"]
	
	----------------- Assign mechanics UI image to cars ----------------
	ISCarMechanicsOverlay.CarList["Base.f700water"] = {imgPrefix = "fueltruck_", x=10,y=0};
	ISCarMechanicsOverlay.CarList["Base.f700vacuum"] = {imgPrefix = "fueltruck_", x=10,y=0};
	ISCarMechanicsOverlay.CarList["Base.m50water"] = {imgPrefix = "fueltruck_", x=10,y=0};

end
Events.OnInitWorld.Add(info);
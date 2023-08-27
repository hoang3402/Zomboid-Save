--***********************************************************
--**                          KI5                          **
--***********************************************************

local distributionTable = VehicleDistributions[1]

VehicleDistributions.mccoy = {
	
	TruckBed = VehicleDistributions.McCoyTruckBed;
}

VehicleDistributions.fosoil = {
	
	TruckBed = VehicleDistributions.FossoilTruckBed;
}

VehicleDistributions.other = {
	
	TruckBed = VehicleDistributions.TrunkHeavy;
	TruckBed2 = VehicleDistributions.TrunkHeavy;
}

distributionTable["isoContainer2"] = { Normal = VehicleDistributions.mccoy; }
distributionTable["isoContainer3tanker"] = { Normal = VehicleDistributions.fosoil; }
distributionTable["isoContainer4"] = { Normal = VehicleDistributions.other; }
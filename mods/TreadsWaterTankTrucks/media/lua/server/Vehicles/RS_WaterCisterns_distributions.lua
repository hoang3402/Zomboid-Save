

require "Vehicles/VehicleDistributions"
require "CommonTemplates/CommonDistributions"

local distributionTable = VehicleDistributions[1]

VehicleDistributions.SideBox_RS = {
	TruckBed = VehicleDistributions.TrunkHeavy;
	
	TruckBedOpen = VehicleDistributions.TrunkHeavy;
	
	GloveBox = VehicleDistributions.GloveBox;
	
	SeatRearLeft = VehicleDistributions.Seat;
	SeatRearRight = VehicleDistributions.Seat;
}


-- Side boxes like construction or fuel trucks
distributionTable["f700water"] = { Normal = VehicleDistributions.SideBox_RS; }
distributionTable["f700vacuum"] = { Normal = VehicleDistributions.SideBox_RS; }
distributionTable["AutotsarKbacRSWater"] = { Normal = VehicleDistributions.SideBox_RS; }
distributionTable["m50water"] = { Normal = VehicleDistributions.SideBox_RS; }



if VehicleZoneDistribution then -- check if the table exists for backwards compatibility
-- Parking Stall, common parking stall with random cars, the most used one (shop parking lots, houses etc.)
VehicleZoneDistribution.parkingstall.vehicles["Base.f700water"] = {index = -1, spawnChance = 1};
VehicleZoneDistribution.parkingstall.vehicles["Base.f700vacuum"] = {index = -1, spawnChance = 1};
VehicleZoneDistribution.parkingstall.vehicles["Base.TrailerKbacRSWater"] = {index = -1, spawnChance = 1};

-- Trailer Parks, have a chance to spawn burnt cars, some on top of each others, it's like a pile of junk cars
VehicleZoneDistribution.trailerpark.vehicles["Base.f700water"] = {index = -1, spawnChance = 2};
VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerKbacRSWater"] = {index = -1, spawnChance = 1};
VehicleZoneDistribution.trailerpark.vehicles["Base.f700vacuum"] = {index = -1, spawnChance = 1};
VehicleZoneDistribution.trailerpark.vehicles["Base.m50water"] = {index = -1, spawnChance = 1};

-- bad vehicles, moslty used in poor area, sometimes around pub etc.
VehicleZoneDistribution.bad.vehicles["Base.f700water"] = {index = -1, spawnChance = 1};
VehicleZoneDistribution.bad.vehicles["Base.TrailerKbacRSWater"] = {index = -1, spawnChance = 1};
VehicleZoneDistribution.bad.vehicles["Base.f700vacuum"] = {index = -1, spawnChance = 1};

-- medium vehicles, used in some of the good looking area, or in suburbs

-- good vehicles, used in good looking area, they're meant to spawn only good cars, so they're on every good looking house.

-- sports vehicles, sometimes on good looking area.

-- junkyard, spawn damaged & burnt vehicles, less chance of finding keys but more cars.
-- also used for the random car crash.
VehicleZoneDistribution.junkyard.vehicles["Base.f700water"] = {index = -1, spawnChance = 2};
VehicleZoneDistribution.junkyard.vehicles["Base.TrailerKbacRSWater"] = {index = -1, spawnChance = 1};
VehicleZoneDistribution.junkyard.vehicles["Base.f700vacuum"] = {index = -1, spawnChance = 2};
VehicleZoneDistribution.junkyard.vehicles["Base.m50water"] = {index = -1, spawnChance = 1};
-- traffic jam, mostly burnt car & damaged ones.
-- Used either for hard coded big traffic jam or smaller random ones.
VehicleZoneDistribution.trafficjamw.vehicles["Base.f700water"] = {index = -1, spawnChance = 2};
VehicleZoneDistribution.trafficjamw.vehicles["Base.f700vacuum"] = {index = -1, spawnChance = 1};
VehicleZoneDistribution.trafficjamw.vehicles["Base.m50water"] = {index = -1, spawnChance = 1}
VehicleZoneDistribution.trafficjamn.vehicles["Base.f700water"] = {index = -1, spawnChance = 2};
VehicleZoneDistribution.trafficjamn.vehicles["Base.f700vacuum"] = {index = -1, spawnChance = 1};
VehicleZoneDistribution.trafficjamn.vehicles["Base.m50water"] = {index = -1, spawnChance = 1}
VehicleZoneDistribution.trafficjame.vehicles["Base.f700water"] = {index = -1, spawnChance = 2};
VehicleZoneDistribution.trafficjame.vehicles["Base.f700vacuum"] = {index = -1, spawnChance = 1};
VehicleZoneDistribution.trafficjame.vehicles["Base.m50water"] = {index = -1, spawnChance = 1}
VehicleZoneDistribution.trafficjams.vehicles["Base.f700water"] = {index = -1, spawnChance = 2};
VehicleZoneDistribution.trafficjams.vehicles["Base.f700vacuum"] = {index = -1, spawnChance = 1}
VehicleZoneDistribution.trafficjams.vehicles["Base.m50water"] = {index = -1, spawnChance = 1}

-- ****************************** --
--          SPECIAL VEHICLES      --
-- ****************************** --

-- police

-- fire
VehicleZoneDistribution.fire.vehicles["Base.f700water"] = {index = -1, spawnChance = 6};
-- ranger
VehicleZoneDistribution.ranger.vehicles["Base.f700vacuum"] = {index = -1, spawnChance = 5};
-- mccoy
VehicleZoneDistribution.mccoy.vehicles["Base.f700water"] = {index = -1, spawnChance = 2};
VehicleZoneDistribution.mccoy.vehicles["Base.f700vacuum"] = {index = -1, spawnChance = 5};

-- Fossoil

-- scarlet dist
VehicleZoneDistribution.scarlet = VehicleZoneDistribution.scarlet or {};
VehicleZoneDistribution.scarlet.vehicles = VehicleZoneDistribution.scarlet.vehicles or {};
VehicleZoneDistribution.scarlet.vehicles["Base.f700water"] = {index = 6, spawnChance = 25};

-- ambulance

-- military
VehicleZoneDistribution.military = VehicleZoneDistribution.military or {}
VehicleZoneDistribution.military.vehicles = VehicleZoneDistribution.military.vehicles or {}
VehicleZoneDistribution.military.vehicles["Base.m50water"] = {index = -1, spawnChance = 8};

VehicleZoneDistribution.military.baseVehicleQuality = 1;
VehicleZoneDistribution.military.chanceToSpawnSpecial = 0;
VehicleZoneDistribution.military.spawnRate = 25;

-- farm
VehicleZoneDistribution.farm = VehicleZoneDistribution.farm or {}
VehicleZoneDistribution.farm.vehicles = VehicleZoneDistribution.farm.vehicles or {}
VehicleZoneDistribution.farm.vehicles["Base.f700water"] = {index = -1, spawnChance = 2};
VehicleZoneDistribution.farm.vehicles["Base.TrailerKbacRSWater"] = {index = -1, spawnChance = 2};
VehicleZoneDistribution.farm.vehicles["Base.f700vacuum"] = {index = -1, spawnChance = 1};
VehicleZoneDistribution.farm.vehicles["Base.m50water"] = {index = -1, spawnChance = 1};

VehicleZoneDistribution.farm.baseVehicleQuality = 0.8;
VehicleZoneDistribution.farm.chanceToPartDamage = 20;
VehicleZoneDistribution.farm.chanceToSpawnSpecial = 0;
VehicleZoneDistribution.farm.spawnRate = 25;

end
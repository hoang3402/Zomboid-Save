

if VehicleZoneDistribution then -- check if the table exists for backwards compatibility
-- Parking Stall, common parking stall with random cars, the most used one (shop parking lots, houses etc.)

-- Trailer Parks, have a chance to spawn burnt cars, some on top of each others, it's like a pile of junk cars
VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerM967Water"] = {index = -1, spawnChance = 1};

-- bad vehicles, moslty used in poor area, sometimes around pub etc.

-- medium vehicles, used in some of the good looking area, or in suburbs

-- good vehicles, used in good looking area, they're meant to spawn only good cars, so they're on every good looking house.

-- sports vehicles, sometimes on good looking area.

-- junkyard, spawn damaged & burnt vehicles, less chance of finding keys but more cars.
-- also used for the random car crash.
VehicleZoneDistribution.junkyard.vehicles["Base.TrailerM967Water"] = {index = -1, spawnChance = 1};
-- traffic jam, mostly burnt car & damaged ones.
-- Used either for hard coded big traffic jam or smaller random ones.
VehicleZoneDistribution.trafficjamw.vehicles["Base.TrailerM967Water"] = {index = -1, spawnChance = 1};

-- ****************************** --
--          SPECIAL VEHICLES      --
-- ****************************** --

-- police

-- fire
VehicleZoneDistribution.fire.vehicles["Base.TrailerM967Water"] = {index = -1, spawnChance = 1};
-- ranger

-- mccoy


-- Fossoil

-- scarlet dist

-- ambulance

-- military
VehicleZoneDistribution.military = VehicleZoneDistribution.military or {}
VehicleZoneDistribution.military.vehicles = VehicleZoneDistribution.military.vehicles or {}
VehicleZoneDistribution.military.vehicles["Base.TrailerM967Water"] = {index = -1, spawnChance = 15};

-- farm
VehicleZoneDistribution.farm = VehicleZoneDistribution.farm or {}
VehicleZoneDistribution.farm.vehicles = VehicleZoneDistribution.farm.vehicles or {}
VehicleZoneDistribution.farm.vehicles["Base.TrailerM967Water"] = {index = -1, spawnChance = 15};

end
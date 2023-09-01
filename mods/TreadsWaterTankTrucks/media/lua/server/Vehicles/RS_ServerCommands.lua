---------------------Code by Tread ----- (Trealak on Steam) ---------------------------------
-- inspired by FuelAPI, Water Dispenser and Coco Liquid Overhaul by Konijima, Fuel Trailers and Trucks by Filibuster Rhymes and TMC (Tsar's Modding Company) ----------

--if isClient() then return end

local RSServerCommands = {}
local Commands = {}

function Commands.RS_TaintPartModDataServer(player, args)
	local vehicle = getVehicleById(args.vehicle)
	local part = vehicle:getPartById(args.part)
	part:getModData().tainted = 1
    vehicle:transmitPartModData(part)
end

function Commands.RS_UntaintPartModDataServer(player, args)
	local vehicle = getVehicleById(args.vehicle)
	local part = vehicle:getPartById(args.part)
	part:getModData().tainted = 0
    vehicle:transmitPartModData(part)
end

function Commands.RS_FilterFractionDamage(player, args)
	local vehicle = getVehicleById(args.vehicle)
	local part = vehicle:getPartById(args.part)
	part:getInventoryItem():getModData().filterDmgFraction = args.value
    vehicle:transmitPartModData(part)
	part:getVehicle():transmitPartItem(part);
end


RSServerCommands.OnClientCommand = function(module, command, playerObj, args)
	if module == 'RS_Server' and Commands[command] then
		local argStr = ''
		args = args or {}
		for k,v in pairs(args) do
			argStr = argStr..' '..k..'='..tostring(v)
		end
--		noise('received '..module..' '..command..' '..tostring(playerObj)..argStr)
		Commands[command](playerObj, args)
	end
end

Events.OnClientCommand.Add(RSServerCommands.OnClientCommand)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
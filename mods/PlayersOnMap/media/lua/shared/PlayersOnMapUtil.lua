PlayersOnMap = {}
PlayersOnMap.MOD_ID = "PlayersOnMap"
PlayersOnMap.ServerConfigFileName = 'Server Config.lua'
PlayersOnMap.DefaultServerConfig = {
	["AllowWorldMap"] = true,
	["WorldAllowNames"] = true,
	["WorldAllowHeight"] = true,
	["WorldMaximumDistance"] = -1,

	["AllowMiniMap"] = true,
	["MiniAllowNames"] = true,
	["MiniAllowHeight"] = true,
	["MiniMaximumDistance"] = -1,

	["OnlyShowFaction"] = false,
	['AdminsSeeAll'] = true,
}

PlayersOnMap.ClientConfigFileName = 'Client Config.lua'
PlayersOnMap.DefaultClientConfig = {
	["ShowWorldMap"] = true,
	["WorldShowNames"] = true,
	["WorldShowHeight"] = true,
	["WorldDotColor"] = {r = 0.5, g = 1, b = 0, a = 1},

	["ShowMiniMap"] = true,
	["MiniShowNames"] = true,
	["MiniShowHeight"] = true,
	["MiniDotColor"] = {r = 0.5, g = 1, b = 0, a = 1},
}


local escape_key = function(str)
	return str:gsub('"', '\\"')
end

local table_to_string;
table_to_string = function(tbl, indent)
	indent = indent or ''
	local str = ''

	for k, v in pairs(tbl) do
		str = str .. indent

		if type(k) == 'string' then
			str = str .. '["'.. escape_key(k) ..'"] = '
		else
			str = str .. '['.. tostring(k) ..'] = '
		end

		if type(v) == 'table' then
			str = str .. '{\n' .. table_to_string(v, indent .. '\t') .. indent .. '}' 
		else
			if type(v) == 'string' then
				str = str .. '"' .. escape_key(v) .. '"'
			else
				str = str .. tostring(v)
			end
		end

		str = str .. ',\n'
	end

	return str
end

local update_table;
update_table = function(tbl1, tbl2, updated, remove)
	updated = updated or false
	remove = remove or false
	local temp = tbl2

	if not remove then
		for k, v in pairs(tbl1) do
			if temp[k] == nil then
				updated = true
				temp[k] = v
			elseif type(v) == 'table' then
				temp[k], updated = update_table(v, temp[k], updated, remove)
			end
		end
	end

	for k, v in pairs(tbl2) do
		if tbl1[k] == nil then
			updated = true
			temp[k] = nil
		elseif type(v) == 'table' then
			temp[k], updated = update_table(v, temp[k], updated, true)
		end
	end

	return temp, updated
end

PlayersOnMap.io = {
	write = function(path, tbl)
		local file = getModFileWriter(PlayersOnMap.MOD_ID, path, true, false)
		file:write('return {\n' .. table_to_string(tbl, '\t') .. '}')
		file:close()
	end,

	load = function(path)
		local file = getModFileReader(PlayersOnMap.MOD_ID, path, true)
		local scanline = file:readLine()
		local content = scanline and '' or 'return {}'

		while scanline do
			content = content .. scanline .. '\n'
			scanline = file:readLine()
		end

		file:close()
		return loadstring(content)()
	end
}

if isServer() or not isClient() then
	local updated;
	PlayersOnMap.ServerConfig, updated = update_table(
		PlayersOnMap.DefaultServerConfig,
		PlayersOnMap.io.load(PlayersOnMap.ServerConfigFileName)
	)

	if updated then
		PlayersOnMap.io.write(PlayersOnMap.ServerConfigFileName, PlayersOnMap.ServerConfig)
	end

	updated = nil;
end

PlayersOnMap.ServerConfig = PlayersOnMap.ServerConfig or PlayersOnMap.DefaultServerConfig


if not isServer() or isClient() then
	local updated;
	PlayersOnMap.ClientConfig, updated = update_table(
		PlayersOnMap.DefaultClientConfig,
		PlayersOnMap.io.load(PlayersOnMap.ClientConfigFileName)
	)

	if updated then
		PlayersOnMap.io.write(PlayersOnMap.ClientConfigFileName, PlayersOnMap.ClientConfig)
	end

	PlayersOnMap.ClientConfig = PlayersOnMap.ClientConfig or PlayersOnMap.DefaultClientConfig

	updated = nil;
end


update_table = nil
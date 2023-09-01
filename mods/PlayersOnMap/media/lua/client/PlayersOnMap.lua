require 'ISUI/Maps/ISWorldMap'
require 'ISUI/Maps/ISMiniMap'

local getPlayerFromUsername = getPlayerFromUsername
local getAllPlayers 		= getOnlinePlayers
local getPlayer				= getPlayer
local isAdmin				= isAdmin

if getAllPlayers() == nil then
	local getSpecificPlayer 	= getSpecificPlayer
	local players 				= {
		size = getNumActivePlayers;
		get = function(_, index)
			return getSpecificPlayer(index)
		end
	}

	getAllPlayers = function()
		return players
	end
end

local server_config	= PlayersOnMap.DefaultServerConfig
local client_config	= PlayersOnMap.DefaultClientConfig
local dot_size 		= 3
local updates 		= 0

local function onPlayerUpdate(player)
	updates = updates + 1

	if updates >= 10 then
		sendClientCommand(player, PlayersOnMap.MOD_ID, 'InitLoad', {})
		print('PlayersOnMap - Requested initial config from server.')
		updates = 0
	end
end

local function onServerCommand(module, command, args)
	if module ~= PlayersOnMap.MOD_ID then
		return
	end

	print( ('PlayersOnMap - Received command from server: "%s"'):format(command) )

	if command == 'InitLoad' then
		client_config = PlayersOnMap.io.load(PlayersOnMap.ClientConfigFileName)
		server_config = args.config

		PlayersOnMap.ClientConfig = client_config
		PlayersOnMap.ServerConfig = server_config--You update "ServerConfig" here so it shows the correct options in admin settings;

		Events.OnPlayerUpdate.Remove(onPlayerUpdate)
		updates, onPlayerUpdate = nil, nil
	end

	if command == 'SetServerConfig' then
		print( ('PlayersOnMap - Updating "%s" to "%s"'):format(args.option, tostring(args.config[args.option])) )

		server_config = args.config
		PlayersOnMap.ServerConfig = server_config
	end
end

if isClient() then
	Events.OnServerCommand.Add(onServerCommand)-- Client receiving message from server
	Events.OnPlayerUpdate.Add(onPlayerUpdate)
else
	client_config = PlayersOnMap.ClientConfig
	server_config = PlayersOnMap.ServerConfig
end

local function getPos(player)
	local vehicle = player:getVehicle()

	if vehicle then
		return vehicle:getX(), vehicle:getY(), player:getZ()
	else
		return player:getX(), player:getY(), player:getZ()
	end
end

local function getMapPos(a, x, y)
	return a.mapAPI:worldToUIX(x, y), a.mapAPI:worldToUIY(x, y)
end

local TextManager = getTextManager()
local function getTextSize(font, text)
	return TextManager:MeasureStringX(font, text)
end

local function getDistance(a, b)
	local x = (b[1] - a[1]) * (b[1] - a[1])
	local y = (b[2] - a[2]) * (b[2] - a[2])
	local z = (b[3] - a[3]) * (b[3] - a[3])

	return math.sqrt(x + y + z)
end


local function drawWorldMapPlayerDot(self, player, myX, myY, myZ)
	if player:isInvisible() then
		return
	end

	local x, y, z = getPos(player)
	if server_config.WorldMaximumDistance > 0 then
		local dist = getDistance({x, y, z}, {myX, myY, myZ})
		if dist > server_config.WorldMaximumDistance then
			return
		end
	end

	local X, Y = getMapPos(self, x, y)
	self:drawRect(X - dot_size, Y - dot_size, dot_size * 2 - 1, dot_size * 2 - 1, client_config.WorldDotColor.a, client_config.WorldDotColor.r, client_config.WorldDotColor.g, client_config.WorldDotColor.b)
	self:drawRectBorder(X - dot_size, Y - dot_size, dot_size * 2, dot_size * 2, 1, 0, 0, 0)

	if server_config.WorldAllowNames and client_config.WorldShowNames then
		local name = player:getUsername()
		local name_sizeX = getTextSize(UIFont.Small, name)

		self:drawRect(X + dot_size + 4, Y - 7, name_sizeX+1, 14, 0.5, 0, 0, 0)
		self:drawText(name, X + dot_size + 5, Y - dot_size * 2 - 1, 1, 1, 1, 1, UIFont.Small)
	end

	if server_config.WorldAllowHeight and client_config.WorldShowheight then
		local delta = myZ - z

		if delta < 0 then
			for i=-1, delta, -1 do
				self:drawText('_', X-3, Y - 10 - dot_size*2 - -1*i*2, 0, 0, 0, 1, UIFont.Small)
			end
		elseif delta > 0 then
			for i=1, delta, 1 do
				self:drawText('_', X-3, Y - 9 + i*2, 0, 0, 0, 1, UIFont.Small)
			end
		end
	end
end

local function drawWorldMapPlayerDotForAdmins(self, player, myZ)
	local x, y, z = getPos(player)
	local X, Y = getMapPos(self, x, y)

	self:drawRect(X - dot_size, Y - dot_size, dot_size * 2 - 1, dot_size * 2 - 1, client_config.WorldDotColor.a, client_config.WorldDotColor.r, client_config.WorldDotColor.g, client_config.WorldDotColor.b)
	self:drawRectBorder(X - dot_size, Y - dot_size, dot_size * 2, dot_size * 2, 1, 0, 0, 0)

	if client_config.WorldShowNames then
		local name = player:getUsername()
		local name_sizeX = getTextSize(UIFont.Small, name)

		self:drawRect(X + dot_size + 4, Y - 7, name_sizeX+1, 14, 0.5, 0, 0, 0)
		self:drawText(name, X + dot_size + 5, Y - dot_size * 2 - 1, 1, 1, 1, 1, UIFont.Small)
	end

	if client_config.WorldShowHeight then
		local delta = myZ - z

		if delta < 0 then
			for i=-1, delta, -1 do
				self:drawText('_', X-3, Y - 10 - dot_size*2 - -1*i*2, 0, 0, 0, 1, UIFont.Small)
			end
		elseif delta > 0 then
			for i=1, delta, 1 do
				self:drawText('_', X-3, Y - 9 + i*2, 0, 0, 0, 1, UIFont.Small)
			end
		end
	end
end


local function drawMiniMapPlayerDot(self, player, myX, myY, myZ)
	if player:isInvisible() then
		return
	end

	local x, y, z = getPos(player)
	if server_config.MiniMaximumDistance > 0 then
		local dist = getDistance({x, y, z}, {myX, myY, myZ})
		if dist > server_config.MiniMaximumDistance then
			return
		end
	end

	if not self.inner then
		return
	end

	local X, Y = getMapPos(self.inner, x, y)
	self:drawRect(X-1, Y-1, dot_size * 2 - 1, dot_size * 2 - 1, client_config.MiniDotColor.a, client_config.MiniDotColor.r, client_config.MiniDotColor.g, client_config.MiniDotColor.b)
	self:drawRectBorder(X-1, Y-1, dot_size * 2, dot_size * 2, 1, 0, 0, 0)

	if server_config.MiniAllowNames and client_config.MiniShowNames then
		local name = player:getUsername()
		local name_sizeX = getTextSize(UIFont.Small, name)

		self:drawRect(X + dot_size + 4, Y - 5, name_sizeX+1, 14, 0.5, 0, 0, 0)
		self:drawText(name, X + dot_size + 5, 1 + Y - dot_size * 2, 1, 1, 1, 1, UIFont.Small)
	end

	if server_config.MiniAllowHeight and client_config.MiniShowHeight then
		local delta = myZ - z

		if delta < 0 then
			for i=-1, delta, -1 do
				self:drawText('_', X-1, Y - 9 - dot_size*2 - -1*i*2, 0, 0, 0, 1, UIFont.Small)
			end
		elseif delta > 0 then
			for i=1, delta do
				self:drawText('_', X-1, Y - 7 + i*2, 0, 0, 0, 1, UIFont.Small)
			end
		end
	end
end

local function drawMiniMapPlayerDotForAdmins(self, player, myZ)
	local x, y, z = getPos(player)

	if not self.inner then
		return
	end

	local X, Y = getMapPos(self.inner, x, y)
	self:drawRect(X-1, Y-1, dot_size * 2 - 1, dot_size * 2 - 1, client_config.MiniDotColor.a, client_config.MiniDotColor.r, client_config.MiniDotColor.g, client_config.MiniDotColor.b)
	self:drawRectBorder(X-1, Y-1, dot_size * 2, dot_size * 2, 1, 0, 0, 0)

	if client_config.MiniShowNames then
		local name = player:getUsername()
		local name_sizeX = getTextSize(UIFont.Small, name)

		self:drawRect(X + dot_size + 4, Y - 5, name_sizeX+1, 14, 0.5, 0, 0, 0)
		self:drawText(name, X + dot_size + 5, 1 + Y - dot_size * 2, 1, 1, 1, 1, UIFont.Small)
	end

	if client_config.MiniShowHeight then
		local delta = myZ - z

		if delta < 0 then
			for i=-1, delta, -1 do
				self:drawText('_', X-1, Y - 9 - dot_size*2 - -1*i*2, 0, 0, 0, 1, UIFont.Small)
			end
		elseif delta > 0 then
			for i=1, delta do
				self:drawText('_', X-1, Y - 7 + i*2, 0, 0, 0, 1, UIFont.Small)
			end
		end
	end
end

local function getFactionMembers(user)
	local factions = Faction.getFactions()
	local username = user:getUsername()
	local members = {}

	for i=1, factions:size() do
		local faction = factions:get(i - 1);

		if faction:isOwner(username) or faction:isMember(username) then
			local ownerPlayer = getPlayerFromUsername(faction:getOwner())

			if ownerPlayer then
				members[#members + 1] = ownerPlayer
			end

			local players = faction:getPlayers()
			for j=1, players:size() do
				local player = players:get(j - 1)
				local memberPlayer = getPlayerFromUsername(player)

				if memberPlayer then
					members[#members + 1] = memberPlayer
				end
			end

			break
		end
	end

	return members
end

local oldWorldMapRender = ISWorldMap.render
ISWorldMap.render = function(self)
	oldWorldMapRender(self)

	if not client_config.ShowWorldMap then
		return
	end

	if server_config.AdminsSeeAll and isAdmin() then
		local character = getPlayer()
		local _, _, myZ = getPos(character)
		local players 	= getAllPlayers()

		for i=1, players:size() do
			local player = players:get(i - 1)
			drawWorldMapPlayerDotForAdmins(self, player, myZ)
		end
	else
		if server_config.AllowWorldMap then
			local character = getPlayer()
			local myX, myY, myZ = getPos(character)
	
			if server_config.OnlyShowFaction then
				for _, player in ipairs(getFactionMembers(character)) do
					drawWorldMapPlayerDot(self, player, myX, myY, myZ)
				end
			else
				local players = getAllPlayers()

				for i=1, players:size() do
					local player = players:get(i - 1)
					drawWorldMapPlayerDot(self, player, myX, myY, myZ)
				end
			end
		end
	end
end

local oldMiniMapOuterRender = ISMiniMapOuter.render
ISMiniMapOuter.render = function(self)
	oldMiniMapOuterRender(self)

	if not client_config.ShowMiniMap then
		return
	end

	if server_config.AdminsSeeAll and isAdmin() then
		self:setStencilRect(0, 0, self:getWidth(), self:getHeight() - 15)
		local character = getPlayer()
		local _, _, myZ = getPos(character)
		local players 	= getAllPlayers()

		for i=1, players:size() do
			local player = players:get(i - 1)
			drawMiniMapPlayerDotForAdmins(self, player, myZ)
		end

		self:clearStencilRect()
	else
		if server_config.AllowMiniMap then
			self:setStencilRect(0, 0, self:getWidth(), self:getHeight() - 15)

			local character = getPlayer()
			local myX, myY, myZ = getPos(character)

			if server_config.OnlyShowFaction then
				for _, player in ipairs(getFactionMembers(character)) do
					drawMiniMapPlayerDot(self, player, myX, myY, myZ)
				end
			else
				local players = getAllPlayers()

				for i=1, players:size() do
					local player = players:get(i - 1)
					drawMiniMapPlayerDot(self, player, myX, myY, myZ)
				end
			end

			self:clearStencilRect()
		end
	end
end
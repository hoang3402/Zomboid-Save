local server_config = {};

local function onServerStart()
    server_config = PlayersOnMap.io.load(PlayersOnMap.ServerConfigFileName)

    for k, v in pairs(server_config) do
        print( ('PlayersOnMap Loaded: %s = %s'):format(k, tostring(v)) )
    end
end

local function onClientCommand(module, command, player, args)
    if module ~= PlayersOnMap.MOD_ID then
        return
    end

    print( ('PlayersOnMap - Received command "%s" from client "%s"'):format(command, player:getUsername()) )

    if command == 'InitLoad' then
        sendServerCommand(player, module, 'InitLoad', {config = server_config})
        print( ('PlayersOnMap - Sending server config to client --> "%s"\n'):format(player:getUsername()) )

    elseif command == 'SaveServerConfig' then
        PlayersOnMap.io.write(PlayersOnMap.ServerConfigFileName, args.config)
        sendServerCommand(module, 'SetServerConfig', args)
        server_config = args.config

        print( ('PlayersOnMap - Sending new "%s" value "%s" to players.\n'):format(args.option, tostring(args.config[args.option])) )
    end
end

if isServer() then
    Events.OnServerStarted.Add(onServerStart)
    Events.OnClientCommand.Add(onClientCommand) --// a client sends to server
end
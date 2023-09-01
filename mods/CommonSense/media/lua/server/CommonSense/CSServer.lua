CSServer = {}

CSServer.PryDoorOpen = function(worldObjects, priableObject, playerObj)

    if instanceof(priableObject, "IsoDoor") then

        priableObject:setLockedByKey(false)

        local doubleDoorObjects = buildUtil.getDoubleDoorObjects(priableObject)

        for i=1,#doubleDoorObjects do
            local object = doubleDoorObjects[i]
            object:setLockedByKey(false)
        end

        local garageDoorObjects = buildUtil.getGarageDoorObjects(priableObject)

        for i=1,#garageDoorObjects do
            local object = garageDoorObjects[i]
            object:setLockedByKey(false)
            playerObj:getXp():AddXP(Perks.Strength, 50)
        end

        ISTimedActionQueue.add(ISOpenCloseDoor:new(playerObj, priableObject, 0))
        BravensUtilsO1.TryPlaySoundClip(playerObj, "BreakBarricadePlank")
        playerObj:getXp():AddXP(Perks.Strength, 70)

    elseif instanceof(priableObject, "IsoWindow") then

        --Chance to smash window (FAIL)!
        if ZombRand(10) > 2 then
            priableObject:setIsLocked(false) -- Code snippet thanks to "Buffy"!
            ISWorldObjectContextMenu.onOpenCloseWindow(worldObjects, priableObject, playerObj:getPlayerNum())
            playerObj:getXp():AddXP(Perks.Strength, 40)
        else
            priableObject:setSmashed(true)
            BravensUtilsO1.TryPlaySoundClip(playerObj, "SmashWindow")
            playerObj:getXp():AddXP(Perks.Strength, 25)
        end
    end
end
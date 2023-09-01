-- Local Globals

local player = nil
local halzombie = nil
local LoadedEvents = false
local inBuilding = false
local AlreadyEnteredBuildings = {}
local oldhalzombiepos = {["X"] = nil, ["Y"] = nil, ["Z"] = nil}
local isClumsy = false

-- Local reference tables

local insideSounds = {
    [1] = "heli_hover_loop_distant",
    [2] = "fakethump",
    [3] = "fakethumpsqueak",
    [4] = "gunshots_GAU5A_02",
    [5] = "door_break",
    [6] = "gunshots_M16_02",
    [7] = "metalpipefalling",
    [8] = "window_smash",
}
local outsideSounds = {
    [1] = "heli_hover_loop_close",
    [2] = "gunshots_FAL_02",
    [3] = "gunshots_M16A2_02",
    [4] = "metalpipefalling",
    [5] = "gunshots_M16_02",
    [6] = "gunshots_GAU5A_02",
}
local directionalCatalog = {
    [1] = {Direction = ""},
    [2] = {Direction = "_left"},
    [3] = {Direction = "_right"},
}
local HalZombieSpawnCatalog = {
    [1] = {X = -1, Y = -1},
    [2] = {X = 0, Y = -1},
    [3] = {X = 1, Y = -1},
    [4] = {X = 1, Y = 0},
    [5] = {X = 1, Y = 1},
    [6] = {X = 0, Y = 1},
    [7] = {X = -1, Y = 1},
    [8] = {X = -1, Y = 0},
}
-- Start

function figureOutPlayer()
    if player == nil or player:isLocalPlayer() == false then
        player = getPlayer()
        isClumsy = false
        playerdata = player:getModData()
        if playerdata.ChlorpromazineHours == nil then playerdata.ChlorpromazineHours = 0 end
        if LoadedEvents == false and player:HasTrait("schizophrenia") then AddSchizEvents() end
    end
end

-- local functions

local function checkChlorpromazineHours()
    playerdata = player:getModData()
    if playerdata.ChlorpromazineHours == 0 then return false, 0
    else return true, playerdata.ChlorpromazineHours end
end

local function applyPanic(panicAmo,stressAmo,playBreathing,forceAwake,Request)
    if Request:isLocalPlayer() and Request:getPlayerNum() == 0 then
        local panic = player:getStats():getPanic() + panicAmo
        local stress = player:getStats():getStress() + stressAmo
        player:getStats():setPanic(panic)
        player:getStats():setStress(stress)
        if playBreathing == true then
            if player:isFemale() then getSoundManager():PlaySound("female_heavybreathpanic", false, 5):setVolume(0.035)
            else getSoundManager():PlaySound("male_heavybreathpanic", false, 5):setVolume(0.035) end
        end
        if forceAwake == true then player:forceAwake() end
    end
end

local function applyDepression(depressionAmo,sanityAmo,playLowSanity,Request)
    if Request:isLocalPlayer() and Request:getPlayerNum() == 0 then
        local depression = player:getBodyDamage():getUnhappynessLevel() + depressionAmo
        local sanity = player:getStats():getSanity() + sanityAmo
        player:getBodyDamage():setUnhappynessLevel(depression)
        player:getStats():setSanity(sanity)
        if playLowSanity == true then
            local randNum = ZombRand(4)+1
            getSoundManager():PlaySound("insane"..randNum, false, 0):setVolume(0.25)
        end
    end
end

local function ApplyTripEffects()
    if player ~= nil and player:isLocalPlayer() and player:getPlayerNum() == 0 then
        if player:isRunning() or player:isSprinting() then
            local Rand = ZombRand(2)+1
            local TripType = "None"

            if Rand == 1 then
                TripType = "left"
            elseif Rand == 2 then
                TripType = "right"
            end
            player:clearVariable("BumpFallType")
            player:setBumpFallType("FallForward")
            player:setBumpType(TripType)
            player:setBumpDone(false)
            player:setBumpFall(true)
            player:reportEvent("wasBumped")
            Events.OnTick.Remove(ApplyTripEffects)
            isClumsy = false
        end
    end
end

local function ApplyForceTrip(ForwardOrBack)
    if player ~= nil and player:isLocalPlayer() and player:getPlayerNum() == 0 then
        if not player:isAsleep() and not player:isSitOnGround() and not player:isReading() then
            local Rand = ZombRand(2)+1
            local TripType = "None"

            if Rand == 1 then
                TripType = "left"
            elseif Rand == 2 then
                TripType = "right"
            end
            player:clearVariable("BumpFallType")
            if ForwardOrBack then
                player:setBumpFallType("pushedFront")
            else
                player:setBumpFallType("pushedBehind")
            end
            player:setBumpType(TripType)
            player:setBumpDone(false)
            player:setBumpFall(true)
            player:reportEvent("wasBumped")
            player:dropHandItems()
        else
            if not isClumsy then
                isClumsy = true
                Events.OnTick.Add(ApplyTripEffects)
            end
        end
    end
end

local function ApplyPillEffects(Plr,ReduceHealth,Wetness,Endurance,Thrist,Fatigue,ForceAwakeChance,ForceAsleepChance)
    if player ~= nil and Plr == player and Plr:isLocalPlayer() and Plr:getPlayerNum() == 0 then
        player:getStats():setFatigue(player:getStats():getFatigue() + Fatigue)
        player:getStats():setThirst(player:getStats():getThirst() + Thrist)
        player:getStats():setEndurance(player:getStats():getEndurance() - Endurance)
        player:getBodyDamage():setWetness(player:getBodyDamage():getWetness() + Wetness)
        player:getBodyDamage():ReduceGeneralHealth(ReduceHealth)
        if not isClient() then
            if ForceAwakeChance <= 50 then player:forceAwake() end
            if ForceAsleepChance <= 50 then player:setAsleep(true) end
        else
            if ForceAsleepChance <= 50 then
                player:getStats():setFatigue(player:getStats():getFatigue() + (Fatigue * 0.25))
                player:getStats():setThirst(player:getStats():getThirst() + (Thrist * 0.25))
                player:getStats():setEndurance(player:getStats():getEndurance() - (Endurance * 0.25))
                player:getBodyDamage():setWetness(player:getBodyDamage():getWetness() + (Wetness * 0.25))
                player:getBodyDamage():ReduceGeneralHealth((ReduceHealth * 0.15))
                local Rand = ZombRand(100)+1
                if Rand <= 15 then
                    local Rand = ZombRand(2)+1
                    if Rand == 1 then
                        ApplyForceTrip(false)
                    else
                        if not isClumsy then
                            isClumsy = true
                            Events.OnTick.Add(ApplyTripEffects)
                        end
                    end
                end
            end
        end
    end
end

local function insideSchizoAttack(Request)
    if Request:isLocalPlayer() and Request:getPlayerNum() == 0 then
        local randNum = ZombRand(8)+1
        local randNum2 = ZombRand(3)+1
        getSoundManager():PlaySound(insideSounds[randNum]..directionalCatalog[randNum2].Direction, false, 0):setVolume(0.65);
        applyPanic(50,0.25,true,false,Request)
    end
end

 local function outsideSchizoAttack(Request)
    if Request:isLocalPlayer() and Request:getPlayerNum() == 0 then
        local randNum = ZombRand(6)+1
        local randNum2 = ZombRand(3)+1
        getSoundManager():PlaySound(outsideSounds[randNum]..directionalCatalog[randNum2].Direction, false, 0):setVolume(0.65);
        applyPanic(50,0.25,true,false,Request)
    end
end

-- Checks

function FigureOutBuilding()
    if player:getBuilding() then AlreadyEnteredBuildings[player:getBuilding()] = true end
end

function CheckIfYouDied(deadPlayer)
    if deadPlayer == player and deadPlayer:isLocalPlayer() and deadPlayer:getPlayerNum() == 0 then RemoveSchizEvents() player = nil end
end

function MakeNewPlayer(_,newplayer)
    if newplayer:isLocalPlayer() and newplayer:getPlayerNum() == 0 and player == nil then figureOutPlayer()
        if LoadedEvents == true then
            FigureOutBuilding()
            print(playerdata.ChlorpromazineHours)
        end
    end
end

-- Event Related Functions

function FakeJumpScare(Type,Request)
    if Request:isLocalPlayer() and Request:getPlayerNum() == 0 then
        if Type == 2 or Type == 3 then
            local randNum = ZombRand(2)
            if randNum == 1 then
                getSoundManager():PlaySound("ZombieSurprisedPlayer", false, 0):setVolume(0.50);
            end
        end
        local randNum2 = ZombRand(3)+1
        if Type == 2 then
            if ZombRand(2) == 1 then
                local randNum = ZombRand(8)+1
                getSoundManager():PlaySound("zombie_female_attack_0"..randNum..directionalCatalog[randNum2].Direction, false, 0):setVolume(0.75);
            else
                local randNum = ZombRand(8)+1
                getSoundManager():PlaySound("zombie_male_attack_0"..randNum..directionalCatalog[randNum2].Direction, false, 0):setVolume(0.75);
            end
        end
        if Type == 1 or Type == 3 then
            local randNum = ZombRand(8)+1
            getSoundManager():PlaySound("scratch_gore_short_0"..randNum..directionalCatalog[randNum2].Direction, false, 0):setVolume(0.75);
        elseif Type == 2 then
            local randNum = ZombRand(8)+1
            if ZombRand(2)+1 == 1 then
                getSoundManager():PlaySound("scratch_gore_short_0"..randNum..directionalCatalog[randNum2].Direction, false, 0):setVolume(0.75);
            end
        end
    end
end

function makePlayerSound(player, ForceScream)
    if not player:isAsleep() then
        if not ForceScream then
            local IsOnPills, _ = checkChlorpromazineHours()
            if ZombRand(100)+1 == 5 and IsOnPills == false then
                if player:isFemale() then player:playSound("fscream"..ZombRand(3)+1); else player:playSound("scream"..ZombRand(3)+1); end
                if player:getBuilding() then addSound(getPlayer(), getPlayer():getX(), getPlayer():getY(), getPlayer():getZ(), 6, 6); 
                else addSound(getPlayer(), getPlayer():getX(), getPlayer():getY(), getPlayer():getZ(), 14, 14); end
            else
                if player:isFemale() then player:playSound("f_laugh_"..ZombRand(5)+1); else player:playSound("m_laugh_"..ZombRand(5)+1); end
                if player:getBuilding() then addSound(getPlayer(), getPlayer():getX(), getPlayer():getY(), getPlayer():getZ(), 1, 1); 
                else addSound(getPlayer(), getPlayer():getX(), getPlayer():getY(), getPlayer():getZ(), 4, 4); end
            end
        elseif ForceScream then
            if player:isFemale() then player:playSound("fscream"..ZombRand(3)+1); else player:playSound("scream"..ZombRand(3)+1); end
            if player:getBuilding() then addSound(getPlayer(), getPlayer():getX(), getPlayer():getY(), getPlayer():getZ(), 6, 6); 
            else addSound(getPlayer(), getPlayer():getX(), getPlayer():getY(), getPlayer():getZ(), 14, 14); end
        end
    end
end

function HourEvent()
    if player ~= nil then
        if halzombie ~= nil then
            halzombie:removeFromWorld()
            halzombie:removeFromSquare()
            halzombie = nil
            Events.OnTick.Remove(CanSeeCheck)
            Events.OnHitZombie.Remove(HitHalZombieCheck)
            Events.OnZombieUpdate.Remove(MakeUseless)
        end
        playerdata = player:getModData()
        local IsOnPills, ChlorHours = checkChlorpromazineHours()
        local ChlorModifier = 1
        if IsOnPills then
            playerdata.ChlorpromazineHours = ChlorHours - 1
            ChlorModifier = 0.20
        end
        local randNum = ZombRand(100)+1
        randNum = randNum - (randNum*player:getStats():getStress())*0.5
        if randNum <= (8*ChlorModifier) and player:HasTrait("schizophrenia") and player:isLocalPlayer() and player:getPlayerNum() == 0 then
            if player:getBuilding() then insideSchizoAttack(player)
            else outsideSchizoAttack(player) end
        elseif randNum > (8*ChlorModifier) and player:HasTrait("schizophrenia") and player:isLocalPlayer() and player:getPlayerNum() == 0 then
            randNum = ZombRand(100)+1
            randNum = randNum - (randNum*player:getStats():getStress())*0.5
            if randNum <= (20*ChlorModifier) then makePlayerSound(player, false) end
            randNum = ZombRand(100)+1
            if randNum <= (10*ChlorModifier) then CreateHallucination(player) end
        end
    end
end

function DayEvent()
    if player ~= nil then
        playerdata = player:getModData()
        local IsOnPills, _ = checkChlorpromazineHours()
        local ChlorModifier = 1
        if IsOnPills then ChlorModifier = 0.20 end
        local randNum = ZombRand(100)+1
        AlreadyEnteredBuildings = {}
        if inBuilding == true then AlreadyEnteredBuildings[player:getBuilding()] = true end
        randNum = randNum - (randNum*player:getStats():getStress())*0.5
        if randNum <= (12*ChlorModifier) and player:HasTrait("schizophrenia") and player:isLocalPlayer() and player:getPlayerNum() == 0 then
            applyDepression(25,0.2,true,player)
        end
    end
end

function FakeAlarm(_player)
    if player ~= nil and _player == player and _player:isLocalPlayer() and _player:getPlayerNum() == 0 then
        if inBuilding == false and player:getBuilding() then
            inBuilding = true
            if player:HasTrait("schizophrenia") then
                playerdata = player:getModData()
                local IsOnPills, _ = checkChlorpromazineHours()
                local ChlorModifier = 1
                if IsOnPills then ChlorModifier = 0.20 end
                local randNum = ZombRand(100)+1
                randNum = randNum - (randNum*player:getStats():getStress())*0.5
                if randNum <= (5*ChlorModifier) and not AlreadyEnteredBuildings[player:getBuilding()] then
                    getSoundManager():PlaySound("house_alarm_loop", false, 0):setVolume(0.35);
                    applyPanic(75,0.2,false,false,_player)
                end
                AlreadyEnteredBuildings[player:getBuilding()] = true
            end
        elseif inBuilding == true and not player:getBuilding() then inBuilding = false end
    end
end

function RollFakeJumpscare(_player)
    if player ~= nil and _player == player and _player:isLocalPlayer() and _player:getPlayerNum() == 0 then
        playerdata = player:getModData()
        local IsOnPills, _ = checkChlorpromazineHours()
        local ChlorModifier = 1
        if IsOnPills then ChlorModifier = 0.20 end
        local randNum = ZombRand(100)+1
        randNum = randNum - (randNum*player:getStats():getStress())*0.5
        if randNum <= (10*ChlorModifier) and player:HasTrait("schizophrenia") then
            FakeJumpScare(2,player)
            applyPanic(25,0.05,false,false,_player)
        end
    end
end

function RollHitFakeBite(_,plrChar)
    if player ~= nil and plrChar:getStats() == player:getStats() and player:HasTrait("schizophrenia") and plrChar:isLocalPlayer() and plrChar:getPlayerNum() == 0 then
        playerdata = player:getModData()
        local IsOnPills, _ = checkChlorpromazineHours()
        local ChlorModifier = 1
        if IsOnPills then ChlorModifier = 0.20 end
        local randNum = ZombRand(100)+1
        randNum = randNum - (randNum*player:getStats():getStress())*0.5
        if randNum <= (3*ChlorModifier) then
            FakeJumpScare(1,player)
            applyPanic(25,0.05,false,false,player)
        end
    end
end

function ApplyDeathDepression(deadPlayer)
    if player ~= nil and not deadPlayer:isLocalPlayer() then
        if player:HasTrait("schizophrenia") and player:isLocalPlayer() and player:getPlayerNum() == 0 then
            if deadPlayer:DistTo(player) <= 10 then
                applyDepression(75,0.5,true,player)
                applyPanic(100,1,true,true,player)
            end
        end
    end
end

function ChlorpromazineTakePills(_, player, percent)
    if percent == 1 then
	    playerdata = player:getModData()
	    playerdata.ChlorpromazineHours = playerdata.ChlorpromazineHours + 24
    end
end

function PillEffects()
    if player ~= nil and player:isAlive() == true then
        if player:isLocalPlayer() and player:getPlayerNum() == 0 then
            playerdata = player:getModData()
            if playerdata.ChlorpromazineHours >= 52 then ApplyPillEffects(player,8,50,0.20,0.12,0.20,100,0) return
            elseif playerdata.ChlorpromazineHours >= 46 then ApplyPillEffects(player,0,25,0.12,0.06,0.12,ZombRand(100)+1,ZombRand(100)+1) return
            elseif playerdata.ChlorpromazineHours >= 40 then ApplyPillEffects(player,0,25,0.06,0.04,0.04,100,100) return
            elseif playerdata.ChlorpromazineHours >= 34 then ApplyPillEffects(player,0,0,0.03,0,0.02,100,100) return end
        end
    end
end

-- Hallucination related functions

function HitHalZombieCheck(zombie)
    if player ~= nil and zombie == halzombie and player:isLocalPlayer() and player:getPlayerNum() == 0 then
        halzombie:removeFromWorld()
        halzombie:removeFromSquare()
        halzombie = nil
        Events.OnTick.Remove(CanSeeCheck)
        Events.OnHitZombie.Remove(HitHalZombieCheck)
        applyPanic(100,0.5,false,false,player)
        applyDepression(50,0.2,false,player)
        if ZombRand(10)+1 == 10 then
            ApplyForceTrip(true)
        else
            player:dropHandItems()
        end
        makePlayerSound(player, true)
    end
end

function CanSeeCheck()
    if player ~= nil then
        if halzombie == nil then
            Events.OnHitZombie.Remove(HitHalZombieCheck)
            Events.OnTick.Remove(CanSeeCheck)
        end
        if halzombie:DistTo(player) <= 2.25 and player:CanSee(halzombie) and player:isLocalPlayer() and player:getPlayerNum() == 0 then
            halzombie:removeFromWorld()
            halzombie:removeFromSquare()
            halzombie = nil
            Events.OnHitZombie.Remove(HitHalZombieCheck)
            Events.OnTick.Remove(CanSeeCheck)
            applyPanic(100,0.5,false,false,player)
            applyDepression(50,0.2,false,player)
            if ZombRand(10)+1 == 10 then
                ApplyForceTrip(true)
            else
                player:dropHandItems()
            end
            makePlayerSound(player, true)
        end
    end
end

function MakeUseless(zombie)
    if zombie == halzombie and oldhalzombiepos["X"] ~= halzombie:getX() and oldhalzombiepos["Y"] ~= halzombie:getY() then
        oldhalzombiepos["X"] = nil oldhalzombiepos["Y"] = nil oldhalzombiepos["Z"] = nil
        halzombie:setUseless(true)
        halzombie:setHealth(100000)
        Events.OnZombieUpdate.Remove(MakeUseless)
    end
end

local function getSquare(distance)
    if player ~= nil then
        local pickedNum = ZombRand(8)+1
        local currentPickedNum = pickedNum
        local pickedSquare = nil
        while pickedSquare == nil do
            if currentPickedNum == 9 and pickedNum == 1 then pickedSquare = false break
            elseif currentPickedNum == 9 and pickedNum ~= 1 then currentPickedNum = 1 end
            local ModX = (HalZombieSpawnCatalog[currentPickedNum].X * distance) + player:getX()
            local ModY = (HalZombieSpawnCatalog[currentPickedNum].Y * distance) + player:getY()
            local Square = player:getCell():getGridSquare(ModX,ModY,player:getZ())
            if Square ~= nil then
                if not Square:isSolidTrans() and Square:TreatAsSolidFloor() then
                    if player:getBuilding() then if not Square:isOutside() then pickedSquare = {X = ModX, Y = ModY} break end
                    else if Square:isOutside() then pickedSquare = {X = ModX, Y = ModY} break end end
                end
                if pickedSquare == nil then currentPickedNum = currentPickedNum + 1
                    if currentPickedNum == pickedNum then pickedSquare = false break end
                end
            end
        end
        return pickedSquare
    end
end

function CreateHallucination()
    if player ~= nil and player:HasTrait("schizophrenia") and player:isLocalPlayer() and player:getPlayerNum() == 0 and not player:isAsleep() then
        if halzombie ~= nil then
            halzombie:removeFromWorld()
            halzombie:removeFromSquare()
            halzombie = nil
            Events.OnTick.Remove(CanSeeCheck)
            Events.OnHitZombie.Remove(HitHalZombieCheck)
            Events.OnZombieUpdate.Remove(MakeUseless)
        end
        local Square = nil
        if player:getBuilding() then Square = getSquare(2)
        else Square = getSquare(10) end
        if Square ~= false then
            local zombie = addZombiesInOutfit(Square.X,Square.Y,player:getZ(), 1, "GenericNGNH", nil, false, false, false, false, 100) zombie = zombie:get(0)
            oldhalzombiepos["X"] = zombie:getX() oldhalzombiepos["Y"] = zombie:getY() oldhalzombiepos["Z"] = zombie:getZ()
            zombie:pathToCharacter(player)
            halzombie = zombie
            Events.OnHitZombie.Add(HitHalZombieCheck)
            Events.OnZombieUpdate.Add(MakeUseless)
            Events.OnTick.Add(CanSeeCheck)
        else print("Hal Zombie Fail") end
    end
end

function ForcePlayerLoad()
    figureOutPlayer()
    FigureOutBuilding()
    RemoveSchizEvents()
    AddSchizEvents()
end

-- Events

Events.OnGameStart.Add(figureOutPlayer)
Events.EveryTenMinutes.Add(PillEffects)
Events.OnPlayerDeath.Add(CheckIfYouDied)
Events.OnCreatePlayer.Add(MakeNewPlayer)
Events.OnLoad.Add(FigureOutBuilding)

function AddSchizEvents()
    Events.EveryHours.Add(HourEvent)
    Events.EveryDays.Add(DayEvent)
    Events.OnPlayerMove.Add(FakeAlarm)
    Events.OnHitZombie.Add(RollHitFakeBite)
    Events.OnExitVehicle.Add(RollFakeJumpscare)
    Events.OnPlayerDeath.Add(ApplyDeathDepression)
    LoadedEvents = true
end

function RemoveSchizEvents()
    Events.EveryHours.Remove(HourEvent)
    Events.EveryDays.Remove(DayEvent)
    Events.OnPlayerMove.Remove(FakeAlarm)
    Events.OnHitZombie.Remove(RollHitFakeBite)
    Events.OnExitVehicle.Remove(RollFakeJumpscare)
    Events.OnPlayerDeath.Remove(ApplyDeathDepression)
    LoadedEvents = false
end
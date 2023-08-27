
--print ("KillCount isDedicated="..tostring(getCore():isDedicated() and "true" or "false"))--true probably only for multiplayer dedicated server for server and shared lua modules
--print ("KillCount isClient="..tostring(isClient() and "true" or "false"))--true in multiplayer as client or host
--print ("KillCount isServer="..tostring(isServer() and "true" or "false"))--true ??

--this.setAttackedBy((IsoGameCharacter)null); <= this is done just before Zombie dead by Fire


if getCore() and getCore():isDedicated() then return; end

require ('WeaponTypeKillCount')--ensure WeaponTypeKillCount OnZombieDead callback is registered before KillCountUpdate

KillCount = KillCount or {}
KillCount.DELAY_MAX_SAME_KILL = 20000;--20s max for same kill, this should allows any realistic Z respawn speed AND not bother too much my/any future resurrection mods AND eat any freeze. priority to freeze for now.
KillCount.DELAY_MAX_WEAPON_HIT = 5000;--5s max 
KillCount.Verbose = false;


local lcl = {}
lcl.player_base          = __classmetatables[IsoPlayer.class].__index
lcl.player_getModData    = lcl.player_base.getModData
lcl.player_getVehicle    = lcl.player_base.getVehicle
lcl.player_isLocalPlayer = lcl.player_base.isLocalPlayer

lcl.getTimestampMs = getTimestampMs
lcl.getPlayer = getPlayer


function KillCount.initVersionId()
    local ver_str = getCore():getVersionNumber()
    local num1, num2 = ver_str:match("(%d+)%.(%d+)")
    KillCount.num1 = tonumber(num1)
    KillCount.num2 = tonumber(num2)
end
KillCount.initVersionId()

function KillCount.isB41_60Plus()
    return (KillCount.num1>41 or KillCount.num1==41 and KillCount.num2>=60);
end
function KillCount.isB41_50()
    return (KillCount.num1<41 or KillCount.num1==41 and KillCount.num2<=50);
end


function KillCount.createModData(player)
    if not player or not lcl.player_isLocalPlayer(player) then return end
    local md = lcl.player_getModData(player)
    if md.AKCModData == nil then
        md.AKCModData = {};
        local nbkill = player:getZombieKills() or 0;
        md.AKCModData.gk  = nbkill;
        md.AKCModData.fk  = 0;
        md.AKCModData.ck  = 0;
    else
        if md.AKCModData.ck == nil then
            --backward compatibility for saves before v 1.2
            md.AKCModData.fk  = 0;
            md.AKCModData.ck  = nbkill-md.AKCModData.gk;
            md.AKCModData.gk  = nbkill;
        end
    end
end

function KillCount.debugTable(zombieTableForKillCount)
    if not KillCount.Verbose then return end
    local iter = 1
    for key,value in pairs(zombieTableForKillCount) do 
        print ("Debug Table "..iter..": ["..key.."] "..value);--
        iter = iter + 1;
    end
    if iter == 1 then
        print ("Debug Table (empty)");
    end

end

function KillCount.clearTableOldMemories(myTable,myCurrentTime,maxTime)
    if not myTable then return end
    local keysToRemove = {}
    for key,val in pairs(myTable) do
        if myCurrentTime-val > maxTime then
            table.insert(keysToRemove,key)
        end
    end
    
    for it=1, #keysToRemove do
        key = keysToRemove[it]
        myTable[key] = nil
        if KillCount.Verbose then print('KillCount.clearTableOldMemories removed key '..key) end
    end

    return myTable
end

function KillCount.clearOldMemories()
    local currentTime = lcl.getTimestampMs()
    weaponTableForKillCount = KillCount.clearTableOldMemories(weaponTableForKillCount,currentTime,KillCount.DELAY_MAX_WEAPON_HIT)
    characterTableForKillCount = KillCount.clearTableOldMemories(characterTableForKillCount,currentTime,KillCount.DELAY_MAX_SAME_KILL)
    zombieTableForKillCount = KillCount.clearTableOldMemories(zombieTableForKillCount,currentTime,KillCount.DELAY_MAX_SAME_KILL)
    zombieTable2ForKillCount = KillCount.clearTableOldMemories(zombieTable2ForKillCount,currentTime,KillCount.DELAY_MAX_SAME_KILL)
    zombieTableForCarKillCount = KillCount.clearTableOldMemories(zombieTableForCarKillCount,currentTime,KillCount.DELAY_MAX_SAME_KILL)
    zombieTableForExplosionKillCount = KillCount.clearTableOldMemories(zombieTableForExplosionKillCount,currentTime,KillCount.DELAY_MAX_SAME_KILL)
end

function KillCount.updateB41_52_OnCharacterDeath(character)
    local player = lcl.getPlayer();
    if not player or not lcl.player_isLocalPlayer(player) then return end
    KillCount.createModData(player);
    local charStr = tostring(character);
    if charStr == tostring(player) then return; end
    KillCount.clearOldMemories()
    --first call on characterDeath we count it as car kill
    if zombieTable2ForKillCount and zombieTable2ForKillCount[charStr] ~= nil then--Fire Kill
        if KillCount.Verbose then print('KillCount.updateB41_52_OnCharacterDeath increase fire kill.') end
        lcl.player_getModData(player).AKCModData.fk = lcl.player_getModData(player).AKCModData.fk + 1;
        zombieTable2ForKillCount[charStr] = nil;
        zombieTableForKillCount[charStr] = nil;
        KillCount.debugTable(zombieTable2ForKillCount);
        KillCount.debugTable(zombieTableForKillCount);
    else--car kill (unless it is a weapon kill)
        if weaponTableForKillCount and weaponTableForKillCount[charStr] ~= nil then
            if KillCount.Verbose then print('KillCount.updateB41_52_OnCharacterDeath after weapon kill ignore it. '..charStr..' '..tostring(player:getVehicle() or 'no vehicle')) end
            weaponTableForKillCount[charStr] = nil;
            KillCount.debugTable(weaponTableForKillCount);
        elseif zombieTableForKillCount and zombieTableForKillCount[charStr] ~= nil then--Car Kill or Explosion kill
            if (not KillCountWeaponType or not KillCountWeaponType.isExplosiveDeath or not KillCountWeaponType.isExplosiveDeath(character)) then
                if KillCount.Verbose then print('KillCount.updateB41_52_OnCharacterDeath increase car kill. '..tostring(player:getVehicle() or 'no vehicle')) end
                --TODO count only if there is no recent OnWeaponHitXp on that Zombie and if the player is in a vehicle
                local vehicle = lcl.player_getVehicle(player)
                if vehicle and vehicle:getDriver() == player then
                    lcl.player_getModData(player).AKCModData.ck = lcl.player_getModData(player).AKCModData.ck + 1;
                    zombieTableForCarKillCount[charStr] = zombieTableForKillCount[charStr]
                end
            else
                if KillCount.Verbose then print('KillCount.updateB41_52_OnCharacterDeath increase explosion kill.') end
                lcl.player_getModData(player).AKCModData.ek = (lcl.player_getModData(player).AKCModData.ek or 0) + 1;
                zombieTableForExplosionKillCount[charStr] = zombieTableForKillCount[charStr]
            end
            --KillCount.debugTable(zombieTableForKillCount);
            zombieTableForKillCount[charStr] = nil;
        else--it is probably a weapon kill, we wil detect it on ZombieDead but let the genuine counter work anyway
            characterTableForKillCount[charStr] = lcl.getTimestampMs();
        end
    end
end

function KillCount.updateB41_52_OnZombieDead(character)
    local player = lcl.getPlayer();
    if not player or not lcl.player_isLocalPlayer(player) then return end
    KillCount.createModData(player);
    local charStr = tostring(character);
    if charStr == tostring(player) then return; end
    KillCount.clearOldMemories()
    if characterTableForKillCount and characterTableForKillCount[charStr] ~= nil then--Wpn Kill (Character
        if KillCount.Verbose then print('KillCount.updateB41_52_OnZombieDead increase weapon kill 1. '..tostring(player:getVehicle() or 'no vehicle')) end
        lcl.player_getModData(player).AKCModData.gk = lcl.player_getModData(player).AKCModData.gk + 1 --wpn kill are just counted for future use, for now we stick on genuine counter for display
        characterTableForKillCount[charStr] = nil;
        KillCount.debugTable(characterTableForKillCount);
    elseif weaponTableForKillCount and weaponTableForKillCount[charStr] ~= nil then
        if KillCount.Verbose then print('KillCount.updateB41_52_OnZombieDead increase weapon kill 2. '..tostring(player:getVehicle() or 'no vehicle')) end
        lcl.player_getModData(player).AKCModData.gk = lcl.player_getModData(player).AKCModData.gk + 1 --wpn kill are just counted for future use, for now we stick on genuine counter for display
        KillCount.debugTable(weaponTableForKillCount);
    else--it is Fire Kill or Car Kill let OnCharacterDeath decide
        if zombieTableForKillCount and zombieTableForKillCount[charStr] ~= nil then--
            zombieTable2ForKillCount[charStr] = lcl.getTimestampMs();--Fire Kill
        else
            zombieTableForKillCount[charStr] = lcl.getTimestampMs();--Car Kill or Fire Kill
        end
    end
end

function KillCount.updateB41_60_OnZombieDead(character)
    local player = lcl.getPlayer();
    if not player or not lcl.player_isLocalPlayer(player) then return end
    KillCount.clearOldMemories()
    local charStr = tostring(character);
    local timestamp = lcl.getTimestampMs()
    local consumedChar = false
    if zombieTableForKillCount and zombieTableForKillCount[charStr] ~= nil and timestamp - zombieTableForKillCount[charStr] < KillCount.DELAY_MAX_SAME_KILL then--we already counted a OnZombieDead for that Z
        --if it is recent, it means it is a fire kill. (only fire kills are sources for twice OnZombieDead in short period of time
        KillCount.createModData(player);
        local md = lcl.player_getModData(player).AKCModData
        if KillCount.Verbose then print('KillCount.updateB41_60_OnZombieDead increase fire kill. '..tostring(player:getVehicle() or 'no vehicle')) end
        md.fk = md.fk + 1;--we count ALL fire kills as ours. It is stupid, but I have no better
        if zombieTableForCarKillCount and zombieTableForCarKillCount[charStr] ~= nil then
            if timestamp - zombieTableForCarKillCount[charStr] < KillCount.DELAY_MAX_SAME_KILL then
                --We fire-killed a Z while in a car: rollback on car kill
                if KillCount.Verbose then print('KillCount.updateB41_60_OnZombieDead decrease car kill. '..tostring(player:getVehicle() or 'no vehicle')) end
                md.ck = md.ck - 1;
            end
            zombieTableForCarKillCount[charStr] = nil;
        end
        zombieTableForKillCount[charStr] = nil;
        consumedChar = true
    elseif character:getActionStateName() == "onground" then
        local vehicle = nil
        local target = character:getTarget()
        if target and instanceof(target, "IsoGameCharacter") then
            vehicle = lcl.player_getVehicle(target)
        end
        if vehicle and vehicle:getDriver() == player then 
            --for now we need the target of the Z to be onboard of the car for car kill detection. So the case of a car driver saving a poor survivor on feet by driving on its aggressor may not be managed (to be tested)
            KillCount.createModData(player);
            local md = lcl.player_getModData(player).AKCModData
            --print("print_OnZombieDead Vehicle ".. tostring(character)..getStrParam(character:getTarget():getVehicle()));
            if KillCount.Verbose then print('KillCount.updateB41_60_OnZombieDead increase car kill. '..tostring(vehicle or 'no vehicle')) end
            md.ck = md.ck + 1;
            zombieTableForCarKillCount[charStr] = timestamp
        end
    end
    
    if not consumedChar then
        zombieTableForKillCount[charStr] = timestamp
    end
end

function KillCount.updateB41_60_OnWeaponHitXp(character, weapon, characterTarget, damage)
    KillCount.clearOldMemories()
    local charStr = tostring(characterTarget);
    local removedErrorKill = false
    if zombieTableForCarKillCount then
        local previousCarKillTime = zombieTableForCarKillCount[charStr]
        if previousCarKillTime then
            local player = lcl.getPlayer();
            if not player or not lcl.player_isLocalPlayer(player) then return end
            --We (range?-)weapon-killed a Z while in a car: rollback on car kill
            if KillCount.Verbose then print('KillCount.updateB41_60_OnWeaponHitXp decrease car kill. '..tostring(player:getVehicle() or 'no vehicle')) end
            local md = lcl.player_getModData(player).AKCModData
            md.ck = md.ck - 1;
            removedErrorKill = true
            zombieTableForCarKillCount[charStr] = nil;
        end
    end

    if zombieTableForExplosionKillCount then
        local previousExplosionKillTime = zombieTableForExplosionKillCount[charStr]
        if previousExplosionKillTime then
            local player = lcl.getPlayer();
            if not player or not lcl.player_isLocalPlayer(player) then return end
            --We (range?-)weapon-killed a Z while explosing it: rollback on explosion kill
            if KillCount.Verbose then print('KillCount.updateB41_60_OnWeaponHitXp decrease explosion kill. '..tostring(player:getVehicle() or 'no vehicle')) end
            local md = lcl.player_getModData(player).AKCModData
            md.ek = (md.ek or 1) - 1;
            removedErrorKill = true
            zombieTableForExplosionKillCount[charStr] = nil;
        end
    end
    
    if not removedErrorKill then--it is an exhausted spear kill: prepare memory
        weaponTableForKillCount[charStr] = lcl.getTimestampMs();--Weapon kill memory
    end
end

if not isClient() then
    weaponTableForKillCount = {};
    characterTableForKillCount = {};
    zombieTableForKillCount = {};
    zombieTable2ForKillCount = {};
    zombieTableForCarKillCount = {};
    zombieTableForExplosionKillCount = {};
    Events.OnCharacterDeath.Add(KillCount.updateB41_52_OnCharacterDeath);
    Events.OnZombieDead.Add(KillCount.updateB41_52_OnZombieDead);
    Events.OnWeaponHitXp.Add(KillCount.updateB41_60_OnWeaponHitXp);
    --Events.OnTick.Add(KillCount.computeKillNumbers);
end

Events.OnGameStart.Add(KillCount.createModData);
Events.OnLoad.Add(KillCount.createModData);


local function getStrParam(param)
    return " "..tostring(param or "nil")
end

local function print_OnCharacterDeath(character, param2, param3, param4, param5)
    print("print_OnCharacterDeath".. getStrParam(character)..getStrParam(param2)..getStrParam(param3)..getStrParam(param4)..getStrParam(param5));
    if not character or instanceof(character, "IsoPlayer") then return end
    print("print_OnCharacterDeath HitReaction".. getStrParam(character)..getStrParam(character:getHitReaction())..getStrParam(character:getActionStateName())..getStrParam(character:getTarget())..getStrParam(character:getAttackedBy()));
    if character:getTarget() and instanceof(character:getTarget(), "IsoGameCharacter") and character:getTarget():getVehicle() then 
        print("print_OnCharacterDeath Vehicle".. getStrParam(character)..getStrParam(character:getTarget():getVehicle())..getStrParam(character:getTarget():getVehicle():getDriver()));
    end
end

local function print_OnZombieDead(character, param2, param3, param4, param5)
    print("print_OnZombieDead ".. tostring(character)..getStrParam(param2)..getStrParam(param3)..getStrParam(param4)..getStrParam(param5));
    print("print_OnZombieDead HitReaction ".. tostring(character)..getStrParam(character:getHitReaction())..getStrParam(character:getActionStateName())..getStrParam(character:getTarget())..getStrParam(character:getAttackedBy()));
    if character:getTarget() and instanceof(character:getTarget(), "IsoGameCharacter") and character:getTarget():getVehicle() then 
        print("print_OnZombieDead Vehicle ".. tostring(character)..getStrParam(character:getTarget():getVehicle())..getStrParam(character:getTarget():getVehicle():getDriver()));
    end
end

local function print_OnWeaponHitXp(character, weapon, character2, damage, param5)--this occurs for all weapon kills (at least in B41.61+) so we can substract them from car kills or fire kills if needed
    print("print_OnWeaponHitXp"..getStrParam(character)..getStrParam(weapon)..getStrParam(character2)..getStrParam(damage)..getStrParam(param5)..getStrParam(character2:getHealth()));
end

if KillCount.Verbose then
    Events.OnCharacterDeath.Add(print_OnCharacterDeath);
    Events.OnZombieDead.Add(print_OnZombieDead);
    Events.OnWeaponHitXp.Add(print_OnWeaponHitXp);
end

--note B41.78.16 Exhausted spear critical kill:
--LOG  : General     , 1683824842605> print_OnWeaponHitXp zombie.characters.IsoZombie@2ba04e79 
--LOG  : General     , 1683824844670> print_OnZombieDead zombie.characters.IsoZombie@2ba04e79
--LOG  : General     , 1683824844672> print_OnCharacterDeath zombie.characters.IsoZombie@2ba04e79


--note B41.78.16 spear kill (assumed all weapon kill):
--+ crowbar foot huntingknife M16(FromCar)
--LOG  : General     , 1683826434255> print_OnZombieDead zombie.characters.IsoZombie@2ba04e79 nil nil nil nil
--LOG  : General     , 1683826434256> print_OnCharacterDeath zombie.characters.IsoZombie@2ba04e79 nil nil nil nil
--LOG  : General     , 1683826434258> print_OnWeaponHitXp zombie.characters.IsoPlayer@2dcf244b zombie.inventory.types.HandWeapon@6693becf zombie.characters.IsoZombie@2ba04e79 2.0940001010894775 nil 0

--note B41.78.16 car kill slow & medium & fast speed:
--LOG  : General     , 1683827117211> print_OnZombieDead Vehicle zombie.characters.IsoZombie@17698ed0 zombie.vehicles.BaseVehicle@7005188a zombie.characters.IsoPlayer@2dcf244b
--LOG  : General     , 1683827117213> print_OnCharacterDeath Vehicle zombie.characters.IsoZombie@17698ed0 zombie.vehicles.BaseVehicle@7005188a zombie.characters.IsoPlayer@2dcf244b

--note B41.52 Fire Kill:
--LOG  : General     , 1627414823547> print_OnZombieDeadzombie.characters.IsoZombie@2b9acecd
--LOG  : General     , 1627414824927> print_OnZombieDeadzombie.characters.IsoZombie@2b9acecd
--LOG  : General     , 1627414824927> print_OnCharacterDeathzombie.characters.IsoZombie@2b9acecd

--note B41.50 Car Kill:
--LOG  : General     , 1627143315165> print_OnCharacterDeath zombie.characters.IsoZombie@69a62a4b


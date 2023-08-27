
KillCountWeaponType = {}
KillCountWeaponType.Verbose = false

local lcl = {} 
lcl.hitCharacterMap = {}


lcl.getText        = getText
lcl.isClient       = isClient
lcl.getPlayer      = getPlayer
lcl.getTimestampMs = getTimestampMs



lcl.player_base          = __classmetatables[IsoPlayer.class].__index
lcl.player_isLocalPlayer = lcl.player_base.isLocalPlayer
lcl.player_getModData    = lcl.player_base.getModData

lcl.sm_base    = __classmetatables[ScriptManager.class].__index
lcl.sm_getItem = lcl.sm_base.getItem

lcl.item_base           = __classmetatables[zombie.scripting.objects.Item.class].__index
lcl.item_getDisplayName = lcl.item_base.getDisplayName

lcl.hw_base                = __classmetatables[HandWeapon.class].__index
lcl.hw_getCategories       = lcl.hw_base.getCategories
lcl.hw_getSubCategory      = lcl.hw_base.getSubCategory
lcl.hw_getType             = lcl.hw_base.getType
lcl.hw_isInstantExplosion  = lcl.hw_base.isInstantExplosion


lcl.ArrayList_base        = __classmetatables[ArrayList.class].__index
lcl.ArrayList_size        = lcl.ArrayList_base.size
lcl.ArrayList_get         = lcl.ArrayList_base.get


function KillCountWeaponType.getWpnTypeDisplayName(weaponType)
    local scriptItem = lcl.sm_getItem(ScriptManager.instance,weaponType);
    if scriptItem then return lcl.item_getDisplayName(scriptItem) end--nominal
    return weaponType--backup
end

function KillCountWeaponType.getWpnCategoryDisplayName(weaponCategory)
    if weaponCategory == "Blunt" then return lcl.getText("IGUI_perks_Blunt") end
    if weaponCategory == "SmallBlunt" then return lcl.getText("IGUI_perks_SmallBlunt") end
    if weaponCategory == "LongBlade" then return lcl.getText("IGUI_perks_LongBlade") end
    if weaponCategory == "SmallBlade" then return lcl.getText("IGUI_perks_SmallBlade") end
    if weaponCategory == "Axe" then return lcl.getText("IGUI_perks_Axe") end
    if weaponCategory == "Spear" then return lcl.getText("IGUI_perks_Spear") end
    if weaponCategory == "Firearm" then return lcl.getText("IGUI_perks_Firearm") end
    if weaponCategory == "Fire" then return lcl.getText("IGUI_Emote_Fire") end
    if weaponCategory == "Vehicles" then return lcl.getText("Sandbox_Vehicle") end
    if weaponCategory == "Unarmed" then return KillCountWeaponType.getWpnTypeDisplayName("BareHands") end
    if weaponCategory == "Explosives" then return lcl.getText("IGUI_ItemCat_Explosives") end
    --backup
    return lcl.getText(weaponCategory)
end

function KillCountWeaponType.GetWeaponCategoryFromWeapon(weapon)--if there is one category, return it. if there is more, return the first met that is not Improvised, if there is none, return Neither
    local categories = lcl.hw_getCategories(weapon)
    local chosenCategory = "Other";
    for i=0, lcl.ArrayList_size(categories)-1 do
        chosenCategory = lcl.ArrayList_get(categories,i)
        if (chosenCategory ~= "Improvised") then return chosenCategory end
    end
    if chosenCategory == "Other" then
        local subCategory = lcl.hw_getSubCategory(weapon)
        if subCategory then
            chosenCategory = subCategory;--range weapons use subcategory: Firearm
        end
    end
    return chosenCategory;
end
function KillCountWeaponType.GetWeaponTypeFromWeapon(weapon)
    return lcl.hw_getType(weapon)
end

function KillCountWeaponType.addToKillCount(wielder,victim,weapon,damage)
    if not wielder or not victim then return end
    
    local wielderModData = lcl.player_getModData(wielder)--maybe ensure the type of wielder first (but anyway that's the same IsoObject method)
    if wielderModData then
        if not wielderModData.KillCount then wielderModData.KillCount = {} end
        if weapon then
            local weaponCategory = KillCountWeaponType.GetWeaponCategoryFromWeapon(weapon)
            local weaponType = lcl.hw_getType(weapon)
            if weaponType and weaponCategory then
                if not wielderModData.KillCount.WeaponCategory then wielderModData.KillCount.WeaponCategory = {} end
                if not wielderModData.KillCount.WeaponCategory[weaponCategory] then wielderModData.KillCount.WeaponCategory[weaponCategory] = {count=0,WeaponType={}} end
                wielderModData.KillCount.WeaponCategory[weaponCategory].count = wielderModData.KillCount.WeaponCategory[weaponCategory].count + 1;
                if not wielderModData.KillCount.WeaponCategory[weaponCategory].WeaponType[weaponType] then wielderModData.KillCount.WeaponCategory[weaponCategory].WeaponType[weaponType] = 0 end
                wielderModData.KillCount.WeaponCategory[weaponCategory].WeaponType[weaponType] = wielderModData.KillCount.WeaponCategory[weaponCategory].WeaponType[weaponType] + 1;
            end
            if KillCountWeaponType.Verbose and weaponType and weaponCategory then print ("KillCountWeaponType.addToKillCount "..tostring(weaponType or "nil").." "..tostring(wielderModData.KillCount.WeaponCategory[weaponCategory].WeaponType[weaponType] or "nil")..", "..tostring(weaponCategory or "nil").." "..tostring(wielderModData.KillCount.WeaponCategory[weaponCategory].count or "nil")) end
        end
    end
end

--typical local weapon kill B41.65 (true for both solo and MPclient cases): always in that order. beware multihits. player is local
--LOG  : General     , 1642266409760> 81?658?418> KillCountWeaponType.OnWeaponHitCharacter(zombie.characters.IsoPlayer@2059d685, zombie.characters.IsoZombie@40f0eaaa, zombie.inventory.types.HandWeapon@2bf1b526, 16)
--LOG  : General     , 1642266409761> 81?658?419> KillCountWeaponType.OnZombieDead(zombie.characters.IsoZombie@40f0eaaa, nil, nil, nil)
--LOG  : General     , 1642266409761> 81?658?420> KillCountWeaponType.OnWeaponHitXp(zombie.characters.IsoPlayer@2059d685, zombie.inventory.types.HandWeapon@2bf1b526, zombie.characters.IsoZombie@40f0eaaa, 16)
--typical local distant kill B41.65 (MPclient case): always in that order?? beware multihits. player is not local.
--LOG  : General     , 1642266409793> 81?658?458> KillCountWeaponType.OnWeaponHitCharacter(zombie.characters.IsoPlayer@3b567f49, zombie.characters.IsoZombie@52a9d873, zombie.inventory.types.HandWeapon@322107cc, 12.264361381530762)
--LOG  : General     , 1642266409794> 81?658?458> KillCountWeaponType.OnWeaponHitXp(zombie.characters.IsoPlayer@3b567f49, zombie.inventory.types.HandWeapon@322107cc, zombie.characters.IsoZombie@52a9d873, 12.264361381530762)
--LOG  : Multiplayer , 1642266410426> 81?659?092> HitReaction final (): start=81658459 | (x=10886,738281,y=9971,564453;a=0,547223;l=0,194051)
--LOG  : Multiplayer , 1642266410890> 81?659?554> ReceiveEvent: [ player=0 "Tcherno" | name="Update" | pos=( 10887.689 ; 9971.77 ; 0.0 ) | type1="" | type2="" | type3="" | type4="" | flags=512" | variables=0 ]
--LOG  : Multiplayer , 1642266410921> 81?659?585> Event processed (1) : [ player=0 "Tcherno" | name="Update" | pos=( 10887.689 ; 9971.77 ; 0.0 ) | type1="" | type2="" | type3="" | type4="" | flags=512" | variables=0 ]
--LOG  : Multiplayer , 1642266411201> 81?659?866> ReceiveZombieDeath: DeadZombiePacket id(23098) | killer=IsoPlayer(0) | pos=(x=10886.738,y=9971.564,z=0.0;a=0.54722285) | dir=SE | isFallOnFront=false
--LOG  : Multiplayer , 1642266411201> 81?659?866> ReceiveKillZombie 23098: wait for death
--LOG  : Multiplayer , 1642266411821> 81?660?487> HitReaction final (): start=81659866 | (x=10886,738281,y=9971,564453;a=0,547223;l=0,315906)
--LOG  : General     , 1642266412106> 81?660?771> KillCountWeaponType.OnZombieDead(zombie.characters.IsoZombie@52a9d873, nil, nil, nil)

function KillCountWeaponType.OnWeaponHitCharacter(wielder, victim, weapon, damage)
    if KillCountWeaponType.Verbose then print ("KillCountWeaponType.OnWeaponHitCharacter("..tostring(wielder or "nil")..", "..tostring(victim or "nil")..", "..tostring(weapon or "nil")..", "..tostring(damage or "nil")..")") end
    local hitLog = {}
    if not wielder or not instanceof(wielder, "IsoPlayer") then
        if KillCountWeaponType.Verbose and weapon and instanceof(weapon, "HandWeapon") then
            print ("KillCountWeaponType.OnWeaponHitCharacter pipe bomb ? (",weapon:getCategory(),tostring(weapon:IsWeapon() and "IsWeapon" or "NotWeapon"),tostring(weapon:getPhysicsObject() or "nil"),tostring(weapon:getSubCategory() or "nil"),tostring(weapon:getPlacedSprite() or "nil"),tostring(weapon:getRunAnim() or "nil"),tostring(weapon:getStaticModel() or "nil"),tostring(weapon:getWeaponReloadType() or "nil"),tostring(weapon:getDamageCategory() or "nil"),tostring(weapon:getFireMode() or "nil"),tostring(weapon:isInstantExplosion() and "true" or "false"),")")
        end
        if not lcl.isClient() and weapon and instanceof(weapon, "HandWeapon") and lcl.hw_getSubCategory(weapon) == "Swinging" and lcl.hw_isInstantExplosion(weapon) then
            wielder = lcl.getPlayer()--vanilla returns some unknown IsoZombie as wielder in explosive case. cheat it with local player in solo mode
            if wielder then
                hitLog.explosives = true
            end
        else
            return false
        end
    end
    hitLog.wielder = wielder
    hitLog.weapon = weapon
    hitLog.damage = damage
    hitLog.timestampLastHit = lcl.getTimestampMs()
    lcl.hitCharacterMap[tostring(victim)] = hitLog;
end
Events.OnWeaponHitCharacter.Add(KillCountWeaponType.OnWeaponHitCharacter);

function KillCountWeaponType.isExplosiveDeath(victim)
    local hitLog = lcl.hitCharacterMap[tostring(victim)]
    if KillCountWeaponType.Verbose and hitLog and hitLog.explosives then
        print ("KillCountWeaponType.isExplosiveDeath("..tostring(hitLog.weapon:getSubCategory() or "nil")..", "..tostring(hitLog.weapon:isInstantExplosion() and "true" or "false")..", "..tostring(hitLog.timestampLastHit or "nil")..", "..tostring(hitLog.timestampDead or "nil")..")")
    end
    
    return hitLog and not lcl.isClient() and hitLog.explosives and hitLog.timestampLastHit and (hitLog.timestampDead - hitLog.timestampLastHit < 100)
end
function KillCountWeaponType.OnZombieDead(zombie,var2,var3,var4)
    local hitLog = lcl.hitCharacterMap[tostring(zombie)]
    if hitLog then
        hitLog.timestampDead = lcl.getTimestampMs()
        hitLog.onZombieDead = true
        if KillCountWeaponType.isExplosiveDeath(zombie) then
            if KillCountWeaponType.Verbose then print ("KillCountWeaponType.OnZombieDead by explosive") end
        else
            if KillCountWeaponType.Verbose then print ("KillCountWeaponType.OnZombieDead NOT by explosive 1") end
        end
    else
        if KillCountWeaponType.Verbose then print ("KillCountWeaponType.OnZombieDead NOT by explosive 2") end
    end
    if KillCountWeaponType.Verbose then print ("KillCountWeaponType.OnZombieDead("..tostring(zombie or "nil")..", "..tostring(var2 or "nil")..", "..tostring(var3 or "nil")..", "..tostring(var4 or "nil")..")") end
end
Events.OnZombieDead.Add(KillCountWeaponType.OnZombieDead)

function KillCountWeaponType.OnWeaponHitXp(wielder,weapon,victim,damage)
    local strVictim = tostring(victim)
    local hitLog = lcl.hitCharacterMap[strVictim]
    if hitLog then
        if wielder and hitLog.onZombieDead and lcl.player_isLocalPlayer(wielder) then
            --weapon kill detected
            KillCountWeaponType.addToKillCount(wielder,victim,weapon,damage);
        end
        --clear hitLog
        lcl.hitCharacterMap[strVictim] = nil--lets not keep memory forever both for perf and because strVictim could be reused with a Z repop
    end

    if KillCountWeaponType.Verbose then print ("KillCountWeaponType.OnWeaponHitXp("..tostring(wielder or "nil")..", "..tostring(weapon or "nil")..", "..tostring(victim or "nil")..", "..tostring(damage or "nil")..")") end
end
Events.OnWeaponHitXp.Add(KillCountWeaponType.OnWeaponHitXp);
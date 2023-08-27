---
--- Mod: Moar Can Openers
--- Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=2651600962
--- Author: NoctisFalco
--- Profile: https://steamcommunity.com/id/NoctisFalco/
---
--- Redistribution of this mod without explicit permission from the original creator is prohibited
--- under any circumstances. This includes, but not limited to, uploading this mod to the Steam Workshop
--- or any other site, distribution as part of another mod or modpack, distribution of modified versions.
--- You are free to do whatever you want with the mod provided you do not upload any part of it anywhere.
---
--- The mod overrides parts of the ISCraftingUI.lua, ISInventoryPaneContextMenu.lua files by The Indie Stone.
---

OpenCans = OpenCans or {}
OpenCans.GetItemTypes = {}
OpenCans.Recipe = {}
OpenCans.Recipe.OpenCan = {}

function OpenCans.GetItemTypes.CanOpener(scriptItems)
    scriptItems:add(getScriptManager():getItem("Base.TinOpener"))
    for _, v in ipairs(OpenCans.canOpeners.smallBlade) do
        scriptItems:add(getScriptManager():getItem(v[1]))
    end
    for _, v in ipairs(OpenCans.canOpeners.longBlade) do
        scriptItems:add(getScriptManager():getItem(v[1]))
    end
    scriptItems:add(getScriptManager():getItem("Base.Stone"))
end

function OpenCans.Recipe.OpenCan.OnTest(item)
    if OpenCans.Utils.isHandWeapon(item) then
        if OpenCans.canOpenersForPlayer[item:getFullType()] then
            return item:getCondition() > 0
        else
            return false
        end
    end
    return true
end

function OpenCans.Recipe.OpenCan.OnCreate(items, result, player)
    local openerItem
    local foodItem
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "Food") then
            foodItem = item
        elseif OpenCans.canOpenersForPlayer[item:getFullType()] then
            openerItem = item
        end
    end

    if openerItem:getFullType() == "Base.TinOpener" then return end -- Nothing to do here
    if not OpenCans.Utils.isHandWeapon(openerItem) and not OpenCans.Utils.isStone(openerItem) then return end

    -- Number of cans the player has opened with a specific opener
    local cansUsedOpener = 0
    local cansStone = player:getModData().openCannedFood.cansStone or 0
    local cansBladeLong = player:getModData().openCannedFood.cansBladeLong or 0
    local cansBladeSmall = player:getModData().openCannedFood.cansBladeSmall or 0

    -- Weapon damage
    local isLongBlade = OpenCans.Utils.isLongBlade(openerItem)
    local isSmallBlade = OpenCans.Utils.isSmallBlade(openerItem)
    local isStone = OpenCans.Utils.isStone(openerItem)

    local weaponSkillLevel = 0
    if isLongBlade then
        weaponSkillLevel = player:getPerkLevel(Perks.LongBlade)
        cansUsedOpener = cansBladeLong
    elseif isSmallBlade then
        weaponSkillLevel = player:getPerkLevel(Perks.SmallBlade)
        cansUsedOpener = cansBladeSmall
    elseif isStone then
        cansUsedOpener = cansStone
    end

    if isLongBlade or isSmallBlade then
        -- The game's default implementation
        local chanceConditionLower = math.floor(openerItem:getConditionLowerChance() / 1.5)
        local maintenanceMod = math.floor((player:getPerkLevel(Perks.Maintenance) + weaponSkillLevel / 2) / 2)
        chanceConditionLower = math.floor(chanceConditionLower + maintenanceMod * 2)

        local random = ZombRand(chanceConditionLower)
        if random == 0 then
            openerItem:setCondition(openerItem:getCondition() - 1)
        end
    end

    -- Body damage
    if SandboxVars.MoarCanOpeners.InjurePlayer then
        local chanceInjury = 10 + weaponSkillLevel / 2

        local panicMod = (1.1 * player:getMoodleLevel(MoodleType.Panic)) ^ 1.5
        local drunkMod = player:getMoodleLevel(MoodleType.Drunk) ^ 1.3
        local fatigueMod = 0.5 * player:getMoodleLevel(MoodleType.Tired)
        local hypothermiaMod = 0.8 * player:getMoodleLevel(MoodleType.Hypothermia)

        chanceInjury = chanceInjury - (panicMod + drunkMod + fatigueMod + hypothermiaMod)
        chanceInjury = chanceInjury + math.sqrt(cansUsedOpener / 5)

        -- Lucky and Unlucky
        --if player:HasTrait("Lucky") then
        --    chanceInjury = chanceInjury - ZombRand(1, 3)
        --elseif player:HasTrait("Unlucky") then
        --    chanceInjury = chanceInjury + ZombRand(1, 3)
        --end

        -- Hunter or FormerScout
        if player:HasTrait("Hunter") then
            chanceInjury = chanceInjury + 2
        elseif player:HasTrait("Formerscout") then
            chanceInjury = chanceInjury + 1
        end
        -- Clumsy
        if player:HasTrait("Clumsy") then
            chanceInjury = chanceInjury - 2
        end

        chanceInjury = OpenCans.Utils.round(chanceInjury)
        chanceInjury = math.max(chanceInjury, 1)

        -- Injure the player
        local random = ZombRand(chanceInjury)
        if random == 0 then
            local hand = player:getBodyDamage():getBodyPart(BodyPartType.Hand_L)
            random = ZombRand(2)
            if random == 0 then
                hand = player:getBodyDamage():getBodyPart(BodyPartType.Hand_R)
            end

            -- Chance for a deep wound
            local chanceInjurySeverity = 1
            if isLongBlade or isSmallBlade then
                local avgDamage = (openerItem:getMaxDamage() + openerItem:getMinDamage()) / 2
                chanceInjurySeverity = math.ceil(avgDamage / 0.7)
            end

            random = ZombRand(1, 11)
            if random <= chanceInjurySeverity then
                hand:generateDeepWound()
            else
                hand:setScratched(true, true)
            end
        end
    end

    -- Poisoning
    if SandboxVars.MoarCanOpeners.PoisonResult then
        local bloodAmount
        local poisonPower
        if isStone then
            local visual = player:getHumanVisual()
            bloodAmount = (visual:getBlood(BloodBodyPartType.Hand_L) + visual:getBlood(BloodBodyPartType.Hand_R)) / 2
        else
            bloodAmount = openerItem:getBloodLevel()
        end
        poisonPower = OpenCans.Utils.round(bloodAmount * 20)
        result:setPoisonPower(foodItem:getPoisonPower() + poisonPower)
    end

    -- Spill
    if SandboxVars.MoarCanOpeners.SpillResult then
        local chanceSpill = 1
        -- TODO: needs a better formula
        local spillAmountMod = 5 - player:getMoodleLevel(MoodleType.Panic)
        local spillAmountMin = 0.1
        local spillAmount = 0.5 / spillAmountMod
        if isSmallBlade then
            chanceSpill = 10
            spillAmountMin = 0
            spillAmount = 0.15 / spillAmountMod
        elseif isLongBlade then
            chanceSpill = 6
            spillAmountMin = 0.05
            spillAmount = 0.3 / spillAmountMod
        end

        chanceSpill = chanceSpill - player:getMoodleLevel(MoodleType.Panic)
        chanceSpill = chanceSpill + math.sqrt(cansUsedOpener / 5)
        chanceSpill = math.max(math.floor(chanceSpill), 1)

        spillAmount = ZombRand(math.max(spillAmountMin * 100, 1), spillAmount * 100 + 1) / 100

        local random = ZombRand(chanceSpill)
        if random == 0 then
            result:multiplyFoodValues(1 - spillAmount)
        elseif spillAmountMin > 0 then
            result:multiplyFoodValues(1 - spillAmountMin)
        end
    end

    if isLongBlade then
        player:getModData().openCannedFood.cansBladeLong = cansUsedOpener + 1
    elseif isSmallBlade then
        player:getModData().openCannedFood.cansBladeSmall = cansUsedOpener + 1
    elseif isStone then
        player:getModData().openCannedFood.cansStone = cansUsedOpener + 1
    end
end
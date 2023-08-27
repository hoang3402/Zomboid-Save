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

--MoarCanOpeners = MoarCanOpeners or {}
--MoarCanOpeners.cannedFood = {}

OpenCans = OpenCans or {}

OpenCans.RECIPE_LUA_CREATE = "OpenCans.Recipe.OpenCan.OnCreate"
OpenCans.RECIPE_LUA_TEST = "OpenCans.Recipe.OpenCan.OnTest"

OpenCans.canOpeners = OpenCans.canOpeners or {
    smallBlade = {},
    longBlade = {}
}
OpenCans.canOpenersForPlayer = {}

-- ************************

local function sortItems(t)
    table.sort(t, function(a, b)
        if a[2] ~= b[2] then
            return a[2] > b[2]
        end
        return a[3] > b[3]
    end)
end

local function populateCanOpenersForPlayer()
    if not getPlayer() then return end

    local strengthLevel = getPlayer():getPerkLevel(Perks.Strength)

    local items = {}
    table.insert(items, "Base.TinOpener")
    items["Base.TinOpener"] = true
    if strengthLevel >= SandboxVars.MoarCanOpeners.SmallBladeStrengthLevel then
        for _, entry in ipairs(OpenCans.canOpeners.smallBlade) do
            table.insert(items, entry[1])
            items[entry[1]] = true
        end
    end
    if strengthLevel >= SandboxVars.MoarCanOpeners.LongBladeStrengthLevel then
        for _, entry in ipairs(OpenCans.canOpeners.longBlade) do
            table.insert(items, entry[1])
            items[entry[1]] = true
        end
    end
    table.insert(items, "Base.Stone")
    items["Base.Stone"] = true

    OpenCans.canOpenersForPlayer = items
end

local function populateCanOpeners()
    local itemsCutPlant = getScriptManager():getItemsTag("CutPlant")
    for i = 0, itemsCutPlant:size() - 1 do
        local item = itemsCutPlant:get(i)
        if OpenCans.Utils.isSmallBlade(item) then
            local entry = { item:getFullName(), item:getConditionLowerChance(), item:getConditionMax() }
            table.insert(OpenCans.canOpeners.smallBlade, entry)
        elseif OpenCans.Utils.isLongBlade(item) then
            local entry = { item:getFullName(), item:getConditionLowerChance(), item:getConditionMax() }
            table.insert(OpenCans.canOpeners.longBlade, entry)
        end
    end

    sortItems(OpenCans.canOpeners.smallBlade)
    sortItems(OpenCans.canOpeners.longBlade)
end

local function changeRecipes()
    local recipes = ScriptManager.instance:getAllRecipes()
    for recipeIndex = 0, recipes:size() - 1 do
        local recipe = recipes:get(recipeIndex)
        --print(recipe:getName())

        local doEditSources
        local source = recipe:findSource("[Recipe.GetItemTypes.CanOpener]")
        if source then
            doEditSources = true
        else
            source = recipe:findSource("Base.TinOpener")
            if source and source:isKeep()
                    and recipe:getCategory()
                    and string.match(string.lower(recipe:getCategory()), "cooking") then
                doEditSources = true
            end
        end

        if doEditSources then
            local newSources = {}
            local sources = recipe:getSource()
            for sourceIndex = 0, sources:size() - 1 do
                source = sources:get(sourceIndex)

                local newSource = source:isKeep() and "keep " or ""
                newSource = source:isDestroy() and "destroy " or ""

                local items = source:getItems()
                for itemIndex = 0, items:size() - 1 do
                    local item = items:get(itemIndex)
                    if source:isKeep() then
                        newSource = newSource .. item .. "/"
                    elseif source:getCount() > 1 then
                        newSource = item .. "=" .. source:getCount()
                    elseif source:getUse() > 0 then
                        newSource = item .. ";" .. source:getUse()
                    else
                        newSource = newSource .. item .. "/"
                        -- Insert item
                        --MoarCanOpeners.cannedFood[item] = true
                    end
                end

                if newSource:match("Recipe.GetItemTypes.CanOpener") or newSource:match("Base.TinOpener") then
                    newSource = "keep [OpenCans.GetItemTypes.CanOpener]"
                end
                table.insert(newSources, newSource)
            end

            recipe:getSource():clear()
            for i = 1, #newSources do
                recipe:DoSource(newSources[i])
            end

            recipe:setLuaCreate(OpenCans.RECIPE_LUA_CREATE)
            recipe:setLuaTest(OpenCans.RECIPE_LUA_TEST)
        end
    end
end

-- ************************

local function onLevelPerk(player, perk, perkLevel, _)
    if player:isLocalPlayer() and perk == Perks.Strength then
        if perkLevel ~= SandboxVars.MoarCanOpeners.LongBladeStrengthLevel
                or perkLevel ~= SandboxVars.MoarCanOpeners.SmallBladeStrengthLevel then
            populateCanOpenersForPlayer()
        end
    end
end

local function onGameStart()
    populateCanOpenersForPlayer()
    Events.LevelPerk.Add(onLevelPerk)

    if not getPlayer():getModData().openCannedFood then
        getPlayer():getModData().openCannedFood = {}
    end
end

local function onGameBoot()
    populateCanOpeners()
    changeRecipes()
end

Events.OnGameStart.Add(onGameStart)
Events.OnGameBoot.Add(onGameBoot)
if not OpenCans.original_ISCraftAction_start then
    OpenCans.original_ISCraftAction_start = ISCraftAction.start
end
function ISCraftAction:start()
    OpenCans.original_ISCraftAction_start(self)
    if self.openWithStone then
        self:setActionAnim("RemoveGrass")
    end
end

if not OpenCans.original_ISCraftAction_new then
    OpenCans.original_ISCraftAction_new = ISCraftAction.new
end
function ISCraftAction:new(character, item, time, recipe, container, containers)
    local o = OpenCans.original_ISCraftAction_new(self, character, item, time, recipe, container, containers)
    if recipe and recipe.getOriginalname and recipe:getLuaCreate() == OpenCans.RECIPE_LUA_CREATE then
        local foundOpener = false
        local foundSmallBlade = false
        local foundLongBlade = false

        if OpenCans.canOpenersForPlayer[item:getFullType()] then
            if item:getFullType() == "Base.TinOpener" then
                foundOpener = true
            elseif OpenCans.Utils.isSmallBlade(item) then
                foundSmallBlade = true
            elseif OpenCans.Utils.isLongBlade(item) then
                foundLongBlade = true
            end
        else
            for i = 0, containers:size() - 1 do
                local itemContainer = containers:get(i)
                if itemContainer:contains("Base.TinOpener") then
                    foundOpener = true
                    break
                end
                -- Skip TinOpener (first) and Stone (last)
                for j = 2, #OpenCans.canOpenersForPlayer - 1 do
                    local itemType = OpenCans.canOpenersForPlayer[j]
                    local foundItem = itemContainer:getBestCondition(itemType)
                    if foundItem then
                        if OpenCans.Utils.isSmallBlade(foundItem) then
                            foundSmallBlade = true
                        elseif OpenCans.Utils.isLongBlade(foundItem) then
                            foundLongBlade = true
                        end
                    end
                end
            end
        end

        if not foundOpener then
            if foundSmallBlade then
                o.maxTime = time + 80
            elseif foundLongBlade then
                o.maxTime = time + 160
            else
                o.openWithStone = true
                o.maxTime = time + 400
            end
        end
    end
    return o
end
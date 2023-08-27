if not getActivatedMods():contains("ItemTweakerAPI") then
    -- *********************************
    -- ** DarkSlayerEX's Item Tweaker **
    -- *********************************
    if not ItemTweaker then ItemTweaker = {} end
    if not TweakItem then TweakItem = {} end
    if not TweakItemData then TweakItemData = {} end

    --Prep code to make the changes to all item in the TweakItemData table.
    function ItemTweaker.tweakItems()
        local item;
        for k, v in pairs(TweakItemData) do
            for t, y in pairs(v) do
                item = ScriptManager.instance:getItem(k);
                if item ~= nil then
                    item:DoParam(t .. " = " .. y);
                    print(k .. ": " .. t .. ", " .. y);
                end
            end
        end
    end

    function TweakItem(itemName, itemProperty, propertyValue)
        if not TweakItemData[itemName] then
            TweakItemData[itemName] = {};
        end
        TweakItemData[itemName][itemProperty] = propertyValue;
    end

    Events.OnGameBoot.Add(ItemTweaker.tweakItems)
end

if getActivatedMods():contains("ScrapWeapons") then
    TweakItem("SWeapons.ScrapMachete", "Tags", "CutPlant")
    TweakItem("SWeapons.SalvagedMachete", "Tags", "CutPlant")
    TweakItem("SWeapons.ScrapBlade", "Tags", "CutPlant")
    TweakItem("SWeapons.SalvagedBlade", "Tags", "CutPlant")
end
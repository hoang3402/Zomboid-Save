AutoSewing = AutoSewing or {}
AutoSewing.OPTIONS = AutoSewing.OPTIONS or {}
AutoSewing.OPTIONS.Verbose = AutoSewing.OPTIONS.Verbose or false;--from nil to false :D
AutoSewing.OPTIONS.MaxTailoringLevel = AutoSewing.OPTIONS.MaxTailoringLevel or 10

--hook the ISGarmentUI:doContextMenu to install our button
local genuine_ISGarmentUI_doContextMenu = ISGarmentUI.doContextMenu;
function ISGarmentUI:doContextMenu(part, x, y)
    local context = genuine_ISGarmentUI_doContextMenu(self, part, x, y);

    local needle = AutoSewing.getPlayerFastestItemAnyInventory(self.chr,"Needle");
    local thread = AutoSewing.getPlayerFastestItemAnyInventory(self.chr,"Thread");
    local hole = self.clothing:getVisual():getHole(part) > 0;
    local fabric = AutoSewing.getPatchingItem(self.chr);--will not start the auto stuff even if it could remove patch once and leave.
    local cannotBePatched = not self.clothing:getFabricType();
    
    local trainTailoringOption = context:addOption(getText("ContextMenu_AutoSewing"), self.chr, ISGarmentUI.autoSewing, self.clothing, part);

    if not thread or not needle or not fabric or hole or cannotBePatched then
        trainTailoringOption.notAvailable = true
        trainTailoringOption.toolTip = ISInventoryPaneContextMenu.addToolTip();
        trainTailoringOption.toolTip.description = "You need";
        if hole then trainTailoringOption.toolTip.description = trainTailoringOption.toolTip.description .." <LINE> <RGB:1,0,0> "..getText("ContextMenu_PatchHole"); end 
        if not thread or not needle or not fabric then
            trainTailoringOption.toolTip.description = trainTailoringOption.toolTip.description .." <LINE> <RGB:1,0,0> "..getText("ContextMenu_CantRepair");
        end 
        if cannotBePatched then trainTailoringOption.toolTip.description = trainTailoringOption.toolTip.description .." <LINE> <RGB:1,0,0> "..getText("IGUI_garment_CantRepair"); end 
    end
    
    return context;
end

--activate on right-click on patchable item and left-click on "Auto Sewing"
local AutoSewing_actionStarted = false
ISGarmentUI.autoSewing = function(player, clothing, part)
--we could click long after the menu was created and objects inside inventory could be gone so let's not
    if AutoSewing.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing start "..tostring(player).." "..tostring(clothing).." "..tostring(part)); end
    local needle = AutoSewing.getPlayerFastestItemAnyInventory(player,"Needle");--self player is assumed still there but not needle
    local thread = AutoSewing.getPlayerFastestItemAnyInventory(player,"Thread");--that ressource will be depleted frequently
    local hole = clothing:getVisual():getHole(part) > 0;--clothing is assumed still there but it can lead to bugs ! I am just too lazy
    local actionStarted = false
    if thread and needle and not hole and player:getPerkLevel(Perks.Tailoring) < AutoSewing.OPTIONS.MaxTailoringLevel then
        if AutoSewing.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing ressources check OK "..tostring(thread).." "..tostring(needle)); end
        local patch = clothing:getPatchType(part)
        if not patch then
            if AutoSewing.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing not patch"); end
            local fabric = AutoSewing.getPatchingItem(player);--that ressource will be depleted frequently
            if fabric then
                if AutoSewing.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing fabric valid => repairClothing "..tostring(fabric)); end
                ISInventoryPaneContextMenu.repairClothing(player, clothing, part, fabric, thread, needle);
                actionStarted = true;
            end
        else
            if AutoSewing.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing patched => remove it"); end
            ISInventoryPaneContextMenu.removePatch(player, clothing, part, needle)
            actionStarted = true
        end
    else
        if AutoSewing.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing ressources check NOK "..tostring(thread or "no thread").." "..tostring(needle or "no needle").." "..tostring(hole and "hole" or "no hole").." Tailoring="..tostring(player:getPerkLevel(Perks.Tailoring))); end
    end
    if actionStarted and not AutoSewing_actionStarted then--starting the session, boost time
        --setGameSpeed(4);getGameTime():setMultiplier(40);--activate max LEGAL game speed
        AutoSewing_actionStarted = true;
        if AutoSewing.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing max speed= "..getGameSpeed().." "..getGameTime():getTrueMultiplier()); end
    elseif not actionStarted and AutoSewing_actionStarted then--some ressource is depleted, freeze time
        if AutoSewing.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing stops for lack of ressources."); end
        AutoSewing_stop(true);
    end
end

function AutoSewing_stop(freeze)
    if AutoSewing_actionStarted == false then
        print ("ERROR AutoSewing_stop called while not started.");
    end
    if freeze == true then setGameSpeed(0);getGameTime():setMultiplier(1);--freeze game
    else setGameSpeed(1);getGameTime():setMultiplier(1); end--speed 1 game
    AutoSewing_actionStarted = false;
    if AutoSewing.OPTIONS.Verbose then print ("AutoSewing_stop speed= "..getGameSpeed().." "..getGameTime():getTrueMultiplier()); end
end

local genuine_ISRemovePatch_stop = ISRemovePatch.stop;
function ISRemovePatch:stop()
    genuine_ISRemovePatch_stop(self);
    if AutoSewing_actionStarted then
        if AutoSewing.OPTIONS.Verbose then print ("ISRemovePatch:stop calls AutoSewing_sto"); end
        AutoSewing_stop();
    end
end

local genuine_ISRemovePatch_perform = ISRemovePatch.perform;
function ISRemovePatch:perform()
    genuine_ISRemovePatch_perform(self);
    if AutoSewing_actionStarted then--let's do it after to ensure the patch is removed and maybe reuse the patch
        ISGarmentUI.autoSewing(self.character, self.clothing, self.part)
        if AutoSewing.OPTIONS.Verbose then print ("ISRemovePatch:perform calls ISGarmentUI.autoSewing"); end
    end
end

local genuine_ISRepairClothing_stop = ISRepairClothing.stop;
function ISRepairClothing:stop()
    genuine_ISRepairClothing_stop(self);
    if AutoSewing_actionStarted then
        if AutoSewing.OPTIONS.Verbose then print ("ISRemovePatch:stop calls AutoSewing_sto"); end
        AutoSewing_stop();
    end
end

local genuine_ISRepairClothing_perform = ISRepairClothing.perform;
function ISRepairClothing:perform()
    genuine_ISRepairClothing_perform(self);
    if AutoSewing_actionStarted then--let's do it after to ensure the patch is applied
        ISGarmentUI.autoSewing(self.character, self.clothing, self.part)
        if AutoSewing.OPTIONS.Verbose then print ("ISRepairClothing:perform calls ISGarmentUI.autoSewing"); end
    end
end

--tool functions
function AutoSewing.convertItemFabricTypeToEnum(fabricTypeString)
    if "Cotton"==fabricTypeString then return 1 end
    if "Denim"==fabricTypeString then return 2 end
    if "Leather"==fabricTypeString then return 3 end
    return 0
end
function AutoSewing.getPatchingItem(player, fabricType)
    local fabric = nil
    if (not fabric and (not fabricType or fabricType == 1)) then fabric = AutoSewing.getPlayerFastestItemAnyInventory(player,"RippedSheets"); end
    if (not fabric and (not fabricType or fabricType == 2)) then fabric = AutoSewing.getPlayerFastestItemAnyInventory(player,"DenimStrips"); end
    if (not fabric and (not fabricType or fabricType == 3)) then fabric = AutoSewing.getPlayerFastestItemAnyInventory(player,"LeatherStrips"); end
    if AutoSewing.OPTIONS.Verbose then print ("AutoSewing.getPatchingItem returns "..(fabric~=nil and tostring(fabric) or "nil").." for type ".. tostring(fabricType or "any")); end
    return fabric;
end

function AutoSewing.getPlayerFastestItemAnyInventory(player,itemType)
    return player:getInventory():getFirstTypeRecurse(itemType);
end

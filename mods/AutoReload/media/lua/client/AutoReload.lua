AutoReload = AutoReload or {}
AutoReload.OPTIONS = AutoReload.OPTIONS or {}
AutoReload.OPTIONS.Verbose = AutoReload.OPTIONS.Verbose or false;--from nil to false :D
AutoReload.OPTIONS.MaxReloadingLevel = AutoReload.OPTIONS.MaxReloadingLevel or 10;
AutoReload.actionStarted = false

--hook the ISInventoryPaneContextMenu:doBulletMenu to install our button
local genuine_ISInventoryPaneContextMenu_doBulletMenu = ISInventoryPaneContextMenu.doBulletMenu;
ISInventoryPaneContextMenu.doBulletMenu = function(playerObj, weapon, context)
    genuine_ISInventoryPaneContextMenu_doBulletMenu(playerObj, weapon, context)
    if playerObj:getPerkLevel(Perks.Reloading) < AutoReload.OPTIONS.MaxReloadingLevel and AutoReload.isWeaponManaged(weapon) then
        local bulletAvail = playerObj:getInventory():getItemCountRecurse(weapon:getAmmoType());
        local bulletNeeded = weapon:getMaxAmmo() - weapon:getCurrentAmmoCount();
        if bulletNeeded > bulletAvail then
            bulletNeeded = bulletAvail;
        end
        local insertOption = context:addOption(getText("ContextMenu_AutoReload"), playerObj, AutoReload.TrainReloading, weapon);
        if bulletNeeded <= 0 and weapon:getCurrentAmmoCount() == 0 then
            insertOption.notAvailable = true;--no bullet in weapon nor in inventory
        end
    end
end

--activate on right-click on reloadable item and left-click on "Auto Reload"
function AutoReload.TrainReloading(player, weapon)
--we could click long after the menu was created and objects inside inventory could be gone so let's not
    if AutoReload.OPTIONS.Verbose then print ("AutoReload.TrainReloading start "..tostring(player).." "..tostring(weapon)); end
    local actionStarted = false
    if player:getPerkLevel(Perks.Reloading) < AutoReload.OPTIONS.MaxReloadingLevel and not player:isStrafing() and not player:isAttacking() then
        local ammoItem = AutoReload.getPlayerFastestItemAnyInventory(player,weapon:getAmmoType());--self player is assumed still there but not ammo
        if weapon:getCurrentAmmoCount() > 0 then
            if AutoReload.OPTIONS.Verbose then print ("AutoReload.TrainReloading ISUnloadBulletsFromFirearm ".. weapon:getCurrentAmmoCount()); end
            AutoReload.ensureWeaponEquipped(player, weapon)
            ISTimedActionQueue.add(ISUnloadBulletsFromFirearm:new(player, weapon));--unload
            actionStarted = true;
        elseif ammoItem ~= nil then
            if AutoReload.OPTIONS.Verbose then print ("ISReloadWeaponAction ISReloadWeaponAction"); end
            AutoReload.ensureAmmoMainInventory(player, weapon);
            AutoReload.ensureWeaponEquipped(player, weapon);
            ISTimedActionQueue.add(ISReloadWeaponAction:new(player, weapon));--reload
            actionStarted = true;
        end
    end

    if actionStarted and not AutoReload.actionStarted then--starting the session, boost time
        --setGameSpeed(4);getGameTime():setMultiplier(40);--activate max LEGAL game speed
        AutoReload.actionStarted = true;
        if AutoReload.OPTIONS.Verbose then print ("AutoReload.TrainReloading max speed= "..getGameSpeed().." "..getGameTime():getTrueMultiplier()); end
    elseif not actionStarted and AutoReload.actionStarted then--some ressource is depleted, freeze time
        if AutoReload.OPTIONS.Verbose then print ("AutoReload.TrainReloading stops for lack of ressources."); end
        AutoReload.stop(player:getPerkLevel(Perks.Reloading) >= AutoReload.OPTIONS.MaxReloadingLevel);
    end
end

function AutoReload.stop(freeze)
    if AutoReload.actionStarted == false then
        print ("ERROR AutoReload.stop called while not started.");
    end
    if freeze == true then setGameSpeed(0);getGameTime():setMultiplier(1);--freeze game
    else setGameSpeed(1);getGameTime():setMultiplier(1); end--speed 1 game
    AutoReload.actionStarted = false;
    if AutoReload.OPTIONS.Verbose then print ("AutoReload.stop speed= "..getGameSpeed().." "..getGameTime():getTrueMultiplier()); end
end

local genuine_ISUnloadBulletsFromFirearm_stop = ISUnloadBulletsFromFirearm.stop;
function ISUnloadBulletsFromFirearm:stop()
    genuine_ISUnloadBulletsFromFirearm_stop(self);
    if AutoReload.actionStarted then
        if AutoReload.OPTIONS.Verbose then print ("ISUnloadBulletsFromFirearm:stop calls AutoReload.stop"); end
        AutoReload.stop();
    end
end

local genuine_ISUnloadBulletsFromFirearm_perform = ISUnloadBulletsFromFirearm.perform;
function ISUnloadBulletsFromFirearm:perform()
    genuine_ISUnloadBulletsFromFirearm_perform(self);
    if AutoReload.actionStarted then--let's do it after to ensure the patch is removed and maybe reuse the patch
        AutoReload.TrainReloading(self.character, self.gun)
        if AutoReload.OPTIONS.Verbose then print ("ISUnloadBulletsFromFirearm:perform calls AutoReload.TrainReloading"); end
    end
end

local genuine_ISReloadWeaponAction_stop = ISReloadWeaponAction.stop;
function ISReloadWeaponAction:stop()
    genuine_ISReloadWeaponAction_stop(self);
    if AutoReload.actionStarted then
        if AutoReload.OPTIONS.Verbose then print ("ISUnloadBulletsFromFirearm:stop calls AutoReload.stop"); end
        AutoReload.stop();
    end
end

local genuine_ISReloadWeaponAction_perform = ISReloadWeaponAction.perform;
function ISReloadWeaponAction:perform()
    genuine_ISReloadWeaponAction_perform(self);
    if AutoReload.actionStarted then--let's do it after to ensure the patch is applied
        AutoReload.TrainReloading(self.character, self.gun)
        if AutoReload.OPTIONS.Verbose then print ("ISReloadWeaponAction:perform calls AutoReload.TrainReloading"); end
    end
end

--tool functions
function AutoReload.getPlayerFastestItemAnyInventory(player,itemType)
    return player:getInventory():getFirstTypeRecurse(itemType);
end

function AutoReload.isWeaponManaged(weapon)
    return true;--TODO override to say NO if any modded weapon is bugging with that mod
end

function AutoReload.ensureWeaponEquipped(player, weapon) --equip the weapon if not already equipped
    if player:isEquipped(weapon) == false then
        if AutoReload.OPTIONS.Verbose then print ("AutoReload.ensureWeaponEquipped calls ISInventoryPaneContextMenu.equipWeapon "..tostring(player).." "..tostring(weapon)); end
        ISInventoryPaneContextMenu.equipWeapon(weapon, true, false, player:getPlayerNum());
    end
end

function AutoReload.ensureAmmoMainInventory(player, weapon)--works for magazine too
    ISInventoryPaneContextMenu.transferBullets(player, weapon:getAmmoType(), weapon:getCurrentAmmoCount(), weapon:getMaxAmmo())
end    

--ensure flag is cleared with any escape-like action
local genuine_ISTimedActionQueue_clearQueue = ISTimedActionQueue.clearQueue;
function ISTimedActionQueue:clearQueue()
    genuine_ISTimedActionQueue_clearQueue(self)
    if AutoReload.actionStarted then
        if AutoReload.OPTIONS.Verbose then print ("AutoReload.ensureWeaponEquipped calls ISInventoryPaneContextMenu.equipWeapon "..tostring(player).." "..tostring(weapon)); end
        AutoReload.stop()
    end
end
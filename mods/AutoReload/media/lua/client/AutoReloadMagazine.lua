require 'AutoReload'


--hook the ISInventoryPaneContextMenu:doMagazineMenu to install our button
local genuine_ISInventoryPaneContextMenu_doMagazineMenu = ISInventoryPaneContextMenu.doMagazineMenu;
ISInventoryPaneContextMenu.doMagazineMenu = function(playerObj, magazine, context)
    genuine_ISInventoryPaneContextMenu_doMagazineMenu(playerObj, magazine, context)
    if playerObj:getPerkLevel(Perks.Reloading) < AutoReload.OPTIONS.MaxReloadingLevel and AutoReload.isMagazineManaged(magazine) then
        local bulletAvail = playerObj:getInventory():getItemCountRecurse(magazine:getAmmoType());
        local bulletNeeded = magazine:getMaxAmmo() - magazine:getCurrentAmmoCount();
        if bulletNeeded > bulletAvail then
            bulletNeeded = bulletAvail;
        end
        local insertOption = context:addOption(getText("ContextMenu_AutoReload"), playerObj, AutoReload.TrainReloadingMagazine, magazine);
        if bulletNeeded <= 0 and magazine:getCurrentAmmoCount() == 0 then
            insertOption.notAvailable = true;--no bullet in weapon nor in inventory
        end
    end
end


--activate on right-click on reloadable item and left-click on "Auto Reload"
function AutoReload.TrainReloadingMagazine(player, magazine)
--we could click long after the menu was created and objects inside inventory could be gone so let's not
    if AutoReload.OPTIONS.Verbose then print ("AutoReload.TrainReloadingMagazine start "..tostring(player).." "..tostring(magazine)); end
    local actionStarted = false
    if player:getPerkLevel(Perks.Reloading) < AutoReload.OPTIONS.MaxReloadingLevel and not player:isStrafing() and not player:isAttacking() then
        local ammoItem = AutoReload.getPlayerFastestItemAnyInventory(player,magazine:getAmmoType());--self player is assumed still there but not ammo
        if magazine:getCurrentAmmoCount() > 0 then
            if AutoReload.OPTIONS.Verbose then print ("AutoReload.TrainReloadingMagazine ISUnloadBulletsFromFirearm ".. magazine:getCurrentAmmoCount()); end
            ISTimedActionQueue.add(ISUnloadBulletsFromMagazine:new(player, magazine));--unload
            actionStarted = true;
        elseif ammoItem ~= nil then
            if AutoReload.OPTIONS.Verbose then print ("ISLoadBulletsInMagazine"); end
            AutoReload.ensureAmmoMainInventory(player, magazine);
            local ammoCount = player:getInventory():getItemCountRecurse(magazine:getAmmoType());
            if ammoCount > magazine:getMaxAmmo() - magazine:getCurrentAmmoCount() then
                ammoCount = magazine:getMaxAmmo() - magazine:getCurrentAmmoCount();
            end
            ISTimedActionQueue.add(ISLoadBulletsInMagazine:new(player, magazine, ammoCount));--reload
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



local genuine_ISUnloadBulletsFromMagazine_stop = ISUnloadBulletsFromMagazine.stop;
function ISUnloadBulletsFromMagazine:stop()
    genuine_ISUnloadBulletsFromMagazine_stop(self);
    if AutoReload.actionStarted then
        if AutoReload.OPTIONS.Verbose then print ("ISUnloadBulletsFromMagazine:stop calls AutoReload.stop"); end
        AutoReload.stop();
    end
end

local genuine_ISUnloadBulletsFromMagazine_perform = ISUnloadBulletsFromMagazine.perform;
function ISUnloadBulletsFromMagazine:perform()
    genuine_ISUnloadBulletsFromMagazine_perform(self);
    if AutoReload.actionStarted then--let's do it after to ensure the patch is removed and maybe reuse the patch
        AutoReload.TrainReloadingMagazine(self.character, self.magazine)
        if AutoReload.OPTIONS.Verbose then print ("ISUnloadBulletsFromMagazine:perform calls AutoReload.TrainReloadingMagazine"); end
    end
end

local genuine_ISLoadBulletsInMagazine_stop = ISLoadBulletsInMagazine.stop;
function ISLoadBulletsInMagazine:stop()
    genuine_ISLoadBulletsInMagazine_stop(self);
    if AutoReload.actionStarted then
        if AutoReload.OPTIONS.Verbose then print ("ISLoadBulletsInMagazine:stop calls AutoReload.stop"); end
        AutoReload.stop();
    end
end

local genuine_ISLoadBulletsInMagazine_perform = ISLoadBulletsInMagazine.perform;
function ISLoadBulletsInMagazine:perform()
    genuine_ISLoadBulletsInMagazine_perform(self);
    if AutoReload.actionStarted then--let's do it after to ensure the patch is applied
        AutoReload.TrainReloadingMagazine(self.character, self.magazine)
        if AutoReload.OPTIONS.Verbose then print ("ISLoadBulletsInMagazine:perform calls AutoReload.TrainReloadingMagazine"); end
    end
end

--tool functions
function AutoReload.isMagazineManaged(magazine)
    return true;--TODO override to say NO if any modded magazine is bugging with that mod
end


AutoSewing = AutoSewing or {}
AutoSewing.nbHolesForMoodle = 0;
AutoSewing.displayDelayForMoodle = 15000;--show for 15 seconds
AutoSewing.hideTimeForMoodle = 0;--internal time memo

function AutoSewing.isModEnabled(modname)
    local actmods = getActivatedMods();
    for i=0, actmods:size()-1, 1 do
        if actmods:get(i) == modname then
            return true;
        end
    end
    return false;
end

AutoSewing.isMoodleFrameworkEnabled = AutoSewing.isModEnabled("MoodleFramework")

if AutoSewing.isMoodleFrameworkEnabled then
    require "MF_ISMoodle"

    --Moodle creation, replace Proteins by your own moodle name.
    MF.createMoodle("ClothingHole");

    function AutoSewing.updateClothingHoleMoodle(player)
        if player and player == getPlayer() then--some clothing change occured on local player
            local nbHoles = 0
            for j = 0, player:getWornItems():size()-1 do
                local clothingItem = player:getWornItems():get(j):getItem();
                if instanceof(clothingItem, "Clothing") then
                    --if AutoSewing.OPTIONS.Verbose then print ("updateClothingHoleMoodle cloth = "..clothingItem:getFullType()); end
                    nbHoles = nbHoles + clothingItem:getHolesNumber();
                end
            end
            
            if AutoSewing.nbHolesForMoodle ~= nbHoles then--on change
                local moodle = MF.getMoodle("ClothingHole");--get access to the moodle
                if moodle then
                    if nbHoles > 0 then
                        moodle:setValue(0.3);--update has holes
                        moodle:setDescription(moodle:getGoodBadNeutral(), moodle:getLevel(), getText("Moodles_ClothingHole_Custom",tostring(nbHoles)));--update description
                    else
                        moodle:setValue(0.7);--update has no more holes
                        moodle:setDescription(moodle:getGoodBadNeutral(), moodle:getLevel(), "");--remove description
                    end
                    moodle:doWiggle();--force wiggling
                    AutoSewing.nbHolesForMoodle = nbHoles;--memo for on change detection
                    AutoSewing.manageTransientMoodle(moodle);
                end
            end
        end
    end

    function AutoSewing.manageTransientMoodle(moodle)
        local reconnectEvent = AutoSewing.hideTimeForMoodle <= 0;
        
        AutoSewing.hideTimeForMoodle = getTimestampMs()+AutoSewing.displayDelayForMoodle;--set end time
        
        if reconnectEvent then
            Events.OnPlayerUpdate.Add(AutoSewing.updatePlayerMoodle)
        end
    end
    
    Events.OnClothingUpdated.Add(AutoSewing.updateClothingHoleMoodle)


    function AutoSewing.updatePlayerMoodle(player)--manage the time to display only temporarily
        if getTimestampMs() > AutoSewing.hideTimeForMoodle then
            local moodle = MF.getMoodle("ClothingHole");--get access to the moodle
            if moodle then
                moodle:setValue(0.5)--hide
            end
            AutoSewing.hideTimeForMoodle = 0;
            Events.OnPlayerUpdate.Remove(AutoSewing.updatePlayerMoodle)--disconnect
        end
    end
end

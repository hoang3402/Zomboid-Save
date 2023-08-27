AutoMechanics = AutoMechanics or {}
AutoMechanics.OPTIONS = AutoMechanics.OPTIONS or {}
AutoMechanics.OPTIONS.Verbose = AutoMechanics.OPTIONS.Verbose or false;
AutoMechanics.OPTIONS.VerboseTimeSpeed = AutoMechanics.OPTIONS.VerboseTimeSpeed or false;
AutoMechanics.OPTIONS.WaitTicks = AutoMechanics.OPTIONS.WaitTicks or 7
AutoMechanics.DelayTimer = AutoMechanics.DelayTimer or 7
AutoMechanics.OPTIONS.FailThreshold = AutoMechanics.OPTIONS.FailThreshold or 6
AutoMechanics.OPTIONS.EndPause = AutoMechanics.OPTIONS.EndPause or true
AutoMechanics.OPTIONS.UntilSuccess = AutoMechanics.OPTIONS.UntilSuccess or true

--AutoMechanics "until success" management
AutoMechanics.untilSuccess = {}
AutoMechanics.untilSuccess.timeSpeed = 1
AutoMechanics.untilSuccess.part = nil
AutoMechanics.untilSuccess.player = nil
AutoMechanics.untilSuccess.item = nil

--AutoMechanics job management
AutoMechanics.uninstallOnly = false;
AutoMechanics.onAutoMechanicsTrain_started = false;
AutoMechanics.jobOrganisation = nil
function AutoMechanics.StopMechanicsTrain()
    local freeze = AutoMechanics.getEndPause()
    if AutoMechanics.onAutoMechanicsTrain_started == false then
        print ("ERROR AutoMechanics.StopMechanicsTrain called while not started.");
    end
    AutoMechanics.uninstallOnly = false;
    AutoMechanics.onAutoMechanicsTrain_started = false;
    AutoMechanics.jobOrganisation = nil
    if freeze == true then setGameSpeed(0);getGameTime():setMultiplier(1);--freeze game
    else setGameSpeed(1);getGameTime():setMultiplier(1); end--speed 1 game
    if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics.StopMechanicsTrain"); end
end

local function sortMechanicJobListByPosition(jobList, vehicle)
    local orderedJobList = {};
    local iterOrdered = 0
    local iterRaw = 0
    local iterRawDone = false
    local areaOrder = {"Engine", "TireFrontLeft", "SeatFrontLeft", "SeatMiddleLeft", "SeatRearLeft", "TireRearLeft", "TruckBed", "GasTank", "TireRearRight","SeatRearRight","SeatMiddleRight","SeatFrontRight","TireFrontRight"}
    for luaItArea, area in ipairs(areaOrder) do
        for luaItMb,partItMb in ipairs(jobList) do
            local part = vehicle:getPartByIndex(partItMb)
            if part:getArea() == area then
                table.insert(orderedJobList,partItMb)
                iterOrdered = iterOrdered + 1
                if AutoMechanics.OPTIONS.Verbose then print ("sortMechanicJobListByPosition : "..iterOrdered.." "..tostring(part:getItemType() or "nil").." "..part:getArea()) end
            end
            if not iterRawDone then iterRaw = iterRaw + 1 end
        end
        iterRawDone = true
    end
    if iterRaw ~= iterOrdered then --error
        print ("ERROR sortMechanicJobListByPosition sort "..iterOrdered.." items instead of "..iterRaw);
        if iterRaw > iterOrdered then
            
            for luaItMb,partItMb in ipairs(jobList) do
                local partIsSort = false
                for luaItSort,partItSort in ipairs(jobList) do
                    if partItMb == partItSort then
                        partIsSort = true
                        break
                    end
                end
                if not partIsSort then
                    table.insert(orderedJobList,partItMb)
                    local part = vehicle:getPartByIndex(partItMb)
                    print ("sortMechanicJobListByPosition : unexpected Area for"..tostring(part:getItemType() or "nil").." "..part:getArea())
                end
            end
        end
    end

    return orderedJobList
end

function startAutoMechanicsTraining(player,vehicle)
    local jobListAvailable = {}
    local jobListMaybe = {}
    local iterJobAvailable = 0
    local iterJobMaybe = 0
    for i=0,vehicle:getPartCount()-1 do
        local part = vehicle:getPartByIndex(i)
        local jobAvailability = AutoMechanics.getPartValidForTrainingState(player, part)
        if jobAvailability == 2 then
            iterJobAvailable = iterJobAvailable + 1--remember iterJobs is lua index
            jobListAvailable[iterJobAvailable] = i--remember i is java index
            if AutoMechanics.OPTIONS.Verbose then print ("startAutoMechanicsTraining Job available "..iterJobAvailable.." on partId "..i.." "..tostring(part)); end
        elseif jobAvailability == 1 then
            iterJobMaybe = iterJobMaybe + 1--remember iterJobs is lua index
            jobListMaybe[iterJobMaybe] = i--remember i is java index
            if AutoMechanics.OPTIONS.Verbose then print ("startAutoMechanicsTraining Job maybe "..iterJobMaybe.." on partId "..i.." "..tostring(part)); end
        else
            if AutoMechanics.OPTIONS.Verbose then print ("startAutoMechanicsTraining Job impossible on partId "..i.." "..tostring(part)); end
        end
    end
    
    jobListAvailable = sortMechanicJobListByPosition(jobListAvailable,vehicle)
    
    AutoMechanics.jobOrganisation = {}
    AutoMechanics.jobOrganisation.jobListAvailable = jobListAvailable--ok for main job list
    AutoMechanics.jobOrganisation.jobListMaybe = jobListMaybe--look for job dependency ? or maybe just reparse that table after each uninstall.
    AutoMechanics.jobOrganisation.jobListDone = {}--I prefer [keeping track of jobs done and wasting time parsing] to [managing lua table removing]
    AutoMechanics.jobOrganisation.jobListUninstalled = {}--I prefer [keeping track of jobs done and wasting time parsing] to [managing lua table removing]
    AutoMechanics.jobOrganisation.player = player
    AutoMechanics.jobOrganisation.vehicle = vehicle
    AutoMechanics.jobOrganisation.pendingJob = nil
    AutoMechanics.jobOrganisation.pendingPart = nil
    AutoMechanics.jobOrganisation.pendingTimeSpeed = 1;
    AutoMechanics.jobOrganisation.jobPriorityUninstall = nil
    AutoMechanics.jobOrganisation.jobPriorityInstall = nil
    AutoMechanics.jobOrganisation.currentArea = nil
    
    AutoMechanics.onAutoMechanicsTrain_started = true;
end
function AutoMechanics.isAutoMechanicsTrain_started()
    return AutoMechanics.onAutoMechanicsTrain_started
end
function AutoMechanics.getVehicle()
    return AutoMechanics.jobOrganisation.vehicle
end

function AutoMechanics.setPartUninstalled(uninstalledpart,vehicle)
    local partFound = false;
    for i=0,vehicle:getPartCount()-1 do
        local part = vehicle:getPartByIndex(i)
        if part == uninstalledpart then
            partFound = true;
            local wasJob = false
            if AutoMechanics.jobOrganisation.jobPriorityUninstall ~= nil and AutoMechanics.jobOrganisation.jobPriorityUninstall == i then
                AutoMechanics.jobOrganisation.jobPriorityUninstall = nil;
                AutoMechanics.jobOrganisation.jobPriorityInstall = i;
                wasJob = true;
            else
                for luaIt,partIt in ipairs(AutoMechanics.jobOrganisation.jobListAvailable) do
                    if partIt == i then
                        wasJob = true;
                        if AutoMechanics.OPTIONS.Verbose then print("AutoMechanics.setPartUninstalled job "..luaIt.." done, part "..i.." uninstalled."); end
                        table.insert(AutoMechanics.jobOrganisation.jobListUninstalled,i);
                        break;
                    end
                end
            end
            if not wasJob then--handle the error
                print ("ERROR AutoMechanics.setPartUninstalled job not found for part "..i);
            end
            break;
        end
    end
    if not partFound then--handle the error
        print ("ERROR AutoMechanics.setPartUninstalled part not found for "..tostring(uninstalledpart or "nil"));
    end
end

function AutoMechanics.setPartInstalled(installedpart,vehicle)
    local partFound = false;
    for i=0,vehicle:getPartCount()-1 do
        local part = vehicle:getPartByIndex(i)
        if part == installedpart then
            partFound = true;
            local wasJob = false
            if AutoMechanics.jobOrganisation.jobPriorityInstall ~= nil and AutoMechanics.jobOrganisation.jobPriorityInstall == i then
                AutoMechanics.jobOrganisation.jobPriorityInstall = nil;
                wasJob = true;
            else
                for luaIt,partIt in ipairs(AutoMechanics.jobOrganisation.jobListUninstalled) do
                    if partIt == i then
                        wasJob = true;
                        if AutoMechanics.OPTIONS.Verbose then print("AutoMechanics.setPartInstalled job "..luaIt.." done, part "..i.." installed."); end
                        table.insert(AutoMechanics.jobOrganisation.jobListDone,i);
                        break;
                    end
                end
            end
            if not wasJob then--handle the error
                print ("ERROR AutoMechanics.setPartInstalled job not found for part "..i);
            end
            break;
        end
    end
    if not partFound then--handle the error
        print ("ERROR AutoMechanics.setPartInstalled part not found for "..tostring(installedpart or "nil"));
    end
end

--AutoMechanics training
function ISVehicleMechanics:onAutoMechanicsTrain(player,vehicle)
    if AutoMechanics.OPTIONS.Verbose then print("ISVehicleMechanics:onAutoMechanicsTrain "..tostring(vehicle)); end

    AutoMechanics.uninstallOnly = false;--whatever the previous state we are currently training
    startAutoMechanicsTraining(player,vehicle)--organise the job
    AutoMechanics.doPendingJob(player,vehicle);--go to work Kaylee Frye !
end

--AutoMechanics uninstall all
function ISVehicleMechanics:onAutoMechanicsUninstallAll(player,vehicle)
    if AutoMechanics.OPTIONS.Verbose then print("ISVehicleMechanics:onAutoMechanicsUninstallAll "..tostring(vehicle)); end

    AutoMechanics.uninstallOnly = true;--whatever the previous state we are currently training
    startAutoMechanicsTraining(player,vehicle)--organise the job
    AutoMechanics.doPendingJob(player,vehicle);--go to work Kaylee Frye !
end


function AutoMechanics.doPendingJob(player,vehicle)
    local jobOrganisation = AutoMechanics.jobOrganisation;
    if not jobOrganisation then
        print ("ERROR AutoMechanics.doPendingJob with job organisation.");
        return
    end
    
    if not player then player = AutoMechanics.jobOrganisation.player end
    if not vehicle then vehicle = AutoMechanics.jobOrganisation.vehicle end
    
    --uninstall first job available
    local invalidPartId = vehicle:getPartCount();
    local partIdToDo = invalidPartId;
    local doInstall = false;
    
    if AutoMechanics.jobOrganisation.jobPriorityUninstall ~= nil then
        partIdToDo = AutoMechanics.jobOrganisation.jobPriorityUninstall;
        if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics.doPendingJob Uninstall Priority part "..partIdToDo);end
    elseif AutoMechanics.jobOrganisation.jobPriorityInstall ~= nil then
        partIdToDo = AutoMechanics.jobOrganisation.jobPriorityInstall;
        if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics.doPendingJob Install Priority part "..partIdToDo);end
        doInstall = true;
    else
        for luaIt,partIt in ipairs(jobOrganisation.jobListAvailable) do
            local alreadyDone = false
            for luaItDone,partItDone in ipairs(jobOrganisation.jobListDone) do
                if partIt == partItDone then
                    alreadyDone = true;
                    break
                end
            end
            --decide if we need to install, uninstall or do a dependency search on jobListMaybe
            if alreadyDone == false then
                local alreadyUninstalled = false
                for luaItUn,partItUn in ipairs(jobOrganisation.jobListUninstalled) do
                    if partIt == partItUn then
                        alreadyUninstalled = true;
                        break
                    end
                end
                if alreadyUninstalled then--that's the time to do a dependency search
                    local maybeJobAvailable = false
                    for luaItMb,partItMb in ipairs(jobOrganisation.jobListMaybe) do
                        local part = vehicle:getPartByIndex(partItMb)
                        local jobAvailability = AutoMechanics.getPartValidForTrainingState(player, part)
                        if jobAvailability == 2 then
                            jobOrganisation.jobListMaybe[luaItMb] = invalidPartId;
                            jobOrganisation.jobPriorityUninstall = partItMb;
                            maybeJobAvailable = true
                            partIt = partItMb--start doing it now in priority
                            if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics.doPendingJob Activate and Uninstall maybe part "..partIt);end
                            break
                        end
                    end
                    if not maybeJobAvailable then
                        if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics.doPendingJob Install part "..partIt);end
                        doInstall = true;--for now we just do install
                    end
                else
                    if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics.doPendingJob Uninstall part "..partIt);end
                
                end
                
                partIdToDo = partIt;
                break;
            end
        end
    end
    
    if partIdToDo == invalidPartId then --job is done
        if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics.doPendingJob job's done"); end
        AutoMechanics.StopMechanicsTrain()
        return
    end
    
    local part = vehicle:getPartByIndex(partIdToDo);
    if not part then --Bug
        print ("ERROR AutoMechanics.doPendingJob job's bugged invalid part id "..partIdToDo);
        AutoMechanics.StopMechanicsTrain()
        return
    end
    
    if doInstall then
        local item = getAnyItemOnPlayerThatMatchesThatPart(player, part);
        local isInstallStillPossible = part:getVehicle():canInstallPart(player, part);--it was possible at start but it can have changed. e.g. for a wheel if we broke suspension
        if not AutoMechanics.uninstallOnly and item and isInstallStillPossible then
            
            --avoid useless movements when area has not changed
            local targetArea = part:getArea();
            local sameArea = targetArea == AutoMechanics.jobOrganisation.currentArea;--compare previous and target
            AutoMechanics.jobOrganisation.currentArea = targetArea;--save area for next action
            local vanilla_ISPathFindAction_pathToVehicleArea = ISPathFindAction.pathToVehicleArea--store for unhook
            if sameArea then ISPathFindAction.pathToVehicleArea = ISPathFindAction.pathToVehicleArea_inactive end --hook to inhibit
            
            if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics.doPendingJob Install part it "..partIdToDo.." on area "..tostring(targetArea)..tostring(sameArea and " unchanged" or " changed") );end
            
            ISVehiclePartMenu.onInstallPart(player, part, item);--asynchronous job start vanilla way
            
            if sameArea then ISPathFindAction.pathToVehicleArea = vanilla_ISPathFindAction_pathToVehicleArea end --unhook
            
        else
            if AutoMechanics.OPTIONS.Verbose and not isInstallStillPossible then print ("AutoMechanics.doPendingJob job Install not possible, missing access to the part for it "..partIdToDo); end
            if AutoMechanics.OPTIONS.Verbose and isInstallStillPossible and not AutoMechanics.uninstallOnly then print ("AutoMechanics.doPendingJob job Install not possible, missing valid item for part it "..partIdToDo); end
            if AutoMechanics.OPTIONS.Verbose and AutoMechanics.uninstallOnly then print ("AutoMechanics.doPendingJob job not reinstalling as requested by Deadly_Shadow "..partIdToDo); end
            
            --Test auto drop
            if not isInstallStillPossible then
                AutoMechanics.dropItem(player, item);
            end
            
            AutoMechanics.setPartInstalled(part,vehicle);--only uninstall or we probably just removed a broken item set jobs done for this part
            
            AutoMechanics.doPendingJob(player,vehicle)--go to next part
        end
    else
        if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics.doPendingJob Uninstall part it "..partIdToDo);end
        
        --avoid useless movements when area has not changed
        local targetArea = part:getArea();
        local sameArea = targetArea == AutoMechanics.jobOrganisation.currentArea;--compare previous and target
        AutoMechanics.jobOrganisation.currentArea = targetArea;--save area for next action
        local vanilla_ISPathFindAction_pathToVehicleArea = ISPathFindAction.pathToVehicleArea--store for unhook
        if sameArea then ISPathFindAction.pathToVehicleArea = ISPathFindAction.pathToVehicleArea_inactive end --hook to inhibit
        
        ISVehiclePartMenu.onUninstallPart(player, part);--asynchronous job start vanilla way
        
        if sameArea then ISPathFindAction.pathToVehicleArea = vanilla_ISPathFindAction_pathToVehicleArea end --unhook
    end
    
    if AutoMechanics.OPTIONS.VerboseTimeSpeed then print ("AutoMechanics.doPendingJob timespeed = "..getGameTime():getTrueMultiplier()) end
end

function AutoMechanics.getPlayerFastestItemAnyInventory(player,itemType)
    return player:getInventory():getFirstTypeRecurse(itemType);
end

function AutoMechanics.getPartValidForTrainingState(player, part)
    if not part then return 0 end
    if AutoMechanics.OPTIONS.Verbose then
        local itemType = part:getItemType();
        local isEmpty = "true"
        if not itemType then
            itemType = "nil"
        else
            isEmpty = (not part:getItemType():isEmpty()) and "false" or "true"
        end
        local partInventoryItem = part:getInventoryItem() or "nil"
        print ("AutoMechanics.isPartValidForTraining "..tostring(part)
        .." itemType="..tostring(itemType)
        .." isEmpty="..tostring(isEmpty)
        .." invItem="..tostring(partInventoryItem)
        .." hasTable="..(part:getTable('uninstall')~=nil and "true" or "false")
        .." canUninstall="..(part:getVehicle():canUninstallPart(player, part) and "true" or "false")
        );
    end
    
    local isUninstallable = part:getItemType() and not part:getItemType():isEmpty() and part:getInventoryItem() and part:getTable('uninstall');--notice we use only the uninstall table. this may break over time.
    isUninstallable = isUninstallable and AutoMechanics.getConditionLossPercentage(player, part) <= AutoMechanics.getConditionLossPercentageThreshold();--so we filter on perk level at start. we won't do it if we get the required level during that session.
    local isUninstallableNow = isUninstallable and part:getVehicle():canUninstallPart(player, part)

    if isUninstallableNow then return 2; end--ok for main job list
    if isUninstallable then return 1; end--look for job dependency ? or maybe just reparse that table after each uninstall.
    return 0;--do not train on that part
end

local function getStrParam(param)
    if not param then return " nil" end
    return " "..tostring(param)
end

function AutoMechanics.getConditionLossPercentage(player, part)--returns 0 when part condition cannot decrease on install/uninstall action.
    local installTable = part:getTable('uninstall')
    if not installTable then
        installTable = part:getTable('install')--some mods break install table but not uninstall one
    end
    if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics.getConditionLossPercentage "..tostring(installTable or 'nil')); end
    local success, failure = false, true
    if installTable then
        local perks = installTable.skills;--notice we use only the install table (like VehicleCommands). this may break over time.
        local perksTable = VehicleUtils.getPerksTableForChr(perks, player)
        success, failure = VehicleUtils.calculateInstallationSuccess(perks, player, perksTable);
    end
    if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics.getConditionLossPercentage"..getStrParam(player)..getStrParam(failure)..getStrParam(part:getItemType())); end
    return failure
end

function getAnyItemOnPlayerThatMatchesThatPart(player, part)
    local typeToItem = VehicleUtils.getItems(player:getPlayerNum())
    -- among all possible items that can be installed on that part
    for i=0,part:getItemType():size() - 1 do
        local name = part:getItemType():get(i);
        local item = InventoryItemFactory.CreateItem(name);
        if item then name = item:getName(); end
        --if any type is owned by the player
        if typeToItem[part:getItemType():get(i)] then
            for j,v in ipairs(typeToItem[part:getItemType():get(i)]) do
                return v;--return first valid item met
            end
        end
    end
    return nil
end
function AutoMechanics.gameSpeedMultiplierToGameSpeed(multiplier)
    if multiplier == 40 then return 4 end
    if multiplier == 20 then return 3 end
    if multiplier == 5 then return 2 end
    if multiplier ~= 1 then print ("AutoMechanics.gameSpeedMultiplierToGameSpeed set speed 1 for multiplier "..tostring(multiplier or "nil")) end
    return 1
end

-- local isB41OrAfter = nil
-- local function isVersionPostB41()
    -- if isB41OrAfter == nil then
        -- local ver_str = getCore():getVersionNumber()
        -- local num1, num2 = ver_str:match("(%d+)%.(%d+)")
        -- num1 = tonumber(num1)
        -- num2 = tonumber(num2)
        -- if num1 >= 41 and num2 < 60 then
            -- isB41OrAfter = true
        -- else
            -- isB41OrAfter = false
        -- end
    -- end
    -- return isB41OrAfter
-- end

function AutoMechanics.OnMechanicActionDone(player,success,vehicleId,partName,itemId,installing,param7)
    if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics.OnMechanicActionDone"..getStrParam(player)..getStrParam(success)..getStrParam(vehicleId)..getStrParam(partName)..getStrParam(itemId)..getStrParam(installing)..getStrParam(param7)); end
    if AutoMechanics.onAutoMechanicsTrain_started and AutoMechanics.jobOrganisation.player == player then
        local vehicle = AutoMechanics.jobOrganisation.vehicle
        if AutoMechanics.jobOrganisation.pendingJob and AutoMechanics.jobOrganisation.pendingPart then
            local part = AutoMechanics.jobOrganisation.pendingPart
            if AutoMechanics.jobOrganisation.pendingJob == "Install" then
                AutoMechanics.jobOrganisation.pendingJob = nil;
                if success and itemId ~= -1 then
                    AutoMechanics.setPartInstalled(part,vehicle);
                end
            elseif AutoMechanics.jobOrganisation.pendingJob == "Uninstall" then
                AutoMechanics.jobOrganisation.pendingJob = nil;
                if success and itemId ~= -1 then
                    AutoMechanics.setPartUninstalled(part,vehicle);
                    
                    local invItem = AutoMechanics.getInventoryItem(player, itemId)
                    if invItem and (AutoMechanics.uninstallOnly or invItem:isBroken()) then --drop the item when uninstalling or when item is broken
                        AutoMechanics.dropItem(player, invItem)
                    end
                end
            else
                print ("ERROR AutoMechanics.OnMechanicActionDone called with invalid pendingJob "..AutoMechanics.jobOrganisation.pendingJob);
                AutoMechanics.StopMechanicsTrain();
                return
            end
        else
            print ("ERROR AutoMechanics.OnMechanicActionDone called while no pendingJob.");
            AutoMechanics.StopMechanicsTrain();
            return
        end
        if AutoMechanics.OPTIONS.VerboseTimeSpeed then print ("AutoMechanics.OnMechanicActionDone timespeed = "..getGameTime():getTrueMultiplier()) end
        if AutoMechanics.jobOrganisation.pendingTimeSpeed > getGameTime():getTrueMultiplier() then
            --re-activate the game speed we had before vanilla deactivated it
            setGameSpeed(AutoMechanics.gameSpeedMultiplierToGameSpeed(AutoMechanics.jobOrganisation.pendingTimeSpeed));
            getGameTime():setMultiplier(AutoMechanics.jobOrganisation.pendingTimeSpeed);
        end

        AutoMechanics.DelayTimer = AutoMechanics.getWaitCycle()
        Events.OnTick.Add(AutoMechanics.OnTick);-- Timed callback
        
    elseif AutoMechanics.doUntilSuccess() and not success and not AutoMechanics.onAutoMechanicsTrain_started then
        local part = AutoMechanics.untilSuccess.part
        if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics.OnMechanicActionDone, starting repeat "..tostring(installing and "install" or "unsinstall").." for part="..tostring(part or "nil").." timespeed="..tostring(AutoMechanics.untilSuccess.timeSpeed or "nil")); end
        if part and player == AutoMechanics.untilSuccess.player then
            AutoMechanics.DelayTimer = AutoMechanics.getWaitCycle()
            AutoMechanics.untilSuccess.isInstall = installing
            if itemId then AutoMechanics.untilSuccess.item = AutoMechanics.getInventoryItem(player, itemId) end--the item can change on server side
            Events.OnTick.Add(AutoMechanics.OnTickUntilSuccess);-- Timed callback
            
            if AutoMechanics.untilSuccess.timeSpeed and AutoMechanics.untilSuccess.timeSpeed > getGameTime():getTrueMultiplier() then
                --re-activate the game speed we had before vanilla deactivated it
                setGameSpeed(AutoMechanics.gameSpeedMultiplierToGameSpeed(AutoMechanics.untilSuccess.timeSpeed));
                getGameTime():setMultiplier(AutoMechanics.untilSuccess.timeSpeed);
            end
        end
    end
end

local function getTableString(object)
    if type(object) == "table" then
        local str = nil
        for key,subObj in pairs(object) do
            if str == nil then str = '[' else str = str..',' end
            str = str..getTableString(key)..'='..getTableString(subObj)
        end
        if str == nil then return "" else return str..']' end
    else
        return tostring(object)
    end
end

--this allows to continue until success (with a delay)
AutoMechanics.OnTickUntilSuccess = function ()
    if AutoMechanics.DelayTimer <= 0 then
        if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics.OnTickUntilSuccess, starting delayed job "..getTableString(AutoMechanics.untilSuccess)); end
        Events.OnTick.Remove(AutoMechanics.OnTickUntilSuccess);
        if AutoMechanics.untilSuccess.isInstall then
            local item = AutoMechanics.untilSuccess.item
            if item and not item:isBroken() then
                --ISVehiclePartMenu.onInstallPart(AutoMechanics.untilSuccess.player, AutoMechanics.untilSuccess.part, item)
                local playerObj = AutoMechanics.untilSuccess.player
                local part = AutoMechanics.untilSuccess.part
                local keyvalues = part:getTable('install')
                local time = tonumber(keyvalues.time) or 50
                ISTimedActionQueue.add(ISInstallVehiclePart:new(playerObj, part, item, time))
            else
                stop = true
            end
        else
            --ISVehiclePartMenu.onUninstallPart(AutoMechanics.untilSuccess.player, AutoMechanics.untilSuccess.part)
            local playerObj = AutoMechanics.untilSuccess.player
            local part = AutoMechanics.untilSuccess.part
            local keyvalues = part:getTable('uninstall')
            local time = tonumber(keyvalues.time) or 50
            ISTimedActionQueue.add(ISUninstallVehiclePart:new(playerObj, part, time))
        end
    end
    AutoMechanics.DelayTimer = AutoMechanics.DelayTimer - 1
    
    if stop then
        AutoMechanics.untilSuccess.timeSpeed = 1
        setGameSpeed(1);getGameTime():setMultiplier(1);
    else
        if AutoMechanics.untilSuccess.timeSpeed and AutoMechanics.untilSuccess.timeSpeed > getGameTime():getTrueMultiplier() then
            --re-activate the game speed we had before vanilla deactivated it
            setGameSpeed(AutoMechanics.gameSpeedMultiplierToGameSpeed(AutoMechanics.untilSuccess.timeSpeed));
            getGameTime():setMultiplier(AutoMechanics.untilSuccess.timeSpeed);
        end
    end
end


--this allows to continue the training / uninstalling job (with a delay)
AutoMechanics.OnTick = function ()
    if AutoMechanics.DelayTimer <= 0 then
        if AutoMechanics.OPTIONS.Verbose then print ("AutoMechanics.OnTick, starting delayed job"); end
        Events.OnTick.Remove(AutoMechanics.OnTick);
        --if new broken item, drop it
        AutoMechanics.dropBrokenItems(AutoMechanics.jobOrganisation.player)
        AutoMechanics.doPendingJob(nil,nil)--try again or do next job
    end
    AutoMechanics.DelayTimer = AutoMechanics.DelayTimer - 1
end


function AutoMechanics.dropBrokenItems(player)
    local playerInv = player:getInventory();
    local it = playerInv:getItems()
    local initialInvLastIt = it:size()-1;
    for i = 0, initialInvLastIt do
        local item = it:get(initialInvLastIt-i)--decreasing loop because we are potentially removing the item we look at
        if item:isBroken() then
            local square = player:getCurrentSquare()
            square:AddWorldInventoryItem(item, 0,0,0);
            playerInv:Remove(item);
        end
    end
end
function AutoMechanics.getInventoryItem(player, itemId)--returns the item only if it is in player main inventory
    local playerInv = player:getInventory();
    local it = playerInv:getItems()
    local initialInvLastIt = it:size()-1;
    for i = 0, initialInvLastIt do
        local item = it:get(initialInvLastIt-i)--decreasing loop because we were potentially removing the item [OBSOLETE]
        if item:getID() == itemId then
            return item
        end
    end
    return nil
end

function AutoMechanics.dropItem(player, invItem)
    if invItem and player and player:getInventory():contains(invItem) then
        local square = player:getCurrentSquare()
        local playerInv = player:getInventory();
        invItem:getContainer():setDrawDirty(true);
        invItem:setJobDelta(0.0);
        playerInv:Remove(invItem);
        local dropX,dropY,dropZ = ISInventoryTransferAction.GetDropItemOffset(player, square, invItem)--some random position around the player
        square:AddWorldInventoryItem(invItem, dropX,dropY,dropZ);
        ISInventoryPage.renderDirty = true
        ISInventoryPage.dirtyUI();--set inventory dirty to force loot window recomputation: FAILED
    end
end

local keyEscape = Keyboard.KEY_ESCAPE
function AutoMechanics.OnKeyStartPressed(key)
    if key == keyEscape and AutoMechanics.onAutoMechanicsTrain_started then
        AutoMechanics.StopMechanicsTrain()
    end
end


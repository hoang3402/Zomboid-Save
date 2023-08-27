require("Unpack/Constants");
require("Unpack/Settings");

---
--
function Unpack:isFloor(item) 
    return item:getType() == "floor";
end

---
--
function Unpack:isKeyRing(item) 
    return item:getType() == "KeyRing";
end

---
--
function Unpack:isEmpty(itemContainer)
    return itemContainer:getItems():isEmpty();
end

---
--
function Unpack:isContainer(object)
    return object and object:getCategory() == "Container";
end

---
--
function Unpack:isExcludedContainer(itemType)
    local excludeMannequins = Unpack.Settings:Get(Unpack.EXCLUDE_MANNEQUIN_CONTAINER);
    local excludeTrash = Unpack.Settings:Get(Unpack.EXCLUDE_TRASH_CONTAINER);
    if itemType == "mannequin" and excludeMannequins then
        return true;
    elseif itemType == "bin" and excludeTrash then
        return true;
    end
    return false;
end

---
--
function Unpack:getItemCategory(item)
    return item:getDisplayCategory() or tostring(item:getCategory());
end

---
--
function Unpack:shouldIgnoreItem(player, item)
    return item:isFavorite() or player:isAttachedItem(item) or player:isEquipped(item) or ISHotbar:isInHotbar(item) or Unpack:isKeyRing(item);
end

---
--
function Unpack:getCategorySetting(category)
    local categoryPercentSetting = Unpack.Settings:Get("CATEGORY_" .. string.upper(category));
    if not categoryPercentSetting then 
        -- sanity check
        categoryPercentSetting = Unpack.Settings:Get(Unpack.CATEGORY_SPECIALIZATION_DEFAULT_PERCENT);
    elseif categoryPercentSetting == "Off" then
        categoryPercentSetting = "200%";
    end
    return tonumber(string.sub(categoryPercentSetting, 1, string.len(categoryPercentSetting)-1));
end

---
--
function Unpack:getContainerCategoryPercent(node, category)
    -- what percentage of the container is dedicated to this item's category?
    local percentageOfContainer = node.categoryPercentageMap[category];
    if percentageOfContainer == nil then
        -- if nil, then the user has turned this feature off, 
        -- or there just aren't any items of this type. so zero.
        percentageOfContainer = -1;
    end
    return percentageOfContainer;
end

---
--
function Unpack:getNearbyContainers(playerNumber)
    local containerList = {};
    -- TODO: these direct member references are bad; is there an interface to get what I need here?
    for i,v in ipairs(getPlayerLoot(playerNumber).inventoryPane.inventoryPage.backpacks) do
        local inventory = v.inventory;
        local t = inventory:getType();
        if not (Unpack:isFloor(inventory) or Unpack:isExcludedContainer(t)) then
            containerList[i] = v.inventory;
        end
    end
    return containerList;
end

---
--
function Unpack:getInventoryList(playerNumber)
    local containerList = {};
    -- TODO: these direct member references are bad; is there an interface to get what I need here?
    for i,v in ipairs(getPlayerInventory(playerNumber).inventoryPane.inventoryPage.backpacks) do
        local inventory = v.inventory;
        local item = inventory:getContainingItem();
        local isFavorite = item ~= nil and item:isFavorite();

        if not Unpack:isKeyRing(inventory) and not isFavorite then
            containerList[i] = inventory;
        end
    end
    return containerList;
end

---
--
function Unpack:moveItemToContainer(player, item, itemContainer)
    if itemContainer:hasRoomFor(player, item) then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, item:getContainer(), itemContainer))
        return true;
    end
    return false;
end

---
--
function Unpack:containerHasItemsToMove(player, sourceContainer, containerMap)
    local itemIter = sourceContainer:getItems();
    for i = 0, itemIter:size()-1 do
        local item = itemIter:get(i);
        local category = Unpack:getItemCategory(item);
        if not Unpack:shouldIgnoreItem(player, item) then
            local shouldTry = true;

            -- handle container/clothing items properly
            local originalItem = item;
            if Unpack:isContainer(item) and Unpack:isEmpty(item:getInventory()) then
                item = item:getInventory();
            end

            for k,node in pairs(containerMap) do
                local setting = Unpack:getCategorySetting(category);
                local containerPercent = Unpack:getContainerCategoryPercent(node, category);
                local container = node.container;
                if containerPercent >= setting or container:contains(item:getType()) then
                    if container:hasRoomFor(player, originalItem) then
                        -- we have at least one item we can move, bail true
                        return true;
                    end
                end
            end
        end
    end

    -- worst case scenario, we went through all items and found nothing we could move..
    return false;
end

---
--
function Unpack:preProcessNearbyContainers(nearbyContainers)
    local containerMap = {};

    local setting = Unpack.Settings:Get(Unpack.CATEGORY_SPECIALIZATION_MIN);

    -- preprocess nearby containers once first to see
    -- if they specialize in any one item category
    for i,container in ipairs(nearbyContainers) do
        local items = container:getItems();
        local itemCount = items:size();
        local percentageMap = {};

        local duplicateCount = 0;
        if not (setting == "Off") then
            -- get the numeric setting value
            setting = tonumber(setting);

            -- NEW IMPL: capture the percentage of all item categories
            local catCountMap = {};
            local typeCountMap = {};
            local uniqueTypeCount = 0;
            for j=0,itemCount-1 do
                local item = items:get(j);

                -- capture unique item for percentage calculation below
                local itemType = item:getType();
                if not typeCountMap[itemType] then
                    typeCountMap[itemType] = true;
                    uniqueTypeCount = uniqueTypeCount + 1;
                    local itemCat = Unpack:getItemCategory(item);
                    local value = catCountMap[itemCat];
                    if not value then
                        value = 0;
                        catCountMap[itemCat] = 0;
                    end
                    catCountMap[itemCat] = value + 1;
                end
            end

            -- convert to percentage
            for cat,value in pairs(catCountMap) do
                if Unpack:getCategorySetting(cat) > 0 then
                    local pct = value / uniqueTypeCount * 100;
                    percentageMap[cat] = pct;
                end
            end
        else
            -- short-circuit our duplicateCount check below if this setting is off
            setting = -1;
        end

        local containerNode = {
            container = container,
            categoryPercentageMap = {}
        };

        -- 
        if itemCount >= setting then
            containerNode.categoryPercentageMap = percentageMap;
        end

        containerMap[tostring(container)] = containerNode;
    end
    return containerMap;
end

---
--
function Unpack:transferItems(player, sourceContainer, nearbyContainerMap)
    -- we will keep track of containers in the player's
    -- inventory in this table, and return them
    local containers = {};
    local containerSize = 0;

    -- loop through items in this ItemContainer, and add them to an indexed table
    local itemIter = sourceContainer:getItems();
    local items = {};
    for i = 0, itemIter:size()-1 do
        local item = itemIter:get(i);
        table.insert(items, item);
    end

    -- sort so we visit items by weight (in descending order) and...
    table.sort(items, function(lhs, rhs) 
        return lhs:getUnequippedWeight() > rhs:getUnequippedWeight();
    end);

    -- loop over items in this player inventory container
    for _,item in ipairs(items) do
        -- do we care about this category?
        local itemCategory = Unpack:getItemCategory(item);
        local categoryPercentSetting = Unpack:getCategorySetting(itemCategory);

        -- go through only non-favorite items
        if not Unpack:shouldIgnoreItem(player, item) then
            local inventory = nil;

            -- if this is a container, keep track of the InventoryItem instance for helper calls below
            if Unpack:isContainer(item) then
                inventory = item:getInventory();
            end

            -- if this is a container (but not the keyring), keep track of it for our return list
            if inventory and not Unpack:isEmpty(inventory) and not Unpack:isKeyRing(inventory) then
                table.insert(containers, item);
            else
                -- go through our nearby containers and try to stash this item
                for k,node in pairs(nearbyContainerMap) do
                    local container = node.container;

                    -- what percentage of the container is dedicated to this item's category?
                    local percentageOfContainer = Unpack:getContainerCategoryPercent(node, itemCategory);
                    if container:contains(item:getType()) or percentageOfContainer >= categoryPercentSetting then
                        if Unpack:moveItemToContainer(player, item, container) then
                            break;
                        end
                    end
                end
            end
        end
    end

    -- return any containers we found
    return containers;
end

---
--
function newLootNode(inventory, square, containerName)
    local node = {};
    node.sq = square;
    node.inventory = inventory;
    node.containerName = containerName;
    return node;
end

---
--
function Unpack:GetLootInSurroundingSquares(playerNumber, worldobjects)
    local lootInventoryTable = {};
    local player = getSpecificPlayer(playerNumber);
    local loot = worldobjects[1];
    if loot then
        local kbLootInventory = loot:getContainer();

        -- if lootInventory is nil, then the user seems to be using a controller. we'll scan for worldobjectts ourselves in this case
        if kbLootInventory then
            table.insert(lootInventoryTable, kbLootInventory);
        else
            ---
            -- this code shamelessly taken from ISInventoryPage.lua from PZ lua source
            ---
            
            -- let's look at the squares around us, and find world object containers on them. we'll
            -- return this same list of world containers around the player
            local squareList = {};
            local dir = player:getDir();
            local dx,dy = 0,0;
            local cx,cy,cz = player:getX(),player:getY(),player:getZ();
            if dir == IsoDirections.NW or dir == IsoDirections.W or dir == IsoDirections.SW then
                dx = -1;
            end
            if dir == IsoDirections.NE or dir == IsoDirections.E or dir == IsoDirections.SE then
                dx = 1;
            end
            if dir == IsoDirections.NW or dir == IsoDirections.N or dir == IsoDirections.NE then
                dy = -1;
            end
            if dir == IsoDirections.SW or dir == IsoDirections.S or dir == IsoDirections.SE then
                dy = 1;
            end

            for dy=-1,1 do
                for dx=-1,1 do
                    local square = getCell():getGridSquare(cx + dx, cy + dy, cz);
                    if square then
                        local node = {};
                        node.sq = square;
                        table.insert(squareList, node);
                    end
                end
            end

            local vehicleContainers = {};
            for _,node in ipairs(squareList) do
                local gs = node.sq;

                -- stop grabbing thru walls...
                local currentSq = player:getCurrentSquare();
                if gs ~= currentSq and currentSq and currentSq:isBlockedTo(gs) then
                    gs = nil;
                end

                -- don't show containers in safehouse if you're not allowed
                if gs and isClient() and SafeHouse.isSafeHouse(gs, player:getUsername(), true) and not getServerOptions():getBoolean("SafehouseAllowLoot") then
                    gs = nil;
                end

                -- can we access this square?
                if gs ~= nil then
                    local wobs = gs:getWorldObjects();
                    for i = 0, wobs:size()-1 do
                        local o = wobs:get(i);
                        if o:getItem() and o:getItem():getCategory() == "Container" then
                            local item = o:getItem();
                            table.insert(lootInventoryTable, newLootNode(item:getInventory(), gs));
                        end
                    end

                    local sobs = gs:getStaticMovingObjects();
                    for i = 0, sobs:size()-1 do
                        local so = sobs:get(i);
                        if so:getContainer() ~= nil then
                            table.insert(lootInventoryTable, newLootNode(so:getContainer(), gs));
                        end
                    end

                    local obs = gs:getObjects();
                    for i = 0, obs:size()-1 do
                        local o = obs:get(i)
                        for containerIndex = 1,o:getContainerCount() do
                            table.insert(lootInventoryTable, newLootNode(o:getContainerByIndex(containerIndex-1), gs));
                        end
                    end

                    local vehicle = gs:getVehicleContainer();
                    if vehicle and not vehicleContainers[vehicle] then
                        vehicleContainers[vehicle] = true;
                        for partIndex=1,vehicle:getPartCount() do
                            local vehiclePart = vehicle:getPartByIndex(partIndex-1)
                            if vehiclePart:getItemContainer() and vehicle:canAccessContainer(partIndex-1, player) then
                                table.insert(lootInventoryTable, newLootNode(vehiclePart:getItemContainer(), gs, "IGUI_VehiclePart" .. vehiclePart:getItemContainer():getType()));
                            end
                        end
                    end
                end
            end
        end
    end
    return lootInventoryTable;
end

---
--
function Unpack:DoStock(player, playerInventoryList, containerMap)
    -- grab our equipped containers
    local primary = player:getPrimaryHandItem();
    local secondary = player:getSecondaryHandItem();
    local back = player:getClothingItem_Back();

    -- loop through our inventory and move items
    for _,inventory in pairs(playerInventoryList) do
        local nestedContainers = Unpack:transferItems(player, inventory, containerMap);
        if nestedContainers ~= nil then
            for j,nestedContainer in pairs(nestedContainers) do
                if Unpack:containerHasItemsToMove(player, nestedContainer:getInventory(), containerMap) then
                    local nestedInventory = nestedContainer:getInventory();

                    -- skip this container if it is favorite'd
                    local item = nestedInventory:getContainingItem();
                    if not Unpack:shouldIgnoreItem(player, item) then
                        -- drop the bag on the floor
                        ISInventoryPaneContextMenu.dropItem(item, 0);

                        -- transfer items from the nested bag
                        Unpack:transferItems(player, nestedInventory, containerMap);

                        -- find the floor...there is probably a better way to do this.
                        local floor = nil;
                        for _,container in ipairs(getPlayerLoot(player:getPlayerNum()).inventoryPane.inventoryPage.backpacks) do
                            if Unpack:isFloor(container.inventory) then
                                floor = container.inventory;
                                break;
                            end
                        end

                        -- then move it back to its original parent container
                        ISTimedActionQueue.add(ISInventoryTransferAction:new(player, nestedInventory:getContainingItem(), floor, inventory));
                    end
                end
            end
        end
    end

    if secondary ~= nil then
        ISWorldObjectContextMenu.equip(player, nil, secondary, false, false);
    end

    if primary ~= nil then
        if instanceof(primary, "HandWeapon") and primary:isTwoHandWeapon() and not secondary then
            twoHands = true;
        end
        ISWorldObjectContextMenu.equip(player, nil, primary, true, twoHands);
    end
end


---
--
function Unpack:InitOptions()
    local Settings = Unpack.Settings;

    -- load settings
    Settings:Deserialize();

    local categories = {};
    local percentages = {};
    local allScriptItems = getScriptManager():getAllItems();
    for i=1,allScriptItems:size() do
        local scriptItem = allScriptItems:get(i-1);
        local cat = scriptItem:getDisplayCategory() or tostring(scriptItem:getType());
        if cat and not percentages[cat] then
            table.insert(categories, cat);
            local settingPercent = Settings:Get("CATEGORY_" .. string.upper(cat));
            if not settingPercent then
                settingPercent = Settings:Get(Unpack.CATEGORY_SPECIALIZATION_DEFAULT_PERCENT);
            end
            percentages[cat] = settingPercent
        end
    end

    -- add our settings tab
    MainOptions.instance:addPage(Unpack.NAME .. " Mod");
    MainOptions.instance.addY = 0;

    -- build UI for settings...hack hack hack
    local splitpoint = MainOptions.instance:getWidth() / 3;
    local comboWidth = MainOptions.instance:getWidth()-splitpoint - 100;
    local comboWidth = 300;
    local delta = 20;
    local padding = 6;
    local ypos = delta;
    local scrollHeight = ypos;
    local function addScrollHeight(amount)
        scrollHeight = scrollHeight + delta + amount + padding;
    end

    -- disable custom category checkbox
    local disableCustomCategories = MainOptions.instance:addYesNo(splitpoint, ypos, comboWidth, 20, getText(Unpack.UI_MenuOptions_DisableItemCategories));
    disableCustomCategories.tooltip = getText(Unpack.UI_MenuOptions_DisableItemCategoriesTooltip);
    local disableCustomCategoriesOption = Unpack.GameOption:new('disableCustomCategories', disableCustomCategories);
    function disableCustomCategoriesOption:toUI()
        local value = Settings:GetBool(Unpack.OVERRIDE_BASE_CATEGORIES);
        self.control:setSelected(1, not value);
    end
    function disableCustomCategoriesOption:apply()
        local value = self.control.options[self.control.selected];
        Settings:Set(Unpack.OVERRIDE_BASE_CATEGORIES, not self.control:isSelected(1));
        Settings:Serialize();
    end
    MainOptions.instance.gameOptions:add(disableCustomCategoriesOption);
    ypos = ypos + delta;
    addScrollHeight(disableCustomCategories:getHeight());

    -- ignore mannequins
    local ignoreMannequins = MainOptions.instance:addYesNo(splitpoint, ypos, comboWidth, 20, getText(Unpack.UI_MenuOptions_ExcludeMannequinContainer));
    ignoreMannequins.tooltip = getText(Unpack.UI_MenuOptions_ExcludeMannequinContainerTooltip);
    local ignoreMannequinsOption = Unpack.GameOption:new('ignoreMannequins', ignoreMannequins);
    function ignoreMannequinsOption:toUI()
        local value = Settings:GetBool(Unpack.EXCLUDE_MANNEQUIN_CONTAINER);
        self.control:setSelected(1, value);
    end
    function ignoreMannequinsOption:apply()
        local value = self.control.options[self.control.selected];
        Settings:Set(Unpack.EXCLUDE_MANNEQUIN_CONTAINER, self.control:isSelected(1));
        Settings:Serialize();
    end
    MainOptions.instance.gameOptions:add(ignoreMannequinsOption);
    ypos = ypos + delta;
    addScrollHeight(ignoreMannequins:getHeight());

    -- ignore trash cans
    local ignoreBins = MainOptions.instance:addYesNo(splitpoint, ypos, comboWidth, 20, getText(Unpack.UI_MenuOptions_ExcludeTrashContainer));
    ignoreBins.tooltip = getText(Unpack.UI_MenuOptions_ExcludeTrashContainerTooltip);
    local ignoreBinsOption = Unpack.GameOption:new('ignoreBins', ignoreBins);
    function ignoreBinsOption:toUI()
        local value = Settings:GetBool(Unpack.EXCLUDE_TRASH_CONTAINER);
        self.control:setSelected(1, value);
    end
    function ignoreBinsOption:apply()
        local value = self.control.options[self.control.selected];
        Settings:Set(Unpack.EXCLUDE_TRASH_CONTAINER, self.control:isSelected(1));
        Settings:Serialize();
    end
    MainOptions.instance.gameOptions:add(ignoreBinsOption);
    ypos = ypos + delta;
    addScrollHeight(ignoreBins:getHeight());

    --
    local specializationCount = MainOptions.instance:addCombo(splitpoint, ypos, comboWidth, 20, getText(Unpack.UI_MenuOptions_ContainerPercentageItemCount), {"Off", "1", "3", "5", "7"}, 1);
    specializationCount:setToolTipMap({["defaultTooltip"] = getText(Unpack.UI_MenuOptions_ContainerPercentageItemCountTooltip)});
    local specializationCountOption = Unpack.GameOption:new('specializationCount', specializationCount);
    function specializationCountOption:toUI()
        local value = Settings:Get(Unpack.CATEGORY_SPECIALIZATION_MIN);
        self.control:select(tostring(value));
    end
    function specializationCountOption:apply()
        local value = self.control.options[self.control.selected];

        -- save settings
        Settings:Set(Unpack.CATEGORY_SPECIALIZATION_MIN, value);
        Settings:Serialize();
    end
    MainOptions.instance.gameOptions:add(specializationCountOption);
    addScrollHeight(specializationCount:getHeight());

    -- create a combo box for EACH category
    local options = {"Off", "1%", "5%", "10%", "15%", "20%", "25%", "30%", "35%", "40%", "45%", "50%", "55%", "60%", "65%", "70%", "75%", "80%", "85%", "90%", "95%", "99%", "100%"};
    for _,category in ipairs(categories) do
        ypos = ypos + delta;
        local categoryComboBox = MainOptions.instance:addCombo(splitpoint, ypos, comboWidth, 20, getText("IGUI_ItemCat_" .. category), options, 1);
        local categoryComboOption = Unpack.GameOption:new('categoryComboBox', categoryComboBox);
        function categoryComboOption.toUI(self)
            self.control:select(percentages[category]);
        end
        function categoryComboOption.apply(self)
            local value = self.control.options[self.control.selected];
            percentages[category] = value;

            -- serialize category option
            Settings:Set("CATEGORY_" .. string.upper(category), value);
            Settings:Serialize();
        end
        MainOptions.instance.gameOptions:add(categoryComboOption);
        addScrollHeight(categoryComboBox:getHeight());
    end

    -- set our panel scroll height
    MainOptions.instance.mainPanel:setScrollHeight(scrollHeight + delta);

    -- reset this to be nice, its state seems to apply to every tab created
    MainOptions.instance.addY = 0;
end
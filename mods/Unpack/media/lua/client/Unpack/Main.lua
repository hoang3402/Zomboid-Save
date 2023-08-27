require("Unpack/Unpack");
require("Unpack/Items");

---
--
local function OnKeyPress(key)
    -- return if we're not hitting our bound key
    local keyCodeStr = tostring(getCore():getKey(Unpack.KEY_NAME));
    if tostring(key) ~= keyCodeStr then 
        return;
    end

    -- restock all nearby containers from all player inventory items
    -- TODO: I guess "on key press" can only be done by the first player then? How do I tell who I am?
    local player = getSpecificPlayer(0);
    local playerNumber = player:getPlayerNum();
    Unpack:DoStock(getSpecificPlayer(0), Unpack:getInventoryList(playerNumber), Unpack:preProcessNearbyContainers(Unpack:getNearbyContainers(playerNumber)));
end

---
--
local function moveItemsToInventory(items, inventory, player)
    for _,item in ipairs(items) do
        if not Unpack:isKeyRing(item) then
            Unpack:moveItemToContainer(player, item, inventory);
        end
    end
end

---
--
local function AddInventoryContextMenu(playerNumber, context, items)
    if #items > 0 then
        local u = Unpack;
        local player = getSpecificPlayer(playerNumber);
        local primary = player:getPrimaryHandItem();
        local secondary = player:getSecondaryHandItem();
        local back = player:getClothingItem_Back();
        local playerInventory = player:getInventory();

        -- we'll use the parent container of ther first item
        -- to tell us whether or not we're clicking on the player
        -- inventory or loot
        local actualItems = ISInventoryPane.getActualItems(items);
        local parentContainer = actualItems[1]:getContainer();

        -- setup the text for our option
        local itemCount = #items;
        local textKey = u.UI_ContextMenu_PutItemsInContainerSingular;
        if itemCount > 1 then
            textKey = u.UI_ContextMenu_PutItemsInContainerPlural;
        end

        -- show context options based on the parent container where stored items were clicked
        if not (parentContainer == playerInventory) then
            context:addOption(
                getText(
                    textKey,
                    itemCount, getText(u.IGUI_InventoryTooltip)),
                actualItems,
                moveItemsToInventory,
                playerInventory,
                player
            );
        end

        -- lazy repitition below!
        if u:isContainer(back) and not (parentContainer == back:getInventory()) then
            context:addOption(
                getText(
                    textKey,
                    itemCount,
                    getItemNameFromFullType(back:getModule() .. "." .. back:getType()) .. " (" .. getText(u.IGUI_health_Back) .. ")"),
                actualItems,
                moveItemsToInventory,
                back:getInventory(),
                player
            );
        end
        if u:isContainer(primary) and not (parentContainer == primary:getInventory()) then
            context:addOption(
                getText(
                    textKey,
                    itemCount,
                    getItemNameFromFullType(primary:getModule() .. "." .. primary:getType()) .. " (" .. getText(u.IGUI_PrimaryTooltip) .. ")"),
                actualItems,
                moveItemsToInventory,
                primary:getInventory(),
                player
            );
        end
        if u:isContainer(secondary) and not (parentContainer == secondary:getInventory()) then
            context:addOption(
                getText(
                    textKey,
                    itemCount,
                    getItemNameFromFullType(secondary:getModule() .. "." .. secondary:getType()) .. " (" .. getText(u.IGUI_SecondaryTooltip) .. ")"),
                actualItems,
                moveItemsToInventory,
                secondary:getInventory(),
                player
            );
        end
    end
end

---
--
local function walkToAndRestock(container, playerNumber, playerInventory, containerMap)
    if luautils.walkToContainer(container, playerNumber) then
        Unpack:DoStock(getSpecificPlayer(playerNumber), playerInventory, containerMap);
    end
end

---
--
local function AddContextMenu(playerNumber, context, worldobjects, test)
    local u = Unpack;
    local player = getSpecificPlayer(playerNumber);
    local loot = worldobjects[1];
    local lootInventoryTable = {};
    local lootInventory;

    if loot then
        lootInventory = loot:getContainer();
        if lootInventory then
            local node = {};
            node.inventory = lootInventory;
            table.insert(lootInventoryTable, node);
        end
    end
    
    -- for some reason, when a player using a controller does this... lootInventory is null. not true of mouse an keyboard.
    if not lootInventory then
        -- let's find containers in the tiles surrounding the player
        lootInventoryTable = u:GetLootInSurroundingSquares(playerNumber, worldobjects);
    end

    -- any containers to look at?
    if lootInventoryTable then
        -- capture these so we can compare to containers being added to the 
        -- context menu below. We'll add a parenthetical suffix to indicate
        -- where the container is equipped in these three cases.
        local primary = player:getPrimaryHandItem();
        local secondary = player:getSecondaryHandItem();
        local back = player:getClothingItem_Back();

        -- NOTE: there seems to be an issue in 41.43...isExplored is ALWAYS true? Maybe I am misunderstanding..
        for _,node in ipairs(lootInventoryTable) do
            local lootInventory = node.inventory;
            if not u:isFloor(lootInventory) then
                local suffix;
                local containerCount = 0;
                local containerName = getText("IGUI_ContainerTitle_" .. lootInventory:getType());

                -- if this is set, then the container's name was already localized (i.e. for vehicles, since they seem to be a special case)
                if node.containerName then
                    containerName = getText(node.containerName);
                end

                local containerMap = u:preProcessNearbyContainers({[1]=lootInventory});
                local it = player:getInventory():getItems();
                for i = 0, it:size()-1 do
                    local item = it:get(i);
                    if u:isContainer(item) and player:isEquipped(item) and not u:isKeyRing(item) then
                        suffix = getText(item:getName());
                        if back == item then
                            suffix = suffix .. " (" .. getText(u.IGUI_health_Back) .. ")";
                        elseif secondary == item then
                            suffix = suffix .. " (" .. getText(u.IGUI_SecondaryTooltip) .. ")";
                        elseif primary == item then
                            suffix = suffix .. " (" .. getText(u.IGUI_PrimaryTooltip) .. ")";
                        end

                        local container = item:getInventory();
                        if u:containerHasItemsToMove(player, container, containerMap) then
                            -- add our context option for the selected inventory and container
                            context:addOption(
                                getText(u.UI_WorldContextMenu_StockContainerFrom, containerName, suffix),
                                lootInventory,
                                walkToAndRestock,
                                playerNumber,
                                {[1]=container},
                                containerMap
                            );
                            containerCount = containerCount + 1;
                        end
                    end
                end

                container = player:getInventory();
                if u:containerHasItemsToMove(player, container, containerMap) then
                    context:addOption(
                        getText(u.UI_WorldContextMenu_StockContainerFrom, containerName, getText(u.IGUI_InventoryTooltip)),
                        lootInventory,
                        walkToAndRestock,
                        playerNumber,
                        {[1]=container},
                        containerMap
                    );
                    containerCount = containerCount + 1;
                end

                -- add an all option
                if containerCount > 1 then
                    context:addOption(
                        getText(u.UI_WorldContextMenu_Stock) .. " " .. containerName,
                        lootInventory,
                        walkToAndRestock,
                        playerNumber,
                        u:getInventoryList(playerNumber),
                        containerMap
                    );
                end
            end
        end
    end
end

-- Register events we need
Events.OnMainMenuEnter.Add(Unpack.InitOptions);                             -- init menu options (main menu)
Events.OnGameStart.Add(Unpack.InitOptions);                                 -- init menu options (add to game options menu)
Events.OnPreFillWorldObjectContextMenu.Add(AddContextMenu);                 -- add context menu on world container right-click
Events.OnPreFillInventoryObjectContextMenu.Add(AddInventoryContextMenu);    -- add context menu on inventory menu right-click
Events.OnCustomUIKey.Add(OnKeyPress);                                       -- "unpack" in nearby containers

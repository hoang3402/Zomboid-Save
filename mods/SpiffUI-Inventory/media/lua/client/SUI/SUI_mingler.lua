------------------------------------------
-- Mingler 2!!!!
---- Merges inventories into one container
---- Includes a mingler for the Tetris Inventory!
------------------------------------------

--if getActivatedMods():contains("INVENTORY_TETRIS") then return end

-- Add module
SpiffUI = SpiffUI or {}

-- Register our inventory
local spiff = SpiffUI:Register("inventory")

local sui = {
    -- some lookup tables
    bags = {
        ["SpiffContainer"] = 1,
        ["SpiffBodies"] = 2,
        ["SpiffPack"] = 1,
        ["SpiffEquip"] = 2
    },
    lootFilter = {
        ["SpiffContainer"] = true,
        ["SpiffBodies"] = true,
        ["floor"] = true,
        ["inventorymale"] = true,
        ["inventoryfemale"] = true
    },
    corpseFilter = {
        ["inventorymale"] = true,
        ["inventoryfemale"] = true
    },
    eventStates = {
        ["begin"] = 1,
        ["buttonsAdded"] = 2,
        ["end"] = 3
    },
    megaPackFilter = {
        ["KeyRing"] = true,
        ["SpiffPack"] = true,
        ["SpiffEquip"] = true
    },
    mingle = {}
}

-- Sort available inventories into loots and corpses, remove corpse buttons, add spiff buttons
local addLootButtons = function(inv)
    local mng = sui.bags[inv.inventoryPane.inventory:getType()]
    if mng then
        inv.isMingler = (mng == 1 and sui.mingle[inv.player].loot) or sui.mingle[inv.player].corpse 
    else
        -- nothing to do, unset mingler
        inv.wasMingler = inv.isMingler
        inv.isMingler = nil
    end

    -- update our filter configs
    sui.lootFilter["floor"] = not (not spiff.hasTetris or spiff.Conf.showfloormerged)

    sui.corpseFilter["inventorymale"] = spiff.Conf.sepzeds
    sui.corpseFilter["inventoryfemale"] = spiff.Conf.sepzeds

    local kept, corpse, loot = {}, {}, {}

    for i=1, #inv.backpacks do
        local pButton = inv.backpacks[i]
        if pButton.onclick then
            local inventory = pButton.inventory
            if sui.corpseFilter[inventory:getType()] then
                if not inventory:isEmpty() then
                    -- Only include if the corpse has anything
                    corpse[#corpse+1] = pButton
                end
                -- Still remove the button
                inv:removeChild(pButton)
            elseif not sui.lootFilter[inventory:getType()] then
                if not inventory:isEmpty() then
                    loot[#loot+1] = pButton
                end
                kept[#kept+1] = pButton
            else -- Catch for the floor and zeds if options are disabled
                kept[#kept+1] = pButton
            end
        end
    end

    -- Make the Mingle containers "sticky when active"
    mng = spiff.Conf.stickyButtons and sui.bags[inv.inventoryPane.lastinventory:getType()]
    local forceb1, forceb2 = false, false
    if mng then
        if mng == 1 then
            inv.forceSelectedContainer = sui.mingle[inv.player].loot.container
            inv.forceSelectedContainerTime = getTimestampMs() + 100
            inv.isMingler = sui.mingle[inv.player].loot
            inv.wasMingler = nil
            forceb1 = true
        else
            inv.forceSelectedContainer = sui.mingle[inv.player].corpse.container
            inv.forceSelectedContainerTime = getTimestampMs() + 100
            inv.isMingler = sui.mingle[inv.player].corpse
            inv.wasMingler = nil
            forceb2 = true
        end
    elseif spiff.Conf.sepzeds and sui.corpseFilter[inv.inventoryPane.inventory:getType()] then
        inv.forceSelectedContainer = sui.mingle[inv.player].corpse.container
        inv.forceSelectedContainerTime = getTimestampMs() + 100
        inv.isMingler = sui.mingle[inv.player].corpse
        inv.wasMingler = nil
        forceb2 = true
    end

    -- Add our buttons
    if spiff.Conf.lootinv and (spiff.Conf.buttonShow or #loot > 1 or forceb1) then -- We have more than 2 containers, or option to keep
        sui.mingle[inv.player].loot.button = inv:addContainerButton(sui.mingle[inv.player].loot.container, sui.mingle[inv.player].loot.icon, sui.mingle[inv.player].loot.name, nil)
    else
        sui.mingle[inv.player].loot.button = nil
    end
    if spiff.Conf.sepzeds and (spiff.Conf.buttonShow or #corpse > 0 or forceb2) then -- We have more than one container, or option to keep
        sui.mingle[inv.player].corpse.button = inv:addContainerButton(sui.mingle[inv.player].corpse.container, sui.mingle[inv.player].corpse.icon, sui.mingle[inv.player].corpse.name, nil)
    else
        sui.mingle[inv.player].corpse.button = nil
    end

    if spiff.Conf.sepzeds then
        local y = 0
        for i=1, #kept do
            kept[i]:setY((inv.buttonSize*y) + (inv:titleBarHeight()))
            y = y + 1
        end
        if sui.mingle[inv.player].loot.button then
            sui.mingle[inv.player].loot.button:setY((inv.buttonSize*y) + (inv:titleBarHeight()))
            y = y + 1
        end
        if sui.mingle[inv.player].corpse.button then
            sui.mingle[inv.player].corpse.button:setY((inv.buttonSize*y) + (inv:titleBarHeight()))
            y = y + 1
        end
    end

    sui.mingle[inv.player].corpse.invs = corpse
    sui.mingle[inv.player].loot.invs = loot
    if inv.isMingler then
        inv.refreshColors = inv.isMingler.invs or {}
    end
end

local processLootBags = function(loot)
    -- ONLY do this if we have a mingler active
    local mnglr = loot.isMingler
    if not mnglr then
        return
    end
    local tW = 0
    mnglr.container:clear()
    --local playerObj = getSpecificPlayer(loot.player)
    for i=1, #mnglr.invs do
        local inv = mnglr.invs[i].inventory
        if mnglr.isCorpse then
            -- Some corpses have more than they can actually carry
            local weight = inv:getCapacityWeight()
            tW = tW + ((weight >= inv:getMaxWeight() and weight) or inv:getMaxWeight())
        else
            tW = tW + inv:getMaxWeight()
        end
        mnglr.container:setCapacity(tW)
        mnglr.container:getItems():addAll(inv:getItems())
    end
    if mnglr.button then
        mnglr.button.capacity = tW
    end
end

local addInvButton = function(inv)
    local mng = sui.bags[inv.inventoryPane.inventory:getType()]
    if mng then
        inv.isMingler = (mng == 1 and sui.mingle[inv.player].megapack) or sui.mingle[inv.player].equip
    else
        -- nothing to do, unset mingler
        inv.wasMingler = inv.isMingler
        inv.isMingler = nil
    end

    local kept = {}

    for i=1, #inv.backpacks do
        local inv2 = inv.backpacks[i].inventory
        if not sui.megaPackFilter[inv2:getType()] and not inv2:isEmpty() then
            kept[#kept+1] = inv2
        end
    end
    sui.mingle[inv.player].megapack.invs = kept

    if spiff.Conf.selfinv and #kept > 2 then -- We have more than 2 containers, or option to keep
        sui.mingle[inv.player].megapack.button = inv:addContainerButton(sui.mingle[inv.player].megapack.container, sui.mingle[inv.player].megapack.icon, sui.mingle[inv.player].megapack.name, nil)
    else
        sui.mingle[inv.player].megapack.button = nil
    end
end

-- prevent inventories from being added multiple times
local function syncItemsPlayer(inv, mnglr, player, hotbar, weight, p)
    -- if already done, skip
    if p[inv] then 
        return weight, p
    end

    -- index
    p[inv] = true

    -- if filtered or empty, skip
    if sui.megaPackFilter[inv:getType()] or inv:isEmpty() then
        return weight, p
    end

    -- calculate the weight
    if inv == player:getInventory() then
        weight = weight + inv:getCapacityWeight()
    else
        weight = weight + inv:getMaxWeight()
    end
    -- set
    mnglr.container:setCapacity(weight)

    -- Build the container
    -- Can't really optimize this as we want to only get items that are not equipped, in a hotbar, or a key/keyring
    local items = inv:getItems()
    for i=0, items:size()-1 do
        local item = items:get(i)
        if not player:isEquipped(item) and not mnglr.container:contains(item) then
            -- if item is a container, build
            if instanceof(item, "InventoryContainer") and not sui.megaPackFilter[item:getType()] and not p[inv] then
                weight, p = syncItemsPlayer(item:getInventory(), mnglr, player, hotbar, weight, p)
            end
            if not hotbar:isInHotbar(item) then
                mnglr.container:AddItemBlind(item)
            end
        end
    end
    return weight, p
end

local processInvBag = function(inv)
    -- ONLY do this if we have a mingler active
    local mnglr = inv.isMingler
    if not mnglr or mnglr and mnglr.isEquip then
        return
    end
    mnglr.container:clear()
    local hotbar = getPlayerHotbar(inv.player)
    local playerObj = getSpecificPlayer(inv.player)
    local w, p = 0, {} -- temp variables
    for i=1, #mnglr.invs do
        w, p = syncItemsPlayer(mnglr.invs[i], mnglr, playerObj, hotbar, w, p)
    end
end

local addEquipButton = function(inv)
    local mng = sui.bags[inv.inventoryPane.inventory:getType()]
    if mng then
        inv.isMingler = (mng == 1 and sui.mingle[inv.player].megapack) or sui.mingle[inv.player].equip
    else
        -- nothing to do, unset mingler
        inv.wasMingler = inv.isMingler
        inv.isMingler = nil
    end

    if spiff.Conf.spiffequip then -- We have more than 2 containers, or option to keep
        sui.mingle[inv.player].equip.button = inv:addContainerButton(sui.mingle[inv.player].equip.container, sui.mingle[inv.player].equip.icon, sui.mingle[inv.player].equip.name, nil)
    else
        sui.mingle[inv.player].equip.button = nil
    end
end

local processEquipBag = function(inv)
    -- ONLY do this if we have a mingler active
    local mnglr = inv.isMingler
    if not mnglr or mnglr and not mnglr.isEquip then
        return
    end
    mnglr.container:clear()
    local player = getSpecificPlayer(inv.player)
    local hotbar = getPlayerHotbar(inv.player)

    -- local w = player:getInventory():getEffectiveCapacity(player)
    -- if w < player:getInventory():getMaxWeight() then
    --     w = player:getInventory():getMaxWeight()
    -- end
    --local w = player:getInventory():getCapacityWeight()
    mnglr.container:setCapacity(999)

    local items = player:getInventory():getItems()
    for i=0, items:size()-1 do
        local item = items:get(i)
        if hotbar:isInHotbar(item) or player:isEquipped(item) and not mnglr.container:contains(item) then
            mnglr.container:AddItemBlind(item)
        end
    end
    mnglr.container:setCapacity(player:getInventory():getMaxWeight())
end

local processMingler = function(inv, state)
    if sui.eventStates[state] == 1 then
        if inv.onCharacter and not spiff.hasEquipUI then
            addEquipButton(inv)
        end
    elseif sui.eventStates[state] == 2 then
        if inv.onCharacter then
            addInvButton(inv)
        else
            addLootButtons(inv)
        end
    elseif sui.eventStates[state] == 3 then
        if inv.onCharacter then
            processInvBag(inv)
            processEquipBag(inv)
        else
            processLootBags(inv)
        end
    end
end

local addSpiffUITetrisButtons = function(inv, state)
    if sui.eventStates[state] == 2 and not inv.onCharacter then
        addLootButtons(inv)
        -- The inventory management is processed later
    end
end

sui.CreatePlayer = function(id)
    local playerObj = getSpecificPlayer(id)
    sui.mingle[id] = {}
    sui.mingle[id].loot = {
        icon = getTexture("media/spifficons/spiffcontainers.png"),
        name = getText("UI_SpiffUI_Inv_containers"),
        cat = "SpiffContainer",
        bag = InventoryItemFactory.CreateItem("SpiffUI.Bag"),
        invs = {}
    }
    sui.mingle[id].loot.bag:setName(sui.mingle[id].loot.name)
    sui.mingle[id].loot.container = sui.mingle[id].loot.bag:getInventory()
    sui.mingle[id].loot.container:setType(sui.mingle[id].loot.cat)
    sui.mingle[id].loot.container:setCapacity(0)

    sui.mingle[id].corpse = {
        --icon = getTexture("media/spifficons/spiffbodies.png"),
        icon = getTexture("media/ui/Container_Bodybag.png"),
        name = getText("UI_SpiffUI_Inv_bodies"),
        cat = "SpiffBodies",
        bag = InventoryItemFactory.CreateItem("SpiffUI.Bag"),
        invs = {}
    }
    sui.mingle[id].corpse.bag:setName(sui.mingle[id].corpse.name)
    sui.mingle[id].corpse.container = sui.mingle[id].corpse.bag:getInventory()
    sui.mingle[id].corpse.container:setType(sui.mingle[id].corpse.cat)
    sui.mingle[id].corpse.container:setCapacity(0)
    sui.mingle[id].corpse.isCorpse = true

    if not spiff.hasEquipUI then
        
        sui.mingle[id].equip = {
            icon = getTexture("media/spifficons/spiffequip.png"),
            name = getText("UI_SpffUI_Inv_equippack", playerObj:getDescriptor():getForename(), playerObj:getDescriptor():getSurname()),
            cat = "SpiffEquip",
            bag = InventoryItemFactory.CreateItem("SpiffUI.Bag"),
        }
        sui.mingle[id].equip.bag:setName(sui.mingle[id].equip.name)
        sui.mingle[id].equip.container = sui.mingle[id].equip.bag:getInventory()
        sui.mingle[id].equip.container:setType(sui.mingle[id].equip.cat)
        sui.mingle[id].equip.container:setCapacity(0)
        sui.mingle[id].equip.isEquip = true
    end

    if not spiff.hasTetris then          
        sui.mingle[id].megapack = {
            icon = getTexture("media/spifficons/spiffpack.png"),
            name = getText("UI_SpffUI_Inv_selfpack", playerObj:getDescriptor():getForename(), playerObj:getDescriptor():getSurname()),
            cat = "SpiffPack",
            bag = InventoryItemFactory.CreateItem("SpiffUI.Bag"),
            invs = {}
        }
        sui.mingle[id].megapack.bag:setName(sui.mingle[id].megapack.name)
        sui.mingle[id].megapack.container = sui.mingle[id].megapack.bag:getInventory()
        sui.mingle[id].megapack.container:setType(sui.mingle[id].megapack.cat)
        sui.mingle[id].megapack.container:setCapacity(0)        
    end

    if not spiff.hasTetris then
        Events.OnRefreshInventoryWindowContainers.Add(processMingler)
    else
        Events.OnRefreshInventoryWindowContainers.Add(addSpiffUITetrisButtons)
    end
end

sui.PostBoot = function()
    if spiff.hasTetris then
        -- Add support for the SpiffUI Buttons
        local _ISInventoryPane_refreshItemGrids = ISInventoryPane.refreshItemGrids
        function ISInventoryPane:refreshItemGrids(forceFullRefresh)
            if not self.parent.isMingler then
                -- Was a mingler, so set the scroll to 0
                if self.parent.wasMingler then
                    self.scrollView:setYScroll(0)
                    self.scrollView:setScrollHeight(0)
                end
                return _ISInventoryPane_refreshItemGrids(self, forceFullRefresh)
            end

            local oldGridContainerUis = {}
            for i=1, #self.gridContainerUis do
                local gridContainerUi = self.gridContainerUis[i]
                self.scrollView:removeScrollChild(gridContainerUi)
                oldGridContainerUis[gridContainerUi.inventory] = gridContainerUi
            end

            self.gridContainerUis = {}

            if ISInventoryPage.applyBackpackOrder then
                self.parent:applyBackpackOrder()
            end

            local buttonsAndY = {}
            local inv = self.parent.isMingler.invs
            for i=1, #inv do
                buttonsAndY[#buttonsAndY+1] = {button = inv[i], y = inv[i]:getY()}
            end
            --self.parent.refreshColors = inv or {}
                    
            table.sort(buttonsAndY, function(a, b) return a.y < b.y end)

            local y = 10
            for i=1, #buttonsAndY do
                inv = buttonsAndY[i].button.inventory -- reuse local "inv" from above
                local itemGridContainerUi = not forceFullRefresh and oldGridContainerUis[inv] or nil
                if not itemGridContainerUi then
                    itemGridContainerUi = ItemGridContainerUI:new(inv, self, self.player)
                    itemGridContainerUi:initialise()
                end
                itemGridContainerUi:setY(y)
                itemGridContainerUi:setX(10)
                self.scrollView:addScrollChild(itemGridContainerUi)

                y = y + itemGridContainerUi:getHeight() + 8

                self.gridContainerUis[#self.gridContainerUis+1] = itemGridContainerUi
            end

            self.scrollView:setScrollHeight(y)
        end
    end

    if not spiff.hasEquipUI then
        local _ISInventoryPane_refreshContainer = ISInventoryPane.refreshContainer
        function ISInventoryPane:refreshContainer()
            _ISInventoryPane_refreshContainer(self)

            if not self.parent.onCharacter then return end

            local mngl = self.parent.isMingler
            
            local newlist, equiplist = {}, {}

            for i=1, #self.itemslist do
                local v = self.itemslist[i]
                if v then
                    if v.equipped or v.inHotbar then
                        equiplist[#equiplist+1] = self.itemslist[i]                
                    else
                        newlist[#newlist+1] = self.itemslist[i]
                    end
                end
            end
            if mngl and mngl.isEquip then
                if self.equipSort then
                    table.sort(equiplist, self.equipSort)
                end
                self.itemslist = equiplist
            elseif spiff.Conf.hideEquipped then
                self.itemslist = newlist
            end               
        end

        -- We need to force-refresh our player's backpacks because some events don't properly update the items in the mingler
        local onPlayerUpdateClothes = function(character)
            if character and character:isAlive() and not character:isAsleep() then
                local inv = getPlayerInventory(character:getPlayerNum())
                if inv.isMingler then
                    inv:refreshBackpacks()
                end
            end
        end

        Events.OnClothingUpdated.Add(onPlayerUpdateClothes)
    end
end

return sui
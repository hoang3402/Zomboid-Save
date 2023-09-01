------------------------------------------
-- SpiffUI Inventory
------------------------------------------
-- We have nothing to do if Tetris is enabled
if getActivatedMods():contains("INVENTORY_TETRIS") then return end

-- Add module
SpiffUI = SpiffUI or {}

-- Register our inventory
local spiff = SpiffUI:Register("inventory")

local _ISInventoryPane_doButtons = ISInventoryPane.doButtons
-- Override so that the character minlger has no inventory options
function ISInventoryPane:doButtons(y)
    if self.parent.onCharacter then
        local mnglr = self.parent.isMingler
        if not mnglr then
            return _ISInventoryPane_doButtons(self,y)
        elseif mnglr.spiffI == -1 then
            --return _ISInventoryPane_doButtons(self,y)
        end
    else
        local playerInv = getPlayerInventory(self.player)
        if not playerInv.isMingler then
            return _ISInventoryPane_doButtons(self,y)
        end
    end
    self.contextButton1:setVisible(false)
    self.contextButton2:setVisible(false)
    self.contextButton3:setVisible(false)
end

------------------------------------------
-- Don't allow to drag items into the active Mingle container
local _ISInventoryPane_canPutIn = ISInventoryPane.canPutIn
function ISInventoryPane:canPutIn()
    local mnglr = self.parent.isMingler
    if mnglr then
        -- if mnglr.spiffI == 1 then
        --     return (self.parent.CM.bodies:canPutIn() ~= nil)
        -- elseif mnglr.spiffI == 2 then
        --     return (self.parent.CM.container:canPutIn() ~= nil)
        -- end
        return false
    end
    return _ISInventoryPane_canPutIn(self)
end

-- local _ISInventoryPane_transferItemsByWeight = ISInventoryPane.transferItemsByWeight
-- function ISInventoryPane:transferItemsByWeight(items, container)
--     local mnglr = self.parent:getMingler(container:getType())
--     if mnglr then
--         if mnglr.spiffI > 0 then
--             container = mnglr:canPutIn()
--             if not container then return end
--         else
--             return
--         end
--     end
--     _ISInventoryPane_transferItemsByWeight(self, items, container)
-- end

local _ISInventoryPane_onMouseDoubleClick =  ISInventoryPane.onMouseDoubleClick
function ISInventoryPane:onMouseDoubleClick(x, y)
    -- if this is the inventory, always do the double click action
    if self.parent.onCharacter then
        if self.parent.isMingler then
            if self.items and self.mouseOverOption and self.previousMouseUp == self.mouseOverOption then
                local item = self.items[self.mouseOverOption]
                if item and item.items then
                    for k, v in ipairs(item.items) do
                        if k ~= 1 then
                            self:doContextualDblClick(v)
                        end
                    end
                    return
                end
            end
        else
            return _ISInventoryPane_onMouseDoubleClick(self, x, y)
        end
    else
        -- Otherwise, don't do the double-click if the inventory mingler is open
        local playerInv = getPlayerInventory(self.player)
        if not playerInv.isMingler then
            _ISInventoryPane_onMouseDoubleClick(self, x, y)
        end
    end
end

local equipSort = require("SUI/SUI_InventorySorter")

function ISInventoryPane:toggleEquipSort()
    if self.equipSort then
        self.equipSort = nil
    else
        self.equipSort = equipSort.itemsList
    end
    self:refreshContainer()
end

local _ISInventoryPane_onFilterMenu =  ISInventoryPane.onFilterMenu
function ISInventoryPane:onFilterMenu(button)
    _ISInventoryPane_onFilterMenu(self, button)
    if not self.parent.onCharacter or getSpecificPlayer(self.player):isAsleep() then
        return
    end
    local mnglr = self.parent.isMingler
    if mnglr and mnglr.isEquip then
        getPlayerContextMenu(self.player):addOption("What Up", self, ISInventoryPane.toggleEquipSort)
    end
end

------------------------------------------
-- Visually show no dragging
local allowed = {
    ["SpiffBodies"] = true,
    ["SpiffContainer"] = true,
    ["SpiffPack"] = true,
    ["SpiffEquip"] = true
}
local _DraggedItems_update = ISInventoryPaneDraggedItems.update
function ISInventoryPaneDraggedItems:update()
    self.playerNum = self.inventoryPane.player
    if self.mouseOverContainer then
        if allowed[self.mouseOverContainer:getType()] then
            self.itemNotOK = {}
            self.validItems = {}
            for _,v in pairs(self.items) do
                self.itemNotOK[v] = true
            end
        end
    end
    _DraggedItems_update(self)
end

ISInventoryPaneContextMenu.onGrabItems = function(items, player)
    --print('onGrabItems')
	local playerInv = getPlayerInventory(player)
    if not playerInv.isMingler then
	    ISInventoryPaneContextMenu.transferItems(items, playerInv.inventory, player)
    end
end

local _ISInventoryPaneContextMenu_onGrabOneItems = ISInventoryPaneContextMenu.onGrabOneItems
ISInventoryPaneContextMenu.onGrabOneItems = function(items, player)
    --print('onGrabOneItems')
    local playerInv = getPlayerInventory(player)
    if not playerInv.isMingler then
        _ISInventoryPaneContextMenu_onGrabOneItems(items, player)
    end
end

local _ISInventoryPaneContextMenu_doGrabMenu = ISInventoryPaneContextMenu.doGrabMenu
function ISInventoryPaneContextMenu.doGrabMenu(context, items, player)
    --print('doGrabMenu')
    local playerInv = getPlayerInventory(player)
    if not playerInv.isMingler then
	    _ISInventoryPaneContextMenu_doGrabMenu(context, items, player)
    end
end

local _ISInventoryPaneContextMenu_isAnyAllowed = ISInventoryPaneContextMenu.isAnyAllowed
function ISInventoryPaneContextMenu.isAnyAllowed(container, items)
    --print('isAnyAllowed')
    if not allowed[container:getType()] then
        return _ISInventoryPaneContextMenu_isAnyAllowed(container, items)
    end
    return false
end
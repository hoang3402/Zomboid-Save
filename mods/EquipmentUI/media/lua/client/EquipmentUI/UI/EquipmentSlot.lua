require "IS/UI/ISPanel"
local c = require "EquipmentUI/Settings"

EquipmentSlot = ISPanel:derive("EquipmentSlot");

function EquipmentSlot:new(x, y, bodyLocation, equipmentUi, inventoryPane, playerNum)
	local o = {}
	o = ISPanel:new(x, y, c.SLOT_SIZE, c.SLOT_SIZE);
	setmetatable(o, self)
    self.__index = self
	o.x = x;
	o.y = y;

    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.backgroundColor = {r=0, g=0, b=0, a=0.95};

    o.bodyLocation = bodyLocation;
    o.equipmentUi = equipmentUi;
    o.inventoryPane = inventoryPane;
    o.playerNum = playerNum;
    
    o.bodyLocationGroup = getSpecificPlayer(playerNum):getWornItems():getBodyLocationGroup();

	return o;
end

function EquipmentSlot:initialise()
    ISPanel.initialise(self);

    table.insert(c.OnScaleChanged, function(scale)
        self:setWidth(c.SLOT_SIZE)
        self:setHeight(c.SLOT_SIZE)
    end);
end

function EquipmentSlot:setItem(item)
    self.item = item;
end

function EquipmentSlot:clearItem()
    self.item = nil;
end

function EquipmentSlot:prerender()
    ISPanel.prerender(self);
    
    local dragItem = DragAndDrop.getDraggedItem();
    if dragItem and dragItem ~= self.item then
        local bodyLocation = EquipmentSlot.getBodyLocationForItem(dragItem);
        if bodyLocation then
            local conflicts = bodyLocation == self.bodyLocation or self.bodyLocationGroup:isExclusive(bodyLocation, self.bodyLocation)
            if conflicts then
                self:drawRect(1, 1, self.width-2, self.height-2, 0.5, 1, 0, 0);
            end
        end
    end
end

function EquipmentSlot:render()
    if not self.item then
        return
    end
    
    local alpha = 1
    if self.item == DragAndDrop.getDraggedItem() then
        alpha = 0.5
    end

    self:drawTextureScaledUniform(self.item:getTex(), 1, 1, c.SCALE, alpha, self.getItemColor(self.item));
    if self:isMouseOver() then
        self.equipmentUi:doTooltipForItem(self, self.item);
    end
end

function EquipmentSlot:onRightMouseUp(x, y)
    if self.item then
        EquipmentSlot.openItemContextMenu(self, x, y, self.item, self.inventoryPane, self.playerNum);
    end
end

function EquipmentSlot:onMouseDown(x, y)
    if self.item then
        DragAndDrop.prepareDrag(self, DragAndDrop.convertItemToStack(self.item), x, y);
    end
end

function EquipmentSlot:onMouseMove(dx, dy)
    DragAndDrop.startDrag(self);
end

function EquipmentSlot:onMouseMoveOutside(dx, dy)
    DragAndDrop.startDrag(self);
end

function EquipmentSlot:onMouseUp(x, y)
    DragAndDrop.endDrag();
end

function EquipmentSlot:onMouseUpOutside(x, y)
    DragAndDrop.cancelDrag(self, EquipmentSlot.dropOrUnequip);
end

function EquipmentSlot:dropOrUnequip()
    local item = self.item
    if item then
        if not InventoryTetris then
            if self.inventoryPane:isMouseOver() then
                ISInventoryPaneContextMenu.unequipItem(item, self.playerNum)
                return
            end
        end

        local playerObj = getSpecificPlayer(self.playerNum)
        local vehicle = playerObj:getVehicle()
        if vehicle then
            return
        end

        if not ISUIElement.isMouseOverAnyUI() then
            ISInventoryPaneContextMenu.dropItem(item, self.playerNum)
        end
    end
end



-- STATIC METHODS

EquipmentSlot.getBodyLocationForItem = function(item)
    if not item:IsClothing() and not item:IsInventoryContainer() then return nil end
    local location = item:IsClothing() and item:getBodyLocation() or item:canBeEquipped()
    if location == "" then return nil end
    return location
end

EquipmentSlot.openItemContextMenu = function(uiContext, x, y, item, invPane, playerNum)
    local container = item:getContainer()
    local isInInv = container and container:isInCharacterInventory(getSpecificPlayer(playerNum))
    local menu = ISInventoryPaneContextMenu.createMenu(playerNum, isInInv, NotUtil.createVanillaStacksFromItems({item}, invPane), uiContext:getAbsoluteX()+x, uiContext:getAbsoluteY()+y)

    if menu and menu.numOptions > 1 and JoypadState.players[playerNum+1] then
        menu.origin = self.inventoryPage
        menu.mouseOver = 1
        setJoypadFocus(playerNum, menu)
    end
end

function EquipmentSlot.getItemColor(item)
    if not item then
        return 1,1,1
    end
    if not item:allowRandomTint() then
        return item:getR(), item:getG(), item:getB()
    end

    local colorInfo = item:getColorInfo()
    local r = colorInfo:getR()
    local g = colorInfo:getG()
    local b = colorInfo:getB()
    
    -- Limit how dark the item can appear if all colors are close to 0
    local limit = 0.2
    while r < limit and g < limit and b < limit do
        r = r + limit / 4
        g = g + limit / 4
        b = b + limit / 4
    end
    return r,g,b
end
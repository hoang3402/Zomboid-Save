require "IS/UI/ISPanel"
local c = require "EquipmentUI/Settings"

local TWO_HAND_OFFSET = 1.3;

WeaponSlot = ISPanel:derive("WeaponSlot");

function WeaponSlot:new(weaponSlotDef, equipmentUi, inventoryPane, playerNum, isSecondary)
    local o = {}
	o = ISPanel:new(0, 0, c.WEAPON_SLOT_SIZE, c.WEAPON_SLOT_SIZE);
	setmetatable(o, self)
    self.__index = self

    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.backgroundColor = {r=0, g=0, b=0, a=0.15};

    o.weaponSlotDef = weaponSlotDef;
    o.equipmentUi = equipmentUi;
    o.inventoryPane = inventoryPane;
    o.playerNum = playerNum;
    o.player = getSpecificPlayer(playerNum);
    o.isSecondary = isSecondary;

    o.primaryTexture = getTexture("media/ui/HandMain2_Off.png");
	o.secondaryTexture = getTexture("media/ui/HandSecondary2_Off.png");

	return o;
end

function WeaponSlot:initialise()
    ISPanel.initialise(self);

    table.insert(c.OnScaleChanged, function(scale)
       self:applyScale(scale) 
    end)
    self:applyScale(c.SCALE)
end

function WeaponSlot:applyScale(scale)
    local x = (scale * self.weaponSlotDef.position.x + c.EQUIPMENT_UI_X_OFFSET);
    local y = (scale * self.weaponSlotDef.position.y + c.EQUIPMENT_UI_Y_OFFSET);

    self:setX(x)
    self:setY(y)
    self:setWidth(c.WEAPON_SLOT_SIZE)
    self:setHeight(c.WEAPON_SLOT_SIZE)
end

function WeaponSlot:getHandItem()
    if self.isSecondary then
        return self.player:getSecondaryHandItem();
    else
        return self.player:getPrimaryHandItem();
    end
end

function WeaponSlot:prerender()
    local tex = self.isSecondary and self.secondaryTexture or self.primaryTexture;
    local r, g, b = 1, 1, 1;
    
    local item = self:getHandItem();
    local dragItem = DragAndDrop.getDraggedItem();
    if dragItem then
        if dragItem ~= item and self:canAcceptItem(dragItem) then
            if item then
                r = c.MIDDLE_COLOR.r;
                g = c.MIDDLE_COLOR.g;
                b = c.MIDDLE_COLOR.b;
            else
                r = c.GOOD_COLOR.r;
                g = c.GOOD_COLOR.g;
                b = c.GOOD_COLOR.b;
            end
        end

        if not self.isSecondary and dragItem:isTwoHandWeapon() then
            self.draw2hSlot = true;
        end
    else
        self.draw2hSlot = false;
    end

    self:drawTextureScaledUniform(tex, 0, 0, c.SCALE, 1, r,g,b);

    if self.draw2hSlot then
        self:bringToTop()
        self:setWidth(c.WEAPON_SLOT_SIZE * (TWO_HAND_OFFSET+1))
        self:drawTextureScaledUniform(self.primaryTexture, c.WEAPON_SLOT_SIZE * TWO_HAND_OFFSET, 0, c.SCALE, 1, c.GOOD_COLOR.r, c.GOOD_COLOR.g, c.GOOD_COLOR.b);
    else
        self:setWidth(c.WEAPON_SLOT_SIZE)
    end
end

function WeaponSlot:render()
    local item = self:getHandItem();
    if not item then
        return
    end

    local alpha = 1
    if item == DragAndDrop.getDraggedItem() then
        alpha = 0.5
    end

    if self.isSecondary then
        self:drawTextureCenteredAndSquare(item:getTex(), c.WEAPON_SLOT_SECONDARY_X_OFFSET, c.WEAPON_SLOT_SECONDARY_Y_OFFSET, c.WEAPON_SLOT_SECONDARY_SIZE, alpha, self.getItemColor(item));
    else
        self:drawTextureCenteredAndSquare(item:getTex(), 1 + c.WEAPON_SLOT_PRIMARY_OFFSET, c.WEAPON_SLOT_PRIMARY_OFFSET, c.WEAPON_SLOT_PRIMARY_SIZE, alpha, self.getItemColor(item));
    end

    if self:isMouseOver() then
        self.equipmentUi:doTooltipForItem(self, item);
    end
end

function WeaponSlot.getItemColor(item)
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

function WeaponSlot:onRightMouseUp(x, y)
    local item = self:getHandItem();
    if item then
        EquipmentSlot.openItemContextMenu(self, x, y, item, self.inventoryPane, self.playerNum);
    end
end

function WeaponSlot:onMouseDown(x, y)
    local item = self:getHandItem();
    if item then
        DragAndDrop.prepareDrag(self, DragAndDrop.convertItemToStack(item), x, y);
    end
end

function WeaponSlot:onMouseMove(dx, dy)
    DragAndDrop.startDrag(self);
end

function WeaponSlot:onMouseMoveOutside(dx, dy)
    DragAndDrop.startDrag(self);
end

function WeaponSlot:onMouseUp(x, y)
    if DragAndDrop.isDragging() then
        self:handleItemDrop(DragAndDrop.getDraggedItem(), x, y);
    end
    DragAndDrop.endDrag();
end

function WeaponSlot:onMouseUpOutside(x, y)
    DragAndDrop.cancelDrag(self, WeaponSlot.dropOrUnequip);
end

function WeaponSlot:handleItemDrop(item, x, y)
    local playerObj = getSpecificPlayer(self.playerNum)
    local requiresBothHands = item:isRequiresEquippedBothHands()
    
    if self.draw2hSlot then
        if x > c.WEAPON_SLOT_SIZE * TWO_HAND_OFFSET then
            requiresBothHands = true
        end
    end

    if requiresBothHands then
        ISInventoryPaneContextMenu.equipWeapon(item, true, true, self.playerNum)
    elseif self:canAcceptItem(item) then
        if not self.isSecondary then
            ISInventoryPaneContextMenu.equipWeapon(item, true, false, self.playerNum)
        else
            ISInventoryPaneContextMenu.equipWeapon(item, false, false, self.playerNum)
        end
    end
end

function WeaponSlot:canAcceptItem(item)
    local isFood = item:getCategory() == "Food" and not item:getScriptItem():isCantEat()
    if isFood then
        return false
    end

    local isClothes = item:getCategory() == "Clothing"
    if isClothes then
        return false
    end

    return self:isHandGood(item)
end

function WeaponSlot:isHandGood(item)
    local playerObj = getSpecificPlayer(self.playerNum)
    local hand = self.isSecondary and 
                    playerObj:getBodyDamage():getBodyPart(BodyPartType.Hand_L) or 
                    playerObj:getBodyDamage():getBodyPart(BodyPartType.Hand_R)

    local isAlreadyEquipped = self.isSecondary and playerObj:isSecondaryHandItem(item) or playerObj:isPrimaryHandItem(item)
    local isInOtherHand = self.isSecondary and playerObj:isPrimaryHandItem(item) or playerObj:isSecondaryHandItem(item)

    if (not isAlreadyEquipped or isInOtherHand) and not hand:isDeepWounded() and (hand:getFractureTime() == 0 or hand:getSplintFactor() > 0) then
        -- forbid reequipping skinned items to avoid multiple problems for now
        local add = true;
        if isInOtherHand and item:getScriptItem():getReplaceWhenUnequip() then
            return false
        end
        return true
    end
end

function WeaponSlot:dropOrUnequip()
    if InventoryTetris then
        return
    end

    local item = self:getHandItem();
    if item then
        if self.inventoryPane:isMouseOver() then
            ISInventoryPaneContextMenu.unequipItem(item, self.playerNum)
            return
        end

        local playerObj = getSpecificPlayer(self.playerNum)
        local vehicle = playerObj:getVehicle()
        if vehicle then
            return
        end

        local mouseOverUi = false
        local mx, my = getMouseX(), getMouseY()
        local allUi = UIManager.getUI()
        for i = 0, allUi:size() - 1 do
            local ui = allUi:get(i)
            if ui:isPointOver(mx, my) then
                mouseOverUi = true
                break
            end
        end

        if not mouseOverUi then
            ISInventoryPaneContextMenu.dropItem(item, self.playerNum)
        end
    end
end
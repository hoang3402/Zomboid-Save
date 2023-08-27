require "ISUI/ISPanelJoypad"
local c = require "EquipmentUI/Settings"

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local POPOUT_TEX = getTexture("media/ui/equipmentui/popout.png")
local ATTACH_TEX = getTexture("media/ui/equipmentui/attach.png")
local CLOSE_TEX = getTexture("media/ui/equipmentui/close.png")
local COLLAPSE_TEX = getTexture("media/ui/Panel_Icon_Collapse.png");
local PIN_TEX = getTexture("media/ui/Panel_Icon_Pin.png");

local function getLayoutModData(playerObj)
    local modData = playerObj:getModData()["EquipmentUILayout"];
    if not modData then
        modData = {
            isDocked = true,
            isClosed = false
        };
        playerObj:getModData()["EquipmentUILayout"] = modData;
    end
    return modData;
end

EquipmentUIWindow = ISPanelJoypad:derive("EquipmentUIWindow");

function EquipmentUIWindow:new(x, y, inventoryPane, playerNum)
	local o = {};
	o = ISPanelJoypad:new(x, y, c.EQUIPMENT_WIDTH + 12, inventoryPane.parent:getHeight());
	setmetatable(o, self);
    self.__index = self;

    o.inventoryPane = inventoryPane
    o.playerNum = playerNum

	o.char = getSpecificPlayer(playerNum);
	o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
	o.backgroundColor = {r=0, g=0, b=0, a=0.8};

    o.titlebarbkg = getTexture("media/ui/Panel_TitleBar.png");

    local modData = getLayoutModData(o.char);
    o.isDocked = modData.isDocked;
    o.isClosed = modData.isClosed;

    o.isCollapsed = false;
    o.collapseCounter = 0;
    o.pin = true;

    return o;
end

function EquipmentUIWindow:createChildren()
    ISPanelJoypad.createChildren(self);

    local titleBarHeight = self.inventoryPane.parent:titleBarHeight()

    self.scrollView = NotlocScrollView:new(0, titleBarHeight, self.width, self.height - titleBarHeight - 9);
    self.scrollView:initialise();
    self:addChild(self.scrollView);

    self.equipmentUi = EquipmentUI:new(0, 0, c.EQUIPMENT_WIDTH, 5000, self.inventoryPane, self.playerNum);
    self.equipmentUi:initialise()
    self.scrollView:addScrollChild(self.equipmentUi);

    self.popoutButton = ISButton:new(self:getWidth() - 24, 1, 20, titleBarHeight - 2, "", self, self.onPopoutOrAttach);
    self.popoutButton.internal = "POP";
    self.popoutButton.borderColor = {r=0, g=0, b=0, a=0};
    self.popoutButton.backgroundColor = {r=0, g=0, b=0, a=0};
    self.popoutButton:initialise();
    self.popoutButton:instantiate();
    self.popoutButton:setImage(self.isDocked and POPOUT_TEX or ATTACH_TEX);
    self.popoutButton:setAnchorRight(true);
    self.popoutButton:setAnchorTop(true);
    self.popoutButton:setAnchorLeft(false);
    self:addChild(self.popoutButton);

    self.closeButton = ISButton:new(2, 1, 20, titleBarHeight - 2, "", self, self.onClose);
    self.closeButton.internal = "CLOSE";
    self.closeButton.borderColor = {r=0, g=0, b=0, a=0};
    self.closeButton.backgroundColor = {r=0, g=0, b=0, a=0};
    self.closeButton:initialise();
    self.closeButton:instantiate();
    self.closeButton:setImage(CLOSE_TEX);
    self.closeButton:setAnchorRight(false);
    self.closeButton:setAnchorTop(true);
    self.closeButton:setAnchorLeft(true);
    self:addChild(self.closeButton);
    self.closeButton:setVisible(not self.isDocked);

    self.pinButton = ISButton:new(self.width - 42, 0, titleBarHeight, titleBarHeight, "", self, EquipmentUIWindow.doPin);
    self.pinButton.anchorRight = true;
    self.pinButton.anchorLeft = false;
    self.pinButton:initialise();
    self.pinButton.borderColor.a = 0;
    self.pinButton.backgroundColor.a = 0;
    self.pinButton.backgroundColorMouseOver.a = 0;
    self.pinButton:setImage(PIN_TEX);
    self:addChild(self.pinButton);
    self.pinButton:setVisible(false);

    self.collapseButton = ISButton:new(self.pinButton:getX(), 0, titleBarHeight, titleBarHeight, "", self, EquipmentUIWindow.doCollapse);
    self.collapseButton.anchorRight = true;
    self.collapseButton.anchorLeft = false;
    self.collapseButton:initialise();
    self.collapseButton.borderColor.a = 0;
    self.collapseButton.backgroundColor.a = 0;
    self.collapseButton.backgroundColorMouseOver.a = 0;
    self.collapseButton:setImage(COLLAPSE_TEX);
    self:addChild(self.collapseButton);
    self.collapseButton:setVisible(false);

    Events.OnKeyPressed.Add(function(key)
        if key == getCore():getKey("equipment_toggle_window") then
            self:toggleWindow();
        end
    end);

    if self.playerNum == 0 then
		ISLayoutManager.RegisterWindow('equipment_ui_mod', EquipmentUIWindow, self)
	end
end

function EquipmentUIWindow:prerender()
    if self.isDocked and not self.inventoryPane.parent:isVisible() then 
        self:setVisible(false);
        return;
    end

    if self.pin or DragAndDrop.isDragging()then
        self:uncollapseWindow();
    end

    self:setWidth(c.EQUIPMENT_WIDTH + 12);
    self.scrollView:setScrollHeight(self.equipmentUi:getHeightForScroll());
    
    local invPage = self.inventoryPane.parent
    if self.isDocked then
        self:setHeight(invPage:getHeight());
        self:setX(invPage:getX() - self:getWidth() + 1);
        self:setY(invPage:getY());
    end
    
    local hasScrollBar = self.scrollView:isVScrollBarVisible()
    local xOffset = hasScrollBar and 0 or 5
    self.equipmentUi:setX(xOffset);

    if not self.isCollapsed then
	    ISPanelJoypad.prerender(self)
    end

    local titleBarHeight = self.inventoryPane.parent:titleBarHeight()
    self:drawTextureScaled(self.titlebarbkg, 2, 1, self:getWidth() - 4, titleBarHeight - 2, 1, 1, 1, 1);
    self:drawRectBorder(0, 0, self:getWidth(), titleBarHeight, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
    
    self:drawText(getText("UI_equipment_equipment"), 24, 0, 1, 1, 1, 1, UIFont.Small);

    if not self.isCollapsed then
        self:drawTextureScaled(self.titlebarbkg, 2, self:getHeight() - 9, self:getWidth() - 4, 9, 1, 1, 1, 1);
        self:drawRectBorder(0, self:getHeight() - 9, self:getWidth(), 9, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
    end
end

function EquipmentUIWindow:render()
    ISPanelJoypad.render(self)
end

function EquipmentUIWindow:onInventoryVisibilityChanged(isVisible)
    if not self.isDocked then return; end
    self:setVisible(isVisible and not self.isClosed);
end

function EquipmentUIWindow:onPopoutOrAttach()
    self.isDocked = not self.isDocked;
    self.popoutButton:setImage(self.isDocked and POPOUT_TEX or ATTACH_TEX);
    if not self.isDocked then
        self:setX(self:getX() - 8);
    else
        self:setVisible(self.inventoryPane.parent:isVisible());
    end

    self.closeButton:setVisible(not self.isDocked);

    if self.isDocked then
        self:doPin();
        self.pinButton:setVisible(false);
        self.collapseButton:setVisible(false);
    else
        self.pinButton:setVisible(not self.pin);
        self.collapseButton:setVisible(self.pin);
    end

    local modData = getLayoutModData(self.char);
    modData.isDocked = self.isDocked;
end

function EquipmentUIWindow:onClose()
    self.isClosed = true;
    self:setVisible(false);

    local modData = getLayoutModData(self.char);
    modData.isClosed = true;

    self.inventoryPane.parent:bringToTop();
end

function EquipmentUIWindow:toggleWindow()
    if self.isClosed or not self:isVisible() then
        self.isClosed = false;
        if self.isDocked then
            self:setVisible(self.inventoryPane.parent:isVisible());
            if self.inventoryPane.parent:isVisible() then
                self.inventoryPane.parent:uncollapse();
            end
        else
            self:setVisible(true);
        end
    else
        self:onClose();
    end

    local modData = getLayoutModData(self.char);
    modData.isClosed = self.isClosed;
end

function EquipmentUIWindow:onMouseDown(x, y)
    if self.isDocked then return; end
    
    -- if over the title bar, then drag the window
    local titleBarHeight = self.inventoryPane.parent:titleBarHeight()
    if y < titleBarHeight then
        self.dragging = true;
        self.dragX = x;
        self.dragY = y;
        return true
    end

    -- if over the bottom bar, and not docked, then resize the window
    if y > self:getHeight() - 9 then
        self.resizing = true;
        self.dragX = x;
        self.dragY = y;
        return true
    end
end



function EquipmentUIWindow:onMouseDownOutside(x, y)
    -- check if the mouse is over this window
    if self:isMouseOver() then return; end


    if self.isDocked then
        if self.inventoryPane.parent:isMouseOver() then
            self:uncollapseWindow();
            return
        end 
    end
    self:collapseWindow();
end

function EquipmentUIWindow:onRightMouseDownOutside(x, y)
    self:onMouseDownOutside(x, y)    
end

function EquipmentUIWindow:onMouseUp(x, y)
    self.dragging = false;
    self.resizing = false;
end

function EquipmentUIWindow:onMouseUpOutside(x, y)
    self.dragging = false;
    self.resizing = false;
end

function EquipmentUIWindow:onMouseMove(dx, dy)
    local player = getSpecificPlayer(self.playerNum)
    if player:isAiming() then return; end

    if not isMouseButtonDown(0) and not isMouseButtonDown(1) and not isMouseButtonDown(2) then
        self:uncollapseWindow();
    end
    
    local panCameraKey = getCore():getKey("PanCamera")
    if self.isCollapsed and panCameraKey ~= 0 and isKeyDown(panCameraKey) then
        return
    end

    self.toggleElement:bringToTop();
    
    if self.dragging then
        self:setX(self:getX() + dx);
        self:setY(self:getY() + dy);
        return true
    end
   
    if self.resizing then
        local newHeight = self:getHeight() + dy
        if newHeight < 100 then newHeight = 100; end
        self:setHeight(newHeight);
        return true
    end
end

function EquipmentUIWindow:onMouseMoveOutside(dx, dy)
    if not DragAndDrop.isDragging() and not self.pin then
        self.collapseCounter = self.collapseCounter + getGameTime():getMultiplier() / 0.8;

        local playerObj = getSpecificPlayer(self.playerNum)
        if playerObj and playerObj:isAiming() then
            self.collapseCounter = 1000
        end

        if self.collapseCounter > 120 and not self.isCollapsed and bDo then
            self:collapseWindow();
        end
    end

    if self.dragging then
        self:setX(self:getX() + dx);
        self:setY(self:getY() + dy);
        return true
    end
   
    if self.resizing then
        local newHeight = self:getHeight() + dy
        if newHeight < 100 then newHeight = 100; end
        self:setHeight(newHeight);
        return true
    end
end

function EquipmentUIWindow:collapseWindow()
    self.isCollapsed = true;
    self:setMaxDrawHeight(self.inventoryPane.parent:titleBarHeight());
end

function EquipmentUIWindow:uncollapseWindow()
    self.isCollapsed = false;
    self:clearMaxDrawHeight();
    self.collapseCounter = 0;
end

function EquipmentUIWindow:doPin()
    self.pin = true

    if not self.isDocked then
        self.pinButton:setVisible(false)
        self.collapseButton:setVisible(true)
    end
end

function EquipmentUIWindow:doCollapse()
    if self.isDocked then return; end

    self.pin = false
    self.pinButton:setVisible(true)
    self.collapseButton:setVisible(false)
end

function EquipmentUIWindow:RestoreLayout(name, layout)
    ISLayoutManager.DefaultRestoreWindow(self, layout)
    if layout.pin == 'true' or layout.pin == nil then
        self:doPin()
    else
        self:doCollapse()
        self:collapseWindow()
    end
end

function EquipmentUIWindow:SaveLayout(name, layout)
    if self.pin then layout.pin = 'true' else layout.pin = 'false' end
    ISLayoutManager.DefaultSaveWindow(self, layout)
end

function EquipmentUIWindow:updateTooltip()
    self.equipmentUi:updateTooltip();
end

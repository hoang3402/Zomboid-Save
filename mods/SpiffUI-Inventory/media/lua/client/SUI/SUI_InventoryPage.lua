------------------------------------------
-- SpiffUI Inventory
------------------------------------------

-- Add module
SpiffUI = SpiffUI or {}

-- Register our inventory
local spiff = SpiffUI:Register("inventory")

local sui = {
    Overrides = {},
    mingler = require("SUI/SUI_mingler")
}

------------------------------------------
-- mingler
------------------------------------------
if not spiff.hasEquipUI then
    -- Just hotpatch if this doesn't exist. easier than checking conditions.
    function ISInventoryPage:isMouseOverEquipmentUi()
        return false
    end
end

sui.PostBoot = function()

    ISInventoryPage.SpiffOnKey = function(playerObj)
        if isGamePaused() then return end
        local player = getPlayerInventory(0)
        local loot = getPlayerLoot(0)
        local state = not player.isCollapsed and not loot.isCollapsed
        if not spiff.Conf.enableInv then
            state = not player:getIsVisible()
            player:setVisible(state)
            loot:setVisible(state)
            return
        end
        -- if dragging and tab is pressed, don't do the toggle. it resets the state
        if (not ISMouseDrag.dragging or #ISMouseDrag.dragging == 0) then
            player:Collapse(state, "Toggle")
            loot:Collapse(state, "Toggle")
        end

        -- still set this tho
        player.fVisible = not state
        loot.fVisible = not state
    end

    local keyBind = {
        name = 'SpiffUI_Inv',
        key = Keyboard.KEY_TAB,
        qBlock = false,
        Down = ISInventoryPage.SpiffOnKey
    }

    SpiffUI:AddKeyBind(keyBind)
    -- Remove the original
    Events.OnKeyPressed.Remove(ISInventoryPage.onKeyPressed)

    -- Reset our inventory to the default location
    ---- This only occurs for user "0" as this is the only user that uses mouse/keys
    spiff.Reset = function()
        local isMouse = (not JoypadState.players[1])
        if isMouse then
            getPlayerInventory(0):SUIReset()
            getPlayerLoot(0):SUIReset()
        end
    end
    spiff.resetDesc = " <LINE> Inventory Panel Location & Size "

    ------------------------------------------
    -- ADDITIONS
    ------------------------------------------
    function ISInventoryPage:isMouseInBuffer()
        if self.resizeWidget2.resizing then return true end

        -- So the inventory disappearing isn't so sensitive
        local buffer = 32
        local boX = buffer * (-1)
        local boY = 0 -- can't really go further up at the top
        local boW = self:getWidth() + buffer
        local boH = self:getHeight() + buffer

        local x = self:getMouseX()
        local y = self:getMouseY()

        return (x >= boX and x <= boW) and (y >= boY and y <= boH) or self:isMouseOverEquipmentUi()
    end

    function ISInventoryPage:isMouseIn()
        if self.resizeWidget2.resizing then return true end

        -- So the inventory disappearing isn't so sensitive
        local boX = 0
        local boY = 0 -- can't really go further up at the top
        local boW = self:getWidth()
        local boH = self:getHeight()

        local x = self:getMouseX()
        local y = self:getMouseY()

        return (x >= boX and x <= boW) and (y >= boY and y <= boH) or self:isMouseOverEquipmentUi()
    end

    function ISInventoryPage:isMouseInTop() 
        -- So the inventory disappearing isn't so sensitive
        local buffer = 32
        local boX = buffer * (-1)
        local boY = 0 -- can't really go further up at the top
        local boW = self:getWidth() + buffer
        local boH = self:titleBarHeight() + buffer

        local x = self:getMouseX()
        local y = self:getMouseY()

        return (x >= boX and x <= boW) and (y >= boY and y <= boH)
    end

    function ISInventoryPage:InitSUI()
        -- If player is on a controller
        self.isMouse = (self.player == 0) and (not JoypadState.players[1])

        -- If force visible
        self.fVisible = false
        -- autohide is used on mouse-over only
        self.autoHide = false
        -- Used to toggle Autohide until interaction with window
        self.holdOpen = false
        -- If being dragged to
        self.toDrag = false
        -- If dragged from here
        self.fromDrag = false
        -- If was opened from drag
        self.wasDrag = false

        self.wasVisible = false
        self.mouseHide = spiff.Conf.mouseHide

        self.infoX = self.infoButton:getX()
        self.infoXNew = self.closeButton:getX()

        self.minimumHeight = getPlayerScreenHeight(self.player) / 4

        -- We add our inventory containers to the loot panel itself
        if not spiff.hasTetris and self.onCharacter then
            self.equipSort = require("SUI/SUI_InventorySorter")
        end

        -- maybe later....
        --self.borderColor = { r=0.0, g=0.0,b=0.0,a=1.0}
        --self.titlebarbkg = getTexture("media/ui/spiffpanel.png")
    end

    function ISInventoryPage:SUIReset()
        local x = getPlayerScreenLeft(self.player)
        local y = getPlayerScreenTop(self.player)
        local w = getPlayerScreenWidth(self.player)
        local h = getPlayerScreenHeight(self.player)

        local divhei = 0
        local divwid = 0
        divhei = h / 3;

        if w < h then
            divhei = h / 4;
        end

        divwid = round(w / 3)
        if divwid < 256 + 32 then
            -- min width of ISInventoryPage
            divwid = 256 + 32
        end

        if self.onCharacter then
            self:setX(x + w / 2 - divwid)
        else
            self:setX(x + w / 2)
        end
        self:setY(y)
        self:setWidth(divwid)
        self:setHeight(divhei)

        -- Set the column sizes too!
        local column2 = 48
        local column3 = (self.width - column2) / 4
        local column3 = math.ceil(column3*self.inventoryPane.zoom)
        local column3 = (column3) + 100

        self.inventoryPane.column2 = column2
        self.inventoryPane.column3 = column3

        self.inventoryPane.nameHeader:setX(column2)
        self.inventoryPane.nameHeader:setWidth((column3 - column2))

        self.inventoryPane.typeHeader:setX(column3-1)
        self.inventoryPane.typeHeader:setWidth(self.width - column3 + 1)
    end

    function ISInventoryPage:Collapse(collapse, why)
        --if self.isCollapsed == collapse then return end

        -- local label
        -- if self.onCharacter then
        --     label = "Player"
        -- else
        --     label = "Loot"
        -- end
        
        -- if collapse then
        --     print("Collapsing: " .. label .. " | " .. why)
        -- else
        --     print("Showing: " .. label .. " | " .. why)
        -- end

        self.isCollapsed = collapse
        if self.isCollapsed then
            self:setMaxDrawHeight(self:titleBarHeight())
            self.holdOpen = false
            if spiff.Conf.enableInv then
                if self.friend.isCollapsed then
                    self:setVisibleReal(spiff.Conf.invVisible)
                    self.friend:setVisibleReal(spiff.Conf.invVisible)
                end
                self.autoHide = false
                self.holdOpen = false
                self.toDrag = false
                self.fromDrag = false
                self.wasDrag = false
                self.collapsing = true
                if spiff.Conf.autohidepopups and self.inventoryPane.tetrisWindowManager then
                    self.inventoryPane.tetrisWindowManager:closeAll()
                end
            end
        else
            if isClient() and not self.onCharacter then
                self.inventoryPane.inventory:requestSync()
            end
            self:clearMaxDrawHeight(true)
            self.collapseCounter = 0

            if spiff.Conf.enableInv then
                self:setVisibleReal(true)
                self.friend:setVisibleReal(true)
            end

            if self.coloredInvs then
                for i=1, #self.coloredInvs  do
                    local parent = self.coloredInvs[i]
                    if parent then
                        parent:setHighlighted(false)
                        parent:setOutlineHighlight(false);
                    end
                end
            end
        end

        
    end

    -- local mings = {
    --     ["SpiffContainer"] = 1,
    --     ["SpiffPack"] = 1,
    --     ["SpiffBodies"] = 2,
    --     ["SpiffEquip"] = 2
    -- }
    -- function ISInventoryPage:getMingler(name)
    --     if mings[name] == 1 then
    --         return self.CM.container
    --     elseif mings[name] == 2 then
    --         return self.CM.bodies
    --     else
    --         return nil
    --     end
    -- end

    -- Set Decoration Visibility
    function ISInventoryPage:setDecVisible(val)
        self.closeButton:setVisible(val)
        self.infoButton:setVisible(val)
        self.pinButton:setVisible(val)
        self.collapseButton:setVisible(val)
        self.resizeWidget:setVisible(val)

        -- We have the Equipment UI Object
        if self.equipmentUi then
            -- hide all the buttons, basically make it part of the inventory window
            self.equipmentUi.popoutButton:setVisible(val)
            self.equipmentUi.closeButton:setVisible(val)
            self.equipmentUi.pinButton:setVisible(val)
            self.equipmentUi.collapseButton:setVisible(val)
            self.equipmentUi.toggleElement:setVisible(val)

            self.equipmentUi.isDocked = (spiff.Conf.equipUIManager or self.equipmentUi.isDocked)
            self.equipmentUi.isClosed = false
        end
        self.infoButton:setX((val and self.infoX) or self.infoXNew)
        self.titleLoc = self.infoButton:getX() + self.infoButton:getWidth() + 4
    end

    -- We need this
    local _ISInventoryPage_setVisible = ISInventoryPage.setVisible
    function ISInventoryPage:setVisibleReal(vis)
        _ISInventoryPage_setVisible(self, vis)
    end
end
    
-- Moving to a new "Hot Patch" method.  Basically, we override the functions based on the current options
---- This should prevent reloading from being required for things, be an optimization step for when SpiffUI is disabled, improve compatibility, and just be better.
sui.Start = function() 
    ------------------------------------------
    -- ISInventoryPage:setVisible
    sui.Overrides.setVisible = {
        old = ISInventoryPage.setVisible,
        new =  function(self, vis)
            if not self.isMouse then
                return sui.Overrides.setVisible.old(self, vis)
            end

            -- This gets called at the start of the game before init, so just don't do anything yet.
            if not self.friend then return end

            self:Collapse(not vis, "setVisible")

            if vis then
                --- This is really only called when the world interacts now
                --- So let's treat it as such
                self.holdOpen = true
                self.autoHide = true
            end
        end
    }
    ------------------------------------------
    -- ISInventoryPage:getIsVisible
    sui.Overrides.getIsVisible = {
        old = ISInventoryPage.getIsVisible,
        new =  function(self)
            if not self.isMouse then
                return sui.Overrides.getIsVisible.old(self)
            end
            return not self.isCollapsed
        end
    }

    ------------------------------------------
    -- ISInventoryPage:prerender
    sui.Overrides.prerender = {
        old = ISInventoryPage.prerender,
        new =  function(self)
            sui.Overrides.prerender.old(self)
            local hide = (self.needSearch or self.friend.needSearch) or (self.friend.isMingler and true) or self.inventoryPane.inventory:isEmpty()
            if self.onCharacter then
                self.transferAll:setVisible(not hide)
                if self.EDNLDropItems then -- run this 2nd
                    self.EDNLDropItems:setVisible(not hide)
                end
            else
                self.lootAll:setVisible(not hide)
                if self.EDNLLootItems then
                    self.EDNLLootItems:setVisible(not hide)
                end
            end
        end
    }

    ------------------------------------------
    -- ISInventoryPage:onMouseMove
    sui.Overrides.onMouseMove = { 
        old = ISInventoryPage.onMouseMove,
        new = function(self, dx, dy)
            if not self.isMouse then
                return sui.Overrides.onMouseMove.old(self, dx, dy)    
            end
            -- Disable this
            self.collapseCounter = 0

            if isGamePaused() then
                return
            end

            -- if we're collapsed and pressing right mouse, we're probably aiming
            --- this shouldn't trigger the inventory
            if self.isCollapsed and getSpecificPlayer(self.player):isAiming() then
                return
            end

            self.mouseOver = true

            -- Disable inventory window moving
            if self.moving then
                self.moving = false
            end

            -- camera panning
            local panCameraKey = getCore():getKey("PanCamera")
            if self.isCollapsed and panCameraKey ~= 0 and isKeyDown(panCameraKey) then
                return
            end

            self.fromDrag = false
            -- If we are dragging items from this inventory
            if (ISMouseDrag.dragging and #ISMouseDrag.dragging > 0) and not self.toDrag and not self.fromDrag then
                self.fromDrag = true
            end

            -- First we touch the window, then close
            if self.holdOpen then
                self.holdOpen = false
            end

            self.prevMouse = self.mouseOver
        end
    }

    ------------------------------------------
    -- ISInventoryPage:onMouseMoveOutside
    sui.Overrides.onMouseMoveOutside = {
        old = ISInventoryPage.onMouseMoveOutside,
        new = function(self, dx, dy)
            if not self.isMouse then
                return sui.Overrides.onMouseMoveOutside.old(self, dx, dy)
            end

            if isGamePaused() then
                return
            end
            self.mouseOver = false;

            if self.moving then
                self.moving = false
            end

            if self.wasDrag then
                self.wasDrag = self.friend.mouseOver
            end

            self.prevMouse = self.mouseOver
        end
    }

    ------------------------------------------
    -- ISInventoryPage:onMouseDownOutside
    sui.Overrides.onMouseDownOutside = {
        old = ISInventoryPage.onMouseDownOutside,
        new = function(self, x, y)
            if not self.isMouse then
                return sui.Overrides.onMouseDownOutside.old(self, x, y)
            end
            if not self.fVisible and not self.isCollapsed and not self:isMouseInBuffer() and not self.fromDrag and not self.toDrag and not self.wasDrag then
                self:Collapse(true, "onMouseDownOutside")
            end
        end
    }

    ------------------------------------------
    -- ISInventoryPage:onRightMouseDownOutside
    sui.Overrides.onRightMouseDownOutside = {
        old = ISInventoryPage.onRightMouseDownOutside,
        new = function(self, x, y)
            if not self.isMouse then
                return sui.Overrides.onRightMouseDownOutside.old(self, x, y)
            end

            if not self.fVisible and not self.isCollapsed and not self:isMouseInBuffer() and not self.fromDrag and not self.toDrag and not self.wasDrag then
                self:Collapse(true, "onRightMouseDownOutside")
            end
        end
    }

    ------------------------------------------
    -- ISInventoryPage:clearMaxDrawHeight
    -- this is a hack to catch when the vanilla expand is done, we add a parameter to run it or logic to undo it
    sui.Overrides.clearMaxDrawHeight = {
        old = ISInventoryPage.clearMaxDrawHeight,
        new = function(self, extra)
            if not self.isMouse or extra or self.fVisible then 
                ISUIElement.clearMaxDrawHeight(self)
                return
            end

            if not self.autoHide and not self.fromDrag and not self.toDrag and not self.wasDrag and not self.holdOpen then
                self.isCollapsed = true     
            else
                ISUIElement.clearMaxDrawHeight(self)   
            end
        end
    }

    sui.Overrides.canPutIn = {
        old = ISInventoryPage.canPutIn,
        new = function(self)
            if (self.mouseOverButton and sui.mingler.bags[self.mouseOverButton.inventory:getType()]) then
                return false
            end
            return sui.Overrides.canPutIn.old(self)
        end,
        noTetris = true
    }

    ------------------------------------------
    -- MISC OTHER THINGS
    ----- These should probably be in their own file, but eh. xD
    ------------------------------------------

    ------------------------------------------
    -- We don't want the inventory to change if we are transferring from a Mingle container  
    local _ISInventoryTransferAction_doActionAnim = ISInventoryTransferAction.doActionAnim
    function ISInventoryTransferAction:doActionAnim(cont)
        local loot = getPlayerLoot(self.character:getPlayerNum())
        if loot.isMingler then
            self.selectedContainer = loot.inventory
        end        
        _ISInventoryTransferAction_doActionAnim(self, cont)
    end
    

    --local keyring = {["KeyRing"] = true}
    ---- This should be a better implementation, as it only gets the first keyring in the player's inventory directly.
    ----- No bags and such
    local getNextKeyRing = function(player, key)
        local k = player:getInventory():getFirstType("KeyRing")
        local inv = (k and k:getInventory())
        return (inv and inv:hasRoomFor(player, key) and inv) or nil
    end

    ------------------------------------------
    -- OnStart OVERRIDES
    --- For ultimate Mod Compat, do this OnStart
    ------------------------------------------
    -- This is actually unused, so lets just use this one!
    ---- Let's do this here, because I'm sure other modders have the same idea
    local _ISInventoryTransferAction_transferItem = ISInventoryTransferAction.transferItem
    function ISInventoryTransferAction:transferItem(item)
        -- restore the original destination if there is one
        if self.ogDest then
            self.destContainer = self.ogDest
            self.ogDest = nil
        end
        -- True if a container is on a character
        local char = self.destContainer:getCharacter()
        if char and char == self.character then
            -- if its from our character, and we're not moving it from anywhere on our person
            if not (self.srcContainer:getCharacter() and self.srcContainer:getCharacter() == self.character) then
                --Send keys to the keyring, if available. don't do it if we have a specific grid index (drag it to a tile)
                if instanceof(item, "Key") and spiff.Conf.handleKeys and not self.gridIndex then
                    self.ogDest = self.destContainer
                    -- default to the destContainer
                    self.destContainer = getNextKeyRing(self.character, item) or self.destContainer
                end
            end
        end

        return _ISInventoryTransferAction_transferItem(self, item)
    end

    local _ISInventoryPage_onBackpackRightMouseDown = ISInventoryPage.onBackpackRightMouseDown
    function ISInventoryPage:onBackpackRightMouseDown(x, y)
        return not (self.inventory and sui.mingler.bags[self.inventory:getType()]) and _ISInventoryPage_onBackpackRightMouseDown(self, x, y)
    end

    local _ISInventoryPage_update = ISInventoryPage.update
    function ISInventoryPage:update()
        _ISInventoryPage_update(self)

        ------------------------------------------
        -- mingler highlights
        if not self.onCharacter then
            if self.isMingler then
                -- Ok, let's actually optimize this a bit.
                -- first, unset this....
                if self.coloredInv then
                    if self.coloredInv:getParent() then
                        self.coloredInv:getParent():setHighlighted(false)
                        self.coloredInv:getParent():setOutlineHighlight(false)
                    end
                    self.coloredInv = nil
                end

                -- Update, refreshColors is set from the Mingler on container refresh
                if self.refreshColors then
                    -- If we have an old list
                    if self.keptColors then
                        for i=1, #self.keptColors  do
                            local parent = self.keptColors[i]
                            if parent then
                                parent:setHighlighted(false)
                                parent:setOutlineHighlight(false);
                            end
                        end
                    end
                    -- unset our list
                    self.keptColors = nil
                    self.coloredInvs = {}
                    -- get the parent object of all selected containers
                    for i=1, #self.refreshColors do
                        self.coloredInvs[#self.coloredInvs+1] = self.refreshColors[i].inventory:getParent()
                    end
                    -- and we're done
                    self.refreshColors = nil
                end

                if not self.isCollapsed and self.coloredInvs then
                    -- If we have coloredInvs to show, then show if panel is open
                    for i=1, #self.coloredInvs do
                        local parent = self.coloredInvs[i]
                        if parent and (instanceof(parent, "IsoObject") or instanceof(parent, "IsoDeadBody")) then
                            parent:setHighlighted(true, false);
                            if getCore():getOptionDoContainerOutline() then
                                parent:setOutlineHighlight(true);
                                parent:setOutlineHighlightCol(1, 1, 1, 1);
                            end
                            parent:setHighlightColor(getCore():getObjectHighlitedColor())
                        end
                    end
                    -- set our keptColors variable to our active coloredInvs
                    self.keptColors = self.coloredInvs
                    self.coloredInvs = nil
                elseif self.isCollapsed and self.keptColors then
                    -- if we collapse and have invs highlighted
                    for i=1, #self.keptColors  do
                        local parent = self.keptColors[i]
                        if parent then
                            parent:setHighlighted(false)
                            parent:setOutlineHighlight(false);
                        end
                    end
                    -- prep to have this run on re-open
                    self.coloredInvs = self.keptColors
                    self.keptColors = nil
                end
            else
                -- if we had some colors selected, unset when not using a mingler
                if self.keptColors then
                    for i=1, #self.keptColors  do
                        local parent = self.keptColors[i]
                        if parent then
                            parent:setHighlighted(false)
                            parent:setOutlineHighlight(false);
                        end
                    end
                    self.keptColors = nil
                end
            end
        end
        ------------------------------------------

        if not spiff.Conf.enableInv or not self.isMouse then
            return
        end
        
        ------------------------------------------
        self.collapseCounter = 0
        
        self.wasVisible = not self.isCollapsed

        if not self.onCharacter and not self.isCollapsed and self.inventoryPane.inventory:getType() == "floor" and self.inventoryPane.inventory:getItems():isEmpty() then
            if self.autoHide and self.holdOpen and not self.prevMouse and not spiff.Conf.mouseHide then
                self:Collapse(true, "No Floor Items")
            end
        end

        if not self.isCollapsed then

            if not self.fVisible then
                -- When we stop dragging, set panel to close after next mouseout or click, or set to tie with our friend
                if (not ISMouseDrag.dragging or #ISMouseDrag.dragging == 0) then
                    if self.fromDrag then
                        self.fromDrag = false
                        self.autoHide = true
                        self.wasDrag = self.friend.mouseOver
                        self.holdOpen = not self.wasDrag
                    end

                    if self.toDrag then 
                        -- If we're not dragging anything and we're not moused over and not from where we started, close
                        if not self.mouseOver then
                            self.toDrag = false
                            self.autoHide = true
                        end

                        -- If we're no longer dragging items, but we're still on our window
                        if self:isMouseInBuffer() then
                            self.toDrag = false
                        end
                    end
                else
                    -- If we have dragged items, but we're not in our window
                    if  self.toDrag and not self:isMouseInBuffer() then
                        self.toDrag = false
                        self.autoHide = true
                    end
                end

            end

            -- If we should autohide
            --- prevmouse is to not have this happen immediately, we need a tick for other logic to kick in on state change
            --- holdOpen should prevent the window from closing if we click on an object
            --- We do this here so we can check the mouse location with our buffer
            if not self.fVisible and not spiff.Conf.mouseHide and self.autoHide 
                and not self.prevMouse and not self.holdOpen and not self.fromDrag 
                and not self.toDrag and not self.wasDrag and not self:isMouseInBuffer()
                and not getPlayerContextMenu(self.player):isReallyVisible() then
                self:Collapse(true, "Autohide")
            end

        else
            
            -- If we are dragging items from the other inventory to our window
            if not self.fVisible then
                if (ISMouseDrag.dragging and #ISMouseDrag.dragging > 0) and not self.fromDrag and self:isMouseInBuffer() then
                    self:Collapse(false, "From Drag!")
                    self.toDrag = true
                    self.autoHide = true
                end

                -- If mouse is at the top of the screen, show. but not when esc is used, or when a context menu is visible, or right mouse button is down
                if not self.toDrag and not self.fromDrag and not getSpecificPlayer(self.player):isAiming() and not self.collapsing
                and not MainScreen.instance:isVisible() and not getPlayerContextMenu(self.player):isReallyVisible() then
                    if not self.friend.wasVisible then
                        if self:isMouseInTop() then
                            self:Collapse(false, "MouseMoveIn")
                            self.autoHide = true
                        end
                    else
                        if self:isMouseInTop() then
                            self:Collapse(false, "MouseMoveInFriend")
                            self.autoHide = true
                        end
                    end
                end
            else
                self:Collapse(false, "force visible")
            end
        end

        if self.collapsing then
            self.collapsing = false
        end
    end

    sui.started = true
    -- Sync active functions
    sui.OnConfigSync()
end

sui.OnConfigSync = function()
    if not sui.started then return end
    for i,v in pairs(sui.Overrides) do
        if not v.noTetris or (v.noTetris and not spiff.hasTetris) then
            ISInventoryPage[i] = (spiff.Conf.enableInv and v.new) or v.old
        end
    end

    for i=1, #ISPlayerData do
        ISPlayerData[i].playerInventory:setDecVisible(not spiff.Conf.enableInv)
        ISPlayerData[i].lootInventory:setDecVisible(not spiff.Conf.enableInv)
    end
    
end

sui.Reset = function()
    if not sui.started or not spiff.Conf.enableInv then return end
    for i=1, #ISPlayerData do
        ISPlayerData[i].playerInventory:SUIReset()
        ISPlayerData[i].lootInventory:SUIReset()
    end
end

sui.OnCreatePlayerDataObject = function(id)
    --print("WHAT:OnCreatePlayerDataObject")
    local inv = getPlayerInventory(id)
    local loot = getPlayerLoot(id)

    inv:InitSUI()
    loot:InitSUI()    

    -- Make them Friends!
    inv.friend = loot
    loot.friend = inv

    if spiff.Conf.enableInv then
        -- Start collapsed
        inv:Collapse(true, "Start")
        loot:Collapse(true, "Start")
    end
end

return sui
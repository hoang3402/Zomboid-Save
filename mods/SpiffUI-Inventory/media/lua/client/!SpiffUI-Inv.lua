------------------------------------------
-- SpiffUI Main Library
------------------------------------------
-- Authors: 
---- @dhert (2022)
------------------------------------------
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
------------------------------------------

------------------------------------------
-- Set the SpiffUI lib version 
local SPIFFUI_VERSION = 5 --<<< DO NOT CHANGE UNLESS YOU KNOW WHAT YOU'RE DOING
if SpiffUI then 
    if SpiffUI.Version >= SPIFFUI_VERSION then
        return -- Don't do anything else
    else
        -- We only want the newest version, and this is it
        Events.OnGameBoot.Remove(SpiffUI.firstBoot)
        SpiffUI = nil
    end
end

------------------------------------------
-- Start SpiffUI
SpiffUI = {}
SpiffUI.Version = SPIFFUI_VERSION

------------------------------------------
-- These fixes/tweaks are included in other mods, so this prevents from multiple runnings
Exterminator = Exterminator or {}

if not Exterminator.onEnterFromGame then
    -- Protects Against a Known Options Bug
    ---- Thanks Burryaga!
    Exterminator.onEnterFromGame = MainScreen.onEnterFromGame
    function MainScreen:onEnterFromGame()
        Exterminator.onEnterFromGame(self)
        -- Guarantee that when you ENTER the options menu, the game does not think you've already changed your options.
        MainOptions.instance.gameOptions.changed = false
    end
end

-- Adds an event when Game Options are changed
if not Exterminator.MainOptions_apply then
    LuaEventManager.AddEvent("OnSettingsApply")
    Exterminator.MainOptions_apply = MainOptions.apply
    function MainOptions:apply(closeAfter)
        Exterminator.MainOptions_apply(self, closeAfter)
        triggerEvent("OnSettingsApply")
    end
end

-- Adds an event for when a player joins via a controller, and the UI is rebuilt
---- Runs for each player
if not Exterminator.OnCreatePlayerDataObject then
    LuaEventManager.AddEvent("OnCreatePlayerDataObject")
    Exterminator.OnCreatePlayerDataObject = ISPlayerDataObject.createInventoryInterface
    function ISPlayerDataObject:createInventoryInterface()
        Exterminator.OnCreatePlayerDataObject(self)
        triggerEvent("OnCreatePlayerDataObject", self.id)
    end
end
------------------------------------------

------------------------------------------
-- Register Module
SpiffUI.Mods = {}
function SpiffUI:Register(name)
    if not SpiffUI.Mods[name] then
        -- Add module
        SpiffUI.Mods[name] = {}
    end
    return SpiffUI.Mods[name]
end


------------------------------------------
-- Overrides for already-defined keys
SpiffUI.KeyDefaults = {}

-- Add a new Key Default
function SpiffUI:AddKeyDefault(name, key)
    SpiffUI.KeyDefaults[name] = tonumber(key)
end

-- Add an array of keys
---- Expected: 
---- binds { 
----    ["Name"] = key,
---- }
function SpiffUI:AddKeyDefaults(binds)
    for i,j in pairs(binds) do
        self:AddKeyDefault(i,j)
    end
end

------------------------------------------
-- Keys that will be removed from the binds
SpiffUI.KeyDisables = {}

-- Add a new Key Disable
function SpiffUI:AddKeyDisable(name)
    -- We do it where the name is the index to avoid dupes
    SpiffUI.KeyDisables[name] = true
end

-- Add an array of keys
---- Expected: 
---- binds { 
----    ["Name"] = true,
---- }
function SpiffUI:AddKeyDisables(binds)
    for i,_ in pairs(binds) do
        self:AddKeyDisable(i)
    end
end

------------------------------------------
-- New Keys to Add
SpiffUI.KeyBinds = {
    {
        name = '[SpiffUI]', -- Title
    }
}

-- Builds the optimized KeyBinds array, indexed by key
local _keybinds
local _buildKeys = function()
    _keybinds = {}
    for _,v in ipairs(SpiffUI.KeyBinds) do
        if v.key then -- has a key
            local key = getCore():getKey(v.name)
            if key then
                local obj = _keybinds[key] or {}
                obj[#obj+1] = {
                    down = v.Down,
                    hold = v.Hold,
                    up = v.Up,
                    block = v.qBlock
                }
                _keybinds[key] = obj
            end
        end
    end
end
Events.OnSettingsApply.Add(_buildKeys)

-- Add a new Key Bind
---- Expected:
---- bind = { 
----    name = 'KeyBind',    -- Name of Key
----    key = Keyboard.KEY,  -- Key
----    qBlock = true,       -- Don't perform key action with queue
----    Down = actionDown,   -- Action on Down -- Receives playerObj  -- Optional
----    Hold = actionHold,   -- Action on Hold -- Receives playerObj  -- Optional
----    Up = actionUp        -- Action on Up   -- Receives playerObj  -- Optional
---- }
function SpiffUI:AddKeyBind(bind)
    --SpiffUI.KeyDefaults[name] = tonumber(key)
    --print("Bind: " .. tostring(bind.name) .. " | Down: " .. tostring(bind.Down))
    table.insert(SpiffUI.KeyBinds, bind)
end

-- Add an array of keys
---- Expected: 
---- binds = { 
----     { 
----        name = 'KeyBind',    -- Name of Key
----        key = Keyboard.KEY,  -- Key
----        qBlock = true,        -- Don't perform key action with queue
----        Down = actionDown,   -- Action on Down -- Receives playerObj  -- Optional
----        Hold = actionHold,   -- Action on Hold -- Receives playerObj  -- Optional
----        Up = actionUp        -- Action on Up   -- Receives playerObj  -- Optional
----    },
---- }
function SpiffUI:AddKeyBinds(binds)
    for _,j in ipairs(binds) do
        self:AddKeyBind(j)
    end
end

------------------------------------------
-- Key Handlers
-- Common things to check for when checking a key
---- Returns the player object if successful
SpiffUI.preCheck = function()
    local player = getSpecificPlayer(0)

    if not player or player:isDead() or player:isAsleep() then
        return nil
    end

    return player
end

local _queue = ISTimedActionQueue.queues

local function keyDown(key)
    local player = SpiffUI.preCheck()
    if not player then return end

    if _keybinds[key] then
        local obj = _keybinds[key]
        for i=1, #obj do
            if obj[i].down then
                local q = _queue[player]
                if (not q or #q.queue == 0) or not obj[i].block then
                    obj[i].down(player)
                end
            end
        end
    end
end

local function keyHold(key)
    local player = SpiffUI.preCheck()
    if not player then return end

    if _keybinds[key] then
        local obj = _keybinds[key]
        for i=1, #obj do
            if obj[i].hold then
                local q = _queue[player]
                if (not q or #q.queue == 0) and not obj[i].block then
                    obj[i].hold(player)
                end
            end
        end
    end
end

local function keyRelease(key)
    local player = SpiffUI.preCheck(key)
    if not player then return end

    if _keybinds[key] then
        local obj = _keybinds[key]
        for i=1, #obj do
            if obj[i].up then
                local q = _queue[player]
                if (not q or #q.queue == 0) and not obj[i].block then
                    obj[i].up(player)
                end
            end
        end
    end
end

------------------------------------------
-- Key Action Handlers
---- used mostly for radials
SpiffUI.action = {
    ticks = 0,
    delay = 500,
    ready = true,
    wasVisible = false
}

-- onKeyDown starts an action
SpiffUI.onKeyDown = function(player)
    -- The radial menu will also close without updating me
    ---- So we need to catch this
    local radialMenu = getPlayerRadialMenu(0)
    if SpiffUI.action.ready and (not radialMenu:isReallyVisible() and SpiffUI.action.wasVisible) then
        SpiffUI.action.ready = true
    end

    -- True means we're not doing another action
    if SpiffUI.action.ready then
        -- Hide Radial Menu on Press if applicable
        if radialMenu:isReallyVisible() and getCore():getOptionRadialMenuKeyToggle() then
            radialMenu.timeActionKeep = nil
            radialMenu:undisplay()
            setJoypadFocus(player:getPlayerNum(), nil)
            SpiffUI.action.wasVisible = false
            SpiffUI.action.ready = true
            return
        end
        SpiffUI.action.ticks = getTimestampMs()
        SpiffUI.action.ready = false
        SpiffUI.action.wasVisible = false
    end
end

-- We check here and set our state if true on hold
SpiffUI.holdTime = function()
    if SpiffUI.action.ready then return false end
    SpiffUI.action.ready = (getTimestampMs() - SpiffUI.action.ticks) >= SpiffUI.action.delay
    return SpiffUI.action.ready
end

-- We check here and set our state if true on release
SpiffUI.releaseTime = function()
    if SpiffUI.action.ready then return false end
    SpiffUI.action.ready = (getTimestampMs() - SpiffUI.action.ticks) < SpiffUI.action.delay
    return SpiffUI.action.ready
end

SpiffUI.resetKey = function()
    SpiffUI.action.ready = true
end

------------------------------------------
-- ISEquippedItem Buttons
SpiffUI.equippedItem = {
    ["Inventory"] = true,
    ["Health"] = true,
    ["QOLEquip"] = true,
    ["Craft"] = true,
    ["Movable"] = true,
    ["Search"] = true,
    ["Map"] = true,
    ["MiniMap"] = true,
    ["Debug"] = true,
    ["Client"] = true,
    ["Admin"] = true
}

function SpiffUI:updateEquippedItem()
    -- Redo the ISEquippedItem tree based on what we set
    local player = getPlayerData(0)
    local y = player.equipped.invBtn:getY()
    -- Add support for the QOL Equipment mod's icon
    SpiffUI.equippedItem["QOLEquip"] = (SETTINGS_QOLMT and SETTINGS_QOLMT.options and SETTINGS_QOLMT.options.useIcon) or false
    for i,v in pairs(SpiffUI.equippedItem) do
        if i == "Inventory" then
            player.equipped.invBtn:setVisible(v)
            if v then
                y = player.equipped.invBtn:getY() + player.equipped.inventoryTexture:getHeightOrig() + 5
            end
        elseif i == "Health" then
            player.equipped.healthBtn:setVisible(v)
            player.equipped.healthBtn:setY(y)
            if v then
                y = player.equipped.healthBtn:getY() + player.equipped.heartIcon:getHeightOrig() + 5
            end
        -- Add support for the QOL Equipment mod's icon
        elseif i == "QOLEquip" and player.equipped.equipButton then
            player.equipped.equipButton:setVisible(v)
            player.equipped.equipButton:setY(y)
            if v then
                y = player.equipped.equipButton:getY() + player.equipped.equipmentIconOFF:getHeightOrig() + 5
            end
        elseif i == "Craft" then
            player.equipped.craftingBtn:setVisible(v)
            player.equipped.craftingBtn:setY(y)
            if v then
                y = player.equipped.craftingBtn:getY() + player.equipped.craftingIcon:getHeightOrig() + 5
            end
        elseif i == "Movable" then
            player.equipped.movableBtn:setVisible(v)
            player.equipped.movableBtn:setY(y)
            player.equipped.movableTooltip:setY(y)
            player.equipped.movablePopup:setY(y)
            if v then
                y = player.equipped.movableBtn:getBottom() + 5
            end
        elseif i == "Search" then
            player.equipped.searchBtn:setVisible(v)
            player.equipped.searchBtn:setY(y)
            if v then
                y = player.equipped.searchBtn:getY() + player.equipped.searchIconOff:getHeightOrig() + 5
            end
        elseif i == "Map" then
            if ISWorldMap.IsAllowed() then
                player.equipped.mapBtn:setVisible(v)
                player.equipped.mapBtn:setY(y)
                
                if ISMiniMap.IsAllowed() then
                    player.equipped.mapPopup:setY(10 + y)
                end

                if v then
                    y = player.equipped.mapBtn:getBottom() + 5
                end
            end
        elseif i == "Debug" then
            if getCore():getDebug() or (ISDebugMenu.forceEnable and not isClient()) then
                player.equipped.debugBtn:setVisible(v)
                player.equipped.debugBtn:setY(y)
                if v then
                    y = player.equipped.debugBtn:getY() + player.equipped.debugIcon:getHeightOrig() + 5
                end
            end
        elseif i == "Client" then
            if isClient() then
                player.equipped.clientBtn:setVisible(v)
                player.equipped.clientBtn:setY(y)
                if v then
                    y = player.equipped.clientBtn:getY() + player.equipped.clientIcon:getHeightOrig() + 5
                end
            end
        elseif i == "Admin" then
            if isClient() then
                player.equipped.adminBtn:setVisible(v)
                player.equipped.adminBtn:setY(y)
            end
        end
    end
end

Events.OnCreatePlayerDataObject.Add(function(id) 
    SpiffUI:updateEquippedItem()
    for _,mod in pairs(SpiffUI.Mods) do
        if mod and mod.OnCreatePlayerDataObject then
            mod.OnCreatePlayerDataObject(id)
        end
    end
end)

------------------------------------------

SpiffUI.debug = false

local _conf = {}

-- Make this local to help prevent external modifications
_conf.configs = {
    ["base"] = {
        options = {
            applyNewKeybinds = {
                name = "UI_ModOptions_SpiffUI_applyNewKeybinds",
                default = function() _conf:showKeyDialog() end
            }

        },
        name = getText("UI_Name_SpiffUI"),
        columns = 4
    }
}

if isDebugEnabled() then
    _conf.configs["base"].options.debug = {
        name = "Enable Debug",
        default = false
    }
end

function _conf:keyString(text,h)
    for name,key in pairs(SpiffUI.KeyDefaults) do
        text = text .. getText("UI_ModOptions_SpiffUI_Modal_aNKChild", getText("UI_optionscreen_binding_" .. name), getKeyName(key))
        h = h + 20
    end
    return text,h
end

function _conf:showKeyDialog()
    local text,h = self:keyString(getText("UI_ModOptions_SpiffUI_Modal_applyNewKeybinds"), 120)
    self:settingsPopup(350, h, text, _conf.applyNewKeybinds)
end

function _conf:applyNewKeybinds(button)
    self.modal = nil
    if button.internal == "NO" then
        return
    end
    for name,key in pairs(SpiffUI.KeyDefaults) do
        for i,v in ipairs(MainOptions.keyText) do
            if not v.value then
                if v.txt:getName() == name then
                    v.keyCode = key
                    v.btn:setTitle(getKeyName(key))
                    break
                end
            end
        end
    end
    getCore():saveOptions()
    MainOptions.instance.gameOptions.changed = false
end

function _conf:resetString(text,h)
    for _,mod in pairs(SpiffUI.Mods) do
        if mod and mod.Reset then
            if mod.resetDesc then
                text = text .. mod.resetDesc
            else
                text = text .. " <LINE> " .. j
            end
            h = h + 20
        end
    end
    return text,h
end

function _conf:showResetDialog()
    local text,h = self:resetString(getText("UI_ModOptions_SpiffUI_Modal_runResets"), 120)
    self:settingsPopup(350, h, text, _conf.runResets)
end

function _conf:runResets()
    for _,mod in pairs(SpiffUI.Mods) do
        if mod and mod.Reset then
            mod.Reset()
        end
    end
end

function _conf:showImportDialog()
    self:settingsPopup(350, 120, getText("UI_ModOptions_SpiffUI_Modal_importModOptions"), _conf.importModOptions)
end

function _conf:importModOptions()
    local config = {}
    local file = getFileReader("mods_options.ini", false)
    local line = ""
    local sec
    local found = false
    local imports = {
        ["SpiffUI - Inventory"] = "inventory",
        ["SpiffUI-Rads"] = "radials",
        ["SpiffUI-zMinimap"] = "map"
    }
    if file then
        while true do
            line = file:readLine()
            if not line then 
                break
            end
            line = line:trim()
            if line ~= "" then
                local next = false 
                local k = line:match('^%[([^%[%]]+)%]$')
                if k and imports[k] then
                    found = true
                    next = true
                    sec = imports[k]
                elseif k and not imports[k] then
                    found = false -- we found the next one, so we're done
                    sec = nil
                end
                if found and not next then 
                    local i, v = line:match('^([%w|_]+)%s-=%s-(.+)$')
                    if(i and v)then
                        v = v:trim()
                        i = i:trim()
                        if(tonumber(v))then
                            v = tonumber(v)
                        elseif(v:lower() == 'true')then
                            v = true
                        elseif(v:lower() == 'false')then
                            v = false
                        else -- we only want the above
                            v = nil
                        end
                        self.configs[sec] = self.configs[sec] or {}
                        self.configs[sec].options = self.configs[sec].options or {}
                        self.configs[sec].options[i] = self.configs[sec].options[i] or {}
                        self.configs[sec].options[i].value = v
                    end
                end
            end
        end
        file:close()
    end

    self:Save()
    -- reset to make sure that the configuration changes take in place.
    ---- also, i'm too lazy to rewrite this to let me update all of the UI Elements for something that should only be run once. :)
    getCore():DelayResetLua("default", "importModOptions")
end

function _conf:Print()
    for n,sec in pairs(self.configs) do
        print("SECTION: " .. tostring(n))
        if sec.options then
            for _,data in pairs(sec.options) do
                print("   " ..tostring(data.name) .. " | " .. tostring(data.value))
            end
        end
    end
end

-- ensure that ALL config options have a value
function _conf:prepConfig() 
    for _,sec in pairs(self.configs) do
        if sec.options and not sec.disabled then
            for _,data in pairs(sec.options) do
                if type(data.default) ~= 'function' and data.default ~= 'Seperator' then
                    if data.value == nil then 
                        data.value = data.default
                    end
                end
            end
        end
    end
end

-- Build gathers all available configuration from the enabled SpiffUI modules.
function _conf:build()
    for j,mod in pairs(SpiffUI.Mods) do
        if mod.BuildConfig then
            self.configs[j] = mod:BuildConfig()
        end
    end
end

-- Sync our active configurations into the modules
function _conf:Sync()
    if _conf.configs["base"].options.debug and _conf.configs["base"].options.debug.value then
        print("SUI Syncing Config")
        SpiffUI.debug = true
    end

    for j,mod in pairs(SpiffUI.Mods) do
        mod.Conf = {}
        if self.configs[j] then
            for i,v in pairs(self.configs[j].options) do
                mod.Conf[i] = v.value
            end
        elseif SpiffUI.debug then
            print("SUI ERROR: Failed to Sync Options | Mod: " .. j)
        end

        -- get any Sandbox variables
        if mod.SandboxName and self.inGame then
            local vars = SandboxVars[mod.SandboxName]
            if vars then
                for i,v in pairs(vars) do
                    mod.Conf[i] = v
                end 
            elseif SpiffUI.debug then
                print("SUI ERROR: Failed to load Sanbox: " .. mod.SandboxName .. " | Mod: " .. j)
            end
        end

        -- Perform any additional changes to the config
        if mod.OnConfigSync then mod.OnConfigSync() end

        if SpiffUI.debug then
            print("  SUI Synced: " .. j)
            for i,v in pairs(mod.Conf) do
                print("   KEY: " .. tostring(i) .. " | VALUE: " .. tostring(v))
            end
        end
    end
end

function _conf:boot()


    self:build()
    self:Load()
    self:prepConfig()
    self:Sync()
end

function _conf:Save()
    local file = getFileWriter("spiffui.ini", true, false)
    for section, data in pairs(self.configs) do
        if data.options then
            file:write("[" .. section .. "]\n")
            for k,v in pairs(data.options) do
                if v.value ~= nil and v.value ~= v.default then
                    file:write(tostring(k) .. " = " .. tostring(v.value) .. "\n")
                end
            end
            file:write("\n")
        end
    end
    file:close()
end

function _conf:Load()
    local file = getFileReader("spiffui.ini", false)
    local cur = ""
    if file then
        while true do
            local line = file:readLine()
            if not line then 
                file:close() 
                break
            end
            line = line:trim()
            if line ~= "" then
                local k = line:match('^%[([^%[%]]+)%]$')
                if k then
                    k = k:trim()
                    cur = k
                    if not self.configs[cur] then
                        self.configs[cur] = {
                            options = {},
                            disabled = true -- if it doesn't exist already, then its not loaded
                        }
                    end
                else
                    local i, v = line:match('^([%w|_]+)%s-=%s-(.+)$')
                    if(i and v)then
                        v = v:trim()
                        i = i:trim()
                        if(tonumber(v))then
                            v = tonumber(v)
                        elseif(v == 'true')then
                            v = true
                        elseif(v == 'false')then
                            v = false
                        end
                        -- Required to not lose unloaded mods
                        if not self.configs[cur].options[i] then
                            self.configs[cur].options[i] = {
                                value = v
                            }
                        end
                        self.configs[cur].options[i].value = v 
                    end
                end
            end
        end
        file:close()
    end

    if not isDebugEnabled() then
        if _conf.configs["base"].options.debug then
            -- unset this if not in debug
            _conf.configs["base"].options.debug = nil
        end
    end
end

function _conf:settingsPopup(w, h, text, callback)
    self.modal = ISModalRichText:new((getCore():getScreenWidth() / 2) - w / 2,
                    (getCore():getScreenHeight() / 2) - h / 2, w, h,
                    text, true, self, callback)
    self.modal:initialise()
    self.modal:setCapture(true)
    self.modal:setAlwaysOnTop(true)
    self.modal:addToUIManager()

    local noClick = function()
        self.modal:destroy()
    end

    self.modal.no.onmousedown = noClick

    if MainOptions.joyfocus then
        MainOptions.joyfocus.focus = self.modal
        updateJoypadFocus(self.joyfocus)
    end
end

function _conf:buildTab(inGame)
    _conf.inGame = inGame
    if inGame then
        self.configs.base.options.runAllResets = {
            name = "UI_ModOptions_SpiffUI_runAllResets",
            tooltip = "UI_ModOptions_SpiffUI_tooltip_runResets",
            default = function() _conf:showResetDialog() end
        }
        self.configs.base.options.importModOptions = nil
    else
        self.configs.base.options.importModOptions = {
            name = "UI_ModOptions_SpiffUI_importModOptions",
            tooltip = "UI_ModOptions_SpiffUI_importModOptions_tt",
            default = function() _conf:showImportDialog() end
        }
        self.configs.base.options.runAllResets = nil
    end
    local opts = MainOptions.instance

    ------------------------------------------
    -- Stolen from MainOptions :D
    local HorizontalLine = ISPanel:derive("HorizontalLine")

    function HorizontalLine:render()
        self:drawRect(0, 0, self.width, 1, 1.0, 0.5, 0.5, 0.5)
    end

    function HorizontalLine:new(x, y, width)
        local o = ISPanel.new(self, x, y, width, 2)
        return o
    end

    -- Game options also taken from MainOptions
    local GameOption = ISBaseObject:derive("GameOption")
    function GameOption:new(name, control, arg1, arg2)
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o.name = name
        o.control = control
        o.arg1 = arg1
        o.arg2 = arg2
        if control.isCombobox then
            control.onChange = self.onChangeComboBox
            control.target = o
        end
        if control.isTickBox then
            control.changeOptionMethod = self.onChangeTickBox
            control.changeOptionTarget = o
        end
        if control.isSlider then
            control.targetFunc = self.onChangeVolumeControl
            control.target = o
        end
        return o
    end

    function GameOption:toUI()
        print('ERROR: option "'..self.name..'" missing toUI()')
    end
    
    function GameOption:apply()
        print('ERROR: option "'..self.name..'" missing apply()')
    end
    
    function GameOption:resetLua()
        opts.resetLua = true
    end

    function GameOption:onChangeComboBox(box)
        opts.gameOptions:onChange(opts)
        if self.onChange then
            self:onChange(box)
        end
    end
    
    function GameOption:onChangeTickBox(index, selected)
        opts.gameOptions:onChange(opts)
        if self.onChange then
            self:onChange(index, selected)
        end
    end

    function GameOption:onChangeVolumeControl(control, volume)
        opts.gameOptions:onChange(opts)
        if self.onChange then
            self:onChange(control, volume)
        end
    end
    ------------------------------------------

    local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
    local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
    -- add our settings tab
    opts:addPage(getText("UI_Name_SpiffUI"))
    opts.addY = 0

    local function colW(cols)
        return (opts:getWidth() - 120) / (cols or 1)
    end

    local function colX(x, cols)
        return 60 + (colW(cols) * x)
    end

    local space = 12

    local y = 20

    local lHeight = FONT_HGT_SMALL + 2

    ------------------------------------------

    local function makeSeparator(txt)
        local sbarWidth = 13
        
        local hLine = HorizontalLine:new(colX(0), y, opts.width - 120)
        hLine.anchorRight = true
        opts.mainPanel:addChild(hLine)

        local label = ISLabel:new(100, y + 8, FONT_HGT_MEDIUM, txt, 1, 1, 1, 1, UIFont.Medium)
        label:setX(colX(0))
        label:initialise()
        label:setAnchorRight(true)
        opts.mainPanel:addChild(label)

        y = y + FONT_HGT_MEDIUM + space
    end

    local function makeButton(data, x, w)
        local txt = getText(data.name)
        local textWid = getTextManager():MeasureStringX(UIFont.Small, txt)
        local btnWid = textWid + 20
        if btnWid < 120 then
            btnWid = 120
        end

        local btn = ISButton:new(x, y, btnWid, lHeight, txt, SpiffUI, data.default)
        btn:initialise()
        btn:instantiate()
        opts.mainPanel:addChild(btn)
        if data.tooltip then
            btn.tooltip = getText(data.tooltip)
        end
        opts.addY = 0
    end

    local function makeCheckbox(data, x, w)
        local txt = getText(data.name)

        local tick = opts:addYesNo(x, y, w/2, lHeight, txt)
        if data.tooltip then
            tick.tooltip = getText(data.tooltip)
        end
        opts.addY = 0

        local option = GameOption:new(data.name, tick)
        --data.option = option
        function option:toUI()
            self.control:setSelected(1, data.value)
        end
        function option:apply()
            local set = self.control:isSelected(1)
            if set ~= data.value then
                data.value = set
            end
        end

        opts.gameOptions:add(option)
	end

    local function makeCombo(data, x, w)
        local txt = getText(data.name)

        -- get our available opts
        local cOpts = {}
		for _,v in ipairs(data) do
			table.insert(cOpts, getText(v))
		end

		local combo = opts:addCombo(x, y, w/2, lHeight, txt, cOpts, 1)
		if data.tooltip then
			local map = {}
			map["defaultTooltip"] = getText(data.tooltip)
			combo:setToolTipMap(map)
		end
        opts.addY = 0

        local option = GameOption:new(data.name, combo)
        --data.option = option
        function option:toUI()
            self.control.selected = tonumber(data.value) or 1
        end
        function option:apply()
            local set = self.control.selected
            if data[set] and set ~= data.value then
                data.value = set
            end
        end

        opts.gameOptions:add(option)
    end

    local function makeText(data, x, w)
        if not data.name then return end
        local txt = getText(data.name)
        local label = ISLabel:new(x, y, lHeight, txt, 1, 1, 1, 1, UIFont.Small)
        label:initialise()
        opts.mainPanel:addChild(label)
        opts.addY = 0
    end

    local function nextLine()
        y = y + lHeight + space
    end

    local function miniSeperator(txt, x, w)
        local label = ISLabel:new(x, y, FONT_HGT_MEDIUM, txt, 1, 1, 1, 1, UIFont.Medium)
        label:setX(x-(w/4))
        label:initialise()
        label:setAnchorRight(true)
        opts.mainPanel:addChild(label)
        
        local hLine = HorizontalLine:new(x-(w/4), y - FONT_HGT_MEDIUM/2, w*2.5)
        hLine.anchorRight = true
        opts.mainPanel:addChild(hLine)
    end
    ------------------------------------------

    -- Sort our sections alphabetically
    local orderd = {}
    for i,_ in pairs(self.configs) do 
        orderd[#orderd+1] = i
    end
    table.sort(orderd)

    ------------------------------------------
    for _,sec in ipairs(orderd) do
        local conf = self.configs[sec]
        local col = 1
        
        if not conf.columns then conf.columns = 2 end
        if getCore():getOptionFontSize() == 2 and conf.columns > 3 then
            conf.columns = conf.columns - 1
        elseif getCore():getOptionFontSize() > 2 then
            conf.columns = 2
        end
        local colw = colW(conf.columns)
        if conf.name and conf.options and not conf.disabled then
            makeSeparator(conf.name)
            
            for _,data in pairs(conf.options) do
                if type(data.default) == 'boolean' then
                    makeCheckbox(data, colX(col, conf.columns), colw)
                elseif type(data.default) == 'function' then
                    makeButton(data, colX(col, conf.columns), colw)
                elseif type(data.default) == 'number' then
                    makeCombo(data, colX(col, conf.columns), colw)
                elseif type(data.default) == 'string' then
                    if data.default == "Seperator" then
                        -- new line here
                        nextLine()
                        if col > 1 then
                            -- Another if needed
                            nextLine()
                            col = 1
                        end
                        miniSeperator(getText(data.name), colX(col, 6), colW(3))
                        col = 9999
                    end
                elseif not data.default then
                    -- Just print the name
                    makeText(data, colX(col, conf.columns), colw)
                end

                if data.endline then
                    -- force a new line
                    col = 9999                
                end

                col = col + 1
                if col >= conf.columns then
                    col = 1
                    nextLine()
                end
            end

            -- ensure new line on end
            nextLine()
            if col > 1 then
                nextLine()
            end
        end
    end
    opts.mainPanel:setScrollHeight(y)
    opts.addY = 0
end

local _MainOptions_apply = MainOptions.apply
function MainOptions:apply(closeAfter)
    _MainOptions_apply(self, closeAfter)
    _conf:Save()
    _conf:Sync()
end

if Events.OnSandboxOptionsChanged then
    Events.OnSandboxOptionsChanged.Add(function()
        _conf:Sync()
    end)
end
------------------------------------------

SpiffUI.firstBoot = function()
    SpiffUI:OnGameBoot()
end

function SpiffUI:OnGameBoot()
    -- Add our OnPostBoot to run last
    ---- BindAid will still run last though
    Events.OnGameBoot.Add(function()
        SpiffUI:OnPostBoot()
    end)
    
    Events.OnGameStart.Add(function()
        _conf:buildTab(true)
        -- Cheeky way to ensure SpiffUI runs last OnGameStart
        ---- During GameStart, add our function to GameStart :)
        Events.OnGameStart.Add(function()
            SpiffUI:OnGameStart()
        end)
    end)

    -- For the Main Menu
    Events.OnMainMenuEnter.Add(function()
        _conf:buildTab(false)
    end)

    -- For In Game
    Events.OnInitGlobalModData.Add(function()
        _conf:Sync()
    end)

    Events.OnCreatePlayer.Add(function(id)
        SpiffUI:OnCreatePlayer(id)
    end)

    -- Ready our configuration
    _conf:boot()

    -- Run all our other Boot Functions
    for _,mod in pairs(SpiffUI.Mods) do
        if mod and mod.Boot then
            mod.Boot()
        end
    end

    local _MainOptions_onResolutionChange = MainOptions.onResolutionChange
    function MainOptions:onResolutionChange(oldw, oldh, neww, newh)
        _MainOptions_onResolutionChange(self, oldw, oldh, neww, newh)
        self:centerTabChildrenX(getText("UI_Name_SpiffUI"))
    end
end
-- Boot here
Events.OnGameBoot.Add(SpiffUI.firstBoot)

function SpiffUI:OnPostBoot()
    -- Run all our other PostBoot Functions
    for _,mod in pairs(SpiffUI.Mods) do
        if mod and mod.PostBoot then
            mod.PostBoot()
        end
    end

    -- Now let's add our keybinds!
    if #SpiffUI.KeyBinds > 1 then
        for _, bind in ipairs(SpiffUI.KeyBinds) do
            table.insert(keyBinding, { value = bind.name, key = bind.key }) 
        end
    end

    -- Let's Remove some keys, possibly added by mods too
    for name,_ in pairs(SpiffUI.KeyDisables) do
        local found = false
        for i = 1, #keyBinding do
            if keyBinding[i].value == name then
                table.remove(keyBinding, i)
                --print("Removed Keybind: " .. name)
                found = true
                break
            end
        end

        -- We may have a SpiffUI key we want to remove
        if not found then
            for i,bind in ipairs(SpiffUI.KeyBinds) do
                if bind.name == name then
                    table.remove(SpiffUI.KeyBinds, i)
                    --print("Removed SpiffUI Keybind: " .. name)
                    break
                end
            end
        end
    end
end

------------------------------------------

function SpiffUI:OnGameStart()
    _buildKeys()
    Events.OnKeyStartPressed.Add(keyDown)
    Events.OnKeyKeepPressed.Add(keyHold)
    Events.OnKeyPressed.Add(keyRelease)

    for _,mod in pairs(SpiffUI.Mods) do
        if mod and mod.Start then
            mod.Start()
        end
    end

    self:updateEquippedItem()
end

------------------------------------------
function SpiffUI:OnCreatePlayer(id)
    for _,mod in pairs(SpiffUI.Mods) do
        if mod and mod.CreatePlayer then
            mod.CreatePlayer(id)
        end
    end
end
------------------------------------------

local function words(msg)
    local out = {}
    for i in msg:gmatch("%w+") do
        out[#out+1] = i
    end
    return out
end

SpiffUI.textwrap = function(message, limit, fontSize, center)
    local result = ""
    local width = 0

    local line = ""
    local lines = 0

    local dummy = ""
    local length = 0

    local ws = words(message)
    for i=1, #ws do
        dummy = line .. ws[i] .. " "
        if getTextManager():MeasureStringX(fontSize, dummy) > limit then
            length = getTextManager():MeasureStringX(fontSize, line:trim())
            result = result .. line:trim() .. "\n"
            line = ws[i] .. " "
            if length > width then width = length end
            lines = lines + 1
        else
            line = dummy
        end
    end

    -- -- Add the final line.
    result = ((center and "<CENTRE> ") or "") .. result .. line:trim()
    lines = lines + 1
    length = getTextManager():MeasureStringX(fontSize, line:trim())
    if length > width then width = length end

    return result, width, lines
end

------------------------------------------
-- Hello SpiffUI :)
print(getText("UI_Hello_SpiffUI"))
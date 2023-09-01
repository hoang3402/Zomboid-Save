local function SaveServerConfig(option_name)
    if isClient() then
        sendClientCommand(PlayersOnMap.MOD_ID, "SaveServerConfig", {
            config = PlayersOnMap.ServerConfig,
            option = option_name
        })
    else
        PlayersOnMap.io.write(PlayersOnMap.ServerConfigFileName, PlayersOnMap.ServerConfig)
    end
end

local function SaveClientConfig()
    PlayersOnMap.io.write(PlayersOnMap.ClientConfigFileName, PlayersOnMap.ClientConfig)
end

local GameOption = ISBaseObject:derive("GameOption")
function GameOption:new(name, control, arg1, arg2)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.name = name
    o.control = control
    o.arg1 = arg1
    o.arg2 = arg2

    if control.isTextEntryBox then
        control.onTextChange = function()
            o.gameOptions:onChange(self)
        end
    end

    if control.isTickBox then
        control.changeOptionMethod = self.onChangeTickBox
        control.changeOptionTarget = o
    end

    return o
end

function GameOption:toUI()
    print('ERROR: option "'..self.name..'" missing toUI()')
end

function GameOption:apply()
    print('ERROR: option "'..self.name..'" missing apply()')
end

function GameOption:onChangeTickBox(index, selected)
    self.gameOptions:onChange(self)
    if self.onChange then
        self:onChange(index, selected)
    end
end

-- MainOptions
local TextManager = getTextManager()
local FONT_HGT_SMALL = TextManager:getFontHeight(UIFont.Small)

local function validate(box, a, b)
    local text = box:getInternalText()
    box:setText(text)

    local num = tonumber(text) or a
    num =
        num <= a and a or 
        num >= b and b or 
        num

    box:setText(tostring(num))
    return num
end

function MainOptions:CreateLabel(x, y, h, title, r, g, b, a, font, left)
    local label = ISLabel:new(x, y + self.addY, h, title, r, g, b, a, font, left)
    label:initialise()
    self.mainPanel:addChild(label)
end

function MainOptions:CreateTickBox(x, y, w, h, admin_option, option_name, title, tooltip)
    local tickbox = self:addYesNo(x, y, w, h, title)
    local gameOption = GameOption:new(option_name, tickbox)
    tickbox.tooltip = tooltip

    function gameOption.toUI(self)
        local box = self.control

        if admin_option then
            box:setSelected(1, PlayersOnMap.ServerConfig[option_name])
        else
            box:setSelected(1, PlayersOnMap.ClientConfig[option_name])
        end
    end

    function gameOption.apply(self)
        local box = self.control
        local val = box:isSelected(1)

        if admin_option then
            if val ~= PlayersOnMap.ServerConfig[option_name] then
                PlayersOnMap.ServerConfig[option_name] = val
                SaveServerConfig(option_name)
            end
        else
            if val ~= PlayersOnMap.ClientConfig[option_name] then
                PlayersOnMap.ClientConfig[option_name] = val
                SaveClientConfig()
            end
        end
    end

    self.gameOptions:add(gameOption)
    self.addY = self.addY + h
end

function MainOptions:CreateTextBox(x, y, w, h, admin_option, option_name, title, tooltip, default, min_value, max_value)
    h = FONT_HGT_SMALL
    self:CreateLabel(x, y, h, title, 1, 1, 1, 1, UIFont.Small)
    local textEntry = ISTextEntryBox:new(default, x + 20, y + self.addY, w, h)

    textEntry.isTextEntryBox = true
    textEntry.tooltip = tooltip

    textEntry:initialise()
    textEntry:instantiate()
    textEntry:setOnlyNumbers(true)  
    self.mainPanel:addChild(textEntry)

    local gameOption = GameOption:new(option_name, textEntry)

    function gameOption.toUI(self)
        local box = self.control

        if admin_option then
            box:setText( tostring(PlayersOnMap.ServerConfig[option_name]) )
        else
            box:setText( tostring(PlayersOnMap.ClientConfig[option_name]) )
        end

        local val = box:getText()
        if not val or val == "" or not tonumber(val) then 
            box:setText(default) 
        end
    end

    function gameOption.apply(self)
        local box = self.control
        local number = validate(box, min_value, max_value)

        if admin_option then
            if number ~= PlayersOnMap.ServerConfig[option_name] then
                PlayersOnMap.ServerConfig[option_name] = number
                SaveServerConfig(option_name)
            end
        else
            if number ~= PlayersOnMap.ClientConfig[option_name] then
                PlayersOnMap.ClientConfig[option_name] = number
                SaveClientConfig()
            end
        end
    end

    function gameOption:onChange(box)
        if admin_option then
            PlayersOnMap.ServerConfig[option_name] = tonumber(box:getText())
        else
            PlayersOnMap.ClientConfig[option_name] = tonumber(box:getText())
        end
    end

    self.gameOptions:add(gameOption)
    self.addY = self.addY + h
end

local oldMainOptionsCreate = MainOptions.create
function MainOptions:create()
    oldMainOptionsCreate(self)

    self:addPage("Players On Map")
    self.addY = 0

    local oldGameOptionsToUI = self.gameOptions.toUI
    function self.gameOptions:toUI()
        oldGameOptionsToUI(self)
        self.changed = false
    end

    local x = self:getWidth() / 2
    local y, w, h = 25, 35, 10

    if isAdmin() or not isClient() then
        -- Create Admin Game Options
        self:CreateLabel(x + 25, y, h, 'Admin Options', 1, 1, 1, 1, UIFont.Medium)
        self.addY = y + self.addY
    
        self:CreateTickBox(x, y, w, h, true, 'AllowWorldMap', 'Allow World Map', 'Allow player dots to show on world map.')
        self:CreateTickBox(x, y, w, h, true, 'WorldAllowNames', 'Allow Names on World Map', 'Allow player dots to show name on world map.')
        self:CreateTickBox(x, y, w, h, true, 'WorldAllowHeight', 'Allow Height on World Map', 'Allow player dots to show height on World map.')
        self:CreateTextBox(x, y, w, h, true, 'WorldMaximumDistance', 'Maximum Distance on World Map', 'This will set the maximum distance players can see other player dots on the world map.', '-1', -1, 10000)
        y = y + h*2

        self:CreateTickBox(x, y, w, h, true, 'AllowMiniMap', 'Allow Mini Map', 'Allow player dots to show on mini map.')
        self:CreateTickBox(x, y, w, h, true, 'MiniAllowNames', 'Allow Names on Mini Map', 'Allow player dots to show name on mini map.')
        self:CreateTickBox(x, y, w, h, true, 'MiniAllowHeight', 'Allow Height on Mini Map', 'Allow player dots to show height on Mini map.')
        self:CreateTextBox(x, y, w, h, true, 'MiniMaximumDistance', 'Maximum Distance on Mini Map', 'This will set the maximum distance players can see other player dots on the mini map.', '-1', -1, 10000)
        y = y + h*2

        self:CreateTickBox(x, y, w, h, true, 'OnlyShowFaction', 'Only Show Faction', 'This will only allow faction members to see each others dots.')
        self:CreateTickBox(x, y, w, h, true, 'AdminsSeeAll', 'Admins See All', 'This will show admins every player on the map.\n(regardless of the settings above, you need to have the client options enabled)')
        y = y + 30

        -- Create Client Options
        self:CreateLabel(x + 25, y, h, 'Client Options', 1, 1, 1, 1, UIFont.Medium)
    else
        -- Create Client Options
        self:CreateLabel(x + 25, y, h, 'Client Options', 1, 1, 1, 1, UIFont.Medium)
        y = y + 35
    end

    self.addY = y + self.addY - h*7

    -- Create Client Options
    self:CreateTickBox(x, y, w, h, false, 'ShowWorldMap', 'Show World Map', 'Show player dots on world map.')
    self:CreateTickBox(x, y, w, h, false, 'WorldShowNames', 'Show Names on World Map', 'Show player\'s name next to the dot on the world map.')
    self:CreateTickBox(x, y, w, h, false, 'WorldShowHeight', 'Show Height on World Map', 'Show player\'s difference in height on the world map (this will show a "-" above/below the players dot if they are above/below you)')
    y = y + h

    self:CreateTickBox(x, y, w, h, false, 'ShowMiniMap', 'Show Mini Map', 'Show player dots on mini map.')
    self:CreateTickBox(x, y, w, h, false, 'MiniShowNames', 'Show Names on Mini Map', 'Show player\'s name next to the dot on the mini map.')
    self:CreateTickBox(x, y, w, h, false, 'MiniShowHeight', 'Show Height on Mini Map', 'Show player\'s difference in height on the mini map (this will show a "-" above/below the players dot if they are above/below you)')
    y = y + h


    self.addY = self.addY + MainOptions.translatorPane:getHeight() + 22
    self.mainPanel:setScrollHeight(y + self.addY)
end
local activeMods = {}

local Mod = { }

Mod.LOG_LEVEL = {
    INFO = 0,
    ERROR = 0
}

function Mod:new(name)
    local mod = activeMods[name]
    if mod then
        mod:reset()
        return mod
    end

    local o = { name=name, registeredHandlers = {}, eventHandlers = {} }
    setmetatable(o, self)
    self.__index = self
    activeMods[name] = o
    return o
end

function Mod:log(message, level)
    local level = level or self.LOG_LEVEL.INFO
    if level == self.LOG_LEVEL.INFO then
        if isDebugEnabled() then
            print(string.format("%s - %s: %s", self.name, "INFO", message))
        end
    elseif level == self.LOG_LEVEL.ERROR then
        print(string.format("%s - %s: %s", self.name, "ERROR", message))
    end
end

function Mod:reset()
end

--[[
    Automatically registers all handlers under Mod.eventHandlers with the game.
    Follows the naming convention of Events.EventName, e.g. to register a handler
    for the Events.OnHitZombie event:

    MyMod = ModLib.Mod:new('mymod')
    function MyMod.eventHandlers.OnHitZombie(zombie, wielder, bodyPart, weapon)
        -- do things here
    end
    MyMod:init() -- registers the event handler

    Why not just use Events.OnHitZombie.Add(MyMod.OnHitZombie) ?
    This does not work with hot-reloading. The above call passes the value of MyMod.OnHitZombie.
    When you reload the file through the Lua console, you would update MyMod.OnHitZombie,
    but the Events system would still have the old function.
    If you had an error in your function, it would continue to error until you reset Lua.

    When you use Mod:register, it creates a lambda that then calls Mod.eventHandlers.OnHitZombie.
    The lambda is only registered once, and the mod remembers that it has registered this handler.
    When you hot-reload, Mod.eventHandlers.OnHitZombie is changed, and the registered lambda calls the new function.
--]]
function Mod:register()
    for handlerName, handler in pairs(self.eventHandlers) do
        if not self.registeredHandlers[handlerName] then
            local wrapper = function(...)
                self.eventHandlers[handlerName](...)
            end
            local eventRegister = Events[handlerName];
            if type(eventRegister) ~= "table" then
                self:log("ERROR: Events." .. handlerName .. " does not exist", self.LOG_LEVEL.ERROR)
                break
            end
            eventRegister.Add(wrapper)
            self.registeredHandlers[handlerName] = true
            self:log("Registered event handler for " .. handlerName)
        else
            self:log("Event handler for " .. handlerName .. " already registered")
        end
    end
end

function Mod:init()
    self:register();
end

return Mod


require "TimedActions/ISBaseTimedAction"

ISContinue = ISBaseTimedAction:derive("ISContinue");

function ISContinue:isValid()
    return self.target ~= nil;
end

function ISContinue:update()
end

function ISContinue:start()
end

function ISContinue:stop()
    ISBaseTimedAction.stop(self);
end

function ISContinue:perform()
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
    self.target:continue();
end

function ISContinue:new(target, character, maxTime)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.target = target;
    o.stopOnWalk = false;
    o.stopOnRun = false;
    o.maxTime = maxTime;
    return o;
end

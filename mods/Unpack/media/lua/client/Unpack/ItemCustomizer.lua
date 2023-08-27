---
--
local customItems = {};

---
--
function Customize(name, field, value)
    if not customItems[name] then
        customItems[name] = {};
    end
    customItems[name][field] = value;
end

---
--
function Finalize()
    local sm = ScriptManager.instance;
    for name,fields in pairs(customItems) do
        local item = sm:getItem(name);
        if item then
            for field,value in pairs(fields) do
                item:DoParam(field .. "=" .. value);
            end
        end
    end
end

Events.OnGameBoot.Add(Finalize);

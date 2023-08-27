require("Unpack/Constants");

Unpack.Settings = {};
local defaultSettings = {
    OVERRIDE_BASE_CATEGORIES = 0,
    CATEGORY_SPECIALIZATION_MIN = 1,
    EXCLUDE_MANNEQUIN_CONTAINER = 1,
    EXCLUDE_TRASH_CONTAINER = 1,
    CATEGORY_SPECIALIZATION_DEFAULT_PERCENT = "1%"
};

---
--
function Unpack.Settings:Get(settingKey)
    return defaultSettings[settingKey];
end

---
--
function Unpack.Settings:GetBool(settingKey)
    local result = self:Get(settingKey);
    if not result or result == "false" or result == 0 then
        return false;
    end
    return true;
end

---
--
function Unpack.Settings:Set(settingKey, value)
    defaultSettings[settingKey] = value;
end

---
--
function Unpack.Settings:Deserialize()
    local file = getFileReader(Unpack.INI, false);
    if file then
        while true do
            local line = file:readLine();
            if line == nil then
                break;
            end

            local tuple = {};
            for match in (line.."="):gmatch("(.-)=") do
                table.insert(tuple, match);
            end
            Unpack.Settings:Set(tuple[1], tuple[2]);
        end
        file:close();
    end
end

---
--
function Unpack.Settings:Serialize()
    local file = getFileWriter(Unpack.INI, true, false);
    for k,v in pairs(defaultSettings) do
        file:write(k .. "=" .. tostring(v) .. "\n");
    end
    file:close();
end


local modInfoBM = getModInfoByID("BigMoodles")
if not modInfoBM or not isModActive(modInfoBM) then
    return--handle : compat not required
end


require 'MF_ISMoodle'
require 'BigMoodles'

local LuaMoodles = require("StatsAPI/moodles/LuaMoodles")
local core = getCore()

local old_adjustPositions = LuaMoodles.adjustPositions

LuaMoodles.adjustPositions = function()
    local scale = core:getScreenHeight() / 720 + 0.5
    scale = scale - scale % 1
    if scale < 1 then scale = 1 end
    MF.scale = scale
    
    old_adjustPositions()
end


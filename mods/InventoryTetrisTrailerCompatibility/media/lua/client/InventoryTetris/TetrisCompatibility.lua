require "InventoryTetris/TetrisContainerData"

local MAX_ITEM_HEIGHT_F = 500
local MAX_ITEM_WIDTH_F = 10

function TetrisContainerData._calculateDimensions(target)
    local best = 99999999
    local bestX = 1
    local bestY = 1

    for x = 1, MAX_ITEM_WIDTH_F do
        for y = 1, MAX_ITEM_HEIGHT_F do
            local result = x * y
            local diff = math.abs(result - target) + math.abs(x - y) -- Encourage square shapes 
            if diff < best then
                best = diff 
                bestX = x
                bestY = y
            end
        end
    end

    return bestX, bestY
end

OpenCans = OpenCans or {}
OpenCans.Utils = {}

function OpenCans.Utils.round(number, decimalPlaces)
    local multiplier = 10 ^ (decimalPlaces or 0)
    return math.floor(number * multiplier + 0.5) / multiplier
end

function OpenCans.Utils.isHandWeapon(item)
    return instanceof(item, "HandWeapon")
end

function OpenCans.Utils.isLongBlade(item)
    return item.getCategories and item:getCategories():contains("LongBlade")
end

function OpenCans.Utils.isSmallBlade(item)
    return item.getCategories and item:getCategories():contains("SmallBlade")
end

function OpenCans.Utils.isStone(item)
    return item:getFullType() == "Base.Stone"
end
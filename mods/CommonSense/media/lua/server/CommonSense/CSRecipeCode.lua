--***********************************************************
--**                       BitBraven                       **
--***********************************************************

function Recipe.OnCreate.OpenJarredFood(items, result, player)
    local jar = items:get(0)
    local aged = jar:getAge() / jar:getOffAgeMax()

    result:setAge(result:getOffAgeMax() * aged)
    player:getInventory():AddItem("Base.EmptyJar")
    player:getInventory():AddItem("Base.JarLid")
  end
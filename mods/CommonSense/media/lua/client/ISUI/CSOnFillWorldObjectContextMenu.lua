--***********************************************************
--**                       BitBraven                       **
--***********************************************************

OnFillWorldObjectContextMenu = function(player, context, worldobjects, test)
    CSUtils.OnFillWorldObjectContextMenuCrowbar(player, context, worldobjects, test)
end

Events.OnFillWorldObjectContextMenu.Add(OnFillWorldObjectContextMenu)
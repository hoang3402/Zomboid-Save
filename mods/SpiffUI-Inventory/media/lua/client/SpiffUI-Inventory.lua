------------------------------------------
-- SpiffUI Inventory Module
------------------------------------------
SpiffUI = SpiffUI or {}

-- Register our inventory
local spiff = SpiffUI:Register("inventory")

spiff.hasTetris =  getActivatedMods():contains("INVENTORY_TETRIS")
spiff.hasEquipUI = getActivatedMods():contains("EQUIPMENT_UI")

local sui = {
    page = require("SUI/SUI_InventoryPage"),
    mingler = require("SUI/SUI_mingler")
}

spiff.Boot = function() 
    local defKeys = {
        ["Toggle mode"] = Keyboard.KEY_I,
        ["Toggle Moveable Panel Mode"] = 0
    }
    SpiffUI:AddKeyDefaults(defKeys)

    SpiffUI:AddKeyDisable("Toggle Inventory")

    if spiff.Conf.equipUIManager then
        SpiffUI:AddKeyDisable("equipment_toggle_window")
        SpiffUI:AddKeyDisable("[EquipmentUI]")
    end

    for i,v in pairs(sui) do
        if v.Boot then
            v.Boot()
        end
    end

    -- Hello :)
    print(getText("UI_Hello_SpiffUI_Inv"))
end

spiff.PostBoot = function()
    for i,v in pairs(sui) do
        if v.PostBoot then
            v.PostBoot()
        end
    end
end

spiff.OnConfigSync = function()
    if spiff.hasTetris then
        spiff.Conf.selfinv = false
    else
        spiff.Conf.autohidepopups = false
    end
    if spiff.hasEquipUI then
        spiff.Conf.spiffequip = false
        spiff.Conf.hideEquipped = false
    else
        spiff.Conf.equipUIManager = false
    end
    for i,v in pairs(sui) do
        if v.OnConfigSync then
            v.OnConfigSync()
        end
    end
end

spiff.CreatePlayer = function(id)
    for i,v in pairs(sui) do
        if v.CreatePlayer then
            v.CreatePlayer(id)
        end
    end
end

spiff.OnCreatePlayerDataObject = function(id)
    for i,v in pairs(sui) do
        if v.OnCreatePlayerDataObject then
            v.OnCreatePlayerDataObject(id)
        end
    end
end

spiff.Start = function()
    for i,v in pairs(sui) do
        if v.Start then
            v.Start()
        end
    end
end

spiff.Reset = function()
    for i,v in pairs(sui) do
        if v.Reset then
            v.Reset()
        end
    end
end

spiff.BuildConfig = function()
    local opts =  {
        options = {
            enableInv = {
                name = "UI_ModOptions_SpiffUI_Inv_enable",
                default = true,
                tooltip = "UI_ModOptions_SpiffUI_Inv_tooltip_enable"
            },
            hideInv = {
                name = "UI_ModOptions_SpiffUI_Inv_hideInv",
                default = false
            },
            mouseHide = {
                name = "UI_ModOptions_SpiffUI_Inv_mouseHide",
                default = false
            },
            invVisible = {
                name = "UI_ModOptions_SpiffUI_Inv_invVisible",
                default = false,
                tooltip = "UI_ModOptions_SpiffUI_Inv_invVisibleTT"
            },
            handleKeys = {
                name = "UI_ModOptions_SpiffUI_KeyRing",
                default = false,
                tooltip = "UI_ModOptions_SpiffUI_KeyRing_tt"
            },
            lootinv = {
                name = "UI_ModOptions_SpiffUI_Inv_lootinv",
                default = true,
                tooltip = "UI_ModOptions_SpiffUI_Inv_lootinv_tt"
            },
            showfloormerged = {
                name = "UI_ModOptions_SpiffUI_showfloormerged",
                default = false,
                tooltip = "UI_ModOptions_SpiffUI_showfloormerged_tt"
            },
            sepzeds = {
                name = "UI_ModOptions_SpiffUI_Inv_sepzeds",
                default = true,
                tooltip = "UI_ModOptions_SpiffUI_Inv_sepzeds_tt"
            },
            stickyButtons = {
                name = "UI_ModOptions_SpiffUI_Inv_stickyButtons",
                default = true,
                tooltip = "UI_ModOptions_SpiffUI_Inv_stickyButtons_tt"
            }
        },
        name = "SpiffUI - Inventory",
        columns = 3
    }

    if not spiff.hasTetris then
        opts.options.selfinv = {
            name = "UI_ModOptions_SpiffUI_Inv_selfinv",
            default = false,
            tooltip = "UI_ModOptions_SpiffUI_Inv_selfinv_tt"
        }
        opts.options.buttonShow = {
            name = "UI_ModOptions_SpiffUI_Inv_buttonShow",
            default = false,
            tooltip = "UI_ModOptions_SpiffUI_Inv_buttonShow_tt"
        }
    else
        opts.options.buttonShow = {
            name = "UI_ModOptions_SpiffUI_Inv_buttonShow",
            default = false,
            tooltip = "UI_ModOptions_SpiffUI_Inv_buttonShow_tt"
        }

        opts.options.handleKeys.tooltip = "UI_ModOptions_SpiffUI_KeyRing_Tetris_tt"

        opts.options.lootinv.name = "UI_ModOptions_SpiffUI_Inv_lootinv_Tetris"
        opts.options.sepzeds.name = "UI_ModOptions_SpiffUI_Inv_sepzeds_Tetris"
        opts.options.lootinv.tooltip = "UI_ModOptions_SpiffUI_Inv_lootinv_Tetris_tt"
        opts.options.sepzeds.tooltip = "UI_ModOptions_SpiffUI_Inv_sepzeds_Tetris_tt"

        opts.options.autohidepopups = {
            name = "UI_ModOptions_SpiffUI_autohidepopups",
            default = true,
            tooltip = "UI_ModOptions_SpiffUI_autohidepopups_tt"
        }
    end

    if not spiff.hasEquipUI then
        opts.options.spiffequip = {
            name = "UI_ModOptions_SpiffUI_EquipButton",
            default = false,
            tooltip = "UI_ModOptions_SpiffUI_EquipButton_tt"
        }
        opts.options.hideEquipped = {
            name = "UI_ModOptions_SpiffUI_HideEquip",
            default = false,
            tooltip = "UI_ModOptions_SpiffUI_HideEquip_tt"
        }
    else
        opts.options.equipUIManager = {
            name = "UI_ModOptions_SpiffUI_EquipUIManager",
            default = true,
            tooltip = "UI_ModOptions_SpiffUI_EquipUIManager_tt"
        }
    end

    return opts
end
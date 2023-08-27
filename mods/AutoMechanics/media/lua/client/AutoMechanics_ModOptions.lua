require "AutoMechanics"

-- Connecting the options to the menu, so user can change them.
if ModOptions and ModOptions.getInstance then
  local settings = ModOptions:getInstance(AutoMechanics.OPTIONS, "AutoMechanics", "AutoMechanics")

  ModOptions:loadFile();

  local optWaitTicks           = settings:getData("WaitTicks")
  local optFailThreshold       = settings:getData("FailThreshold")
  local optEndPause            = settings:getData("EndPause")
  local optUntilSuccess        = settings:getData("UntilSuccess")
  local optVerbose             = settings:getData("Verbose")

  if optWaitTicks then
      optWaitTicks.name        = "UI_AutoMechanics_WaitTicks";
      optFailThreshold.name    = "UI_AutoMechanics_FailThreshold";
      optEndPause.name         = "UI_AutoMechanics_EndPause";
      optUntilSuccess.name     = "UI_AutoMechanics_UntilSuccess";
      optVerbose.name          = "UI_Verbose";

      optWaitTicks.tooltip     = "UI_AutoMechanics_Tooltip_WaitTicks";
      optFailThreshold.tooltip = "UI_AutoMechanics_Tooltip_FailThreshold";
      optEndPause.tooltip      = "UI_AutoMechanics_Tooltip_EndPause";
      optUntilSuccess.tooltip  = "UI_AutoMechanics_Tooltip_UntilSuccess";
      optVerbose.tooltip       = "UI_Tooltip_Verbose";

      optWaitTicks[1] = getText("UI_AutoMechanics_WaitTicks_0")
      optWaitTicks[2] = getText("UI_AutoMechanics_WaitTicks_1")
      optWaitTicks[3] = getText("UI_AutoMechanics_WaitTicks_2")
      optWaitTicks[4] = getText("UI_AutoMechanics_WaitTicks_3")
      optWaitTicks[5] = getText("UI_AutoMechanics_WaitTicks_4")
      optWaitTicks[6] = getText("UI_AutoMechanics_WaitTicks_5")
      optWaitTicks[7] = getText("UI_AutoMechanics_WaitTicks_10")
      optWaitTicks[8] = getText("UI_AutoMechanics_WaitTicks_20")
      
      optFailThreshold[1] = getText("UI_AutoMechanics_FailThreshold_0")
      optFailThreshold[2] = getText("UI_AutoMechanics_FailThreshold_20")
      optFailThreshold[3] = getText("UI_AutoMechanics_FailThreshold_40")
      optFailThreshold[4] = getText("UI_AutoMechanics_FailThreshold_60")
      optFailThreshold[5] = getText("UI_AutoMechanics_FailThreshold_80")
      optFailThreshold[6] = getText("UI_AutoMechanics_FailThreshold_100")
  end
end

function AutoMechanics.getWaitCycle()
    if AutoMechanics.OPTIONS.WaitTicks == 1 then return 0 end
    if AutoMechanics.OPTIONS.WaitTicks == 2 then return 1 end
    if AutoMechanics.OPTIONS.WaitTicks == 3 then return 2 end
    if AutoMechanics.OPTIONS.WaitTicks == 4 then return 3 end
    if AutoMechanics.OPTIONS.WaitTicks == 5 then return 4 end
    if AutoMechanics.OPTIONS.WaitTicks == 6 then return 5 end
    if AutoMechanics.OPTIONS.WaitTicks == 7 then return 10 end
    if AutoMechanics.OPTIONS.WaitTicks == 8 then return 20 end
    return 2
end

function AutoMechanics.getConditionLossPercentageThreshold()
    if AutoMechanics.OPTIONS.FailThreshold == 1 then return 0 end
    if AutoMechanics.OPTIONS.FailThreshold == 2 then return 20 end
    if AutoMechanics.OPTIONS.FailThreshold == 3 then return 40 end
    if AutoMechanics.OPTIONS.FailThreshold == 4 then return 60 end
    if AutoMechanics.OPTIONS.FailThreshold == 5 then return 80 end
    return 100
end

function AutoMechanics.getEndPause()
    return AutoMechanics.OPTIONS.EndPause
end

function AutoMechanics.doUntilSuccess()
    return AutoMechanics.OPTIONS.UntilSuccess
end
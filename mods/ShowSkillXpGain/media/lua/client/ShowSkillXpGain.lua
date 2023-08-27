ShowSkillXpGain = ShowSkillXpGain or {}
ShowSkillXpGain.showValue = true
ShowSkillXpGain.invalidPerks = { "Strength", "Fitness", "Foraging" } 

local function isValid(perkName)
	local valid = true
	
	for k, v in ipairs(ShowSkillXpGain.invalidPerks) do
		if perkName == v then
			valid = false
			break
		end
	end
	
	return valid
end

local function ShowXP(player, skill, level)
	if skill ~= nil then
		local perkName = skill:getName()
		
		if not player:isNPC() then
			if isValid(perkName) then
				local showAmountString = ""
				
				if ShowSkillXpGain.showValue then
					showAmountString = string.format(" +%.2f", tostring(level))
				end

				HaloTextHelper.addTextWithArrow(player, perkName .. showAmountString, true, HaloTextHelper.getColorGreen())
			end
		end
	end
end

if ModOptions and ModOptions.getInstance then
    function ShowSkillXpGainOnModOptionsApply(optionValues)
        ShowSkillXpGain.showValue = optionValues.settings.options.showValue
		
		local tempTable = {"Foraging"}

		if optionValues.settings.options.strength then
			table.insert(tempTable, "Strength")
		end

		if optionValues.settings.options.fitness then
			table.insert(tempTable, "Fitness")
		end
		
		if optionValues.settings.options.sprinting then
			table.insert(tempTable, "Sprinting")
		end
		
		if optionValues.settings.options.sneaking then
			table.insert(tempTable, "Sneaking")
		end
		
		if optionValues.settings.options.lightfoot then
			table.insert(tempTable, "Lightfooted")
		end
		
		if optionValues.settings.options.nimble then
			table.insert(tempTable, "Nimble")
		end
		
		if optionValues.settings.options.melee then
			table.insert(tempTable, "Short Blade")
			table.insert(tempTable, "Long Blade")
			
			table.insert(tempTable, "Short Blunt")
			table.insert(tempTable, "Long Blunt")
			
			table.insert(tempTable, "Axe")
			table.insert(tempTable, "Spear")
		end
		
		if optionValues.settings.options.aiming then
			table.insert(tempTable, "Aiming")
		end
		
		if optionValues.settings.options.reloading then
			table.insert(tempTable, "Reloading")
		end
		
		if optionValues.settings.options.maintenance then
			table.insert(tempTable, "Maintenance")
		end
		
		ShowSkillXpGain.invalidPerks = tempTable
    end

    function ShowSkillXpGainOnModOptionsApplyInGame(optionValues)
        ShowSkillXpGainOnModOptionsApply(optionValues)
    end
	
	local SETTINGS = {
	options_data = {
        showValue = {
            name = "Show Value",
            default = true,
			tooltip = 'Show the amount of XP gained or only show skill name and green arrow',
            OnApplyMainMenu = ShowSkillXpGainOnModOptionsApply,
            OnApplyInGame = ShowSkillXpGainOnModOptionsApplyInGame,
        },
		strength = {
            name = "Hide Strength",
            default = true,
			tooltip = 'Hide XP gains for this skill',
            OnApplyMainMenu = ShowSkillXpGainOnModOptionsApply,
            OnApplyInGame = ShowSkillXpGainOnModOptionsApplyInGame,
        },
		fitness = {
            name = "Hide Fitness",
            default = true,
			tooltip = 'Hide XP gains for this skill',
            OnApplyMainMenu = ShowSkillXpGainOnModOptionsApply,
            OnApplyInGame = ShowSkillXpGainOnModOptionsApplyInGame,
        },
		sprinting = {
            name = "Hide Sprinting",
            default = false,
			tooltip = 'Hide XP gains for this skill',
            OnApplyMainMenu = ShowSkillXpGainOnModOptionsApply,
            OnApplyInGame = ShowSkillXpGainOnModOptionsApplyInGame,
        },
		sneaking = {
            name = "Hide Sneaking",
            default = false,
			tooltip = 'Hide XP gains for this skill',
            OnApplyMainMenu = ShowSkillXpGainOnModOptionsApply,
            OnApplyInGame = ShowSkillXpGainOnModOptionsApplyInGame,
        },
		lightfoot = {
            name = "Hide Lightfooted",
            default = false,
			tooltip = 'Hide XP gains for this skill',
            OnApplyMainMenu = ShowSkillXpGainOnModOptionsApply,
            OnApplyInGame = ShowSkillXpGainOnModOptionsApplyInGame,
        },
		nimble = {
            name = "Hide Nimble",
            default = false,
			tooltip = 'Hide XP gains for this skill',
            OnApplyMainMenu = ShowSkillXpGainOnModOptionsApply,
            OnApplyInGame = ShowSkillXpGainOnModOptionsApplyInGame,
        },
		melee = {
            name = "Hide Melee",
            default = false,
			tooltip = 'Hide XP gains for these skills',
            OnApplyMainMenu = ShowSkillXpGainOnModOptionsApply,
            OnApplyInGame = ShowSkillXpGainOnModOptionsApplyInGame,
        },
		aiming = {
            name = "Hide Aiming",
            default = false,
			tooltip = 'Hide XP gains for this skill',
            OnApplyMainMenu = ShowSkillXpGainOnModOptionsApply,
            OnApplyInGame = ShowSkillXpGainOnModOptionsApplyInGame,
        },
		reloading = {
            name = "Hide Reloading",
            default = false,
			tooltip = 'Hide XP gains for this skill',
            OnApplyMainMenu = ShowSkillXpGainOnModOptionsApply,
            OnApplyInGame = ShowSkillXpGainOnModOptionsApplyInGame,
        },
		maintenance = {
            name = "Hide Maintenance",
            default = false,
			tooltip = 'Hide XP gains for this skill',
            OnApplyMainMenu = ShowSkillXpGainOnModOptionsApply,
            OnApplyInGame = ShowSkillXpGainOnModOptionsApplyInGame,
        },
    },

    mod_id = 'ShowSkillXpGain',
    mod_shortname = 'Show Skill Xp Gain',
    mod_fullname = 'Show Skill Xp Gain',
}

	ModOptions:getInstance(SETTINGS)
	ModOptions:loadFile()

    Events.OnGameStart.Add(function() ShowSkillXpGainOnModOptionsApplyInGame({ settings = SETTINGS }) end)
end

Events.AddXP.Add(ShowXP)
local instanceof = instanceof

local item_base = __classmetatables[InventoryItem.class].__index
local item_getType = item_base.getType
local item_getFullType = item_base.getFullType
local item_getModule = item_base.getModule
local item_getTooltip = item_base.getTooltip
local item_isRecordedMedia = item_base.isRecordedMedia
local item_getMediaData = item_base.getMediaData

local literature_base = __classmetatables[Literature.class].__index
local literature_getSkillTrained = literature_base.getSkillTrained
local literature_getTeachedRecipes = literature_base.getTeachedRecipes
local literature_getLvlSkillTrained = literature_base.getLvlSkillTrained
local literature_getNumberOfPages = literature_base.getNumberOfPages
local literature_getMaxLevelTrained = literature_base.getMaxLevelTrained

local perk_base = __classmetatables[Perk.class].__index
local perk_getParent = perk_base.getParent

local media_data_base = __classmetatables[MediaData.class].__index
local media_data_getId = media_data_base.getId
local media_data_getMediaType = media_data_base.getMediaType
local media_data_getCategory = media_data_base.getCategory

local player_base = __classmetatables[IsoPlayer.class].__index
local player_base_getPerkLevel = player_base.getPerkLevel
local player_base_getAlreadyReadPages = player_base.getAlreadyReadPages
local player_base_getKnownRecipes = player_base.getKnownRecipes
local player_base_getAlreadyReadBook = player_base.getAlreadyReadBook

local array_list_base = __classmetatables[ArrayList.class].__index
local array_list_base_containsAll = array_list_base.containsAll
local array_list_base_contains = array_list_base.contains

local recorded_media
local hasListenedToAll

local function cacheRecordedMedia()

	recorded_media = getZomboidRadio():getRecordedMedia()
	hasListenedToAll = recorded_media.hasListenedToAll

end

Events.OnInitRecordedMedia.Add(cacheRecordedMedia)

local literature_blacklist = EasyLiterature.LiteratureBlackList

function EasyLiterature:GetLiteratureItemType(item)

	if instanceof(item, 'Literature') then

		local skill_book = SkillBook[literature_getSkillTrained(item)]

		if skill_book then

			return perk_getParent(skill_book.perk) ~= Perks.None and "SkillBook" or false

		elseif literature_getTeachedRecipes(item) then

			if self:NeedModSupport("TrueActionsDancing") and item_getModule(item) == "TAD" then
				
				return "TrueActionsDancingMagazine"

			else

				return "RecipesMagazine"

			end

		end

	elseif item_isRecordedMedia(item) then

		local media_data = item_getMediaData(item)

		local media_type = media_data_getMediaType(media_data)

		if media_type == 1 then

			return media_data_getCategory(media_data) == "Retail-VHS" and "VHS" or "HomeVHS"

		elseif media_type == 0 then

			return "CD"

		end

	elseif self:NeedModSupport("TrueActionsDancing") and item_getTooltip(item) == "Tooltip_TADcard" and not literature_blacklist.TrueActionsDancingCards[item_getType(item)] then

		return "TrueActionsDancingCard"

	elseif self:NeedModSupport("SpiffoTradingCards") and item_getModule(item) == "SpiffoCards" and not literature_blacklist.SpiffoTradingCards[item_getType(item)] then

		return "SpiffoTradingCard"

	elseif self:NeedModSupport("ATCGbyWulf") and item_getModule(item) == "atcgcards" and not literature_blacklist.ATCGbyWulfCards[item_getType(item)] then

		return "ATCGbyWulfCard"

	end

	return false

end

function EasyLiterature:GetLiteratureItemInfo(item, player)

	if instanceof(item, 'Literature') then

		local skill_book = SkillBook[literature_getSkillTrained(item)]

		if skill_book then

			local perk = skill_book.perk

			if perk_getParent(perk) == Perks.None then

				return false

			end
			
			if not self:GetSettingsValue("FoundStatusForSkillBooks") then
				
				if not self:GetSettingsValue("KnownStatusForSkillBooks") then

					return false

				end

				return true, false, self:GetLiteratureItemKnownStatus(item, "SkillBook", player, perk)

			end

			if not self:GetSettingsValue("KnownStatusForSkillBooks") then

				return true, self:GetLiratureItemFoundStatus(item, "SkillBook"), false

			end

			return true, self:GetLiratureItemFoundStatus(item, "SkillBook"), self:GetLiteratureItemKnownStatus(item, "SkillBook", player, perk)

		end

		local teached_recipes = literature_getTeachedRecipes(item)
		
		if teached_recipes then

			if self:NeedModSupport("TrueActionsDancing") and item_getModule(item) == "TAD" then
				
				if not self:GetSettingsValue("FoundStatusForTrueActionsDancingMagazines") then
					
					if not self:GetSettingsValue("KnownStatusForTrueActionsDancingMagazines") then

						return false

					end

					return true, false, self:GetLiteratureItemKnownStatus(item, "TrueActionsDancingMagazine", player, teached_recipes)

				end

				if not self:GetSettingsValue("KnownStatusForTrueActionsDancingMagazines") then

					return true, self:GetLiratureItemFoundStatus(item, "TrueActionsDancingMagazine"), false

				end

				return true, self:GetLiratureItemFoundStatus(item, "TrueActionsDancingMagazine"), self:GetLiteratureItemKnownStatus(item, "TrueActionsDancingMagazine", player, teached_recipes)

			else

				if not self:GetSettingsValue("FoundStatusForRecipesMagazines") then
					
					if not self:GetSettingsValue("KnownStatusForRecipesMagazines") then

						return false

					end

					return true, false, self:GetLiteratureItemKnownStatus(item, "RecipesMagazine", player, teached_recipes)

				end

				if not self:GetSettingsValue("KnownStatusForRecipesMagazines") then

					return true, self:GetLiratureItemFoundStatus(item, "RecipesMagazine"), false

				end

				return true, self:GetLiratureItemFoundStatus(item, "RecipesMagazine"), self:GetLiteratureItemKnownStatus(item, "RecipesMagazine", player, teached_recipes)

			end

		end

	elseif item_isRecordedMedia(item) then

		local media_data = item_getMediaData(item)

		local media_type = media_data_getMediaType(media_data)

		if media_type == 1 then

			if media_data_getCategory(media_data) == "Retail-VHS" then
				
				if not self:GetSettingsValue("FoundStatusForVHS") then
					
					if not self:GetSettingsValue("KnownStatusForVHS") then

						return false

					end

					return true, false, self:GetLiteratureItemKnownStatus(item, "VHS", player, media_data), self:IsSkillMedia(media_data_getId(media_data))

				end

				if not self:GetSettingsValue("KnownStatusForVHS") then

					return true, self:GetLiratureItemFoundStatus(item, "VHS"), false

				end

				return true, self:GetLiratureItemFoundStatus(item, "VHS"), self:GetLiteratureItemKnownStatus(item, "VHS", player, media_data), self:IsSkillMedia(media_data_getId(media_data))

			else

				if not self:GetSettingsValue("FoundStatusForHomeVHS") then
					
					if not self:GetSettingsValue("KnownStatusForHomeVHS") then

						return false

					end

					return true, false, self:GetLiteratureItemKnownStatus(item, "HomeVHS", player, media_data), self:IsSkillMedia(media_data_getId(media_data))

				end

				if not self:GetSettingsValue("KnownStatusForHomeVHS") then

					return true, self:GetLiratureItemFoundStatus(item, "HomeVHS"), false

				end

				return true, self:GetLiratureItemFoundStatus(item, "HomeVHS"), self:GetLiteratureItemKnownStatus(item, "HomeVHS", player, media_data), self:IsSkillMedia(media_data_getId(media_data))

			end

		elseif media_type == 0 then

			if not self:GetSettingsValue("FoundStatusForCD") then
					
				if not self:GetSettingsValue("KnownStatusForCD") then

					return false

				end

				return true, false, self:GetLiteratureItemKnownStatus(item, "CD", player, media_data), self:IsSkillMedia(media_data_getId(media_data))

			end

			if not self:GetSettingsValue("KnownStatusForCD") then

				return true, self:GetLiratureItemFoundStatus(item, "CD"), false

			end

			return true, self:GetLiratureItemFoundStatus(item, "CD"), self:GetLiteratureItemKnownStatus(item, "CD", player, media_data), self:IsSkillMedia(media_data_getId(media_data))

		end

	elseif self:NeedModSupport("TrueActionsDancing") and item_getTooltip(item) == "Tooltip_TADcard" and not literature_blacklist.TrueActionsDancingCards[item_getType(item)] then

		if not self:GetSettingsValue("FoundStatusForTrueActionsDancingCards") then

			return false

		end

		return true, self:GetLiratureItemFoundStatus(item, "TrueActionsDancingCard"), false

	elseif self:NeedModSupport("SpiffoTradingCards") and item_getModule(item) == "SpiffoCards" and not literature_blacklist.SpiffoTradingCards[item_getType(item)] then

		if not self:GetSettingsValue("FoundStatusForSpiffoTradingCards") then

			return false

		end

		return true, self:GetLiratureItemFoundStatus(item, "SpiffoTradingCard"), false

	elseif self:NeedModSupport("ATCGbyWulf") and item_getModule(item) == "atcgcards" and not literature_blacklist.ATCGbyWulfCards[item_getType(item)] then

		if not self:GetSettingsValue("FoundStatusForATCGbyWulfCards") then

			return false

		end

		return true, self:GetLiratureItemFoundStatus(item, "ATCGbyWulfCard"), false

	elseif self:NeedModSupport("TrueMusicTheTwilightZone1") and item then

		return false

	end

	return false

end

local literature_item_id_funcs = {
	["SkillBook"] = function(item)

		return item_getFullType(item)

	end,
	["RecipesMagazine"] = function(item)

		return item_getFullType(item)

	end,
	["VHS"] = function(item)

		return media_data_getId(item_getMediaData(item))

	end,
	["HomeVHS"] = function(item)

		return media_data_getId(item_getMediaData(item))

	end,
	["CD"] = function(item)

		return media_data_getId(item_getMediaData(item))

	end,
	["TrueActionsDancingMagazine"] = function(item)

		return item_getFullType(item)

	end,
	["TrueActionsDancingCard"] = function(item)

		return item_getFullType(item)

	end,
	["SpiffoTradingCard"] = function(item)

		return item_getFullType(item)

	end,
	["ATCGbyWulfCard"] = function(item)

		return item_getFullType(item)

	end,
}

function EasyLiterature:GetLiteratureItemID(item, literature_type)

	return literature_item_id_funcs[literature_type](item)

end

function EasyLiterature:GetLiratureItemFoundStatus(item, literature_type)

	return self.ModData.Data[self:GetLiteratureItemID(item, literature_type)] and 1 or 0

end

local literature_item_known_status_funcs = {
	["SkillBook"] = function(item, player, perk)

		local current_perk_level = player_base_getPerkLevel(player, perk) + 1
			
		if literature_getLvlSkillTrained(item) > current_perk_level then

			return 1

		end
		
		if literature_getNumberOfPages(item) > player_base_getAlreadyReadPages(player, item_getFullType(item))
			and
			(
				(
					EasyLiterature:NeedModSupport("ExpRecovery")
					and
					ExpRecovery:GetMissedExpForSkillBook(item, player, perk) > 0
				)
				or
				(
					EasyLiterature:NeedModSupport("JSRetroBooks")
					and
					(player:getModData()[JSRetroBooksGetIndexName(player, perk)] or 0) > 0
				)
				or
				literature_getMaxLevelTrained(item) >= current_perk_level
			) then
		
			return 2

		end

		return 3

	end,
	["RecipesMagazine"] = function(item, player, teached_recipes)

		return array_list_base_containsAll(player_base_getKnownRecipes(player), teached_recipes) and array_list_base_contains(player_base_getAlreadyReadBook(player), item_getFullType(item)) and 3 or 2
		
	end,
	["VHS"] = function(item, player, media_data)

		return (hasListenedToAll(recorded_media, player, media_data) and 3 or 2), EasyLiterature:IsSkillMedia(media_data_getId(media_data))

	end,
	["HomeVHS"] = function(item, player, media_data)

		return (hasListenedToAll(recorded_media, player, media_data) and 3 or 2), EasyLiterature:IsSkillMedia(media_data_getId(media_data))

	end,
	["CD"] = function(item, player, media_data)

		return (hasListenedToAll(recorded_media, player, media_data) and 3 or 2), EasyLiterature:IsSkillMedia(media_data_getId(media_data))

	end,
	["TrueActionsDancingMagazine"] = function(item, player, teached_recipes)

		return array_list_base_containsAll(player_base_getKnownRecipes(player), teached_recipes) and array_list_base_contains(player_base_getAlreadyReadBook(player), item_getFullType(item)) and 3 or 2
		
	end,
}

function EasyLiterature:GetLiteratureItemKnownStatus(item, literature_type, ...)

	return literature_item_known_status_funcs[literature_type](item, ...)

end

local moodle_codes = {
	ANG = true,
	BOR = true,
	FAT = true,
	HUN = true,
	STS = true,
	FEA = true,
	PAN = true,
	SIC = true,
	PAI = true,
	DRU = true,
	THI = true,
	UHP = true,
}

function EasyLiterature:IsSkillMediaCode(media_line)

	local code = string.match(media_line, "^%u%u%u+")

	return code and not moodle_codes[code] or false

end

local skill_media_cache = {}

function EasyLiterature:IsSkillMedia(media_index)

	if skill_media_cache[media_index] ~= nil then

		return skill_media_cache[media_index]

	end

	local media_data = RecMedia[media_index]

	if not media_data then return false end
	
	for i = 1, #media_data.lines do

		local line = media_data.lines[i]

		if line.codes and #line.codes ~= 0 then

			for code in string.gmatch(line.codes, "([^,]+)") do

				if self:IsSkillMediaCode(code) then
				
					skill_media_cache[media_index] = true

					return true

				end

			end

		end

	end

	skill_media_cache[media_index] = false

	return false
	
end

-- cacheRecordedMedia()
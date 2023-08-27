function EasyLiterature.InitFoundBooksData()

	EasyLiterature.ModData = ModData.getOrCreate("EasyLiterature")
	EasyLiterature.ModData.Data = EasyLiterature.ModData.Data or {}
	EasyLiterature.ModData.Settings = EasyLiterature.ModData.Settings or {
		Categories = {
			["SkillBooks"] = true,
			["RecipesMagazines"] = true,
			["VHS"] = true,
			["HomeVHS"] = true,
			["CD"] = true,
			["TrueActionsDancingMagazines"] = true,
			["TrueActionsDancingCards"] = true,
		},

		AutoMarkTransferedLiterature = true,
		ShowNotFoundMark = true,
		ShowFoundMark = true,
		ShowKnownMark = true,
		LazyListsFill = true,

		FoundStatusForSkillBooks = true,
		KnownStatusForSkillBooks = true,

		FoundStatusForRecipesMagazines = true,
		KnownStatusForRecipesMagazines = true,

		FoundStatusForVHS = true,
		KnownStatusForVHS = true,

		FoundStatusForHomeVHS = true,
		KnownStatusForHomeVHS = true,

		FoundStatusForCD = true,
		KnownStatusForCD = true,
		
		FoundStatusForTrueActionsDancingMagazines = true,
		KnownStatusForTrueActionsDancingMagazines = true,	
	}
	EasyLiterature.ModData.Settings.Categories.SpiffoTradingCards = EasyLiterature.ModData.Settings.Categories.SpiffoTradingCards or true
	EasyLiterature.ModData.Settings.FoundStatusForSpiffoTradingCards = EasyLiterature.ModData.Settings.FoundStatusForSpiffoTradingCards or true
	EasyLiterature.ModData.Settings.Categories.ATCGbyWulfCards = EasyLiterature.ModData.Settings.Categories.ATCGbyWulfCards or true
	EasyLiterature.ModData.Settings.FoundStatusForATCGbyWulfCards = EasyLiterature.ModData.Settings.FoundStatusForATCGbyWulfCards or true
	
	local settings = EasyLiterature.ModData.Settings

	function EasyLiterature:GetSettingsValue(settings_key)

		return settings[settings_key]

	end

	triggerEvent("EasyLiterature:OnReadySettingsFunctions")

end

Events.OnInitGlobalModData.Add(EasyLiterature.InitFoundBooksData)

EasyLiterature.LiteratureBlackList = {
	["TrueActionsDancingCards"] = {
		["OpenKosmotsars"] = true,
		["CloseKosmotsars"] = true,
	},
	["SpiffoTradingCards"] = {
		["cardpack"] = true,
		["cardpackgold"] = true,
		["cardpack_trash"] = true,
	},
	["ATCGbyWulfCards"] = {
		["boosterpack_trash"] = true,
		["boosterpack"] = true,
		["atcgcollectionbox"] = true,
		["boosterbox"] = true,
		["cardbinder_empty"] = true,
		["cardbinder_full"] = true,
		["atcg_map1"] = true,
		["atcg_map2"] = true,
		["atcg_map3"] = true,
	},
}

local literature_blacklist = EasyLiterature.LiteratureBlackList

EasyLiterature.LiteratureList = EasyLiterature.LiteratureList or {}

function EasyLiterature.InitLiteratureList()

	local literature_list = {
		SkillBooks = {},
		RecipeMagazines = {},
		VHS = {},
		HomeVHS = {},
		CD = {},
		TrueActionsDancingMagazines = {},
		TrueActionsDancingCards = {},
		SpiffoTradingCards = {},
		ATCGbyWulfCards = {},
	}

	local allItems = getScriptManager():getAllItems()

	for i = 0, allItems:size() - 1 do

		local item = allItems:get(i)

		if item:getType() == Type.Literature then

			local skill_book = SkillBook[item:getSkillTrained()]

			if skill_book then

				local perk = skill_book.perk

				if perk:getParent() ~= Perks.None then

					local perk_id = perk:getId()

					literature_list.SkillBooks[perk_id] = literature_list.SkillBooks[perk_id] or {}

					table.insert(literature_list.SkillBooks[perk_id], {
						Level = item:getLevelSkillTrained(),
						Name = item:getFullName(),
					})

				end

			elseif item:getTeachedRecipes() then

				if EasyLiterature:NeedModSupport("TrueActionsDancing") and item:getModule():getName() == "TAD" then

					table.insert(literature_list.TrueActionsDancingMagazines, item:getFullName())

				else

					table.insert(literature_list.RecipeMagazines, item:getFullName())

				end

			end

		elseif EasyLiterature:NeedModSupport("TrueActionsDancing") and item:getModule():getName() == "TAD" and not literature_blacklist["TrueActionsDancingCards"][item:getName()] then

			table.insert(literature_list.TrueActionsDancingCards, item:getFullName())

		elseif EasyLiterature:NeedModSupport("SpiffoTradingCards") and item:getModule():getName() == "SpiffoCards" and not literature_blacklist["SpiffoTradingCards"][item:getName()] then

			table.insert(literature_list.SpiffoTradingCards, item:getFullName())

		elseif EasyLiterature:NeedModSupport("ATCGbyWulf") and item:getModule():getName() == "atcgcards" and not literature_blacklist["ATCGbyWulfCards"][item:getName()] then

			table.insert(literature_list.ATCGbyWulfCards, item:getFullName())

		end

	end

	local vhses = getZomboidRadio():getRecordedMedia():getAllMediaForType(1)

	for i = 0, vhses:size() - 1 do

		local vhs = vhses:get(i)

		if vhs:getCategory() == "Retail-VHS" then

			table.insert(literature_list.VHS, vhs:getId())
		
		else

			table.insert(literature_list.HomeVHS, vhs:getId())

		end
		
	end

	local cds = getZomboidRadio():getRecordedMedia():getAllMediaForType(0)

	for i = 0, cds:size() - 1 do

		local cd = cds:get(i)
		
		table.insert(literature_list.CD, cd:getId())
		
	end

	local getItemNameFromFullType = getItemNameFromFullType
	local recorded_media = getZomboidRadio():getRecordedMedia()
	local get_media_data = recorded_media.getMediaData

	local skill_books = {}
	
	for k,v in pairs(literature_list.SkillBooks) do

		table.sort(v, function(a, b)
				
			return a.Level < b.Level

		end)

		for _k,_v in pairs(v) do

			v[_k] = _v.Name
			
		end

		table.insert(skill_books, v)

	end

	literature_list.SkillBooks = skill_books

	table.sort(literature_list.SkillBooks, function(a, b)
		return getItemNameFromFullType(a[1]) < getItemNameFromFullType(b[1])
	end)
	table.sort(literature_list.RecipeMagazines, function(a, b) return getItemNameFromFullType(a) < getItemNameFromFullType(b) end)
	table.sort(literature_list.VHS, function(a, b) return get_media_data(recorded_media, a):getTranslatedItemDisplayName() < get_media_data(recorded_media, b):getTranslatedItemDisplayName() end)
	table.sort(literature_list.HomeVHS, function(a, b) return get_media_data(recorded_media, a):getTranslatedItemDisplayName() < get_media_data(recorded_media, b):getTranslatedItemDisplayName() end)
	table.sort(literature_list.CD, function(a, b) return get_media_data(recorded_media, a):getTranslatedItemDisplayName() < get_media_data(recorded_media, b):getTranslatedItemDisplayName() end)
	table.sort(literature_list.TrueActionsDancingMagazines, function(a, b) return getItemNameFromFullType(a) < getItemNameFromFullType(b) end)
	table.sort(literature_list.TrueActionsDancingCards, function(a, b) return getItemNameFromFullType(a) < getItemNameFromFullType(b) end)
	table.sort(literature_list.SpiffoTradingCards, function(a, b) return getItemNameFromFullType(a) < getItemNameFromFullType(b) end)
	table.sort(literature_list.ATCGbyWulfCards, function(a, b) return getItemNameFromFullType(a) < getItemNameFromFullType(b) end)

	EasyLiterature.LiteratureList = literature_list

end

Events["EasyLiterature:OnReadyModSupport"].Add(EasyLiterature.InitLiteratureList)
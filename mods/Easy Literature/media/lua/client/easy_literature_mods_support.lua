local EasyLiterature = EasyLiterature

EasyLiterature.ModSupports = {
	AlternativeInventoryRendering = false,
	TrueActionsDancing = false,
	JSRetroBooks = false,
	ExpRecovery = false,
	SpiffoTradingCards = false,
	ATCGbyWulf = false,
	TrueMusicTheTwilightZone1 = false,
}

function EasyLiterature:NeedModSupport(mod_id)

	return self.ModSupports[mod_id] or false

end

local mod_support_id_to_name = {
	blkt_invtrack = "AlternativeInventoryRendering",
	TrueActionsDancing = "TrueActionsDancing",
	JSRetroBooks = "JSRetroBooks",
	ExpRecovery = "ExpRecovery",
	spiffotradingcards = "SpiffoTradingCards",
	ATCGbyWulf = "ATCGbyWulf",
	TOHV2A23 = "TrueMusicTheTwilightZone1",
}

local function initModSupport()

	local active_mods = getActivatedMods()

	for i = 0, active_mods:size() - 1 do

		local mod_id = active_mods:get(i)

		if mod_support_id_to_name[mod_id] then

			EasyLiterature.ModSupports[mod_support_id_to_name[mod_id]] = true

		end

	end

	triggerEvent("EasyLiterature:OnReadyModSupport")

end

Events.OnLoad.Add(initModSupport)
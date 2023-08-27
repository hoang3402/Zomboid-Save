local modId = "MultiHitLimiter";
getSandboxOptions():load();
local sandboxOpts = getSandboxOptions();
MultiHit = MultiHit or {};

local function MultiHitLimiter_LoadSandboxOptions()
	MultiHit.Opt = sandboxOpts:getOptionByName("MultiHitZombies"):getValue(); -- Weapon Multi Hit setting
	MultiHit.TwoHandReq = sandboxOpts:getOptionByName("MultiHitLimiter.TwoHandReq"):getValue();
	MultiHit.RangeBool = sandboxOpts:getOptionByName("MultiHitLimiter.RangeBool"):getValue();
	MultiHit.RangeNum = tonumber(sandboxOpts:getOptionByName("MultiHitLimiter.RangeNum"):getValue()); -- Required weapon range for multi hit
	MultiHit.StrReq = tonumber(sandboxOpts:getOptionByName("MultiHitLimiter.StrReq"):getValue());
	MultiHit.FitReq = tonumber(sandboxOpts:getOptionByName("MultiHitLimiter.FitReq"):getValue());
	MultiHit.SkillReq = tonumber(sandboxOpts:getOptionByName("MultiHitLimiter.SkillReq"):getValue());
	MultiHit.MaxHitCap = tonumber(sandboxOpts:getOptionByName("MultiHitLimiter.MaxHitCap"):getValue());
	MultiHit.Categories = { -- Weapon categories allowed for multi hit
		Axe = sandboxOpts:getOptionByName("MultiHitLimiter.Axe"):getValue();
		SmallBlunt = sandboxOpts:getOptionByName("MultiHitLimiter.SmallBlunt"):getValue();
		Blunt = sandboxOpts:getOptionByName("MultiHitLimiter.LongBlunt"):getValue();
		LongBlade = sandboxOpts:getOptionByName("MultiHitLimiter.LongBlade"):getValue();
		SmallBlade = sandboxOpts:getOptionByName("MultiHitLimiter.SmallBlade"):getValue();
		Spear = sandboxOpts:getOptionByName("MultiHitLimiter.Spear"):getValue();
		Unarmed = sandboxOpts:getOptionByName("MultiHitLimiter.Unarmed"):getValue();
	};
	MultiHit.Whitelist = sandboxOpts:getOptionByName("MultiHitLimiter.Whitelist"):getValue();
	MultiHit.Blacklist = sandboxOpts:getOptionByName("MultiHitLimiter.Blacklist"):getValue();
	MultiHitLimiter_OnInitWorld();
end

MultiHitLimiter_OnInitWorld = function()
	local allScriptItems = getScriptManager():getAllItems();
	if not MultiHit.Opt or not allScriptItems then return end
	local count = 0;
	for i=0, allScriptItems:size()-1 do
		local scriptItem = allScriptItems:get(i);
		if scriptItem then 
			local typeString = scriptItem:getTypeString();
			if typeString == "Weapon" and not (scriptItem:getObsolete() or scriptItem:isHidden()) then 
				local moduleName = scriptItem:getModuleName();
				local itemName = scriptItem:getName();
				local fullType = tostring(moduleName.."."..itemName);
				local tempItem = InventoryItemFactory.CreateItem(fullType);
				local itemCats = (tempItem ~= nil) and tempItem:getCategories() or '';
				local MultiHitCat = true;
				for str,bool in pairs(MultiHit.Categories) do 
					if itemCats:contains(str) then 
						MultiHitCat = bool; 
						break
					end
				end
				local twoHands = (tempItem ~= nil) and (tempItem:isRequiresEquippedBothHands() or tempItem:isTwoHandWeapon()) or nil;
				local maxRange = (tempItem ~= nil) and tempItem:getMaxRange() or 100;
				local Ranged = (tempItem ~= nil) and tempItem:isRanged() or false;
				local Firearm = (tempItem ~= nil) and tempItem:isAimedFirearm() or false;
				local maxHitCount = scriptItem:getMaxHitCount();
				if not Ranged and not Firearm and maxHitCount ~= nil then
					if (not MultiHitCat or (MultiHit.TwoHandReq and not twoHands) or (MultiHit.RangeBool and maxRange < MultiHit.RangeNum) or MultiHit.Blacklist:contains(fullType)) and not MultiHit.Whitelist:contains(fullType) and (maxHitCount > 1) then 
						scriptItem:DoParam("MaxHitCount = 1");
						count = count + 1;
						print("["..modId.."] Set \""..fullType.."\" maxHitCount: "..tostring(maxHitCount).." -> 1");
					elseif MultiHit.MaxHitCap > 0 and ((MultiHitCat and (not MultiHit.TwoHandReq or twoHands) and (not MultiHit.RangeBool or maxRange >= MultiHit.RangeNum)) or MultiHit.Whitelist:contains(fullType)) and not MultiHit.Blacklist:contains(fullType) and (maxHitCount > MultiHit.MaxHitCap) then
						scriptItem:DoParam("MaxHitCount = "..tostring(MultiHit.MaxHitCap));
						count = count + 1;
						print("["..modId.."] Set \""..fullType.."\" maxHitCount: "..tostring(maxHitCount).." -> "..tostring(MultiHit.MaxHitCap).." (Capped)");
					end
				end
			end
		end
	end
	print('['..modId..'] Finished tweaking '..count..' scriptItems');
end

Events.OnInitWorld.Add(MultiHitLimiter_LoadSandboxOptions);

MultiHitLimiter_OnEquipItem = function(_player, _itemObj)
	if not MultiHit.Opt or (MultiHit.StrReq == 0 and MultiHit.FitReq == 0 and MultiHit.SkillReq == 0) then return end
	local player = getSpecificPlayer(_player:getPlayerNum());
	local itemObj = _itemObj;
	if not player or not itemObj or not instanceof(itemObj, "HandWeapon") or not itemObj:IsWeapon() then return end

	local moduleName = itemObj:getScriptItem():getModuleName();
	local itemType = itemObj:getType();
	local fullType = tostring(moduleName.."."..itemType);
	local scriptItem = getScriptManager():FindItem(fullType); -- Base item after OnInitWorld changes, in case the object has been edited (e.g by another mod)
	local scriptHitCount = (scriptItem ~= nil) and scriptItem:getMaxHitCount() or 0;
	local maxHitCount = itemObj:getMaxHitCount();
	if (scriptHitCount <= 1 or not maxHitCount) or (itemObj:isRanged() or itemObj:isAimedFirearm()) then return end

	local WeaponCategory = '';
	local WeaponCategories = {
		'Axe';
		'SmallBlunt';
		'Blunt';
		'LongBlade';
		'SmallBlade';
		'Spear';
		'Unarmed';
	};
	for i,str in ipairs(WeaponCategories) do 
		if itemObj:getCategories():contains(str) then 
			WeaponCategory = str;
			break
		end
	end

	if WeaponCategory ~= '' then
		local strLevel = player:getPerkLevel(Perks.Strength);
		local fitLevel = player:getPerkLevel(Perks.Fitness);
		local perk = (WeaponCategory ~= 'Unarmed') and Perks.FromString(WeaponCategory) or nil;
		local perkLevel = (WeaponCategory ~= 'Unarmed') and player:getPerkLevel(perk) or nil;
		-- if getDebug() then
		-- 	print("["..modId.."] Skill Required: "..tostring(MultiHit.SkillReq)..", Strength/Fitness Required: "..tostring(MultiHit.StrReq).."/"..tostring(MultiHit.FitReq));
		-- 	print("["..modId.."] "..WeaponCategory.." Level: "..tostring(perkLevel)..", Strength/Fitness Levels: "..tostring(strLevel).."/"..tostring(fitLevel));
		-- end
		if maxHitCount ~= 1 and ((MultiHit.SkillReq > 0 and (perk ~= nil and perkLevel < MultiHit.SkillReq)) or (MultiHit.StrReq > 0 and strLevel < MultiHit.StrReq) or (MultiHit.FitReq > 0 and fitLevel < MultiHit.FitReq)) then 
			itemObj:setMaxHitCount(1); 
			-- if getDebug() then print("["..modId.."] Set \""..fullType.."\" maxHitCount: "..tostring(maxHitCount).." -> 1".." (Equipped) (<Req)") end
		elseif maxHitCount ~= scriptHitCount and ((not perk or perkLevel >= MultiHit.SkillReq) and (strLevel >= MultiHit.StrReq) and (fitLevel >= MultiHit.FitReq)) then
			itemObj:setMaxHitCount(scriptHitCount); 
			-- if getDebug() then print("["..modId.."] Set \""..fullType.."\" maxHitCount: "..tostring(maxHitCount).." -> "..tostring(scriptHitCount).." (Equipped) (>=Req)") end
		end
	end
end

local function MultiHitLimiter_UpdateEquippedItems(_player)
	if not _player or not MultiHit.Opt or (MultiHit.StrReq == 0 and MultiHit.FitReq == 0 and MultiHit.SkillReq == 0) then return end
	MultiHitLimiter_OnEquipItem(_player, _player:getPrimaryHandItem());
	MultiHitLimiter_OnEquipItem(_player, _player:getSecondaryHandItem());
end

Events.OnEquipPrimary.Add(MultiHitLimiter_OnEquipItem);
Events.OnEquipSecondary.Add(MultiHitLimiter_OnEquipItem);
Events.LevelPerk.Add(function()
	local player = getPlayer();
	MultiHitLimiter_UpdateEquippedItems(player);
end)
Events.OnGameStart.Add(function()
	local player = getPlayer();
	MultiHitLimiter_UpdateEquippedItems(player);
end)
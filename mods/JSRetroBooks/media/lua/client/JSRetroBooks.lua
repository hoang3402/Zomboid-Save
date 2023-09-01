-- If you're reading this, this is my first mod, so it's dumb and gross
-- Try learning from better modders than me!

-- Used to mute XPAdd while adding "missing" XP after book is read 
-- Wouldn't be necessary if I knew how to check if XP was boosted
-- The array allows us to index per player ID, in case that's needed
local JSRetroBooksMuteReturn = {};

-- This one's for muting while reading, a compatibility setting for XP from books mods
-- Also uses an array to indedx per player ID
local JSRetroBooksMuteReading = {};

-- ! Event Functions ! --

-- On AddXP, find "missed" XP due to missing multiplier
-- DOES NOT check if xp is actually boosted (I don't know how)
-- Saves "missed" XP to character mod data by perk name & level range tag
-- Need to check if we've gained XP in the last boostable level range, and remove that!
function JSRetroBooksAddXP(character, perk, xp)

	if(not (JSRetroBooksMuteReturn[JSRetroBooksGetPlayerID(character)] or JSRetroBooksGetMuteReading(character))) then

		local modXPData = character:getModData();
		local indexName = JSRetroBooksGetIndexName(character, perk);
		local skillMulti = math.max(1, character:getXp():getMultiplier(perk));
		local skillMultiMax = JSRetroBooksGetMaxMulti(character, perk);
		local missedXP = 0;
		
		--print("JSSI - " .. indexName .. " [" .. perk:getName() .. ": " .. character:getPerkLevel(perk) .. "] [XP: " .. xp .. "]");

		if(skillMulti < skillMultiMax) then
			
			local boostableXP = character:getXp():getXP(perk) - perk:getTotalXpForLevel(JSRetroBooksGetCurrentMinBoostLevel(character, perk));

			--print("JSSI - boostable: " .. boostableXP .. " vs. xp: " .. xp);
			
			if(xp > boostableXP) then
				xp = boostableXP;
			end

			missedXP = xp * (skillMultiMax - skillMulti);
		
			if(not modXPData[indexName]) then
				modXPData[indexName] = missedXP;
			else
				modXPData[indexName] = modXPData[indexName] + missedXP;
			end
		
		end
		
	end
	
end

Events.AddXP.Add(JSRetroBooksAddXP);

-- ! Override Functions ! --

local JSRetroBooksCheckMultiplierOld = ISReadABook.checkMultiplier;

-- Overriding this function lets us catch when the book is finished, and could possibly update to add XP on semi-completion, too
-- Call the old checkMultiplier, then check if book is completed and sanity check we're in level range and have mod data
-- Decay "missed" XP by SandboxVars "return" value, then add all XP if uncapped, or add until max training level if capped
-- Clear the old mod data, unmute, and pop up XP gained over the character
function ISReadABook.checkMultiplier(action)

	JSRetroBooksCheckMultiplierOld(action);

	if(action.item:getAlreadyReadPages() >= action.item:getNumberOfPages() and SkillBook[action.item:getSkillTrained()]) then

		local perk = SkillBook[action.item:getSkillTrained()].perk;
		local minLevel = action.item:getLvlSkillTrained() - 1;
		local maxLevel = minLevel + action.item:getNumLevelsTrained();
		local indexName = JSRetroBooksGetIndexName(action.character, perk);
		local modXPData = action.character:getModData();

		if(modXPData[indexName] and action.character:getPerkLevel(perk) >= minLevel) then
		
			local totalAdded = 0;
			local missedXPBank = modXPData[indexName] * SandboxVars.JSRetroBooks.Return;
				
			if(SandboxVars.JSRetroBooks.Capped) then

				local charLevel = action.character:getPerkLevel(perk);
					
				while(missedXPBank > 0 and charLevel < maxLevel) do
						
					local xpToLevel = perk:getTotalXpForLevel(charLevel+1) - (action.character:getXp():getXP(perk) + totalAdded);
	
					if(xpToLevel <= missedXPBank) then
						
						missedXPBank = missedXPBank - xpToLevel;
						totalAdded = totalAdded + xpToLevel;
						charLevel = charLevel + 1;
						
					else
						
						
						totalAdded = totalAdded + missedXPBank;
						missedXPBank = 0;

					end

				end
					
			else

				totalAdded = totalAdded + missedXPBank;
				
			end
				
			modXPData[indexName] = nil;
				
			if(totalAdded > 0) then
				
				JSRetroBooksMuteReturn[JSRetroBooksGetPlayerID(action.character)] = true;
			
				action.character:getXp():AddXP(perk, totalAdded, true, false, false);
				HaloTextHelper.addTextWithArrow(action.character, perk:getName() .. " " .. math.floor(totalAdded), true, HaloTextHelper.getColorGreen());

				JSRetroBooksMuteReturn[JSRetroBooksGetPlayerID(action.character)] = false;
			
			end
					
		end	
			
	end

end

local JSRetroBooksUpdateOld = ISReadABook.update;

-- We override this only for the obsolete skill book return settings
-- If we enable obsolete skill book XP return and the book has XP to return
-- we can make the player say something about that
-- then, if we finish the book, we can return the XP depending on the obsolete return style
function ISReadABook:update()

	local obsoleteReady = SkillBook[self.item:getSkillTrained()];

	obsoleteReady = obsoleteReady and not self.character:HasTrait("Illiterate");
	obsoleteReady = obsoleteReady and self.item:getMaxLevelTrained() < self.character:getPerkLevel(SkillBook[self.item:getSkillTrained()].perk) + 1;
	obsoleteReady = obsoleteReady and self.character:getModData()[JSRetroBooksGetObsoleteIndexName(self.character, self.item)];
	obsoleteReady = obsoleteReady and SandboxVars.JSRetroBooks.ObsoleteStyle > 1;
	
	if(obsoleteReady) then
	
		local allowConversation = self.character:isAllowConversation();
		self.character:setAllowConversation(false);

		JSRetroBooksUpdateOld(self);
		
		self.character:setAllowConversation(allowConversation);
		
		if(self.pageTimer == 0) then
				
			local textRoll = ZombRand(2);
				
			if(textRoll == 0) then
				self.character:Say(getText("IGUI_PlayerText_JSRSMoreToLearn"));
			else
				self.character:Say(getText("IGUI_PlayerText_JSRSBrushUp"));
			end
			
			self.pageTimer = 0;

		end
		
		if(self.item:getAlreadyReadPages() >= self.item:getNumberOfPages()) then
			
			local perk = SkillBook[self.item:getSkillTrained()].perk;
			local indexName = JSRetroBooksGetObsoleteIndexName(self.character, self.item);
			local modXPData = self.character:getModData();
			
			if(modXPData[indexName]) then
			
				local missedXPBank = modXPData[indexName] * SandboxVars.JSRetroBooks.Return;
				local totalAdded = 0;
				
				if(SandboxVars.JSRetroBooks.ObsoleteStyle == 2) then
				
					totalAdded = math.min(missedXPBank, JSRetroBooksGetMissableXP(self.item));
				
				elseif(SandboxVars.JSRetroBooks.ObsoleteStyle == 3) then
				
					totalAdded = missedXPBank;
				
				end
			
				modXPData[indexName] = nil;
					
				if(totalAdded > 0) then
					
					JSRetroBooksMuteReturn[JSRetroBooksGetPlayerID(self.character)] = true;	
				
					self.character:getXp():AddXP(perk, totalAdded, true, false, false);
					HaloTextHelper.addTextWithArrow(self.character, perk:getName() .. " " .. math.floor(totalAdded), true, HaloTextHelper.getColorGreen());

					JSRetroBooksMuteReturn[JSRetroBooksGetPlayerID(self.character)] = false;
				
				end
				
			end
		
		end
		
	else
	
		JSRetroBooksUpdateOld(self);
	
	end

end

local JSRetroBooksStartOld = ISReadABook.start;

-- Overriding this for the mod compatibility option to mute XP tracking when reading
-- This is for mods that add XP while reading
-- If the setting is on and we're actually reading a skill book, we can mute XP tracking
function ISReadABook:start()

	JSRetroBooksStartOld(self);
	
	if(SkillBook[self.item:getSkillTrained()] and SandboxVars.JSRetroBooks.MuteWhileReading) then
		JSRetroBooksMuteReading[JSRetroBooksGetPlayerID(self.character)] = true;	
	end

end

local JSRetroBooksStopOld = ISReadABook.stop;

-- Overriding this for reading mute--easiest way to catch when reading stops
-- Need both this, for when reading is cancelled, and perform
function ISReadABook:stop()

	JSRetroBooksStopOld(self);
	
	JSRetroBooksMuteReading[JSRetroBooksGetPlayerID(self.character)] = false;	

end

local JSRetroBooksPerformOld = ISReadABook.perform;

-- Overriding this for reading mute--easiest way to catch when reading stops
-- Need both this, for when reading is actually completed, and stop
function ISReadABook:perform()

	JSRetroBooksPerformOld(self);
	
	JSRetroBooksMuteReading[JSRetroBooksGetPlayerID(self.character)] = false;	

end

-- ! Support Functiuons ! --

-- This builds our index name so we're saving "missed" XP for each perk and training level
function JSRetroBooksGetIndexName(character, perk)

	local multiLevel = math.floor(character:getPerkLevel(perk) / 2) + 1;
	return "JSRetroBooks" .. JSRetroBooksGetPerkName(perk) .. multiLevel;

end

-- The last index name function sucks and doesn't work for obsolete levels
-- so I need this one for obsolete books
function JSRetroBooksGetObsoleteIndexName(character, item)

	local multiLevel = math.floor((item:getLvlSkillTrained() + 1) / 2);
	return "JSRetroBooks" .. item:getSkillTrained() .. multiLevel;

end

-- Like in ISReadABook, we grab the maximum multiplier from SkillBook data
function JSRetroBooksGetMaxMulti(character, perk)

	local perkName = JSRetroBooksGetPerkName(perk);
	local perkLevel = character:getPerkLevel(perk);

	if(SkillBook[perkName]) then
	
        if(perkLevel == 0 or perkLevel == 1) then
            return SkillBook[perkName].maxMultiplier1;
        elseif (perkLevel == 2 or perkLevel == 3) then
            return SkillBook[perkName].maxMultiplier2;
        elseif(perkLevel == 4 or perkLevel == 5) then
            return SkillBook[perkName].maxMultiplier3;
        elseif(perkLevel == 6 or perkLevel == 7) then
            return SkillBook[perkName].maxMultiplier4;
        elseif(perkLevel == 8 or perkLevel == 9) then
            return SkillBook[perkName].maxMultiplier5;
		end
    
	end
	
	return 1;

end

-- This is for obsolete books--we want to get the XP needed to level through the skill book range
-- Then we want to reduce it to the maximum "missable" XP, which is the ratio (1-multiplier)/multiplier
function JSRetroBooksGetMissableXP(item)

	local skillBook = SkillBook[item:getSkillTrained()];
	local xp = 0;
	
	if(skillBook) then

		local multiplier = skillBook["maxMultiplier" .. math.floor((item:getLvlSkillTrained()+ 1) / 2)];
		local multiRatio = 1;

		if(multiplier ~= nil) then
			multiRatio = (multiplier-1)/multiplier;
		end

		for i=item:getLvlSkillTrained(),item:getMaxLevelTrained() do
			xp = xp + skillBook.perk:getXpForLevel(i) * multiRatio;	
		end

	end
		
	return xp;

end

--Use this to find the min boost level
function JSRetroBooksGetCurrentMinBoostLevel(character, perk)

	local perkLevel = character:getPerkLevel(perk);
	return perkLevel - math.fmod(perkLevel, 2);
	
end

--I don't know if there's a centralized way to get the correct skillbooks skill names
--But perk getName & getId doesn't match up 1:1 so we're just using this method to make sure
--we're always using the skillbooks skill names
function JSRetroBooksGetPerkName(perk)

	for y,z in pairs(SkillBook) do
		
		if(z.perk:getName() == perk:getName()) then
		
			return y;
			
		end
		
	end
	
	return perk:getName();
	
end

-- Use this to get player id, checking whether we're multiplayer or not
function JSRetroBooksGetPlayerID(player)

	if(isClient() or isServer()) then
	
		return player:getOnlineID();
		
	else
	
		return player:getID();
		
	end
		
end

function JSRetroBooksGetMuteReading(character)

	return SandboxVars.JSRetroBooks.MuteWhileReading and JSRetroBooksMuteReading[JSRetroBooksGetPlayerID(character)] and character:isReading();

end
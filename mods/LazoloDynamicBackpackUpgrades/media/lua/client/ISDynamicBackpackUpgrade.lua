--***********************************************************
--**                    ROBERT JOHNSON                     **
--***********************************************************

require "TimedActions/ISBaseTimedAction"
require "DynamicBackpackUpgrades"

ISDynamicBackpacksAction = ISBaseTimedAction:derive("ISDynamicBackpacksAction");

function ISDynamicBackpacksAction:isValid()
	return self.StartValid
end

function ISDynamicBackpacksAction:update()
	self.item:setJobDelta(self:getJobDelta());
	for i,v in pairs(self.ExtraItems) do
		v:setJobDelta(self:getJobDelta())
	end
	--    if self.recipe:getSound() and (not self.craftSound or not self.craftSound:isPlaying()) then
	--        self.craftSound = getSoundManager():PlayWorldSoundWav(self.recipe:getSound(), self.character:getCurrentSquare(), 0, 2, 1, true);
	--    end
	self.character:setMetabolicTarget(Metabolics.UsingTools);
end

function ISDynamicBackpacksAction:start()
	--if self.recipe:getSound() then
		--self.craftSound = self.character:playSound(self.recipe:getSound());
	--end
	self.item:setJobType(self.JobType);
	self.item:setJobDelta(0.0);
	
	for i,v in pairs(self.ExtraItems) do
		v:setJobType(self.JobType)
		v:setJobDelta(0.0)
	end
	
	
	-- putting this in Start, this is a lot of code to run every frame when it really shouldn't be able to change.
	local imd = self.item:getModData()
	local TailoringModifier = SandboxVars.DynamicBackpacks.TailoringModifier
	if TailoringModifier == 0 then TailoringModifier = 100 end -- easier to make the math function do this than to make a whole set of "if" statements.
	if instanceof(self.iteminfo,"InventoryItem") then
		local UpgradesValid = imd.LMaxUpgrades > 0 and #imd.LUpgrades < imd.LMaxUpgrades + math.floor(self.character:getPerkLevel(Perks.Tailoring)/TailoringModifier)
		local ItemsLocationValid = self.character:getInventory():contains(self.item) and self.character:getInventory():contains(self.iteminfo)
		local HasTools = self.character:getInventory():contains("Needle") and self.character:getInventory():contains("Thread")
		print(UpgradesValid, ItemsLocationValid, HasTools)
		self.StartValid = UpgradesValid and ItemsLocationValid and HasTools
	else
		if self.character:getInventory():getFirstTag("Scissors") or SandboxVars.DynamicBackpacks.KnivesCanRemove and self.character:getInventory():getFirstTag("SharpKnife") then
			HasTool = true
		else
			HasTool = false
		end
		local UpgradesValid = false
		for i,v in pairs(imd.LUpgrades) do
			if v == self.iteminfo then
				UpgradesValid = true
			end
		end
		
		local BagRemovalValid = RemoveValid(self.item,self.iteminfo)
		print(HasTool, BagRemovalValid, UpgradesValid)
		self.StartValid = HasTool and BagRemovalValid and UpgradesValid
	end
	
	--if self.recipe:getProp1() or self.recipe:getProp2() then
		--self:setOverrideHandModels(self:getPropItemOrModel(self.recipe:getProp1()), self:getPropItemOrModel(self.recipe:getProp2()))
	--end
	--if self.recipe:getAnimNode() then
		--self:setActionAnim(self.recipe:getAnimNode());
	--else
		self:setActionAnim(CharacterActionAnims.Craft);
	--end

	--	self.character:reportEvent("EventCrafting");
end

function ISDynamicBackpacksAction:stop()
	--if self.craftSound and self.character:getEmitter():isPlaying(self.craftSound) then
		--self.character:stopOrTriggerSound(self.craftSound);
	--end
	self.item:setJobDelta(0.0);
	for i,v in pairs(self.ExtraItems) do
		v:setJobDelta(0.0)
	end
	ISBaseTimedAction.stop(self);
end

function ISDynamicBackpacksAction:perform()
	--if self.craftSound and self.character:getEmitter():isPlaying(self.craftSound) then
		--self.character:stopOrTriggerSound(self.craftSound);
	--end
	self.item:setJobDelta(0.0);
	for i,v in pairs(self.ExtraItems) do
		v:setJobDelta(0.0)
		if v:getType() == "Thread" then
			local Rem = v:getUsedDelta()
			if Rem > 0.1 then
				v:setUsedDelta(Rem-0.1)
			else
				v:getContainer():Remove(v)
			end
		end
	end
	self.onComplete(self.item,self.iteminfo,self.character)

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISDynamicBackpacksAction:new(character, onComplete, item, info, jobtype, extraitems)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.onComplete = onComplete;
	o.item = item;
	o.iteminfo = info
	o.StartValid = true
	o.JobType = jobtype
	o.ExtraItems = extraitems
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime = 70;
	
	if character:isTimedActionInstant() then
		--o.maxTime = 1;
	end
	o.forceProgressBar = true;
	return o;
end

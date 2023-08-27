
local upperLayer = {}
upperLayer.ISCharacterProtection = {}
upperLayer.ISCharacterProtection.render = ISCharacterProtection.render
upperLayer.ISCharacterProtection.Repair = {}
upperLayer.ISCharacterProtection.RepairAll = {}
upperLayer.ISCharacterProtection.Repair.partsInRepairAll = {}
upperLayer.ISCharacterProtection.Patch = {}
upperLayer.ISCharacterProtection.PatchAll = {}

function ISCharacterProtection:render()
    upperLayer.ISCharacterProtection.render(self)--call vanilla / upperlayer
    
    local labelBite = getText("IGUI_health_Bite");
    local labelScratch = getText("IGUI_health_Scratch");
    local labelBullet = getText("IGUI_health_Bullet");
    local biteWidth = getTextManager():MeasureStringX(UIFont.Small, labelBite);
    local scratchWidth = getTextManager():MeasureStringX(UIFont.Small, labelScratch);
    local bulletWidth = getTextManager():MeasureStringX(UIFont.Small, labelBullet);

    local xOffset = 0;
    local yOffset = 8;
    local yText = yOffset;
    local partX = 150;
    local biteX = partX + self.maxLabelWidth + 20;
    local scratchX = biteX + biteWidth + 20;
    local bulletX = scratchX + scratchWidth + 20;
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    self:drawText(labelBullet, bulletX, yText, 1, 1, 1, 1, UIFont.Small)

    yText = yText + fontHeight + 5;
    
    local mouseY = self:getMouseY()
    local mouseX = self:getMouseX()
    local minY = yText
    local maxY = yText + fontHeight * self.nbPartsDisplayed;
    local minX = partX
    local maxX = bulletX + bulletWidth;
    local displayTooltip = self:isMouseOver() and mouseY >= minY and mouseY < maxY and mouseX >= minX and mouseX < maxX;
    if self.tooltip ~= nil and not displayTooltip then
        self.tooltip:setVisible(false);
        self.tooltip:removeFromUIManager();
        self.tooltip = nil;
    end
    --print ("ISCharacterProtection.render "..self:getMouseX().." < "..minX.."/"..maxX .." | "..self:getMouseY().." < "..minY.."/"..maxY);
    
    local bodyPartsWithHole = {}
    local activateRepairAll = false
    local whiteColor = " <RGB:1,1,1> "
    local repairAllToolTipText = ""
    local linerepall = " <LINE>"

    --if AutoSewing.OPTIONS.Verbose then print ("ISCharacterProtection:render"); end
    for i=0, BodyPartType.ToIndex(BodyPartType.MAX) do
        local part = BloodBodyPartType.FromIndex(i);
        local bodyPartName = BodyPartType.ToString(BodyPartType.FromIndex(i));
        if self.bparts[bodyPartName] then
            bodyPartsWithHole[bodyPartName] = {}
            local partCoveringClothings = nil
            local bulletDefense = 0
            --if AutoSewing.OPTIONS.Verbose then print ("ISCharacterProtection:render part name = "..bodyPartName); end
            for j = 0, self.char:getWornItems():size()-1 do
                local clothingItem = self.char:getWornItems():get(j):getItem();
                if instanceof(clothingItem, "Clothing") then
                    --if AutoSewing.OPTIONS.Verbose then print ("ISCharacterProtection:render cloth = "..clothingItem:getFullType()); end
                    local clothCoverThatPart = false
                    for k=0, clothingItem:getCoveredParts():size() - 1 do
                        --if AutoSewing.OPTIONS.Verbose then print ("ISCharacterProtection:render "..clothingItem:getFullType() .. " covers "..tostring(clothingItem:getCoveredParts():get(k)).." vs "..tostring(part)); end
                        if clothingItem:getCoveredParts():get(k) == part then
                            --if AutoSewing.OPTIONS.Verbose then print ("ISCharacterProtection:render "..clothingItem:getFullType() .. " covers "..bodyPartName .." Found !"); end
                            if not partCoveringClothings then partCoveringClothings = {} end
                            partCoveringClothings[j] = clothingItem
                            clothCoverThatPart = true;
                            break
                        end
                    end
                    if clothCoverThatPart then
                        local hasHoleOnThisPart = clothingItem:getVisual():getHole(part) > 0;
                        if hasHoleOnThisPart then--current clothing could be repaired on this part
                            --if AutoSewing.OPTIONS.Verbose then print ("ISCharacterProtection:render "..clothingItem:getFullType() .. " has hole on "..bodyPartName); end
                            if bodyPartsWithHole[bodyPartName].clothingList == nil then
                                bodyPartsWithHole[bodyPartName].clothingList = {}
                                bodyPartsWithHole[bodyPartName].part = part;
                            end
                            bodyPartsWithHole[bodyPartName].clothingList[j] = clothingItem;
                        else
                            bulletDefense = bulletDefense + clothingItem:getDefForPart(part, false, true);
                        end
                    end
                end
            end
            if partCoveringClothings then
                self.holeButtons[bodyPartName]:setX(partX + self.maxLabelWidth + 5 );
                self.holeButtons[bodyPartName]:setY(yText);
                
                local tooltipText = nil
                local line = ""
                local oneOrMoreHole = false
                local oneOrMoreMissingLeatherPatch = false
                for iter,clothingItem in pairs(partCoveringClothings) do
                    local hasHole = bodyPartsWithHole[bodyPartName].clothingList and bodyPartsWithHole[bodyPartName].clothingList[iter]
                    if hasHole then
                        colorStr = self.colorRedStr
                        oneOrMoreHole = true
                        activateRepairAll = true
                        repairAllToolTipText = repairAllToolTipText .. linerepall..colorStr..clothingItem:getDisplayName()..whiteColor.." ["..bodyPartName.."]";
                    else
                        local canBePatched = clothingItem:getFabricType();
                        local patch = clothingItem:getPatchType(part);
                        if canBePatched and (not patch or patch:getFabricType()<3) then--TODO split color depending on no patch or low level patch ?
                            oneOrMoreMissingLeatherPatch = true
                            colorStr = self.colorYellowStr
                        else
                            colorStr = self.colorGreenStr
                        end
                    end
                    if not tooltipText then tooltipText = "" end
                    tooltipText = tooltipText..line..colorStr..clothingItem:getDisplayName()..whiteColor.." ["..(clothingItem:getBodyLocation() or "na").."]";
                    line = " <LINE>"
                end
                --self.holeButtons[bodyPartName].tooltip = tooltipText;--todo inform on the list of clothingItem with holes
                local displayTooltipYCurrent = mouseY >= yText and mouseY < yText+fontHeight;
                if displayTooltip and displayTooltipYCurrent then
                    if self.tooltip == nil then
                        self.tooltip = ISToolTip:new();
                        self.tooltip:initialise();
                        self.tooltip:addToUIManager();
                        self.tooltip:setOwner(self)
                    end
                    self.tooltip.description = tooltipText;
                end
                
                if oneOrMoreHole then
                    self.holeButtons[bodyPartName].textureOverride = self.textureOverrideRed;
                    self.holeButtons[bodyPartName]:setOnClick(ISCharacterProtection.repair, bodyPartName)
                elseif oneOrMoreMissingLeatherPatch then
                    self.holeButtons[bodyPartName].textureOverride = self.textureOverrideYellow;
                    --todo override callback patch
                    self.holeButtons[bodyPartName]:setOnClick(ISCharacterProtection.patch, bodyPartName, partCoveringClothings)
                else
                    self.holeButtons[bodyPartName].textureOverride = self.textureOverrideGreen;
                end
                self.holeButtons[bodyPartName].enable = oneOrMoreHole or oneOrMoreMissingLeatherPatch;
                self.holeButtons[bodyPartName]:setVisible(true);
                if self.holeButtons[bodyPartName].tooltipUI then self.holeButtons[bodyPartName].tooltipUI.backgroundColor.a = 1 end--not valid on first cycle
            else
                self.holeButtons[bodyPartName]:setVisible(false);
            end
            
            --add bullet
            bulletDefense = luautils.round(bulletDefense)
            local r, g, b = self.bodyPartPanel:getRgbForValue( bulletDefense );
            self:drawText(bulletDefense.."%", bulletX, yText, r, g, b, 1, UIFont.Small)
            
            yText = yText + fontHeight;
        end
    end
    if activateRepairAll then
        self.repairAllButton:setX(partX + self.maxLabelWidth + 5 );
        self.repairAllButton:setY(yOffset);
        self.repairAllButton.tooltip = getText("ContextMenu_Repair")..repairAllToolTipText;
        self.repairAllButton.enable = true;
        self.repairAllButton:setVisible(true);
        if self.repairAllButton.tooltipUI then self.repairAllButton.tooltipUI.backgroundColor.a = 1 end--not valid on first cycle
    else
        self.repairAllButton:setVisible(false);
    end
    
    local width = math.max(self.width, bulletX + bulletWidth + 5);
    self:setWidthAndParentWidth(width);

    self.bodyPartsWithHole = bodyPartsWithHole;
end

upperLayer.ISCharacterProtection.create = ISCharacterProtection.create
function ISCharacterProtection:create()
    upperLayer.ISCharacterProtection.create(self)--call vanilla / upperlayer

    --self.bparts["Back"] = true--watch the elusive BloodBodyPart for now it is never attacked
    self.textureOverrideRed = getTexture("media/ui/redcross10.png");
    --self.textureOverrideAmber = getTexture("media/ui/amberdot10.png");
    self.textureOverrideYellow = getTexture("media/ui/yellowdot10.png");
    self.textureOverrideGreen = getTexture("media/ui/greendot10.png");
    
    local smallFontHgt = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()
    local newButton = ISButton:new(0,0, 1, smallFontHgt, " ", self, ISCharacterProtection.repairAll);
    newButton:initialise();
    newButton:instantiate();
    newButton:setVisible(false);--try with true by default
    newButton:setBackgroundRGBA(0,0,0,0);
    newButton:setBackgroundColorMouseOverRGBA(0.3, 0.3, 0.3, 0.5);
    newButton:setBorderRGBA(0,0,0,0);
    newButton.textureOverride = self.textureOverrideRed
    self.repairAllButton = newButton
    self:addChild(self.repairAllButton);
    
    self.holeButtons = {}
    self.nbPartsDisplayed = 0;
    for i=0, BodyPartType.ToIndex(BodyPartType.MAX) do
        local bodyPartName = BodyPartType.ToString(BodyPartType.FromIndex(i));
        if self.bparts[bodyPartName] then
            local newButton = ISButton:new(0,0, 1, smallFontHgt, " ", self, ISCharacterProtection.repair);
            newButton:initialise();
            newButton:instantiate();
            newButton:setVisible(false);--try with true by default
            newButton:setBackgroundRGBA(0,0,0,0);
            newButton:setBackgroundColorMouseOverRGBA(0.3, 0.3, 0.3, 0.5);
            newButton:setBorderRGBA(0,0,0,0);
            newButton:setOnClick(ISCharacterProtection.repair, bodyPartName)
            
            self.holeButtons[bodyPartName] = newButton
            if AutoSewing.OPTIONS.Verbose then print ("ISCharacterProtection:create repair button for "..bodyPartName); end
            self:addChild(self.holeButtons[bodyPartName]);
            self.nbPartsDisplayed = self.nbPartsDisplayed + 1
        end
    end
    
    local r, g, b = self.bodyPartPanel:getRgbForValue( 100 )
    self.colorGreenStr = " <RGB:"..r..","..g..","..b.."> "
    r, g, b = self.bodyPartPanel:getRgbForValue( 50 )
    self.colorYellowStr = " <RGB:"..r..","..g..","..b.."> "
    r, g, b = self.bodyPartPanel:getRgbForValue( 25 )
    self.colorAmberStr = " <RGB:"..r..","..g..","..b.."> "
    r, g, b = self.bodyPartPanel:getRgbForValue( 0 )
    self.colorRedStr = " <RGB:"..r..","..g..","..b.."> "
end

function ISCharacterProtection:repair(button, bodyPartName)
    if AutoSewing.OPTIONS.Verbose then print ("ISCharacterProtection:repair "..tostring(bodyPartName or "nil")); end
    
    if self.bodyPartsWithHole and self.bodyPartsWithHole[bodyPartName] and self.bodyPartsWithHole[bodyPartName].clothingList then
        local needle = AutoSewing.getPlayerFastestItemAnyInventory(self.char,"Needle");
        local thread = AutoSewing.getPlayerFastestItemAnyInventory(self.char,"Thread");
        if not needle or not thread then return end
        
        for _,clothingItem in pairs(self.bodyPartsWithHole[bodyPartName].clothingList) do
            local part = self.bodyPartsWithHole[bodyPartName].part
            if AutoSewing.OPTIONS.Verbose then print ("ISCharacterProtection:repair "..tostring(clothingItem or "nil").." "..tostring(part or "nil").." "..tostring(thread or "nil").." "..tostring(needle or "nil")); end
            if part and clothingItem:getVisual():getHole(part) > 0 then
                local fabric = AutoSewing.getPatchingItem(self.char, AutoSewing.convertItemFabricTypeToEnum(clothingItem:getFabricType()));
                if AutoSewing.OPTIONS.Verbose then print ("ISCharacterProtection:repair fabric="..tostring(fabric or "nil")); end
                if fabric then
                    ISInventoryPaneContextMenu.repairClothing(self.char, clothingItem, part, fabric, thread, needle);
                    upperLayer.ISCharacterProtection.Repair.self = self;
                    upperLayer.ISCharacterProtection.Repair.bodyPartName = bodyPartName;
                    ISTimedActionQueue.add(ISContinue:new(upperLayer.ISCharacterProtection.Repair, self.char, 10));
                    return
                end
            end
        end
    end
    
    --disconnect after use (today, my code is cleaner than my living room)
    if upperLayer.ISCharacterProtection.Repair.all then
        --todo implement bodyPartName cycling
        ISTimedActionQueue.add(ISContinue:new(upperLayer.ISCharacterProtection.RepairAll, self.char, 1))
    else
        upperLayer.ISCharacterProtection.Repair.self = nil;
        upperLayer.ISCharacterProtection.Repair.bodyPartName = nil
    end
end

function ISCharacterProtection:patch(button, bodyPartName, partCoveringClothings)
    
    local needle = AutoSewing.getPlayerFastestItemAnyInventory(self.char,"Needle");
    local thread = AutoSewing.getPlayerFastestItemAnyInventory(self.char,"Thread");
    local fabric = AutoSewing.getPatchingItem(self.char, 3);
    if not needle or not thread or not fabric then return end

    if not bodyPartName then bodyPartName = upperLayer.ISCharacterProtection.Patch.bodyPartName or "" end
    if not partCoveringClothings then partCoveringClothings = upperLayer.ISCharacterProtection.Patch.partCoveringClothings or {} end
    local part = BloodBodyPartType.FromString(bodyPartName)
    if AutoSewing.OPTIONS.Verbose then print ("ISCharacterProtection:patch "..tostring(bodyPartName or "nil").." "..tostring(part or "nil")); end
    if not part then return end
    
    for iter,clothingItem in pairs(partCoveringClothings) do--a loop for 1 iteration, stupid me
        local canBePatched = clothingItem:getFabricType();
        local patch = clothingItem:getPatchType(part);
        if AutoSewing.OPTIONS.Verbose then print ("ISCharacterProtection:patch "..tostring(clothingItem or "nil").." "..tostring(part or "nil").." "..tostring(thread or "nil").." "..tostring(needle or "nil").." fabric="..tostring(fabric or "nil")); end
        if canBePatched and (not patch or patch:getFabricType()<3) then--TODO split color depending on no patch or low level patch ?
            upperLayer.ISCharacterProtection.Patch.self = self;
            upperLayer.ISCharacterProtection.Patch.bodyPartName = bodyPartName;
            upperLayer.ISCharacterProtection.Patch.partCoveringClothings = partCoveringClothings;
            if not patch then--add leather patch
                ISInventoryPaneContextMenu.repairClothing(self.char, clothingItem, part, fabric, thread, needle);
                partCoveringClothings[iter]= nil
            else--remove old patch
                ISInventoryPaneContextMenu.removePatch(self.char, clothingItem, part, needle)
            end
            ISTimedActionQueue.add(ISContinue:new(upperLayer.ISCharacterProtection.Patch, self.char, 10));
            return
        end
    end
    
    --disconnect after use (today, my code is cleaner than my living room)
    if upperLayer.ISCharacterProtection.Patch.all then
        --todo implement bodyPartName cycling
        ISTimedActionQueue.add(ISContinue:new(upperLayer.ISCharacterProtection.PatchAll, self.char, 1))
    else
        upperLayer.ISCharacterProtection.Patch.self = nil;
        upperLayer.ISCharacterProtection.Repair.bodyPartName = nil
        upperLayer.ISCharacterProtection.Patch.partCoveringClothings = nil
    end
end


function ISCharacterProtection:repairAll(button)
    upperLayer.ISCharacterProtection.Repair.iter = nil
    upperLayer.ISCharacterProtection.Repair.bodyPartName = nil
    upperLayer.ISCharacterProtection.Repair.partsInRepairAll = {}
    upperLayer.ISCharacterProtection.Repair.all = nil
    upperLayer.ISCharacterProtection.Repair.self = nil
    local iter = 0
    if AutoSewing.OPTIONS.Verbose then print ("ISCharacterProtection:repairAll") end
    for bodyPartName,struct in pairs(self.bodyPartsWithHole) do
        upperLayer.ISCharacterProtection.Repair.partsInRepairAll[iter] = bodyPartName
        if upperLayer.ISCharacterProtection.Repair.iter == nil then--start the pump
            upperLayer.ISCharacterProtection.Repair.iter = 0
            upperLayer.ISCharacterProtection.Repair.bodyPartName = bodyPartName
        end
        iter = iter + 1
    end
    if upperLayer.ISCharacterProtection.Repair.iter ~= nil then
        upperLayer.ISCharacterProtection.Repair.all = true
        upperLayer.ISCharacterProtection.Repair.self = self
        if AutoSewing.OPTIONS.Verbose then print ("ISCharacterProtection:repairAll starts with "..tostring(upperLayer.ISCharacterProtection.Repair.bodyPartName or "nil")) end
        self:repair(nil, upperLayer.ISCharacterProtection.Repair.bodyPartName)
    end
end

--specialised continue method (but is this a method?)
function upperLayer.ISCharacterProtection.Repair:continue()
    if upperLayer.ISCharacterProtection.Repair.self then
        upperLayer.ISCharacterProtection.Repair.self:repair(nil,upperLayer.ISCharacterProtection.Repair.bodyPartName)
    end
end
function upperLayer.ISCharacterProtection.Patch:continue()
    if upperLayer.ISCharacterProtection.Patch.self then
        upperLayer.ISCharacterProtection.Patch.self:patch(nil,upperLayer.ISCharacterProtection.Patch.bodyPartName)
    end
end

function upperLayer.ISCharacterProtection.RepairAll:continue()
    if AutoSewing.OPTIONS.Verbose then print ("RepairAll:continue part= "..tostring(upperLayer.ISCharacterProtection.Repair.bodyPartName or "nil") .." self="..tostring(upperLayer.ISCharacterProtection.Repair.self or "nil") ) end
    if upperLayer.ISCharacterProtection.Repair.self and upperLayer.ISCharacterProtection.Repair.bodyPartName then
        upperLayer.ISCharacterProtection.Repair.bodyPartName = nil--this part is finished
        if upperLayer.ISCharacterProtection.Repair.iter ~= nil then--go to next part
            upperLayer.ISCharacterProtection.Repair.iter = upperLayer.ISCharacterProtection.Repair.iter + 1
            upperLayer.ISCharacterProtection.Repair.bodyPartName = upperLayer.ISCharacterProtection.Repair.partsInRepairAll[upperLayer.ISCharacterProtection.Repair.iter];
            if AutoSewing.OPTIONS.Verbose then print ("RepairAll:continue next="..tostring(upperLayer.ISCharacterProtection.Repair.bodyPartName or "nil") .." / "..tostring(upperLayer.ISCharacterProtection.Repair.iter or "nil") ) end
        end
        if upperLayer.ISCharacterProtection.Repair.bodyPartName then--next part
            if AutoSewing.OPTIONS.Verbose then print ("RepairAll:continue start next part "..tostring(upperLayer.ISCharacterProtection.Repair.bodyPartName or "nil") .." / "..tostring(upperLayer.ISCharacterProtection.Repair.iter or "nil") ) end
            upperLayer.ISCharacterProtection.Repair.self:repair(nil, upperLayer.ISCharacterProtection.Repair.bodyPartName)
        else--stop the pump
            if AutoSewing.OPTIONS.Verbose then print ("RepairAll:continue stop the pump at next= "..tostring(upperLayer.ISCharacterProtection.Repair.iter or "nil") ) end
            upperLayer.ISCharacterProtection.Repair.iter = nil
            upperLayer.ISCharacterProtection.Repair.all = nil
            upperLayer.ISCharacterProtection.Repair.self = nil;
            upperLayer.ISCharacterProtection.Repair.partsInRepairAll = {}
        end
    end
end


--correct collapse/pin button
--this is brutal and could be optimized but I am bored with that shit. sorry. better solution is welcome.
upperLayer.ISCharacterInfoWindow = {}
upperLayer.ISCharacterInfoWindow.render = ISCharacterInfoWindow.render
function ISCharacterInfoWindow:render()
    local th = ISCharacterInfoWindow.instance:titleBarHeight()
    ISCharacterInfoWindow.instance.pinButton:setX(ISCharacterInfoWindow.instance.width - th - 3)
    ISCharacterInfoWindow.instance.collapseButton:setX(ISCharacterInfoWindow.instance.width - th - 3)
        
    upperLayer.ISCharacterInfoWindow.render(self)
end


--upperLayer.ISUIElement = {}
--upperLayer.ISUIElement.setX = ISUIElement.setX
--function ISUIElement:setX(x)
--    if ISCharacterInfoWindow and ISCharacterInfoWindow.instance and self == ISCharacterInfoWindow.instance.pinButton then
--        print ("ISUIElement:setX pin width from "..tostring(self.x or "nil").." to "..tostring(x or "nil").." in "..ISCharacterInfoWindow.instance:getWidth())
--    end
--    if ISCharacterInfoWindow and ISCharacterInfoWindow.instance and self == ISCharacterInfoWindow.instance.collapseButton then
--        print ("ISUIElement:setX collapseButton width from "..tostring(self.x or "nil").." to "..tostring(x or "nil").." in "..ISCharacterInfoWindow.instance:getWidth())
--    end
--    upperLayer.ISUIElement.setX(self,x)
--end

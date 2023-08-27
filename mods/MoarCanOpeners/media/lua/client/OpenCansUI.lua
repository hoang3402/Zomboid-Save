require('ISUI/ISCraftingUI')
require('ISUI/ISInventoryPaneContextMenu')

-- ***************************
-- ISCraftingUI
-- ***************************

local original_ISCraftingUI_refreshIngredientPanel = ISCraftingUI.refreshIngredientPanel
function ISCraftingUI:refreshIngredientPanel()
    local hasFocus = not self.recipeListHasFocus
    self.recipeListHasFocus = true

    self.ingredientPanel:setVisible(false)

    local recipeListbox = self:getRecipeListBox()
    if not recipeListbox.items or #recipeListbox.items == 0 or not recipeListbox.items[recipeListbox.selected] then return end

    local selectedItem = recipeListbox.items[recipeListbox.selected].item;
    if not selectedItem or selectedItem.evolved then return end

    selectedItem.typesAvailable = self:getAvailableItemsType()

    if selectedItem.recipe:getLuaCreate() ~= OpenCans.RECIPE_LUA_CREATE then
        return original_ISCraftingUI_refreshIngredientPanel(self)
    end

    self.recipeListHasFocus = not hasFocus
    self.ingredientPanel:setVisible(true)

    self.ingredientPanel:clear()

    -- Display single-item sources before multi-item sources
    local sortedSources = {}
    for _, source in ipairs(selectedItem.sources) do
        table.insert(sortedSources, source)
    end
    table.sort(sortedSources, function(a, b) return #a.items == 1 and #b.items > 1 end)

    for _, source in ipairs(sortedSources) do
        local available = {}
        local unavailable = {}

        --
        local isSourceToEdit
        for _, item in ipairs(source.items) do
            if item.fullType == OpenCans.canOpeners.smallBlade[1][1] then
                isSourceToEdit = true
            end
        end

        for _, item in ipairs(source.items) do
            -- Check if player can use listed items
            local addItemData = true
            if isSourceToEdit then
                addItemData = OpenCans.canOpenersForPlayer[item.fullType]
            end

            if addItemData then
                local data = {}
                data.selectedItem = selectedItem
                data.name = item.name
                data.texture = item.texture
                data.fullType = item.fullType
                data.count = item.count
                data.recipe = selectedItem.recipe
                data.multiple = #source.items > 1
                if selectedItem.typesAvailable and (not selectedItem.typesAvailable[item.fullType] or selectedItem.typesAvailable[item.fullType] < item.count) then
                    table.insert(unavailable, data)
                else
                    table.insert(available, data)
                end
            end
        end

        if #source.items > 1 then
            local data = {}
            data.selectedItem = selectedItem
            data.texture = self.TreeExpanded
            data.multipleHeader = true
            data.available = #available > 0
            self.ingredientPanel:addItem(getText("IGUI_CraftUI_OneOf"), data)
        end

        for _, item in ipairs(available) do
            self.ingredientPanel:addItem(item.name, item)
        end
        for _, item in ipairs(unavailable) do
            self.ingredientPanel:addItem(item.name, item)
        end
    end

    self.refreshTypesAvailableMS = getTimestampMs()
    self.ingredientPanel.doDrawItem = ISCraftingUI.drawNonEvolvedIngredient
end

-- **********************************
-- ISInventoryPaneContextMenu.lua:
-- ISRecipeTooltip
-- **********************************

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local IMAGE_SIZE = 20

local original_CraftTooltip_layoutContents = ISRecipeTooltip.layoutContents
function ISRecipeTooltip:layoutContents(x, y)
    if self.recipe:getLuaCreate() ~= OpenCans.RECIPE_LUA_CREATE then
        return original_CraftTooltip_layoutContents(self, x, y)
    end

    if self.contents then
        return self.contentsWidth, self.contentsHeight
    end

    self:getContainers()
    self:getAvailableItemsType()

    self.contents = {}
    local marginLeft = 20
    local marginTop = 10
    local marginBottom = 10
    local y1 = y + marginTop
    local lineHeight = math.max(FONT_HGT_SMALL, 20 + 2)
    local textDY = (lineHeight - FONT_HGT_SMALL) / 2
    local imageDY = (lineHeight - IMAGE_SIZE) / 2
    local singleSources = {}
    local multiSources = {}
    local allSources = {}

    for j = 1, self.recipe:getSource():size() do
        local source = self.recipe:getSource():get(j - 1)
        if source:getItems():size() == 1 then
            table.insert(singleSources, source)
        else
            table.insert(multiSources, source)
        end
    end

    -- Display singleSources before multiSources
    for _, source in ipairs(singleSources) do
        table.insert(allSources, source)
    end

    for _, source in ipairs(multiSources) do
        table.insert(allSources, source)
    end

    local maxSingleSourceLabelWidth = 0
    for _, source in ipairs(singleSources) do
        local txt = self:getSingleSourceText(source)
        local width = getTextManager():MeasureStringX(UIFont.Small, txt)
        maxSingleSourceLabelWidth = math.max(maxSingleSourceLabelWidth, width)
    end

    for _, source in ipairs(allSources) do
        local txt = ""
        local x1 = x + marginLeft
        if source:getItems():size() > 1 then
            if source:isDestroy() then
                txt = getText("IGUI_CraftUI_SourceDestroyOneOf")
            elseif source:isKeep() then
                txt = getText("IGUI_CraftUI_SourceKeepOneOf")
            else
                txt = getText("IGUI_CraftUI_SourceUseOneOf")
            end
            self:addText(x1, y1 + textDY, txt)
            y1 = y1 + lineHeight
        else
            txt = self:getSingleSourceText(source)
            self:addText(x1, y1 + textDY, txt)
            x1 = x1 + maxSingleSourceLabelWidth + 10
        end

        --
        local isSourceToEdit
        if source:getItems():contains(OpenCans.canOpeners.smallBlade[1][1]) then
            isSourceToEdit = true
        end

        local itemDataList = {}
        for k = 1, source:getItems():size() do
            -- Check if player can use listed items
            local addItemData = true
            if isSourceToEdit then
                addItemData = OpenCans.canOpenersForPlayer[source:getItems():get(k - 1)]
            end

            if addItemData then
                local itemData = {}
                itemData.fullType = source:getItems():get(k - 1)
                itemData.available = true
                -- Insert index to sort later
                itemData.index = k
                local item
                if itemData.fullType == "Water" then
                    item = ISInventoryPaneContextMenu.getItemInstance("Base.WaterDrop")
                else
                    item = ISInventoryPaneContextMenu.getItemInstance(itemData.fullType)
                    --this reads the worldsprite so the generated item will have correct icon
                    if instanceof(item, "Moveable") and instanceof(self.recipe, "MovableRecipe") then
                        item:ReadFromWorldSprite(self.recipe:getWorldSprite());
                    end
                end
                itemData.texture = ""
                if item then
                    itemData.texture = item:getTex():getName()
                    if itemData.fullType == "Water" then
                        if source:getCount() == 1 then
                            itemData.name = getText("IGUI_CraftUI_CountOneUnit", getText("ContextMenu_WaterName"))
                        else
                            itemData.name = getText("IGUI_CraftUI_CountUnits", getText("ContextMenu_WaterName"), source:getCount())
                        end
                    elseif source:getItems():size() > 1 then
                        -- no units
                        itemData.name = item:getDisplayName()
                    elseif not source:isDestroy() and item:IsDrainable() then
                        if source:getCount() == 1 then
                            itemData.name = getText("IGUI_CraftUI_CountOneUnit", item:getDisplayName())
                        else
                            itemData.name = getText("IGUI_CraftUI_CountUnits", item:getDisplayName(), source:getCount())
                        end
                    elseif not source:isDestroy() and source:getUse() > 0 then
                        -- food
                        if source:getUse() == 1 then
                            itemData.name = getText("IGUI_CraftUI_CountOneUnit", item:getDisplayName())
                        else
                            itemData.name = getText("IGUI_CraftUI_CountUnits", item:getDisplayName(), source:getUse())
                        end
                    elseif source:getCount() > 1 then
                        itemData.name = getText("IGUI_CraftUI_CountNumber", item:getDisplayName(), source:getCount())
                    else
                        itemData.name = item:getDisplayName()
                    end
                else
                    itemData.name = itemData.fullType
                end
                local countAvailable = self.typesAvailable[itemData.fullType] or 0
                if countAvailable < source:getCount() then
                    itemData.available = false
                    itemData.r = 0.54
                    itemData.g = 0.54
                    itemData.b = 0.54
                end
                table.insert(itemDataList, itemData)
            end
        end

        -- Sort by availability and then original order
        table.sort(itemDataList, function(a, b)
            if a.available ~= b.available then
                return a.available and not b.available
            end
            return a.index < b.index
        end)

        for i, itemData in ipairs(itemDataList) do
            local x2 = x1
            if source:getItems():size() > 1 then
                x2 = x2 + 20
            end
            if itemData.texture ~= "" then
                self:addImage(x2, y1 + imageDY, itemData.texture)
                x2 = x2 + IMAGE_SIZE + 6
            end
            self:addText(x2, y1 + textDY, itemData.name, itemData.r, itemData.g, itemData.b)
            y1 = y1 + lineHeight

            if i == 10 and i < #itemDataList then
                self:addText(x2, y1 + textDY, getText("Tooltip_AndNMore", #itemDataList - i))
                y1 = y1 + lineHeight
                break
            end
        end
    end

    if self.recipe:getTooltip() then
        local x1 = x + marginLeft
        local tooltip = getText(self.recipe:getTooltip())
        self:addText(x1, y1 + 8, tooltip)
    end

    self.contentsX = x
    self.contentsY = y
    self.contentsWidth = 0
    self.contentsHeight = 0
    for _, v in ipairs(self.contents) do
        self.contentsWidth = math.max(self.contentsWidth, v.x + v.width - x)
        self.contentsHeight = math.max(self.contentsHeight, v.y + v.height + marginBottom - y)
    end
    return self.contentsWidth, self.contentsHeight
end
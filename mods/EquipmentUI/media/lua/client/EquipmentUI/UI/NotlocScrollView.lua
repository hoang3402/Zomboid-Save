require "ISUI/ISUIElement"

NotlocScrollView = ISUIElement:derive("NotlocScrollView");

function NotlocScrollView:new(x, y, w, h)
	local o = {};
	o = ISUIElement:new(x, y, w, h);
	setmetatable(o, self);
    self.__index = self;

    o:setAnchorLeft(true);
    o:setAnchorRight(true);
    o:setAnchorTop(true);
    o:setAnchorBottom(true);

    o.scrollChildren = {};
    o.lastY = 0;

    o.scrollSensitivity = 12;

    return o;
end

function NotlocScrollView:createChildren()
    ISUIElement.createChildren(self);
    self:addScrollBars();
end

function NotlocScrollView:addScrollChild(child)
    self:addChild(child);
    table.insert(self.scrollChildren, child);

    local y = self:getYScroll()
    child.keepOnScreen = false
    child:setY(child:getY() + y)
end

function NotlocScrollView:removeScrollChild(child)
    self:removeChild(child);
    for i, v in ipairs(self.scrollChildren) do
        if v == child then
            table.remove(self.scrollChildren, i);
            return
        end
    end
end

function NotlocScrollView:isChildVisible(child)
    local childY = child:getY()
    local childH = child:getHeight()
    local selfH = self:getHeight()
    return childY + childH > 0 and childY < selfH
end

function NotlocScrollView:prerender()
    self:setStencilRect(0, 0, self.width, self.height);
    self:updateScrollbars();

    local deltaY = self:getYScroll() - self.lastY
    for _, child in pairs(self.scrollChildren) do
        child:setY(child:getY() + deltaY)
    end
    self.lastY = self:getYScroll()

	ISUIElement.prerender(self)
end

function NotlocScrollView:render()
    ISUIElement.render(self);
    self:clearStencilRect();
end

function NotlocScrollView:onMouseWheel(del)
    --if self.inventoryPage.isCollapsed then return false; end
	self:setYScroll(self:getYScroll() - (del * self.scrollSensitivity));
    return true;
end


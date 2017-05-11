--
-- HudText
--
-- @author  TyKonKet
-- @date 06/04/2017
HudText = {};
local HudText_mt = Class(HudText, Hud);

function HudText:new(name, text, size, x, y, parent, custom_mt)
    if custom_mt == nil then
        custom_mt = HudText_mt;
    end
    self.uiScale = g_gameSettings:getValue("uiScale");
    self.text = text;
    self:setSize(size);
    local self = Hud:new(name, x, y, self.width, self.height, parent, custom_mt);
    return self;
end

function HudText:render()
    if self.visible then
        local x, y = self:getRenderPosition();
        setTextColor(self.r, self.g, self.b, self.a);
        renderText(x, y, self.size, self.text);
        setTextColor(1, 1, 1, 1);
    end
end

function HudText:setText(text)
    self.text = text;
    self.width = getTextWidth(self.size, self.text);
    self.height = getTextHeight(self.size, self.text);
    self:realign();
end

function HudText:setSize(size)
    _, self.size = getNormalizedScreenValues(0, size * self.uiScale);
    self:setText(self.text);
end

function HudText:realign()
    if self.alignmentVertical == Hud.ALIGNS_VERTICAL_TOP then
        self.offsetY = -self.height;
    elseif self.alignmentVertical == Hud.ALIGNS_VERTICAL_MIDDLE then
        self.offsetY = -self.height * 0.5;
    else
        self.offsetY = 0;
    end
    
    if self.alignmentHorizontal == Hud.ALIGNS_HORIZONTAL_RIGHT then
        self.offsetX = -self.width;
    elseif self.alignmentHorizontal == Hud.ALIGNS_HORIZONTAL_CENTER then
        self.offsetX = -self.width * 0.5;
    else
        self.offsetX = 0;
    end
end

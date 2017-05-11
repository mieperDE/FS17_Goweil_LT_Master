--
--Goweil LT Master
--
--TyKonKet - fcelsa (Team FSI Modding)
--
--10/05/2017
BaleInfos = {};

function BaleInfos.renderTxtBale(x,y,z, text, textSize, textOffset)
    local sx,sy,sz = project(x,y,z);
    if sx > -1 and sx < 2 and sy > -1 and sy < 2 and sz <= 1 then
        setTextAlignment(RenderText.ALIGN_CENTER);
        setTextBold(true);
        setTextColor(0.0, 0.0, 1.0, 0.70);
        renderText(sx, sy-0.0018+textOffset, textSize, text);
        setTextColor(0.5, 1.0, 0.7, 1.0);
        renderText(sx, sy+textOffset, textSize, text);
        setTextAlignment(RenderText.ALIGN_LEFT);
	end;
end;

function BaleInfos:loadMap(name)
    self.guiScale = Utils.getNoNil(g_gameSettings:getValue("uiScale"),1);
	self.fontSize = 0.016*self.guiScale;
end

function BaleInfos:deleteMap()
end

function BaleInfos:keyEvent(unicode, sym, modifier, isDown)
end

function BaleInfos:mouseEvent(posX, posY, isDown, isUp, button)
end

function BaleInfos:update(dt)
    if g_currentMission.player ~= nil then
        if g_currentMission.player.isObjectInRange then
            self.nodeBaleInfos = g_currentMission:getNodeObject(g_currentMission.player.lastFoundObject);
            if self.nodeBaleInfos:isa(Bale) then
                local desc = FillUtil.fillTypeIndexToDesc[self.nodeBaleInfos.fillType];
                local iName = desc.nameI18N; 
                local fLevel = self.nodeBaleInfos.fillLevel;
                local baseValue = self.nodeBaleInfos:getValue();
                local realWeight = (fLevel * desc.massPerLiter)*1000;
                self.textBaleInfos = iName .. " (" .. string.format("%0.f l)", fLevel) .. "\n" .. string.format("%0.f kg", realWeight) .. "\n" .. g_i18n.globalI18N:formatMoney(baseValue, 0, true);
            else 
                self.textBaleInfos = nil;
            end
        else
            self.nodeBaleInfos = nil;
        end
    end
end

function BaleInfos:draw()
    if self.textBaleInfos and self.nodeBaleInfos then 
        local x,y,z = getWorldTranslation(self.nodeBaleInfos.nodeId);
        BaleInfos.renderTxtBale(x, y, z, self.textBaleInfos, getCorrectTextSize(self.fontSize), 0);
    end
end

addModEventListener(BaleInfos);
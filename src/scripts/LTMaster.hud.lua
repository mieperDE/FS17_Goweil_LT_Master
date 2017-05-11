--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--11/05/2017
function LTMaster:loadHud(savegame)
    self.LTMaster.hud = {};
    local uiScale = g_gameSettings:getValue("uiScale");
    local x = g_currentMission.vehicleHudBg.x;
    local y = g_safeFrameOffsetY + g_currentMission.vehicleHudBg.height;
    local width = 225;
    local height = 28;
    
    self.LTMaster.hud.bg = HudImage:new("HudBackground", g_baseUIFilename, x, y, width, height);
    self.LTMaster.hud.bg:setUVs(g_colorBgUVs);
    self.LTMaster.hud.bg:setColor(unpack(g_colorBg));
    
    self.LTMaster.hud.lfg = HudImage:new("HudLeftForeground", g_baseUIFilename, 0.01778, -0.08333, 75, 26.5, self.LTMaster.hud.bg);
    self.LTMaster.hud.lfg:setUVs(g_colorBgUVs);
    self.LTMaster.hud.lfg:setColor(0.0075, 0.0075, 0.0075, 1);
    
    self.LTMaster.hud.rfg = HudImage:new("HudRightForeground", g_baseUIFilename, 1 - 0.01778, -0.08333, 140, 26.5, self.LTMaster.hud.bg);
    self.LTMaster.hud.rfg:setAlignment(Hud.ALIGNS_VERTICAL_BOTTOM, Hud.ALIGNS_HORIZONTAL_RIGHT);
    self.LTMaster.hud.rfg:setUVs(g_colorBgUVs);
    self.LTMaster.hud.rfg:setColor(0.0075, 0.0075, 0.0075, 1);
    
    self.LTMaster.hud.balerLevelBar = HudLevelBar:new("HudLevelBar", g_baseUIFilename, g_colorBgUVs, nil, g_colorBg, {0.2122, 0.5271, 0.0307, 1}, nil, 0.25, 0.11321, 95, 2, self.LTMaster.hud.rfg);
    self.LTMaster.hud.balerLevelBar:setTextColor(1, 1, 1, 1);
    self.LTMaster.hud.balerLevelBar:setUnitTextColor(0.0865, 0.0865, 0.0865, 1);
    
    self.LTMaster.hud.bg:setIsVisible(false, true);
end

function LTMaster:deleteHud(savegame)
    self.LTMaster.bg:delete(true);
end

function LTMaster:updateHud(dt)
    if self:getRootAttacherVehicle().isEntered then
        self.LTMaster.hud.bg:setIsVisible(true, true);
        local value = self:getUnitFillLevel(self.LTMaster.baler.fillUnitIndex) / self:getUnitCapacity(self.LTMaster.baler.fillUnitIndex);
        self.LTMaster.hud.balerLevelBar:setValue(value);
        self.LTMaster.hud.balerLevelBar:setAll(string.format("%d", self:getUnitFillLevel(self.LTMaster.baler.fillUnitIndex)), string.format("%d%%", value * 100), self:getUnitLastValidFillType(self.LTMaster.baler.fillUnitIndex));
    else
        self.LTMaster.hud.bg:setIsVisible(false, true);
    end
end

function LTMaster:drawHud()

end

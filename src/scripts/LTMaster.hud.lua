--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--11/05/2017
function LTMaster:loadHud(savegame)
    self.LTMaster.hud = {};
    self.LTMaster.hud.player = {};
    local uiScale = g_gameSettings:getValue("uiScale");
    local x = g_currentMission.vehicleHudBg.x;
    local y = g_safeFrameOffsetY + g_currentMission.vehicleHudBg.height;
    local width = 225;
    local height = 28;
    local imageSize = {128, 128};
    
    self.LTMaster.hud.bg = HudImage:new("HudBackground", g_baseUIFilename, x, y, width, height);
    self.LTMaster.hud.bg:setUVs(g_colorBgUVs);
    self.LTMaster.hud.bg:setColor(unpack(g_colorBg));
    
    self.LTMaster.hud.lfg = HudImage:new("HudLeftForeground", g_baseUIFilename, 0.01778, -0.08333, 75, 26.5, self.LTMaster.hud.bg);
    self.LTMaster.hud.lfg:setUVs(g_colorBgUVs);
    self.LTMaster.hud.lfg:setColor(0.0075, 0.0075, 0.0075, 1);
    
    self.LTMaster.hud.wrapperIcon = HudImage:new("WrapperIcon", HudManager.modDir .. "hud/icons.dds", 0.042, 0.11320, 20, 20, self.LTMaster.hud.lfg);
    self.LTMaster.hud.wrapperIcon.normalUVs = GuiUtils.getUVs("0px 0px 64px 64px", imageSize);
    self.LTMaster.hud.wrapperIcon.activeUVs = GuiUtils.getUVs("0px 64px 64px 64px", imageSize);
    self.LTMaster.hud.wrapperIcon:setUVs(self.LTMaster.hud.wrapperIcon.normalUVs);
    
    self.LTMaster.hud.netIcon = HudProgressIcon:new("NetIcon", HudManager.modDir .. "hud/fillTypes/hud_fill_balesNet.dds", 0.36607, 0.11320, 20, 20, self.LTMaster.hud.lfg);
    self.LTMaster.hud.netIcon:setUVs(GuiUtils.getUVs("0px 0px 256px 256px", {256, 256}));
    self.LTMaster.hud.netIcon:setColor(0.2122, 0.5271, 0.0307, 1);
    
    self.LTMaster.hud.foilIcon = HudProgressIcon:new("FoilIcon", HudManager.modDir .. "hud/fillTypes/hud_fill_balesFoil.dds", 0.6875, 0.11320, 20, 20, self.LTMaster.hud.lfg);
    self.LTMaster.hud.foilIcon:setUVs(GuiUtils.getUVs("0px 0px 256px 256px", {256, 256}));
    self.LTMaster.hud.foilIcon:setColor(0.2122, 0.5271, 0.0307, 1);
    
    self.LTMaster.hud.rfg = HudImage:new("HudRightForeground", g_baseUIFilename, 1 - 0.01778, -0.08333, 140, 26.5, self.LTMaster.hud.bg);
    self.LTMaster.hud.rfg:setAlignment(Hud.ALIGNS_VERTICAL_BOTTOM, Hud.ALIGNS_HORIZONTAL_RIGHT);
    self.LTMaster.hud.rfg:setUVs(g_colorBgUVs);
    self.LTMaster.hud.rfg:setColor(0.0075, 0.0075, 0.0075, 1);
    
    self.LTMaster.hud.balerLevelBar = HudLevelBar:new("HudLevelBar", g_baseUIFilename, g_colorBgUVs, nil, g_colorBg, {0.2122, 0.5271, 0.0307, 1}, nil, 0.25, 0.11321, 95, 2, self.LTMaster.hud.rfg);
    self.LTMaster.hud.balerLevelBar:setTextColor(1, 1, 1, 1);
    self.LTMaster.hud.balerLevelBar:setUnitTextColor(0.0865, 0.0865, 0.0865, 1);
    
    self.LTMaster.hud.bg:setIsVisible(false, true);
    
    self.LTMaster.hud.player.bg = HudImage:new("HudBackground", g_baseUIFilename, g_currentMission.vehicleHudBg.x, g_safeFrameOffsetY, width, 34.5);
    self.LTMaster.hud.player.bg:setUVs(g_colorBgUVs);
    self.LTMaster.hud.player.bg:setColor(unpack(g_colorBg));
    
    self.LTMaster.hud.player.lfg = HudImage:new("HudLeftForeground", g_baseUIFilename, 0.01778, 0.11428, 75, 26.5, self.LTMaster.hud.player.bg);
    self.LTMaster.hud.player.lfg:setUVs(g_colorBgUVs);
    self.LTMaster.hud.player.lfg:setColor(0.0075, 0.0075, 0.0075, 1);
    
    self.LTMaster.hud.player.wrapperIcon = HudImage:new("WrapperIcon", HudManager.modDir .. "hud/icons.dds", 0.042, 0.11320, 20, 20, self.LTMaster.hud.player.lfg);
    self.LTMaster.hud.player.wrapperIcon.normalUVs = GuiUtils.getUVs("0px 0px 64px 64px", imageSize);
    self.LTMaster.hud.player.wrapperIcon.activeUVs = GuiUtils.getUVs("0px 64px 64px 64px", imageSize);
    self.LTMaster.hud.player.wrapperIcon:setUVs(self.LTMaster.hud.player.wrapperIcon.normalUVs);
    
    self.LTMaster.hud.player.netIcon = HudProgressIcon:new("NetIcon", HudManager.modDir .. "hud/fillTypes/hud_fill_balesNet.dds", 0.36607, 0.11320, 20, 20, self.LTMaster.hud.player.lfg);
    self.LTMaster.hud.player.netIcon:setUVs(GuiUtils.getUVs("0px 0px 256px 256px", {256, 256}));
    self.LTMaster.hud.player.netIcon:setColor(0.2122, 0.5271, 0.0307, 1);
    
    self.LTMaster.hud.player.foilIcon = HudProgressIcon:new("FoilIcon", HudManager.modDir .. "hud/fillTypes/hud_fill_balesFoil.dds", 0.6875, 0.11320, 20, 20, self.LTMaster.hud.player.lfg);
    self.LTMaster.hud.player.foilIcon:setUVs(GuiUtils.getUVs("0px 0px 256px 256px", {256, 256}));
    self.LTMaster.hud.player.foilIcon:setColor(0.2122, 0.5271, 0.0307, 1);
    
    self.LTMaster.hud.player.rfg = HudImage:new("HudRightForeground", g_baseUIFilename, 1 - 0.01778, 0.11428, 140, 26.5, self.LTMaster.hud.player.bg);
    self.LTMaster.hud.player.rfg:setAlignment(Hud.ALIGNS_VERTICAL_BOTTOM, Hud.ALIGNS_HORIZONTAL_RIGHT);
    self.LTMaster.hud.player.rfg:setUVs(g_colorBgUVs);
    self.LTMaster.hud.player.rfg:setColor(0.0075, 0.0075, 0.0075, 1);
    
    self.LTMaster.hud.player.balerLevelBar = HudLevelBar:new("HudLevelBar", g_baseUIFilename, g_colorBgUVs, nil, g_colorBg, {0.2122, 0.5271, 0.0307, 1}, nil, 0.25, 0.11321, 95, 2, self.LTMaster.hud.player.rfg);
    self.LTMaster.hud.player.balerLevelBar:setTextColor(1, 1, 1, 1);
    self.LTMaster.hud.player.balerLevelBar:setUnitTextColor(0.0865, 0.0865, 0.0865, 1);
    
    self.LTMaster.hud.player.bg:setIsVisible(false, true);
end

function LTMaster:deleteHud(savegame)
    self.LTMaster.hud.bg:delete(true);
    self.LTMaster.hud.player.bg:delete(true);
end

function LTMaster:updateHud(dt)
    local isVehicleInRange = false;
    local isPlayerInRange = false;
    if not self:getRootAttacherVehicle().isEntered and self:getIsTurnedOn() then
        local px, py, pz = getWorldTranslation(self.rootNode);
        if g_currentMission.controlledVehicle ~= nil then
            local tx, ty, tz = getWorldTranslation(g_currentMission.controlledVehicle.rootNode);
            if Utils.vector3Length(px - tx, py - ty, pz - tz) <= 15 then
                isVehicleInRange = true;
            end
        else
            local tx, ty, tz = getWorldTranslation(g_currentMission.player.rootNode);
            if Utils.vector3Length(px - tx, py - ty, pz - tz) <= 15 then
                isPlayerInRange = true;
            end
        end
    end
    if self:getRootAttacherVehicle().isEntered or isVehicleInRange then
        self.LTMaster.hud.bg:setIsVisible(true, true);
        local value = self:getUnitFillLevel(self.LTMaster.baler.fillUnitIndex) / self:getUnitCapacity(self.LTMaster.baler.fillUnitIndex);
        self.LTMaster.hud.balerLevelBar:setValue(value);
        self.LTMaster.hud.balerLevelBar:setAll(string.format("%d", self:getUnitFillLevel(self.LTMaster.baler.fillUnitIndex)), string.format("%d%%", value * 100), self:getUnitLastValidFillType(self.LTMaster.baler.fillUnitIndex));
        self.LTMaster.hud.netIcon:setValue(self.LTMaster.baler.balesNet.netRollRemainingUses / self.LTMaster.baler.balesNet.netRollUses);
        self.LTMaster.hud.foilIcon:setValue(self.LTMaster.wrapper.balesFoil.foilRollRemainingUses / self.LTMaster.wrapper.balesFoil.foilRollUses);
        if self:getIsTurnedOn() and self.LTMaster.wrapper.enabled then
            self.LTMaster.hud.wrapperIcon:setUVs(self.LTMaster.hud.wrapperIcon.activeUVs);
        else
            self.LTMaster.hud.wrapperIcon:setUVs(self.LTMaster.hud.wrapperIcon.normalUVs);
        end
    else
        self.LTMaster.hud.bg:setIsVisible(false, true);
    end
    if isPlayerInRange then
        self.LTMaster.hud.player.bg:setIsVisible(true, true);
        local value = self:getUnitFillLevel(self.LTMaster.baler.fillUnitIndex) / self:getUnitCapacity(self.LTMaster.baler.fillUnitIndex);
        self.LTMaster.hud.player.balerLevelBar:setValue(value);
        self.LTMaster.hud.player.balerLevelBar:setAll(string.format("%d", self:getUnitFillLevel(self.LTMaster.baler.fillUnitIndex)), string.format("%d%%", value * 100), self:getUnitLastValidFillType(self.LTMaster.baler.fillUnitIndex));
        self.LTMaster.hud.player.netIcon:setValue(self.LTMaster.baler.balesNet.netRollRemainingUses / self.LTMaster.baler.balesNet.netRollUses);
        self.LTMaster.hud.player.foilIcon:setValue(self.LTMaster.wrapper.balesFoil.foilRollRemainingUses / self.LTMaster.wrapper.balesFoil.foilRollUses);
        if self:getIsTurnedOn() and self.LTMaster.wrapper.enabled then
            self.LTMaster.hud.player.wrapperIcon:setUVs(self.LTMaster.hud.player.wrapperIcon.activeUVs);
        else
            self.LTMaster.hud.player.wrapperIcon:setUVs(self.LTMaster.hud.player.wrapperIcon.normalUVs);
        end
    else
        self.LTMaster.hud.player.bg:setIsVisible(false, true);
    end
end

function LTMaster:drawHud()

end

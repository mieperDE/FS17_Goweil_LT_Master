--
-- HudManager
--
-- @author  TyKonKet
-- @date 04/04/2017
HudManager = {};
HudManager.modDir = g_currentModDirectory;
HudManager.modName = g_currentModName;
HudManager.hudsKey = {};
HudManager.huds = {};
HudManager.hudIndex = 0;
source(HudManager.modDir .. "scripts/hud/hud.lua", HudManager.modName);
source(HudManager.modDir .. "scripts/hud/hudImage.lua", HudManager.modName);
source(HudManager.modDir .. "scripts/hud/hudText.lua", HudManager.modName);
source(HudManager.modDir .. "scripts/hud/hudProgressBar.lua", HudManager.modName);
source(HudManager.modDir .. "scripts/hud/hudLevelBar.lua", HudManager.modName);
source(HudManager.modDir .. "scripts/hud/hudProgressIcon.lua", HudManager.modName);

function HudManager:loadMap(name)
end

function HudManager:deleteMap()
end

function HudManager:keyEvent(unicode, sym, modifier, isDown)
    if self.missionIsStarted then
        for _, h in pairs(self.huds) do
            if h.keyEvent ~= nil then
                h:keyEvent(unicode, sym, modifier, isDown);
            end
        end
    end
end

function HudManager:mouseEvent(posX, posY, isDown, isUp, button)
    if self.missionIsStarted then
        for _, h in pairs(self.huds) do
            if h.mouseEvent ~= nil then
                h:mouseEvent(posX, posY, isDown, isUp, button);
            end
        end
    end
end

function HudManager:update(dt)
    if not self.missionIsStarted then
        self.missionIsStarted = true;
    end
    for _, h in pairs(self.huds) do
        if h.update ~= nil then
            h:update(dt);
        end
    end
end

function HudManager:draw()
    if self.missionIsStarted and g_currentMission.showVehicleInfo then
        for _, h in pairs(self.huds) do
            if h.render ~= nil then
                h:render();
            end
        end
    end
end

function HudManager:addHud(hud)
    self.hudIndex = self.hudIndex + 1;
    local key = string.format("[%s]%s", self.hudIndex, hud.name);
    self.huds[self.hudIndex] = hud;
    self.hudsKey[key] = self.hudIndex;
    return self.hudIndex, key;
end

function HudManager:removeHud(index)
    self.huds[index] = nil;
end

function HudManager:removeHudWithKey(key)
    self.huds[self.hudsKey[key]] = nil;
    self.hudsKey[key] = nil;
end

addModEventListener(HudManager);

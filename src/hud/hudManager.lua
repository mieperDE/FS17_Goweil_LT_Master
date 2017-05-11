--
-- HudManager
--
-- @author  TyKonKet
-- @date 04/04/2017
HudManager = {};
HudManager.huds = {};
HudManager.modDir = g_currentModDirectory;
HudManager.modName = g_currentModName;
source(HudManager.modDir .. "hud/hud.lua", HudManager.modName);
source(HudManager.modDir .. "hud/hudImage.lua", HudManager.modName);
source(HudManager.modDir .. "hud/hudText.lua", HudManager.modName);
source(HudManager.modDir .. "hud/hudProgressBar.lua", HudManager.modName);
source(HudManager.modDir .. "hud/hudLevelBar.lua", HudManager.modName);

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
    if self.missionIsStarted then
        for _, h in pairs(self.huds) do
            if h.render ~= nil then
                h:render();
            end
        end
    end
end

function HudManager:addHud(hud)
    table.insert(self.huds, hud);
end

addModEventListener(HudManager);

--
-- Goweil LT Master
--
-- Team FSI Modding
--
-- 18/04/2017
LTMaster = {};
LTMaster.debug = true

function LTMaster.print(text, ...)
    if LTMaster.debug then
        local start = string.format("[%s(%s)] -> ", "LTMaster", getDate("%H:%M:%S"));
        local ptext = string.format(text, ...);
        print(string.format("%s%s", start, ptext));
    end
end

function LTMaster.prerequisitesPresent(specializations)
    return true;
end

function LTMaster:preLoad(savegame)

end

function LTMaster:load(savegame)
    self.LTMaster = {};
    local triggerId = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerLeft#index"));
    addTrigger(triggerId, "playerTriggerLeft", self);
    triggerId = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerRight#index"));
    addTrigger(triggerId, "playerTriggerRight", self);
end

function LTMaster:postLoad(savegame)

end

function LTMaster:delete()

end

function LTMaster:mouseEvent(posX, posY, isDown, isUp, button)

end

function LTMaster:keyEvent(unicode, sym, modifier, isDown)

end

function LTMaster:update(dt)
end

function LTMaster:updateTick(dt)

end

function LTMaster:draw()

end

function LTMaster:playerTriggerLeft(triggerId, otherId, onEnter, onLeave)
    if g_currentMission.player ~= nil and g_currentMission.player.rootNode == otherId then
        if onEnter then
            self.triggerLeftActive = true;
        end
        if onLeave then
            self.triggerLeftActive = false;
        end
        LTMaster.debug("self.triggerLeftActive:%s", self.triggerLeftActive);
    end
end

function LTMaster:playerTriggerRight(triggerId, otherId, onEnter, onLeave)
    if g_currentMission.player ~= nil and g_currentMission.player.rootNode == otherId then
        if onEnter then
            self.triggerRightActive = true;
        end
        if onLeave then
            self.triggerRightActive = false;
        end
        LTMaster.debug("self.triggerRightActive:%s", self.triggerRightActive);
    end
end

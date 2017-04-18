--
-- Goweil LT Master
--
-- Team FSI Modding
--
-- 18/04/2017
LTMaster = {};
LTMaster.debug = true

LTMaster.STATUS_OC_OPEN = 1;
LTMaster.STATUS_OC_OPENING = 2;
LTMaster.STATUS_OC_CLOSE = 3;
LTMaster.STATUS_OC_CLOSING = 4;

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
    self.updateDoorAnim = LTMaster.updateDoorAnim;
end

function LTMaster:load(savegame)
    self.LTMaster = {};
    
    local trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerLeft#index"));
    self.LTMaster.triggerLeft = PlayerTrigger:new(trigger, 2.5);
    trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerRight#index"));
    self.LTMaster.triggerRight = PlayerTrigger:new(trigger, 2.5);
    
    self.LTMaster.doors = {};
    self.LTMaster.doors["left"] = {};
    self.LTMaster.doors["left"].animation = getXMLString(self.xmlFile, "vehicle.LTMaster.doors.leftDoor#animationName");
    self.LTMaster.doors["left"].status = LTMaster.STATUS_OC_CLOSE;
    
    self.LTMaster.doors["right"] = {};
    self.LTMaster.doors["right"].animation = getXMLString(self.xmlFile, "vehicle.LTMaster.doors.rightDoor#animationName");
    self.LTMaster.doors["right"].status = LTMaster.STATUS_OC_CLOSE;
end

function LTMaster:postLoad(savegame)
    
    self:updateDoorAnim(self.LTMaster.doors["left"], nil, true);
    self:updateDoorAnim(self.LTMaster.doors["right"], nil, true);
end

function LTMaster:delete()
    self.LTMaster.triggerLeft:delete();
    self.LTMaster.triggerRight:delete();
end

function LTMaster:mouseEvent(posX, posY, isDown, isUp, button)
end

function LTMaster:keyEvent(unicode, sym, modifier, isDown)
end

function LTMaster:update(dt)
    if self.isClient then
        if self.LTMaster.triggerLeft.active then
            if self.LTMaster.doors["left"].status == LTMaster.STATUS_OC_OPEN then
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_CLOSE_DOOR"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                    self:updateDoorAnim(self.LTMaster.doors["left"], LTMaster.STATUS_OC_CLOSE);
                end
            else
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_OPEN_DOOR"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                    self:updateDoorAnim(self.LTMaster.doors["left"], LTMaster.STATUS_OC_OPEN);
                end
            end
        end
        if self.LTMaster.triggerRight.active then
            if self.LTMaster.doors["right"].status == LTMaster.STATUS_OC_OPEN then
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_CLOSE_DOOR"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                    self:updateDoorAnim(self.LTMaster.doors["right"], LTMaster.STATUS_OC_CLOSE);
                end
            else
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_OPEN_DOOR"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                    self:updateDoorAnim(self.LTMaster.doors["right"], LTMaster.STATUS_OC_OPEN);
                end
            end
        end
    end
end

function LTMaster:updateTick(dt)
    PlayerTriggers:update();
end

function LTMaster:draw()
end

function LTMaster:updateDoorAnim(door, newStatus, setTime)
    local status = newStatus or door.status;
    if status == LTMaster.STATUS_OC_OPEN then
        if setTime then
            self:playAnimation(door.animation, math.huge);
        else
            self:playAnimation(door.animation, 1);
        end
    end
    if status == LTMaster.STATUS_OC_CLOSE then
        if setTime then
            self:playAnimation(door.animation, -math.huge);
        else
            self:playAnimation(door.animation, -1);
        end
    end
    door.status = status;
end

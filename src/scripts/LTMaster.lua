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

source(g_currentModDirectory .. "scripts/events/hoodStatusEvent.lua");

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
    self.updateHoodStatus = LTMaster.updateHoodStatus;
end

function LTMaster:load(savegame)
    self.LTMaster = {};
    
    local trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerLeft#index"));
    self.LTMaster.triggerLeft = PlayerTrigger:new(trigger, Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.triggers.triggerLeft#radius"), 2.5));
    trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerRight#index"));
    self.LTMaster.triggerRight = PlayerTrigger:new(trigger, Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.triggers.triggerRight#radius"), 2.5));
    
    self.LTMaster.hoods = {};
    self.LTMaster.hoods.openingSound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.hoods.openingSound", nil, self.baseDirectory);
    self.LTMaster.hoods.closingSound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.hoods.closingSound", nil, self.baseDirectory);
    self.LTMaster.hoods["left"] = {};
    self.LTMaster.hoods["left"].name = "left";
    self.LTMaster.hoods["left"].animation = getXMLString(self.xmlFile, "vehicle.LTMaster.hoods.leftDoor#animationName");
    self.LTMaster.hoods["left"].status = LTMaster.STATUS_OC_CLOSE;
    
    self.LTMaster.hoods["right"] = {};
    self.LTMaster.hoods["right"].name = "right";
    self.LTMaster.hoods["right"].animation = getXMLString(self.xmlFile, "vehicle.LTMaster.hoods.rightDoor#animationName");
    self.LTMaster.hoods["right"].status = LTMaster.STATUS_OC_CLOSE;
end

function LTMaster:postLoad(savegame)
    if self.isServer then
        if savegame ~= nil and not savegame.resetVehicles then
            self.LTMaster.hoods["left"].status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#leftHoodStatus"), self.LTMaster.hoods["left"].status);
            self.LTMaster.hoods["right"].status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#rightHoodStatus"), self.LTMaster.hoods["right"].status);
        end
        LTMaster.finalizeLoad(self);
    end
end

function LTMaster:getSaveAttributesAndNodes(nodeIdent)
    local attributes = string.format("leftHoodStatus=\"%s\" rightHoodStatus=\"%s\"", self.LTMaster.hoods["left"].status, self.LTMaster.hoods["right"].status);
    local nodes = nil;
    return attributes, nodes;
end

function LTMaster:finalizeLoad()
    self:updateHoodStatus(self.LTMaster.hoods["left"], nil, true);
    self:updateHoodStatus(self.LTMaster.hoods["right"], nil, true);
end

function LTMaster:delete()
    self.LTMaster.triggerLeft:delete();
    self.LTMaster.triggerRight:delete();
    SoundUtil.deleteSample(self.LTMaster.hoods.openingSound);
    SoundUtil.deleteSample(self.LTMaster.hoods.closingSound);
end

function LTMaster:mouseEvent(posX, posY, isDown, isUp, button)
end

function LTMaster:keyEvent(unicode, sym, modifier, isDown)
end

function LTMaster:update(dt)
    if self.isClient then
        -- Open/Close of the left door
        if self.LTMaster.triggerLeft.active then
            if self.LTMaster.hoods["left"].status == LTMaster.STATUS_OC_OPEN then
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_CLOSE_HOOD"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                    self:updateHoodStatus(self.LTMaster.hoods["left"], LTMaster.STATUS_OC_CLOSE);
                end
            else
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_OPEN_HOOD"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                    self:updateHoodStatus(self.LTMaster.hoods["left"], LTMaster.STATUS_OC_OPEN);
                end
            end
        end
        -- Open/Close of the right door
        if self.LTMaster.triggerRight.active then
            if self.LTMaster.hoods["right"].status == LTMaster.STATUS_OC_OPEN then
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_CLOSE_HOOD"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                    self:updateHoodStatus(self.LTMaster.hoods["right"], LTMaster.STATUS_OC_CLOSE);
                end
            else
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_OPEN_HOOD"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                    self:updateHoodStatus(self.LTMaster.hoods["right"], LTMaster.STATUS_OC_OPEN);
                end
            end
        end
    end
end

function LTMaster:writeStream(streamId, connection)
    if not connection:getIsServer() then
        streamWriteUInt8(streamId, self.LTMaster.hoods["left"].status);
        streamWriteUInt8(streamId, self.LTMaster.hoods["right"].status);
    end
end

function LTMaster:readStream(streamId, connection)
    if connection:getIsServer() then
        self.LTMaster.hoods["left"].status = streamReadUInt8(streamId);
        self.LTMaster.hoods["right"].status = streamReadUInt8(streamId);
        LTMaster.finalizeLoad(self);
    end
end

function LTMaster:writeUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        streamWriteUInt8(streamId, self.LTMaster.hoods["left"].status);
        streamWriteUInt8(streamId, self.LTMaster.hoods["right"].status);
    end
end

function LTMaster:readUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        self.LTMaster.hoods["left"].status = streamReadUInt8(streamId);
        self.LTMaster.hoods["right"].status = streamReadUInt8(streamId);
    end
end

function LTMaster:updateTick(dt)
    PlayerTriggers:update();
end

function LTMaster:draw()
end

function LTMaster:updateHoodStatus(hood, newStatus, setTime)
    local status = newStatus or hood.status;
    if g_client ~= nil then
        g_client:getServerConnection():sendEvent(HoodStatusEvent:new(status, hood.name, self));
    end
    if status == LTMaster.STATUS_OC_OPEN then
        if setTime then
            self:playAnimation(hood.animation, math.huge);
        else
            SoundUtil.playSample(self.LTMaster.hoods.openingSound, 1, 0, nil);
            self:playAnimation(hood.animation, 1);
        end
    end
    if status == LTMaster.STATUS_OC_CLOSE then
        if setTime then
            self:playAnimation(hood.animation, -math.huge);
        else
            self:playAnimation(hood.animation, -1);
            SoundUtil.playSample(self.LTMaster.hoods.closingSound, 1, 0, nil);
        end
    end
end

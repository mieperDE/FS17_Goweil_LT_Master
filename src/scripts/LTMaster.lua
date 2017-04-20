--
--Goweil LT Master
--
--Team FSI Modding
--
--18/04/2017
LTMaster = {};
LTMaster.debug = true

LTMaster.STATUS_OC_OPEN = 1;
LTMaster.STATUS_OC_OPENING = 2;
LTMaster.STATUS_OC_CLOSED = 3;
LTMaster.STATUS_OC_CLOSING = 4;

LTMaster.STATUS_RL_LOWERED = 1;
LTMaster.STATUS_RL_LOWERING = 2;
LTMaster.STATUS_RL_RAISED = 3;
LTMaster.STATUS_RL_RAISING = 4;

LTMaster.STATUS_FU_UNFOLDED = 1;
LTMaster.STATUS_FU_UNFOLDING = 2;
LTMaster.STATUS_FU_FOLDED = 3;
LTMaster.STATUS_FU_FOLDING = 4;

source(g_currentModDirectory .. "scripts/LTMaster.animations.lua");
source(g_currentModDirectory .. "scripts/helpers/delayedCallBack.lua");
source(g_currentModDirectory .. "scripts/events/hoodStatusEvent.lua");
source(g_currentModDirectory .. "scripts/events/supportsStatusEvent.lua");
source(g_currentModDirectory .. "scripts/events/foldingStatusEvent.lua");
source(g_currentModDirectory .. "scripts/events/ladderStatusEvent.lua");

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
    self.updateSupportsStatus = LTMaster.updateSupportsStatus;
    self.updateFoldingStatus = LTMaster.updateFoldingStatus;
    self.updateLadderStatus = LTMaster.updateLadderStatus;
end

function LTMaster:load(savegame)
    self.applyInitialAnimation = Utils.overwrittenFunction(self.applyInitialAnimation, LTMaster.applyInitialAnimation);
    self.getIsTurnedOnAllowed = Utils.overwrittenFunction(self.getIsTurnedOnAllowed, LTMaster.getIsTurnedOnAllowed);
    self.getTurnedOnNotAllowedWarning = Utils.overwrittenFunction(self.getTurnedOnNotAllowedWarning, LTMaster.getTurnedOnNotAllowedWarning);
    self.getConsumedPtoTorque = Utils.overwrittenFunction(self.getConsumedPtoTorque, LTMaster.getConsumedPtoTorque);
    self.getPtoRpm = Utils.overwrittenFunction(self.getPtoRpm, LTMaster.getPtoRpm);
    
    self.LTMaster = {};
    
    local trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerLeft#index"));
    self.LTMaster.triggerLeft = PlayerTrigger:new(trigger, Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.triggers.triggerLeft#radius"), 2.5));
    trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerRight#index"));
    self.LTMaster.triggerRight = PlayerTrigger:new(trigger, Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.triggers.triggerRight#radius"), 2.5));
    trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerLadder#index"));
    self.LTMaster.triggerLadder = PlayerTrigger:new(trigger, Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.triggers.triggerLadder#radius"), 2.5));
    
    self.LTMaster.hoods = {};
    self.LTMaster.hoods.openingSound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.hoods.openingSound", nil, self.baseDirectory);
    self.LTMaster.hoods.closingSound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.hoods.closingSound", nil, self.baseDirectory);
    self.LTMaster.hoods.delayedUpdateHoodStatus = DelayedCallBack:new(LTMaster.updateHoodStatus, self);
    self.LTMaster.hoods["left"] = {};
    self.LTMaster.hoods["left"].name = "left";
    self.LTMaster.hoods["left"].animation = getXMLString(self.xmlFile, "vehicle.LTMaster.hoods.leftDoor#animationName");
    self.LTMaster.hoods["left"].status = LTMaster.STATUS_OC_CLOSED;
    
    self.LTMaster.hoods["right"] = {};
    self.LTMaster.hoods["right"].name = "right";
    self.LTMaster.hoods["right"].animation = getXMLString(self.xmlFile, "vehicle.LTMaster.hoods.rightDoor#animationName");
    self.LTMaster.hoods["right"].status = LTMaster.STATUS_OC_CLOSED;
    
    self.LTMaster.supports = {};
    self.LTMaster.supports.animation = getXMLString(self.xmlFile, "vehicle.LTMaster.supports#animationName");
    self.LTMaster.supports.status = LTMaster.STATUS_RL_RAISED;
    self.LTMaster.supports.delayedUpdateSupportsStatus = DelayedCallBack:new(LTMaster.updateSupportsStatus, self);
    self.LTMaster.supports.sound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.supports.sound", nil, self.baseDirectory);
    
    self.LTMaster.folding = {};
    self.LTMaster.folding.animation = getXMLString(self.xmlFile, "vehicle.LTMaster.folding#animationName");
    self.LTMaster.folding.status = LTMaster.STATUS_FU_FOLDED;
    self.LTMaster.folding.delayedUpdateFoldingStatus = DelayedCallBack:new(LTMaster.updateFoldingStatus, self);
    self.LTMaster.folding.sound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.folding.sound", nil, self.baseDirectory);
    
    self.LTMaster.ladder = {};
    self.LTMaster.ladder.animation = getXMLString(self.xmlFile, "vehicle.LTMaster.ladder#animationName");
    self.LTMaster.ladder.status = LTMaster.STATUS_RL_RAISED;
    self.LTMaster.ladder.delayedUpdateLadderStatus = DelayedCallBack:new(LTMaster.updateLadderStatus, self);
    self.LTMaster.ladder.sound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.ladder.sound", nil, self.baseDirectory);
end

function LTMaster:postLoad(savegame)
    if self.isServer then
        if savegame ~= nil and not savegame.resetVehicles then
            self.LTMaster.hoods["left"].status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#leftHoodStatus"), self.LTMaster.hoods["left"].status);
            self.LTMaster.hoods["right"].status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#rightHoodStatus"), self.LTMaster.hoods["right"].status);
            self.LTMaster.supports.status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#supportsStatus"), self.LTMaster.supports.status);
            self.LTMaster.folding.status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#foldingStatus"), self.LTMaster.folding.status);
            self.LTMaster.ladder.status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#ladderStatus"), self.LTMaster.ladder.status);
        end
        LTMaster.finalizeLoad(self);
    end
end

function LTMaster:getSaveAttributesAndNodes(nodeIdent)
    local attributes = string.format("leftHoodStatus=\"%s\" rightHoodStatus=\"%s\" ", self.LTMaster.hoods["left"].status, self.LTMaster.hoods["right"].status);
    attributes = attributes .. string.format("supportsStatus=\"%s\" ", self.LTMaster.supports.status);
    attributes = attributes .. string.format("foldingStatus=\"%s\" ", self.LTMaster.folding.status);
    attributes = attributes .. string.format("ladderStatus=\"%s\" ", self.LTMaster.ladder.status);
    local nodes = nil;
    return attributes, nodes;
end

function LTMaster:finalizeLoad()
    self:updateHoodStatus(self.LTMaster.hoods["left"], nil, true);
    self:updateHoodStatus(self.LTMaster.hoods["right"], nil, true);
    self:updateSupportsStatus(self.LTMaster.supports.status, true);
    self:updateFoldingStatus(self.LTMaster.folding.status, true);
    self:updateLadderStatus(self.LTMaster.ladder.status, true);
end

function LTMaster:delete()
    self.LTMaster.triggerLeft:delete();
    self.LTMaster.triggerRight:delete();
    self.LTMaster.triggerLadder:delete();
    SoundUtil.deleteSample(self.LTMaster.hoods.openingSound);
    SoundUtil.deleteSample(self.LTMaster.hoods.closingSound);
    SoundUtil.deleteSample(self.LTMaster.supports.sound);
    SoundUtil.deleteSample(self.LTMaster.folding.sound);
    SoundUtil.deleteSample(self.LTMaster.ladder.sound);
end

function LTMaster:mouseEvent(posX, posY, isDown, isUp, button)
end

function LTMaster:keyEvent(unicode, sym, modifier, isDown)
end

function LTMaster:update(dt)
    self.LTMaster.hoods.delayedUpdateHoodStatus:update(dt);
    self.LTMaster.supports.delayedUpdateSupportsStatus:update(dt);
    self.LTMaster.folding.delayedUpdateFoldingStatus:update(dt);
    self.LTMaster.ladder.delayedUpdateLadderStatus:update(dt);
    if self.isClient then
        LTMaster.animationsInput(self, dt);
    end
end

function LTMaster:writeStream(streamId, connection)
    if not connection:getIsServer() then
        streamWriteUInt8(streamId, self.LTMaster.hoods["left"].status);
        streamWriteUInt8(streamId, self.LTMaster.hoods["right"].status);
        streamWriteUInt8(streamId, self.LTMaster.supports.status);
        streamWriteUInt8(streamId, self.LTMaster.folding.status);
        streamWriteUInt8(streamId, self.LTMaster.ladder.status);
    end
end

function LTMaster:readStream(streamId, connection)
    if connection:getIsServer() then
        self.LTMaster.hoods["left"].status = streamReadUInt8(streamId);
        self.LTMaster.hoods["right"].status = streamReadUInt8(streamId);
        self.LTMaster.supports.status = streamReadUInt8(streamId);
        self.LTMaster.folding.status = streamReadUInt8(streamId);
        self.LTMaster.ladder.status = streamReadUInt8(streamId);
        LTMaster.finalizeLoad(self);
    end
end

function LTMaster:writeUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        streamWriteUInt8(streamId, self.LTMaster.hoods["left"].status);
        streamWriteUInt8(streamId, self.LTMaster.hoods["right"].status);
        streamWriteUInt8(streamId, self.LTMaster.supports.status);
        streamWriteUInt8(streamId, self.LTMaster.folding.status);
        streamWriteUInt8(streamId, self.LTMaster.ladder.status);
    end
end

function LTMaster:readUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        self.LTMaster.hoods["left"].status = streamReadUInt8(streamId);
        self.LTMaster.hoods["right"].status = streamReadUInt8(streamId);
        self.LTMaster.supports.status = streamReadUInt8(streamId);
        self.LTMaster.folding.status = streamReadUInt8(streamId);
        self.LTMaster.ladder.status = streamReadUInt8(streamId);
    end
end

function LTMaster:updateTick(dt)
    PlayerTriggers:update();
end

function LTMaster:draw()
end

function LTMaster:getIsTurnedOnAllowed(superFunc, isTurnOn)
    if isTurnOn then
        if self.LTMaster.folding.status ~= LTMaster.STATUS_FU_UNFOLDED then
            return false;
        end
    end
    if superFunc ~= nil then
        return superFunc(self, isTurnOn);
    end
    return true;
end

function LTMaster:getTurnedOnNotAllowedWarning(superFunc)
    if self.LTMaster.folding.status ~= LTMaster.STATUS_FU_UNFOLDED then
        return "qui si deve mettere il messaggio di errore";
    end
    if superFunc ~= nil then
        return superFunc(self);
    end
    return nil;
end

function LTMaster:getConsumedPtoTorque(superFunc)
    local torque = 0;
    if superFunc ~= nil then
        torque = superFunc(self);
    end
    if self.LTMaster.supports.status == LTMaster.STATUS_RL_LOWERING or self.LTMaster.supports.status == LTMaster.STATUS_RL_RAISING then
        torque = torque + (50 / (540 * math.pi / 30));
    end
    if self.LTMaster.folding.status == LTMaster.STATUS_FU_FOLDING or self.LTMaster.folding.status == LTMaster.STATUS_FU_UNFOLDING then
        torque = torque + (120 / (760 * math.pi / 30));
    end
    return torque;
end

function LTMaster:getPtoRpm(superFunc)
    local ptoRpm = 0;
    if superFunc ~= nil then
        ptoRpm = superFunc(self);
    end
    if self.LTMaster.supports.status == LTMaster.STATUS_RL_LOWERING or self.LTMaster.supports.status == LTMaster.STATUS_RL_RAISING then
        ptoRpm = math.max(ptoRpm, 540);
    end
    if self.LTMaster.folding.status == LTMaster.STATUS_FU_FOLDING or self.LTMaster.folding.status == LTMaster.STATUS_FU_UNFOLDING then
        ptoRpm = math.max(ptoRpm, 760);
    end
    return ptoRpm;
end

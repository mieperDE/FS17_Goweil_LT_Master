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
    self.applyInitialAnimation = Utils.overwrittenFunction(self.applyInitialAnimation, LTMaster.applyInitialAnimation);
end

function LTMaster:load(savegame)
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

function LTMaster:applyInitialAnimation()
    --LTMaster.finalizeLoad(self);
    if superFunc ~= nil then
        superFunc(self);
    end
end

function LTMaster:setRelativePosition(positionX, offsetY, positionZ, yRot)
    --Called on setting position of vehicle (e. g. loading or reseting vehicle)
    self.LTMaster.hoods["left"].status = LTMaster.STATUS_OC_CLOSED;
    self.LTMaster.hoods["right"].status = LTMaster.STATUS_OC_CLOSED;
    self.LTMaster.supports.status = LTMaster.STATUS_RL_RAISED;
    self.LTMaster.folding.status = LTMaster.STATUS_FU_FOLDED;
    self.LTMaster.ladder.status = LTMaster.STATUS_RL_RAISED;
    LTMaster.finalizeLoad(self);
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
        --Open/Close of the left door -->
        if self.LTMaster.triggerLeft.active then
            if self.LTMaster.hoods["left"].status == LTMaster.STATUS_OC_OPEN then
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_CLOSE_HOOD"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                    self:updateHoodStatus(self.LTMaster.hoods["left"], LTMaster.STATUS_OC_CLOSING);
                end
                --Raise/Lower of the supports -->
                if self.LTMaster.supports.status == LTMaster.STATUS_RL_RAISED then
                    g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_LOWER_SUPPORTS"), InputBinding.IMPLEMENT_EXTRA4, nil, GS_PRIO_HIGH);
                    if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA4) then
                        self:updateSupportsStatus(LTMaster.STATUS_RL_LOWERING);
                    end
                end
                if self.LTMaster.supports.status == LTMaster.STATUS_RL_LOWERED then
                    g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_RAISE_SUPPORTS"), InputBinding.IMPLEMENT_EXTRA4, nil, GS_PRIO_HIGH);
                    if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA4) then
                        self:updateSupportsStatus(LTMaster.STATUS_RL_RAISING);
                    end
                    --Fold/Unfold -->
                    if self.LTMaster.folding.status == LTMaster.STATUS_FU_FOLDED then
                        g_currentMission:addHelpButtonText(g_i18n:getText("action_unfoldOBJECT"), InputBinding.IMPLEMENT_EXTRA, nil, GS_PRIO_HIGH);
                        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
                            self:updateFoldingStatus(LTMaster.STATUS_FU_UNFOLDING);
                        end
                    end
                    if self.LTMaster.folding.status == LTMaster.STATUS_FU_UNFOLDED then
                        g_currentMission:addHelpButtonText(g_i18n:getText("action_foldOBJECT"), InputBinding.IMPLEMENT_EXTRA, nil, GS_PRIO_HIGH);
                        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
                            self:updateFoldingStatus(LTMaster.STATUS_FU_FOLDING);
                        end
                    end
                --Fold/Unfold <--
                end
            --Raise/Lower of the supports <--
            end
            if self.LTMaster.hoods["left"].status == LTMaster.STATUS_OC_CLOSED then
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_OPEN_HOOD"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                    self:updateHoodStatus(self.LTMaster.hoods["left"], LTMaster.STATUS_OC_OPENING);
                end
            end
        end
        --Open/Close of the left door <--
        --Open/Close of the right door -->
        if self.LTMaster.triggerRight.active then
            if self.LTMaster.hoods["right"].status == LTMaster.STATUS_OC_OPEN then
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_CLOSE_HOOD"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                    self:updateHoodStatus(self.LTMaster.hoods["right"], LTMaster.STATUS_OC_CLOSING);
                end
            end
            if self.LTMaster.hoods["right"].status == LTMaster.STATUS_OC_CLOSED then
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_OPEN_HOOD"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                    self:updateHoodStatus(self.LTMaster.hoods["right"], LTMaster.STATUS_OC_OPENING);
                end
            end
        end
        --Open/Close of the right door <--
        --Raise/Lower of the ladder -->
        if self.LTMaster.triggerLadder.active then
            if self.LTMaster.ladder.status == LTMaster.STATUS_RL_RAISED then
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_LOWER_LADDER"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                    self:updateLadderStatus(LTMaster.STATUS_RL_LOWERING);
                end
            end
            if self.LTMaster.ladder.status == LTMaster.STATUS_RL_LOWERED then
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_RAISE_LADDER"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                    self:updateLadderStatus(LTMaster.STATUS_RL_RAISING);
                end
            end
        end
    --Raise/Lower of the ladder <--
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

function LTMaster:updateHoodStatus(hood, newStatus, noEventSend)
    local status = newStatus or hood.status;
    if not self.isServer and (noEventSend == nil or not noEventSend) then
        g_client:getServerConnection():sendEvent(HoodStatusEvent:new(status, hood.name, self));
    end
    if self.isServer then
        hood.status = status;
    end
    if status == LTMaster.STATUS_OC_OPEN then
        self:playAnimation(hood.animation, math.huge);
    end
    if status == LTMaster.STATUS_OC_OPENING then
        SoundUtil.playSample(self.LTMaster.hoods.openingSound, 1, 0, nil);
        self:playAnimation(hood.animation, 1);
        self.LTMaster.hoods.delayedUpdateHoodStatus:call(self:getAnimationDuration(hood.animation), hood, LTMaster.STATUS_OC_OPEN);
    end
    if status == LTMaster.STATUS_OC_CLOSED then
        self:playAnimation(hood.animation, -math.huge);
    end
    if status == LTMaster.STATUS_OC_CLOSING then
        SoundUtil.playSample(self.LTMaster.hoods.closingSound, 1, 0, nil);
        self:playAnimation(hood.animation, -1);
        self.LTMaster.hoods.delayedUpdateHoodStatus:call(self:getAnimationDuration(hood.animation), hood, LTMaster.STATUS_OC_CLOSED);
    end
end

function LTMaster:updateSupportsStatus(newStatus, noEventSend)
    local status = newStatus or self.LTMaster.supports.status;
    if not self.isServer and (noEventSend == nil or not noEventSend) then
        g_client:getServerConnection():sendEvent(SupportsStatusEvent:new(status, self));
    end
    if self.isServer then
        self.LTMaster.supports.status = status;
    end
    if status == LTMaster.STATUS_RL_LOWERED then
        SoundUtil.stopSample(self.LTMaster.supports.sound, true);
        self:playAnimation(self.LTMaster.supports.animation, math.huge);
    end
    if status == LTMaster.STATUS_RL_LOWERING then
        SoundUtil.playSample(self.LTMaster.supports.sound, 0, 0, nil);
        self:playAnimation(self.LTMaster.supports.animation, 1);
        self.LTMaster.supports.delayedUpdateSupportsStatus:call(self:getAnimationDuration(self.LTMaster.supports.animation), LTMaster.STATUS_RL_LOWERED);
    end
    if status == LTMaster.STATUS_RL_RAISED then
        SoundUtil.stopSample(self.LTMaster.supports.sound, true);
        self:playAnimation(self.LTMaster.supports.animation, -math.huge);
    end
    if status == LTMaster.STATUS_RL_RAISING then
        SoundUtil.playSample(self.LTMaster.supports.sound, 0, 0, nil);
        self:playAnimation(self.LTMaster.supports.animation, -1);
        self.LTMaster.supports.delayedUpdateSupportsStatus:call(self:getAnimationDuration(self.LTMaster.supports.animation), LTMaster.STATUS_RL_RAISED);
    end
end

function LTMaster:updateFoldingStatus(newStatus, noEventSend)
    local status = newStatus or self.LTMaster.folding.status;
    if not self.isServer and (noEventSend == nil or not noEventSend) then
        g_client:getServerConnection():sendEvent(FoldingStatusEvent:new(status, self));
    end
    if self.isServer then
        self.LTMaster.folding.status = status;
    end
    if status == LTMaster.STATUS_FU_UNFOLDED then
        SoundUtil.stopSample(self.LTMaster.folding.sound, true);
        self:playAnimation(self.LTMaster.folding.animation, math.huge);
    end
    if status == LTMaster.STATUS_FU_UNFOLDING then
        SoundUtil.playSample(self.LTMaster.folding.sound, 0, 0, nil);
        self:playAnimation(self.LTMaster.folding.animation, 1);
        self.LTMaster.folding.delayedUpdateFoldingStatus:call(self:getAnimationDuration(self.LTMaster.folding.animation), LTMaster.STATUS_FU_UNFOLDED);
    end
    if status == LTMaster.STATUS_FU_FOLDED then
        SoundUtil.stopSample(self.LTMaster.folding.sound, true);
        self:playAnimation(self.LTMaster.folding.animation, -math.huge);
    end
    if status == LTMaster.STATUS_FU_FOLDING then
        SoundUtil.playSample(self.LTMaster.folding.sound, 0, 0, nil);
        self:playAnimation(self.LTMaster.folding.animation, -1);
        self.LTMaster.folding.delayedUpdateFoldingStatus:call(self:getAnimationDuration(self.LTMaster.folding.animation), LTMaster.STATUS_FU_FOLDED);
    end
end

function LTMaster:updateLadderStatus(newStatus, noEventSend)
    local status = newStatus or self.LTMaster.supports.status;
    if not self.isServer and (noEventSend == nil or not noEventSend) then
        g_client:getServerConnection():sendEvent(LadderStatusEvent:new(status, self));
    end
    if self.isServer then
        self.LTMaster.ladder.status = status;
    end
    if status == LTMaster.STATUS_RL_LOWERED then
        SoundUtil.stopSample(self.LTMaster.ladder.sound, true);
        self:playAnimation(self.LTMaster.ladder.animation, math.huge);
    end
    if status == LTMaster.STATUS_RL_LOWERING then
        SoundUtil.playSample(self.LTMaster.ladder.sound, 0, 0, nil);
        self:playAnimation(self.LTMaster.ladder.animation, 1);
        self.LTMaster.ladder.delayedUpdateLadderStatus:call(self:getAnimationDuration(self.LTMaster.ladder.animation), LTMaster.STATUS_RL_LOWERED);
    end
    if status == LTMaster.STATUS_RL_RAISED then
        SoundUtil.stopSample(self.LTMaster.ladder.sound, true);
        self:playAnimation(self.LTMaster.ladder.animation, -math.huge);
    end
    if status == LTMaster.STATUS_RL_RAISING then
        SoundUtil.playSample(self.LTMaster.ladder.sound, 0, 0, nil);
        self:playAnimation(self.LTMaster.ladder.animation, -1);
        self.LTMaster.ladder.delayedUpdateLadderStatus:call(self:getAnimationDuration(self.LTMaster.ladder.animation), LTMaster.STATUS_RL_RAISED);
    end
end

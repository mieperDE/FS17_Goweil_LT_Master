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
source(g_currentModDirectory .. "scripts/events/baleSlideStatusEvent.lua");
source(g_currentModDirectory .. "scripts/events/sideUnloadEvent.lua");
source(g_currentModDirectory .. "scripts/events/conveyorStatusEvent.lua");
source(g_currentModDirectory .. "scripts/triggers/LTMasterTipTrigger.lua");

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
    self.updateBaleSlideStatus = LTMaster.updateBaleSlideStatus;
    self.unloadSide = LTMaster.unloadSide;
    self.setConveyorStatus = LTMaster.setConveyorStatus;
end

function LTMaster:load(savegame)
    self.applyInitialAnimation = Utils.overwrittenFunction(self.applyInitialAnimation, LTMaster.applyInitialAnimation);
    self.getIsTurnedOnAllowed = Utils.overwrittenFunction(self.getIsTurnedOnAllowed, LTMaster.getIsTurnedOnAllowed);
    self.getTurnedOnNotAllowedWarning = Utils.overwrittenFunction(self.getTurnedOnNotAllowedWarning, LTMaster.getTurnedOnNotAllowedWarning);
    self.getConsumedPtoTorque = Utils.overwrittenFunction(self.getConsumedPtoTorque, LTMaster.getConsumedPtoTorque);
    self.getPtoRpm = Utils.overwrittenFunction(self.getPtoRpm, LTMaster.getPtoRpm);
    
    self.LTMaster = {};
    
    self.LTMaster.fillUnits = {};
    self.LTMaster.fillUnits["main"] = {};
    self.LTMaster.fillUnits["main"].index = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.triggers.tipTrigger#fillUnitIndex"), 1);
    self.LTMaster.fillUnits["right"] = {};
    self.LTMaster.fillUnits["right"].index = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.triggers.tipTrigger#rightFillUnitIndex"), 2);
    self.LTMaster.fillUnits["right"].unloadSpeed = 0;
    self.LTMaster.fillUnits["left"] = {};
    self.LTMaster.fillUnits["left"].index = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.triggers.tipTrigger#leftFillUnitIndex"), 3);
    self.LTMaster.fillUnits["left"].unloadSpeed = 0;
    
    self.LTMaster.conveyor = {};
    self.LTMaster.conveyor.effects = EffectManager:loadEffect(self.xmlFile, "vehicle.LTMaster.conveyor.effects", self.components, self);
    self.LTMaster.conveyor.currentDelay = 0;
    for _, effect in pairs(self.LTMaster.conveyor.effects) do
        if effect.planeFadeTime ~= nil then
            self.LTMaster.conveyor.currentDelay = self.LTMaster.conveyor.currentDelay + effect.planeFadeTime;
        end
    end
    self.LTMaster.conveyor.maxDelay = self.LTMaster.conveyor.currentDelay;
    self.LTMaster.conveyor.lastLoadingTime = 0;
    self.LTMaster.conveyor.lastUnloadingTime = 0;
    self.LTMaster.conveyor.lastFillLevelChangedTime = 0;
    self.LTMaster.conveyor.lastFilllevel = 0;
    self.LTMaster.conveyor.startFillLevel = self:getUnitCapacity(self.LTMaster.fillUnits["main"].index);
    self.LTMaster.conveyor.uvScrollParts = Utils.loadScrollers(self.components, self.xmlFile, "vehicle.LTMaster.conveyor.uvScrollParts.uvScrollPart", {}, false);
    self.LTMaster.conveyor.overloadingCapacity = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.conveyor#overloadingCapacity"), 100);
    self.LTMaster.conveyor.isTurnedOn = false;
    
    self.LTMaster.sideUnload = {};
    self.LTMaster.sideUnload.animation = getXMLString(self.xmlFile, "vehicle.LTMaster.sideUnload#animationName");
    self.LTMaster.sideUnload.minAmount = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.sideUnload#minAmount"), 0);
    self.LTMaster.sideUnload.isUnloading = false;
    
    local trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerLeft#index"));
    self.LTMaster.triggerLeft = PlayerTrigger:new(trigger, Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.triggers.triggerLeft#radius"), 2.5));
    trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerRight#index"));
    self.LTMaster.triggerRight = PlayerTrigger:new(trigger, Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.triggers.triggerRight#radius"), 2.5));
    trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerLadder#index"));
    self.LTMaster.triggerLadder = PlayerTrigger:new(trigger, Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.triggers.triggerLadder#radius"), 2.5));
    trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.triggerBaleSlide#index"));
    self.LTMaster.triggerBaleSlide = PlayerTrigger:new(trigger, Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.triggers.triggerBaleSlide#radius"), 2.5));
    trigger = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.triggers.tipTrigger#index"));
    self.LTMaster.tipTrigger = LTMasterTipTrigger:new(self.isServer, self.isClient);
    self.LTMaster.tipTrigger:load(trigger, self, self.LTMaster.fillUnits["main"].index, self.LTMaster.fillUnits["right"].index, self.LTMaster.fillUnits["left"].index);
    self.LTMaster.tipTrigger:register(true);
    
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
    
    self.LTMaster.baleSlide = {};
    self.LTMaster.baleSlide.animation = getXMLString(self.xmlFile, "vehicle.LTMaster.baleSlide#animationName");
    self.LTMaster.baleSlide.status = LTMaster.STATUS_RL_RAISED;
    self.LTMaster.baleSlide.delayedUpdateBaleSlideStatus = DelayedCallBack:new(LTMaster.updateBaleSlideStatus, self);
    self.LTMaster.baleSlide.sound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.baleSlide.sound", nil, self.baseDirectory);
    
    self.fillLevelChangedDirtyFlag = self:getNextDirtyFlag();
end

function LTMaster:postLoad(savegame)
    self.setUnitFillLevel = Utils.overwrittenFunction(self.setUnitFillLevel, LTMaster.setUnitFillLevel);
    if self.isServer then
        if savegame ~= nil and not savegame.resetVehicles then
            self.LTMaster.hoods["left"].status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#leftHoodStatus"), self.LTMaster.hoods["left"].status);
            self.LTMaster.hoods["right"].status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#rightHoodStatus"), self.LTMaster.hoods["right"].status);
            self.LTMaster.supports.status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#supportsStatus"), self.LTMaster.supports.status);
            self.LTMaster.folding.status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#foldingStatus"), self.LTMaster.folding.status);
            self.LTMaster.ladder.status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#ladderStatus"), self.LTMaster.ladder.status);
            self.LTMaster.baleSlide.status = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#baleSlideStatus"), self.LTMaster.baleSlide.status);
            self.LTMaster.conveyor.isTurnedOn = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#isConveyorTurnedOn"), self.LTMaster.conveyor.isTurnedOn);
        end
        LTMaster.finalizeLoad(self);
    end
end

function LTMaster:getSaveAttributesAndNodes(nodeIdent)
    local attributes = string.format("leftHoodStatus=\"%s\" rightHoodStatus=\"%s\" ", self.LTMaster.hoods["left"].status, self.LTMaster.hoods["right"].status);
    attributes = attributes .. string.format("supportsStatus=\"%s\" ", self.LTMaster.supports.status);
    attributes = attributes .. string.format("foldingStatus=\"%s\" ", self.LTMaster.folding.status);
    attributes = attributes .. string.format("ladderStatus=\"%s\" ", self.LTMaster.ladder.status);
    attributes = attributes .. string.format("baleSlideStatus=\"%s\" ", self.LTMaster.baleSlide.status);
    attributes = attributes .. string.format("isConveyorTurnedOn=\"%s\" ", self.LTMaster.conveyor.isTurnedOn);
    local nodes = nil;
    return attributes, nodes;
end

function LTMaster:finalizeLoad()
    self:updateHoodStatus(self.LTMaster.hoods["left"], nil, true);
    self:updateHoodStatus(self.LTMaster.hoods["right"], nil, true);
    self:updateSupportsStatus(self.LTMaster.supports.status, true);
    self:updateFoldingStatus(self.LTMaster.folding.status, true);
    self:updateLadderStatus(self.LTMaster.ladder.status, true);
    self:updateBaleSlideStatus(self.LTMaster.baleSlide.status, true);
end

function LTMaster:delete()
    self.LTMaster.triggerLeft:delete();
    self.LTMaster.triggerRight:delete();
    self.LTMaster.triggerLadder:delete();
    self.LTMaster.triggerBaleSlide:delete();
    self.LTMaster.tipTrigger:delete();
    SoundUtil.deleteSample(self.LTMaster.hoods.openingSound);
    SoundUtil.deleteSample(self.LTMaster.hoods.closingSound);
    SoundUtil.deleteSample(self.LTMaster.supports.sound);
    SoundUtil.deleteSample(self.LTMaster.folding.sound);
    SoundUtil.deleteSample(self.LTMaster.ladder.sound);
    SoundUtil.deleteSample(self.LTMaster.baleSlide.sound);
    EffectManager:deleteEffects(self.LTMaster.conveyor.effects);
end

function LTMaster:mouseEvent(posX, posY, isDown, isUp, button)
end

function LTMaster:keyEvent(unicode, sym, modifier, isDown)
end

function LTMaster:writeStream(streamId, connection)
    if not connection:getIsServer() then
        streamWriteUInt8(streamId, self.LTMaster.hoods["left"].status);
        streamWriteUInt8(streamId, self.LTMaster.hoods["right"].status);
        streamWriteUInt8(streamId, self.LTMaster.supports.status);
        streamWriteUInt8(streamId, self.LTMaster.folding.status);
        streamWriteUInt8(streamId, self.LTMaster.ladder.status);
        streamWriteUInt8(streamId, self.LTMaster.baleSlide.status);
        streamWriteInt32(streamId, self.LTMaster.tipTrigger.id);
        streamWriteBool(streamId, self.LTMaster.sideUnload.isUnloading);
        streamWriteBool(streamId, self.LTMaster.conveyor.isTurnedOn);
        self.LTMaster.tipTrigger:writeStream(streamId, connection);
        g_server:registerObjectInStream(connection, self.LTMaster.tipTrigger);
    end
end

function LTMaster:readStream(streamId, connection)
    if connection:getIsServer() then
        self.LTMaster.hoods["left"].status = streamReadUInt8(streamId);
        self.LTMaster.hoods["right"].status = streamReadUInt8(streamId);
        self.LTMaster.supports.status = streamReadUInt8(streamId);
        self.LTMaster.folding.status = streamReadUInt8(streamId);
        self.LTMaster.ladder.status = streamReadUInt8(streamId);
        self.LTMaster.baleSlide.status = streamReadUInt8(streamId);
        local tipTriggerId = streamReadInt32(streamId);
        self.LTMaster.sideUnload.isUnloading = streamReadBool(streamId);
        self.LTMaster.conveyor.isTurnedOn = streamReadBool(streamId);
        self.LTMaster.tipTrigger:readStream(streamId, connection);
        g_client:finishRegisterObject(self.LTMaster.tipTrigger, tipTriggerId);
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
        streamWriteUInt8(streamId, self.LTMaster.baleSlide.status);
        streamWriteBool(streamId, self.LTMaster.sideUnload.isUnloading);
        streamWriteBool(streamId, self.LTMaster.conveyor.isTurnedOn);
        streamWriteInt32(streamId, self.LTMaster.conveyor.lastFillLevelChangedTime);
    end
end

function LTMaster:readUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        self.LTMaster.hoods["left"].status = streamReadUInt8(streamId);
        self.LTMaster.hoods["right"].status = streamReadUInt8(streamId);
        self.LTMaster.supports.status = streamReadUInt8(streamId);
        self.LTMaster.folding.status = streamReadUInt8(streamId);
        self.LTMaster.ladder.status = streamReadUInt8(streamId);
        self.LTMaster.ladder.baleSlide = streamReadUInt8(streamId);
        self.LTMaster.sideUnload.isUnloading = streamReadBool(streamId);
        self.LTMaster.conveyor.isTurnedOn = streamReadBool(streamId);
        self.LTMaster.conveyor.lastFillLevelChangedTime = streamReadInt32(streamId);
    end
end

function LTMaster:update(dt)
    self.LTMaster.hoods.delayedUpdateHoodStatus:update(dt);
    self.LTMaster.supports.delayedUpdateSupportsStatus:update(dt);
    self.LTMaster.folding.delayedUpdateFoldingStatus:update(dt);
    self.LTMaster.ladder.delayedUpdateLadderStatus:update(dt);
    self.LTMaster.baleSlide.delayedUpdateBaleSlideStatus:update(dt);
    if self.isClient then
        LTMaster.animationsInput(self, dt);
        if self.LTMaster.triggerLeft.active and not self.LTMaster.sideUnload.isUnloading then
            if self:getUnitFillLevel(self.LTMaster.fillUnits["main"].index) <= self.LTMaster.sideUnload.minAmount then
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_UNLOAD_SIDE"), InputBinding.IMPLEMENT_EXTRA4, nil, GS_PRIO_HIGH);
                if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA4) then
                    g_client:getServerConnection():sendEvent(SideUnloadEvent:new(self));
                    self.LTMaster.sideUnload.isUnloading = true;
                end
            end
        end
        if self.LTMaster.triggerLeft.active then
            if self.LTMaster.conveyor.isTurnedOn then
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_TURNOFF_CONVEYOR"), InputBinding.TOGGLE_PIPE, nil, GS_PRIO_HIGH);
            else
                g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_TURNON_CONVEYOR"), InputBinding.TOGGLE_PIPE, nil, GS_PRIO_HIGH);
            end
            if InputBinding.hasEvent(InputBinding.TOGGLE_PIPE) then
                g_client:getServerConnection():sendEvent(ConveyorStatusEvent:new(self));
            end
        end
        Utils.updateScrollers(self.LTMaster.conveyor.uvScrollParts, dt, self:getIsActive() and self.LTMaster.conveyor.isTurnedOn);
    end
end

function LTMaster:updateTick(dt)
    local normalizedDt = dt / 1000;
    PlayerTriggers:update();
    if self.isServer then
        if self.LTMaster.conveyor.isTurnedOn then
            local fillType = self:getUnitLastValidFillType(self.LTMaster.fillUnits["main"].index);
            local fillLevel = self:getUnitFillLevel(self.LTMaster.fillUnits["main"].index);
            local delta = math.min(fillLevel, self.LTMaster.conveyor.overloadingCapacity * normalizedDt);
            if delta > 0 then
                self:setUnitFillLevel(self.LTMaster.fillUnits["main"].index, fillLevel - delta, fillType);
            else
                self:setConveyorStatus(false);
            end
        end
        if self.LTMaster.sideUnload.isUnloading then
            for _, fillUnit in pairs({self.LTMaster.fillUnits["left"], self.LTMaster.fillUnits["right"]}) do
                local fillType = self:getUnitLastValidFillType(fillUnit.index);
                local fillLevel = self:getUnitFillLevel(fillUnit.index);
                local delta = math.min(fillLevel, fillUnit.unloadSpeed * dt);
                if delta > 0 then
                    local mainCapacity = self:getUnitCapacity(self.LTMaster.fillUnits["main"].index);
                    local mainFillLevel = self:getUnitFillLevel(self.LTMaster.fillUnits["main"].index);
                    local mainDelta = math.min(delta, mainCapacity - mainFillLevel);
                    if mainDelta > 0 then
                        self:setUnitFillLevel(fillUnit.index, fillLevel - mainDelta, fillType);
                        self:setUnitFillLevel(self.LTMaster.fillUnits["main"].index, mainFillLevel + mainDelta, fillType);
                    end
                end
            end
            if self:getAnimationTime(self.LTMaster.sideUnload.animation) >= 1 then
                self.LTMaster.sideUnload.isUnloading = false;
            end
        end
    end
    if self.isClient then
        if self.LTMaster.conveyor.lastFillLevelChangedTime + 100 < g_currentMission.time then
            for _, effect in pairs(self.LTMaster.conveyor.effects) do
                if effect.setScrollUpdate ~= nil then
                    effect:setScrollUpdate(false);
                end
            end
        end
    end
end

function LTMaster:draw()
end

function LTMaster:unloadSide()
    self:playAnimation(self.LTMaster.sideUnload.animation, 1);
    local animationDuration = self:getAnimationDuration(self.LTMaster.sideUnload.animation) / 2;
    self.LTMaster.fillUnits["left"].unloadSpeed = self:getUnitFillLevel(self.LTMaster.fillUnits["left"].index) / animationDuration;
    self.LTMaster.fillUnits["right"].unloadSpeed = self:getUnitFillLevel(self.LTMaster.fillUnits["right"].index) / animationDuration;
    self.LTMaster.sideUnload.isUnloading = true;
end

function LTMaster:setConveyorStatus(isTurnedOn)
    self.LTMaster.conveyor.isTurnedOn = isTurnedOn;
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

function LTMaster:setUnitFillLevel(superFunc, fillUnitIndex, fillLevel, fillType, force, fillInfo)
    local isLoading = fillLevel > self.LTMaster.conveyor.lastFilllevel;
    local isUnLoading = fillLevel < self.LTMaster.conveyor.lastFilllevel;
    
    if fillUnitIndex == self.LTMaster.fillUnits["main"].index then
        if self.isClient then
            if self.LTMaster.conveyor.effects ~= nil then
                if fillType ~= FillUtil.FILLTYPE_UNKNOWN then
                    EffectManager:setFillType(self.LTMaster.conveyor.effects, fillType)
                    EffectManager:startEffects(self.LTMaster.conveyor.effects)
                else
                    EffectManager:stopEffects(self.LTMaster.conveyor.effects)
                end
            end
            for _, effect in pairs(self.LTMaster.conveyor.effects) do
                if effect.setMorphPosition ~= nil then
                    if isLoading then
                        local globalPos = Utils.clamp(fillLevel / self.LTMaster.conveyor.startFillLevel, 0, 1)
                        local localPos = (globalPos - (effect.startDelay / self.LTMaster.conveyor.currentDelay)) / (effect.planeFadeTime / self.LTMaster.conveyor.currentDelay);
                        local offset = effect.offset / effect.planeFadeTime;
                        effect:setMorphPosition(offset, Utils.clamp(localPos + offset, offset, 1));
                    elseif isUnLoading and not isLoading then
                        local globalPos = 1 - Utils.clamp(fillLevel / self.LTMaster.conveyor.startFillLevel, 0, 1);
                        local localPos = (globalPos - (effect.startDelay / self.LTMaster.conveyor.currentDelay)) / (effect.planeFadeTime / self.LTMaster.conveyor.currentDelay);
                        local offset = effect.offset / effect.planeFadeTime;
                        effect:setMorphPosition(Utils.clamp(localPos + offset, offset, 1), 1)
                    end
                end
            end
            for _, effect in pairs(self.LTMaster.conveyor.effects) do
                if effect.setScrollUpdate ~= nil then
                    effect:setScrollUpdate(true);
                end
            end
        end
    end
    
    if isLoading then
        self.LTMaster.conveyor.lastLoadingTime = g_currentMission.time;
    elseif isUnLoading then
        self.LTMaster.conveyor.lastUnloadingTime = g_currentMission.time;
    end
    
    self.LTMaster.conveyor.lastFilllevel = fillLevel;
    
    if self.isServer then
        self.LTMaster.conveyor.lastFillLevelChangedTime = g_currentMission.time;
        self:raiseDirtyFlags(self.fillLevelChangedDirtyFlag);
    end
    
    if superFunc ~= nil then
        return superFunc(self, fillUnitIndex, fillLevel, fillType, force, fillInfo);
    end
    return nil;
end

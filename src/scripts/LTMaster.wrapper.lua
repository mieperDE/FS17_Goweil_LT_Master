--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--07/05/2017
function LTMaster:loadWrapper(savegame)
    self.getIsFoldAllowed = Utils.overwrittenFunction(self.getIsFoldAllowed, LTMaster.getIsFoldAllowed);
    self.allowsGrabbingBale = LTMaster.allowsGrabbingBale;
    self.pickupWrapperBale = LTMaster.pickupWrapperBale;
    self.getWrapperBaleType = LTMaster.getWrapperBaleType;
    self.updateWrappingState = LTMaster.updateWrappingState;
    self.dropBaleFromWrapper = LTMaster.dropBaleFromWrapper;
    self.moveBaleToWrapper = LTMaster.moveBaleToWrapper;
    self.doStateChange = LTMaster.doStateChange;
    self.updateWrapNodes = LTMaster.updateWrapNodes;
    self.playMoveToWrapper = LTMaster.playMoveToWrapper;
    for _, baleCategory in pairs({"roundBaleWrapper", "squareBaleWrapper"}) do
        self[baleCategory] = {};
        self[baleCategory].animations = {};
        for _, animType in pairs({"moveToWrapper", "wrapBale", "dropFromWrapper", "resetAfterDrop"}) do
            local key = string.format("vehicle.wrapper.%s.animations.%s", baleCategory, animType);
            self[baleCategory].animations[animType] = {};
            self[baleCategory].animations[animType].animName = getXMLString(self.xmlFile, key .. "#animName");
            self[baleCategory].animations[animType].animSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#animSpeed"), 1);
            self[baleCategory].animations[animType].reverseAfterMove = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#reverseAfterMove"), true);
        end
        self[baleCategory].allowedBaleTypes = {};
        local i = 0;
        while true do
            local key = string.format("vehicle.wrapper.%s.baleTypes.baleType(%d)", baleCategory, i);
            if not hasXMLProperty(self.xmlFile, key) then
                break;
            end
            local wrapperBaleFilename = Utils.getFilename(getXMLString(self.xmlFile, key .. "#wrapperBaleFilename"), self.baseDirectory);
            local fillTypeStr = getXMLString(self.xmlFile, key .. "#fillType");
            if wrapperBaleFilename ~= nil and fillTypeStr ~= nil then
                local fillType = FillUtil.fillTypeNameToInt[fillTypeStr];
                if fillType == nil then
                    print("Warning: invalid fillType '" .. tostring(fillTypeStr) .. "' for '" .. tostring(key) .. "' given!");
                    break;
                end
                self[baleCategory].allowedBaleTypes[fillType] = {};
                local minBaleDiameter = getXMLFloat(self.xmlFile, key .. "#minBaleDiameter");
                local maxBaleDiameter = getXMLFloat(self.xmlFile, key .. "#maxBaleDiameter");
                local minBaleWidth = getXMLFloat(self.xmlFile, key .. "#minBaleWidth");
                local maxBaleWidth = getXMLFloat(self.xmlFile, key .. "#maxBaleWidth");
                if minBaleDiameter ~= nil and maxBaleDiameter ~= nil and minBaleWidth ~= nil and maxBaleWidth ~= nil then
                    table.insert(self[baleCategory].allowedBaleTypes[fillType], {fillType = fillType, wrapperBaleFilename = wrapperBaleFilename, minBaleDiameter = minBaleDiameter, maxBaleDiameter = maxBaleDiameter, minBaleWidth = minBaleWidth, maxBaleWidth = maxBaleWidth});
                else
                    local minBaleHeight = getXMLFloat(self.xmlFile, key .. "#minBaleHeight");
                    local maxBaleHeight = getXMLFloat(self.xmlFile, key .. "#maxBaleHeight");
                    local minBaleLength = getXMLFloat(self.xmlFile, key .. "#minBaleLength");
                    local maxBaleLength = getXMLFloat(self.xmlFile, key .. "#maxBaleLength");
                    if minBaleWidth ~= nil and maxBaleWidth ~= nil and minBaleHeight ~= nil and maxBaleHeight ~= nil and minBaleLength ~= nil and maxBaleLength ~= nil then
                        table.insert(self[baleCategory].allowedBaleTypes[fillType], {fillType = fillType, wrapperBaleFilename = wrapperBaleFilename, minBaleWidth = minBaleWidth, maxBaleWidth = maxBaleWidth, minBaleHeight = minBaleHeight, maxBaleHeight = maxBaleHeight, minBaleLength = minBaleLength, maxBaleLength = maxBaleLength});
                    end
                end
            end
            i = i + 1;
        end
        local key = string.format("vehicle.wrapper.%s", baleCategory);
        self[baleCategory].baleNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#baleIndex"));
        self[baleCategory].wrapperNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#wrapperIndex"));
        self[baleCategory].wrapperRotAxis = Utils.getNoNil(getXMLInt(self.xmlFile, key .. "#wrapperRotAxis"), 2);
        local wrappingAnimCurve = AnimCurve:new(linearInterpolatorN);
        local i = 0;
        while true do
            local keyI = string.format("%s.wrapperAnimation.key(%d)", key, i);
            local t = getXMLFloat(self.xmlFile, keyI .. "#time");
            local baleX, baleY, baleZ = Utils.getVectorFromString(getXMLString(self.xmlFile, keyI .. "#baleRot"));
            if baleX == nil or baleY == nil or baleZ == nil then
                break;
            end
            baleX = math.rad(Utils.getNoNil(baleX, 0));
            baleY = math.rad(Utils.getNoNil(baleY, 0));
            baleZ = math.rad(Utils.getNoNil(baleZ, 0));
            local wrapperX, wrapperY, wrapperZ = Utils.getVectorFromString(getXMLString(self.xmlFile, keyI .. "#wrapperRot"));
            wrapperX = math.rad(Utils.getNoNil(wrapperX, 0));
            wrapperY = math.rad(Utils.getNoNil(wrapperY, 0));
            wrapperZ = math.rad(Utils.getNoNil(wrapperZ, 0));
            wrappingAnimCurve:addKeyframe({v = {baleX, baleY, baleZ, wrapperX, wrapperY, wrapperZ}, time = t});
            i = i + 1;
        end
        self[baleCategory].animCurve = wrappingAnimCurve;
        self[baleCategory].animTime = Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#wrappingTime"), 5) * 1000;
        self[baleCategory].currentTime = 0;
        self[baleCategory].currentBale = nil;
        self[baleCategory].wrapAnimNodes = {};
        local i = 0;
        while true do
            local wrapAnimNodeKey = string.format("vehicle.wrapper.%s.wrapAnimNodes.wrapAnimNode(%d)", baleCategory, i);
            if not hasXMLProperty(self.xmlFile, wrapAnimNodeKey) then
                break;
            end
            local nodeId = Utils.indexToObject(self.components, getXMLString(self.xmlFile, wrapAnimNodeKey .. "#index"));
            if nodeId ~= nil then
                local animCurve = AnimCurve:new(linearInterpolatorN);
                local keyI = 0;
                local useWrapperRot = false;
                while true do
                    local key = string.format(wrapAnimNodeKey .. ".key(%d)", keyI);
                    local wrapperRot = getXMLFloat(self.xmlFile, key .. "#wrapperRot");
                    local wrapperTime = getXMLFloat(self.xmlFile, key .. "#wrapperTime");
                    if wrapperRot == nil and wrapperTime == nil then
                        break;
                    end
                    useWrapperRot = wrapperRot ~= nil;
                    local x, y, z = Utils.getVectorFromString(getXMLString(self.xmlFile, key .. "#trans"));
                    local rx, ry, rz = Utils.getVectorFromString(getXMLString(self.xmlFile, key .. "#rot"));
                    local sx, sy, sz = Utils.getVectorFromString(getXMLString(self.xmlFile, key .. "#scale"));
                    x = Utils.getNoNil(x, 0);
                    y = Utils.getNoNil(y, 0);
                    z = Utils.getNoNil(z, 0);
                    rx = math.rad(Utils.getNoNil(rx, 0));
                    ry = math.rad(Utils.getNoNil(ry, 0));
                    rz = math.rad(Utils.getNoNil(rz, 0));
                    sx = Utils.getNoNil(sx, 1);
                    sy = Utils.getNoNil(sy, 1);
                    sz = Utils.getNoNil(sz, 1);
                    if wrapperRot ~= nil then
                        animCurve:addKeyframe({v = {x, y, z, rx, ry, rz, sx, sy, sz}, time = math.rad(wrapperRot)});
                    else
                        animCurve:addKeyframe({v = {x, y, z, rx, ry, rz, sx, sy, sz}, time = wrapperTime});
                    end
                    keyI = keyI + 1;
                end
                if keyI > 0 then
                    local repeatWrapperRot = Utils.getNoNil(getXMLBool(self.xmlFile, wrapAnimNodeKey .. "#repeatWrapperRot"), false);
                    local normalizeRotationOnBaleDrop = Utils.getNoNil(getXMLInt(self.xmlFile, wrapAnimNodeKey .. "#normalizeRotationOnBaleDrop"), 0);
                    table.insert(self[baleCategory].wrapAnimNodes, {nodeId = nodeId, animCurve = animCurve, repeatWrapperRot = repeatWrapperRot, normalizeRotationOnBaleDrop = normalizeRotationOnBaleDrop, useWrapperRot = useWrapperRot});
                end
            end
            i = i + 1;
        end
        self[baleCategory].wrapNodes = {};
        local i = 0;
        while true do
            local wrapNodeKey = string.format("vehicle.wrapper.%s.wrapNodes.wrapNode(%d)", baleCategory, i);
            if not hasXMLProperty(self.xmlFile, wrapNodeKey) then
                break;
            end
            local nodeId = Utils.indexToObject(self.components, getXMLString(self.xmlFile, wrapNodeKey .. "#index"));
            local wrapVisibility = Utils.getNoNil(getXMLBool(self.xmlFile, wrapNodeKey .. "#wrapVisibility"), false);
            local emptyVisibility = Utils.getNoNil(getXMLBool(self.xmlFile, wrapNodeKey .. "#emptyVisibility"), false);
            if nodeId ~= nil and (wrapVisibility or emptyVisibility) then
                local maxWrapperRot = getXMLFloat(self.xmlFile, wrapNodeKey .. "#maxWrapperRot");
                if maxWrapperRot == nil then
                    maxWrapperRot = math.huge;
                else
                    maxWrapperRot = math.rad(maxWrapperRot);
                end
                table.insert(self[baleCategory].wrapNodes, {nodeId = nodeId, wrapVisibility = wrapVisibility, emptyVisibility = emptyVisibility, maxWrapperRot = maxWrapperRot});
            end
            i = i + 1;
        end
        local defaultText = baleCategory == "roundBaleWrapper" and "action_unloadRoundBale" or "action_unloadBaler";
        self[baleCategory].unloadBaleText = Utils.getNoNil(getXMLString(self.xmlFile, key .. "#unloadBaleText"), defaultText);
    end
    self.currentWrapper = {};
    self.currentWrapperFoldMinLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.wrapper#foldMinLimit"), 0);
    self.currentWrapperFoldMaxLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.wrapper#foldMaxLimit"), 1);
    self.showInvalidBaleWarning = false;
    self.currentWrapper = self.roundBaleWrapper;
    self:updateWrapNodes(false, true, 0);
    self.currentWrapper = self.squareBaleWrapper;
    self:updateWrapNodes(false, true, 0);
    self.baleGrabber = {};
    self.baleGrabber.grabNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.baleGrabber#index"));
    self.baleGrabber.nearestDistance = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baleGrabber#nearestDistance"), 3.0);
    self.baleGrabber.origTrans = {getTranslation(self.baleGrabber.grabNode)};
    if self.isClient then
        self.currentWrapperSound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.wrapperSound", nil, self.baseDirectory, self.components[1].node);
        self.currentWrapperStartSound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.wrapperStartSound", nil, self.baseDirectory, self.components[1].node);
        self.currentWrapperStopSound = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.wrapperStopSound", nil, self.baseDirectory, self.components[1].node);
    end
    self.baleToLoad = nil;
    self.baleToMount = nil;
    self.baleWrapperState = BaleWrapper.STATE_NONE;
    self.grabberIsMoving = false;
    self.hasBaleWrapper = true;
    if savegame ~= nil and not savegame.resetVehicles then
        local filename = getXMLString(savegame.xmlFile, savegame.key .. "#baleFileName");
        if filename ~= nil then
            filename = Utils.convertFromNetworkFilename(filename);
            local wrapperTime = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#wrapperTime"), 0);
            local baleValueScale = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#baleValueScale"), 1);
            local fillLevel = getXMLFloat(savegame.xmlFile, savegame.key .. "#fillLevel");
            local translation = {0, 0, 0};
            local rotation = {0, 0, 0};
            self.baleToLoad = {filename = filename, translation = translation, rotation = rotation, fillLevel = fillLevel, wrapperTime = wrapperTime, baleValueScale = baleValueScale};
        end
    end
end

function LTMaster:deleteWrapper()
    if self.isServer then
        local baleId;
        if self.currentWrapper.currentBale ~= nil then
            baleId = self.currentWrapper.currentBale;
        end
        if self.baleGrabber.currentBale ~= nil then
            baleId = self.baleGrabber.currentBale;
        end
        if baleId ~= nil then
            local bale = networkGetObject(baleId);
            if bale ~= nil then
                bale:unmount();
            end
        end
    end
    if self.isClient then
        SoundUtil.deleteSample(self.currentWrapperSound);
        SoundUtil.deleteSample(self.currentWrapperStartSound);
        SoundUtil.deleteSample(self.currentWrapperStopSound);
    end
end

function LTMaster:readStreamWrapper(streamId, connection)
    if connection:getIsServer() then
        local wrapperState = streamReadUIntN(streamId, BaleWrapper.STATE_NUM_BITS);
        if wrapperState >= BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
            local baleServerId;
            if wrapperState ~= BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
                baleServerId = readNetworkNodeObjectId(streamId);
            end
            if wrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
                self:doStateChange(BaleWrapper.CHANGE_GRAB_BALE, baleServerId);
                AnimatedVehicle.updateAnimations(self, 99999999);
            elseif wrapperState == BaleWrapper.STATE_MOVING_GRABBER_TO_WORK then
                self.baleGrabber.currentBale = baleServerId;
                self:doStateChange(BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER);
                AnimatedVehicle.updateAnimations(self, 99999999);
            elseif wrapperState ~= BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
                local attachNode = self.currentWrapper.baleNode;
                self.baleToMount = {serverId = baleServerId, linkNode = attachNode, trans = {0, 0, 0}, rot = {0, 0, 0}};
                self:updateWrapNodes(true, false, 0);
                self.currentWrapper.currentBale = baleServerId;
                if wrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
                    local wrapperTime = streamReadFloat32(streamId);
                    self.currentWrapper.currentTime = wrapperTime;
                    self:updateWrappingState(self.currentWrapper.currentTime / self.currentWrapper.animTime, true);
                else
                    self.currentWrapper.currentTime = self.currentWrapper.animTime;
                    self:updateWrappingState(1, true);
                    self:doStateChange(BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED);
                    AnimatedVehicle.updateAnimations(self, 99999999);
                    if wrapperState >= BaleWrapper.STATE_WRAPPER_DROPPING_BALE then
                        self:doStateChange(BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE);
                        AnimatedVehicle.updateAnimations(self, 99999999);
                    end
                end
            else
                self.baleWrapperState = BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM;
            end
        end
    end
end

function LTMaster:writeStreamWrapper(streamId, connection)
    if not connection:getIsServer() then
        local wrapperState = self.baleWrapperState;
        streamWriteUIntN(streamId, wrapperState, BaleWrapper.STATE_NUM_BITS);
        if wrapperState >= BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER and wrapperState ~= BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
            if wrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
                writeNetworkNodeObjectId(streamId, self.baleGrabber.currentBale);
            else
                writeNetworkNodeObjectId(streamId, self.currentWrapper.currentBale);
            end
        end
        if wrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
            streamWriteFloat32(streamId, self.currentWrapper.currentTime);
        end
    end
end

function LTMaster:updateWrapper(dt)
    if self.firstTimeRun then
        if self.baleToLoad ~= nil then
            local v = self.baleToLoad;
            self.baleToLoad = nil;
            local baleObject = Bale:new(self.isServer, self.isClient);
            local x, y, z = unpack(v.translation);
            local rx, ry, rz = unpack(v.rotation);
            baleObject:load(v.filename, x, y, z, rx, ry, rz, v.fillLevel);
            if baleObject.nodeId ~= nil and baleObject.nodeId ~= 0 then
                self:playMoveToWrapper(baleObject);
                baleObject.baleValueScale = v.baleValueScale;
                local wrapperState = math.min(v.wrapperTime / self.currentWrapper.animTime, 1);
                baleObject:setWrappingState(wrapperState);
                baleObject:mount(self, self.currentWrapper.baleNode, x, y, z, rx, ry, rz)
                baleObject:register();
                self:doStateChange(BaleWrapper.CHANGE_WRAPPING_START);
                self.currentWrapper.currentBale = networkGetObjectId(baleObject);
                self.currentWrapper.currentTime = v.wrapperTime;
                self:updateWrappingState(self.currentWrapper.currentTime / self.currentWrapper.animTime);
            end
        end
        if self.baleToMount ~= nil then
            local bale = networkGetObject(self.baleToMount.serverId);
            if bale ~= nil then
                local x, y, z = unpack(self.baleToMount.trans);
                local rx, ry, rz = unpack(self.baleToMount.rot);
                bale:mount(self, self.baleToMount.linkNode, x, y, z, rx, ry, rz);
                self.baleToMount = nil;
                if self.baleWrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
                    self:playMoveToWrapper(bale)
                end
            end
        end
    end
    if self:getIsActive() then
        if self:getIsActiveForInput() then
            if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA3) then
                if self.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED then
                    g_client:getServerConnection():sendEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_BUTTON_EMPTY));
                end
            end
        end
        if self.baleWrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
            if self.isClient then
                if not self.currentWrapperSound.isPlaying then
                    if self.currentWrapperStartSound.sample == nil or not SoundUtil.isSamplePlaying(self.currentWrapperStartSound, 1.8 * dt) then
                        Sound3DUtil:playSample(self.currentWrapperSound, 0, 0, nil, self:getIsActiveForSound());
                    end
                end
            end
            self.currentWrapper.currentTime = self.currentWrapper.currentTime + dt;
            self:updateWrappingState(self.currentWrapper.currentTime / self.currentWrapper.animTime);
        end
    end
end

function LTMaster:updateTickWrapper(dt)
    if self:getIsActive() then
        self.showInvalidBaleWarning = false;
        if self:allowsGrabbingBale() then
            if self.baleGrabber.grabNode ~= nil and self.baleGrabber.currentBale == nil then
                local nearestBale, nearestBaleType = LTMaster.getBaleInRange(self, self.baleGrabber.grabNode, self.baleGrabber.nearestDistance);
                if nearestBale ~= nil then
                    if nearestBaleType == nil then
                        if self.lastDroppedBale ~= nearestBale then
                            self.showInvalidBaleWarning = true;
                        end
                    elseif self.isServer then
                        self:pickupWrapperBale(nearestBale, nearestBaleType);
                    end
                end
            end
        end
        if self.isServer then
            if self.baleWrapperState ~= BaleWrapper.STATE_NONE then
                if self.baleWrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
                    if not self:getIsAnimationPlaying(self.currentWrapper.animations["moveToWrapper"].animName) then
                        g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER), true, nil, self);
                    end
                elseif self.baleWrapperState == BaleWrapper.STATE_MOVING_GRABBER_TO_WORK then
                    if not self:getIsAnimationPlaying(self.currentWrapper.animations["moveToWrapper"].animName) then
                        local bale = networkGetObject(self.currentWrapper.currentBale);
                        if bale ~= nil and not bale.supportsWrapping then
                            g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE), true, nil, self);
                        else
                            g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPING_START), true, nil, self);
                        end
                    end
                elseif self.baleWrapperState == BaleWrapper.STATE_WRAPPER_DROPPING_BALE then
                    if not self:getIsAnimationPlaying(self.currentWrapper.animations["dropFromWrapper"].animName) then
                        g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED), true, nil, self);
                    end
                elseif self.baleWrapperState == BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
                    if not self:getIsAnimationPlaying(self.currentWrapper.animations["resetAfterDrop"].animName) then
                        g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPER_PLATFORM_RESET), true, nil, self);
                    end
                end
            end
        end
    end
end

function LTMaster:drawWrapper()
    if self.isClient then
        if self:getIsActiveForInput(true) then
            if self.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED then
                g_currentMission:addHelpButtonText(g_i18n:getText(self.currentWrapper.unloadBaleText), InputBinding.IMPLEMENT_EXTRA3, nil, GS_PRIO_HIGH);
            end
        end
        if self.showInvalidBaleWarning then
            g_currentMission:showBlinkingWarning(g_i18n:getText("warning_baleNotSupported"));
        end
    end
end

function LTMaster:getSaveAttributesAndNodesWrapper(nodeIdent)
    local attributes = "";
    local baleServerId = self.baleGrabber.currentBale;
    if baleServerId == nil then
        baleServerId = self.currentWrapper.currentBale;
    end
    if baleServerId ~= nil then
        local bale = networkGetObject(baleServerId);
        if bale ~= nil then
            local fillLevel = bale:getFillLevel();
            local baleValueScale = bale.baleValueScale;
            attributes = 'baleFileName="' .. Utils.encodeToHTML(Utils.convertToNetworkFilename(bale.i3dFilename)) .. '" fillLevel="' .. fillLevel .. '" wrapperTime="' .. tostring(self.currentWrapper.currentTime) .. '" baleValueScale="' .. baleValueScale .. '"';
        end
    end
    return attributes;
end

function LTMaster:onDeactivateWrapper()
    self.showInvalidBaleWarning = false;
end

function LTMaster:onDeactivateSoundsWrapper()
    if self.isClient then
        Sound3DUtil:stopSample(self.currentWrapperStartSound, true);
        Sound3DUtil:stopSample(self.currentWrapperStopSound, true);
        Sound3DUtil:stopSample(self.currentWrapperSound, true);
    end
end

function LTMaster:allowsGrabbingBale()
    local foldAnimTime = self.foldAnimTime;
    if foldAnimTime ~= nil and (foldAnimTime > self.currentWrapperFoldMaxLimit or foldAnimTime < self.currentWrapperFoldMinLimit) then
        return false;
    end
    return self.baleWrapperState == BaleWrapper.STATE_NONE;
end

function LTMaster:updateWrapNodes(isWrapping, isEmpty, t, wrapperRot)
    if wrapperRot == nil then
        wrapperRot = 0;
    end
    for _, wrapNode in pairs(self.currentWrapper.wrapNodes) do
        local doShow = true;
        if wrapNode.maxWrapperRot ~= nil then
            doShow = wrapperRot < wrapNode.maxWrapperRot;
        end
        setVisibility(wrapNode.nodeId, doShow and ((isWrapping and wrapNode.wrapVisibility) or (isEmpty and wrapNode.emptyVisibility)));
    end
    if isWrapping then
        local wrapperRotRepeat = Utils.sign(wrapperRot) * (wrapperRot % math.pi);
        if wrapperRotRepeat < 0 then
            wrapperRotRepeat = wrapperRotRepeat + math.pi;
        end
        for _, wrapAnimNode in pairs(self.currentWrapper.wrapAnimNodes) do
            local v;
            if wrapAnimNode.useWrapperRot then
                local rot = wrapperRot;
                if wrapAnimNode.repeatWrapperRot then
                    rot = wrapperRotRepeat;
                end
                v = wrapAnimNode.animCurve:get(rot);
            else
                v = wrapAnimNode.animCurve:get(t);
            end
            if v ~= nil then
                setTranslation(wrapAnimNode.nodeId, v[1], v[2], v[3]);
                setRotation(wrapAnimNode.nodeId, v[4], v[5], v[6]);
                setScale(wrapAnimNode.nodeId, v[7], v[8], v[9]);
            end
        end
    else
        if not isEmpty then
            for _, wrapAnimNode in pairs(self.currentWrapper.wrapAnimNodes) do
                if wrapAnimNode.normalizeRotationOnBaleDrop ~= 0 then
                    local rot = {getRotation(wrapAnimNode.nodeId)};
                    for i = 1, 3 do
                        rot[i] = wrapAnimNode.normalizeRotationOnBaleDrop * Utils.sign(rot[i]) * (rot[i] % (2 * math.pi));
                    end
                    setRotation(wrapAnimNode.nodeId, rot[1], rot[2], rot[3]);
                end
            end
        end
    end
end

function LTMaster:updateWrappingState(t, noEventSend)
    t = math.min(t, 1);
    local wrapperRot = 0;
    if self.currentWrapper.animCurve ~= nil then
        local v = self.currentWrapper.animCurve:get(t);
        if v ~= nil then
            setRotation(self.currentWrapper.baleNode, v[1] % (math.pi * 2), v[2] % (math.pi * 2), v[3] % (math.pi * 2));
            setRotation(self.currentWrapper.wrapperNode, v[4] % (math.pi * 2), v[5] % (math.pi * 2), v[6] % (math.pi * 2));
            wrapperRot = v[3 + self.currentWrapper.wrapperRotAxis];
        elseif self.currentWrapper.animations["wrapBale"].animName ~= nil then
            t = self:getAnimationTime(self.currentWrapper.animations["wrapBale"].animName);
        end
        if self.currentWrapper.currentBale ~= nil and self.isServer then
            local bale = networkGetObject(self.currentWrapper.currentBale);
            if bale ~= nil then
                bale:setWrappingState(t);
            end
        end
    end
    self:updateWrapNodes(t > 0, false, t, wrapperRot);
    if t == 1 then
        if self.isServer and self.baleWrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE and not noEventSend then
            g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED), true, nil, self);
        end
    end
end

function LTMaster:moveBaleToWrapper(bale)
    local baleType = self:getWrapperBaleType(bale);
    self:pickupWrapperBale(bale, baleType);
end

function LTMaster:playMoveToWrapper(bale)
    self.currentWrapper = self.roundBaleWrapper;
    if bale.baleDiameter == nil then
        self.currentWrapper = self.squareBaleWrapper;
    end
    if self.currentWrapper.animations["moveToWrapper"].animName ~= nil then
        self:playAnimation(self.currentWrapper.animations["moveToWrapper"].animName, self.currentWrapper.animations["moveToWrapper"].animSpeed, nil, true);
    end
end

function LTMaster:doStateChange(id, nearestBaleServerId)
    if id == BaleWrapper.CHANGE_GRAB_BALE then
        local bale = networkGetObject(nearestBaleServerId);
        self.baleGrabber.currentBale = nearestBaleServerId;
        if bale ~= nil then
            local x, y, z = localToLocal(bale.nodeId, getParent(self.baleGrabber.grabNode), 0, 0, 0);
            setTranslation(self.baleGrabber.grabNode, x, y, z);
            bale:mount(self, self.baleGrabber.grabNode, 0, 0, 0, 0, 0, 0);
            self.baleToMount = nil;
            self:playMoveToWrapper(bale)
        else
            self.baleToMount = {serverId = nearestBaleServerId, linkNode = self.baleGrabber.grabNode, trans = {0, 0, 0}, rot = {0, 0, 0}};
        end
        self.baleWrapperState = BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER;
    elseif id == BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER then
        local attachNode = self.currentWrapper.baleNode;
        local bale = networkGetObject(self.baleGrabber.currentBale);
        if bale ~= nil then
            bale:mount(self, attachNode, 0, 0, 0, 0, 0, 0);
            self.baleToMount = nil;
        else
            self.baleToMount = {serverId = self.baleGrabber.currentBale, linkNode = attachNode, trans = {0, 0, 0}, rot = {0, 0, 0}};
        end
        self:updateWrapNodes(true, false, 0);
        self.currentWrapper.currentBale = self.baleGrabber.currentBale;
        self.baleGrabber.currentBale = nil;
        if self.currentWrapper.animations["moveToWrapper"].animName ~= nil then
            if self.currentWrapper.animations["moveToWrapper"].reverseAfterMove then
                self:playAnimation(self.currentWrapper.animations["moveToWrapper"].animName, -self.currentWrapper.animations["moveToWrapper"].animSpeed, nil, true);
            end
        end
        self.baleWrapperState = BaleWrapper.STATE_MOVING_GRABBER_TO_WORK;
    elseif id == BaleWrapper.CHANGE_WRAPPING_START then
        self.baleWrapperState = BaleWrapper.STATE_WRAPPER_WRAPPING_BALE;
        if self.isClient and self:getIsActiveForSound() then
            Sound3DUtil:playSample(self.currentWrapperStartSound, 1, 0, nil, self:getIsActiveForSound());
        end
        if self.currentWrapper.animations["wrapBale"].animName ~= nil then
            self:playAnimation(self.currentWrapper.animations["wrapBale"].animName, self.currentWrapper.animations["wrapBale"].animSpeed, nil, true);
        end
    elseif id == BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED then
        if self.isClient then
            Sound3DUtil:stopSample(self.currentWrapperSound);
            if self.isClient then
                Sound3DUtil:playSample(self.currentWrapperStopSound, 1, 0, nil, self:getIsActiveForSound());
            end
        end
        self:updateWrappingState(1, true);
        self.baleWrapperState = BaleWrapper.STATE_WRAPPER_FINSIHED;
    elseif id == BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE then
        self:updateWrapNodes(false, false, 0);
        if self.currentWrapper.animations["dropFromWrapper"].animName ~= nil then
            self:playAnimation(self.currentWrapper.animations["dropFromWrapper"].animName, self.currentWrapper.animations["dropFromWrapper"].animSpeed, nil, true);
        end
        self.baleWrapperState = BaleWrapper.STATE_WRAPPER_DROPPING_BALE;
    elseif id == BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED then
        local bale = networkGetObject(self.currentWrapper.currentBale);
        if bale ~= nil then
            bale:unmount();
        end
        self.lastDroppedBale = bale;
        self.currentWrapper.currentBale = nil;
        self.currentWrapper.currentTime = 0;
        if self.currentWrapper.animations["resetAfterDrop"].animName ~= nil then
            self:playAnimation(self.currentWrapper.animations["resetAfterDrop"].animName, self.currentWrapper.animations["resetAfterDrop"].animSpeed, nil, true);
        end
        self.baleWrapperState = BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM;
    elseif id == BaleWrapper.CHANGE_WRAPPER_PLATFORM_RESET then
        self:updateWrappingState(0);
        self:updateWrapNodes(false, true, 0);
        self.baleWrapperState = BaleWrapper.STATE_NONE;
    elseif id == BaleWrapper.CHANGE_BUTTON_EMPTY then
        assert(self.isServer);
        if self.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED then
            g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE), true, nil, self);
        end
    end
end

function LTMaster:setIsUnloadingBale(isUnloadingBale, noEventSend)
    if self.baler ~= nil and self.baler.baleUnloadAnimationName ~= nil then
        if isUnloadingBale then
            if self.baleWrapperUnloadingState ~= BaleWrapper.UNLOADING_OPENING then
                BaleWrapperSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend);
                self.baleWrapperUnloadingState = BaleWrapper.UNLOADING_OPENING;
                self:playAnimation(self.baler.baleUnloadAnimationName, self.baler.baleUnloadAnimationSpeed, nil, true);
            end
        else
            if self.baleWrapperUnloadingState ~= BaleWrapper.UNLOADING_CLOSING then
                BaleWrapperSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend);
                self.baleWrapperUnloadingState = BaleWrapper.UNLOADING_CLOSING;
                self:playAnimation(self.baler.baleCloseAnimationName, self.baler.baleCloseAnimationSpeed, nil, true);
            end
        end
    end
end

function LTMaster:getWrapperBaleType(bale)
    local baleTypes;
    if bale.baleDiameter ~= nil then
        baleTypes = self.roundBaleWrapper.allowedBaleTypes[bale:getFillType()];
    else
        baleTypes = self.squareBaleWrapper.allowedBaleTypes[bale:getFillType()];
    end
    if baleTypes ~= nil then
        for _, baleType in pairs(baleTypes) do
            if bale.baleDiameter ~= nil and bale.baleWidth ~= nil then
                if bale.baleDiameter >= baleType.minBaleDiameter and bale.baleDiameter <= baleType.maxBaleDiameter and
                    bale.baleWidth >= baleType.minBaleWidth and bale.baleWidth <= baleType.maxBaleWidth
                then
                    return baleType;
                end
            elseif bale.baleHeight ~= nil and bale.baleWidth ~= nil and bale.baleLength ~= nil then
                if bale.baleHeight >= baleType.minBaleHeight and bale.baleHeight <= baleType.maxBaleHeight and
                    bale.baleWidth >= baleType.minBaleWidth and bale.baleWidth <= baleType.maxBaleWidth and
                    bale.baleLength >= baleType.minBaleLength and bale.baleLength <= baleType.maxBaleLength
                then
                    return baleType;
                end
            end
        end
    end
    return nil;
end

function LTMaster:pickupWrapperBale(bale, baleType)
    if baleType ~= nil and bale.i3dFilename ~= baleType.wrapperBaleFilename then
        local x, y, z = getWorldTranslation(bale.nodeId);
        local rx, ry, rz = getWorldRotation(bale.nodeId);
        local fillLevel = bale.fillLevel;
        local baleValueScale = bale.baleValueScale;
        bale:delete();
        bale = Bale:new(self.isServer, self.isClient);
        bale:load(baleType.wrapperBaleFilename, x, y, z, rx, ry, rz, fillLevel);
        bale.baleValueScale = baleValueScale;
        bale:register();
    end
    g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_GRAB_BALE, networkGetObjectId(bale)), true, nil, self);
end

function LTMaster.getBaleInRange(self, refNode, distance)
    local px, py, pz = getWorldTranslation(refNode);
    local nearestDistance = distance;
    local nearestBale = nil;
    local nearestBaleType;
    for _, item in pairs(g_currentMission.itemsToSave) do
        local bale = item.item;
        if bale:isa(Bale) then
            local vx, vy, vz = getWorldTranslation(bale.nodeId);
            local maxDist;
            if bale.baleDiameter ~= nil then
                maxDist = math.min(bale.baleDiameter, bale.baleWidth);
            else
                maxDist = math.min(bale.baleLength, bale.baleHeight, bale.baleWidth);
            end
            local _, _, z = localToLocal(bale.nodeId, refNode, 0, 0, 0);
            if math.abs(z) < nearestDistance and Utils.vector3Length(px - vx, py - vy, pz - vz) < maxDist then
                local foundBaleType;
                if not bale.supportsWrapping or bale.wrappingState < 0.99 then
                    foundBaleType = self:getWrapperBaleType(bale);
                end
                if foundBaleType ~= nil or nearestBaleType == nil then
                    if foundBaleType ~= nil then
                        nearestDistance = distance;
                    end
                    nearestBale = bale;
                    nearestBaleType = foundBaleType;
                end
            end
        end
    end
    return nearestBale, nearestBaleType;
end

function LTMaster:getIsFoldAllowed(superFunc, onAiTurnOn)
    if self.baleWrapperState ~= BaleWrapper.STATE_NONE then
        return false;
    end
    if superFunc ~= nil then
        return superFunc(self, onAiTurnOn);
    end
    return true;
end

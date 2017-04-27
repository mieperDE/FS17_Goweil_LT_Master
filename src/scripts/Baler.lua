--
--Baler
--
--@author  Stefan Geiger
--@date  10/09/08
--
--Copyright (C) GIANTS Software GmbH, Confidential, All Rights Reserved.
source("dataS/scripts/vehicles/specializations/events/SetTurnedOnEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerSetIsUnloadingBaleEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerSetBaleTimeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerCreateBaleEvent.lua")

---Class for all Balers
--@category Specializations
Baler = {}

Baler.UNLOADING_CLOSED = 1
Baler.UNLOADING_OPENING = 2
Baler.UNLOADING_OPEN = 3
Baler.UNLOADING_CLOSING = 4

---Called on specialization initializing
--@includeCode
function Baler.initSpecialization()
    WorkArea.registerAreaType("baler")
end

---Checks if all prerequisite specializations are loaded
--@param table specializations specializations
--@return boolean hasPrerequisite true if all prerequisite specializations are loaded
--@includeCode
function Baler.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Fillable, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations) and SpecializationUtil.hasSpecialization(Pickup, specializations)
end

---Called before loading
--@param table savegame savegame
--@includeCode
function Baler:preLoad(savegame)
    self.loadWorkAreaFromXML = Utils.overwrittenFunction(self.loadWorkAreaFromXML, Baler.loadWorkAreaFromXML)
    self.loadSpeedRotatingPartFromXML = Utils.overwrittenFunction(self.loadSpeedRotatingPartFromXML, Baler.loadSpeedRotatingPartFromXML)
end

---Called on loading
--@param table savegame savegame
--@includeCode
function Baler:load(savegame)
    
    Utils.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.fillScale#value", "vehicle.baler#fillScale")
    Utils.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleAnimation", "vehicle.baler.baleAnimation")
    Utils.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleAnimation", "vehicle.baler.baleAnimation")
    Utils.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.balerUVScrollParts.balerUVScrollPart", "vehicle.baler.uvScrollParts.uvScrollPart")
    Utils.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.knotingAnimation", "vehicle.baler.knotingAnimation")
    Utils.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.balingAnimation", "vehicle.baler.balingAnimation")
    Utils.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleUnloading#allowed", "vehicle.baler.baleUnloading#allowed")
    Utils.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleUnloading#time", "vehicle.baler.baleUnloading#time")
    Utils.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleUnloading#foldThreshold", "vehicle.baler.baleUnloading#foldThreshold")
    
    self.doCheckSpeedLimit = Utils.overwrittenFunction(self.doCheckSpeedLimit, Baler.doCheckSpeedLimit)
    self.getIsSpeedRotatingPartActive = Utils.overwrittenFunction(self.getIsSpeedRotatingPartActive, Baler.getIsSpeedRotatingPartActive)
    self.allowPickingUp = Utils.overwrittenFunction(self.allowPickingUp, Baler.allowPickingUp)
    self.getIsTurnedOnAllowed = Utils.overwrittenFunction(self.getIsTurnedOnAllowed, Baler.getIsTurnedOnAllowed)
    self.getIsFoldAllowed = Utils.overwrittenFunction(self.getIsFoldAllowed, Baler.getIsFoldAllowed)
    self.setUnitFillLevel = Utils.appendedFunction(self.setUnitFillLevel, Baler.setUnitFillLevel)
    self.isUnloadingAllowed = Baler.isUnloadingAllowed
    self.getTimeFromLevel = Baler.getTimeFromLevel
    self.moveBales = SpecializationUtil.callSpecializationsFunction("moveBales")
    self.moveBale = SpecializationUtil.callSpecializationsFunction("moveBale")
    self.allowFillType = Baler.allowFillType
    self.setIsUnloadingBale = Baler.setIsUnloadingBale
    self.dropBale = Baler.dropBale
    self.createBale = Baler.createBale
    self.setBaleTime = Baler.setBaleTime
    self.processBalerAreas = Baler.processBalerAreas
    
    self.baler = {}
    self.baler.fillScale = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.fillScale#value"), 1)
    self.baler.fillUnitIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.baler#fillUnitIndex"), 1)
    self.baler.unloadInfoIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.baler#unloadInfoIndex"), 1)
    self.baler.loadInfoIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.baler#loadInfoIndex"), 1)
    self.baler.dischargeInfoIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.baler#dischargeInfoIndex"), 1)
    
    local firstBaleMarker = getXMLFloat(self.xmlFile, "vehicle.baler.baleAnimation#firstBaleMarker")
    if firstBaleMarker ~= nil then
        local baleAnimCurve = AnimCurve:new(linearInterpolatorN)
        local keyI = 0
        while true do
            local key = string.format("vehicle.baler.baleAnimation.key(%d)", keyI)
            local t = getXMLFloat(self.xmlFile, key .. "#time")
            local x, y, z = Utils.getVectorFromString(getXMLString(self.xmlFile, key .. "#pos"))
            if x == nil or y == nil or z == nil then
                break
            end
            local rx, ry, rz = Utils.getVectorFromString(getXMLString(self.xmlFile, key .. "#rot"))
            rx = math.rad(Utils.getNoNil(rx, 0))
            ry = math.rad(Utils.getNoNil(ry, 0))
            rz = math.rad(Utils.getNoNil(rz, 0))
            baleAnimCurve:addKeyframe({v = {x, y, z, rx, ry, rz}, time = t})
            keyI = keyI + 1
        end
        if keyI > 0 then
            self.baler.baleAnimCurve = baleAnimCurve
            self.baler.firstBaleMarker = firstBaleMarker
        end
    end
    self.baler.baleAnimRoot, self.baler.baleAnimRootComponent = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.baler.baleAnimation#node"))
    if self.baler.baleAnimRoot == nil then
        self.baler.baleAnimRoot = self.components[1].node
        self.baler.baleAnimRootComponent = self.components[1].node
    end
    --there is no standard bale animation, load the unload animation (for round baler)
    if self.baler.firstBaleMarker == nil then
        local unloadAnimationName = getXMLString(self.xmlFile, "vehicle.baler.baleAnimation#unloadAnimationName")
        local closeAnimationName = getXMLString(self.xmlFile, "vehicle.baler.baleAnimation#closeAnimationName")
        local unloadAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baler.baleAnimation#unloadAnimationSpeed"), 1)
        local closeAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baler.baleAnimation#closeAnimationSpeed"), 1)
        if unloadAnimationName ~= nil and closeAnimationName ~= nil then
            if self.playAnimation ~= nil and self.animations ~= nil then
                if self.animations[unloadAnimationName] ~= nil and self.animations[closeAnimationName] ~= nil then
                    --print("has unload animation")
                    self.baler.baleUnloadAnimationName = unloadAnimationName
                    self.baler.baleUnloadAnimationSpeed = unloadAnimationSpeed
                    
                    self.baler.baleCloseAnimationName = closeAnimationName
                    self.baler.baleCloseAnimationSpeed = closeAnimationSpeed
                    
                    self.baler.baleDropAnimTime = getXMLFloat(self.xmlFile, "vehicle.baler.baleAnimation#baleDropAnimTime")
                    if self.baler.baleDropAnimTime == nil then
                        self.baler.baleDropAnimTime = self:getAnimationDuration(self.baler.baleUnloadAnimationName)
                    else
                        self.baler.baleDropAnimTime = self.baler.baleDropAnimTime * 1000
                    end
                else
                    print("Error: Failed to find unload animations '" .. unloadAnimationName .. "' and '" .. closeAnimationName .. "' in '" .. self.configFileName .. "'.")
                end
            else
                print("Error: There is an unload animation in '" .. self.configFileName .. "' but it is not a AnimatedVehicle. Change to a vehicle type which has the AnimatedVehicle specialization.")
            end
        end
    end
    
    self.baler.baleTypes = {}
    local i = 0
    while true do
        local key = string.format("vehicle.baler.baleTypes.baleType(%d)", i)
        if not hasXMLProperty(self.xmlFile, key) then
            break
        end
        local isRoundBale = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#isRoundBale"), false)
        local width = Utils.round(Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#width"), 1.2), 2)
        local height = Utils.round(Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#height"), 0.9), 2)
        local length = Utils.round(Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#length"), 2.4), 2)
        local diameter = Utils.round(Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#diameter"), 1.8), 2)
        table.insert(self.baler.baleTypes, {isRoundBale = isRoundBale, width = width, height = height, length = length, diameter = diameter})
        i = i + 1
    end
    self.baler.currentBaleTypeId = 1
    
    if table.getn(self.baler.baleTypes) == 0 then
        self.baler.baleTypes = nil
    end
    
    if self.isClient then
        self.baler.sampleBaler = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.baler.balerSound", nil, self.baseDirectory)
        self.baler.sampleBalerAlarm = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.baler.balerAlarm", nil, self.baseDirectory)
        self.baler.sampleBalerEject = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.baler.balerBaleEject", nil, self.baseDirectory)
        self.baler.sampleBalerDoor = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.baler.balerDoor", nil, self.baseDirectory)
        self.baler.sampleBalerKnotCleaning = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.baler.balerKnotCleaning", nil, self.baseDirectory)
        self.baler.knotCleaningTime = 10000
        
        self.baler.uvScrollParts = Utils.loadScrollers(self.components, self.xmlFile, "vehicle.baler.uvScrollParts.uvScrollPart", {}, false)
        self.baler.turnedOnRotationNodes = Utils.loadRotationNodes(self.xmlFile, {}, "vehicle.turnedOnRotationNodes.turnedOnRotationNode", "baler", self.components)
        
        self.baler.fillEffects = EffectManager:loadEffect(self.xmlFile, "vehicle.baler.fillEffect", self.components, self)
        
        self.baler.knotingAnimation = getXMLString(self.xmlFile, "vehicle.baler.knotingAnimation#name")
        self.baler.knotingAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.knotingAnimation#speed"), 1)
    end
    
    self.baler.balingAnimationName = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.baler.balingAnimation#name"), "")
    if self.playAnimation == nil or self.getIsAnimationPlaying == nil then
        self.baler.balingAnimationName = ""
    end
    
    self.baler.lastAreaBiggerZero = false
    self.baler.lastAreaBiggerZeroSent = false
    self.baler.lastAreaBiggerZeroTime = 0
    
    self.baler.unloadingState = Baler.UNLOADING_CLOSED
    self.baler.pickupFillTypes = {}
    
    self.baler.bales = {}
    self.baler.hasBaler = true
    
    self.baler.dummyBale = {}
    self.baler.dummyBale.scaleNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.baler.baleAnimation#scaleNode"))
    self.baler.dummyBale.baleNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.baler.baleAnimation#baleNode"))
    self.baler.dummyBale.currentBaleFillType = FillUtil.FILLTYPE_UNKNOWN
    self.baler.dummyBale.currentBale = nil
    
    self.baler.allowsBaleUnloading = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.baler.baleUnloading#allowed"), false)
    self.baler.baleUnloadingTime = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baler.baleUnloading#time"), 4) * 1000
    self.baler.baleFoldThreshold = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baler.baleUnloading#foldThreshold"), 0.25) * self:getCapacity()
    
    self.baler.isBaleUnloading = false
    self.baler.isSpeedLimitActive = false
    
    self.baler.dirtyFlag = self:getNextDirtyFlag()
end

---Called after loading
--@param table savegame savegame
--@includeCode
function Baler:postLoad(savegame)
    
    for fillType, enabled in pairs(self:getUnitFillTypes(self.baler.fillUnitIndex)) do
        if enabled and fillType ~= FillUtil.FILLTYPE_UNKNOWN then
            if FruitUtil.fillTypeIsWindrow[fillType] then
                table.insert(self.baler.pickupFillTypes, fillType)
            end
        end
    end
    
    if self.isClient then
        self.baler.fillParticleSystems = {}
        self.baler.currentFillParticleSystem = nil
        local i = 0
        while true do
            local key = string.format("vehicle.baler.fillParticleSystems.emitterShape(%d)", i)
            if not hasXMLProperty(self.xmlFile, key) then
                break
            end
            
            local emitterShape = Utils.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#node"))
            local particleType = getXMLString(self.xmlFile, key .. "#particleType")
            if emitterShape ~= nil then
                for _, fillType in pairs(self.baler.pickupFillTypes) do
                    local particleSystem = MaterialUtil.getParticleSystem(fillType, particleType)
                    if particleSystem ~= nil then
                        if self.baler.fillParticleSystems[fillType] == nil then
                            self.baler.fillParticleSystems[fillType] = {}
                        end
                        table.insert(self.baler.fillParticleSystems[fillType], ParticleUtil.copyParticleSystem(self.xmlFile, key, particleSystem, emitterShape))
                    end
                end
            end
            i = i + 1
        end
    end
    
    if savegame ~= nil and not savegame.resetVehicles then
        local numBales = getXMLInt(savegame.xmlFile, savegame.key .. "#numBales")
        if numBales ~= nil then
            self.baler.balesToLoad = {}
            for i = 1, numBales do
                local baleKey = savegame.key .. string.format(".bale(%d)", i - 1)
                local bale = {}
                local fillTypeStr = getXMLString(savegame.xmlFile, baleKey .. "#fillType")
                local fillType = FillUtil.fillTypeNameToInt[fillTypeStr]
                bale.fillType = fillType
                bale.fillLevel = getXMLFloat(savegame.xmlFile, baleKey .. "#fillLevel")
                bale.baleTime = getXMLFloat(savegame.xmlFile, baleKey .. "#baleTime")
                table.insert(self.baler.balesToLoad, bale)
            end
        end
    end
end

---Called on deleting
--@includeCode
function Baler:delete()
    for k, _ in pairs(self.baler.bales) do
        self:dropBale(k)
    end
    
    if self.baler.dummyBale.currentBale ~= nil then
        delete(self.baler.dummyBale.currentBale)
        self.baler.dummyBale.currentBale = nil
    end
    
    if self.isClient then
        SoundUtil.deleteSample(self.baler.sampleBaler)
        SoundUtil.deleteSample(self.baler.sampleBalerAlarm)
        SoundUtil.deleteSample(self.baler.sampleBalerDoor)
        SoundUtil.deleteSample(self.baler.sampleBalerEject)
        SoundUtil.deleteSample(self.baler.sampleBalerKnotCleaning)
        
        for _, v in pairs(self.baler.fillParticleSystems) do
            ParticleUtil.deleteParticleSystems(v)
        end
        
        EffectManager:deleteEffects(self.baler.fillEffects);
    end
end

---Called on client side on join
--@param integer streamId streamId
--@param integer connection connection
--@includeCode
function Baler:readStream(streamId, connection)
    if self.baler.baleUnloadAnimationName ~= nil then
        local state = streamReadUIntN(streamId, 7)
        local animTime = streamReadFloat32(streamId)
        if state == Baler.UNLOADING_CLOSED or state == Baler.UNLOADING_CLOSING then
            self:setIsUnloadingBale(false, true)
            self:setRealAnimationTime(self.baler.baleCloseAnimationName, animTime)
        elseif state == Baler.UNLOADING_OPEN or state == Baler.UNLOADING_OPENING then
            self:setIsUnloadingBale(true, true)
            self:setRealAnimationTime(self.baler.baleUnloadAnimationName, animTime)
        end
    end
    
    local numBales = streamReadUInt8(streamId)
    for i = 1, numBales do
        local fillType = streamReadInt8(streamId)
        local fillLevel = streamReadFloat32(streamId)
        self:createBale(fillType, fillLevel)
        if self.baler.baleAnimCurve ~= nil then
            local baleTime = streamReadFloat32(streamId)
            self:setBaleTime(i, baleTime)
        end
    end
    
    self.baler.lastAreaBiggerZero = streamReadBool(streamId)
end

---Called on server side on join
--@param integer streamId streamId
--@param integer connection connection
--@includeCode
function Baler:writeStream(streamId, connection)
    
    if self.baler.baleUnloadAnimationName ~= nil then
        streamWriteUIntN(streamId, self.baler.unloadingState, 7)
        local animTime = 0
        if self.baler.unloadingState == Baler.UNLOADING_CLOSED or self.baler.unloadingState == Baler.UNLOADING_CLOSING then
            animTime = self:getRealAnimationTime(self.baler.baleCloseAnimationName)
        elseif self.baler.unloadingState == Baler.UNLOADING_OPEN or self.baler.unloadingState == Baler.UNLOADING_OPENING then
            animTime = self:getRealAnimationTime(self.baler.baleUnloadAnimationName)
        end
        streamWriteFloat32(streamId, animTime)
    end
    
    streamWriteUInt8(streamId, table.getn(self.baler.bales))
    for i = 1, table.getn(self.baler.bales) do
        local bale = self.baler.bales[i]
        streamWriteInt8(streamId, bale.fillType)
        streamWriteFloat32(streamId, bale.fillLevel)
        if self.baler.baleAnimCurve ~= nil then
            streamWriteFloat32(streamId, bale.time)
        end
    end
    
    streamWriteBool(streamId, self.baler.lastAreaBiggerZero)
end

---Called on on update
--@param integer streamId stream ID
--@param integer timestamp timestamp
--@param table connection connection
--@includeCode
function Baler:readUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        self.baler.lastAreaBiggerZero = streamReadBool(streamId)
    end
end

---Called on on update
--@param integer streamId stream ID
--@param table connection connection
--@param integer dirtyMask dirty mask
--@includeCode
function Baler:writeUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        streamWriteBool(streamId, self.baler.lastAreaBiggerZero)
    end
end

---Returns attributes and nodes to save
--@param table nodeIdent node ident
--@return string attributes attributes
--@return string nodes nodes
--@includeCode
function Baler:getSaveAttributesAndNodes(nodeIdent)
    
    local attributes = 'numBales="' .. table.getn(self.baler.bales) .. '"'
    local nodes = ""
    local baleNum = 0
    
    for i = 1, table.getn(self.baler.bales) do
        local bale = self.baler.bales[i]
        local fillTypeStr = "unknown"
        if bale.fillType ~= FillUtil.FILLTYPE_UNKNOWN then
            fillTypeStr = FillUtil.fillTypeIntToName[bale.fillType]
        end
        
        if baleNum > 0 then
            nodes = nodes .. "\n"
        end
        nodes = nodes .. nodeIdent .. '<bale fillType="' .. fillTypeStr .. '" fillLevel="' .. bale.fillLevel .. '"'
        if self.baler.baleAnimCurve ~= nil then
            nodes = nodes .. ' baleTime="' .. bale.time .. '"'
        end
        nodes = nodes .. ' />'
        baleNum = baleNum + 1
    end
    return attributes, nodes
end

function Baler:mouseEvent(posX, posY, isDown, isUp, button)
end

function Baler:keyEvent(unicode, sym, modifier, isDown)
end

---Called on update
--@param float dt time since last call in ms
--@includeCode
function Baler:update(dt)
    
    if self.firstTimeRun and self.baler.balesToLoad ~= nil then
        if table.getn(self.baler.balesToLoad) > 0 then
            local v = self.baler.balesToLoad[1];
            
            if v.targetBaleTime == nil then
                self:createBale(v.fillType, v.fillLevel)
                self:setBaleTime(table.getn(self.baler.bales), 0, true);
                v.targetBaleTime = v.baleTime;
                v.baleTime = 0;
            else
                v.baleTime = math.min(v.baleTime + dt / 1000, v.targetBaleTime);
                self:setBaleTime(table.getn(self.baler.bales), v.baleTime, true);
                
                if v.baleTime == v.targetBaleTime then
                    
                    local index = table.getn(self.baler.balesToLoad);
                    if index == 1 then
                        self.baler.balesToLoad = nil;
                    else
                        table.remove(self.baler.balesToLoad, 1);
                    end;
                end;
            end;
        end;
    end
    
    if self:getIsActiveForInput() then
        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA3) then
            if self:isUnloadingAllowed() then
                if self.baler.baleUnloadAnimationName ~= nil or self.baler.allowsBaleUnloading then
                    if self.baler.unloadingState == Baler.UNLOADING_CLOSED then
                        if table.getn(self.baler.bales) > 0 then
                            self:setIsUnloadingBale(true)
                        end
                    elseif self.baler.unloadingState == Baler.UNLOADING_OPEN then
                        if self.baler.baleUnloadAnimationName ~= nil then
                            self:setIsUnloadingBale(false)
                        end
                    end
                end
            end
        end
    end
    
    if self.isClient then
        Utils.updateRotationNodes(self, self.baler.turnedOnRotationNodes, dt, self:getIsActive() and self:getIsTurnedOn())
        Utils.updateScrollers(self.baler.uvScrollParts, dt, self:getIsActive() and self:getIsTurnedOn())
    end
end

---Called on update tick
--@param float dt time since last call in ms
--@includeCode
function Baler:updateTick(dt)
    self.baler.isSpeedLimitActive = false
    
    if self.isServer then
        self.baler.lastAreaBiggerZero = false
    end
    
    if self:getIsActive() then
        if self:getIsTurnedOn() then
            if self:allowPickingUp() then
                if g_currentMission:getCanAddLimitedObject(FSBaseMission.LIMITED_OBJECT_TYPE_BALE) then
                    self.baler.isSpeedLimitActive = true
                    if self.isServer then
                        local workAreas, _, _ = self:getTypedNetworkAreas(WorkArea.AREATYPE_BALER, false)
                        local totalLiters = 0
                        local usedFillType = FillUtil.FILLTYPE_UNKNOWN
                        if table.getn(workAreas) > 0 then
                            totalLiters, usedFillType = self:processBalerAreas(workAreas, self.baler.pickupFillTypes)
                        end
                        
                        if totalLiters > 0 then
                            self.baler.lastAreaBiggerZero = true
                            if self.baler.lastAreaBiggerZero ~= self.baler.lastAreaBiggerZeroSent then
                                self:raiseDirtyFlags(self.baler.dirtyFlag)
                                self.baler.lastAreaBiggerZeroSent = self.baler.lastAreaBiggerZero
                            end
                            
                            local deltaLevel = totalLiters * self.baler.fillScale
                            
                            if self.baler.baleUnloadAnimationName == nil then
                                --move all bales
                                local deltaTime = self:getTimeFromLevel(deltaLevel)
                                self:moveBales(deltaTime)
                            end
                            
                            local oldFillLevel = self:getUnitFillLevel(self.baler.fillUnitIndex)
                            self:setUnitFillLevel(self.baler.fillUnitIndex, oldFillLevel + deltaLevel, usedFillType, true)
                            if self:getUnitFillLevel(self.baler.fillUnitIndex) >= self:getUnitCapacity(self.baler.fillUnitIndex) then
                                if self.baler.baleTypes ~= nil then
                                    --create bale
                                    if self.baler.baleAnimCurve ~= nil then
                                        local restDeltaFillLevel = deltaLevel - (self:getUnitFillLevel(self.baler.fillUnitIndex) - oldFillLevel)
                                        self:setUnitFillLevel(self.baler.fillUnitIndex, restDeltaFillLevel, usedFillType, true)
                                        
                                        self:createBale(usedFillType, self:getUnitCapacity(self.baler.fillUnitIndex))
                                        
                                        local numBales = table.getn(self.baler.bales)
                                        local bale = self.baler.bales[numBales]
                                        
                                        self:moveBale(numBales, self:getTimeFromLevel(restDeltaFillLevel), true)
                                        --note: self.baler.bales[numBales] can not be accessed anymore since the bale might be dropped already
                                        g_server:broadcastEvent(BalerCreateBaleEvent:new(self, usedFillType, bale.time), nil, nil, self)
                                    elseif self.baler.baleUnloadAnimationName ~= nil then
                                        
                                        self:createBale(usedFillType, self:getUnitCapacity(self.baler.fillUnitIndex))
                                        g_server:broadcastEvent(BalerCreateBaleEvent:new(self, usedFillType, 0), nil, nil, self)
                                    end
                                end
                            end
                        end
                    end
                else
                    g_currentMission:showBlinkingWarning(g_i18n:getText("warning_tooManyBales"), 500)
                end
            end
            
            
            if self.baler.lastAreaBiggerZero and self.fillUnits[self.baler.fillUnitIndex].lastValidFillType ~= FillUtil.FILLTYPE_UNKNOWN then
                self.baler.lastAreaBiggerZeroTime = 500
            else
                if self.baler.lastAreaBiggerZeroTime > 0 then
                    self.baler.lastAreaBiggerZeroTime = self.baler.lastAreaBiggerZeroTime - dt
                end
            end
            
            if self.isClient then
                if self.baler.fillEffects ~= nil then
                    if self.baler.lastAreaBiggerZeroTime > 0 then
                        EffectManager:setFillType(self.baler.fillEffects, self.fillUnits[self.baler.fillUnitIndex].lastValidFillType)
                        EffectManager:startEffects(self.baler.fillEffects)
                    else
                        EffectManager:stopEffects(self.baler.fillEffects)
                    end
                end
                
                local currentFillParticleSystem = self.baler.fillParticleSystems[self.fillUnits[self.baler.fillUnitIndex].lastValidFillType]
                if currentFillParticleSystem ~= self.baler.currentFillParticleSystem then
                    if self.baler.currentFillParticleSystem ~= nil then
                        for _, ps in pairs(self.baler.currentFillParticleSystem) do
                            ParticleUtil.setEmittingState(ps, false)
                        end
                        self.baler.currentFillParticleSystem = nil
                    end
                    self.baler.currentFillParticleSystem = currentFillParticleSystem
                end
                
                if self.baler.currentFillParticleSystem ~= nil then
                    for _, ps in pairs(self.baler.currentFillParticleSystem) do
                        ParticleUtil.setEmittingState(ps, self.baler.lastAreaBiggerZeroTime > 0)
                    end
                end
                
                if self:getIsActiveForSound() then
                    if self.baler.knotCleaningTime <= g_currentMission.time then
                        SoundUtil.playSample(self.baler.sampleBalerKnotCleaning, 1, 0, nil)
                        self.baler.knotCleaningTime = g_currentMission.time + 120000
                    end
                    SoundUtil.playSample(self.baler.sampleBaler, 0, 0, nil)
                end
            end
        else
            if self.baler.isBaleUnloading and self.isServer then
                local deltaTime = dt / self.baler.baleUnloadingTime
                self:moveBales(deltaTime)
            end
        end
        
        if self.isClient then
            if not self:getIsTurnedOn() then
                SoundUtil.stopSample(self.baler.sampleBalerKnotCleaning)
                SoundUtil.stopSample(self.baler.sampleBaler)
            end
            
            if self:getIsTurnedOn() and self:getUnitFillLevel(self.baler.fillUnitIndex) > (self:getUnitCapacity(self.baler.fillUnitIndex) * 0.68) and self:getUnitFillLevel(self.baler.fillUnitIndex) < self:getUnitCapacity(self.baler.fillUnitIndex) then
                --start alarm sound
                if self:getIsActiveForSound() then
                    SoundUtil.playSample(self.baler.sampleBalerAlarm, 0, 0, nil)
                end
            else
                SoundUtil.stopSample(self.baler.sampleBalerAlarm)
            end
            
            --delete dummy bale on client after physical bale is displayed
            if self.baler.unloadingState == Baler.UNLOADING_OPEN then
                if getNumOfChildren(self.baler.baleAnimRoot) > 0 then
                    delete(getChildAt(self.baler.baleAnimRoot, 0));
                end;
            end;
        end;
        
        if self.baler.unloadingState == Baler.UNLOADING_OPENING then
            local isPlaying = self:getIsAnimationPlaying(self.baler.baleUnloadAnimationName)
            local animTime = self:getRealAnimationTime(self.baler.baleUnloadAnimationName)
            if not isPlaying or animTime >= self.baler.baleDropAnimTime then
                if table.getn(self.baler.bales) > 0 then
                    self:dropBale(1)
                    if self.isServer then
                        self:setUnitFillLevel(self.baler.fillUnitIndex, 0, self:getUnitFillType(self.baler.fillUnitIndex), true)
                    end
                end
                if not isPlaying then
                    self.baler.unloadingState = Baler.UNLOADING_OPEN
                    
                    if self.isClient then
                        SoundUtil.stopSample(self.baler.sampleBalerEject)
                        SoundUtil.stopSample(self.baler.sampleBalerDoor)
                    end
                end
            end
        elseif self.baler.unloadingState == Baler.UNLOADING_CLOSING then
            if not self:getIsAnimationPlaying(self.baler.baleCloseAnimationName) then
                self.baler.unloadingState = Baler.UNLOADING_CLOSED
                if self.isClient then
                    SoundUtil.stopSample(self.baler.sampleBalerDoor)
                end
            end
        end
    end
end

---Called on draw
--@includeCode
function Baler:draw()
    if self.isClient then
        if self:getIsActiveForInput(true) then
            if self:isUnloadingAllowed() then
                if self.baler.baleUnloadAnimationName ~= nil or self.baler.allowsBaleUnloading then
                    if self.baler.unloadingState == Baler.UNLOADING_CLOSED then
                        if table.getn(self.baler.bales) > 0 then
                            g_currentMission:addHelpButtonText(g_i18n:getText("action_unloadBaler"), InputBinding.IMPLEMENT_EXTRA3, nil, GS_PRIO_HIGH)
                        end
                    elseif self.baler.unloadingState == Baler.UNLOADING_OPEN then
                        if self.baler.baleUnloadAnimationName ~= nil then
                            g_currentMission:addHelpButtonText(g_i18n:getText("action_closeBack"), InputBinding.IMPLEMENT_EXTRA3, nil, GS_PRIO_HIGH)
                        end
                    end
                end
            end
        end
    end
end

---Returns if fold is allowed
--@param boolean onAiTurnOn called on ai turn on
--@return boolean allowsFold allows folding
--@includeCode
function Baler:getIsFoldAllowed(superFunc, onAiTurnOn)
    if (table.getn(self.baler.bales) > 0 and self:getUnitFillLevel(self.baler.fillUnitIndex) > self.baler.baleFoldThreshold) or table.getn(self.baler.bales) > 1 or self:getIsTurnedOn() then
        return false
    end
    
    if superFunc ~= nil then
        return superFunc(self, onAiTurnOn)
    end
    
    return true
end

---Called on deactivate
--@includeCode
function Baler:onDeactivate()
    if self.baler.balingAnimationName ~= "" then
        self:stopAnimation(self.baler.balingAnimationName, true)
    end
    if self.isClient then
        if self.baler.fillEffects ~= nil then
            EffectManager:stopEffects(self.baler.fillEffects)
        end
        if self.baler.currentFillParticleSystem ~= nil then
            for _, ps in pairs(self.baler.currentFillParticleSystem) do
                ParticleUtil.setEmittingState(ps, false)
            end
        end
    end
end

---Called on deactivating sounds
--@includeCode
function Baler:onDeactivateSounds()
    if self.isClient then
        SoundUtil.stopSample(self.baler.sampleBaler, true)
        SoundUtil.stopSample(self.baler.sampleBalerAlarm, true)
        SoundUtil.stopSample(self.baler.sampleBalerDoor, true)
        SoundUtil.stopSample(self.baler.sampleBalerEject, true)
        SoundUtil.stopSample(self.baler.sampleBalerKnotCleaning, true)
    end
end

---Set unit fill level
--@param integer fillUnitIndex index of fill unit
--@param float fillLevel new fill level
--@param integer fillType fill type
--@param boolean force force action
--@param table fillInfo fill info for fill volume
--@includeCode
function Baler:setUnitFillLevel(fillUnitIndex, fillLevel, fillType, force, fillInfo)
    if fillUnitIndex == self.baler.fillUnitIndex then
        if self.baler.dummyBale.baleNode ~= nil and fillLevel > 0 and fillLevel < self:getUnitCapacity(fillUnitIndex) and (self.baler.dummyBale.currentBale == nil or self.baler.dummyBale.currentBaleFillType ~= fillType) then
            if self.baler.dummyBale.currentBale ~= nil then
                delete(self.baler.dummyBale.currentBale)
                self.baler.dummyBale.currentBale = nil
            end
            local t = self.baler.baleTypes[self.baler.currentBaleTypeId]
            
            local baleType = BaleUtil.getBale(fillType, t.width, t.height, t.length, t.diameter, t.isRoundBale)
            
            local baleRoot = Utils.loadSharedI3DFile(baleType.filename, self.baseDirectory, false, false)
            local baleId = getChildAt(baleRoot, 0)
            setRigidBodyType(baleId, "NoRigidBody")
            link(self.baler.dummyBale.baleNode, baleId)
            delete(baleRoot)
            self.baler.dummyBale.currentBale = baleId
            self.baler.dummyBale.currentBaleFillType = fillType
        end
        
        if self.baler.dummyBale.currentBale ~= nil then
            local percent = fillLevel / self:getUnitCapacity(fillUnitIndex)
            local y = 1
            if getUserAttribute(self.baler.dummyBale.currentBale, "isRoundbale") then
                y = percent
            end
            setScale(self.baler.dummyBale.scaleNode, 1, y, percent)
        end
    end
end

---Called on turn on
--@param boolean noEventSend no event send
--@includeCode
function Baler:onTurnedOn(noEventSend)
    if self.setFoldState ~= nil then
        self:setFoldState(-1)
    end
    if self.baler.balingAnimationName ~= "" then
        self:playAnimation(self.baler.balingAnimationName, 1, self:getAnimationTime(self.baler.balingAnimationName), true)
    end
end

---Called on turn off
--@param boolean noEventSend no event send
--@includeCode
function Baler:onTurnedOff(noEventSend)
    if self.baler.balingAnimationName ~= "" then
        self:stopAnimation(self.baler.balingAnimationName, true)
    end
    if self.isClient then
        if self.baler.fillEffects ~= nil then
            EffectManager:stopEffects(self.baler.fillEffects)
        end
        if self.baler.currentFillParticleSystem ~= nil then
            for _, ps in pairs(self.baler.currentFillParticleSystem) do
                ParticleUtil.setEmittingState(ps, false)
            end
        end
    end
end

---Returns if speed limit should be checked
--@return boolean checkSpeedlimit check speed limit
--@includeCode
function Baler:doCheckSpeedLimit(superFunc)
    local parent = false
    if superFunc ~= nil then
        parent = superFunc(self)
    end
    
    return parent or self.baler.isSpeedLimitActive
end

---Returns if unloading is allowed
--@return boolean isAllowed unloading is allowed
--@includeCode
function Baler:isUnloadingAllowed()
    if self.hasBaleWrapper == nil or not self.hasBaleWrapper then
        return not self.baler.allowsBaleUnloading or (self.baler.allowsBaleUnloading and not self:getIsTurnedOn() and not self.baler.isBaleUnloading)
    end
    
    return self:allowsGrabbingBale()
end

---Set bale unloading
--@param boolean isUnloadingBale is unloading bale
--@param boolean noEventSend no event send
--@includeCode
function Baler:setIsUnloadingBale(isUnloadingBale, noEventSend)
    if self.baler.baleUnloadAnimationName ~= nil then
        if isUnloadingBale then
            if self.baler.unloadingState ~= Baler.UNLOADING_OPENING then
                BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)
                self.baler.unloadingState = Baler.UNLOADING_OPENING
                if self.isClient and self:getIsActiveForSound() then
                    SoundUtil.playSample(self.baler.sampleBalerEject, 1, 0, nil)
                    SoundUtil.playSample(self.baler.sampleBalerDoor, 1, 0, nil)
                end
                self:playAnimation(self.baler.baleUnloadAnimationName, self.baler.baleUnloadAnimationSpeed, nil, true)
            end
        else
            if self.baler.unloadingState ~= Baler.UNLOADING_CLOSING then
                BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)
                self.baler.unloadingState = Baler.UNLOADING_CLOSING
                if self.isClient and self:getIsActiveForSound() then
                    SoundUtil.playSample(self.baler.sampleBalerDoor, 1, 0, nil)
                end
                self:playAnimation(self.baler.baleCloseAnimationName, self.baler.baleCloseAnimationSpeed, nil, true)
            end
        end
    elseif self.baler.allowsBaleUnloading then
        if isUnloadingBale then
            BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)
            self.baler.isBaleUnloading = true
        end
    end
end

---Returns time on animation depending on fill level
--@param float level current bale fill level
--@float float time animation time
--@includeCode
function Baler:getTimeFromLevel(level)
    --level = capacity -> time = firstBaleMarker
    --level = 0           -> time = 0
    if self.baler.firstBaleMarker ~= nil then
        return level / self:getCapacity() * self.baler.firstBaleMarker
    end
    return 0
end

---Move bales
--@param float dt time since last call in ms
--@includeCode
function Baler:moveBales(dt)
    for i = table.getn(self.baler.bales), 1, -1 do
        self:moveBale(i, dt)
    end
end

---Move bale
--@param integer i index of bale to move
--@param float dt time since last call in ms
--@param boolean noEventSend no event send
--@includeCode
function Baler:moveBale(i, dt, noEventSend)
    local bale = self.baler.bales[i]
    self:setBaleTime(i, bale.time + dt, noEventSend)
end

---Set bale animation time
--@param integer i index of bale to move
--@param float baleTime new bale time
--@param boolean noEventSend no event send
--@includeCode
function Baler:setBaleTime(i, baleTime, noEventSend)
    if self.baler.baleAnimCurve ~= nil then
        local bale = self.baler.bales[i]
        bale.time = baleTime
        if self.isServer then
            local v = self.baler.baleAnimCurve:get(bale.time)
            --setTranslation(bale.id, v[1], v[2], v[3])
            --setRotation(bale.id, v[4], v[5], v[6])
            setTranslation(bale.baleJointNode, v[1], v[2], v[3])
            setRotation(bale.baleJointNode, v[4], v[5], v[6])
            if bale.baleJointIndex ~= 0 then
                setJointFrame(bale.baleJointIndex, 0, bale.baleJointNode)
            end
        end
        if bale.time >= 1 then
            self:dropBale(i)
        end
        if table.getn(self.baler.bales) == 0 then
            self.baler.isBaleUnloading = false
        end
        if self.isServer then
            if noEventSend == nil or not noEventSend then
                g_server:broadcastEvent(BalerSetBaleTimeEvent:new(self, i, bale.time), nil, nil, self)
            end
        end
    end
end

---Returns if fill type is allowed
--@param integer fillType fill type
--@return boolean isAllowed fill type is allowed
--@includeCode
function Baler:allowFillType(fillType)
    return self.baler.pickupFillTypes[fillType] ~= nil
end

---Returns if picking up is allowed
--@return boolean isAllowed picking up is allowed
--@includeCode
function Baler:allowPickingUp(superFunc)
    if self.baler.baleUnloadAnimationName ~= nil then
        if table.getn(self.baler.bales) > 0 or self.baler.unloadingState ~= Baler.UNLOADING_CLOSED then
            return false
        end
    end
    
    if superFunc ~= nil then
        return superFunc(self)
    end
    return true
end

---Create new bale in baler
--@param integer baleFillType fill type of bale to create
--@param float fillLevel fill level of bale
--@includeCode
function Baler:createBale(baleFillType, fillLevel)
    
    if self.baler.knotingAnimation ~= nil then
        self:playAnimation(self.baler.knotingAnimation, self.baler.knotingAnimationSpeed, nil, true)
    end
    
    if self.baler.dummyBale.currentBale ~= nil then
        delete(self.baler.dummyBale.currentBale)
        self.baler.dummyBale.currentBale = nil
    end
    
    local t = self.baler.baleTypes[self.baler.currentBaleTypeId]
    local baleType = BaleUtil.getBale(baleFillType, t.width, t.height, t.length, t.diameter, t.isRoundBale)
    
    local bale = {}
    bale.filename = Utils.getFilename(baleType.filename, self.baseDirectory)
    bale.time = 0
    bale.fillType = baleFillType
    bale.fillLevel = fillLevel
    
    if self.baler.baleUnloadAnimationName ~= nil then
        local baleRoot = Utils.loadSharedI3DFile(baleType.filename, self.baseDirectory, false, false)
        local baleId = getChildAt(baleRoot, 0)
        link(self.baler.baleAnimRoot, baleId)
        delete(baleRoot)
        bale.id = baleId
    end
    
    if self.isServer and self.baler.baleUnloadAnimationName == nil then
        local x, y, z = getWorldTranslation(self.baler.baleAnimRoot)
        local rx, ry, rz = getWorldRotation(self.baler.baleAnimRoot)
        
        local baleObject = Bale:new(self.isServer, self.isClient)
        baleObject:load(bale.filename, x, y, z, rx, ry, rz, bale.fillLevel)
        baleObject:register()
        
        local baleJointNode = createTransformGroup("BaleJointTG")
        link(self.baler.baleAnimRoot, baleJointNode)
        setTranslation(baleJointNode, 0, 0, 0)
        setRotation(baleJointNode, 0, 0, 0)
        
        local constr = JointConstructor:new()
        constr:setActors(self.baler.baleAnimRootComponent, baleObject.nodeId)
        constr:setJointTransforms(baleJointNode, baleObject.nodeId)
        for i = 1, 3 do
            constr:setRotationLimit(i - 1, 0, 0)
            constr:setTranslationLimit(i - 1, true, 0, 0)
        end
        constr:setEnableCollision(false)
        local baleJointIndex = constr:finalize()
        
        g_currentMission:removeItemToSave(baleObject)
        
        bale.baleJointNode = baleJointNode
        bale.baleJointIndex = baleJointIndex
        bale.baleObject = baleObject
    end
    
    table.insert(self.baler.bales, bale)
end

---Drop bale
--@param integer baleIndex index of bale
--@includeCode
function Baler:dropBale(baleIndex)
    local bale = self.baler.bales[baleIndex]
    
    if self.isServer then
        local baleObject
        
        if bale.baleJointIndex ~= nil then
            baleObject = bale.baleObject
            removeJoint(bale.baleJointIndex)
            delete(bale.baleJointNode)
            g_currentMission:addItemToSave(bale.baleObject)
        else
            baleObject = Bale:new(self.isServer, self.isClient)
            local x, y, z = getWorldTranslation(bale.id)
            local rx, ry, rz = getWorldRotation(bale.id)
            baleObject:load(bale.filename, x, y, z, rx, ry, rz, bale.fillLevel)
            baleObject:register()
            delete(bale.id)
        end
        
        if (not self.hasBaleWrapper or self.moveBaleToWrapper == nil) and baleObject.nodeId ~= nil then
            --release bale if there's no bale wrapper
            local x, y, z = getWorldTranslation(baleObject.nodeId)
            local vx, vy, vz = getVelocityAtWorldPos(self.baler.baleAnimRootComponent, x, y, z)
            setLinearVelocity(baleObject.nodeId, vx, vy, vz)
        elseif self.moveBaleToWrapper ~= nil then
            --move bale to wrapper
            self:moveBaleToWrapper(baleObject)
        end
    end
    
    Utils.releaseSharedI3DFile(bale.filename, nil, true)
    table.remove(self.baler.bales, baleIndex)
    
    g_currentMission.missionStats:updateStats("baleCount", 1)
end

---Returns if turn on is allowed
--@param boolean isTurnedOn is turned on
--@return boolean allow allow turn on
--@includeCode
function Baler:getIsTurnedOnAllowed(superFunc, isTurnedOn)
    if isTurnedOn and self.baler.isBaleUnloading then
        return false
    end
    
    if superFunc ~= nil then
        return superFunc(self, isTurnedOn)
    end
    
    return true
end

---Loads work areas from xml
--@param table workArea workArea
--@param integer xmlFile id of xml object
--@param string key key
--@return boolean success success
--@includeCode
function Baler:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
    local retValue = true
    if superFunc ~= nil then
        retValue = superFunc(self, workArea, xmlFile, key)
    end
    
    if workArea.type == WorkArea.AREATYPE_DEFAULT then
        workArea.type = WorkArea.AREATYPE_BALER
    end
    
    return retValue
end

---Loads speed rotating parts from xml
--@param table speedRotatingPart speedRotatingPart
--@param integer xmlFile id of xml object
--@param string key key
--@return boolean success success
--@includeCode
function Baler:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
    if superFunc ~= nil then
        if not superFunc(self, speedRotatingPart, xmlFile, key) then
            return false
        end
    end
    
    speedRotatingPart.rotateOnlyIfFillLevelIncreased = Utils.getNoNil(getXMLBool(xmlFile, key .. "#rotateOnlyIfFillLevelIncreased"), false)
    
    return true
end

---Returns true if speed rotating part is active
--@param table speedRotatingPart speedRotatingPart
--@return boolean isActive speed rotating part is active
--@includeCode
function Baler:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
    if speedRotatingPart.rotateOnlyIfFillLevelIncreased ~= nil then
        if speedRotatingPart.rotateOnlyIfFillLevelIncreased and not self.baler.lastAreaBiggerZero then
            return false
        end
    end
    
    if superFunc ~= nil then
        return superFunc(self, speedRotatingPart)
    end
    return true
end

---Returns default speed limit
--@return float speedLimit speed limit
--@includeCode
function Baler.getDefaultSpeedLimit()
    return 25
end

---Process baler areas
--@param table workAreas work areas to process
--@param table fillTypes fill types
--@return float totalLiters total liters picked up
--@return integer usedFillType fill type picked up
--@includeCode
function Baler:processBalerAreas(workAreas, fillTypes)
    
    local totalLiters = 0
    local usedFillType = FillUtil.FILLTYPE_UNKNOWN
    
    local numAreas = table.getn(workAreas)
    for i = 1, numAreas do
        local x0 = workAreas[i][1]
        local z0 = workAreas[i][2]
        local x1 = workAreas[i][3]
        local z1 = workAreas[i][4]
        local x2 = workAreas[i][5]
        local z2 = workAreas[i][6]
        
        local hx = x2 - x0
        local hz = z2 - z0
        local hLength = Utils.vector2Length(hx, hz)
        local hLength_2 = 0.5 * hLength
        
        local wx = x1 - x0
        local wz = z1 - z0
        local wLength = Utils.vector2Length(wx, wz)
        
        local sx = x0 + (hx * 0.5) + ((wx / wLength) * hLength_2)
        local sz = z0 + (hz * 0.5) + ((wz / wLength) * hLength_2)
        
        local ex = x1 + (hx * 0.5) - ((wx / wLength) * hLength_2)
        local ez = z1 + (hz * 0.5) - ((wz / wLength) * hLength_2)
        
        local sy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, sx, 0, sz)
        local ey = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, ex, 0, ez)
        
        
        if usedFillType == FillUtil.FILLTYPE_UNKNOWN then
            for _, fillType in pairs(fillTypes) do
                local liters = -TipUtil.tipToGroundAroundLine(self, -math.huge, fillType, sx, sy, sz, ex, ey, ez, hLength_2, nil, nil, false, nil)
                if liters > 0 then
                    usedFillType = fillType
                    totalLiters = totalLiters + liters
                    break
                end
            end
        else
            totalLiters = totalLiters - TipUtil.tipToGroundAroundLine(self, -math.huge, usedFillType, sx, sy, sz, ex, ey, ez, hLength_2, nil, nil, false, nil)
        end
    
    end
    
    return totalLiters, usedFillType
end

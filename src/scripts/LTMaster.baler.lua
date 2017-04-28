--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--28/04/2017
LTMaster.BALER_UNLOADING_CLOSED = 1;
LTMaster.BALER_UNLOADING_OPENING = 2;
LTMaster.BALER_UNLOADING_OPEN = 3;
LTMaster.BALER_UNLOADING_CLOSING = 4;
function LTMaster:loadBaler()
    self.LTMaster.baler = {};
    self.LTMaster.baler.fillScale = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.baler#value"), 1);
    self.LTMaster.baler.fillUnitIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.baler#fillUnitIndex"), 1);
    --self.LTMaster.baler.unloadInfoIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.baler#unloadInfoIndex"), 1);
    --self.LTMaster.baler.loadInfoIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.baler#loadInfoIndex"), 1);
    --self.LTMaster.baler.dischargeInfoIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.LTMaster.baler#dischargeInfoIndex"), 1);
    self.LTMaster.baler.baleAnimRoot, self.LTMaster.baler.baleAnimRootComponent = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#node"));
    if self.LTMaster.baler.baleAnimRoot == nil then
        self.LTMaster.baler.baleAnimRoot = self.components[1].node;
        self.LTMaster.baler.baleAnimRootComponent = self.components[1].node;
    end
    local unloadAnimationName = getXMLString(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#unloadAnimationName");
    local closeAnimationName = getXMLString(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#closeAnimationName");
    local unloadAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#unloadAnimationSpeed"), 1);
    local closeAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#closeAnimationSpeed"), 1);
    if unloadAnimationName ~= nil and closeAnimationName ~= nil then
        if self.playAnimation ~= nil and self.animations ~= nil then
            if self.animations[unloadAnimationName] ~= nil and self.animations[closeAnimationName] ~= nil then
                self.LTMaster.baler.baleUnloadAnimationName = unloadAnimationName;
                self.LTMaster.baler.baleUnloadAnimationSpeed = unloadAnimationSpeed;
                
                self.LTMaster.baler.baleCloseAnimationName = closeAnimationName;
                self.LTMaster.baler.baleCloseAnimationSpeed = closeAnimationSpeed;
                
                self.LTMaster.baler.baleDropAnimTime = getXMLFloat(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#baleDropAnimTime");
                if self.LTMaster.baler.baleDropAnimTime == nil then
                    self.LTMaster.baler.baleDropAnimTime = self:getAnimationDuration(self.LTMaster.baler.baleUnloadAnimationName);
                else
                    self.LTMaster.baler.baleDropAnimTime = self.LTMaster.baler.baleDropAnimTime * 1000;
                end
            else
                print("Error: Failed to find unload animations '" .. unloadAnimationName .. "' and '" .. closeAnimationName .. "' in '" .. self.configFileName .. "'.");
            end
        else
            print("Error: There is an unload animation in '" .. self.configFileName .. "' but it is not a AnimatedVehicle. Change to a vehicle type which has the AnimatedVehicle specialization.");
        end
    end
    self.LTMaster.baler.baleTypes = {};
    local i = 0
    while true do
        local key = string.format("vehicle.LTMaster.baler.baleTypes.baleType(%d)", i);
        if not hasXMLProperty(self.xmlFile, key) then
            break;
        end
        local width = Utils.round(Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#width"), 1.2), 2);
        local diameter = Utils.round(Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#diameter"), 1.8), 2);
        table.insert(self.LTMaster.baler.baleTypes, {isRoundBale = true, width = width, height = 0.9, length = 2.4, diameter = diameter});
        i = i + 1;
    end
    self.LTMaster.baler.currentBaleTypeId = 1;
    if table.getn(self.LTMaster.baler.baleTypes) == 0 then
        self.LTMaster.baler.baleTypes = nil;
    end
    if self.isClient then
        self.LTMaster.baler.sampleBaler = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.baler.balerSound", nil, self.baseDirectory);
        self.LTMaster.baler.sampleBalerEject = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.baler.balerBaleEject", nil, self.baseDirectory);
        self.LTMaster.baler.sampleBalerDoor = SoundUtil.loadSample(self.xmlFile, {}, "vehicle.LTMaster.baler.balerDoor", nil, self.baseDirectory);
        self.LTMaster.baler.uvScrollParts = Utils.loadScrollers(self.components, self.xmlFile, "vehicle.LTMaster.baler.uvScrollParts.uvScrollPart", {}, false);
        self.LTMaster.baler.turnedOnRotationNodes = Utils.loadRotationNodes(self.xmlFile, {}, "vehicle.LTMaster.baler.rotatingParts.rotatingPart", "LTMaster.baler", self.components);
        self.LTMaster.baler.knotingAnimation = getXMLString(self.xmlFile, "vehicle.LTMaster.baler.knotingAnimation#name");
        self.LTMaster.baler.knotingAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.LTMaster.baler.knotingAnimation#speed"), 1);
    end
    self.LTMaster.baler.unloadingState = LTMaster.BALER_UNLOADING_CLOSED;
    self.LTMaster.baler.bales = {};
    self.LTMaster.baler.hasBaler = true;
    self.LTMaster.baler.dummyBale = {}
    self.LTMaster.baler.dummyBale.scaleNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#scaleNode"));
    self.LTMaster.baler.dummyBale.baleNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.LTMaster.baler.baleAnimation#baleNode"));
    self.LTMaster.baler.dummyBale.currentBaleFillType = FillUtil.FILLTYPE_UNKNOWN;
    self.LTMaster.baler.dummyBale.currentBale = nil;
    self.LTMaster.baler.dirtyFlag = self:getNextDirtyFlag();
end

function LTMaster:postLoadBaler(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        local numBales = getXMLInt(savegame.xmlFile, savegame.key .. "#numBales");
        if numBales ~= nil then
            self.LTMaster.baler.balesToLoad = {};
            for i = 1, numBales do
                local baleKey = savegame.key .. string.format(".bale(%d)", i - 1);
                local bale = {};
                local fillTypeStr = getXMLString(savegame.xmlFile, baleKey .. "#fillType");
                local fillType = FillUtil.fillTypeNameToInt[fillTypeStr];
                bale.fillType = fillType;
                bale.fillLevel = getXMLFloat(savegame.xmlFile, baleKey .. "#fillLevel");
                bale.baleTime = getXMLFloat(savegame.xmlFile, baleKey .. "#baleTime");
                table.insert(self.LTMaster.baler.balesToLoad, bale);
            end
        end
    end
end

function LTMaster:deleteBaler()
    for k, _ in pairs(self.LTMaster.baler.bales) do
        self:dropBale(k);
    end
    if self.LTMaster.baler.dummyBale.currentBale ~= nil then
        delete(self.LTMaster.baler.dummyBale.currentBale);
        self.LTMaster.baler.dummyBale.currentBale = nil;
    end
    if self.isClient then
        SoundUtil.deleteSample(self.LTMaster.baler.sampleBaler);
        SoundUtil.deleteSample(self.LTMaster.baler.sampleBalerDoor);
        SoundUtil.deleteSample(self.LTMaster.baler.sampleBalerEject);
    end
end

function LTMaster:getSaveAttributesAndNodesBaler(nodeIdent)
    local attributes = 'numBales="' .. table.getn(self.LTMaster.baler.bales) .. '"';
    local nodes = "";
    local baleNum = 0;
    for i = 1, table.getn(self.LTMaster.baler.bales) do
        local bale = self.LTMaster.baler.bales[i];
        local fillTypeStr = "unknown";
        if bale.fillType ~= FillUtil.FILLTYPE_UNKNOWN then
            fillTypeStr = FillUtil.fillTypeIntToName[bale.fillType];
        end
        if baleNum > 0 then
            nodes = nodes .. "\n";
        end
        nodes = nodes .. nodeIdent .. '<bale fillType="' .. fillTypeStr .. '" fillLevel="' .. bale.fillLevel .. '"';
        nodes = nodes .. ' />';
        baleNum = baleNum + 1;
    end
    return attributes, nodes;
end

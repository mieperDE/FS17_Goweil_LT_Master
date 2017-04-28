--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--28/04/2017
LTMasterBalerCreateBaleEvent = {};

LTMasterBalerCreateBaleEvent_mt = Class(LTMasterBalerCreateBaleEvent, Event);
InitEventClass(LTMasterBalerCreateBaleEvent, "LTMasterBalerCreateBaleEvent");

function LTMasterBalerCreateBaleEvent:emptyNew()
    local self = Event:new(LTMasterBalerCreateBaleEvent_mt);
    return self;
end

function LTMasterBalerCreateBaleEvent:new(object, baleFillType)
    local self = LTMasterBalerCreateBaleEvent:emptyNew()
    self.baleFillType = baleFillType;
    self.object = object;
    return self;
end

function LTMasterBalerCreateBaleEvent:readStream(streamId, connection)
    self.object = readNetworkNodeObject(streamId);
    self.baleFillType = streamReadUIntN(streamId, FillUtil.sendNumBits);
    self:run(connection);
end

function LTMasterBalerCreateBaleEvent:writeStream(streamId, connection)
    writeNetworkNodeObject(streamId, self.object);
    streamWriteUIntN(streamId, self.baleFillType, FillUtil.sendNumBits);
end

function LTMasterBalerCreateBaleEvent:run(connection)
    self.object:createBale(self.baleFillType);
end

--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--19/04/2017
SupportsStatusEvent = {};
SupportsStatusEvent_mt = Class(SupportsStatusEvent, Event);
InitEventClass(SupportsStatusEvent, "SupportsStatusEvent");

function SupportsStatusEvent:emptyNew()
    local self = Event:new(SupportsStatusEvent_mt);
    return self;
end

function SupportsStatusEvent:new(status, vehicle)
    local self = SupportsStatusEvent:emptyNew();
    self.status = status;
    self.vehicle = vehicle;
    return self;
end

function SupportsStatusEvent:writeStream(streamId, connection)
    streamWriteUInt8(streamId, self.status);
    writeNetworkNodeObject(streamId, self.vehicle);
end

function SupportsStatusEvent:readStream(streamId, connection)
    self.status = streamReadUInt8(streamId);
    self.vehicle = readNetworkNodeObject(streamId);
    self:run(connection);
end

function SupportsStatusEvent:run(connection)
    self.vehicle.LTMaster.supports.status = self.status;
end

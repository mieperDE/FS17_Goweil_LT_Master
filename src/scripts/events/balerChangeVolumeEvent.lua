--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--03/05/2017
BalerChangeVolumeEvent = {};
BalerChangeVolumeEvent_mt = Class(BalerChangeVolumeEvent, Event);
InitEventClass(BalerChangeVolumeEvent, "BalerChangeVolumeEvent");

function BalerChangeVolumeEvent:emptyNew()
    local self = Event:new(BalerChangeVolumeEvent_mt);
    return self;
end

function BalerChangeVolumeEvent:new(volumeIndex, vehicle)
    local self = BalerChangeVolumeEvent:emptyNew();
    self.volumeIndex = volumeIndex;
    self.vehicle = vehicle;
    return self;
end

function BalerChangeVolumeEvent:writeStream(streamId, connection)
    streamWriteUInt8(streamId, self.volumeIndex);
    writeNetworkNodeObject(streamId, self.vehicle);
end

function BalerChangeVolumeEvent:readStream(streamId, connection)
    self.volumeIndex = streamReadUInt8(streamId);
    self.vehicle = readNetworkNodeObject(streamId);
    self:run(connection);
end

function BalerChangeVolumeEvent:run(connection)
    self.vehicle:setBaleVolume(self.volumeIndex);
end

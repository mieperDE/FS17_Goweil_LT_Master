--
-- Goweil LT Master
--
-- Team FSI Modding
--
-- 26/04/2017
SideUnloadEvent = {};
SideUnloadEvent_mt = Class(SideUnloadEvent, Event);
InitEventClass(SideUnloadEvent, "SideUnloadEvent");

function SideUnloadEvent:emptyNew()
    local self = Event:new(SideUnloadEvent_mt);
    return self;
end

function SideUnloadEvent:new(vehicle)
    local self = SideUnloadEvent:emptyNew();
    self.vehicle = vehicle;
    return self;
end

function SideUnloadEvent:writeStream(streamId, connection)
    writeNetworkNodeObject(streamId, self.vehicle);
end

function SideUnloadEvent:readStream(streamId, connection)
    self.vehicle = readNetworkNodeObject(streamId);
    self:run(connection);
end

function SideUnloadEvent:run(connection)
    self.vehicle:unloadSide();
end

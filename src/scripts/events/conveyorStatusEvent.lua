--
-- Goweil LT Master
--
-- Team FSI Modding
--
-- 26/04/2017
ConveyorStatusEvent = {};
ConveyorStatusEvent_mt = Class(ConveyorStatusEvent, Event);
InitEventClass(ConveyorStatusEvent, "ConveyorStatusEvent");

function ConveyorStatusEvent:emptyNew()
    local self = Event:new(ConveyorStatusEvent_mt);
    return self;
end

function ConveyorStatusEvent:new(vehicle)
    local self = ConveyorStatusEvent:emptyNew();
    self.vehicle = vehicle;
    return self;
end

function ConveyorStatusEvent:writeStream(streamId, connection)
    writeNetworkNodeObject(streamId, self.vehicle);
end

function ConveyorStatusEvent:readStream(streamId, connection)
    self.vehicle = readNetworkNodeObject(streamId);
    self:run(connection);
end

function ConveyorStatusEvent:run(connection)
    self.vehicle:setConveyorStatus(not self.vehicle.LTMaster.conveyor.isTurnedOn);
end

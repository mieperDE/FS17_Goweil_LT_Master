--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--06/05/2017
WrapperChangeStatus = {};
WrapperChangeStatus_mt = Class(WrapperChangeStatus, Event);
InitEventClass(WrapperChangeStatus, "WrapperChangeStatus");

function WrapperChangeStatus:emptyNew()
    local self = Event:new(WrapperChangeStatus_mt);
    return self;
end

function WrapperChangeStatus:new(status, vehicle)
    local self = WrapperChangeStatus:emptyNew();
    self.status = status;
    self.vehicle = vehicle;
    return self;
end

function WrapperChangeStatus:writeStream(streamId, connection)
    streamWriteBool(streamId, self.status);
    writeNetworkNodeObject(streamId, self.vehicle);
end

function WrapperChangeStatus:readStream(streamId, connection)
    self.status = streamReadBool(streamId);
    self.vehicle = readNetworkNodeObject(streamId);
    self:run(connection);
end

function WrapperChangeStatus:run(connection)
    self.vehicle.LTMaster.wrapper.wrapperEnabled = self.status;
end

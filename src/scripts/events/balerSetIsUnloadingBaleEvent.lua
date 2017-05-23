--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--23/04/2017
LTMBalerSetIsUnloadingBaleEvent = {};
BalerSetIsUnloadingBaleEvent_mt = Class(LTMBalerSetIsUnloadingBaleEvent, Event);
InitEventClass(LTMBalerSetIsUnloadingBaleEvent, "LTMBalerSetIsUnloadingBaleEvent");

function LTMBalerSetIsUnloadingBaleEvent:emptyNew()
    local self = Event:new(BalerSetIsUnloadingBaleEvent_mt);
    return self;
end

function LTMBalerSetIsUnloadingBaleEvent:new(object, isUnloadingBale)
    local self = LTMBalerSetIsUnloadingBaleEvent:emptyNew()
    self.object = object;
    self.isUnloadingBale = isUnloadingBale;
    return self;
end

function LTMBalerSetIsUnloadingBaleEvent:readStream(streamId, connection)
    self.object = readNetworkNodeObject(streamId);
    self.isUnloadingBale = streamReadBool(streamId);
    self:run(connection);
end

function LTMBalerSetIsUnloadingBaleEvent:writeStream(streamId, connection)
    writeNetworkNodeObject(streamId, self.object);
    streamWriteBool(streamId, self.isUnloadingBale);
end

function LTMBalerSetIsUnloadingBaleEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object);
    end
    self.object:setIsBalerUnloadingBale(self.isUnloadingBale, true);
end

function LTMBalerSetIsUnloadingBaleEvent.sendEvent(object, isUnloadingBale, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(LTMBalerSetIsUnloadingBaleEvent:new(object, isUnloadingBale), nil, nil, object);
        else
            g_client:getServerConnection():sendEvent(LTMBalerSetIsUnloadingBaleEvent:new(object, isUnloadingBale));
        end
    end
end

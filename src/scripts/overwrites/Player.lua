--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--24/05/2017
PlayerOverwrite = {};
function PlayerOverwrite:update(dt)
    if self.isServer and (self.isEntered or self.isControlled) then
        self.lastFoundBale = nil;
        if self.isObjectInRange then
            local object = g_currentMission:getNodeObject(self.lastFoundObject);
            if object ~= nil and object:isa(Bale) then
                self.lastFoundBale = object;
            end
        end
    end
end
Player.update = Utils.appendedFunction(Player.update, PlayerOverwrite.update);

function PlayerOverwrite:writeUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        writeNetworkNodeObject(streamId, self.lastFoundBale);
    end
end
Player.writeUpdateStream = Utils.appendedFunction(Player.writeUpdateStream, PlayerOverwrite.writeUpdateStream);

function PlayerOverwrite:readUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        self.lastFoundBale = readNetworkNodeObject(streamId);
    end
end
Player.readUpdateStream = Utils.appendedFunction(Player.readUpdateStream, PlayerOverwrite.readUpdateStream);

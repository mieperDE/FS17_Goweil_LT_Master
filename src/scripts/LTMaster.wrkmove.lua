--
--Goweil LT Master
--
--fcelsa (Team FSI Modding)
--
--08/05/2017
function LTMaster:loadWrkMove()
    self.LTMaster.wrkMove = {};
    self.LTMaster.wrkMove.conditions = {};
    self.LTMaster.wrkMove.conditions["noCondition"] = true;
    self.LTMaster.wrkMove.conditions["turnedOn"] = false;
    self.LTMaster.wrkMove.conditions["isBaling"] = false;
    self.LTMaster.wrkMove.conditions["isWrapping"] = false;
    self.LTMaster.wrkMove.conditions["isMoving"] = false;
    
    self.LTMaster.gauge = {}
    local i = 0;
    while true do
        local gaugeKey = string.format("vehicle.LTMaster.gauge.part(%d)", i);
        if not hasXMLProperty(self.xmlFile, gaugeKey) then
            break;
        end;
        local part = {}
        part.index = Utils.indexToObject(self.components, getXMLString(self.xmlFile, gaugeKey .. "#index"));
        part.speed = Utils.getNoNil(getXMLFloat(self.xmlFile, gaugeKey .. "#speed"), 1) * 1000;
        part.axis = Utils.getNoNil(getXMLString(self.xmlFile, gaugeKey .. "#axis"), "x");
        part.startRot = math.rad(getXMLFloat(self.xmlFile, gaugeKey .. "#startRot"));
        part.endRot = math.rad(getXMLFloat(self.xmlFile, gaugeKey .. "#endRot"));
        part.delta = math.abs(part.endRot - part.startRot);
        part.condition = Utils.getNoNil(getXMLString(self.xmlFile, gaugeKey .. "#condition"), "noCondition");
        table.insert(self.LTMaster.gauge, part);
        i = i + 1;
    end
end

function LTMaster:postLoadWrkMove(savegame)

end

function LTMaster:deleteWrkMove()

end

function LTMaster:updateWrkMove(dt)
    if self:getIsTurnedOn() then
        self.LTMaster.wrkMove.conditions["turnedOn"] = true;
    else
        self.LTMaster.wrkMove.conditions["turnedOn"] = false;
    end
    if self:getIsActive() then
        for i, part in pairs(self.LTMaster.gauge) do
            local x, y, z = getRotation(part.index);
            local xyz = LTMaster.getRotationaxis(x, y, z, part.axis);
            local factor = dt / part.speed;
            local delta = part.delta * factor;
            if self.LTMaster.wrkMove.conditions[part.condition] then
                if xyz > part.endRot then
                    xyz = xyz - delta;
                end
            else
                if xyz < part.startRot then
                    xyz = xyz + delta;
                end
            end
            x, y, z = LTMaster.setRotationaxis(x, y, z, xyz, part.axis);
            setRotation(part.index, x, y, z);
        end
    end
end

function LTMaster:updateTickWrkMove(dt, normalizedDt)

end

function LTMaster:drawWrkMove()

end

function LTMaster:onDeactivateWrkMove()

end

function LTMaster:onTurnedOn(noEventSend)

end

function LTMaster:onTurnedOff(noEventSend)

end

function LTMaster.getRotationaxis(x, y, z, axis)
    if axis == "x" then
        return x;
    elseif axis == "y" then
        return y;
    else
        return z;
    end
end

function LTMaster.setRotationaxis(x, y, z, xyz, axis)
    if axis == "x" then
        x = xyz;
    elseif axis == "y" then
        y = xyz;
    else
        z = xyz;
    end
    return x, y, z;
end

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
    self.LTMaster.wrkMove.conditions["isKnotting"] = false;
    self.LTMaster.wrkMove.conditions["baleDoorOpening"] = false;
    self.LTMaster.wrkMove.conditions["baleDoorClosing"] = false;
    self.LTMaster.wrkMove.conditions["conveyorOn"] = false;
    self.LTMaster.wrkMove.conditions["wrapperEnabled"] = false;
    
    self.LTMaster.gauge = {}
    local i = 0;
    while true do
        local gaugeKey = string.format("vehicle.LTMaster.gauge.part(%d)", i);
        if not hasXMLProperty(self.xmlFile, gaugeKey) then
            break;
        end;
        local part = {}
        part.index = Utils.indexToObject(self.components, getXMLString(self.xmlFile, gaugeKey .. "#index"));
        part.fade = Utils.getNoNil(getXMLFloat(self.xmlFile, gaugeKey .. "#fade"), 1);
        part.fadeIn = Utils.getNoNil(getXMLFloat(self.xmlFile, gaugeKey .. "#fadeIn"), part.fade) * 1000;
        part.fadeOut = Utils.getNoNil(getXMLFloat(self.xmlFile, gaugeKey .. "#fadeOut"), part.fade) * 1000;
        part.axis = Utils.getNoNil(getXMLString(self.xmlFile, gaugeKey .. "#axis"), "x");
        part.startRot = math.rad(getXMLFloat(self.xmlFile, gaugeKey .. "#startRot"));
        part.endRot = math.rad(getXMLFloat(self.xmlFile, gaugeKey .. "#endRot"));
        part.delta = math.abs(part.endRot - part.startRot);
        part.condition = Utils.getNoNil(getXMLString(self.xmlFile, gaugeKey .. "#condition"), "noCondition");
        part.positiveDir = part.endRot > part.startRot;
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
    if self.LTMaster.baler.autoUnloadTime ~= nil and g_currentMission.time < self.LTMaster.baler.autoUnloadTime then
        self.LTMaster.wrkMove.conditions["isKnotting"] = true;
    else
        self.LTMaster.wrkMove.conditions["isKnotting"] = false;
    end
    if self.LTMaster.baler.unloadingState == Baler.UNLOADING_OPENING then
        self.LTMaster.wrkMove.conditions["baleDoorOpening"] = true;
    else
        self.LTMaster.wrkMove.conditions["baleDoorOpening"] = false;
    end
    if self.LTMaster.baler.unloadingState == Baler.UNLOADING_CLOSING then
        self.LTMaster.wrkMove.conditions["baleDoorClosing"] = true;
    else
        self.LTMaster.wrkMove.conditions["baleDoorClosing"] = false;
    end
    if self:getUnitFillLevel(self.LTMaster.fillUnits["main"].index) > 0 and self.LTMaster.conveyor.isOverloading then
        self.LTMaster.wrkMove.conditions["conveyorOn"] = true;
    else
        self.LTMaster.wrkMove.conditions["conveyorOn"] = false;
    end
    if self.LTMaster.wrapper.enabled then
        self.LTMaster.wrkMove.conditions["wrapperEnabled"] = true;
    else
        self.LTMaster.wrkMove.conditions["wrapperEnabled"] = false;
    end
    
    if self:getIsActive() then
        for i, part in pairs(self.LTMaster.gauge) do
            local x, y, z = getRotation(part.index);
            local xyz = LTMaster.getRotationaxis(x, y, z, part.axis);
            if self.LTMaster.wrkMove.conditions[part.condition] then
                local factor = dt / part.fadeIn;
                local delta = part.delta * factor;
                if part.positiveDir then
                    if xyz < part.endRot then
                        xyz = xyz + delta;
                    end
                else
                    if xyz > part.endRot then
                        xyz = xyz - delta;
                    end
                end
            else
                local factor = dt / part.fadeOut;
                local delta = part.delta * factor;
                if part.positiveDir then
                    if xyz > part.startRot then
                        xyz = xyz - delta;
                    end
                else
                    if xyz < part.startRot then
                        xyz = xyz + delta;
                    end
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

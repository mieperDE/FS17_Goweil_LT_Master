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
        part.gaugeIndex = Utils.indexToObject(self.components, getXMLString(self.xmlFile, gaugeKey .. "#index"));
        part.speed = Utils.getNoNil(getXMLFloat(self.xmlFile, gaugeKey .. "#speed"), 1) * 1000;
        local stx,sty,stz = Utils.getVectorFromString(getXMLString(self.xmlFile, gaugeKey.."#startRot"));
        local etx,ety,etz = Utils.getVectorFromString(getXMLString(self.xmlFile, gaugeKey.."#endRot"));
        part.condition = Utils.getNoNil(getXMLString(self.xmlFile, gaugeKey .. "#condition"), "noCondition");
        part.stx = math.rad(stx);
        part.etx = math.rad(etx);
        i = i + 1;
        part.numPart = i;
        self.LTMaster.gauge[i] = part;
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
end

function LTMaster:updateTickWrkMove(dt, normalizedDt)
    if self:getIsActive() then
        for i, part in pairs(self.LTMaster.gauge) do
            if self.LTMaster.wrkMove.conditions[part.condition] then
                local rotationFactor = dt / part.speed;
                local target = Utils.clamp(rotationFactor, math.rad(part.ex), math.rad(part.sx));
                --local target = math.rad(part.sx) + (math.rad(part.ex) - math.rad(part.sx)) * rotationFactor;
                
                local textOffset = (i/100)*1.2
                renderText(0.002, 0.002+textOffset, getCorrectTextSize(0.014), string.format("%.4f", target) .. "  " .. string.format("%.1f", i));
                
                setRotation(part.gaugeIndex, math.rad(part.sx)+target, 0, 0);
            else
                setRotation(part.gaugeIndex, math.rad(part.sx), 0, 0)
            end
        end
    end
end

function LTMaster:drawWrkMove()

end

function LTMaster:onDeactivateWrkMove()

end

function LTMaster:onTurnedOn(noEventSend)

end

function LTMaster:onTurnedOff(noEventSend)

end

function LTMaster:setGaugeRotation(gaugeI, gaugeRotation)
    
    setRotation(self.LTMaster.gauge[gaugeI].gaugeIndex, gaugeRotation, 0, 0);

end

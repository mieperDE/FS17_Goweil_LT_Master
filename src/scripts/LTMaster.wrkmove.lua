--
--Goweil LT Master
--
--fcelsa (Team FSI Modding)
--
--08/05/2017

function LTMaster:loadWrkMove()
    self.LTMaster.gauge = {}
    local i=0;
    while true do
        local gaugeKey = string.format("vehicle.LTMaster.gauge.part(%d)", i);
        if not hasXMLProperty(self.xmlFile, gaugeKey) then            
            break;
        end;
        local part = {}
        part.gaugeIndex = Utils.indexToObject(self.components, getXMLString(self.xmlFile, gaugeKey .. "#index"));
        --part.minX = Utils.getNoNil(getXMLFloat(self.xmlFile, gaugeKey .. "#minX", 0));
        --part.maxX = Utils.getNoNil(getXMLFloat(self.xmlFile, gaugeKey .. "#maxX", 10));
        --part.peak = Utils.getNoNil(getXMLFloat(self.xmlFile, gaugeKey .. "#peak", 0));
        --part.bounce = Utils.getNoNil(getXMLFloat(self.xmlFile, gaugeKey .. "#bounce"),0);
        local x,_,_ = getRotation(part.gaugeIndex);
        part.minX = x;
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

end

function LTMaster:updateTickWrkMove(dt, normalizedDt)
    if self:getIsActive() and self:getIsTurnedOn() then

        for i,part in pairs(self.LTMaster.gauge) do
            local target = part.minX + (2*normalizedDt);
            -- v1+ (v2 - v1) * alpha;
            local x,_,_ = getRotation(part.gaugeIndex);
            if i == 1 then 
                renderText(0.002, 0.002, getCorrectTextSize(0.012), string.format("%.4f",x).."  "..string.format("%.4f",math.rad(target)));
            end
            setRotation(part.gaugeIndex, x-math.rad(target), 0, 0)
        end
    end
end

function LTMaster:drawWrkMove()

end

function LTMaster:onDeactivateWrkMove()
    
end

function LTMaster:onTurnedOn(noEventSend)

    --for i,part in pairs(self.LTMaster.levers) do            
    --    LTMaster.print("levers part: x %s  y %s  z %s  lAxis %s", part.x, part.y, part.z, part.lAxis);
    --end
    
end

function LTMaster:onTurnedOff(noEventSend)

    --LTMaster.print("wrkmove on turned off");
    for i,part in pairs(self.LTMaster.gauge) do
        setRotation(part.gaugeIndex, math.rad(part.minX), 0, 0);
        print(tostring(math.rad(part.minX)));
    end

end

function LTMaster:setGaugeRotation(gaugeI, gaugeRotation)

    setRotation(self.LTMaster.gauge[gaugeI].gaugeIndex, gaugeRotation, 0, 0);
    
end

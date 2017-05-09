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
        local x,y,z = getRotation(part.gaugeIndex);
        part.x = x;
        part.y = y;
        part.z = z;
        part.minX = Utils.getNoNil(getXMLFloat(self.xmlFile, gaugeKey .. "#minX", 0));
        part.maxX = Utils.getNoNil(getXMLFloat(self.xmlFile, gaugeKey .. "#maxX", 10));
        part.bounce = Utils.getNoNil(getXMLFloat(self.xmlFile, gaugeKey .. "#bounce"),0);
        part.loctimer = 4000;
        i = i + 1;
        part.numPart = i;
        self.LTMaster.gauge[i] = part;
    end
    self.LTMaster.levers = {}
    local i=0;
    while true do
        local leversKey = string.format("vehicle.LTMaster.levers.part(%d)", i);
        if not hasXMLProperty(self.xmlFile, leversKey) then
            break;
        end;
        local part = {}
        part.leversIndex = Utils.indexToObject(self.components, getXMLString(self.xmlFile, leversKey .. "#index"));
        local x,y,z = getRotation(part.leversIndex);
        part.x = x;
        part.y = y;
        part.z = z;
        part.lAxis = Utils.getNoNil(getXMLFloat(self.xmlFile, leversKey .. "#lAxis", 0));
        part.lUp = Utils.getNoNil(getXMLFloat(self.xmlFile, leversKey .. "#lUp", 10));
        part.lDown = Utils.getNoNil(getXMLFloat(self.xmlFile, leversKey .. "#lDown"),0);
        i = i + 1;
        part.numPart = i;
        self.LTMaster.levers[i] = part;
    end
end

function LTMaster:postLoadWrkMove(savegame)
    
end

function LTMaster:deleteWrkMove()

end

function LTMaster:updateWrkMove(dt)
    
end

function LTMaster:updateTickWrkMove(dt, normalizedDt)
    
end

function LTMaster:drawWrkMove()
    
end

function LTMaster:onDeactivateWrkMove()
    
end

function LTMaster:onTurnedOn(noEventSend)

    --LTMaster.print("wrkmove on turned on");
    
    --for i,part in pairs(self.LTMaster.gauge) do            
    --    LTMaster.print("levers part: x %s  y %s  z %s  minX %s  maxX %s  bounce %s", part.x, part.y, part.z, part.minX, part.maxX, part.bounce);
    --end
    
    --for i,part in pairs(self.LTMaster.levers) do            
    --    LTMaster.print("levers part: x %s  y %s  z %s  lAxis %s", part.x, part.y, part.z, part.lAxis);
    --end
    
end

function LTMaster:onTurnedOff(noEventSend)

    --LTMaster.print("wrkmove on turned off");
    
end

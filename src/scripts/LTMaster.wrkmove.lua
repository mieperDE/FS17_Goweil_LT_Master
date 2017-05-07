--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--28/04/2017

function LTMaster:loadWrkMove()
    self.LTMaster.gauge = {}
    local i=0;
    while true do
        local areaKey = string.format("vehicle.gauge.part(%d)", i);
        if not hasXMLProperty(self.xmlFile, areaKey) then            
            break;
        end;
        local part = {}
        part.objRot = Utils.indexToObject(self.components, getXMLString(self.xmlFile, areaKey .. "#index"));
        local x,y,z = getRotation(part.objRot);
        part.x = x;
        part.y = y;
        part.z = z;
        part.minX = Utils.getNoNil(getXMLFloat(self.xmlFile, areaKey .. "#minX", 0));
        part.maxX = Utils.getNoNil(getXMLFloat(self.xmlFile, areaKey .. "#maxX", 10));
        part.bounce = Utils.getNoNil(getXMLFloat(self.xmlFile, areaKey .. "#bounce"),0);
        part.loctimer = 4000;
        i = i + 1;
        part.numPart = i;
        self.LTMaster.gauge[i] = part;
    end;

    self.LTMaster.levers = {}
    local i=0;
    while true do
        local areaKey = string.format("vehicle.levers.part(%d)", i);
        if not hasXMLProperty(self.xmlFile, areaKey) then            
            break;
        end;
        local part = {}
        part.objRot = Utils.indexToObject(self.components, getXMLString(self.xmlFile, areaKey .. "#index"));
        local x,y,z = getRotation(part.objRot);
        part.x = x;
        part.y = y;
        part.z = z;
        part.lAxis = Utils.getNoNil(getXMLFloat(self.xmlFile, areaKey .. "#lAxis", 0));
        part.lUp = Utils.getNoNil(getXMLFloat(self.xmlFile, areaKey .. "#lUp", 10));
        part.lDown = Utils.getNoNil(getXMLFloat(self.xmlFile, areaKey .. "#lDown"),0);
        i = i + 1;
        part.numPart = i;
        self.LTMaster.levers[i] = part;
    end;
    
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
    
end

function LTMaster:onTurnedOff(noEventSend)
    
end

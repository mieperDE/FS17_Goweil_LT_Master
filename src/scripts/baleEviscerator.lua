--
--Goweil LT Master
--
--fcelsa (Team FSI Modding)
--
--10/05/2017
BaleEviscerator = {};
BaleEviscerator.baleObject = nil;

function BaleEviscerator:loadMap(name)

end

function BaleEviscerator:deleteMap()
end

function BaleEviscerator:keyEvent(unicode, sym, modifier, isDown)
end

function BaleEviscerator:mouseEvent(posX, posY, isDown, isUp, button)
end

function BaleEviscerator:update(dt)
    self.baleObject = nil;
    if g_currentMission.player ~= nil then
        if g_currentMission.player.isObjectInRange then
            local object = g_currentMission:getNodeObject(g_currentMission.player.lastFoundObject);
            if object:isa(Bale) then
                self.baleObject = object;
            end
        end
    end
    if baleObject ~= nil then
        if InputBinding.hasEvent(InputBinding.ACTIVATE_HANDTOOL) then
            self:evisceratesBale(baleObject);
        end
    end
end

function BaleEviscerator:draw()
    if baleObject ~= nil then
        --aggiungi nel menù f1 il tasto per sviscerare la balla
        g_currentMission:addHelpButtonText(g_i18n:getText("input_EVIBALE"), InputBinding.ACTIVATE_HANDTOOL);
    end
end

function BaleEviscerator:evisceratesBale(baleObject)
    if g_currentMission:getIsServer() then
        local delta = baleObject.fillLevel;
        local fillType = baleObject.fillType;
        local x,y,z = getWorldTranslation(baleObject.rootNode);
        if TipUtil.getCanTipToGround(fillType) then 
            baleObject:delete();
            local xzRndm = ((math.random(1, 20))-10)/10;
            local xOffset = math.max(math.min(xzRndm, 0.3), -0.3);
            local zOffset = math.max(math.min(xzRndm, 0.8), -0.1);
            local ex = x + xOffset;
            local ey = y - 0.1;
            local ez = z + zOffset;
            local innerRadius = 0;
            local outerRadius = TipUtil.getDefaultMaxRadius(fillType);
            local levelerNode = 1;
            local valueOk, droppedToLine = TipUtil.tipToGroundAroundLine(nil,
                delta,
                fillType,
                x,
                y,
                z,
                ex,
                ey,
                ez,
                innerRadius,
                outerRadius,
                levelerNode,
                false, nil, false);
        end
    else
        g_client:getServerConnection():sendEvent(BaleEvisceratorEvent:new(baleObject));
    end
end

addModEventListener(BaleEviscerator);

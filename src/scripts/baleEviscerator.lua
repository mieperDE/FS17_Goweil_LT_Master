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
        --if controlli se il tasto per sviscerare la balla è premuto then
            --se è premuto e se in questo punt si può tippare to ground
                --chiami l'evento di sfaciatura e tip
                --chiami la funzione di sfaciatura e tip
    end
end

function BaleEviscerator:draw()
    if baleObject ~= nil then
        --aggiungi nel menù f1 il tasto per sviscerare la balla
    end
end

function BaleEviscerator:evisceratesBale(baleObject)
    --distruggi la balla ( puoi vedere il bale destroyer )
    --tippi to ground il materiale
end

addModEventListener(BaleEviscerator);

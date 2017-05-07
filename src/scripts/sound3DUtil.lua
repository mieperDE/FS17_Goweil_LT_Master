--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--07/05/2017
Sound3DUtil = {};
Sound3DUtil.soundsToStop = {};

function Sound3DUtil:loadMap(name)
end

function Sound3DUtil:deleteMap()
end

function Sound3DUtil:keyEvent(unicode, sym, modifier, isDown)
end

function Sound3DUtil:mouseEvent(posX, posY, isDown, isUp, button)
end

function Sound3DUtil:update(dt)
    local tr = nil;
    for i, sts in ipairs(self.soundsToStop) do
        if g_currentMission.time >= sts.time then
            SoundUtil.stop3DSample(sts.sample);
            tr = i;
            break;
        end
    end
    if tr ~= nil then
        table.remove(self.soundsToStop, tr);
    end
end

function Sound3DUtil:draw()
end

function Sound3DUtil:playSample(sample, numLoops, offsetMs, volume, activeForSound)
    if activeForSound then
        SoundUtil.playSample(sample, numLoops, offsetMs, volume);
    else
        SoundUtil.play3DSample(sample);
        if numLoops > 0 then
            table.insert(self.soundsToStop, {sample = sample, time = g_currentMission.time + (sample.duration * numLoops)});
        end
    end
end

function Sound3DUtil:stopSample(sample, force)
    SoundUtil.stopSample(sample, force);
    SoundUtil.stop3DSample(sample);
end

addModEventListener(Sound3DUtil);

--
-- LTMaster
--
-- Team FSI Modding
-- 
-- 2017-03
--

-- Appunti poi da cancellare... spec di default Baler
--			<specialization name="attacherJoints" />
--            <specialization name="lights" />
--            <specialization name="workArea" />
--            <specialization name="speedRotatingParts" />
--            <specialization name="attachable" />
--            <specialization name="turnOnVehicle" />
--            <specialization name="animatedVehicle" />
--            <specialization name="cylindered" />
--            <specialization name="foldable" />
--            <specialization name="fillable" />
--            <specialization name="fillVolume" />
--            <specialization name="pickup" />
--            <specialization name="baler" />
--            <specialization name="powerConsumer" />
--            <specialization name="washable" />
--            <specialization name="mountable" />
--


LTMaster = {};

function LTMaster.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Baler, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations);
end


function LTMaster:preLoad(savegame)	

end


function LTMaster:load(savegame)	

end


function LTMaster:postLoad(savegame)

end


function LTMaster:delete()

end


function LTMaster:mouseEvent(posX, posY, isDown, isUp, button)

end


function LTMaster:keyEvent(unicode, sym, modifier, isDown)

end


function LTMaster:update(dt)
	if self:getIsActive() then
		-- ma... esattamente che significa getIsActive...
	end;
end


function LTMaster:updateTick(dt)

end


function LTMaster:draw()

end


function LTMaster:setupLTMaster()

end




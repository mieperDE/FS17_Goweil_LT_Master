--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--20/04/2017
function LTMaster:applyInitialAnimation()
    --LTMaster.finalizeLoad(self);
    if superFunc ~= nil then
        superFunc(self);
    end
end

function LTMaster:setRelativePosition(positionX, offsetY, positionZ, yRot)
    --Called on setting position of vehicle (e. g. loading or reseting vehicle)
    self.LTMaster.hoods["left"].status = LTMaster.STATUS_OC_CLOSED;
    self.LTMaster.hoods["right"].status = LTMaster.STATUS_OC_CLOSED;
    self.LTMaster.supports.status = LTMaster.STATUS_RL_RAISED;
    self.LTMaster.folding.status = LTMaster.STATUS_FU_FOLDED;
    self.LTMaster.ladder.status = LTMaster.STATUS_RL_RAISED;
    self.LTMaster.baleSlide.status = LTMaster.STATUS_RL_RAISED;
    LTMaster.finalizeLoad(self);
end

function LTMaster:animationsInput(dt)
    if self.LTMaster.triggerLeft.active or self.LTMaster.triggerRight.active or self.LTMaster.triggerBaleSlide.active then
        if self:getRootAttacherVehicle().isMotorStarted then
            --Open/Close of the left door
            if self.LTMaster.triggerLeft.active then
                if self.LTMaster.hoods["left"].status == LTMaster.STATUS_OC_CLOSED then
                    g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_OPEN_HOOD"), InputBinding.TOGGLE_COVER, nil, GS_PRIO_HIGH);
                    if InputBinding.hasEvent(InputBinding.TOGGLE_COVER) then
                        self:updateHoodStatus(self.LTMaster.hoods["left"], LTMaster.STATUS_OC_OPENING);
                    end
                end
                if self.LTMaster.hoods["left"].status == LTMaster.STATUS_OC_OPEN then
                    g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_CLOSE_HOOD"), InputBinding.TOGGLE_COVER, nil, GS_PRIO_HIGH);
                    if InputBinding.hasEvent(InputBinding.TOGGLE_COVER) then
                        self:updateHoodStatus(self.LTMaster.hoods["left"], LTMaster.STATUS_OC_CLOSING);
                    end
                end
            end
            --Open/Close of the right door
            if self.LTMaster.triggerRight.active then
                if self.LTMaster.hoods["right"].status == LTMaster.STATUS_OC_CLOSED then
                    g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_OPEN_HOOD"), InputBinding.TOGGLE_COVER, nil, GS_PRIO_HIGH);
                    if InputBinding.hasEvent(InputBinding.TOGGLE_COVER) then
                        self:updateHoodStatus(self.LTMaster.hoods["right"], LTMaster.STATUS_OC_OPENING);
                    end
                end
                if self.LTMaster.hoods["right"].status == LTMaster.STATUS_OC_OPEN then
                    g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_CLOSE_HOOD"), InputBinding.TOGGLE_COVER, nil, GS_PRIO_HIGH);
                    if InputBinding.hasEvent(InputBinding.TOGGLE_COVER) then
                        self:updateHoodStatus(self.LTMaster.hoods["right"], LTMaster.STATUS_OC_CLOSING);
                    end
                end
            end
            if self.LTMaster.hoods["left"].status == LTMaster.STATUS_OC_OPEN then
                --Raise/Lower of the supports
                if self.LTMaster.triggerLeft.active then
                    if self.LTMaster.supports.status == LTMaster.STATUS_RL_RAISED and self:getIsUnfolded() then
                        g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_LOWER_SUPPORTS"), InputBinding.IMPLEMENT_EXTRA4, nil, GS_PRIO_HIGH);
                        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA4) then
                            self:updateSupportsStatus(LTMaster.STATUS_RL_LOWERING);
                        end
                    end
                    if self.LTMaster.supports.status == LTMaster.STATUS_RL_LOWERED and self.LTMaster.folding.status == LTMaster.STATUS_FU_FOLDED then
                        g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_RAISE_SUPPORTS"), InputBinding.IMPLEMENT_EXTRA4, nil, GS_PRIO_HIGH);
                        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA4) then
                            self:updateSupportsStatus(LTMaster.STATUS_RL_RAISING);
                        end
                    end
                end
                --Fold/Unfold
                if self.LTMaster.triggerLeft.active then
                    if self.LTMaster.folding.status == LTMaster.STATUS_FU_FOLDED and self.LTMaster.supports.status == LTMaster.STATUS_RL_LOWERED then
                        g_currentMission:addHelpButtonText(string.format(g_i18n:getText("action_unfoldOBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA, nil, GS_PRIO_HIGH);
                        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
                            self:updateFoldingStatus(LTMaster.STATUS_FU_UNFOLDING);
                        end
                    end
                    if self.LTMaster.folding.status == LTMaster.STATUS_FU_UNFOLDED and self:getUnitFillLevel(self.LTMaster.fillUnits["main"].index) <= 0.1 then
                        g_currentMission:addHelpButtonText(string.format(g_i18n:getText("action_foldOBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA, nil, GS_PRIO_HIGH);
                        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
                            if self.setIsTurnedOn ~= nil and self:getIsTurnedOn() then
                                self:setIsTurnedOn(false, true);
                            end
                            self:updateFoldingStatus(LTMaster.STATUS_FU_FOLDING);
                        end
                    end
                end
                --Raise/Lower of the bale slide
                if (self.LTMaster.triggerBaleSlide.active or self.LTMaster.triggerLeft.active) and self:getIsUnfolded() then
                    if self.LTMaster.baleSlide.status == LTMaster.STATUS_RL_RAISED then
                        g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_LOWER_BALE_SLIDE"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                            self:updateBaleSlideStatus(LTMaster.STATUS_RL_LOWERING);
                        end
                    end
                    if self.LTMaster.baleSlide.status == LTMaster.STATUS_RL_LOWERED and not self:getIsTurnedOn() then
                        g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_RAISE_BALE_SLIDE"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
                        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                            self:updateBaleSlideStatus(LTMaster.STATUS_RL_RAISING);
                        end
                    end
                end
            end
        else
            g_currentMission:addExtraPrintText(g_i18n:getText("GLTM_TURNON_VEHICLE"));
        end
    end
    
    --Raise/Lower of the ladder
    if self.LTMaster.triggerLadder.active then
        if self.LTMaster.ladder.status == LTMaster.STATUS_RL_RAISED then
            g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_LOWER_LADDER"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
            if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                self:updateLadderStatus(LTMaster.STATUS_RL_LOWERING);
            end
        end
        if self.LTMaster.ladder.status == LTMaster.STATUS_RL_LOWERED then
            g_currentMission:addHelpButtonText(g_i18n:getText("GLTM_RAISE_LADDER"), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH);
            if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
                self:updateLadderStatus(LTMaster.STATUS_RL_RAISING);
            end
        end
    end
end

function LTMaster:updateHoodStatus(hood, newStatus, noEventSend)
    local status = newStatus or hood.status;
    if (noEventSend == nil or not noEventSend) then
        if self.isServer then
            LTMaster.eventUpdateHoodStatus(self, hood.name, status);
            g_server:broadcastEvent(HoodStatusEvent:new(self, hood.name, status), false);
        else
            g_client:getServerConnection():sendEvent(HoodStatusEvent:new(self, hood.name, status));
        end
    else
        hood.status = status;
    end
    if self.isServer or noEventSend then
        if status == LTMaster.STATUS_OC_OPEN then
            self:playAnimation(hood.animation, math.huge, nil, noEventSend);
        end
        if status == LTMaster.STATUS_OC_OPENING then
            self:playAnimation(hood.animation, 1, nil, noEventSend);
            if self.isServer then
                self.LTMaster.hoods.delayedUpdateHoodStatus:call(self:getAnimationDuration(hood.animation), hood, LTMaster.STATUS_OC_OPEN);
            end
        end
        if status == LTMaster.STATUS_OC_CLOSED then
            self:playAnimation(hood.animation, -math.huge, nil, noEventSend);
        end
        if status == LTMaster.STATUS_OC_CLOSING then
            self:playAnimation(hood.animation, -1, nil, noEventSend);
            if self.isServer then
                self.LTMaster.hoods.delayedUpdateHoodStatus:call(self:getAnimationDuration(hood.animation), hood, LTMaster.STATUS_OC_CLOSED);
            end
        end
    end
end

function LTMaster:eventUpdateHoodStatus(hood, newStatus)
    self.LTMaster.hoods[hood].status = newStatus;
    if newStatus == LTMaster.STATUS_OC_OPENING then
        Sound3DUtil:playSample(self.LTMaster.hoods.openingSound, 1, 0, nil);
    end
    if newStatus == LTMaster.STATUS_OC_CLOSING then
        Sound3DUtil:playSample(self.LTMaster.hoods.closingSound, 1, 0, nil);
    end
end

function LTMaster:updateSupportsStatus(newStatus, noEventSend)
    local status = newStatus or self.LTMaster.supports.status;
    if (noEventSend == nil or not noEventSend) then
        if self.isServer then
            LTMaster.eventUpdateSupportsStatus(self, status);
            g_server:broadcastEvent(SupportsStatusEvent:new(self, status), false);
        else
            g_client:getServerConnection():sendEvent(SupportsStatusEvent:new(self, status));
        end
    else
        self.LTMaster.supports.status = status;
    end
    if self.isServer or noEventSend then
        if status == LTMaster.STATUS_RL_LOWERED then
            self:playAnimation(self.LTMaster.supports.animation, math.huge, nil, noEventSend);
        end
        if status == LTMaster.STATUS_RL_LOWERING then
            self:playAnimation(self.LTMaster.supports.animation, 1, nil, noEventSend);
            if self.isServer then
                self.LTMaster.supports.delayedUpdateSupportsStatus:call(self:getAnimationDuration(self.LTMaster.supports.animation), LTMaster.STATUS_RL_LOWERED);
            end
        end
        if status == LTMaster.STATUS_RL_RAISED then
            Sound3DUtil:stopSample(self.LTMaster.supports.sound, true);
            self:playAnimation(self.LTMaster.supports.animation, -math.huge, nil, noEventSend);
        end
        if status == LTMaster.STATUS_RL_RAISING then
            self:playAnimation(self.LTMaster.supports.animation, -1, nil, noEventSend);
            if self.isServer then
                self.LTMaster.supports.delayedUpdateSupportsStatus:call(self:getAnimationDuration(self.LTMaster.supports.animation), LTMaster.STATUS_RL_RAISED);
            end
        end
    end
end

function LTMaster:eventUpdateSupportsStatus(newStatus)
    self.LTMaster.supports.status = newStatus;
    if newStatus == LTMaster.STATUS_RL_LOWERED then
        Sound3DUtil:stopSample(self.LTMaster.supports.sound, true);
    end
    if newStatus == LTMaster.STATUS_RL_LOWERING then
        Sound3DUtil:playSample(self.LTMaster.supports.sound, 0, 0, nil);
    end
    if newStatus == LTMaster.STATUS_RL_RAISED then
        Sound3DUtil:stopSample(self.LTMaster.supports.sound, true);
    end
    if newStatus == LTMaster.STATUS_RL_RAISING then
        Sound3DUtil:playSample(self.LTMaster.supports.sound, 0, 0, nil);
    end
end

function LTMaster:updateFoldingStatus(newStatus, noEventSend)
    local status = newStatus or self.LTMaster.folding.status;
    if (noEventSend == nil or not noEventSend) then
        if self.isServer then
            LTMaster.eventUpdateFoldingStatus(self, status);
            g_server:broadcastEvent(FoldingStatusEvent:new(self, status), false);
        else
            g_client:getServerConnection():sendEvent(FoldingStatusEvent:new(self, status));
        end
    else
        self.LTMaster.folding.status = status;
    end
    if self.isServer or noEventSend then
        if status == LTMaster.STATUS_FU_UNFOLDED then
            self:playAnimation(self.LTMaster.folding.animation, math.huge, nil, noEventSend);
        end
        if status == LTMaster.STATUS_FU_UNFOLDING then
            self:playAnimation(self.LTMaster.folding.animation, 1, nil, noEventSend);
            if self.isServer then
                self.LTMaster.folding.delayedUpdateFoldingStatus:call(self:getAnimationDuration(self.LTMaster.folding.animation), LTMaster.STATUS_FU_UNFOLDED);
            end
        end
        if status == LTMaster.STATUS_FU_FOLDED then
            self:playAnimation(self.LTMaster.folding.animation, -math.huge, nil, noEventSend);
        end
        if status == LTMaster.STATUS_FU_FOLDING then
            self:playAnimation(self.LTMaster.folding.animation, -1, nil, noEventSend);
            if self.isServer then
                self.LTMaster.folding.delayedUpdateFoldingStatus:call(self:getAnimationDuration(self.LTMaster.folding.animation), LTMaster.STATUS_FU_FOLDED);
            end
        end
    end
end

function LTMaster:eventUpdateFoldingStatus(newStatus)
    self.LTMaster.folding.status = newStatus;
    if newStatus == LTMaster.STATUS_FU_UNFOLDED then
        Sound3DUtil:stopSample(self.LTMaster.folding.sound, true);
    end
    if newStatus == LTMaster.STATUS_FU_UNFOLDING then
        Sound3DUtil:playSample(self.LTMaster.folding.sound, 0, 0, nil);
    end
    if newStatus == LTMaster.STATUS_FU_FOLDED then
        Sound3DUtil:stopSample(self.LTMaster.folding.sound, true);
    end
    if newStatus == LTMaster.STATUS_FU_FOLDING then
        Sound3DUtil:playSample(self.LTMaster.folding.sound, 0, 0, nil);
    end
end

function LTMaster:updateLadderStatus(newStatus, noEventSend)
    local status = newStatus or self.LTMaster.supports.status;
    if (noEventSend == nil or not noEventSend) then
        if self.isServer then
            LTMaster.eventUpdateLadderStatus(self, status);
            g_server:broadcastEvent(LadderStatusEvent:new(self, status), false);
        else
            g_client:getServerConnection():sendEvent(LadderStatusEvent:new(self, status));
        end
    else
        self.LTMaster.ladder.status = status;
    end
    if self.isServer or noEventSend then
        if status == LTMaster.STATUS_RL_LOWERED then
            self:playAnimation(self.LTMaster.ladder.animation, math.huge, nil, noEventSend);
        end
        if status == LTMaster.STATUS_RL_LOWERING then
            self:playAnimation(self.LTMaster.ladder.animation, 1, nil, noEventSend);
            if self.isServer then
                self.LTMaster.ladder.delayedUpdateLadderStatus:call(self:getAnimationDuration(self.LTMaster.ladder.animation), LTMaster.STATUS_RL_LOWERED);
            end
        end
        if status == LTMaster.STATUS_RL_RAISED then
            self:playAnimation(self.LTMaster.ladder.animation, -math.huge, nil, noEventSend);
        end
        if status == LTMaster.STATUS_RL_RAISING then
            self:playAnimation(self.LTMaster.ladder.animation, -1, nil, noEventSend);
            if self.isServer then
                self.LTMaster.ladder.delayedUpdateLadderStatus:call(self:getAnimationDuration(self.LTMaster.ladder.animation), LTMaster.STATUS_RL_RAISED);
            end
        end
    end
end

function LTMaster:eventUpdateLadderStatus(newStatus)
    self.LTMaster.ladder.status = newStatus;
    if newStatus == LTMaster.STATUS_RL_LOWERED then
        Sound3DUtil:stopSample(self.LTMaster.ladder.sound, true);
    end
    if newStatus == LTMaster.STATUS_RL_LOWERING then
        Sound3DUtil:playSample(self.LTMaster.ladder.sound, 0, 0, nil);
    end
    if newStatus == LTMaster.STATUS_RL_RAISED then
        Sound3DUtil:stopSample(self.LTMaster.ladder.sound, true);
    end
    if newStatus == LTMaster.STATUS_RL_RAISING then
        Sound3DUtil:playSample(self.LTMaster.ladder.sound, 0, 0, nil);
    end
end

function LTMaster:updateBaleSlideStatus(newStatus, noEventSend)
    local status = newStatus or self.LTMaster.baleSlide.status;
    if (noEventSend == nil or not noEventSend) then
        if self.isServer then
            LTMaster.eventUpdateBaleSlideStatus(self, status);
            g_server:broadcastEvent(BaleSlideStatusEvent:new(self, status), false);
        else
            g_client:getServerConnection():sendEvent(BaleSlideStatusEvent:new(self, status));
        end
    else
        self.LTMaster.baleSlide.status = status;
    end
    if self.isServer or noEventSend then
        if status == LTMaster.STATUS_RL_LOWERED then
            self:playAnimation(self.LTMaster.baleSlide.animation, math.huge, nil, noEventSend);
        end
        if status == LTMaster.STATUS_RL_LOWERING then
            self:playAnimation(self.LTMaster.baleSlide.animation, 1, nil, noEventSend);
            if self.isServer then
                self.LTMaster.baleSlide.delayedUpdateBaleSlideStatus:call(self:getAnimationDuration(self.LTMaster.baleSlide.animation), LTMaster.STATUS_RL_LOWERED);
            end
        end
        if status == LTMaster.STATUS_RL_RAISED then
            self:playAnimation(self.LTMaster.baleSlide.animation, -math.huge, nil, noEventSend);
        end
        if status == LTMaster.STATUS_RL_RAISING then
            self:playAnimation(self.LTMaster.baleSlide.animation, -1, nil, noEventSend);
            if self.isServer then
                self.LTMaster.baleSlide.delayedUpdateBaleSlideStatus:call(self:getAnimationDuration(self.LTMaster.baleSlide.animation), LTMaster.STATUS_RL_RAISED);
            end
        end
    end
end

function LTMaster:eventUpdateBaleSlideStatus(newStatus)
    self.LTMaster.baleSlide.status = newStatus;
    if newStatus == LTMaster.STATUS_RL_LOWERED then
        Sound3DUtil:stopSample(self.LTMaster.baleSlide.sound, true);
    end
    if newStatus == LTMaster.STATUS_RL_LOWERING then
        Sound3DUtil:playSample(self.LTMaster.baleSlide.sound, 0, 0, nil);
    end
    if newStatus == LTMaster.STATUS_RL_RAISED then
        Sound3DUtil:stopSample(self.LTMaster.baleSlide.sound, true);
    end
    if newStatus == LTMaster.STATUS_RL_RAISING then
        Sound3DUtil:playSample(self.LTMaster.baleSlide.sound, 0, 0, nil);
    end
end

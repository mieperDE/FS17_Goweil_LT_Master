--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--27/04/2017
LTMasterConveyorEffect = {};
local LTMasterConveyorEffect_mt = Class(LTMasterConveyorEffect, ShaderPlaneEffect);

function LTMasterConveyorEffect:new(customMt)
    if customMt == nil then
        customMt = LTMasterConveyorEffect_mt;
    end
    local self = ShaderPlaneEffect:new(customMt);
    return self;
end

function LTMasterConveyorEffect:loadEffectAttributes(xmlFile, key, node, i3dNode)
    LTMasterConveyorEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode)
    self.speed = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "speed"), 1);
    self.fadeCur = {0, 0};
    self.fadeDir = {0, 0};
    self.scrollLength = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "scrollLength"), 1);
    self.scrollSpeed = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "scrollSpeed"), 1) * 0.001;
    self.scrollPosition = 0;
    self.scrollUpdate = true;
    setShaderParameter(self.node, "morphPosition", 0.0, 1.0, 1.0, 0.0, false);
    setVisibility(self.node, false);
end

function LTMasterConveyorEffect:update(dt)
    local running = false;
    if self.currentDelay > 0 then
        self.currentDelay = self.currentDelay - dt;
    end
    if self.currentDelay <= 0 and self.state ~= ShaderPlaneEffect.STATE_OFF then
        local fadeTime = self.fadeInTime;
        if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
            fadeTime = self.fadeOutTime;
        end
        self.fadeCur[1] = math.max(0, math.min(1, self.fadeCur[1] + self.fadeDir[1] * (dt / fadeTime)));
        self.fadeCur[2] = math.max(0, math.min(1, self.fadeCur[2] + self.fadeDir[2] * (dt / fadeTime)), self.offset);
        if self.state ~= ShaderPlaneEffect.STATE_OFF and self.state ~= ShaderPlaneEffect.STATE_TURNING_OFF then
            self.fadeCur[1] = self.offset;
        end
        setShaderParameter(self.node, "morphPosition", self.fadeCur[1], self.fadeCur[2], 1.0, self.speed, false);
        local isVisible = true;
        if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
            if self.fadeCur[1] == 1 then
                isVisible = false;
                self.fadeCur[1] = 0;
                self.fadeCur[2] = 0;
                self.state = ShaderPlaneEffect.STATE_OFF;
            end
        end
        setVisibility(self.node, isVisible);
        if not ((self.state == ShaderPlaneEffect.STATE_TURNING_ON and self.fadeCur[1] == 0 and self.fadeCur[2] == 1) or (self.state == ShaderPlaneEffect.STATE_TURNING_OFF and self.fadeCur[1] == 1 and self.fadeCur[2] == 1)) then
            running = true;
        end
    else
        running = true;
    end
    if self.scrollUpdate then
        self.scrollPosition = (self.scrollPosition + dt * self.scrollSpeed) % self.scrollLength;
        setShaderParameter(self.node, "offsetUV", self.scrollPosition, 0, 0, 0, false);
    end
    if not running then
        if self.state == ShaderPlaneEffect.STATE_TURNING_ON then
            self.state = ShaderPlaneEffect.STATE_ON;
        elseif self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
            self.state = ShaderPlaneEffect.STATE_OFF;
        end
    end
end

function LTMasterConveyorEffect:start()
    if self.state ~= ShaderPlaneEffect.STATE_TURNING_ON and self.state ~= ShaderPlaneEffect.STATE_ON then
        self.state = ShaderPlaneEffect.STATE_TURNING_ON;
        self.fadeCur = {math.min(self.offset, 0), math.min(self.offset, self.fadeCur[2])};
        self.fadeDir = {0, 1};
        self.currentDelay = self.startDelay;
        return true;
    end
    return false;
end

function LTMasterConveyorEffect:stop()
    if self.state ~= ShaderPlaneEffect.STATE_TURNING_OFF and self.state ~= ShaderPlaneEffect.STATE_OFF then
        self.state = ShaderPlaneEffect.STATE_TURNING_OFF;
        self.fadeDir = {1, 1};
        self.currentDelay = self.stopDelay;
        return true;
    end
    return false;
end

function LTMasterConveyorEffect:reset()
    self.fadeCur = {math.min(self.offset, 0), math.min(self.offset, 0)};
    self.fadeDir = {0, 1};
    setShaderParameter(self.node, "morphPosition", self.fadeCur[1], self.fadeCur[2], 0.0, self.scrollSpeed, false);
    setVisibility(self.node, false);
    self.state = ShaderPlaneEffect.STATE_OFF;
end

function LTMasterConveyorEffect:setScrollUpdate(state)
    if state == nil then
        self.scrollUpdate = not self.scrollUpdate;
    else
        self.scrollUpdate = state;
    end
end

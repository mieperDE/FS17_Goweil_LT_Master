LTMasterTipTrigger = {};

local LTMasterTipTrigger_mt = Class(LTMasterTipTrigger, TipTrigger);

InitObjectClass(LTMasterTipTrigger, "LTMasterTipTrigger");

function LTMasterTipTrigger:new(isServer, isClient, customMt)
    if customMt == nil then
        customMt = LTMasterTipTrigger_mt;
    end
    local self = TipTrigger:new(isServer, isClient, customMt);
    return self;
end

function LTMasterTipTrigger:load(id, owner, fillUnitIndex, rightFillUnitIndex, leftFillUnitIndex)
    local isSuccessfull = LTMasterTipTrigger:superClass().load(self, id);
    self.owner = owner;
    self.fillUnitIndex = fillUnitIndex;
    self.rightFillUnitIndex = rightFillUnitIndex;
    self.leftFillUnitIndex = leftFillUnitIndex;
    for fillType, active in pairs(self.owner.fillUnits[fillUnitIndex].fillTypes) do
        if active then
            self:addAcceptedFillType(fillType, 0, 0, true, {TipTrigger.TOOL_TYPE_TRAILER, TipTrigger.TOOL_TYPE_SHOVEL, TipTrigger.TOOL_TYPE_PIPE, TipTrigger.TOOL_TYPE_PALLET})
        end
    end
    return isSuccessfull;
end

function LTMasterTipTrigger:delete()
    LTMasterTipTrigger:superClass().delete(self);
end

function LTMasterTipTrigger:readStream(streamId, connection)
end

function LTMasterTipTrigger:writeStream(streamId, connection)
end

function LTMasterTipTrigger:readUpdateStream(streamId, timestamp, connection)
end

function LTMasterTipTrigger:writeUpdateStream(streamId, connection, dirtyMask)
end

function LTMasterTipTrigger:update(dt)
end

function LTMasterTipTrigger:addFillLevelFromTool(trailer, fillDelta, fillType, toolType)
    if fillDelta > 0 then
        local mainFillDelta = fillDelta / 2;
        local leftRightFillDelta = fillDelta / 4;
        local mainCapacity = self.owner:getUnitCapacity(self.fillUnitIndex);
        local mainFillLevel = self.owner:getUnitFillLevel(self.fillUnitIndex);
        local mainDelta = math.min(mainFillDelta, mainCapacity - mainFillLevel);
        if mainDelta > 0 then
            self.owner:setUnitFillLevel(self.fillUnitIndex, mainFillLevel + mainDelta, fillType);
        end
        local rightCapacity = self.owner:getUnitCapacity(self.rightFillUnitIndex);
        local rightFillLevel = self.owner:getUnitFillLevel(self.rightFillUnitIndex);
        local rightDelta = math.min(leftRightFillDelta, rightCapacity - rightFillLevel);
        if rightDelta > 0 then
            self.owner:setUnitFillLevel(self.rightFillUnitIndex, rightFillLevel + rightDelta, fillType);
        end
        local leftCapacity = self.owner:getUnitCapacity(self.leftFillUnitIndex);
        local leftFillLevel = self.owner:getUnitFillLevel(self.leftFillUnitIndex);
        local leftDelta = math.min(leftRightFillDelta, leftCapacity - leftFillLevel);
        if leftDelta > 0 then
            self.owner:setUnitFillLevel(self.leftFillUnitIndex, leftFillLevel + leftDelta, fillType);
        end
        local dropped = mainDelta + rightDelta + leftDelta;
        if self.owner:getIsTurnedOn() then
            if dropped <= 0 and trailer:getFillLevel(fillType) <= 0 then
                trailer:onEndTip();
            end
        else
            if dropped <= 0 then
                trailer:onEndTip();
            end
        end
        return dropped + 0.01000001;
    end
end

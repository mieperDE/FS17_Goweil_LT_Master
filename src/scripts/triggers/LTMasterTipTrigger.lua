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

function LTMasterTipTrigger:load(id, owner, fillUnitIndex)
    local isSuccessfull = LTMasterTipTrigger:superClass().load(self, id);
    self.owner = owner;
    self.fillUnitIndex = fillUnitIndex;
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
        local capacity = self.owner:getUnitCapacity(self.fillUnitIndex);
        local fillLevel = self.owner:getUnitFillLevel(self.fillUnitIndex);
        local delta = math.min(fillDelta, capacity - fillLevel);
        if delta <= 0 then
            trailer:onEndTip(true);
        else
            self.owner:setUnitFillLevel(self.fillUnitIndex, fillLevel + delta, fillType);
        end
        return delta;
    end
end

--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--18/04/2017
PlayerTriggers = {};
PlayerTriggers.triggers = {};

function PlayerTriggers:add(trigger)
    self.triggers[trigger.node] = trigger;
end

function PlayerTriggers:remove(trigger)
    self.triggers[trigger.node] = nil;
end

function PlayerTriggers:update()
    for _, t in pairs(self.triggers) do
        if t.update ~= nil then
            t:update();
        end
    end
end

PlayerTrigger = {};
local PlayerTrigger_mt = Class(PlayerTrigger);

function PlayerTrigger:new(node, radius, mt)
    local self = {};
    if mt == nil then
        mt = PlayerTrigger_mt;
    end
    setmetatable(self, mt);
    
    self.node = node;
    self.radius = radius;
    self.active = false;
    
    PlayerTriggers:add(self);
    
    return self;
end

function PlayerTrigger:delete()
    PlayerTriggers:remove(self);
end

function PlayerTrigger:update()
    local px, py, pz = getWorldTranslation(g_currentMission.player.rootNode);
    local tx, ty, tz = getWorldTranslation(self.node);
    if Utils.vector3Length(px - tx, py - ty, pz - tz) <= self.radius then
        self.active = true;
    else
        self.active = false;
    end
end

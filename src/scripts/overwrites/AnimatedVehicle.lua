--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--18/05/2017
function AnimatedVehicle.initializeParts(self, animation)
    local numParts = table.getn(animation.parts);
    
    for i = 1, numParts do
        local part = animation.parts[i];
        
        -- find the next rot part
        if part.endRot ~= nil then
            for j = i + 1, numParts do
                local part2 = animation.parts[j];
                if part.node == part2.node and part2.endRot ~= nil then
                    if part.startTime + part.duration > part2.startTime + 0.001 and part.direction == part2.direction then
                        print("Warning: overlapping rotation parts for node " .. getName(part.node) .. " in " .. animation.name .. " " .. self.configFileName);
                    end
                    part.nextRotPart = part2;
                    part2.prevRotPart = part;
                    if part2.startRot == nil then
                        part2.startRot = {part.endRot[1], part.endRot[2], part.endRot[3]};
                    end
                    break;
                end
            end
        end
        
        -- find the next trans part
        if part.endTrans ~= nil then
            for j = i + 1, numParts do
                local part2 = animation.parts[j];
                if part.node == part2.node and part2.endTrans ~= nil then
                    if part.startTime + part.duration > part2.startTime + 0.001 and part.direction == part2.direction then
                        print("Warning: overlapping translation parts for node " .. getName(part.node) .. " in " .. animation.name .. " " .. self.configFileName);
                    end
                    part.nextTransPart = part2;
                    part2.prevTransPart = part;
                    if part2.startTrans == nil then
                        part2.startTrans = {part.endTrans[1], part.endTrans[2], part.endTrans[3]};
                    end
                    break;
                end
            end
        end
        
        -- find the next scale part
        if part.endScale ~= nil then
            for j = i + 1, numParts do
                local part2 = animation.parts[j];
                if part.node == part2.node and part2.endScale ~= nil then
                    if part.startTime + part.duration > part2.startTime + 0.001 and part.direction == part2.direction then
                        print("Warning: overlapping scale parts for node " .. getName(part.node) .. " in " .. animation.name .. " " .. self.configFileName);
                    end
                    part.nextScalePart = part2;
                    part2.prevScalePart = part;
                    if part2.startScale == nil then
                        part2.startScale = {part.endScale[1], part.endScale[2], part.endScale[3]};
                    end
                    break;
                end
            end
        end
        
        -- find the next shader part
        if part.shaderEndValues ~= nil then
            for j = i + 1, numParts do
                local part2 = animation.parts[j];
                if part.node == part2.node and part2.shaderEndValues ~= nil then
                    if part.startTime + part.duration > part2.startTime + 0.001 and part.direction == part2.direction then
                        print("Warning: overlapping shaderParameter parts for node " .. getName(part.node) .. " in " .. animation.name .. " " .. self.configFileName);
                    end
                    part.nextShaderPart = part2;
                    part2.prevShaderPart = part;
                    if part2.shaderStartValues == nil then
                        part2.shaderStartValues = {part.shaderEndValues[1], part.shaderEndValues[2], part.shaderEndValues[3], part.shaderEndValues[4]};
                    end
                    break;
                end
            end
        end
        
        if self.isServer then
            -- find the next joint rot limit part
            if part.endRotMinLimit ~= nil then
                for j = i + 1, numParts do
                    local part2 = animation.parts[j];
                    if part.componentJoint == part2.componentJoint and (part2.endRotMinLimit ~= nil and part2.endRotMaxLimit ~= nil) then
                        if part.startTime + part.duration > part2.startTime + 0.001 and part.direction == part2.direction then
                            print("Warning: overlapping joint rot limit parts for component joint " .. getName(part.componentJoint.jointNode) .. " in " .. animation.name .. " " .. self.configFileName);
                        end
                        part.nextRotLimitPart = part2;
                        part2.prevRotLimitPart = part;
                        if part2.startRotMinLimit == nil then
                            part2.startRotMinLimit = {part.endRotMinLimit[1], part.endRotMinLimit[2], part.endRotMinLimit[3]};
                        end
                        if part2.startRotMaxLimit == nil then
                            part2.startRotMaxLimit = {part.endRotMaxLimit[1], part.endRotMaxLimit[2], part.endRotMaxLimit[3]};
                        end
                        break;
                    end
                end
            end
            
            -- find the next joint trans limit part
            if part.endTransMinLimit ~= nil then
                for j = i + 1, numParts do
                    local part2 = animation.parts[j];
                    if part.componentJoint == part2.componentJoint and (part2.endTransMinLimit ~= nil and part2.endTransMaxLimit ~= nil) then
                        if part.startTime + part.duration > part2.startTime + 0.001 and part.direction == part2.direction then
                            print("Warning: overlapping joint trans limit parts for component joint " .. getName(part.componentJoint.jointNode) .. " in " .. animation.name .. " " .. self.configFileName);
                        end
                        part.nextTransLimitPart = part2;
                        part2.prevTransLimitPart = part;
                        if part2.startTransMinLimit == nil then
                            part2.startTransMinLimit = {part.endTransMinLimit[1], part.endTransMinLimit[2], part.endTransMinLimit[3]};
                        end
                        if part2.startTransMaxLimit == nil then
                            part2.startTransMaxLimit = {part.endTransMaxLimit[1], part.endTransMaxLimit[2], part.endTransMaxLimit[3]};
                        end
                        break;
                    end
                end
            end
        end
    end
    
    -- default start values to the value stored in the i3d (if not set by the end value of the previous part)
    for i = 1, numParts do
        local part = animation.parts[i];
        if part.endRot ~= nil and part.startRot == nil then
            local x, y, z = getRotation(part.node);
            part.startRot = {x, y, z};
        end
        if part.endTrans ~= nil and part.startTrans == nil then
            local x, y, z = getTranslation(part.node);
            part.startTrans = {x, y, z};
        end;
        if part.endScale ~= nil and part.startScale == nil then
            local x, y, z = getScale(part.node);
            part.startScale = {x, y, z};
        end;
        if self.isServer then
            if part.endRotMinLimit ~= nil and part.startRotMinLimit == nil then
                local rotLimit = part.componentJoint.rotMinLimit;
                part.startRotMinLimit = {rotLimit[1], rotLimit[2], rotLimit[3]};
            end
            if part.endRotMaxLimit ~= nil and part.startRotMaxLimit == nil then
                local rotLimit = part.componentJoint.rotLimit;
                part.startRotMaxLimit = {rotLimit[1], rotLimit[2], rotLimit[3]};
            end
            if part.endTransMinLimit ~= nil and part.startTransMinLimit == nil then
                local transLimit = part.componentJoint.transMinLimit;
                part.startTransMinLimit = {transLimit[1], transLimit[2], transLimit[3]};
            end
            if part.endTransMaxLimit ~= nil and part.startTransMaxLimit == nil then
                local transLimit = part.componentJoint.transLimit;
                part.startTransMaxLimit = {transLimit[1], transLimit[2], transLimit[3]};
            end
        end
    end
end

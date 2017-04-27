--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--27/04/2017
function getClassObject(className)
    local parts = Utils.splitString(".", className);
    local numParts = table.getn(parts);
    local currentTable = _G[parts[1]];
    if type(currentTable) ~= "table" then
        return nil;
    end
    for i = 2, numParts do
        currentTable = currentTable[parts[i]];
        if type(currentTable) ~= "table" then
            return nil;
        end
    end
    return currentTable;
end

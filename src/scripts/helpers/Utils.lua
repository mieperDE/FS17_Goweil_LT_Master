--
--Goweil LT Master
--
--TyKonKet (Team FSI Modding)
--
--23/05/2017
function Utils.tableLength(t)
    local c = 0;
    for _ in pairs(t) do
        c = c + 1;
    end
    return c;
end

function Utils.loadHelpLine(xml, helpLineCategories, helpLineCategorySelectorElement, modDirectory)
    xml = loadXMLFile("customHelpLineViewContentXML", xml);
    local categoriesIndex = 0;
    while true do
        local categoryQuery = string.format("helpLines.helpLineCategory(%d)", categoriesIndex);
        if not hasXMLProperty(xml, categoryQuery) then
            break;
        end
        local category = {
            title = getXMLString(xml, string.format("%s#title", categoryQuery)),
            helpLines = {}
        };
        helpLineCategorySelectorElement:addText(g_i18n:getText(category.title));
        local helpLinesIndex = 0;
        while true do
            local helpLineQuery = string.format("%s.helpLine(%d)", categoryQuery, helpLinesIndex);
            if not hasXMLProperty(xml, helpLineQuery) then
                break;
            end
            local helpLine = {
                title = getXMLString(xml, string.format("%s#title", helpLineQuery)),
                items = {}
            };
            local itemsIndex = 0;
            while true do
                local itemQuery = string.format("%s.item(%d)", helpLineQuery, itemsIndex);
                if not hasXMLProperty(xml, itemQuery) then
                    break;
                end
                local itemType = getXMLString(xml, string.format("%s#type", itemQuery));
                local itemValue = getXMLString(xml, string.format("%s#value", itemQuery));
                if itemType == "image" then
                    itemValue = modDirectory .. itemValue;
                end
                if (itemType == "text" or itemType == "image") and itemValue ~= nil then
                    table.insert(helpLine.items, {
                        type = itemType,
                        value = itemValue,
                        heightScale = Utils.getNoNil(getXMLFloat(xml, string.format("%s#heightScale", itemQuery)), 1)
                    });
                end
                itemsIndex = itemsIndex + 1;
            end
            table.insert(category.helpLines, helpLine);
            helpLinesIndex = helpLinesIndex + 1;
        end
        table.insert(helpLineCategories, category);
        categoriesIndex = categoriesIndex + 1;
    end
    delete(xml);
end

function Utils.loadI3D(i3dFilename, parent)
    local filename = i3dFilename;
    local i3dNode = loadI3DFile(filename, false, true, false);
    for i = getNumOfChildren(i3dNode) - 1, 0, -1 do
        local child = getChildAt(i3dNode, i);
        if parent ~= nil then
            link(parent, child);
        else
            unlink(child);
        end
        table.insert(g_currentMission.dynamicallyLoadedObjects, child);
    end
    delete(i3dNode);
end

function InputBinding.getKeysNamesOfDigitalAction(actionIndex)
    local actionData = InputBinding.actions[actionIndex];
    local k1, k2, m1 = nil;
    if #actionData.keys1 > 0 then
        k1 = InputBinding.getKeyNames(actionData.keys1);
    end
    if #actionData.keys2 > 0 then
        k2 = InputBinding.getKeyNames(actionData.keys2);
    end
    if #actionData.mouseButtons > 0 then
        m1 = InputBinding.getMouseButtonNames(actionData.mouseButtons);
    end
    if k1 ~= nil and k2 ~= nil then
        return string.format("%s %s %s", k1, g_i18n:getText("ui_and"), k2);
    end
    if k1 ~= nil then
        return k1;
    end
    if k2 ~= nil then
        return k2;
    end
    if m1 ~= nil then
        return m1
    end
    return "";
end

function InputBinding.getMouseButtonNames(mouseButtons)
    return g_i18n:getText("ui_mouse") .. " " .. MouseHelper.getButtonNames(mouseButtons);
end

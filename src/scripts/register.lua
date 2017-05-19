--
--Goweil LT Master
--
--TyKonKet - fcelsa (Team FSI Modding)
--
--01/05/2017

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

function loadHelpLine(xml, helpLineCategories, helpLineCategorySelectorElement, modDirectory)
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

ConfigurationUtil.registerConfigurationType("silageAdditiveSystem", g_i18n:getText("configuration_silageAdditiveSystem"), nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION);
ConfigurationUtil.registerConfigurationType("conveyorFlow", g_i18n:getText("configuration_conveyorFlow"), nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION);
ConfigurationUtil.registerConfigurationType("dynamicChamber", g_i18n:getText("configuration_dynamicChamber"), nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION);
ConfigurationUtil.registerConfigurationType("monitorSystem", g_i18n:getText("configuration_monitorSystem"), nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION);
ConfigurationUtil.registerConfigurationType("remoteMonitorSystem", g_i18n:getText("configuration_remoteMonitorSystem"), nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION);

FillUtil.registerFillType(
    "silageAdditive",
    g_i18n:getText("fillType_silageAdditive"),
    FillUtil.FILLTYPE_CATEGORY_LIQUID,
    5.000,
    false,
    g_currentModDirectory .. "hud/fillTypes/hud_fill_silageAdditive.png",
    g_currentModDirectory .. "hud/fillTypes/hud_fill_silageAdditive_sml.png",
    550 * 0.000001,
    math.rad(0)
);

FillUtil.registerFillType(
    "balesNet",
    g_i18n:getText("fillType_balesNet"),
    FillUtil.FILLTYPE_CATEGORY_PIECE,
    75,
    false,
    g_currentModDirectory .. "hud/fillTypes/hud_fill_balesNet.png",
    g_currentModDirectory .. "hud/fillTypes/hud_fill_balesNet_sml.png",
    1500 * 0.000001,
    math.rad(0)
);

FillUtil.registerFillType(
    "balesFoil",
    g_i18n:getText("fillType_balesFoil"),
    FillUtil.FILLTYPE_CATEGORY_PIECE,
    50,
    false,
    g_currentModDirectory .. "hud/fillTypes/hud_fill_balesFoil.png",
    g_currentModDirectory .. "hud/fillTypes/hud_fill_balesFoil_sml.png",
    1800 * 0.000001,
    math.rad(0)
);

BaleUtil.registerBaleType(
    "bales/roundbaleGrass_w112_d130.i3d",
    "grass_windrow",
    1.12,
    nil,
    nil,
    1.3,
    true
);

BaleUtil.registerBaleType(
    "bales/roundbaleGrassSilage_w112_d130.i3d",
    "silage",
    1.12,
    nil,
    nil,
    1.3,
    true
);

BaleUtil.registerBaleType(
    "bales/roundbaleHay_w112_d130.i3d",
    "dryGrass_windrow",
    1.12,
    nil,
    nil,
    1.3,
    true
);

BaleUtil.registerBaleType(
    "bales/roundbaleStraw_w112_d130.i3d",
    "straw",
    1.12,
    nil,
    nil,
    1.3,
    true
);

BaleUtil.registerBaleType(
    "bales/roundbaleChaff_w112_d130.i3d",
    "chaff",
    1.12,
    nil,
    nil,
    1.3,
    true
);

BaleUtil.registerBaleType(
    "bales/roundbaleChaffSilage_w112_d130.i3d",
    "silage",
    1.13,
    nil,
    nil,
    1.3,
    true
);

BaleUtil.registerBaleType(
    "bales/roundbaleWoodChips_w112_d130.i3d",
    "woodChips",
    1.12,
    nil,
    nil,
    1.3,
    true
);

BaleUtil.registerBaleType(
    "bales/roundbaleManure_w112_d130.i3d",
    "manure",
    1.12,
    nil,
    nil,
    1.3,
    true
);

for k, v in pairs(g_i18n.texts) do
    local nv = v;
    for m in nv:gmatch("$input_.-;") do
        local input = m:gsub("$input_", ""):gsub(";", "");
        nv = nv:gsub(m, InputBinding.getKeysNamesOfDigitalAction(InputBinding[input]));
    end
    g_i18n.globalI18N:setText(k, nv);
end

loadHelpLine(g_currentModDirectory .. "helpline/helpLine.xml", g_inGameMenu.helpLineCategories, g_inGameMenu.helpLineCategorySelectorElement, g_currentModDirectory);

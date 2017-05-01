--
--Goweil LT Master
--
--TyKonKet - fcelsa (Team FSI Modding)
--
--01/05/2017

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

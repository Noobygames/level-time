-- Klassenfarbe am Spielerrahmen (classColorPlayerFrame, Classic-Rahmen): eigener Namenshintergrund in Klassenfarbe
wow.state.class = "MAGE"
wow.login()
expectTrue("Schalter im Classic-Rahmen", addon.ClassColors.CanColorPlayerFrame())
expect("aus: keine Textur", addon.ClassColors.PlayerBackground(), nil)

addon.Set("classColorPlayerFrame", true)
local background = addon.ClassColors.PlayerBackground()
expectTrue("Hintergrund sichtbar", background:IsShown())
expectNear("Klassenfarbe", (background:GetVertexColor()), RAID_CLASS_COLORS.MAGE.r)

wow.state.class = wow.SECRET
addon.ApplySettings()
expect("geheime Klasse: versteckt", background:IsShown(), false)
wow.state.class = "MAGE"
addon.Set("classColorPlayerFrame", false)
expect("aus: versteckt", background:IsShown(), false)

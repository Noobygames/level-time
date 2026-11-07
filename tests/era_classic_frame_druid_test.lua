-- Druiden-Manaleiste (druidManaBar, Classic): nur in Gestalten ohne Mana, Werte aus UnitPower(Mana), geheim = aus
local powerType = 0
function UnitPowerType() return powerType end
wow.state.class = "DRUID"
wow.state.power, wow.state.powerMax = 300, 1000
wow.login()
expectTrue("Druide im Classic-Rahmen", addon.DruidManaBar.IsAvailable())
expect("aus: keine Leiste", addon.DruidManaBar.Bar(), nil)

addon.Set("druidManaBar", true)
local bar = addon.DruidManaBar.Bar()
expect("Normalgestalt: versteckt", bar:IsShown(), false)
powerType = 1  -- Wut (Bär)
wow.fire("UPDATE_SHAPESHIFT_FORM")
expectTrue("Bärengestalt: sichtbar", bar:IsShown())
expect("Mana-Wert", bar.text:GetText(), "300 / 1000")
wow.state.power = 450
wow.fire("UNIT_POWER_UPDATE", "player", "MANA")
expect("aktualisiert", bar.text:GetText(), "450 / 1000")
wow.state.power = wow.SECRET
wow.fire("UNIT_POWER_UPDATE", "player", "MANA")
expect("geheim: versteckt", bar:IsShown(), false)
wow.state.power = 450
addon.Set("druidManaBar", false)
expect("aus: versteckt", bar:IsShown(), false)

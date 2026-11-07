-- Seltene Gegner melden (Roadmap 348): Plakette, Ziel oder Mouseover mit rare/rareelite, je Name einmal pro Session,
-- optional Taskleiste blinken; geheime Werte und tote Gegner melden nichts.
local L = addon.L
local Alerts = addon.Alerts

wow.login({ level = 30 })
addon.Set("alertStyle", "banner")
wow.state.units.nameplate1 = { name = "Mor'Ladim", classification = "rareelite" }
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
expect("aus: nichts", LevelTimerNotice:IsShown(), false)

addon.Set("alertRareSpotted", true)
addon.Set("alertRareFlash", true)
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
expect("Rare gemeldet", LevelTimerNotice.title:GetText(), string.format(L.ALERT_RARE_SPOTTED, "Mor'Ladim"))
expect("Taskleiste blinkt", wow.flashes, 1)

-- Gleicher Name: nur einmal
Alerts.Clear()
wow.state.units.target = { name = "Mor'Ladim", classification = "rareelite" }
wow.fire("PLAYER_TARGET_CHANGED")
expect("nur einmal", LevelTimerNotice:IsShown(), false)

-- Tot, normal, geheim: nichts
wow.state.units.mouseover = { name = "Toter Rare", classification = "rare", dead = true }
wow.fire("UPDATE_MOUSEOVER_UNIT")
wow.state.units.mouseover = { name = "Wolf", classification = "normal" }
wow.fire("UPDATE_MOUSEOVER_UNIT")
wow.state.units.mouseover = { name = "Geheim", classification = wow.SECRET }
wow.fire("UPDATE_MOUSEOVER_UNIT")
expect("nichts gemeldet", LevelTimerNotice:IsShown(), false)

-- Mouseover mit neuem Rare
wow.state.units.mouseover = { name = "Fedfennel", classification = "rare" }
wow.fire("UPDATE_MOUSEOVER_UNIT")
expect("Mouseover gemeldet", LevelTimerNotice.title:GetText(), string.format(L.ALERT_RARE_SPOTTED, "Fedfennel"))

-- Neue Session: wieder melden
Alerts.Clear()
wow.login({ level = 30 })
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
expect("neue Session", LevelTimerNotice.title:GetText(), string.format(L.ALERT_RARE_SPOTTED, "Mor'Ladim"))
expect("Fehler?", #wow.errors, 0)

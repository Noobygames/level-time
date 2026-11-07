-- Elite- und Rare-Kills: Einstufung aus Ziel, Maus oder Namensplakette, beim Kill per Name nachgeschlagen.
local Stats = addon.Stats

wow.login({ level = 30 })

local function see(unit, name, classification)
  wow.state.units[unit] = { name = name, classification = classification }
end
local function kill(name)
  wow.fire("CHAT_MSG_COMBAT_XP_GAIN", name .. " stirbt, Ihr bekommt 100 Erfahrung.")
end

see("target", "Hogger", "elite")
wow.fire("PLAYER_TARGET_CHANGED")
see("mouseover", "Mor'Ladim", "rareelite")
wow.fire("UPDATE_MOUSEOVER_UNIT")
see("nameplate1", "Morgan der Sammler", "rare")
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
wow.state.units.nameplate2 = { name = "Spieler", classification = "elite", isPlayer = true }
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate2")

kill("Hogger")
kill("Mor'Ladim")
kill("Morgan der Sammler")
kill("Wolf")  -- nie gesehen: normal

expect("PvE-Kills gesamt", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 4)
expect("Elite (inkl. Rare-Elite)", Stats.Get(Stats.LEVEL, Stats.ELITE_KILLS), 2)
expect("Rare (inkl. Rare-Elite)", Stats.Get(Stats.SESSION, Stats.RARE_KILLS), 2)

local kills = addon.character.killLog
expect("Einstufung im Journal", kills[1].classification, "elite")
expect("Rare-Elite im Journal", kills[2].classification, "rareelite")
expect("unbekannte Einstufung", kills[4].classification, nil)
expect("Spieler werden nicht eingestuft", addon.Classification.Of("Spieler"), nil)

addon.Set("showSpecialKills", true)
SlashCmdList.LEVELTIMER("history")
expectTrue("Kill-Liste rendert", wow.click("Kills"))

-- Geheime Werte (Retail/Forever): weder Fehler noch Einträge
wow.errors = {}
wow.state.units.mouseover = { name = wow.SECRET, classification = "elite" }
wow.fire("UPDATE_MOUSEOVER_UNIT")
wow.state.units.mouseover = { name = "Geheimer Elite", classification = wow.SECRET }
wow.fire("UPDATE_MOUSEOVER_UNIT")
wow.state.units.mouseover = { name = "Geheimer Spieler", classification = "elite", isPlayer = wow.SECRET }
wow.fire("UPDATE_MOUSEOVER_UNIT")
expect("geheime Werte ohne Fehler", #wow.errors, 0)
expect("geheimer Name nicht gemerkt", addon.Classification.Of("Geheimer Elite"), nil)
expect("geheimer Spielerstatus nicht gemerkt", addon.Classification.Of("Geheimer Spieler"), nil)
expect("geheime GUID ohne zoneUID", addon.InstanceCopy.ZoneUIDOf(wow.SECRET), nil)

-- Roadmap 187: gleichnamige Gegner; steht der getötete tot im Ziel, zählt dessen Einstufung
see("nameplate3", "Defias-Schläger", "elite")
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate3")
wow.state.units.target = { name = "Defias-Schläger", classification = "normal", dead = true }
local elitesBefore = Stats.Get(Stats.LEVEL, Stats.ELITE_KILLS)
kill("Defias-Schläger")
expect("totes Ziel entscheidet", Stats.Get(Stats.LEVEL, Stats.ELITE_KILLS), elitesBefore)
wow.state.units.target = nil
kill("Defias-Schläger")
expect("ohne Ziel die zuletzt gesehene", Stats.Get(Stats.LEVEL, Stats.ELITE_KILLS), elitesBefore + 1)
-- Geheimes Ziel: kein Fehler, Rückfall auf den Namen
wow.state.units.target = { name = wow.SECRET, classification = "normal", dead = true }
kill("Defias-Schläger")
expect("geheimes Ziel: Name entscheidet", Stats.Get(Stats.LEVEL, Stats.ELITE_KILLS), elitesBefore + 2)
expect("keine Fehler", #wow.errors, 0)

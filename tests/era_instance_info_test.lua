-- Roadmap 460: Instanz-Stammdaten (Reset, Gruppengröße, Level-Bereich) aus ns.InstanceData in Classic Era
local Info = addon.InstanceInfo
local L = addon.L

local function row(setting)
  for _, line in ipairs(addon.STAT_LINES) do
    if line.setting == setting then return line.rows[1].value() end
  end
end

-- Wehklagen (43): Normal 5 Spieler ohne Reset, Level 15-28; Dire Maul (429): Flügel vereint
local wailing = Info.Get(43, 1)
expect("Wehklagen Spieler", wailing.players, 5)
expect("Wehklagen kein Reset", wailing.resetDays, 0)
expect("Wehklagen Level", wailing.minLevel .. "-" .. wailing.maxLevel, "15-28")
expect("Dire Maul Level vereint", Info.Get(429, 1).minLevel .. "-" .. Info.Get(429, 1).maxLevel, "54-60")
expect("Molten Core 40 Spieler wöchentlich", Info.Get(409, 9).players .. "/" .. Info.Get(409, 9).resetDays, "40/7")
expect("unbekannte Schwierigkeit: kleinste ID", Info.Get(43, 99).players, 5)
expect("unbekannte Karte", Info.Get(1, 1), nil)
expectTrue("Era liefert Level", Info.HasLevels())
expect("Reset täglich", Info.ResetText(1), L.INSTANCE_RESET_DAILY)
expect("Reset 3 Tage", Info.ResetText(3), string.format(L.INSTANCE_RESET_DAYS, 3))

-- passende Dungeons: Level 20 enthält Wehklagen, keine Raids
local ids = {}
for _, entry in ipairs(Info.ForLevel(20)) do ids[entry.mapID] = true end
expectTrue("Level 20: Wehklagen", ids[43])
expect("Level 20: kein Molten Core", ids[409], nil)
expect("Level 20: Reihenfolge nach Mindestlevel", Info.ForLevel(20)[1].minLevel >= Info.ForLevel(20)[2].minLevel, true)

-- Lauf speichert Karte und Schwierigkeit, Statistikzeilen und Historie lesen sie
wow.login({ level = 20, xp = 0, xpMax = 100000 })
-- Instanzname zur Karten-ID (der Stub kennt GetRealZoneText nicht, andere Szenarien fallen auf GetZoneText zurück)
function GetRealZoneText(mapID)
  if not mapID then return GetZoneText() end
  return mapID == 43 and "Wailing Caverns" or "Instanz " .. mapID
end
wow.state.instance = { name = "Wailing Caverns", type = "party", difficulty = 1, mapID = 43, maxPlayers = 5 }
wow.fire("PLAYER_ENTERING_WORLD")
local run = addon.Instances.GetCurrentRun()
expect("Lauf Karte", run.mapID, 43)
expect("Lauf Schwierigkeit", run.difficultyID, 1)
expect("Zeile Instanz-Daten", row("showInstanceInfo"),
  string.format("%s, %s, %s", string.format(L.INSTANCE_PLAYERS, 5), string.format(L.INSTANCE_RESET, L.INSTANCE_RESET_NONE),
    string.format(L.INSTANCE_LEVELS, 15, 28)))
local fit = row("showInstanceFit")
expectTrue("Zeile passende Dungeons: drei Namen mit Bereich", select(2, fit:gsub("%(%d+%-%d+%)", "")) == 3)
expectTrue("Zeile passende Dungeons: Rest als Zahl", fit:find(string.format(L.INSTANCE_FIT_MORE, #Info.ForLevel(20) - 3), 1, true) ~= nil)

local entries = addon.History.GetInstanceLog(addon.characterKey)
expect("Historie: laufender Lauf mit Karte", entries[1].mapID, 43)

wow.state.instance = nil
wow.fire("PLAYER_ENTERING_WORLD")
expectTrue("angehaltener Lauf zeigt weiter seine Daten", row("showInstanceInfo") ~= addon.Format.NO_VALUE)
addon.character.currentRun = nil
expect("Zeile ohne Lauf", row("showInstanceInfo"), addon.Format.NO_VALUE)

-- Roadmap 460: Retail liefert Reset und Gruppengröße, aber keine Level-Bereiche
local Info = addon.InstanceInfo

local function infoRow()
  for _, line in ipairs(addon.STAT_LINES) do
    if line.setting == "showInstanceFit" then return line end
  end
end

expect("Retail ohne Level-Spalten", Info.HasLevels(), false)
expect("Retail: Zeile passende Dungeons nicht verfügbar", infoRow().available(), false)
expect("Retail: keine Dungeons zum Level", #Info.ForLevel(20), 0)

-- Wehklagen (43): Normal 5 Spieler, kein Reset; ohne Level
local normal = Info.Get(43, 1)
expect("Retail Wehklagen Spieler", normal.players, 5)
expect("Retail Wehklagen kein Reset", normal.resetDays, 0)
expect("Retail ohne Level", normal.minLevel, nil)
expect("Retail Beschreibung ohne Level", Info.Describe(43, 1),
  string.format("%s, %s", string.format(addon.L.INSTANCE_PLAYERS, 5),
    string.format(addon.L.INSTANCE_RESET, addon.L.INSTANCE_RESET_NONE)))

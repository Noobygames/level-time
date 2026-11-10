-- Roadmap 460: WoW Forever liefert Reset und Gruppengröße, aber keine Level-Bereiche
local Info = addon.InstanceInfo

local function infoRow()
  for _, line in ipairs(addon.STAT_LINES) do
    if line.setting == "showInstanceFit" then return line end
  end
end

expect("Forever ohne Level-Spalten", Info.HasLevels(), false)
expect("Forever: Zeile passende Dungeons nicht verfügbar", infoRow().available(), false)
expect("Forever: keine Dungeons zum Level", #Info.ForLevel(20), 0)

-- Wehklagen (43): Normal 5 Spieler, kein Reset; ohne Level
local normal = Info.Get(43, 1)
expect("Forever Wehklagen Spieler", normal.players, 5)
expect("Forever Wehklagen kein Reset", normal.resetDays, 0)
expect("Forever ohne Level", normal.minLevel, nil)
expect("Forever Beschreibung ohne Level", Info.Describe(43, 1),
  string.format("%s, %s", string.format(addon.L.INSTANCE_PLAYERS, 5),
    string.format(addon.L.INSTANCE_RESET, addon.L.INSTANCE_RESET_NONE)))

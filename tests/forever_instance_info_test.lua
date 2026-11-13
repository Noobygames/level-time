-- Roadmap 460: WoW Forever liefert Reset und Gruppengröße aus den Spieldaten, Level-Bereiche aus ns.InstanceGuide
local Info = addon.InstanceInfo

local function infoRow()
  for _, line in ipairs(addon.STAT_LINES) do
    if line.setting == "showInstanceFit" then return line end
  end
end

expect("Forever mit Level-Bereichen", Info.HasLevels(), true)
expect("Forever: Zeile passende Dungeons verfügbar", infoRow().available(), true)
expectTrue("Forever: Dungeons zum Level", #Info.ForLevel(20) > 0)

-- Wehklagen (43): Normal 5 Spieler, kein Reset, Level 15-24
local normal = Info.Get(43, 1)
expect("Forever Wehklagen Spieler", normal.players, 5)
expect("Forever Wehklagen kein Reset", normal.resetDays, 0)
expect("Forever Level", normal.minLevel, 15)
expect("Forever Beschreibung mit Level", Info.Describe(43, 1),
  string.format("%s, %s, %s", string.format(addon.L.INSTANCE_PLAYERS, 5),
    string.format(addon.L.INSTANCE_RESET, addon.L.INSTANCE_RESET_NONE), string.format(addon.L.INSTANCE_LEVELS, 15, 24)))

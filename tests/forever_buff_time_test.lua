-- Zeit mit und ohne Buff (Roadmap 485): "Satt" und "Gut erholt" (Schlafsack, Forever) je Level, Session und in der
-- Historie; AFK zählt nicht als aktive Zeit, gesperrte Auren behalten den letzten Zustand.
local TimeBreakdown, Stats = addon.TimeBreakdown, addon.Stats
local WELL_RESTED = 429959

wow.login({ level = 10, playedSeconds = 0 })

local function run(seconds)
  for _ = 1, seconds do TimeBreakdown.Update(1) end
end
local function seconds(counter, scope)
  return TimeBreakdown.GetSeconds(scope or Stats.LEVEL, counter)
end

-- 20 s ohne Buff, dann 30 s satt und gut erholt
run(20)
expect("ohne Buff nichts", seconds(Stats.WELL_FED_SECONDS), 0)
wow.state.buffs = { "Satt", { name = "Gut erholt", spellId = WELL_RESTED } }
TimeBreakdown.Update(1)       -- Buff erkannt; die Sekunde davor zählt noch ohne
run(30)
expect("Satt 30 s", seconds(Stats.WELL_FED_SECONDS), 30)
expect("Gut erholt 30 s", seconds(Stats.WELL_RESTED_SECONDS), 30)
expect("Session zählt mit", seconds(Stats.WELL_FED_SECONDS, Stats.SESSION), 30)

-- Gesperrte Auren (Kampf): Zustand bleibt
wow.state.aurasSecret = true
addon.Auras.Invalidate()
run(10)
expect("gesperrt: zählt weiter", seconds(Stats.WELL_FED_SECONDS), 40)
wow.state.aurasSecret = false
addon.Auras.Invalidate()

-- AFK ist keine aktive Zeit
wow.state.afk = true
TimeBreakdown.Update(1)
run(15)
wow.state.afk = false
TimeBreakdown.Update(1)
expect("AFK zählt nicht", seconds(Stats.WELL_FED_SECONDS), 41)

-- "Ohne" = aktive Zeit minus "mit"
wow.fire("TIME_PLAYED_MSG", 1000, 100)
local afk = seconds(Stats.AFK_SECONDS)
expect("ohne Satt", TimeBreakdown.WithoutBuff(Stats.LEVEL, Stats.WELL_FED_SECONDS), 100 - afk - 41)

-- Anzeige: zwei Zeilen je Buff
addon.Set("showWellFedTime", true)
addon.Set("showWellRestedTime", true)
local labels = {}
for _, line in ipairs(addon.STAT_LINES) do
  if line.setting == "showWellFedTime" or line.setting == "showWellRestedTime" then
    expectTrue(line.setting .. " verfügbar", line.available == nil or line.available())
    for _, row in ipairs(line.rows) do
      labels[#labels + 1] = row.label
      expectTrue(row.label .. " hat Wert", type(row.value(Stats.LEVEL)) == "string")
    end
  end
end
expect("Zeilen", table.concat(labels, ","), "ROW_WELL_FED,ROW_NOT_WELL_FED,ROW_WELL_RESTED,ROW_NOT_WELL_RESTED")

-- Level-Up: laufende Buff-Zeit landet in der Historie
run(5)
wow.levelUp(11)
local record = addon.character.levelHistory[#addon.character.levelHistory]
expect("Historie: Satt", record.counters.wellFedSeconds, 46)
expect("Historie: Gut erholt", record.counters.wellRestedSeconds, 46)
expect("neues Level leer", seconds(Stats.WELL_FED_SECONDS), 0)
expect("keine Fehler", #wow.errors, 0)

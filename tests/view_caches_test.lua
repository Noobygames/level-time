-- Roadmap 355: Ansichten rechnen nur bei Änderungen. Top-Gegner/Todesursachen zählen neue Einträge dazu, Geld nach
-- Zeitraum liest nur die Tage des Zeitraums, Vergleich merkt sich die Zeilen anderer Charaktere, Todeskarte hat einen
-- Index je Karte, Recap liest nur die Session. Ergebnisse wie die vollständige Berechnung.
local Journal = addon.Journal
local Analysis = addon.Analysis
local L = addon.L

wow.state.clock = os.time({ year = 2026, month = 10, day = 14, hour = 12 })
wow.login({ level = 10, xp = 0, xpMax = 1000 })
local key = addon.characterKey

---------------------------------------------------------------------------
-- Top-Gegner: gezählt wie früher (alles zählen, alles sortieren)
---------------------------------------------------------------------------
local function naiveTop(entries, nameOf)
  local counts = {}
  for _, entry in ipairs(entries) do
    local name = nameOf(entry)
    counts[name] = (counts[name] or 0) + 1
  end
  local items = {}
  for name, count in pairs(counts) do table.insert(items, { label = name, value = count }) end
  table.sort(items, function(a, b)
    if a.value ~= b.value then return a.value > b.value end
    return a.label < b.label
  end)
  while #items > 10 do table.remove(items) end
  return items
end

local function sameTop(actual, expected)
  if #actual ~= #expected then return false end
  for i, item in ipairs(expected) do
    if actual[i].label ~= item.label or actual[i].value ~= item.value then return false end
  end
  return true
end

math.randomseed(11)
local NAMES = { "Wolf", "Eber", "Bär", "Murloc", "Kobold", "Ghul", "Defias", "Spinne", "Harpyie", "Gnoll", "Oger",
  "Troll", "Zentaur" }
local wrong = { count = 0 }
for step = 1, 60 do
  for _ = 1, math.random(5) do
    Journal.AddKill(Journal.PVE, math.random(8) > 1 and NAMES[math.random(#NAMES)] or nil)
  end
  if step == 30 then addon.Set("language", "enUS") end
  local expected = naiveTop(Journal.GetEntries(key, "killLog"), function(kill) return kill.name or L.UNKNOWN_NAME end)
  if not sameTop(Analysis.TopKills(key), expected) then wrong.count = wrong.count + 1 end
end
addon.Set("language", "deDE")
expect("Top-Gegner wie vollständig gezählt", wrong.count, 0)
local top = Analysis.TopKills(key)
expectTrue("Text mit Anteil", top[1].text:find("%(") ~= nil)

-- Todesursachen: nachgetragene Ursache zählt um
local death = Journal.AddDeath({})
expect("unbekannte Ursache", Analysis.DeathCauses(key)[1].label, L.CAUSE_UNKNOWN)
Journal.SetDeathCause(death, { killer = "Hogger" })
expect("nachgetragen", Analysis.DeathCauses(key)[1].label, "Hogger")

---------------------------------------------------------------------------
-- Geld: nur Tage des Zeitraums, Ergebnis wie der Durchlauf über alle Tage
---------------------------------------------------------------------------
local Money, Daily = addon.Money, addon.Daily
local daily = addon.character.dailyStats
for offset = -400, 0 do
  local day = Daily.DayKey(Daily.AddDays(wow.state.clock, offset))
  daily[day] = { seconds = 60, kills = 0, deaths = 0, xp = 0, moneyIn = 100 + offset, moneyOut = 1 }
end
local function naive(period)
  local startKey = Daily.DayKey(Money.PeriodStart(period, wow.state.clock))
  local sum = 0
  for dayKey, entry in pairs(Daily.GetStats(key)) do
    if dayKey >= startKey then sum = sum + (entry.moneyIn or 0) end
  end
  return sum
end
local records = Money.GetPeriodRecords(key)
expect("heute", records[1].moneyIn, naive(Money.DAY))
expect("Woche", records[2].moneyIn, naive(Money.WEEK))
expect("Monat", records[3].moneyIn, naive(Money.MONTH))
-- Am nächsten Tag neue Zeiträume
wow.advance(24 * 3600)
daily[Daily.DayKey(wow.state.clock)] = { seconds = 0, kills = 0, deaths = 0, xp = 0, moneyIn = 5000, moneyOut = 0 }
records = Money.GetPeriodRecords(key)
expect("nächster Tag: heute", records[1].moneyIn, naive(Money.DAY))
expect("nächster Tag: Monat", records[3].moneyIn, naive(Money.MONTH))

---------------------------------------------------------------------------
-- Vergleich: Zeilen anderer Charaktere gemerkt, neu bei geänderter Level-Historie
---------------------------------------------------------------------------
LevelTimerStatsDB.characters["Alt-Testrealm"] = {
  schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = "Alt", realm = "Testrealm", class = "MAGE",
  currentLevel = { level = 3, counters = {} }, levelHistory = { [1] = { level = 1, seconds = 100, counters = {} } },
  sessionHistory = {}, killLog = {}, deathLog = {},
}
local function altRow()
  for _, row in ipairs(addon.History.GetCharacterComparison()) do
    if row.key == "Alt-Testrealm" then return row end
  end
end
local first = altRow()
expect("gemerkt", altRow(), first)
LevelTimerStatsDB.characters["Alt-Testrealm"].levelHistory[2] = { level = 2, seconds = 300, counters = {} }
expect("neu nach weiterem Level", altRow().averageLevelSeconds, 200)

---------------------------------------------------------------------------
-- Recap: nur Einträge der Session, auch bei langem Eingang
---------------------------------------------------------------------------
for _ = 1, 50 do Journal.AddLoot({ link = "[Alt]", quality = 4 }) end
wow.advance(10)
SlashCmdList.LEVELTIMER("newsession")
wow.advance(1)
Journal.AddLoot({ link = "[Neu]", quality = 3 })
local function recapRow(label)
  for _, line in ipairs(addon.RecapWindow.BuildRows()) do
    if line[1] == label then return line[2] end
  end
end
expect("nur Beute der Session", recapRow(L.RECAP_BEST_LOOT), "[Neu]")

-- Roadmap 213: Die offene Historie wertet jede Sekunde nur aus, was sich geändert haben kann; Anzeige wie bisher.
local L = addon.L
local History = addon.History
local Journal = addon.Journal

wow.login({ level = 20, xp = 0, xpMax = 1000 })
wow.fire("TIME_PLAYED_MSG", 5000, 100)
for i = 1, 30 do
  wow.fire("CHAT_MSG_COMBAT_XP_GAIN", (i % 3 == 0 and "Eber" or "Wolf") .. " stirbt, Ihr bekommt 10 Erfahrung.")
end

-- Ranglisten über das Journal: nur bei neuem Journal-Stand neu ausgewertet
local reads = 0
local getEntries = Journal.GetEntries
Journal.GetEntries = function(...)
  reads = reads + 1
  return getEntries(...)
end
SlashCmdList.LEVELTIMER("history")
wow.click(L.HISTORY_TAB_CHARTS)
expectTrue("Top-Gegner", wow.click(L.CHART_TOP_KILLS))
local afterOpen = reads
wow.update(1.1)
wow.update(1.1)
wow.update(1.1)
expect("ohne neue Einträge keine Auswertung", reads, afterOpen)
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Bär stirbt, Ihr bekommt 10 Erfahrung.")
wow.update(1.1)
expectTrue("neuer Kill: neu ausgewertet", reads > afterOpen)
local afterKill = reads
addon.Set("language", "enUS")
wow.update(1.1)
expectTrue("Sprachwechsel: neu ausgewertet", reads > afterKill)
addon.Set("language", "deDE")
Journal.GetEntries = getEntries

-- Laufende Zeile der Level-Übersicht zählt weiter jede Sekunde, auch sortiert
wow.click(L.HISTORY_GROUP_LEVELS)
wow.click(L.HISTORY_TAB_LEVELS)
local function currentSeconds()
  local table = wow.shownTable()
  local first = table:GetVisibleRecords()[1]
  return first and first.isCurrent and first.seconds
end
local before = currentSeconds()
wow.advance(1)
wow.update(1.1)
expectNear("laufendes Level zählt weiter", currentSeconds(), before + 1)
wow.shownTable():SortBy(1)
wow.advance(1)
wow.update(1.1)
local found
for _, record in ipairs(wow.shownTable():GetVisibleRecords()) do
  if record.isCurrent then found = record.seconds end
end
expectNear("sortiert: laufendes Level zählt weiter", found, before + 2)

-- Instanz-Durchgänge: keine Kopie aller Läufe je Aufruf, der laufende Lauf ist aktuell
addon.character.instanceLog = {}
for i = 1, 3 do
  addon.character.instanceLog[i] = { time = time() - 1000 * i, name = "Alt " .. i, seconds = 600, level = 18 }
end
wow.state.instance = { name = "Die Todesminen", type = "party" }
wow.fire("PLAYER_ENTERING_WORLD")
local first = History.GetInstanceLog(addon.characterKey)
wow.advance(30)
local second = History.GetInstanceLog(addon.characterKey)
expect("dieselbe Liste", first, second)
expect("laufender Lauf vorne", second[1].isCurrent, true)
expect("ältere Läufe dahinter", #second, 4)
expectTrue("laufende Zeit aktuell", second[1].seconds >= 30)
local run = addon.character.currentRun
addon.character.currentRun = nil
expect("ohne Lauf kein Platzhalter", History.GetInstanceLog(addon.characterKey)[1].isCurrent, nil)
addon.character.currentRun = run

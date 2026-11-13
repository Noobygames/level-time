-- Erfassungsquote und Teil-Level (Coverage.lua): erfasste Zeit / /played, Lücken und zurückgespielte Spielstände
local Coverage = addon.Coverage
local L = addon.L

local function printedContains(text)
  for _, line in ipairs(wow.printed) do
    if line:find(text, 1, true) then return true end
  end
  return false
end

local function played(total, onLevel)
  wow.fire("TIME_PLAYED_MSG", total, onLevel)
end

-- Erster Login eines neuen Charakters: kaum Zeit vor dem Addon, Level nicht teilweise
wow.login({ level = 10 })
played(20, 20)
expect("neues Level nicht teilweise", addon.character.currentLevel.partial, nil)
wow.advance(1000)
expectNear("fast alles erfasst", Coverage.Get(addon.characterKey), 1000 / 1020, 0.001)
expectTrue("grün ab 95 %", Coverage.Text(Coverage.Get(addon.characterKey)):find("40ff40", 1, true) ~= nil)
played(1020, 1020)  -- weitere Antworten (z.B. /played) werten nichts neu aus
expect("zweite Antwort ändert nichts", addon.character.coverage.untracked, 20)

-- Ohne Addon gespielt: Lücke über 45 s zählt als nicht erfasst und macht das Level zum Teil-Level
wow.logout()
local lastPlayed = addon.character.coverage.lastPlayed
expectNear("Stand beim Logout", lastPlayed, 1020, 0.001)
wow.printed = {}
wow.login({ level = 10 })
played(lastPlayed + 600, lastPlayed + 600)
expectTrue("Chatzeile zur Lücke", printedContains(string.format(L.COVERAGE_GAP, addon.Format.Duration(600))))
expect("Level jetzt teilweise", addon.character.currentLevel.partial, true)
expectNear("Quote nach der Lücke", Coverage.Get(addon.characterKey), 1000 / 1620, 0.001)
expectTrue("rot unter 90 %", Coverage.Text(Coverage.Get(addon.characterKey)):find("ff4040", 1, true) ~= nil)
expectTrue("gelb ab 90 %", Coverage.Text(0.92):find("ffd100", 1, true) ~= nil)

-- Teil-Level im Level-Eintrag, aber nicht als Bestzeit
wow.levelUp(11, 1200)
expect("Eintrag teilweise", addon.character.levelHistory[10].partial, true)
expect("neues Level wieder vollständig", addon.character.currentLevel.partial, nil)
expectTrue("Zeit bleibt im Lauf", addon.Runs.LevelTimes(addon.characterKey)[10] ~= nil)
expect("aber keine Bestzeit", addon.Runs.LevelTimes(addon.characterKey, true)[10], nil)

-- Kurze Abweichung (Hochrechnung, /reload) ist keine Lücke
wow.logout()
lastPlayed = addon.character.coverage.lastPlayed
wow.printed = {}
wow.login({ level = 11 })
played(lastPlayed + 10, 10)
expect("keine Meldung bei kleiner Abweichung", #wow.printed, 0)
expect("Level 11 vollständig", addon.character.currentLevel.partial, nil)

-- Älterer Spielstand: /played deutlich kleiner
wow.logout()
lastPlayed = addon.character.coverage.lastPlayed
wow.login({ level = 11 })
played(lastPlayed - 300, 5)
expectTrue("Chatzeile zum alten Spielstand", printedContains(string.format(L.COVERAGE_ROLLBACK, addon.Format.Duration(300))))
expect("gezählt", addon.character.coverage.rollbacks, 1)

-- Vergleich und Läufe zeigen die Quote
local comparison = addon.History.GetCharacterComparison()[1]
expectTrue("Vergleich hat Quote", comparison.coverage ~= nil)
expectTrue("Lauf hat Quote", addon.Runs.Get(addon.characterKey).coverage ~= nil)
expect("ohne Stand kein Wert", Coverage.Text(nil), "-")

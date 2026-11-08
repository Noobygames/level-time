-- Historie-Fenster: Lazy Load in langen Listen und Graphen rendern ohne Fehler.
local Journal = addon.Journal

wow.login({ level = 20, playedSeconds = 600 })

for i = 1, 1000 do
  Journal.AddKill(Journal.PVE, "Gegner " .. i)
end

SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Kills", wow.click("Kills"))

-- Tabelle mit Mausrad: nur die Kill-Tabelle ist sichtbar und scrollbar
local killTable = wow.shownTable()
expectTrue("Kill-Tabelle gefunden", killTable ~= nil)
expect("startet oben", killTable.offset, 0)

killTable._scripts.OnMouseWheel(killTable, -1)
expect("Mausrad scrollt drei Zeilen", killTable.offset, 3)
killTable._scripts.OnMouseWheel(killTable, 10)
expect("nicht über den Anfang hinaus", killTable.offset, 0)
for _ = 1, 1000 do
  killTable._scripts.OnMouseWheel(killTable, -1)
end
expectTrue("bis zum Ende scrollbar, nicht darüber hinaus", killTable.offset > 900 and killTable.offset < 1000)

-- Wechsel der Ansicht setzt den Bildlauf zurück
expectTrue("Reiter Tode", wow.click("Tode"))
expectTrue("zurück zu Kills", wow.click("Kills"))
expect("Bildlauf zurückgesetzt", killTable.offset, 0)

-- Graphen: alle Diagramme anklickbar
expectTrue("Reiter Graphen", wow.click("Graphen"))
for _, chart in ipairs({ "Zeit je Level", "XP/h je Level", "Kills je Tag", "Häufigste Gegner", "Todesursachen", "XP/h je Zone",
  "Spielzeit je Tag", "Spielzeit je Woche", "XP der Session" }) do
  expectTrue("Diagramm " .. chart, wow.click(chart))
end

-- Leere Daten: anderer Charakter ohne Einträge
wow.logout()
wow.login({ name = "Neuling", level = 1 })
SlashCmdList.LEVELTIMER("history")
SlashCmdList.LEVELTIMER("history")
expectTrue("leere Rangliste", wow.click("Todesursachen"))

-- Reitergruppen: Unterreiter nur in der gewählten Gruppe sichtbar
local function tabWithLabel(text)
  return wow.findFrame(function(frame)
    local label = rawget(frame, "label")
    return label and label._text == text
  end)
end
expectTrue("Gruppe Level", wow.click("Level"))
expect("Unterreiter Timeline sichtbar", tabWithLabel("Verlauf"):IsShown(), true)
expect("Journal-Unterreiter versteckt", tabWithLabel("Kills"):IsShown(), false)
expectTrue("Sessions ohne Unterreiter", wow.click("Sessions"))
expect("Timeline versteckt", tabWithLabel("Verlauf"):IsShown(), false)

-- Zuletzt gewählter Reiter wird gemerkt (Einstellung historyTab)
SlashCmdList.LEVELTIMER("history")
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Sessions", wow.click(addon.L.HISTORY_TAB_SESSIONS))
expect("Reiter gemerkt", LevelTimerDB.historyTab, "HISTORY_TAB_SESSIONS")

-- Journal-Archiv lädt erst bei Bedarf: kleiner Eingang lädt beim Login nichts, Level-Tabellen auch nicht, erst die
-- Journal-Tabellen. Lässt sich das Archiv-Addon nicht laden, bleibt alles im Eingang und nichts bricht.
local Journal, Archive = addon.Journal, addon.JournalArchive
local ARCHIVE = Archive.ADDON

wow.state.addOnsUnavailable = { [ARCHIVE] = true }
wow.login({ level = 10 })
for i = 1, 3 do Journal.AddKill(Journal.PVE, "Ratte " .. i) end
SlashCmdList.LEVELTIMER("history")
expect("Archiv fehlt: Eingang reicht", #Journal.GetEntries(addon.characterKey, "killLog"), 3)
expectTrue("Reiter Kills ohne Archiv", wow.click("Kills"))
expect("nicht geladen", Archive.IsLoaded(), false)

-- Addon wieder da (nächste Sitzung): erst die Journal-Tabelle lädt es. Fenster zu und Level-Reiter gemerkt, wie
-- nach einem echten /reload (Frames überleben im Stub)
expectTrue("Reiter Level vor dem Neuladen", wow.click("Level"))
LevelTimerHistory:Hide()
wow.state.addOnsUnavailable = nil
wow.logout()
wow.login({ level = 10 })
expect("Login lädt bei kleinem Eingang nicht", wow.addOnLoads[ARCHIVE], nil)
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Level", wow.click("Level"))
expect("Level-Tabelle lädt nicht", wow.addOnLoads[ARCHIVE], nil)
expectTrue("Reiter Kills", wow.click("Kills"))
expect("Journal-Tabelle lädt", wow.addOnLoads[ARCHIVE], 1)
expect("Einträge noch da", #Journal.GetEntries(addon.characterKey, "killLog"), 3)
expect("keine Fehler", #wow.errors, 0)

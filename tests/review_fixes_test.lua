-- Funde aus dem Review (Roadmap 172-178, 183-185): Wertebereiche, geschützte Migration und Listener,
-- Einstellungs-Migrationen auch in Profilen, Profilnamen wie Befehlswörter, Schutz vor Zeit-Ausreißern.
LevelTimerDB = {
  schemaVersion = 1,
  fontSize = 32,
  showKills = false,
  profiles = { Alt = { fontSize = 8, showKills = true } },
}
LevelTimerStatsDB = { characters = { ["Kaputt-Realm"] = { schemaVersion = 1, killLog = "kaputt" } } }
local function clearErrors()
  for key in pairs(wow.errors) do wow.errors[key] = nil end
end

wow.login({ level = 10 })

-- 177: Migrationen 2 und 3 gelten auch für gespeicherte Profile
expect("Profil: Schrift zu Größe (frames, Migration 6)", LevelTimerDB.profiles.Alt.frames.main.scale, 0.5)
expect("Profil: Schrift entfernt", LevelTimerDB.profiles.Alt.fontSize, nil)
expect("Profil: Kills aufgeteilt", LevelTimerDB.profiles.Alt.showPveKills, true)
expect("Hauptwerte ebenfalls", LevelTimerDB.frames.main.scale, 2)

-- 173: ein defekter Charakter legt die anderen nicht lahm
expectTrue("eigener Charakter geladen", addon.character ~= nil)
expectTrue("Fehler gemeldet statt abgebrochen", #wow.errors > 0)
clearErrors()

-- 172: Wertebereiche und unendliche Zahlen beim Profil-Import
local clean = addon.Database.SanitizeSettings({
  scale = 0, bgAlpha = 9, reminderInterval = 0, splitListRows = -5, alertScale = 100, alertDuration = 0,
})
expect("Größe nach unten begrenzt", clean.frames.main.scale, 0.5)
expect("Deckkraft nach oben begrenzt", clean.bgAlpha, 1)
expect("Erinnerungsabstand mindestens 1", clean.reminderInterval, 1)
expect("Zeilenzahl mindestens 3", clean.splitListRows, 3)
expect("Einblendungsgröße begrenzt", clean.frames.alert.scale, 2)
expect("Anzeigedauer mindestens 1", clean.alertDuration, 1)
expect("unendlich verworfen", addon.Database.SanitizeSettings({ scale = math.huge }).frames, nil)
expect("NaN verworfen", addon.Database.SanitizeSettings({ scale = 0 / 0 }).frames, nil)

-- 178: Profilname, der wie ein Befehl beginnt, bleibt wählbar
addon.Profiles.SaveAs("save x")
SlashCmdList.LEVELTIMER("profile Default")
expect("zurück auf Default", addon.Profiles.GetActive(), "Default")
SlashCmdList.LEVELTIMER("profile save x")
expect("Profil 'save x' gewählt", addon.Profiles.GetActive(), "save x")

-- 174: ein fehlerhafter Listener stoppt die anderen nicht, die Zeit wird nicht doppelt gebucht
local reached = false
addon.Stats.OnIncrement(function() error("kaputt") end)
addon.Stats.OnIncrement(function() reached = true end)
addon.Stats.Increment(addon.Stats.QUESTS)
expectTrue("zweiter Listener läuft", reached)
expectTrue("Fehler gemeldet", #wow.errors > 0)
clearErrors()
wow.state.inCombat = true
addon.TimeBreakdown.Update(1)
for _ = 1, 5 do addon.TimeBreakdown.Update(1) end
wow.state.inCombat = false
addon.TimeBreakdown.Update(1)  -- Wechsel: bucht die Kampfzeit, ein Listener wirft
local combat = addon.Stats.Get(addon.Stats.LEVEL, addon.Stats.COMBAT_SECONDS)
addon.TimeBreakdown.Update(1)
addon.TimeBreakdown.Update(1)
expect("Kampfzeit nur einmal gebucht", addon.Stats.Get(addon.Stats.LEVEL, addon.Stats.COMBAT_SECONDS), combat)
clearErrors()

-- 176: Tod vor der ersten /played-Antwort löscht den letzten Wert nicht
addon.character.lastDeathPlayed = 5000
addon.PlayedTime.GetTotalSeconds = function() return nil end
wow.state.dead = true
wow.fire("PLAYER_DEAD")
expect("alter Wert bleibt", addon.character.lastDeathPlayed, 5000)

-- 185: Systemuhr zurückgestellt: eine "zukünftige" Session wird nicht fortgesetzt
local session = addon.character.currentSession
session.lastSeen = time() + 3600
addon.Session.StartNew()
expectTrue("neue Session begonnen", addon.character.currentSession ~= session)
clearErrors()  -- der Test-Listener aus 174 wirft bei jedem weiteren Zähler

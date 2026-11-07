-- Ein Positionssystem (Lib/Frames.lua): Migration der alten Schlüssel (auch in Profilen und der Stream-Sicherung),
-- Profile, Import, Zurücksetzen und Fixieren für alle Anzeigen.
LevelTimerDB = {
  schemaVersion = 5,
  scale = 1.3, pos = { "TOPLEFT", "TOPLEFT", 40, -50 },
  splitListPos = { "TOPLEFT", "TOPLEFT", 10, -10 },
  levelUpScale = 1.2, flightPos = { "TOP", "TOP", 0, -90 }, foodScale = 0.8,
  questItemPos = { "CENTER", "CENTER", 5, 5 },
  campPos = { "NIRGENDS", "TOP", 0, 0 },  -- kaputt: fällt weg
  profiles = { Stream = { alertScale = 1.6, alertPos = { "TOP", "TOP", 0, -300 } } },
  streamBackup = { scale = 0.9 },
}
wow.login({ level = 20 })
local Frames = addon.Frames
local db = LevelTimerDB

-- Migration v6: alle alten Schlüssel ziehen nach frames[id] um und sind danach weg
expect("Schema", db.schemaVersion, 6)
expect("Hauptfenster: Größe", db.frames.main.scale, 1.3)
expect("Hauptfenster: Position", db.frames.main.point .. " " .. db.frames.main.x, "TOPLEFT 40")
expect("Split-Liste: Position", db.frames.splitList.y, -10)
expect("Split-Liste: keine eigene Größe", db.frames.splitList.scale, nil)
expect("Level-Up: Größe", db.frames.levelUp.scale, 1.2)
expect("Flug: Position", db.frames.flight.y, -90)
expect("Essen: Größe", db.frames.food.scale, 0.8)
expect("Quest-Knöpfe: Position", db.frames.questItem.x, 5)
expect("kaputte Position verworfen", db.frames.camp, nil)
for _, key in ipairs({ "scale", "pos", "splitListPos", "levelUpScale", "flightPos", "foodScale", "questItemPos", "campPos" }) do
  expect("alter Schlüssel weg: " .. key, db[key], nil)
end
expect("Profil migriert", db.profiles.Stream.frames.alert.scale, 1.6)
expect("Profil: alter Schlüssel weg", db.profiles.Stream.alertPos, nil)
expect("Stream-Sicherung: alte Größe entfernt, kein frames", db.streamBackup.scale or db.streamBackup.frames, nil)

-- Angewendet: Größen und Positionen wie gespeichert
expect("Fenster in alter Größe", LevelTimerFrame:GetScale(), 1.3)
local anchor = LevelTimerFrame._points[1]
expect("Fenster an alter Stelle", anchor[1] .. " " .. anchor[4] .. " " .. anchor[5], "TOPLEFT 40 -50")
expect("Split-Liste folgt der Größe des Hauptfensters", LevelTimerSplits:GetScale(), 1.3)
expect("Level-Up-Fenster", LevelTimerLevelUp:GetScale(), 1.2)
expect("Essen", LevelTimerFood:GetScale(), 0.8)

-- Split-Liste ohne eigene Größe folgt dem Hauptfenster auch bei einer Änderung
Frames.SetScale("main", 1.5)
expect("Split-Liste folgt", LevelTimerSplits:GetScale(), 1.5)
Frames.SetScale("splitList", 0.7)
Frames.SetScale("main", 1)
expect("eigene Größe gewinnt", LevelTimerSplits:GetScale(), 0.7)

-- Größe wird begrenzt, ein Eintrag ohne Position bleibt am Standard
Frames.SetScale("flight", 9)
expect("Größe begrenzt", db.frames.flight.scale, Frames.MAX_SCALE)

-- Profilwechsel: Anzeigen springen an die Stelle des Profils
addon.Profiles.Switch("Stream")
expect("Profil: Einblendung in Profilgröße", LevelTimerAlert:GetScale(), 1.6)
expect("Profil: Karte folgt", LevelTimerNotice:GetScale(), 1.6)
addon.Profiles.Switch("Default")
expect("zurück: Hauptfenster-Größe", LevelTimerFrame:GetScale(), 1)

-- Import eines Profils aus einer älteren Version: alte Schlüssel ziehen um, Müll fällt weg
local name = addon.Profiles.Import(addon.Serializer.Encode("profile", { name = "Alt", settings = {
  campScale = 1.4, campPos = { "TOP", "TOP", 3, 4 }, frames = { food = { scale = "groß" } },
} }))
local imported = db.profiles[name]
expect("Import: alte Größe umgezogen", imported.frames.camp.scale, 1.4)
expect("Import: alte Position umgezogen", imported.frames.camp.x, 3)
expect("Import: ungültiger Eintrag verworfen", imported.frames.food, nil)
expect("Import: alter Schlüssel weg", imported.campScale, nil)

-- Fixieren gilt für alle Anzeigen, die außerhalb des Edit-Modus ziehbar sind (Hauptfenster, Split-Liste)
addon.Set("showSplitList", true)
local moved = { count = 0 }
local function tryDrag(frame)
  frame.StartMoving = function() moved.count = moved.count + 1 end
  frame._scripts.OnDragStart(frame)
  frame.StartMoving = nil
end
SlashCmdList.LEVELTIMER("lock")
tryDrag(LevelTimerFrame)
tryDrag(LevelTimerSplits)
expect("fixiert: nichts ziehbar", moved.count, 0)
SlashCmdList.LEVELTIMER("unlock")
tryDrag(LevelTimerFrame)
tryDrag(LevelTimerSplits)
expect("frei: beide ziehbar", moved.count, 2)
LevelTimerSplits._scripts.OnDragStop(LevelTimerSplits)
expect("Ziehen speichert", db.frames.splitList.point, "CENTER")

-- /lt reset: alle Anzeigen auf Standard
Frames.SetScale("alert", 1.5)
Frames.SetScale("camp", 0.6)
SlashCmdList.LEVELTIMER("reset")
for _, reg in ipairs(Frames.All()) do
  expect("zurückgesetzt: " .. reg.id, db.frames[reg.id], nil)
end
expect("Einblendung wieder 100 %", LevelTimerAlert:GetScale(), 1)
expect("Hauptfenster wieder oben in der Mitte", LevelTimerFrame._points[1][1], "TOP")

-- Geschützte Anzeige (Quest-Knöpfe) im Kampf: nichts ändern, danach nachholen
wow.state.combatLockdown = true
Frames.SetScale("questItem", 1.5)
expect("im Kampf: keine Änderung", LevelTimerQuestItemBar:GetScale(), 1)
db.frames.questItem = { scale = 1.4 }
addon.ApplySettings()
expect("im Kampf: Apply wartet", LevelTimerQuestItemBar:GetScale(), 1)
wow.state.combatLockdown = false
wow.fire("PLAYER_REGEN_ENABLED")
expect("nach dem Kampf nachgeholt", LevelTimerQuestItemBar:GetScale(), 1.4)
expect("Fehlerfrei", #wow.errors, 0)

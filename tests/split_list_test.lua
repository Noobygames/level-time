-- Split-Liste: laufendes Level und die letzten abgeschlossenen, mit Abweichung zur Bestzeit.
local SplitList = addon.SplitList
local list = LevelTimerSplits

wow.login({ name = "Neu", level = 14, playedSeconds = 0 })
LevelTimerStatsDB.characters["Rekord-Testrealm"] = {
  name = "Rekord", realm = "Testrealm", currentLevel = { level = 30, counters = {} },
  levelHistory = { [12] = { level = 12, seconds = 1000 }, [13] = { level = 13, seconds = 1000 } },
  sessionHistory = {}, killLog = {}, deathLog = {},
}
for level = 10, 13 do
  addon.character.levelHistory[level] = { level = level, seconds = 1100 }
end

expect("standardmäßig versteckt", list:IsShown(), false)
SlashCmdList.LEVELTIMER("splits")
expect("per Befehl an", list:IsShown(), true)

addon.Set("splitListRows", 3)
local lines = SplitList.BuildLines()
expect("Zahl der Zeilen", #lines, 3)
expect("laufendes Level zuerst", lines[1].level, 14)
expect("dann neuestes abgeschlossenes", lines[2].level, 13)
expect("Zeit", lines[2].seconds, 1100)
expect("Abweichung zur Bestzeit", lines[2].delta, 100)
expect("ohne Vergleich keine Abweichung", lines[1].delta, nil)

addon.Set("splitListRows", 10)
expect("nur vorhandene Level", #SplitList.BuildLines(), 5)

-- Größe und Hintergrund folgen dem Hauptfenster
addon.Frames.SetScale("main", 1.5)
expect("Größe wie Fenster", list:GetScale(), 1.5)
addon.Set("windowBackground", "green")
expect("Chroma wie Fenster", list._backdropColor[2], 1)

-- Anzeige rendert ohne Fehler und lässt sich ausschalten
list._scripts.OnUpdate(list, 1)
expectTrue("Fensterhöhe für Zeilen", list:GetHeight() > 5 * 14)
SlashCmdList.LEVELTIMER("splits")
expect("aus", list:IsShown(), false)

-- Unter der Summe: gesamte Spielzeit (/played vom Server, wow.login: 100000 s)
SlashCmdList.LEVELTIMER("splits")
list._scripts.OnUpdate(list, 1)
local playedRow = wow.findFrame(function(frame) return frame._text == addon.L.SPLIT_LIST_PLAYED end)
expectTrue("Zeile /played", playedRow ~= nil and playedRow:IsShown())
local found = wow.findFrame(function(frame) return frame._text == addon.Format.Duration(100000) end)
expectTrue("Wert /played", found ~= nil)

-- Größe ändern: die Liste bleibt mit ihrer linken oberen Ecke stehen
addon.Set("showSplitList", true)
addon.Frames.SetScale("splitList", 1)
addon.Frames.SetScale("splitList", 2)
local anchor = LevelTimerSplits._points[1]
expect("an der linken oberen Ecke skaliert", anchor[1] .. " " .. anchor[3], "TOPLEFT BOTTOMLEFT")
expect("Abstand umgerechnet", anchor[4], 50)  -- linke Kante 100 bei Größe 1
expectTrue("Position gespeichert", LevelTimerDB.frames.splitList.point ~= nil)

-- Ziehgriff an der Split-Liste: Loslassen speichert die eigene Größe
local grips = {}
wow.findFrame(function(frame)
  if rawget(frame, "UpdateAlpha") then table.insert(grips, frame) end
  return false
end)
expect("Ziehgriffe an Hauptfenster und Split-Liste", #grips, 2)
addon.Frames.SetScale("main", 1)
local savedSplitScale
for _, grip in ipairs(grips) do
  LevelTimerSplits:SetScale(1.4)               -- wie nach dem Ziehen am Griff der Split-Liste
  grip._scripts.OnMouseUp(grip)
  if math.abs(LevelTimerDB.frames.splitList.scale - 1.4) < 0.001 then savedSplitScale = true end
end
expectTrue("Größe der Split-Liste gespeichert", savedSplitScale)
expectNear("Hauptfenster unverändert", LevelTimerDB.frames.main.scale, 1)

-- Quest-Fokus (LT-260) und Questpfeil (LT-259): Fokus über das Kontextmenü des Questlogs (Retail/Forever) oder einen
-- Kartenpunkt, andere Punkte blass, Pfeil zum nächsten Zielort bzw. zum Abgabe-NPC, weg am Ziel, ohne Position und nach
-- der Abgabe.
local L = addon.L
local QuestFocus = addon.QuestFocus
local QuestMap = addon.QuestMap
local QuestArrow = addon.QuestArrow

local menus = {}
Menu = { ModifyMenu = function(tag, callback) menus[tag] = callback end }

local player = { 0.5, 0.5 }
local function vector(x, y) return { GetXY = function() return x, y end } end
function CreateVector2D(x, y) return vector(x, y) end
C_Map = {
  GetBestMapForUnit = function() return 1429 end,
  GetPlayerMapPosition = function() return player and vector(player[1], player[2]) end,
  -- Karte 1000 Yards breit, 600 hoch (Weltachsen wie im Client: x = Norden, y = Westen)
  GetWorldPosFromMapPos = function(_, position)
    local x, y = position:GetXY()
    return 0, vector(-y * 600, -x * 1000)
  end,
}
function GetPlayerFacing() return 0 end

wow.state.questLog = {
  { questID = 60, title = "Eberjagd" },
  { questID = 61, title = "Wolfsplage" },
}
wow.login({ level = 10 })
LevelTimerStatsDB.questNpcs = {
  [60] = { spots = { { mapID = 1429, x = 0.5, y = 0.4 }, { mapID = 1429, x = 0.8, y = 0.5 } },
    turnIn = { name = "Gryan", mapID = 1429, x = 0.6, y = 0.5 } },
  [61] = { spots = { { mapID = 1429, x = 0.2, y = 0.2 } } },
}
addon.Set("questMap", true)
addon.Set("questArrow", true)

expect("ohne Fokus: volle Deckkraft", QuestMap.PointsOn(1429)[1].alpha, 1)
expect("ohne Fokus: kein Pfeil", LevelTimerQuestArrow, nil)

-- Kontextmenü einer Quest im Questlog (Forever/Retail)
local buttons = {}
local root = { CreateButton = function(_, text, onClick) table.insert(buttons, { text = text, onClick = onClick }) end }
menus.MENU_QUEST_MAP_LOG_TITLE({ questID = 60 }, root)
expect("Menüeintrag", buttons[1].text, L.QUEST_FOCUS_SET)
buttons[1].onClick()
expect("fokussiert", QuestFocus.Get(), 60)

local faded, full = 0, 0
for _, point in ipairs(QuestMap.PointsOn(1429)) do
  if point.questID == 60 then full = full + point.alpha else faded = faded + point.alpha end
end
expect("eigene Punkte voll", full, 2)
expectTrue("andere Quest blass", faded > 0 and faded < 1)

-- Pfeil zum nächsten Zielort: 60 Yards im Norden
expectTrue("Pfeil sichtbar", LevelTimerQuestArrow:IsShown())
local rotation, distance = QuestArrow.Direction()
expectNear("geradeaus", rotation, 0)
expectNear("60 Yards", distance, 60)
expect("Entfernung angezeigt", LevelTimerQuestArrow.distance:GetText(), string.format(L.CORPSE_DISTANCE, 60))

-- Am Zielort: kein Pfeil
player = { 0.5, 0.405 }
wow.update(0.2)
expect("am Ziel: kein Pfeil", LevelTimerQuestArrow.arrow:IsShown(), false)

-- Instanz: keine Position
player = nil
expect("ohne Position: nichts", QuestArrow.Direction(), nil)

-- Abgabebereit: Pfeil zum Abgabe-NPC im Osten (100 Yards)
player = { 0.5, 0.5 }
wow.state.questLog[1].isComplete = 1
wow.fire("QUEST_LOG_UPDATE")
rotation, distance = QuestArrow.Direction()
expectNear("Abgabe im Osten", rotation, -math.pi / 2)
expectNear("100 Yards", distance, 100)

-- Kartenpunkt per Rechtsklick: Fokus aufheben
buttons = {}
menus.MENU_QUEST_MAP_LOG_TITLE({ questID = 60 }, root)
expect("Menü bietet Aufheben", buttons[1].text, L.QUEST_FOCUS_CLEAR)
QuestFocus.Toggle(60)
expect("aufgehoben", QuestFocus.Get(), nil)
expect("Pfeil weg", LevelTimerQuestArrow:IsShown(), false)

-- Abgabe hebt den Fokus auf
QuestFocus.Set(61)
wow.fire("QUEST_TURNED_IN", 61, 0, 0)
expect("nach Abgabe kein Fokus", QuestFocus.Get(), nil)

-- Beide Optionen aus: kein Menüeintrag
addon.Set("questMap", false)
addon.Set("questArrow", false)
buttons = {}
menus.MENU_QUEST_MAP_LOG_TITLE({ questID = 60 }, root)
expect("aus: kein Menüeintrag", #buttons, 0)
expect("Fehler?", #wow.errors, 0)

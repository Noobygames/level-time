-- Todeskarte und letzte Worte (Roadmap 280): Ort und letzte eigene Chatzeile beim Tod, Punkte auf der Weltkarte.
local L = addon.L
local DeathMap = addon.DeathMap

-- Weltkarte wie Blizzards MapCanvas: Karten-ID und Leinwand (GetCanvas)
local shownMap = 1429
WorldMapFrame = CreateFrame("Frame", "WorldMapFrame")
local canvas = CreateFrame("Frame")
canvas:SetSize(1000, 600)
WorldMapFrame.GetCanvas = function() return canvas end
WorldMapFrame.GetMapID = function() return shownMap end
WorldMapFrame.OnMapChanged = function() end
local playerPosition = { 0.25, 0.5 }
C_Map = {
  GetBestMapForUnit = function() return 1429 end,
  GetPlayerMapPosition = function(mapID)
    if mapID ~= 1429 or not playerPosition then return nil end
    return { GetXY = function() return playerPosition[1], playerPosition[2] end }
  end,
}

wow.login({ level = 12 })

local function say(text, guid)
  wow.fire("CHAT_MSG_SAY", text, "Testchar", "", "", "", "", 0, 0, "", 0, 1, guid or wow.state.guid)
end
local function die()
  wow.state.dead = true
  wow.fire("PLAYER_DEAD")
  wow.state.dead = false
  wow.fire("PLAYER_UNGHOST")
end
local function lastDeath() return addon.character.deathLog[#addon.character.deathLog] end

-- Tod draußen: Ort und letzte Worte; fremde und geheime Zeilen zählen nicht
say("Ich schaff das schon")
say("Hilfe!", "Player-1-0002")
say(wow.SECRET)
die()
expect("Karte", lastDeath().mapID, 1429)
expectNear("x", lastDeath().x, 0.25)
expect("letzte Worte", lastDeath().lastWords, "Ich schaff das schon")
expect("Koordinaten", addon.DeathPlace.CoordinatesText(lastDeath()), "25.0, 50.0")

-- Alte Worte verfallen, Instanz ohne Position
wow.advance(601)
playerPosition = nil
die()
expect("in Instanz ohne Karte", lastDeath().x, nil)
expect("alte Worte verfallen", lastDeath().lastWords, nil)

-- Weltkarte: aus = kein Rahmen; an = ein Punkt auf dieser Karte, keiner auf anderen
expect("aus: kein Rahmen", LevelTimerDeathMap, nil)
addon.Set("deathMap", true)
expectTrue("an: Rahmen auf der Leinwand", LevelTimerDeathMap ~= nil and LevelTimerDeathMap._parent == canvas)
expect("ein Tod auf der Karte", #DeathMap.DeathsOn(1429), 1)
DeathMap.Refresh(true)
wow.update(1)
-- Roadmap 398: ohne Änderung kein Neuzeichnen; Kartenwechsel über OnMapChanged sofort
local lookups = { count = 0 }
local deathsOn = DeathMap.DeathsOn
DeathMap.DeathsOn = function(...)
  lookups.count = lookups.count + 1
  return deathsOn(...)
end
for _ = 1, 20 do wow.update(0.5) end
expect("Karte unverändert: nicht neu gezeichnet", lookups.count, 0)
shownMap = 1411
WorldMapFrame:OnMapChanged()
-- je einmal für die gezeigte Karte und für die Karte mit Toden (Nachbarzonen, LT-39)
expect("Kartenwechsel: sofort neu gezeichnet", lookups.count, 2)
DeathMap.DeathsOn = deathsOn
DeathMap.Refresh(true)
expect("andere Karte: keine Tode", #DeathMap.DeathsOn(1411), 0)
addon.Set("deathMap", false)
expectTrue("aus: versteckt", not LevelTimerDeathMap:IsShown())

-- Historie: Tode mit Ort und letzten Worten
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Tode", wow.click("Tode"))
expect("Spalte Ort", L.HISTORY_PLACE, "Ort")

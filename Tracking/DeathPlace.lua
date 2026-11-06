-- Ort und letzte Worte eines Todes (Roadmap 280, wie Deathlog): beim neuen Tod-Eintrag (Journal.OnAdd) Karte und
-- Position des Spielers (C_Map.GetBestMapForUnit / C_Map.GetPlayerMapPosition, in Instanzen nil) und die letzte eigene
-- Chatzeile der letzten LAST_WORDS_MAX_AGE Sekunden. Felder mapID, x, y (0..1), lastWords hinten an
-- Journal.LOGS.deathLog. Eigene Zeilen erkennt die GUID des Absenders (12. Argument der CHAT_MSG_*-Ereignisse);
-- geheime Werte (Retail/Forever in Instanzen und im Kampf) werden übergangen.
local _, ns = ...

local DeathPlace = {}
ns.DeathPlace = DeathPlace

local LAST_WORDS_MAX_AGE = 600  -- s: ältere Zeilen gelten nicht mehr als letzte Worte
local SENDER_GUID_ARG = 12
local CHAT_EVENTS = {
  "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID",
  "CHAT_MSG_RAID_LEADER", "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_GUILD",
  "CHAT_MSG_WHISPER_INFORM",
}

local lastLine, lastLineAt

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

-- Karte und Position (0..1) des Spielers; nil in Instanzen oder ohne C_Map
function DeathPlace.Position()
  if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return nil end
  local mapID = readable(C_Map.GetBestMapForUnit("player"))
  if type(mapID) ~= "number" then return nil end
  local position = C_Map.GetPlayerMapPosition(mapID, "player")
  if not position or ns.IsSecret(position) then return nil end
  local x, y = position:GetXY()
  x, y = readable(x), readable(y)
  if type(x) ~= "number" or type(y) ~= "number" or (x == 0 and y == 0) then return nil end
  return mapID, x, y
end

-- Letzte eigene Chatzeile, wenn sie jung genug ist
function DeathPlace.LastWords()
  if not lastLine or not lastLineAt or GetTime() - lastLineAt > LAST_WORDS_MAX_AGE then return nil end
  return lastLine
end

-- Koordinaten als "45.2, 63.1", nil ohne Position
function DeathPlace.CoordinatesText(entry)
  if type(entry.x) ~= "number" or type(entry.y) ~= "number" then return nil end
  return string.format("%.1f, %.1f", entry.x * 100, entry.y * 100)
end

local function onChat(...)
  local text, guid = readable((select(1, ...))), readable((select(SENDER_GUID_ARG, ...)))
  if type(text) ~= "string" or text == "" or guid == nil or guid ~= UnitGUID("player") then return end
  lastLine, lastLineAt = text, GetTime()
end

for _, event in ipairs(CHAT_EVENTS) do
  ns.RegisterEvent(event, onChat)
end

ns.Journal.OnAdd(function(logName, entry)
  if logName ~= "deathLog" then return end
  entry.mapID, entry.x, entry.y = DeathPlace.Position()
  entry.lastWords = DeathPlace.LastWords()
  ns.Debug("deaths", "place %s %s", tostring(entry.mapID), DeathPlace.CoordinatesText(entry) or "-")
end)

ns.OnLogin(function() lastLine, lastLineAt = nil, nil end)

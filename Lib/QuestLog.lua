-- Questlog lesen, gleich in allen Clients (Blizzard_APIDocumentationGenerated je Client, warcraft.wiki.gg):
--   Retail/Forever  C_QuestLog.GetNumQuestLogEntries + C_QuestLog.GetInfo(i) (questID, title, isHeader, level,
--                   suggestedGroup)
--   Classic Era/TBC GetNumQuestLogEntries + GetQuestLogTitle(i): title, level, suggestedGroup, isHeader, isCollapsed,
--                   isComplete (1 = fertig, -1 = gescheitert, sonst nil), frequency, questID
-- Abgabebereit: C_QuestLog.ReadyForTurnIn(questID) (Retail/Forever), sonst isComplete == 1 (Era/TBC).
-- Belohnungs-XP: GetQuestLogRewardXP(questID) in allen Clients (warcraft.wiki.gg: vanilla 1.14.4, tbc 2.5.5, Forever).
-- Unter eingeklappten Überschriften sieht Classic die Quests nicht. Geheime Werte werden zu nil.
local _, ns = ...

local QuestLog = {}
ns.QuestLog = QuestLog

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function useInfoApi()
  return C_QuestLog ~= nil and C_QuestLog.GetInfo ~= nil and C_QuestLog.GetNumQuestLogEntries ~= nil
end

function QuestLog.Count()
  if useInfoApi() then return readable((C_QuestLog.GetNumQuestLogEntries())) or 0 end
  return GetNumQuestLogEntries and readable((GetNumQuestLogEntries())) or 0
end

-- Anzahl Quests im Log (ohne Überschriften, auch unter eingeklappten): 2. Rückgabewert von
-- C_QuestLog.GetNumQuestLogEntries (Retail/Forever: numShownEntries, numQuests) bzw. GetNumQuestLogEntries (Classic)
function QuestLog.QuestCount()
  local _, quests
  if useInfoApi() then
    _, quests = C_QuestLog.GetNumQuestLogEntries()
  elseif GetNumQuestLogEntries then
    _, quests = GetNumQuestLogEntries()
  end
  quests = readable(quests)
  return type(quests) == "number" and quests or #QuestLog.Entries()
end

-- Höchstzahl annehmbarer Quests: C_QuestLog.GetMaxNumQuestsCanAccept (alle Clients laut Doku), sonst MAX_QUESTS
function QuestLog.MaxQuests()
  local max = C_QuestLog and C_QuestLog.GetMaxNumQuestsCanAccept and readable(C_QuestLog.GetMaxNumQuestsCanAccept())
  if type(max) == "number" and max > 0 then return max end
  return type(MAX_QUESTS) == "number" and MAX_QUESTS or nil
end

-- suggestedGroup: Zahl > 0; ältere Clients liefern evtl. einen Text ("Elite", "Gruppe")
local function isGroup(suggested)
  suggested = readable(suggested)
  if type(suggested) == "number" then return suggested > 0 end
  return type(suggested) == "string" and suggested ~= ""
end

local COMPLETE = 1  -- isComplete von GetQuestLogTitle für eine fertige Quest

local function isReady(questID, isComplete)
  if C_QuestLog and C_QuestLog.ReadyForTurnIn then
    return type(questID) == "number" and readable(C_QuestLog.ReadyForTurnIn(questID)) == true
  end
  return readable(isComplete) == COMPLETE
end

-- Eintrag i als { index, questID, title, level, group, ready }; nil für Überschriften und Unlesbares
function QuestLog.Entry(index)
  local questID, title, level, suggested, isHeader, isComplete
  if useInfoApi() then
    local info = C_QuestLog.GetInfo(index)
    if type(info) ~= "table" then return nil end
    questID, title, level, suggested, isHeader = info.questID, info.title, info.level, info.suggestedGroup, info.isHeader
  elseif GetQuestLogTitle then
    local _
    title, level, suggested, isHeader, _, isComplete, _, questID = GetQuestLogTitle(index)
  else
    return nil
  end
  if readable(isHeader) then return nil end
  questID = readable(questID)
  return { index = index, questID = questID, title = readable(title), level = readable(level),
    group = isGroup(suggested), ready = isReady(questID, isComplete) }
end

-- XP, die die Abgabe der Quest bringt; nil, wenn der Client sie nicht nennt
function QuestLog.RewardXp(questID)
  if not GetQuestLogRewardXP or type(questID) ~= "number" then return nil end
  local xp = readable((GetQuestLogRewardXP(questID)))
  return type(xp) == "number" and xp or nil
end

-- Geld (Kupfer), das die Abgabe bringt: GetQuestLogRewardMoney([questID]) laut warcraft.wiki.gg in allen Clients
-- (ohne ID die zuletzt angesehene Quest); nil, wenn unbekannt. Ob Era die ID beachtet: check 486.questRewards
function QuestLog.RewardMoney(questID)
  if not GetQuestLogRewardMoney or type(questID) ~= "number" then return nil end
  local money = readable((GetQuestLogRewardMoney(questID)))
  return type(money) == "number" and money or nil
end

-- Titel einer Überschrift (Zone, Kategorie) an Position index; nil für Quests und Unlesbares
local function headerTitle(index)
  if useInfoApi() then
    local info = C_QuestLog.GetInfo(index)
    if type(info) ~= "table" or readable(info.isHeader) ~= true then return nil end
    return readable(info.title)
  elseif GetQuestLogTitle then
    local title, _, _, isHeader = GetQuestLogTitle(index)
    if readable(isHeader) then return readable(title) end
  end
  return nil
end

-- Alle Quests im Log (ohne Überschriften) mit Quest-ID; entry.header = Titel der Überschrift darüber (Zone)
function QuestLog.Entries()
  local entries, header = {}, nil
  for index = 1, QuestLog.Count() do
    local entry = QuestLog.Entry(index)
    if entry then
      if type(entry.questID) == "number" and entry.questID ~= 0 then
        entry.header = header
        table.insert(entries, entry)
      end
    else
      header = headerTitle(index) or header
    end
  end
  return entries
end

-- "Durchnässte Säge: 0/1" -> "durchnässte säge" (klein, ohne Zähler, Doppelpunkt und Spiegelstrich); zum Vergleich
-- von Zieltexten mit Namen von Gegnern, Objekten und Gegenständen. Ergebnisse je Text zwischengespeichert (jeder
-- Questlog-Durchlauf fragt dieselben Texte; vier gsub je Ziel erzeugten bei jedem Durchlauf neue Strings), bis
-- NORMALIZED_MAX Texte gemerkt sind, dann beginnt der Speicher neu.
local NORMALIZED_MAX = 500
local normalized, normalizedCount = {}, 0

function QuestLog.NormalizeObjective(text)
  if type(text) ~= "string" then return "" end
  local cached = normalized[text]
  if cached then return cached end
  local result = text:lower():gsub("%d+%s*/%s*%d+", ""):gsub("%d+%s*%%", "")
  result = result:gsub("^[%s:%-]+", ""):gsub("[%s:%-]+$", "")
  if normalizedCount >= NORMALIZED_MAX then normalized, normalizedCount = {}, 0 end
  normalized[text] = result
  normalizedCount = normalizedCount + 1
  return result
end

-- Stand aus dem Zieltext ("Wolf getötet: 3/8" bzw. "3/8 Wolf getötet"), falls die Zahlen fehlen
local function countsFromText(text)
  if type(text) ~= "string" then return nil, nil end
  local have, need = text:match("(%d+)%s*/%s*(%d+)")
  return tonumber(have), tonumber(need)
end

-- Ziele einer Quest (C_QuestLog.GetQuestObjectives, alle Clients; ohne Questdaten evtl. leer):
-- { index, text, name (NormalizeObjective), kind (objective.type: "monster", "item", "object", ...), finished,
-- have, need }; geheime Felder werden nil, have/need notfalls aus dem Text
function QuestLog.Objectives(questID)
  local list = {}
  if type(questID) ~= "number" or not (C_QuestLog and C_QuestLog.GetQuestObjectives) then return list end
  local objectives = readable(C_QuestLog.GetQuestObjectives(questID))
  if type(objectives) ~= "table" then return list end
  for index, objective in ipairs(objectives) do
    local text = readable(objective.text)
    local have, need = readable(objective.numFulfilled), readable(objective.numRequired)
    if type(have) ~= "number" or type(need) ~= "number" then have, need = countsFromText(text) end
    local finished = readable(objective.finished)
    list[index] = { index = index, text = text, name = QuestLog.NormalizeObjective(text),
      kind = readable(objective.type), finished = finished, have = have, need = need }
  end
  return list
end

-- Sind alle Ziele einer Quest erfüllt? false ohne (lesbare) Ziele
function QuestLog.AllFinished(questID)
  local objectives = QuestLog.Objectives(questID)
  for _, objective in ipairs(objectives) do
    if objective.finished ~= true then return false end
  end
  return #objectives > 0
end

-- Eintrag zu einer Quest-ID oder nil
function QuestLog.Find(questID)
  questID = readable(questID)
  if type(questID) ~= "number" then return nil end
  if C_QuestLog and C_QuestLog.GetLogIndexForQuestID and useInfoApi() then
    local index = readable(C_QuestLog.GetLogIndexForQuestID(questID))
    return type(index) == "number" and QuestLog.Entry(index) or nil
  end
  for _, entry in ipairs(QuestLog.Entries()) do
    if entry.questID == questID then return entry end
  end
end

-- Zone einer Quest gegenüber dem Aufenthaltsort des Spielers (Quest-Knöpfe nur in der richtigen Zone):
--   Questkarte  GetQuestUiMapID(questID, ignoreWaypoints) (global in allen Zweigen; Blizzards QuestMapFrame in
--               live/forever ruft es mit ignoreWaypoints auf; 0 = unbekannt). Classic kennt keine Quest-POIs und
--               liefert dort vermutlich 0, dann zählen die übrigen Hinweise.
--   Überschrift Questlog-Überschrift über der Quest (entry.header): in allen Clients der Zonenname, unter dem die
--               Quest einsortiert ist, oder eine Kategorie ("Dungeons", Klassen, "Saisonal"). Gleich einem Ortsnamen
--               des Spielers (GetRealZoneText, GetZoneText, GetSubZoneText, Kartennamen von der Zone abwärts) = hier;
--               ein anderer Zonen- oder Dungeonname aus C_Map.GetMapChildrenInfo = woanders; Kategorien = unbekannt.
--   Gelernt     Karten, auf denen Ziele der Quest vorankamen (QuestNpcs-Orte), vom Aufrufer übergeben.
-- Karten zählen auf Zonenebene: Kleinstkarten (Höhlen, Stockwerke) gehen über C_Map.GetMapInfo().parentMapID bis
-- zur Zone bzw. zum Dungeon hoch; Kontinente und Welt sind zu grob (unbekannt). Ein Hinweis "hier" genügt; nur wenn
-- keiner "hier" und mindestens einer "woanders" sagt, liegt die Quest woanders. Ohne Hinweis: unbekannt (nil).
local MAP_TYPE = Enum and Enum.UIMapType or {}
local ZONE_TYPE = MAP_TYPE.Zone or 3
local DUNGEON_TYPE = MAP_TYPE.Dungeon or 4
local MAX_MAP_DEPTH = 10  -- Schutz gegen Kreise in den Kartendaten
local ZONE_TEXT_FUNCTIONS = { "GetRealZoneText", "GetZoneText", "GetSubZoneText" }
local SIGNAL_ORDER = { "map", "header", "learned" }

local mapInfos = {}  -- [mapID] = { name, mapType, parent } oder false; Kartendaten ändern sich nicht
local zoneNames      -- Namen aller Zonen und Dungeons, einmal je Sitzung

local function mapInfo(mapID)
  if type(mapID) ~= "number" or mapID <= 0 or not (C_Map and C_Map.GetMapInfo) then return nil end
  local info = mapInfos[mapID]
  if info == nil then
    local raw = C_Map.GetMapInfo(mapID)
    info = false
    if type(raw) == "table" then
      info = { name = readable(raw.name), mapType = readable(raw.mapType), parent = readable(raw.parentMapID) }
    end
    mapInfos[mapID] = info
  end
  return info or nil
end

-- Zone bzw. Dungeon einer Karte (Kleinstkarten gehen nach oben); nil für Kontinente, Welt und Unbekanntes
function QuestLog.ZoneMapOf(mapID)
  for _ = 1, MAX_MAP_DEPTH do
    local info = mapInfo(mapID)
    if not info or type(info.mapType) ~= "number" then return nil end
    if info.mapType <= DUNGEON_TYPE then
      return info.mapType >= ZONE_TYPE and mapID or nil
    end
    mapID = info.parent
  end
  return nil
end

-- Karte der Quest laut Client; nil = unbekannt
function QuestLog.QuestMap(questID)
  if type(questID) ~= "number" or not GetQuestUiMapID then return nil end
  local mapID = readable((GetQuestUiMapID(questID, true)))
  return type(mapID) == "number" and mapID > 0 and mapID or nil
end

local function rootOf(mapID)
  for _ = 1, MAX_MAP_DEPTH do
    local info = mapInfo(mapID)
    if not info then return nil end
    if type(info.parent) ~= "number" or info.parent <= 0 then return mapID end
    mapID = info.parent
  end
  return nil
end

-- Namen aller Zonen und Dungeons unter der obersten Karte über dem Spieler; nil, solange keine Karte bekannt ist
local function knownZoneNames(here)
  if zoneNames then return zoneNames end
  local root = here.mapID and rootOf(here.mapID)
  if not (root and C_Map.GetMapChildrenInfo) then return nil end
  local children = C_Map.GetMapChildrenInfo(root, nil, true)
  if type(children) ~= "table" then return nil end
  zoneNames = {}
  for _, child in ipairs(children) do
    local name, mapType = readable(child.name), readable(child.mapType)
    if type(name) == "string" and type(mapType) == "number" and mapType >= ZONE_TYPE and mapType <= DUNGEON_TYPE then
      zoneNames[name] = true
    end
  end
  return zoneNames
end

-- Aufenthaltsort des Spielers: { mapID, zone (ZoneMapOf), names = { [Ortsname] = true } }
function QuestLog.Here()
  local mapID = C_Map and C_Map.GetBestMapForUnit and readable(C_Map.GetBestMapForUnit("player"))
  if type(mapID) ~= "number" then mapID = nil end
  local here = { mapID = mapID, zone = QuestLog.ZoneMapOf(mapID), names = {} }
  for _, name in ipairs(ZONE_TEXT_FUNCTIONS) do
    local text = _G[name] and readable(_G[name]())
    if type(text) == "string" and text ~= "" then here.names[text] = true end
  end
  local current = mapID
  for _ = 1, MAX_MAP_DEPTH do
    local info = mapInfo(current)
    if not info or type(info.mapType) ~= "number" or info.mapType < ZONE_TYPE then break end
    if type(info.name) == "string" then here.names[info.name] = true end
    current = info.parent
  end
  return here
end

local function mapSignal(questID, here)
  local zone = here.zone and QuestLog.ZoneMapOf(QuestLog.QuestMap(questID))
  if zone then return zone == here.zone end
  return nil
end

local function headerSignal(header, here)
  if type(header) ~= "string" or header == "" then return nil end
  if here.names[header] then return true end
  local zones = knownZoneNames(here)
  if zones and zones[header] then return false end
  return nil  -- Kategorie oder unbekannter Name
end

local function learnedSignal(learnedMaps, here)
  if not (learnedMaps and here.zone) then return nil end
  local signal
  for _, mapID in ipairs(learnedMaps) do
    local zone = QuestLog.ZoneMapOf(mapID)
    if zone == here.zone then return true end
    if zone then signal = false end
  end
  return signal
end

-- Liegt die Quest in der Zone des Spielers (here = QuestLog.Here())? true/false, nil = unbekannt; dazu die
-- Einzelhinweise { map, header, learned } (je true/false/nil) für Debug-Zeilen
function QuestLog.ZoneStatus(questID, header, here, learnedMaps)
  local signals = { map = mapSignal(questID, here), header = headerSignal(header, here),
    learned = learnedSignal(learnedMaps, here) }
  local status
  for _, key in ipairs(SIGNAL_ORDER) do
    if signals[key] == true then return true, signals end
    if signals[key] == false then status = false end
  end
  return status, signals
end

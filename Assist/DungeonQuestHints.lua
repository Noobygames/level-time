-- Hinweise zu Dungeonquests im Fenster UI/DungeonQuestHint.lua (nur mit ns.DungeonDB, also Classic Era und Forever).
-- Zone (Einstellung dungeonQuestZoneHint, an): beim Betreten einer Zone (ZONE_CHANGED_NEW_AREA, nach dem Login
-- PLAYER_ENTERING_WORLD) die jetzt annehmbaren Dungeonquests und Kettenschritte, deren Geber in dieser Zone steht
-- (DungeonQuests.OffersOnMap), einmal je Zone und Sitzung. Zone = C_Map.GetBestMapForUnit("player"), Kleinstkarten
-- über QuestLog.ZoneMapOf auf Zonenebene.
-- Annahme (Einstellung dungeonQuestAcceptHint, an): nach Annahme einer Dungeonquest oder eines Kettenschritts
-- (QuestWatch onAccepted) die übrigen offenen Quests derselben Instanz samt Kettenschritten (DungeonQuests.InstanceQuests):
-- jetzt annehmbare zuerst, später verfügbare (Level oder Vorquest fehlt) leiser; Klick setzt einen Kartenpunkt.
-- Gebername: die DungeonDB führt keine NPC-Namen; NPC = gelernter Name aus QuestNpcs (Annahme-Dialog), sonst
-- NpcNames.Get (Kreaturen-Cache des Clients), sonst "Questgeber"; Gegenstand = C_Item.GetItemNameByID (Classic Era laut
-- Blizzard-Doku, sonst geschützt); Objekt = englischer Name aus der DungeonDB auf englischen Clients, sonst "Objekt".
-- Das Fenster fragt Detail gedrosselt neu ab und zieht so einen später auflösbaren NPC-Namen nach.
-- Objektnamen: Classic Era hat kein C_TooltipInfo (keine Objekt-ID im Welt-Tooltip), übersetzte Namen gibt es nur
-- englisch; auf deDE/frFR/esES bleibt "Objekt".
-- Fenster bleiben stehen (Schließen-Knopf); /lt dq und der Knopf in den Optionen öffnen sie erneut (Show), Rechtsklick
-- auf einen Dungeon-Eingang der Karte zeigt die Quests dieser Instanz (ShowInstance).
-- Ort "Zone (x, y)" über DungeonEntrances.StartText (C_Map.GetMapInfo).
-- Abgeschaltete Dungeons (LT-394, Haken im Instanz-Hinweis, je Charakter in character.hiddenDungeonQuestHints): keine
-- Zeilen im Zonen-Hinweis, kein Hinweis nach der Annahme; der Rechtsklick auf den Eingang zeigt sie weiter.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    dungeonQuestZoneHint = true,
    dungeonQuestAcceptHint = true,
    dungeonQuestHintAutoClose = false,  -- aus: Fenster bleibt, bis es geschlossen wird
  },
})
local L = ns.L
local DungeonQuests = ns.DungeonQuests

local DungeonQuestHints = {}
ns.DungeonQuestHints = DungeonQuestHints

local GIVER_FALLBACK = { npc = "DUNGEON_QUEST_GIVER_NPC", object = "DUNGEON_QUEST_GIVER_OBJECT",
  item = "DUNGEON_QUEST_GIVER_ITEM" }

local shownZones = {}  -- [uiMapID] = true: in dieser Sitzung schon gezeigt

local function readable(value)
  if value == nil or ns.IsSecret(value) then return nil end
  return value
end

-- Name des Gebers einer Quest; nil, wenn die Art unbekannt ist
function DungeonQuestHints.GiverName(questID)
  local kind, giverID = DungeonQuests.Giver(questID)
  if not kind then return nil end
  local name
  if kind == "npc" then
    local learned = ns.QuestNpcs.Get(questID)
    name = learned and learned.giver and learned.giver.name or ns.NpcNames.Get(giverID)
  elseif kind == "object" and ns.DungeonQuestStarters.NamesAvailable() then
    name = ns.DungeonQuestStarters.ObjectName(giverID)
  elseif kind == "item" and C_Item and C_Item.GetItemNameByID then
    name = readable(C_Item.GetItemNameByID(giverID))
  end
  if type(name) == "string" and name ~= "" then return name end
  return L[GIVER_FALLBACK[kind]]
end

-- Zweite Zeile eines Eintrags: "Geber – Zone (x, y)", nur der Geber oder nur der Ort; nil ohne beides
function DungeonQuestHints.Detail(questID, place)
  local giver = DungeonQuestHints.GiverName(questID)
  local where = place and ns.DungeonEntrances.StartText(place)
  if giver and where then return string.format(L.DUNGEON_QUEST_HINT_DETAIL, giver, where) end
  return giver or where
end

-- Zeile eines Angebots: "Titel (Instanz)" bzw. "Titel (Instanz, Schritt 2/7)"
local function offerText(offer)
  local questTitle, instance = DungeonQuests.Title(offer.questID), ns.InstanceInfo.MapName(offer.mapID)
  if offer.step then return string.format(L.DUNGEON_QUEST_HINT_CHAIN_ROW, questTitle, instance, offer.step, offer.total) end
  return string.format(L.DUNGEON_QUEST_HINT_ROW, questTitle, instance)
end

-- Eintrag mit questID und place; textOf bildet den Text beim Anzeigen neu (folgt dem Sprachwechsel), refresh die
-- Detailzeile (Fenster zieht Gebernamen nach, sobald auflösbar)
local function questEntry(questID, textOf, place, muted)
  return { text = textOf(), textOf = textOf, detail = DungeonQuestHints.Detail(questID, place), place = place, muted = muted,
    questID = questID, refresh = function() return DungeonQuestHints.Detail(questID, place) end }
end

function DungeonQuestHints.IsHidden(mapID)
  return ns.character ~= nil and ns.character.hiddenDungeonQuestHints[mapID] == true
end

function DungeonQuestHints.SetHidden(mapID, hidden)
  ns.character.hiddenDungeonQuestHints[mapID] = hidden or nil
end

-- Einträge für die Geber auf einer Zonenkarte (ohne abgeschaltete Dungeons)
function DungeonQuestHints.ZoneEntries(uiMapID)
  local entries = {}
  for _, point in ipairs(DungeonQuests.OffersOnMap(uiMapID)) do
    local place = { uiMapID = uiMapID, x = point.x, y = point.y }
    for _, offer in ipairs(point.offers) do
      if not DungeonQuestHints.IsHidden(offer.mapID) then
        table.insert(entries, questEntry(offer.questID, function() return offerText(offer) end, place))
      end
    end
  end
  return entries
end

local function currentZone()
  local mapID = C_Map and C_Map.GetBestMapForUnit and readable(C_Map.GetBestMapForUnit("player"))
  return mapID and ns.QuestLog.ZoneMapOf(mapID)
end

local function zoneName(uiMapID)
  local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(uiMapID)
  return info and readable(info.name) or ""
end

local function onZoneEntered()
  if not (ns.db and ns.db.dungeonQuestZoneHint and DungeonQuests.IsAvailable()) then return end
  local zone = currentZone()
  if not zone or shownZones[zone] then return end
  local entries = DungeonQuestHints.ZoneEntries(zone)
  ns.Debug("dungeonquests", "zone %s: %s offers", zone, #entries)
  if #entries == 0 then return end
  shownZones[zone] = true
  ns.DungeonQuestHint.Show(function() return string.format(L.DUNGEON_QUEST_ZONE_HINT_TITLE, zoneName(zone)) end, entries)
end

ns.RegisterEvent("ZONE_CHANGED_NEW_AREA", onZoneEntered)
ns.RegisterEvent("PLAYER_ENTERING_WORLD", onZoneEntered)

-- Zeile einer Instanzquest: "Titel", "Titel (Schritt 2/7)", später verfügbare mit "– Ab Level 18"
local function instanceQuestText(quest)
  local text = DungeonQuests.Title(quest.questID)
  if quest.step then text = string.format(L.DUNGEON_QUEST_HINT_STEP, text, quest.step, quest.total) end
  if not quest.available and (UnitLevel("player") or 0) < quest.minLevel then
    text = string.format(L.DUNGEON_QUEST_HINT_DETAIL, text, string.format(L.DUNGEON_QUEST_MIN_LEVEL, quest.minLevel))
  end
  return text
end

-- Einträge der offenen Quests einer Instanz (ohne exceptQuestID), annehmbare zuerst
local function instanceEntries(mapID, exceptQuestID)
  local entries = {}
  for _, quest in ipairs(DungeonQuests.InstanceQuests(mapID)) do
    if quest.questID ~= exceptQuestID then
      local place = DungeonQuests.GiverPlace(quest.questID)
      table.insert(entries, questEntry(quest.questID, function() return instanceQuestText(quest) end, place, not quest.available))
    end
  end
  return entries
end

-- Einträge für die übrigen offenen Quests der Instanz von questID; nil, wenn die Quest zu keiner Instanz gehört
function DungeonQuestHints.AcceptEntries(questID)
  local mapID = DungeonQuests.Instance(questID) or DungeonQuests.Chain(questID)
  if not mapID then return nil end
  return instanceEntries(mapID, questID), mapID
end

-- Quests einer Instanz zeigen (Rechtsklick auf den Eingang); false ohne offene Quests
function DungeonQuestHints.ShowInstance(mapID)
  local entries = instanceEntries(mapID)
  if #entries == 0 then return false end
  ns.DungeonQuestHint.Show(function()
    return string.format(L.DUNGEON_QUEST_ACCEPT_HINT_TITLE, ns.InstanceInfo.MapName(mapID))
  end, entries, mapID)
  return true
end

-- /lt dq: Hinweis der aktuellen Zone, sonst der zuletzt gezeigte
function DungeonQuestHints.Show()
  local zone = DungeonQuests.IsAvailable() and currentZone()
  local entries = zone and DungeonQuestHints.ZoneEntries(zone) or {}
  if #entries > 0 then
    ns.DungeonQuestHint.Show(function() return string.format(L.DUNGEON_QUEST_ZONE_HINT_TITLE, zoneName(zone)) end, entries)
  elseif not ns.DungeonQuestHint.ShowLast() then
    ns.Print(L.DUNGEON_QUEST_HINT_NONE)
  end
end

ns.QuestWatch.Subscribe({
  enabled = function(db) return db.dungeonQuestAcceptHint and DungeonQuests.IsAvailable() end,
  onAccepted = function(quest)
    local entries, mapID = DungeonQuestHints.AcceptEntries(quest.questID)
    ns.Debug("dungeonquests", "accepted %s: instance %s, %s more", quest.questID, mapID, entries and #entries)
    if not entries or #entries == 0 or DungeonQuestHints.IsHidden(mapID) then return end
    ns.DungeonQuestHint.Show(function()
      return string.format(L.DUNGEON_QUEST_ACCEPT_HINT_TITLE, ns.InstanceInfo.MapName(mapID))
    end, entries, mapID)
  end,
})

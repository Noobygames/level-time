-- Ziele von Dungeonquests an Namensplaketten (Einstellungen questTargetsTake / questTargetsParty, an; nur mit ns.DungeonDB,
-- also Classic Era und Forever): Gegner, deren NPC-ID ein Ziel (DungeonQuests.TargetNpcs) einer Quest ist, die der Charakter
-- jetzt annehmen kann ("take"), oder einer Quest eines Gruppenmitglieds (PartyQuestSync, "party").
-- Das Zeichnen übernimmt Assist/QuestMarks.lua (die eigene aktive Quest hat dort Vorrang). Die Umkehrkarte NPC-ID -> Quests
-- wird nur bei geänderter Revision der annehmbaren Quests (take) bzw. höchstens alle PARTY_SECONDS (party) neu aufgebaut.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    questTargetsTake = true,
    questTargetsParty = true,
  },
})

local QuestTargets = {}
ns.QuestTargets = QuestTargets

QuestTargets.TAKE = "take"
QuestTargets.PARTY = "party"

local PARTY_SECONDS = 2  -- Gruppenstände ändern sich über Nachrichten ohne Revision

local takeMap, takeRevision      -- [npcID] = { questID, ... }
local partyMap, partyBuiltAt

function QuestTargets.IsAvailable()
  return ns.DungeonQuests.IsAvailable()
end

local function addTargets(map, questID)
  local npcs = ns.DungeonQuests.TargetNpcs(questID)
  if not npcs then return end
  for npcID in pairs(npcs) do
    map[npcID] = map[npcID] or {}
    table.insert(map[npcID], questID)
  end
end

local function takeQuests()
  local revision = ns.DungeonQuests.Revision()
  if takeMap and takeRevision == revision then return takeMap end
  takeMap, takeRevision = {}, revision
  for questID in pairs(ns.DungeonDB.questInfo) do
    if ns.DungeonQuests.CanTake(questID) then addTargets(takeMap, questID) end
  end
  return takeMap
end

local function partyQuests()
  local now = GetTime()
  if partyMap and now - partyBuiltAt < PARTY_SECONDS then return partyMap end
  partyMap, partyBuiltAt = {}, now
  for _, quests in pairs(ns.PartyQuestSync.GetPeers()) do
    for questID in pairs(quests) do addTargets(partyMap, questID) end
  end
  return partyMap
end

-- "take", "party" oder nil für die Einheit (nur NPCs; geheime GUIDs ergeben nil)
function QuestTargets.KindOf(unit)
  if not (ns.db and QuestTargets.IsAvailable()) then return nil end
  local npcID = ns.QuestBlocklist.NpcId(UnitGUID(unit))
  if not npcID then return nil end
  if ns.db.questTargetsTake and takeQuests()[npcID] then return QuestTargets.TAKE end
  if ns.db.questTargetsParty and partyQuests()[npcID] then return QuestTargets.PARTY end
  return nil
end

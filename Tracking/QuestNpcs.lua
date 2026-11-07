-- Quest-NPCs und Orte lernen (Roadmap 350, mit Einstellung questLearning): wer eine Quest vergibt und wer sie annimmt,
-- mit Ort, und wo ihre Ziele vorankamen. Accountweit, damit Twinks eine eigene, wachsende Questkarte bekommen.
-- LevelTimerStatsDB.questNpcs[questID] = { giver = Ort, turnIn = Ort, spots = { Ort, ... } },
-- Ort = { name, npcId, mapID, x, y } (name/npcId nur bei NPCs).
-- Quellen: QUEST_DETAIL (Annahme-Dialog) und QUEST_COMPLETE (Abgabe-Dialog) mit GetQuestID(), UnitName("npc"),
-- UnitGUID("npc") (6. Feld = NPC-ID; in Forever-Instanzen geheim = nur Name), Position über DeathPlace.Position
-- (C_Map.GetBestMapForUnit, C_Map.GetPlayerMapPosition; in Instanzen nil). Zielorte bei jedem Anstieg eines Ziels
-- (QuestWatch), höchstens MAX_SPOTS je Quest, nahe Punkte (SPOT_DISTANCE) nur einmal.
local _, ns = ...

local QuestNpcs = {}
ns.QuestNpcs = QuestNpcs

QuestNpcs.MAX_SPOTS = 12
local SPOT_DISTANCE = 0.02  -- Kartenanteil: näher beieinander zählt als derselbe Ort
local NPC_UNIT = "npc"

local revision = 0

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function store()
  LevelTimerStatsDB.questNpcs = LevelTimerStatsDB.questNpcs or {}
  return LevelTimerStatsDB.questNpcs
end

local function questRecord(questID)
  local quests = store()
  quests[questID] = quests[questID] or { spots = {} }
  return quests[questID]
end

function QuestNpcs.Get(questID)
  return LevelTimerStatsDB and LevelTimerStatsDB.questNpcs and LevelTimerStatsDB.questNpcs[questID]
end

-- Stand der Daten (Karte zeichnet nur bei Änderung neu)
function QuestNpcs.Revision()
  return revision
end

local function place()
  local mapID, x, y = ns.DeathPlace.Position()
  if not mapID then return nil end
  return { mapID = mapID, x = x, y = y }
end

local function npcPlace()
  local entry = place() or {}
  local exists = readable(UnitExists(NPC_UNIT))
  if exists then
    local name = readable(UnitName(NPC_UNIT))
    entry.name = type(name) == "string" and name or nil
    entry.npcId = ns.QuestBlocklist.NpcId(readable(UnitGUID(NPC_UNIT)))
  end
  if not entry.mapID and not entry.name then return nil end
  return entry
end

local function currentQuestID()
  local questID = GetQuestID and readable(GetQuestID())
  return type(questID) == "number" and questID > 0 and questID or nil
end

local function remember(role)
  if not ns.db.questLearning then return end
  local questID = currentQuestID()
  local entry = questID and npcPlace()
  if not entry then return end
  questRecord(questID)[role] = entry
  revision = revision + 1
  ns.Debug("quests", "quest %s %s: %s (%s) map %s", questID, role, entry.name, entry.npcId, entry.mapID)
end

ns.RegisterEvent("QUEST_DETAIL", function() remember("giver") end)
ns.RegisterEvent("QUEST_COMPLETE", function() remember("turnIn") end)

local function nearSpot(spots, spot)
  for _, known in ipairs(spots) do
    if known.mapID == spot.mapID and math.abs(known.x - spot.x) <= SPOT_DISTANCE
      and math.abs(known.y - spot.y) <= SPOT_DISTANCE then
      return true
    end
  end
  return false
end

ns.QuestWatch.Subscribe({
  enabled = function(db) return db.questLearning end,
  onObjective = function(quest)
    local spot = place()
    if not spot then return end
    local spots = questRecord(quest.questID).spots
    if nearSpot(spots, spot) then return end
    table.insert(spots, spot)
    if #spots > QuestNpcs.MAX_SPOTS then table.remove(spots, 1) end
    revision = revision + 1
  end,
})

-- Name des gelernten Abgabe-NPCs (Abgabe-Übersicht)
function QuestNpcs.TurnInName(questID)
  local record = QuestNpcs.Get(questID)
  return record and record.turnIn and record.turnIn.name or nil
end

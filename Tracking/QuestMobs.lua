-- Questgegner und Quest-Gegenstände lernen (Roadmap 341, Einstellung questLearning, aus): steigt ein Questziel kurz
-- nach einem Kill oder einer eigenen Beute, merkt sich Level Time, welcher Gegner bzw. welcher Gegenstand dazu gehört.
-- Accountweit in LevelTimerStatsDB.questMobs[questID][Ziel] = { mobs = { [Name] = Treffer },
-- items = { [itemID] = Treffer }, itemNames = { [itemID] = Name } }; Namen in der Sprache des Clients. Erst ab
-- MIN_HITS Treffern gilt eine Zuordnung (gegen Zufälle), damit Twinks sie ab dem ersten Mal nutzen können.
-- Keine fremden Daten: alles kommt aus dem eigenen Spiel.
-- Quellen der Ereignisse:
--   Ziel gestiegen  Tracking/QuestWatch.lua (C_QuestLog.GetQuestObjectives in allen Clients)
--   Kill            neuer killLog-Eintrag (Journal.OnAdd; nur Kills mit XP) oder das tote Ziel ("target") im Moment
--                   des Anstiegs (graue Gegner ohne XP)
--   Beute           Loot.OnSelfLoot (CHAT_MSG_LOOT, eigene Beute); die Quelle eines Gegenstands ist der letzte Kill
--                   davor (höchstens DROP_SOURCE_SECONDS)
-- Zuordnung erst RESOLVE_DELAY nach dem Anstieg, weil Kill-Meldung und Questlog-Änderung in beliebiger Reihenfolge
-- kommen; gezählt wird, was höchstens MATCH_WINDOW Sekunden daneben liegt.
-- Genutzt von QuestMarks (Ersatz für C_QuestLog.UnitIsRelatedToActiveQuest in Classic), Zielknopf, Tooltips und
-- Questresten.
local _, ns = ...
local QuestLog = ns.QuestLog

local QuestMobs = {}
ns.QuestMobs = QuestMobs

QuestMobs.MIN_HITS = 2
local RESOLVE_DELAY = 1        -- Sekunden nach dem Anstieg, bevor zugeordnet wird
local MATCH_WINDOW = 1.5       -- Kill/Beute so nah am Anstieg zählt
local DROP_SOURCE_SECONDS = 30 -- Gegenstand stammt vom letzten Kill in dieser Zeit
local KEEP_SECONDS = 60        -- so lange bleiben Kills und Beute zum Abgleich gemerkt
local CHECK_SECONDS = 0.5
local ITEM_KIND, MONSTER_KIND = "item", "monster"

local recentKills = {}  -- { name, at }
local recentLoot = {}   -- { itemID, name, at, source }
local pending = {}      -- { questID, index, kind, at, deadTarget }
local openIndex         -- Abfrage-Index der offenen Ziele; nil = neu aufbauen

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function enabled(db)
  return db.questLearning
end

local function store()
  LevelTimerStatsDB.questMobs = LevelTimerStatsDB.questMobs or {}
  return LevelTimerStatsDB.questMobs
end

local function record(questID, index)
  local quests = store()
  quests[questID] = quests[questID] or {}
  local objective = quests[questID][index]
  if not objective then
    objective = { mobs = {}, items = {}, itemNames = {} }
    quests[questID][index] = objective
  end
  return objective
end

local function prune(list, now)
  while list[1] and now - list[1].at > KEEP_SECONDS do table.remove(list, 1) end
end

local function lastKillBefore(at, maxAge)
  for i = #recentKills, 1, -1 do
    local kill = recentKills[i]
    if kill.at <= at + MATCH_WINDOW and at - kill.at <= maxAge then return kill end
  end
end

---------------------------------------------------------------------------
-- Lernen
---------------------------------------------------------------------------
local function creditMob(objective, name)
  objective.mobs[name] = (objective.mobs[name] or 0) + 1
end

local function creditItem(objective, loot)
  objective.items[loot.itemID] = (objective.items[loot.itemID] or 0) + 1
  objective.itemNames[loot.itemID] = loot.name
  if loot.source then creditMob(objective, loot.source) end
end

-- Liegt Kill/Beute am Anstieg und zählte noch nicht für dieses Ziel? (ein Kill kann zwei Quests weiterbringen,
-- dasselbe Ziel aber nur einmal)
local function claim(rise, entry)
  if math.abs(entry.at - rise.at) > MATCH_WINDOW then return false end
  local key = rise.questID .. ":" .. rise.index
  entry.used = entry.used or {}
  if entry.used[key] then return false end
  entry.used[key] = true
  return true
end

-- Ein Anstieg: passende Beute (Sammelziele) bzw. passende Kills (Tötungsziele) gutschreiben
local function resolve(rise)
  local objective = record(rise.questID, rise.index)
  local learned = false
  if rise.kind ~= MONSTER_KIND then
    for _, loot in ipairs(recentLoot) do
      if claim(rise, loot) then
        creditItem(objective, loot)
        learned = true
      end
    end
  end
  if not learned and rise.kind ~= ITEM_KIND then
    local credited = {}
    for _, kill in ipairs(recentKills) do
      if not credited[kill.name] and claim(rise, kill) then
        credited[kill.name] = true
        creditMob(objective, kill.name)
        learned = true
      end
    end
    if not learned and rise.deadTarget then
      creditMob(objective, rise.deadTarget)
      learned = true
    end
  end
  ns.Debug("quests", "objective %s/%s rose (%s): learned %s", rise.questID, rise.index, rise.kind, learned)
  if learned then openIndex = nil end
end

local function resolvePending()
  local now = GetTime()
  prune(recentKills, now)
  prune(recentLoot, now)
  local index = 1
  while pending[index] do
    if now - pending[index].at >= RESOLVE_DELAY then
      resolve(table.remove(pending, index))
    else
      index = index + 1
    end
  end
end

-- Name des toten Ziels (graue Gegner geben keine XP und landen nicht im Kill-Journal)
local function deadTargetName()
  local dead, player = readable(UnitIsDead("target")), readable(UnitIsPlayer("target"))
  if dead ~= true or player ~= false then return nil end
  local name = readable(UnitName("target"))
  return type(name) == "string" and name ~= "" and name or nil
end

ns.QuestWatch.Subscribe({
  enabled = enabled,
  onObjective = function(quest, objective)
    table.insert(pending, { questID = quest.questID, index = objective.index, kind = objective.kind,
      at = GetTime(), deadTarget = deadTargetName() })
  end,
})

ns.Journal.OnAdd(function(logName, entry)
  if logName ~= "killLog" or not ns.db.questLearning or type(entry.name) ~= "string" then return end
  table.insert(recentKills, { name = entry.name, at = GetTime() })
end)

ns.Loot.OnSelfLoot(function(link)
  if not ns.db.questLearning or type(link) ~= "string" then return end
  local itemID = tonumber((link:match("item:(%d+)")))
  if not itemID then return end
  local now = GetTime()
  local source = lastKillBefore(now, DROP_SOURCE_SECONDS)
  table.insert(recentLoot, { itemID = itemID, name = link:match("%[(.-)%]"), at = now, source = source and source.name })
end)

ns.Every(CHECK_SECONDS, resolvePending, function(db) return db.questLearning end)

ns.RegisterApply(function(db)
  if not db.questLearning then recentKills, recentLoot, pending = {}, {}, {} end
end)

---------------------------------------------------------------------------
-- Abfragen: nur offene Ziele der Quests im eigenen Log zählen
---------------------------------------------------------------------------
local function confirmed(hits)
  return (hits or 0) >= QuestMobs.MIN_HITS
end

-- mobs[Name] und items[itemID] = Liste { questID, index, title, objective } offener Ziele
local function buildIndex()
  openIndex = { mobs = {}, items = {} }
  local quests = LevelTimerStatsDB and LevelTimerStatsDB.questMobs
  if not quests then return end
  for _, entry in ipairs(QuestLog.Entries()) do
    local learned = quests[entry.questID]
    if learned then
      local objectives = QuestLog.Objectives(entry.questID)
      for index, data in pairs(learned) do
        local objective = objectives[index]
        if objective and objective.finished == false then
          local hit = { questID = entry.questID, index = index, title = entry.title, objective = objective }
          for name, hits in pairs(data.mobs) do
            if confirmed(hits) then
              openIndex.mobs[name] = openIndex.mobs[name] or {}
              table.insert(openIndex.mobs[name], hit)
            end
          end
          for itemID, hits in pairs(data.items) do
            if confirmed(hits) then
              openIndex.items[itemID] = openIndex.items[itemID] or {}
              table.insert(openIndex.items[itemID], hit)
            end
          end
        end
      end
    end
  end
end

local function index()
  if not openIndex then buildIndex() end
  return openIndex
end

-- Offene Ziele, zu denen ein Gegner gehört; nil = keins (auch bei geheimem Namen)
function QuestMobs.ForMob(name)
  if type(name) ~= "string" or ns.IsSecret(name) then return nil end
  return index().mobs[name]
end

function QuestMobs.IsQuestMob(name)
  return QuestMobs.ForMob(name) ~= nil
end

-- Offene Ziele, zu denen ein Gegenstand gehört
function QuestMobs.ForItem(itemID)
  if type(itemID) ~= "number" then return nil end
  return index().items[itemID]
end

-- Namen aller Gegner offener Ziele (für den Zielknopf), alphabetisch
function QuestMobs.OpenMobNames()
  local names = {}
  for name in pairs(index().mobs) do table.insert(names, name) end
  table.sort(names)
  return names
end

-- Alle gelernten Gegenstände einer Quest (auch nach der Abgabe): { [itemID] = Name }
function QuestMobs.ItemsOf(questID)
  local items = {}
  local learned = LevelTimerStatsDB and LevelTimerStatsDB.questMobs and LevelTimerStatsDB.questMobs[questID]
  for _, data in pairs(learned or {}) do
    for itemID, hits in pairs(data.items) do
      if confirmed(hits) then items[itemID] = data.itemNames[itemID] or true end
    end
  end
  return items
end

-- Alle Quests (auch abgegebene), zu denen ein Gegenstand laut gelernten Daten gehört: Liste der Quest-IDs
function QuestMobs.QuestsOfItem(itemID)
  local quests = {}
  for questID, learned in pairs(LevelTimerStatsDB and LevelTimerStatsDB.questMobs or {}) do
    for _, data in pairs(learned) do
      if confirmed(data.items[itemID]) then
        quests[#quests + 1] = questID
        break
      end
    end
  end
  table.sort(quests)
  return quests
end

-- Stand zum Gegner aus dem Questlog: "Titel (3/8)" bzw. "3/8" und der Treffer; nil ohne gelerntes offenes Ziel
function QuestMobs.ProgressOf(name)
  local hits = QuestMobs.ForMob(name)
  local hit = hits and hits[1]
  if not hit then return nil end
  local objective = hit.objective
  if objective.have and objective.need then return objective.have .. "/" .. objective.need, hit end
  return nil, hit
end

local function invalidate() openIndex = nil end
ns.RegisterEvent("QUEST_LOG_UPDATE", invalidate)
ns.RegisterUnitEvent("UNIT_QUEST_LOG_CHANGED", "player", invalidate)
ns.OnLogin(invalidate)

-- /lt debug check: wie viele Quests, Ziele und Namen gelernt sind und was gerade offen ist
ns.DebugLog.AddCheck("quests.learned", function()
  local quests, objectives, names = 0, 0, 0
  for _, learned in pairs(LevelTimerStatsDB and LevelTimerStatsDB.questMobs or {}) do
    quests = quests + 1
    for _, data in pairs(learned) do
      objectives = objectives + 1
      for _ in pairs(data.mobs) do names = names + 1 end
    end
  end
  return { quests = quests, objectives = objectives, mobNames = names, openMobs = QuestMobs.OpenMobNames(),
    pending = #pending, related = C_QuestLog ~= nil and C_QuestLog.UnitIsRelatedToActiveQuest ~= nil }
end)

-- Gemeinsamer Beobachter des Questlogs: liest nach Änderungen alle Quests und Ziele einmal ein und meldet den
-- Abonnenten, was sich gegenüber dem letzten Stand geändert hat (Gruppenansage, Einblendung, Lernen, Orte).
-- Abonnent = { enabled(db), onObjective(quest, objective, old), onComplete(quest), onReady(quest),
-- onAccepted(quest) }; alle Felder außer enabled optional. quest = Eintrag aus Lib/QuestLog.lua, objective aus
-- QuestLog.Objectives, old = { finished, have } des letzten Stands.
--   onObjective  ein Ziel ist gestiegen (have größer) oder erfüllt worden
--   onComplete   alle Ziele erfüllt (Quest hat mindestens ein Ziel)
--   onReady      abgabebereit laut Client (QuestLog.Entry().ready)
--   onAccepted   neu angenommen (QUEST_ACCEPTED: Era questIndex, questID; Retail/Forever questID)
-- Gemeldet wird nur nach einem bekannten Stand: der erste Durchlauf nach Login, /reload oder dem Einschalten des
-- ersten Abonnenten zählt nur. Eingelesen wird gebündelt alle SCAN_SECONDS nach QUEST_LOG_UPDATE bzw.
-- UNIT_QUEST_LOG_CHANGED für den Spieler und nur, solange ein Abonnent eingeschaltet ist.
local _, ns = ...
local QuestLog = ns.QuestLog

local QuestWatch = {}
ns.QuestWatch = QuestWatch

local SCAN_SECONDS = 0.5

local subscribers = {}
local states = {}    -- [questID] = { objectives = { [index] = { finished, have } }, complete, ready }
local accepted = {}  -- angenommene Quests, die beim nächsten Einlesen gemeldet werden
local seen = false   -- erster Durchlauf seit Login/Einschalten erledigt
local dirty = true

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

function QuestWatch.Subscribe(subscriber)
  table.insert(subscribers, subscriber)
end

-- Ist ein Abonnent eingeschaltet?
function QuestWatch.IsActive(db)
  for _, subscriber in ipairs(subscribers) do
    if subscriber.enabled(db) then return true end
  end
  return false
end

local function emit(name, ...)
  for _, subscriber in ipairs(subscribers) do
    if subscriber[name] and subscriber.enabled(ns.db) then ns.SafeCall(subscriber[name], ...) end
  end
end

local function rose(objective, old)
  if not old then return false end
  if objective.finished == true and old.finished == false then return true end
  return objective.have ~= nil and old.have ~= nil and objective.have > old.have
end

-- Stand einer Quest einlesen und Änderungen gegenüber dem letzten Stand melden. Der Stand je Quest und Ziel wird an
-- Ort und Stelle fortgeschrieben (Roadmap 392: keine neuen Tabellen je Durchlauf); gemeldet wird vor dem Überschreiben,
-- old ist also noch der letzte Stand.
local function update(quest)
  local questID = quest.questID
  local state = states[questID]
  local known = seen and state ~= nil
  if not state then
    state = { objectives = {} }
    states[questID] = state
  end
  local wasComplete, wasReady = state.complete, state.ready
  local objectives = QuestLog.Objectives(questID)
  local stored = state.objectives
  local complete = #objectives > 0
  for index, objective in ipairs(objectives) do
    local old = stored[index]
    if objective.finished == nil then
      complete = false
      stored[index] = false  -- unlesbar: beim nächsten Mal kein Vergleich (wie ohne Stand)
    else
      complete = complete and objective.finished
      if known and old and rose(objective, old) then emit("onObjective", quest, objective, old) end
      if old then
        old.finished, old.have = objective.finished, objective.have
      else
        stored[index] = { finished = objective.finished, have = objective.have }
      end
    end
  end
  for index = #stored, #objectives + 1, -1 do stored[index] = nil end
  state.complete, state.ready = complete, quest.ready == true
  if accepted[questID] then
    accepted[questID] = nil
    emit("onAccepted", quest)
  end
  if known and not wasComplete and state.complete then emit("onComplete", quest) end
  if known and not wasReady and state.ready then emit("onReady", quest) end
end

function QuestWatch.Scan()
  if not dirty then return end
  dirty = false
  for _, quest in ipairs(QuestLog.Entries()) do update(quest) end
  seen = true
end

local function reset()
  states, accepted, seen, dirty = {}, {}, false, true
end

local function markDirty() dirty = true end
ns.RegisterEvent("QUEST_LOG_UPDATE", markDirty)
ns.RegisterUnitEvent("UNIT_QUEST_LOG_CHANGED", "player", markDirty)

-- Das letzte Argument ist die Quest-ID (Era: questIndex, questID)
local function onAccepted(first, second)
  local questID = readable(second) or readable(first)
  if seen and type(questID) == "number" then accepted[questID] = true end
  dirty = true
end
ns.RegisterEvent("QUEST_ACCEPTED", onAccepted)

local function forget(questID)
  questID = readable(questID)
  if questID then states[questID], accepted[questID] = nil, nil end
end
ns.RegisterEvent("QUEST_REMOVED", forget)
ns.RegisterEvent("QUEST_TURNED_IN", forget)

-- Ausgeschaltet nichts merken; beim Einschalten zählt der erste Durchlauf nur den Stand
ns.RegisterApply(function(db)
  if not QuestWatch.IsActive(db) then reset() end
end)

ns.Every(SCAN_SECONDS, QuestWatch.Scan, QuestWatch.IsActive)
ns.OnLogin(reset)

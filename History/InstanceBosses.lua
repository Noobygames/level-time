-- Boss-Kills je Instanz-Lauf (Roadmap 483): run.bosses = besiegte encounterIDs in Kill-Reihenfolge als Text
-- ("2741,2747"; so passt es als ein Feld in den kompakten Journal-Speicher), run.splits = Laufzeit in ganzen Sekunden je
-- Kill in derselben Reihenfolge ("192,305", Roadmap 493; Auswertung in InstanceRuns.lua). Quelle ENCOUNTER_END(encounterID,
-- encounterName, difficultyID, groupSize, success) mit success = 1; Fallback (falls ein Client das Event bei einem
-- Boss nicht schickt): Kampflog UNIT_DIED eines Gegners, dessen Name ein Boss der Instanz ist (Encounter- und
-- NPC-Name sind bei Classic-Dungeonbossen gleich; geheime Namen fallen weg).
-- Bossliste je Karte und Schwierigkeit aus ns.BossData (Assist/BossData/<flavor>.lua, DB2 DungeonEncounter),
-- Reihenfolge = OrderIndex, der letzte gilt als Endboss: fällt er, meldet der Chat "Dungeon abgeschlossen" (mit
-- "neue Bestzeit", wenn er schneller fiel als im besten abgeschlossenen Lauf derselben Instanz).
-- Boss-Level und optionale Rar-Bosse (nur Forever) aus ns.InstanceGuide.bossLevels/rareBosses
-- (Assist/InstanceData/forever_guide.lua): Rar-Bosse zählen nicht zum Fortschritt ("5/5", eigene Zahl über
-- RaresKilled) und nie als Endboss (Endboss = letzter Boss der Liste, der kein Rar-Boss ist).
-- shortcut: Retail hat keine Bossliste (nur die Zahl der Kills), bei Bedarf über das Encounter-Journal nachrüsten.
local _, ns = ...
local L = ns.L

local InstanceBosses = {}
ns.InstanceBosses = InstanceBosses

local SUCCESS = 1
local SEPARATOR = ","
local ICON_SIZE = 14
local ICON_DEAD = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
local ICON_ALIVE = "Interface\\Icons\\INV_Misc_Head_Dragon_01"
local localeIndex  -- Spalte der Client-Sprache in ns.BossData.locales (unbekannte Sprache: 1 = Englisch)

local lastEvent  -- letzte Meldung für die Debug-Prüfung: { source, id, name, success, counted }

local function nameColumn()
  if localeIndex then return localeIndex end
  localeIndex = 1
  for index, locale in ipairs(ns.BossData and ns.BossData.locales or {}) do
    if locale == GetLocale() then localeIndex = index end
  end
  return localeIndex
end

-- Bosse einer Instanz in Reihenfolge ({ encounterID, ... }) oder nil, wenn der Client keine Daten hat
function InstanceBosses.List(mapID, difficultyID)
  local byDifficulty = ns.BossData and mapID and ns.BossData.maps[mapID]
  if not byDifficulty then return nil end
  return byDifficulty[difficultyID or 0] or byDifficulty[0]
end

-- Name eines Bosses in der Sprache des Clients (nil ohne Daten)
function InstanceBosses.Name(encounterID)
  local names = ns.BossData and ns.BossData.names[encounterID]
  if type(names) == "table" then
    local name = names[nameColumn()]
    return (name and name ~= "") and name or names[1]
  end
  return names
end

-- Level eines Bosses oder nil ohne Daten
function InstanceBosses.Level(encounterID)
  return ns.InstanceGuide and ns.InstanceGuide.bossLevels[encounterID]
end

-- Optionaler Rar-Boss (zählt nicht zum Fortschritt, nie Endboss)?
function InstanceBosses.IsRare(encounterID)
  local rares = ns.InstanceGuide and ns.InstanceGuide.rareBosses
  return rares ~= nil and rares[encounterID] == true
end

-- Endboss einer Bossliste: der letzte, der kein Rar-Boss ist (nil ohne Liste)
function InstanceBosses.EndBoss(list)
  if not list then return nil end
  for index = #list, 1, -1 do
    if not InstanceBosses.IsRare(list[index]) then return list[index] end
  end
  return nil
end

-- Zahl der besiegten Rar-Bosse eines Laufs oder Journal-Eintrags
function InstanceBosses.RaresKilled(record)
  local count = 0
  for id in pairs(InstanceBosses.Killed(record)) do
    if InstanceBosses.IsRare(id) then count = count + 1 end
  end
  return count
end

-- Letzte Boss-Meldung (für die Fehlersuche): { source = "encounter"|"died", id, name, success, counted } oder nil
function InstanceBosses.LastEvent()
  return lastEvent
end

-- Besiegte Bosse eines Laufs oder Journal-Eintrags als Menge { [encounterID] = true } und ihre Zahl
function InstanceBosses.Killed(record)
  local killed, count = {}, 0
  for id in string.gmatch(record.bosses or "", "%d+") do
    killed[tonumber(id)] = true
    count = count + 1
  end
  return killed, count
end

-- Besiegte und nötige Bosse der Bossliste ohne Rar-Bosse; nil ohne Liste
function InstanceBosses.Progress(record)
  local list = InstanceBosses.List(record.mapID, record.difficultyID)
  if not list then return nil end
  local killed = InstanceBosses.Killed(record)
  local done, required = 0, 0
  for _, id in ipairs(list) do
    if not InstanceBosses.IsRare(id) then
      required = required + 1
      if killed[id] then done = done + 1 end
    end
  end
  return done, required
end

-- "3/7" (mit Bossliste, ohne Rar-Bosse), "3" (ohne Liste) oder nil, wenn es weder Liste noch Kill gibt
function InstanceBosses.ProgressText(record)
  local done, required = InstanceBosses.Progress(record)
  if done then return done .. "/" .. required end
  local _, count = InstanceBosses.Killed(record)
  return count > 0 and tostring(count) or nil
end

-- Tooltip-Zeilen: je Boss Symbol (Totenkopf = besiegt, Kopf = lebt), Position im Dungeon, Name und Level, wo bekannt;
-- nil ohne Liste
function InstanceBosses.TooltipLines(record)
  local list = InstanceBosses.List(record.mapID, record.difficultyID)
  if not list then return nil end
  local killed = InstanceBosses.Killed(record)
  local lines = { record.name or "?" }
  for index, id in ipairs(list) do
    local icon = killed[id] and ICON_DEAD or ICON_ALIVE
    local line = string.format("|T%s:%d|t %d. %s", icon, ICON_SIZE, index, InstanceBosses.Name(id) or "?")
    local level = InstanceBosses.Level(id)
    lines[#lines + 1] = level and string.format("%s (%d)", line, level) or line
  end
  return lines
end

-- Boss im offenen, laufenden Lauf als besiegt eintragen (jeder nur einmal); Endboss meldet den Abschluss
local function recordKill(id, source)
  local run = ns.Instances.GetCurrentRun()
  if not run or not ns.Instances.IsRunning() then return false end
  if InstanceBosses.Killed(run)[id] then return false end
  run.bosses = run.bosses and (run.bosses .. SEPARATOR .. id) or tostring(id)
  local split = tostring(math.floor(ns.Instances.GetRunSeconds(run)))
  run.splits = run.splits and (run.splits .. SEPARATOR .. split) or split
  ns.Instances.NoteGroupSize(run)
  ns.Debug("instances", "boss killed (%s): %s, bosses %s", source, id, run.bosses)
  local list = InstanceBosses.List(run.mapID, run.difficultyID)
  if list and InstanceBosses.EndBoss(list) == id then
    ns.Debug("instances", "dungeon completed: %s, bosses %s", run.name, InstanceBosses.ProgressText(run))
    local text = string.format(L.INSTANCE_COMPLETED, run.name or "?",
      ns.Format.Duration(ns.Instances.GetRunSeconds(run)), InstanceBosses.ProgressText(run))
    ns.Print(ns.InstanceRuns.IsNewBest(run) and (text .. " " .. L.DUNGEON_RUN_NEW_BEST) or text)
  end
  return true
end

ns.RegisterEvent("ENCOUNTER_END", function(encounterID, encounterName, _, _, success)
  if ns.IsSecret(encounterID) or ns.IsSecret(success) then return end
  local counted = success == SUCCESS and type(encounterID) == "number" and recordKill(encounterID, "encounter")
  lastEvent = { source = "encounter", id = encounterID, success = success, counted = counted,
    name = not ns.IsSecret(encounterName) and encounterName or nil }
end)

---------------------------------------------------------------------------
-- Fallback über das Kampflog: Name des gestorbenen Gegners -> Boss der laufenden Instanz
---------------------------------------------------------------------------
local namesOf = setmetatable({}, { __mode = "k" })  -- Bossliste -> { [Name] = encounterID }

local function bossByName(list, name)
  local index = namesOf[list]
  if not index then
    index = {}
    for _, id in ipairs(list) do
      local bossName = InstanceBosses.Name(id)
      if bossName then index[bossName] = id end
    end
    namesOf[list] = index
  end
  return index[name]
end

-- Feldreihenfolge wie in DeathCounter.lua: 2 = Event, 9 = Ziel-Name
local getCombatLogEventInfo = (C_CombatLog and C_CombatLog.GetCurrentEventInfo) or CombatLogGetCurrentEventInfo
local isSecret = issecretvalue

-- Läuft für jedes Kampflog-Event: zuerst die billigen Abbrüche (kein Tod, kein laufender Lauf mit Bossliste)
local function onCombatLogEvent()
  local ok, _, subevent, _, _, _, _, _, _, destName = pcall(getCombatLogEventInfo)
  if not ok or subevent ~= "UNIT_DIED" or (isSecret and isSecret(destName)) or type(destName) ~= "string" then return end
  local run = ns.Instances.GetCurrentRun()
  local list = run and ns.Instances.IsRunning() and InstanceBosses.List(run.mapID, run.difficultyID)
  local id = list and bossByName(list, destName)
  if id then
    lastEvent = { source = "died", id = id, name = destName, counted = recordKill(id, "died") }
  end
end

if getCombatLogEventInfo and ns.BossData then
  local combatLogFrame = CreateFrame("Frame")
  if pcall(combatLogFrame.RegisterEvent, combatLogFrame, "COMBAT_LOG_EVENT_UNFILTERED") then
    ns.SetEventScript(combatLogFrame, "COMBAT_LOG_EVENT_UNFILTERED InstanceBosses", onCombatLogEvent)
  end
end

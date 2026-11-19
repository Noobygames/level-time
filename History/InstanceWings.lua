-- Flügel eines Laufs schon vor dem ersten Boss-Kill erkennen (LT-318). Karten mit Flügeln (ns.InstanceGuide.wings, nur
-- Forever: Kloster, Stratholme, Düsterbruch, Schwarzfelsspitze) teilen sich eine Karten-ID; InstanceBosses kennt den
-- Flügel sonst erst nach dem ersten Boss. Ergebnis ist der Hinweis run.wing (ein Boss-Kill geht immer vor,
-- InstanceBosses.BossWing). Quellen:
--   1. Unterzone (GetSubZoneText, ZoneScriptDocumentation; im Debug-Log 2026-11-16 in Forever-Instanzen lesbar, z.B.
--      "Die Kapelle des Kreuzfahrers" in der Kathedrale); Wechsel über ZONE_CHANGED / ZONE_CHANGED_INDOORS
--   2. Aktivitäten des eigenen Gruppensuche-Eintrags (LFG_LIST_ACTIVE_ENTRY_UPDATE, C_LFGList.GetActiveEntryInfo und
--      GetActivityInfoTable(...).mapID, forever LFGListInfoDocumentation.lua; den Eintrag hat nur, wer ihn erstellt)
--   3. NPC-IDs gestorbener Gegner (Event UNIT_DIED; in Forever-Instanzen sind die GUIDs meist geheim, dann fällt das weg)
-- Alles wird gelernt, sobald ein Boss-Kill den Flügel festlegt: die in diesem Lauf besuchten Unterzonen, gestorbenen
-- Gegner und die Aktivitäten des Eintrags mit dieser Karte gehören dann zu dem Flügel. Account-weit gespeichert in
-- LevelTimerStatsDB.instanceWings = { subzones = { [Karten-ID] = { [Unterzone] = Flügel } },
--   npcs = { [Karten-ID] = { [NPC-ID] = Flügel } }, activities = { [Aktivitäts-ID] = Flügel } };
-- AMBIGUOUS = in mehreren Flügeln gesehen, ist nie ein Hinweis. Unterzonen sind Texte der Client-Sprache.
local _, ns = ...
if not (ns.InstanceGuide and ns.InstanceGuide.wings) then return end

local InstanceWings = {}
ns.InstanceWings = InstanceWings

local AMBIGUOUS = 0
local HAS_LFG = C_LFGList ~= nil and C_LFGList.GetActiveEntryInfo ~= nil and C_LFGList.GetActivityInfoTable ~= nil

-- Im Lauf seenRun gesehen und noch nicht gelernt: { subzones = { [Text] = true }, npcs = { [NPC-ID] = true } }
local seen, seenRun = { subzones = {}, npcs = {} }, nil
local listed = {}  -- Aktivitäts-IDs des letzten eigenen Gruppensuche-Eintrags (bleibt nach dem Austragen)

local function store()
  LevelTimerStatsDB.instanceWings = LevelTimerStatsDB.instanceWings or {}
  local db = LevelTimerStatsDB.instanceWings
  db.subzones, db.npcs, db.activities = db.subzones or {}, db.npcs or {}, db.activities or {}
  return db
end

-- Gelernte Tabelle einer Art für eine Karte (wird angelegt)
local function learnedFor(db, kind, mapID)
  db[kind][mapID] = db[kind][mapID] or {}
  return db[kind][mapID]
end

-- Flügel eintragen; widerspricht er dem bisher gelernten, ist der Schlüssel mehrdeutig
local function learn(known, key, wing)
  local before = known[key]
  known[key] = (before == nil or before == wing) and wing or AMBIGUOUS
end

local function asHint(wing)
  return wing ~= AMBIGUOUS and wing or nil
end

-- Offener, laufender Lauf auf einer Karte mit Flügeln, sonst nil
local function wingRun()
  local run = ns.Instances.GetCurrentRun()
  if not run or not ns.Instances.IsRunning() or not ns.InstanceGuide.wings[run.mapID or 0] then return nil end
  if seenRun ~= run then seen, seenRun = { subzones = {}, npcs = {} }, run end
  return run
end

local function currentSubZone()
  local text = GetSubZoneText and GetSubZoneText()
  if type(text) ~= "string" or ns.IsSecret(text) or text == "" then return nil end
  return text
end

local function activityMap(activityID)
  local info = C_LFGList.GetActivityInfoTable(activityID)
  if type(info) ~= "table" or ns.IsSecret(info.mapID) then return nil end
  return info.mapID
end

-- Aktivitäten des Eintrags, die zur Karte des Laufs gehören
local function runActivities(run)
  local result = {}
  if not HAS_LFG then return result end
  for _, activityID in ipairs(listed) do
    if activityMap(activityID) == run.mapID then result[#result + 1] = activityID end
  end
  return result
end

-- Erster Hinweis aus den gesehenen Schlüsseln einer Art: Flügel und Quelle für das Debug-Log
local function hintFrom(keys, known, label)
  for key in pairs(keys) do
    local wing = asHint(known[key])
    if wing then return wing, label .. " " .. key end
  end
end

-- Mit Boss-Flügel lernen, sonst (ohne Hinweis) den Flügel aus dem Gelernten ableiten
local function update(run)
  local db = store()
  local subzones, npcs = learnedFor(db, "subzones", run.mapID), learnedFor(db, "npcs", run.mapID)
  local bossWing = ns.InstanceBosses.BossWing(run)
  if bossWing then
    for text in pairs(seen.subzones) do learn(subzones, text, bossWing) end
    for npcID in pairs(seen.npcs) do learn(npcs, npcID, bossWing) end
    -- Nur ein Eintrag mit genau einer Aktivität der Karte sagt etwas über den Flügel; mehrere (z.B. alle Flügel
    -- gelistet) würden die übrigen falsch lernen und dauerhaft mehrdeutig machen
    local activities = runActivities(run)
    if #activities == 1 then learn(db.activities, activities[1], bossWing) end
    seen.subzones, seen.npcs = {}, {}
    return
  end
  if run.wing then return end
  local wing, source
  for _, activityID in ipairs(runActivities(run)) do
    if not wing then wing, source = asHint(db.activities[activityID]), "activity " .. activityID end
  end
  if not wing then wing, source = hintFrom(seen.subzones, subzones, "subzone") end
  if not wing then wing, source = hintFrom(seen.npcs, npcs, "npc") end
  if wing then
    run.wing = wing
    ns.Debug("instances", "wing hint: %s (%s) from %s", wing, run.name, source)
  end
end

-- Aktivitäten des eigenen Eintrags merken (ohne Eintrag bleiben die letzten)
local function readListing()
  -- Unter Chat-Sperre (eingeschränkte Instanz) kann die Struktur geheime Felder haben: nicht anfassen
  if not HAS_LFG or ns.GroupChat.Locked() then return end
  local entry = C_LFGList.GetActiveEntryInfo()
  if type(entry) ~= "table" or ns.IsSecret(entry) or type(entry.activityIDs) ~= "table" then return end
  listed = {}
  for _, activityID in ipairs(entry.activityIDs) do
    if not ns.IsSecret(activityID) then listed[#listed + 1] = activityID end
  end
end

-- Unterzone merken und neu bewerten
local function onZoneChanged()
  local run = wingRun()
  if not run then return end
  local text = currentSubZone()
  if text then seen.subzones[text] = true end
  update(run)
end

-- Erst der billige Lauf-Test: außerhalb von Flügel-Instanzen kein GUID-Parsen je Tod
ns.RegisterEvent("UNIT_DIED", function(guid)
  local run = wingRun()
  local npcID = run and ns.InstanceBosses.NpcIDOf(guid)
  if not npcID then return end
  seen.npcs[npcID] = true
  update(run)
end)

-- Nach InstanceBosses (.toc-Reihenfolge): der Kill steht schon im Lauf
ns.RegisterEvent("ENCOUNTER_END", onZoneChanged)
ns.RegisterEvent("ZONE_CHANGED", onZoneChanged)
ns.RegisterEvent("ZONE_CHANGED_INDOORS", onZoneChanged)
ns.InstanceCopy.OnEnter(function()
  readListing()
  onZoneChanged()
end)
if HAS_LFG then
  ns.RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE", function()
    readListing()
    local run = wingRun()
    if run then update(run) end
  end)
end

-- Für den Debug-Check LT318.wings.state: gemerkte Aktivitäten, aktuelle Unterzone, noch nicht gelernte Unterzonen und
-- Gegner sowie die Zahl der gelernten Unterzonen und Gegner je Karte
function InstanceWings.State()
  local db = LevelTimerStatsDB and LevelTimerStatsDB.instanceWings or {}
  local function counts(byMap)
    local result = {}
    for mapID, known in pairs(byMap or {}) do
      local count = 0
      for _ in pairs(known) do count = count + 1 end
      result[mapID] = count
    end
    return result
  end
  local pendingZones = {}
  for text in pairs(seen.subzones) do pendingZones[#pendingZones + 1] = text end
  local pendingNpcs = 0
  for _ in pairs(seen.npcs) do pendingNpcs = pendingNpcs + 1 end
  return { listed = listed, subZone = currentSubZone() or false, pendingZones = pendingZones, pending = pendingNpcs,
    learned = counts(db.npcs), learnedZones = counts(db.subzones), zones = db.subzones or {} }
end

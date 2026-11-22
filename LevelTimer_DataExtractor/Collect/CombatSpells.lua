-- Gegner-Zauber aus dem Kampflog (LT-52, ohne Kampflog: UNIT_SPELLCAST_*, LT-278): in Instanzen je NPC die Zauber, die
-- er wirkt, als Aura setzt oder womit er Schaden macht. Damit lassen sich die Zauber-IDs der Mechaniken
-- (Assist/InstanceData/mechanics.lua) prüfen
-- (tools/extractor, make extract-check).
-- Felder: instances[Karten-ID].spells[npcID][Schlüssel] = { names, count, events[Kampflog-Event] = Anzahl };
--   Schlüssel = Zauber-ID, ohne lesbare ID (Classic-Kampflog kennt teils nur 0) "name:<Zaubername>".
-- Feldreihenfolge von C_CombatLog.GetCurrentEventInfo bzw. CombatLogGetCurrentEventInfo (wie
-- History/InstanceBosses.lua): 2 Event, 4 Quell-GUID, 12 Zauber-ID, 13 Zaubername (SPELL_*-Präfix).
-- Ohne Kampflog (LT-278): UNIT_SPELLCAST_START/CHANNEL_START/SUCCEEDED von Ziel, Fokus, Mouseover, Namensplaketten und Bossrahmen
-- (nur sichtbare Einheiten, keine Auren und kein Schaden), gespeichert unter denselben Event-Schlüsseln wie der Kampflog.
local _, X = ...

local CombatSpells = {}
X.CombatSpells = CombatSpells

local MAX_SPELLS_PER_NPC = 60  -- danach zählen nur noch bekannte Zauber dieses NPCs
local TRACKED = { SPELL_CAST_START = true, SPELL_CAST_SUCCESS = true, SPELL_AURA_APPLIED = true, SPELL_DAMAGE = true,
  SPELL_PERIODIC_DAMAGE = true }

local getEventInfo = X.GET_COMBAT_EVENT
local currentInstance  -- Karten-ID oder nil; bei jedem Zonenwechsel neu gelesen

-- Zähler dieser Sitzung für die Prüfung LT52.combatlog.guid: sind Quell-GUIDs in Instanzen lesbar?
local status = { events = 0, npcSources = 0, secretGuids = 0, otherSources = 0, nameKeys = 0, castEvents = 0,
  spellIDReadable = 0, spellIDSecret = 0 }

local function onWorld()
  currentInstance = X.InstanceMap()
end
X.On("PLAYER_ENTERING_WORLD", onWorld)
X.On("ZONE_CHANGED_NEW_AREA", onWorld)

local function spellKey(spellID, spellName)
  spellID = X.Readable(spellID)
  if type(spellID) == "number" and spellID > 0 then return spellID end
  spellName = X.Readable(spellName)
  if type(spellName) == "string" and spellName ~= "" then
    status.nameKeys = status.nameKeys + 1
    return "name:" .. spellName
  end
end

local function record(npcID, key, spellName, subevent)
  local instance = X.Record("instances", currentInstance)
  instance.spells = instance.spells or {}
  local spells = instance.spells[npcID]
  if not spells then
    spells = { count = 0 }
    instance.spells[npcID] = spells
  end
  local spell = spells[key]
  if not spell then
    if spells.count >= MAX_SPELLS_PER_NPC then return end
    spell = { count = 0, events = {} }
    spells[key] = spell
    spells.count = spells.count + 1
  end
  X.SetName(spell, spellName)
  spell.count = spell.count + 1
  X.Increment(spell.events, subevent)
end

-- Läuft für jedes Kampflog-Event: zuerst die billigen Abbrüche (fremdes Event, keine Instanz)
local function onCombatLogEvent()
  if not currentInstance or not X.db then return end
  local ok, _, subevent, _, sourceGUID, _, _, _, _, _, _, _, spellID, spellName = pcall(getEventInfo)
  if not ok or X.IsSecret(subevent) or not TRACKED[subevent] then return end
  status.events = status.events + 1
  if X.IsSecret(sourceGUID) then
    status.secretGuids = status.secretGuids + 1
    return
  end
  local kind, npcID = X.ParseGuid(sourceGUID)
  if (kind ~= "Creature" and kind ~= "Vehicle") or not npcID then
    status.otherSources = status.otherSources + 1
    return
  end
  status.npcSources = status.npcSources + 1
  status.lastGuid = sourceGUID
  local key = spellKey(spellID, spellName)
  if key then record(npcID, key, X.Readable(spellName), subevent) end
end

if getEventInfo then X.On("COMBAT_LOG_EVENT_UNFILTERED", onCombatLogEvent) end

---------------------------------------------------------------------------
-- Ohne Kampflog: UNIT_SPELLCAST_*
---------------------------------------------------------------------------
local CAST_EVENTS = { UNIT_SPELLCAST_START = "SPELL_CAST_START", UNIT_SPELLCAST_CHANNEL_START = "SPELL_CAST_START",
  UNIT_SPELLCAST_SUCCEEDED = "SPELL_CAST_SUCCESS" }
local MAX_SEEN_CASTS = 200  -- gemerkte Zauberwürfe; danach neu anfangen
local seenCasts, seenCount = {}, 0  -- "<Event>:<castGUID>": derselbe Wurf kommt über Ziel und Namensplakette doppelt

-- Gegnerische Einheit: Ziel, Fokus, Mouseover, Namensplakette, Bossrahmen (nicht der Spieler, nicht Gruppe)
local function isEnemyToken(unit)
  return unit == "target" or unit == "focus" or unit == "mouseover" or unit:find("^nameplate%d+$") ~= nil or unit:find("^boss%d+$") ~= nil
end

local function onUnitCast(event, unit, castGUID, spellID)
  if not currentInstance or not X.db or X.IsSecret(unit) or type(unit) ~= "string" or not isEnemyToken(unit) then
    return
  end
  status.events = status.events + 1
  status.castEvents = status.castEvents + 1
  if X.IsSecret(spellID) then status.spellIDSecret = status.spellIDSecret + 1
  else status.spellIDReadable = status.spellIDReadable + 1 end
  local guid = X.Call("UnitGUID", unit)
  if not guid then
    status.secretGuids = status.secretGuids + 1
    return
  end
  local kind, npcID = X.ParseGuid(guid)
  if (kind ~= "Creature" and kind ~= "Vehicle") or not npcID then
    status.otherSources = status.otherSources + 1
    return
  end
  status.npcSources = status.npcSources + 1
  status.lastGuid = guid
  local subevent = CAST_EVENTS[event]
  castGUID = X.Readable(castGUID)
  if castGUID then
    local seenKey = subevent .. ":" .. tostring(castGUID)
    if seenCasts[seenKey] then return end
    if seenCount >= MAX_SEEN_CASTS then seenCasts, seenCount = {}, 0 end
    seenCasts[seenKey] = true
    seenCount = seenCount + 1
  end
  local spellName = X.Call("C_Spell.GetSpellName", X.Readable(spellID))
  local key = spellKey(spellID, spellName)
  if key then record(npcID, key, spellName, subevent) end
end

if not getEventInfo then
  for event in pairs(CAST_EVENTS) do
    X.On(event, function(...) onUnitCast(event, ...) end)
  end
end

-- Für die Prüfung: Kampflog-API vorhanden, aktuelle Instanz, Zähler dieser Sitzung
function CombatSpells.Status()
  return { api = getEventInfo ~= nil, unitCasts = getEventInfo == nil, instance = currentInstance, events = status.events,
    npcSources = status.npcSources, secretGuids = status.secretGuids, otherSources = status.otherSources,
    nameKeys = status.nameKeys, castEvents = status.castEvents, spellIDReadable = status.spellIDReadable,
    spellIDSecret = status.spellIDSecret, lastGuid = status.lastGuid }
end

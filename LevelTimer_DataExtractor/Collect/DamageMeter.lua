-- Gegner-Zauber und Todesursachen aus C_DamageMeter (LT-286, WoW Forever ohne Kampflog; Prüfung LT285.damageMeter.api).
-- Nach Kampfende (im Kampf sind die Werte geheim) wird die neueste Sitzung gelesen:
--   instances[Karten-ID].damageTaken[npcID][Schlüssel] = { names, count, deadly, avoidable }  (DamageTaken-Zauber je Quelle)
--   instances[Karten-ID].deaths = Anzahl Tode des Spielers (Deaths-Typ, isLocalPlayer)
-- Schlüssel wie bei CombatSpells: Zauber-ID, sonst "name:<Name>". Jede Sitzung wird nur einmal gezählt.
-- Läuft nur, wenn IsDamageMeterAvailable() wahr ist und die Sitzungs-Funktionen existieren.
local _, X = ...

local DamageMeter = {}
X.DamageMeter = DamageMeter

local MAX_SOURCES = 40  -- Quellen je Sitzung
local lastSession       -- zuletzt gelesene Sitzungs-ID
local status = { reads = 0, spells = 0, deaths = 0, secret = 0 }

local function available()
  local ok, isAvailable = pcall(C_DamageMeter.IsDamageMeterAvailable)
  return ok and isAvailable == true
end

-- Funktionsaufruf; nil bei Fehler, geheimem Ergebnis oder Nicht-Tabelle
local function fetch(fn, ...)
  local ok, value = pcall(fn, ...)
  if ok and X.IsSecret(value) then status.secret = status.secret + 1 end
  if not ok or type(value) ~= "table" or X.IsSecret(value) then return nil end
  return value
end

-- Liste aus einem Feld der Sitzung; leer bei geheimem oder fehlendem Feld
local function list(session, field)
  local value = session and session[field]
  if type(value) ~= "table" or X.IsSecret(value) then return {} end
  return value
end

local function recordSpell(instance, npcID, spell)
  local spellID, name = X.Readable(spell.spellID), X.Readable(spell.creatureName)
  local key = type(spellID) == "number" and spellID > 0 and spellID or (type(name) == "string" and name ~= "" and "name:" .. name)
  if not key then return end
  instance.damageTaken = instance.damageTaken or {}
  instance.damageTaken[npcID] = instance.damageTaken[npcID] or {}
  local entry = instance.damageTaken[npcID][key]
  if not entry then
    entry = { count = 0 }
    instance.damageTaken[npcID][key] = entry
  end
  X.SetName(entry, name)
  X.Increment(entry, "count")
  if X.Readable(spell.isDeadly) == true then X.Increment(entry, "deadly") end
  if X.Readable(spell.isAvoidable) == true then X.Increment(entry, "avoidable") end
  status.spells = status.spells + 1
end

local function readSession(sessionID, mapID)
  local types = Enum and Enum.DamageMeterType
  if not types then return end
  local instance = X.Record("instances", mapID)
  local sources = list(fetch(C_DamageMeter.GetCombatSessionFromID, sessionID, types.DamageTaken), "combatSources")
  if C_DamageMeter.GetCombatSessionSourceFromID then
    for index = 1, math.min(#sources, MAX_SOURCES) do
      local guid, creatureID = X.Readable(sources[index].sourceGUID), X.Readable(sources[index].sourceCreatureID)
      local _, guidNpc = X.ParseGuid(guid)
      local npcID = type(creatureID) == "number" and creatureID or guidNpc
      if npcID then
        local detail = fetch(C_DamageMeter.GetCombatSessionSourceFromID, sessionID, types.DamageTaken, guid, creatureID)
        for _, spell in ipairs(list(detail, "combatSpells")) do recordSpell(instance, npcID, spell) end
      end
    end
  end
  for _, source in ipairs(list(fetch(C_DamageMeter.GetCombatSessionFromID, sessionID, types.Deaths), "combatSources")) do
    if X.Readable(source.isLocalPlayer) == true then
      X.Increment(instance, "deaths")
      status.deaths = status.deaths + 1
    end
  end
end

local function onCombatEnd()
  local mapID = X.InstanceMap()
  if not mapID or not X.db or type(C_DamageMeter) ~= "table" or not C_DamageMeter.GetAvailableCombatSessions
    or not C_DamageMeter.GetCombatSessionFromID or not available() then return end
  local sessions = fetch(C_DamageMeter.GetAvailableCombatSessions)
  local last = sessions and sessions[#sessions]
  local sessionID = last and X.Readable(last.sessionID)
  if not sessionID or sessionID == lastSession then return end
  lastSession = sessionID
  status.reads = status.reads + 1
  readSession(sessionID, mapID)
end

X.On("PLAYER_REGEN_ENABLED", onCombatEnd)

-- Für die Prüfung: Zähler dieser Sitzung
function DamageMeter.Status()
  return { api = type(C_DamageMeter) == "table", reads = status.reads, spells = status.spells, deaths = status.deaths,
    secret = status.secret }
end

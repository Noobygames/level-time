-- Vorlagen und Pakete (Roadmap 301): mehrere Ziele mit einem Klick anlegen. Fertige Pakete (Packs.BUILTIN, Ziele
-- relativ zum aktuellen Level) und eigene: die laufenden Ziele als Paket speichern (StreamGoalDB.packs[Name]),
-- als Text teilen ("LT1:goals:..." über den Serializer von Level Time, ohne loadstring) und wieder einlesen.
-- Paket = { goals = { { kind, params, target, extras }, ... } }; params/extras sind die Eingaben vor prepare
-- (goal.source), flach (nur Text, Zahl, Wahrheitswert). Beim Einlesen prüft Goals.Create jede Eingabe wie bei Hand.
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local L = ns.L

local Packs = {}
ns.Packs = Packs

Packs.SERIAL_KIND = "goals"
Packs.MAX_NAME_LENGTH = 30
local MAX_PACK_GOALS = Goals.MAX_ACTIVE

-- Fertige Pakete; target(level) = Ziel abhängig vom aktuellen Level
Packs.BUILTIN = {
  {
    key = "hardcore", label = "SG_PACK_HARDCORE",
    goals = {
      { kind = "rule", params = { rule = "nodeath" }, target = function(level) return level + 10 end },
      { kind = "level", target = function(level) return level + 5 end },
      { kind = "kills", params = { source = "pve" }, target = function() return 250 end },
    },
  },
  {
    key = "selffound", label = "SG_PACK_SELFFOUND",
    goals = {
      { kind = "rule", params = { rule = "nohelp" }, target = function(level) return level + 10 end },
      { kind = "gold", params = { mode = "earn" }, target = function() return 10 end },
      { kind = "quest", params = { mode = "count" }, target = function() return 25 end },
    },
  },
  {
    key = "dungeons", label = "SG_PACK_DUNGEONS",
    goals = {
      { kind = "dungeon", params = {}, target = function() return 10 end },
      { kind = "quest", params = { mode = "count" }, target = function() return 10 end },
      { kind = "rule", params = { rule = "nodeath" }, target = function(level) return level + 3 end },
    },
  },
  {
    key = "explorer", label = "SG_PACK_EXPLORER",
    goals = {
      { kind = "explore", params = { mode = "count" }, target = function() return 10 end },
      { kind = "quest", params = { mode = "count" }, target = function() return 15 end },
      { kind = "rule", params = { rule = "notaxi" }, target = function(level) return level + 3 end },
    },
  },
}

local function builtin(key)
  for _, pack in ipairs(Packs.BUILTIN) do
    if pack.key == key then return pack end
  end
end

-- Ziele eines fertigen Pakets für das aktuelle Level als Eingaben
local function resolveBuiltin(pack)
  local goals = {}
  for _, entry in ipairs(pack.goals) do
    table.insert(goals, { kind = entry.kind, params = Goals.CopyFlat(entry.params), target = entry.target(LT.level) })
  end
  return goals
end

-- Name eines Pakets für die Anzeige: fertige übersetzt, eigene wie gespeichert
function Packs.Label(key)
  local pack = builtin(key)
  if pack then return L[pack.label] end
  return key
end

-- Alle Pakete: erst die fertigen, dann die eigenen alphabetisch. { { key, builtin } }
function Packs.List()
  local list = {}
  for _, pack in ipairs(Packs.BUILTIN) do table.insert(list, { key = pack.key, builtin = true }) end
  local own = {}
  for name in pairs(ns.db.packs) do table.insert(own, name) end
  table.sort(own)
  for _, name in ipairs(own) do table.insert(list, { key = name, builtin = false }) end
  return list
end

local function goalsOf(key)
  local pack = builtin(key)
  if pack then return resolveBuiltin(pack) end
  local own = ns.db.packs[key]
  return own and own.goals or nil
end

-- Eingaben anlegen, so viele wie Platz ist; Rückgabe: Anzahl angelegt, erster Fehlertext
local function createAll(entries)
  if #Goals.Active() + #entries > Goals.MAX_ACTIVE then
    return 0, string.format(L.SG_ERR_PACK_ROOM, #entries, Goals.MAX_ACTIVE - #Goals.Active())
  end
  local created, firstError = 0, nil
  for _, entry in ipairs(entries) do
    local ok, goal, err = pcall(Goals.Create, entry.kind, Goals.CopyFlat(entry.params), entry.target,
      Goals.CopyFlat(entry.extras))
    if ok and goal then
      created = created + 1
    else
      firstError = firstError or (ok and err) or L.SG_ERR_IMPORT
    end
  end
  return created, firstError
end

-- Paket anlegen; Rückgabe: Anzahl angelegter Ziele, Fehlertext oder nil
function Packs.Apply(key)
  local entries = goalsOf(key)
  if not entries then return 0, string.format(L.SG_ERR_PACK_UNKNOWN, tostring(key)) end
  return createAll(entries)
end

-- Laufende Ziele (ohne Teilziele) als Eingaben
local function activeEntries()
  local entries = {}
  for _, goal in ipairs(Goals.Active()) do
    local source = goal.source
    if source and not goal.parentId then
      table.insert(entries, { kind = goal.kind, params = Goals.CopyFlat(source.params), target = source.target,
        extras = Goals.CopyFlat(source.extras) })
    end
  end
  return entries
end

-- Laufende Ziele als eigenes Paket speichern (überschreibt ein gleichnamiges); Rückgabe: Fehlertext oder nil
function Packs.Save(name)
  name = strtrim(name or "")
  if name == "" or ns.Kinds.TextLength(name) > Packs.MAX_NAME_LENGTH or builtin(name) then
    return L.SG_ERR_PACK_NAME
  end
  local entries = activeEntries()
  if #entries == 0 then return L.SG_ERR_PACK_EMPTY end
  ns.db.packs[name] = { goals = entries, savedAt = time() }
  return nil
end

function Packs.Delete(name)
  if not ns.db.packs[name] then return false end
  ns.db.packs[name] = nil
  return true
end

---------------------------------------------------------------------------
-- Teilen als Text
---------------------------------------------------------------------------
function Packs.Export(key)
  local entries = goalsOf(key)
  if not entries then return nil end
  return LT.Serializer.Encode(Packs.SERIAL_KIND, { name = Packs.Label(key), goals = entries })
end

-- Eingelesenes prüfen: nur bekannte Arten, flache Eingaben, Zahl oder nichts als Ziel, höchstens MAX_PACK_GOALS
local function sanitize(data)
  if type(data) ~= "table" or type(data.goals) ~= "table" then return nil end
  local entries = {}
  for index = 1, MAX_PACK_GOALS do
    local entry = data.goals[index]
    if entry == nil then break end
    if type(entry) ~= "table" or type(entry.kind) ~= "string" or not Goals.GetKind(entry.kind) then return nil end
    if entry.target ~= nil and type(entry.target) ~= "number" then return nil end
    table.insert(entries, { kind = entry.kind, params = Goals.CopyFlat(type(entry.params) == "table" and entry.params),
      target = entry.target, extras = Goals.CopyFlat(type(entry.extras) == "table" and entry.extras) })
  end
  if #entries == 0 then return nil end
  local name = type(data.name) == "string" and strtrim(data.name) or ""
  return entries, name
end

-- Text einlesen und als eigenes Paket speichern (Name aus dem Text, sonst "Import"); Rückgabe: Name oder nil, Fehler
function Packs.Import(text)
  local data = LT.Serializer.Decode(Packs.SERIAL_KIND, strtrim(text or ""))
  local entries, name = sanitize(data)
  if not entries then return nil, L.SG_ERR_IMPORT end
  if name == "" or builtin(name) or ns.Kinds.TextLength(name) > Packs.MAX_NAME_LENGTH then
    name = L.SG_PACK_IMPORTED
  end
  ns.db.packs[name] = { goals = entries, savedAt = time() }
  return name
end

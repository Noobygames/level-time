-- Ziel-Pool für Bingo und Glücksrad (Roadmap 305/306/431): mitgelieferte Einträge (Pool.PREMADE, Ziele relativ zum
-- Level und lustige Texte zum Abhaken) und die Vorlagen (Library.lua) als eine Liste gleich gebauter Einträge:
--   { key, premade, kind, params, target }   key = "p:<Name>" (mitgeliefert) oder "o:<ID>" (eigene Vorlage)
-- Die Schlüssel bleiben stabil, damit Glücksrad (abgeschaltete Einträge) und Bingo-Entwurf (gewählte Felder) sie
-- speichern können; ein gelöschte Vorlage liefert dann nichts mehr (Feld wird zufällig, Rad überspringt).
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Library = ns.Library
local L = ns.L

local Pool = {}
ns.Pool = Pool

local PREMADE_PREFIX, OWN_PREFIX = "p:", "o:"
local TEXT_KIND = "custom"

-- Mitgelieferte Einträge; target(level) = Ziel abhängig vom aktuellen Level, text = Locale-Key eines Textes. Mindestens
-- 24 Einträge, damit ein 5x5-Bingo ohne eigene Vorlagen keine Felder wiederholt (Kinds/Bingo.lua).
-- Texte, die das Spiel erkennt (Roadmap 439), haben zusätzlich eine Art (kind ~= "custom", params, target): kann der
-- Client die Art bzw. den Modus nicht erkennen (Goals.Check lehnt ab), wird daraus der Text zum Abhaken (Freitext).
local function one() return 1 end
Pool.PREMADE = {
  { key = "kills10", kind = "kills", params = { source = "pve" }, target = function() return 10 end },
  { key = "kills25", kind = "kills", params = { source = "pve" }, target = function() return 25 end },
  { key = "kills50", kind = "kills", params = { source = "any" }, target = function() return 50 end },
  { key = "quests2", kind = "quest", params = { mode = "count" }, target = function() return 2 end },
  { key = "quests5", kind = "quest", params = { mode = "count" }, target = function() return 5 end },
  { key = "quests10", kind = "quest", params = { mode = "count" }, target = function() return 10 end },
  { key = "gold1", kind = "gold", params = { mode = "earn" }, target = function() return 1 end },
  { key = "gold5", kind = "gold", params = { mode = "earn" }, target = function() return 5 end },
  { key = "explore1", kind = "explore", params = { mode = "count" }, target = function() return 1 end },
  { key = "explore3", kind = "explore", params = { mode = "count" }, target = function() return 3 end },
  { key = "dungeon1", kind = "dungeon", params = {}, target = function() return 1 end },
  { key = "dungeon3", kind = "dungeon", params = {}, target = function() return 3 end },
  { key = "level1", kind = "level", params = {}, target = function(level) return level + 1 end },
  { key = "honor100", kind = "honor", params = {}, target = function() return 100 end },
  { key = "text1", kind = "moment", params = { mode = "rare" }, target = one, text = "SG_BINGO_TEXT_1" },
  { key = "text2", kind = "moment", params = { mode = "fall" }, target = one, text = "SG_BINGO_TEXT_2" },
  { key = "text3", kind = "moment", params = { mode = "greet" }, target = one, text = "SG_BINGO_TEXT_3" },
  { key = "text4", kind = "moment", params = { mode = "sellreward" }, target = one, text = "SG_BINGO_TEXT_4" },
  { key = "text5", kind = "escape", params = {}, target = one, text = "SG_BINGO_TEXT_5" },
  { key = "text6", kind = "custom", text = "SG_BINGO_TEXT_6" },
  { key = "text7", kind = "custom", text = "SG_BINGO_TEXT_7" },
  { key = "text8", kind = "custom", text = "SG_BINGO_TEXT_8" },
  { key = "text9", kind = "moment", params = { mode = "heal" }, target = one, text = "SG_BINGO_TEXT_9" },
  { key = "text10", kind = "custom", text = "SG_BINGO_TEXT_10" },
  { key = "text11", kind = "moment", params = { mode = "swim" }, target = one, text = "SG_BINGO_TEXT_11" },
  { key = "text12", kind = "moment", params = { mode = "dance" }, target = one, text = "SG_BINGO_TEXT_12" },
  { key = "text13", kind = "moment", params = { mode = "buyback" }, target = one, text = "SG_BINGO_TEXT_13" },
  { key = "text14", kind = "custom", text = "SG_BINGO_TEXT_14" },
}

-- Schlüssel der mitgelieferten Texte (Migration der früheren eigenen Bingo-Texte, Library.lua)
Pool.TEXT_KEYS = {}
for _, entry in ipairs(Pool.PREMADE) do
  if entry.text then table.insert(Pool.TEXT_KEYS, PREMADE_PREFIX .. entry.key) end
end

-- Mitgelieferter Eintrag für das aktuelle Level (Texte in der gewählten Sprache)
local function resolvePremade(entry)
  local params = Goals.CopyFlat(entry.params)
  local kind, target = entry.kind, entry.target and entry.target(LT.level)
  if entry.text and (kind == TEXT_KIND or Goals.Check(kind, params, target)) then
    kind, params, target = TEXT_KIND, { text = L[entry.text] }, nil
  end
  return { key = PREMADE_PREFIX .. entry.key, premade = true, kind = kind, params = params, target = target }
end

-- Gibt es den mitgelieferten Eintrag in diesem Client? Texte immer (notfalls als Freitext)
local function premadeAvailable(entry)
  return entry.text ~= nil or Goals.IsAvailable(entry.kind)
end

-- Schlüssel einer Vorlage
function Pool.OwnKey(id)
  return OWN_PREFIX .. id
end

local function resolveOwn(entry)
  return { key = Pool.OwnKey(entry.id), premade = false, ownId = entry.id, kind = entry.kind,
    params = Goals.CopyFlat(entry.params), target = entry.target, createdAt = entry.createdAt }
end

-- Alle im Client verfügbaren Einträge: erst die mitgelieferten, dann die eigenen (neue Liste)
function Pool.Items()
  local items = {}
  for _, entry in ipairs(Pool.PREMADE) do
    if premadeAvailable(entry) then table.insert(items, resolvePremade(entry)) end
  end
  for _, item in ipairs(Pool.OwnItems()) do table.insert(items, item) end
  return items
end

-- Nur die Vorlagen, im Client verfügbare (neue Liste; Reiter "Sammlung")
function Pool.OwnItems()
  local items = {}
  for _, entry in ipairs(Library.Entries()) do
    if Goals.IsAvailable(entry.kind) then table.insert(items, resolveOwn(entry)) end
  end
  return items
end

-- Herkunft für Tabellen: mitgeliefert oder eigene Vorlage
function Pool.SourceText(item)
  return item.premade and L.SG_POOL_PREMADE or L.SG_POOL_OWN
end

-- Eintrag zu einem Schlüssel, nil = unbekannt (z.B. gelöschte Vorlage)
function Pool.Get(key)
  if type(key) ~= "string" then return nil end
  local id = tonumber((key:match("^" .. OWN_PREFIX .. "(%d+)$")))
  if id then
    local entry = Library.Get(id)
    return entry and Goals.IsAvailable(entry.kind) and resolveOwn(entry) or nil
  end
  local name = key:match("^" .. PREMADE_PREFIX .. "(.+)$")
  for _, entry in ipairs(Pool.PREMADE) do
    if entry.key == name and premadeAvailable(entry) then return resolvePremade(entry) end
  end
end

-- Liste an Ort und Stelle mischen; Rückgabe: dieselbe Liste
function Pool.Shuffle(items)
  for index = #items, 2, -1 do
    local other = math.random(index)
    items[index], items[other] = items[other], items[index]
  end
  return items
end

-- Titel eines Eintrags, ohne ein Ziel anzulegen (Listen, Dreh-Animation)
function Pool.Title(item)
  local def = Goals.GetKind(item.kind)
  local preview = { kind = item.kind, params = Goals.CopyFlat(item.params), target = item.target or 1, progress = 0,
    start = 0 }
  if def.prepare then preview.target = def.prepare(preview.params, preview.target) or preview.target end
  local ok, title = pcall(def.title, preview)
  return ok and title or L[def.label]
end

-- Ziel aus einem Eintrag anlegen (parent = Bingo-Schein); Rückgabe wie Goals.Create
function Pool.Create(item, parent)
  return Goals.Create(item.kind, Goals.CopyFlat(item.params), item.target, {}, parent)
end

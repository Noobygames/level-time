-- Eigene Ziele (Roadmap 431): selbst festgelegte Einträge für Bingo-Felder und das Glücksrad, Account-weit in
-- StreamGoalDB.library = { nextId, entries = { { id, kind, params, target, createdAt }, ... } }.
-- Ein Eintrag ist eine Eingabe wie in einem Paket (Packs.lua): kind, params (flach, vor prepare) und target; angelegt
-- wird daraus erst beim Ziehen (Goals.Create prüft dann Bestand und Plätze). Entstehen über "Als eigenes Ziel
-- speichern" im Formular (jede Zielart), als freier Text (Bingo-Editor, Glücksrad, /sg bingo text) oder per Import.
-- Teilen im Text-Format der Pakete ("LT1:goals:..."), ein Paket-Text lässt sich auch hier einlesen.
local _, ns = ...
local Goals = ns.Goals
local Packs = ns.Packs
local L = ns.L

local Library = {}
ns.Library = Library

Library.MAX_ENTRIES = 60
Library.TEXT_KIND = "custom"
-- Arten, die selbst Ziele anlegen, taugen nicht als Feld oder Radergebnis
local EXCLUDED_KINDS = { bingo = true }
local LEGACY_SCHEMA = 2  -- vorher: settings.bingoTexts (eigene Bingo-Texte)

local function store()
  local db = ns.db
  db.library = type(db.library) == "table" and db.library or {}
  local library = db.library
  library.entries = type(library.entries) == "table" and library.entries or {}
  library.nextId = tonumber(library.nextId) or 1
  return library
end

-- Alle eigenen Ziele, älteste zuerst (nicht verändern)
function Library.Entries()
  return store().entries
end

function Library.Get(id)
  for _, entry in ipairs(store().entries) do
    if entry.id == id then return entry end
  end
end

local function sameInput(entry, kind, params, target)
  if entry.kind ~= kind or entry.target ~= target then return false end
  for key, value in pairs(params) do
    if entry.params[key] ~= value then return false end
  end
  for key in pairs(entry.params) do
    if params[key] == nil then return false end
  end
  return true
end

-- Eigenes Ziel speichern; ein gleiches gibt es nur einmal. Rückgabe: Eintrag, oder nil und Fehlertext
function Library.Add(kind, params, target)
  if EXCLUDED_KINDS[kind] then return nil, L.SG_ERR_OWN_KIND end
  params = Goals.CopyFlat(params)
  local err = Goals.Check(kind, params, target)
  if err then return nil, err end
  local library = store()
  for _, entry in ipairs(library.entries) do
    if sameInput(entry, kind, params, target) then return entry end
  end
  if #library.entries >= Library.MAX_ENTRIES then
    return nil, string.format(L.SG_ERR_OWN_FULL, Library.MAX_ENTRIES)
  end
  local entry = { id = library.nextId, kind = kind, params = params, target = target, createdAt = time() }
  library.nextId = entry.id + 1
  table.insert(library.entries, entry)
  ns.Debug("library", "add #%s %s", entry.id, kind)
  return entry
end

-- Freier Text zum Abhaken (Art custom ohne Zähler)
function Library.AddText(text)
  local clean, err = ns.Kinds.CleanText(text, L.SG_ERR_TEXT)
  if not clean then return nil, err end
  return Library.Add(Library.TEXT_KIND, { text = clean }, nil)
end

function Library.Remove(id)
  local entries = store().entries
  for index, entry in ipairs(entries) do
    if entry.id == id then
      table.remove(entries, index)
      return true
    end
  end
  return false
end

-- Eigene freie Texte (custom ohne Zähler), für /sg bingo texts
function Library.Texts()
  local texts = {}
  for _, entry in ipairs(store().entries) do
    if entry.kind == Library.TEXT_KIND and entry.target == nil then table.insert(texts, entry) end
  end
  return texts
end

-- Alle freien Texte löschen (/sg bingo clear); Rückgabe: Anzahl
function Library.RemoveTexts()
  local removed = 0
  for _, entry in ipairs(Library.Texts()) do
    if Library.Remove(entry.id) then removed = removed + 1 end
  end
  return removed
end

---------------------------------------------------------------------------
-- Teilen als Text (Format der Pakete)
---------------------------------------------------------------------------
function Library.Export()
  local entries = {}
  for _, entry in ipairs(store().entries) do
    table.insert(entries, { kind = entry.kind, params = Goals.CopyFlat(entry.params), target = entry.target })
  end
  if #entries == 0 then return nil end
  return Packs.Encode(L.SG_OWN_GOALS, entries)
end

-- Text einlesen; jeder Eintrag wird wie von Hand geprüft. Rückgabe: Anzahl übernommen, oder nil und Fehlertext
function Library.Import(text)
  local entries = Packs.Decode(text, Library.MAX_ENTRIES)
  if not entries then return nil, L.SG_ERR_IMPORT end
  local added, firstError = 0, nil
  for _, input in ipairs(entries) do
    local before = #store().entries
    local entry, err = Library.Add(input.kind, input.params, input.target)
    if entry and #store().entries > before then added = added + 1 end
    firstError = firstError or err
  end
  if added == 0 and firstError then return nil, firstError end
  return added
end

---------------------------------------------------------------------------
-- Schema 2: eigene Bingo-Texte (settings.bingoTexts) werden eigene Ziele. Früher ersetzten sie die mitgelieferten
-- Texte, daher schaltet die Migration diese im Glücksrad ab, wenn es eigene gab (Wheel.lua liest wheel.pool.off).
---------------------------------------------------------------------------
ns.MIGRATIONS[LEGACY_SCHEMA] = function(db)
  local settings = type(db.settings) == "table" and db.settings or {}
  local texts = settings.bingoTexts
  settings.bingoTexts = nil
  if type(texts) ~= "table" or #texts == 0 then return end
  db.library = { nextId = 1, entries = {} }
  for _, text in ipairs(texts) do
    if type(text) == "string" and strtrim(text) ~= "" then
      local library = db.library
      table.insert(library.entries, { id = library.nextId, kind = Library.TEXT_KIND, params = { text = text },
        createdAt = time() })
      library.nextId = library.nextId + 1
    end
  end
  db.wheel = type(db.wheel) == "table" and db.wheel or {}
  db.wheel.pool = type(db.wheel.pool) == "table" and db.wheel.pool or {}
  db.wheel.pool.off = type(db.wheel.pool.off) == "table" and db.wheel.pool.off or {}
  for _, key in ipairs(ns.Pool.TEXT_KEYS) do db.wheel.pool.off[key] = true end
end

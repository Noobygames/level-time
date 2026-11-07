-- Daten des Hauptfensters ohne Frames (im Stub testbar): welche Zeilen in welcher Reihenfolge, ihre Texte im
-- gewählten Bereich, Reiter, Zeit und XP-Balken. Die Layouts (UI/Layouts/) ordnen das nur an.
--   Zeilen: jede Zeile einer Stat aus ns.STAT_LINES, Schlüssel = Locale-Key ihrer Beschriftung ("ROW_XP_RATE").
--   Quelle "visible": eingeschaltete Stats in der Reihenfolge rowOrder (Stat-Einstellungen, Komma-getrennt; nicht
--   genannte folgen in der Reihenfolge von STAT_LINES). Quelle "chosen": die bis zu MAX_CHOSEN_ROWS gewählten Zeilen
--   aus compactRows (Zeilen-Schlüssel), unabhängig von den Schaltern.
--   Kurzlabel: L["<Schlüssel>_SHORT"], wo es einen gibt, sonst die normale Beschriftung.
-- Die Liste der Zeilen (Struktur) entsteht nur nach Invalidate (Apply, Level-Up, XP an/aus); je Takt werden nur
-- Werte gelesen. model.structure zählt hoch, wenn sich die Liste geändert hat.
local _, ns = ...
local L = ns.L
local Stats = ns.Stats
local Format = ns.Format

local WindowModel = {
  MAX_CHOSEN_ROWS = 3,
  VISIBLE = "visible",
  CHOSEN = "chosen",
  SCOPES = { Stats.LEVEL, Stats.SESSION, Stats.INSTANCE },
}
ns.WindowModel = WindowModel

local NO_VALUE = "-"    -- Zeilen ohne Bereich (Instanz-Reiter ohne Lauf)
local PENDING = "..."   -- Spielzeit, solange /played noch nicht geantwortet hat
local LIST_SEPARATOR = ","

---------------------------------------------------------------------------
-- Zeilen und Listen-Einstellungen
---------------------------------------------------------------------------
local allRows, rowsByKey, statsBySetting = {}, {}, {}
for _, stat in ipairs(ns.STAT_LINES) do
  statsBySetting[stat.setting] = stat
  for _, definition in ipairs(stat.rows) do
    local row = { key = definition.label, stat = stat, definition = definition, group = stat.group }
    table.insert(allRows, row)
    rowsByKey[row.key] = row
  end
end

-- Alle Zeilen in der Reihenfolge von STAT_LINES (nicht ändern)
function WindowModel.AllRows()
  return allRows
end

function WindowModel.RowByKey(key)
  return rowsByKey[key]
end

local function isAvailable(stat)
  return not stat.available or stat.available()
end

function WindowModel.IsRowAvailable(key)
  local row = rowsByKey[key]
  return row ~= nil and isAvailable(row.stat)
end

-- Locale-Key des Kurzlabels oder der normale Key
local function shortKey(key)
  local short = key .. "_SHORT"
  return ns.locales.enUS[short] and short or key
end

function WindowModel.ShortLabel(key)
  return L[shortKey(key)]
end

-- "a, b,c" -> { "a", "b", "c" }; leere Einträge entfallen. Ergebnis je Text gemerkt (nicht ändern)
local parsed = {}
function WindowModel.ParseList(text)
  text = type(text) == "string" and text or ""
  local list = parsed[text]
  if list then return list end
  list = {}
  for entry in text:gmatch("[^" .. LIST_SEPARATOR .. "]+") do
    entry = entry:match("^%s*(.-)%s*$")
    if entry ~= "" then table.insert(list, entry) end
  end
  parsed[text] = list
  return list
end

function WindowModel.JoinList(list)
  return table.concat(list, LIST_SEPARATOR)
end

-- Stats in der Reihenfolge von rowOrder, danach alle übrigen wie in STAT_LINES (gemerkt je rowOrder, nicht ändern)
local orderedFor, ordered
function WindowModel.OrderedStats(db)
  if ordered and orderedFor == db.rowOrder then return ordered end
  local list, seen = {}, {}
  for _, setting in ipairs(WindowModel.ParseList(db.rowOrder)) do
    local stat = statsBySetting[setting]
    if stat and not seen[stat] then
      table.insert(list, stat)
      seen[stat] = true
    end
  end
  for _, stat in ipairs(ns.STAT_LINES) do
    if not seen[stat] then table.insert(list, stat) end
  end
  ordered, orderedFor = list, db.rowOrder
  return list
end

-- Eingeschaltete Stat um eine Stelle unter den eingeschalteten verschieben (delta -1 = nach oben, 1 = nach unten);
-- gespeichert wird die ganze Reihenfolge. false, wenn es nicht weitergeht.
function WindowModel.MoveStat(db, setting, delta)
  local list = {}
  for _, stat in ipairs(WindowModel.OrderedStats(db)) do table.insert(list, stat) end
  local from
  for index, stat in ipairs(list) do
    if stat.setting == setting then from = index end
  end
  if not from then return false end
  local to = from + delta
  while list[to] and not ns.IsStatShown(list[to], db) do to = to + delta end
  if not list[to] then return false end
  table.remove(list, from)
  table.insert(list, to, statsBySetting[setting])
  local settings = {}
  for index, stat in ipairs(list) do settings[index] = stat.setting end
  ns.Set("rowOrder", WindowModel.JoinList(settings))
  return true
end

-- Eingeschaltete und verfügbare Stats in der eingestellten Reihenfolge (für die Auswahl in den Einstellungen)
function WindowModel.ShownStats(db)
  local list = {}
  for _, stat in ipairs(WindowModel.OrderedStats(db)) do
    if ns.IsStatShown(stat, db) then table.insert(list, stat) end
  end
  return list
end

-- Gewählte Zeilen (compactRows) ohne unbekannte oder im Client nicht verfügbare, höchstens MAX_CHOSEN_ROWS
function WindowModel.ChosenRows(db)
  local list = {}
  for _, key in ipairs(WindowModel.ParseList(db.compactRows)) do
    if #list == WindowModel.MAX_CHOSEN_ROWS then break end
    local row = rowsByKey[key]
    if row and isAvailable(row.stat) then table.insert(list, row) end
  end
  return list
end

-- Schlüssel der gewählten Zeile an Stelle index ("" = keine)
function WindowModel.ChosenRowKey(db, index)
  local row = WindowModel.ChosenRows(db)[index]
  return row and row.key or ""
end

-- Gewählte Zeile an Stelle index setzen ("" = keine); die übrigen gültigen Stellen bleiben
function WindowModel.SetChosenRow(db, index, key)
  local keys = {}
  for i = 1, WindowModel.MAX_CHOSEN_ROWS do keys[i] = WindowModel.ChosenRowKey(db, i) end
  keys[index] = key
  local list = {}
  for _, entry in ipairs(keys) do
    if entry ~= "" then table.insert(list, entry) end
  end
  ns.Set("compactRows", WindowModel.JoinList(list))
end

local function visibleRows(db)
  local list = {}
  for _, stat in ipairs(WindowModel.OrderedStats(db)) do
    if ns.IsStatShown(stat, db) then
      for _, definition in ipairs(stat.rows) do table.insert(list, rowsByKey[definition.label]) end
    end
  end
  return list
end

---------------------------------------------------------------------------
-- Modell
---------------------------------------------------------------------------
-- Ein Modell je Anzeige (WindowModel.New), Felder werden an Ort und Stelle aktualisiert:
--   structure, source, scope, open, leveling, level
--   tabs = { { scope, text, active } x3 }, scopeText (Beschriftung des gewählten Bereichs)
--   time = { seconds, text }
--   xpBar = { shown, xp, max, rested, quests (nil ohne questXpOnBar) }
--   rows = { { key, label, shortLabel, group, value } }
local Model = {}
Model.__index = Model

function WindowModel.New()
  local tabs = {}
  for index, scope in ipairs(WindowModel.SCOPES) do tabs[index] = { scope = scope, text = "", active = false } end
  return setmetatable({
    structure = 0, dirty = true, rows = {}, tabs = tabs, time = { text = "" }, xpBar = { shown = false },
  }, Model)
end

-- Zeilenliste beim nächsten Build neu bilden (Einstellungen, Sprache, Level-Up, XP an/aus)
function Model:Invalidate()
  self.dirty = true
end

local function rebuildRows(model, db, source)
  local rows = {}
  for index, row in ipairs(source == WindowModel.CHOSEN and WindowModel.ChosenRows(db) or visibleRows(db)) do
    rows[index] = { key = row.key, label = L[row.key], shortLabel = WindowModel.ShortLabel(row.key),
      group = row.group, definition = row.definition, value = "" }
  end
  model.rows = rows
  model.source = source
  model.dirty = false
  model.structure = model.structure + 1
end

local function tabText(scope)
  if scope == Stats.LEVEL then return string.format(L.TAB_LEVEL, ns.level) end
  if scope == Stats.SESSION then return L.TAB_SESSION end
  return L.TAB_INSTANCE
end

local function readXpBar(bar, db, leveling, always)
  bar.shown = (always or db.showXpBar) and leveling or false
  if not bar.shown then return end
  local xpMax = UnitXPMax("player")
  local xp = UnitXP("player")
  bar.xp, bar.max = xp, xpMax
  bar.rested = math.min(xpMax, xp + (GetXPExhaustion() or 0))
  bar.quests = db.questXpOnBar and math.min(xpMax, xp + ns.QuestLogXp.Get()) or nil
end

-- Werte für den Takt lesen; source = WindowModel.VISIBLE oder CHOSEN (vom Layout), alwaysXpBar = Balken auch ohne
-- showXpBar (Layout "xpbar"). Gibt das Modell zurück.
function Model:Build(db, source, alwaysXpBar)
  local leveling = ns.Experience.IsLeveling()
  if self.dirty or source ~= self.source or leveling ~= self.leveling or ns.level ~= self.level then
    self.leveling, self.level = leveling, ns.level
    rebuildRows(self, db, source)
  end

  local scope = db.windowScope
  local open = Stats.IsOpen(scope)
  self.scope, self.open = scope, open
  for _, tab in ipairs(self.tabs) do
    tab.text = tabText(tab.scope)
    tab.active = tab.scope == scope
    if tab.active then self.scopeText = tab.text end
  end

  local seconds = Stats.GetSeconds(scope)
  self.time.seconds = seconds
  self.time.text = not open and L.INSTANCE_NONE or seconds and Format.Clock(seconds) or PENDING

  for _, row in ipairs(self.rows) do
    row.value = open and row.definition.value(scope) or NO_VALUE
  end
  readXpBar(self.xpBar, db, leveling, alwaysXpBar)
  return self
end

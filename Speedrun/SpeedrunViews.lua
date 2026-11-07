-- Speedrun-Ansichten der Historie (Gruppe "Speedrun"): Läufe zum Vergleichen und Rekorde je Level
-- (schnellste Zeit je Level über die eigenen Charaktere, importierte Läufe zählen nicht) sowie die
-- Speedrun-Rekorde von speedrun.com je Abschnitt (WorldRecords.lua).
-- Läufe: Klick wählt den Lauf als festen Vergleich der Splits, Rechtsklick markiert ihn als Favorit,
-- Shift+Klick zeigt ihn als Text zum Teilen; Favoriten stehen oben. Buttons: alle Läufe sichern, importieren. Suchfeld filtert nach Name und Klasse (wie jede Tabelle über alle Zellen).
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Format = ns.Format
local History = ns.History
local Runs = ns.Runs
local Splits = ns.Splits
local HistoryTables = ns.HistoryTables

local GROUP = "HISTORY_GROUP_SPEEDRUN"
local LEFT = "LEFT"
local FAVORITE_MARK = "*"

local function className(classToken)
  local names = LOCALIZED_CLASS_NAMES_MALE
  return classToken and (names and names[classToken] or classToken) or ""
end

-- Eigene Charaktere mit Streamer-Datenschutz, importierte Läufe mit Kennzeichen
local function runName(run)
  if run.imported then return (run.name or "?") .. " " .. L.RUN_IMPORTED end
  return History.DisplayName(run.id)
end

local function isReference(run)
  local reference = ns.db.splitReference
  return ns.db.splitComparison == Splits.RUN and reference ~= nil and reference.id == run.id
end

local function countLevels(times)
  local count = 0
  for _ in pairs(times) do count = count + 1 end
  return count
end

---------------------------------------------------------------------------
-- Läufe
---------------------------------------------------------------------------

-- Favoriten zuerst, sonst Reihenfolge aus Runs.GetAll; Zeit über dieselbe Spanne wie die Splits
local function runRecords()
  local from, to = Splits.ComparableRange()
  local favorites, others = {}, {}
  for _, run in ipairs(Runs.GetAll()) do
    run.timeToLevel = Runs.SumOfLevels(run.times, from, to - 1)
    run.recordedLevels = countLevels(run.times)
    run.isCurrent = run.id == ns.characterKey
    table.insert(run.favorite and favorites or others, run)
  end
  for _, run in ipairs(others) do table.insert(favorites, run) end
  return favorites
end

local RUN_COLUMNS = {
  { header = "HISTORY_FAVORITE", width = 18, align = LEFT,
    value = function(r) return r.favorite and FAVORITE_MARK or "" end },
  { header = "HISTORY_CHARACTER_NAME", width = 110, align = LEFT, value = runName },
  { header = "HISTORY_CLASS", width = 80, align = LEFT, value = function(r) return className(r.class) end },
  { header = "HISTORY_LEVEL", width = 40, value = function(r) return r.reachedLevel or "" end,
    sort = function(r) return r.reachedLevel end },
  { header = "HISTORY_LEVELS_RECORDED", width = 56, value = function(r) return r.recordedLevels end },
  { header = "HISTORY_TIME_TO_CURRENT", width = 90, value = function(r)
      return r.timeToLevel and Format.Duration(r.timeToLevel) or "-"
    end, sort = function(r) return r.timeToLevel end },
  { header = "HISTORY_COVERAGE", width = 50, value = function(r) return ns.Coverage.Text(r.coverage) end,
    sort = function(r) return r.coverage end },
  { header = "HISTORY_RUN_CATEGORY", width = 64, align = LEFT,
    value = function(r) return ns.RunCategory.Label(r.category) end },
  { header = "HISTORY_RUN_CHECK", width = 60, value = function(r) return ns.RunCheck.StatusText(r) end },
  { header = "HISTORY_RUN_STATUS", width = 70, value = function(r)
      return isReference(r) and L.RUN_REFERENCE or ""
    end },
}

local function runColor(run)
  if isReference(run) then return Widgets.COLORS.highlight end
  return HistoryTables.ClassColor(run)
end

local function onRunClick(run, mouseButton)
  if IsShiftKeyDown() then
    ns.Export.Show(runName(run), Runs.Export(run))
  elseif mouseButton == "RightButton" then
    Runs.ToggleFavorite(run.id)
  elseif not run.isCurrent then
    Splits.SetReferenceRun(run)
    ns.Print(string.format(L.COMPARE_SET, Splits.GetReferenceName()))
  end
end

ns.HistoryWindow.AddView(ns.TableView.Create({
  tab = "HISTORY_TAB_RUNS",
  group = GROUP,
  columns = RUN_COLUMNS,
  records = runRecords,
  footer = HistoryTables.CountCells,
  rowColor = runColor,
  onRowClick = onRunClick,
  hint = "RUNS_HINT",
  buttons = {
    { label = "RUNS_BACKUP", onClick = function() ns.Export.Show(L.RUNS_BACKUP, Runs.ExportAll()) end },
    { label = "IMPORT", onClick = function() ns.ShowRunImport() end },
    { label = "LIVESPLIT_EXPORT", onClick = function() ns.LiveSplitExport.Show() end },
  },
}))

-- Import-Fenster für Läufe (auch /lt runs import)
function ns.ShowRunImport()
  ns.Export.ShowImport(L.RUNS_IMPORT_TITLE, function(text)
    local added = Runs.Import(text)
    if not added then return L.RUNS_IMPORT_INVALID, false end
    return string.format(L.RUNS_IMPORTED, added), true
  end)
end

---------------------------------------------------------------------------
-- Rekorde: schnellste Zeit je Level über alle eigenen Charaktere, dazu die eigene Zeit
---------------------------------------------------------------------------

-- { level, seconds, run, ownSeconds }, höchstes Level zuerst
local function recordRows()
  local best = {}
  for _, run in ipairs(Runs.GetAll()) do
    if not run.imported then
      for level, seconds in pairs(run.bestTimes) do  -- ohne Teil-Level (Coverage.lua)
        if not best[level] or seconds < best[level].seconds then
          best[level] = { level = level, seconds = seconds, run = run }
        end
      end
    end
  end
  local rows = {}
  for level, entry in pairs(best) do
    local own = ns.character.levelHistory[level]
    entry.ownSeconds = own and own.seconds
    entry.isCurrent = entry.run.id == ns.characterKey  -- Rekord vom eingeloggten Charakter hervorheben
    table.insert(rows, entry)
  end
  table.sort(rows, function(a, b) return a.level > b.level end)
  return rows
end

local RECORD_COLUMNS = {
  { header = "HISTORY_LEVEL", width = 40, value = function(r) return r.level end,
    sort = function(r) return r.level end },
  { header = "HISTORY_BEST_TIME", width = 80, value = function(r) return Format.Duration(r.seconds) end,
    sort = function(r) return r.seconds end },
  { header = "HISTORY_CHARACTER_NAME", width = 140, align = LEFT, value = function(r) return runName(r.run) end },
  { header = "HISTORY_CLASS", width = 80, align = LEFT, value = function(r) return className(r.run.class) end },
  { header = "HISTORY_RUN_CATEGORY", width = 64, align = LEFT,
    value = function(r) return ns.RunCategory.Label(r.run.category) end },
  { header = "HISTORY_OWN_TIME", width = 80, value = function(r)
      return r.ownSeconds and Format.Duration(r.ownSeconds) or "-"
    end, sort = function(r) return r.ownSeconds end },
  { header = "HISTORY_DELTA", width = 80, value = function(r)
      return r.ownSeconds and Format.SplitDelta(r.ownSeconds - r.seconds) or "-"
    end, sort = function(r) return r.ownSeconds and r.ownSeconds - r.seconds end },
}

ns.HistoryWindow.AddView(ns.TableView.Create({
  tab = "HISTORY_TAB_RECORDS",
  group = GROUP,
  columns = RECORD_COLUMNS,
  records = recordRows,
  footer = HistoryTables.CountCells,
  rowColor = function(r) return r.isCurrent and Widgets.COLORS.highlight or HistoryTables.ClassColor(r.run) end,
}))

---------------------------------------------------------------------------
-- Quest-Splits: Dauer jeder Quest von der Annahme bis zur Abgabe gegen die Bestzeit je Quest (QuestSplits.lua)
---------------------------------------------------------------------------
local QuestSplits = ns.QuestSplits

local QUEST_SPLIT_COLUMNS = {
  { header = "HISTORY_QUEST", width = 170, align = LEFT, value = function(r) return r.name or L.UNKNOWN_NAME end },
  { header = "HISTORY_LEVEL", width = 40, value = function(r) return r.level or "" end,
    sort = function(r) return r.level end },
  { header = "HISTORY_XP", width = 56, value = function(r) return r.xp and Format.Number(r.xp) or "-" end,
    sort = function(r) return r.xp end },
  { header = "HISTORY_TIME", width = 64, value = function(r) return Format.Duration(r.duration) end,
    sort = function(r) return r.duration end },
  -- Bestzeit über alle Abgaben: ändert sich mit späteren Quests, daher volatile (nicht je Zeile zwischengespeichert)
  { header = "HISTORY_BEST_TIME", width = 64, volatile = true, value = function(r)
      local best = QuestSplits.GetBest(r.questID)
      return best and Format.Duration(best) or "-"
    end, sort = function(r) return QuestSplits.GetBest(r.questID) end },
  { header = "HISTORY_DELTA", width = 70, value = function(r) return Format.SplitDelta(r.delta) end,
    sort = function(r) return r.delta end },
}

ns.HistoryWindow.AddView(ns.TableView.Create({
  tab = "HISTORY_TAB_QUEST_SPLITS",
  group = GROUP,
  columns = QUEST_SPLIT_COLUMNS,
  records = QuestSplits.GetEntries,
  appendOnly = true,
  footer = HistoryTables.CountCells,
  revision = ns.Journal.RevisionOf("questLog"),
  hint = "QUEST_SPLITS_HINT",
}))

---------------------------------------------------------------------------
-- Speedrun-Rekorde (speedrun.com): je Abschnitt gesamt und je Klasse, mit deiner /played-Zeit
---------------------------------------------------------------------------
local WorldRecords = ns.WorldRecords

-- Eigene Zeit je Abschnitt aus WorldRecords.GetComparisons (für alle Zeilen des Abschnitts gleich)
local function worldRecordRows()
  local own = {}
  for _, comparison in ipairs(WorldRecords.GetComparisons()) do
    own[comparison.label] = comparison
  end
  local rows = WorldRecords.GetAllRecords()
  for _, row in ipairs(rows) do
    local comparison = own[row.label]
    row.ownSeconds = comparison and comparison.ownSeconds
    row.reached = comparison and comparison.reached
    row.delta = row.ownSeconds and row.ownSeconds - row.record.seconds
    row.isCurrent = not row.isOverall and row.record.class == ns.character.class  -- eigene Klasse hervorheben
  end
  return rows
end

local WORLD_RECORD_COLUMNS = {
  { header = "HISTORY_BRACKET", width = 46, align = LEFT, value = function(r) return r.label end,
    sort = function(r) return r.level end },
  { header = "HISTORY_CLASS", width = 74, align = LEFT, value = function(r)
      return r.isOverall and L.WORLD_RECORD_ALL_CLASSES or className(r.record.class)
    end },
  { header = "HISTORY_BEST_TIME", width = 70, value = function(r) return Format.Duration(r.record.seconds) end,
    sort = function(r) return r.record.seconds end },
  { header = "HISTORY_RUNNER", width = 100, align = LEFT, value = function(r) return r.record.runner end },
  { header = "HISTORY_WHEN", width = 70, value = function(r) return r.record.date end },
  { header = "HISTORY_OWN_TIME", width = 70, value = function(r)
      if not r.ownSeconds then return "-" end
      return Format.Duration(r.ownSeconds) .. (r.reached and "" or "*")
    end, sort = function(r) return r.ownSeconds end },
  { header = "HISTORY_DELTA", width = 70, value = function(r) return Format.SplitDelta(r.delta) end,
    sort = function(r) return r.delta end },
}

local function worldRecordHint()
  return string.format(L.WORLD_RECORDS_HINT, WorldRecords.GetFetchedText())
end

ns.HistoryWindow.AddView(ns.TableView.Create({
  tab = "HISTORY_TAB_WORLD_RECORDS",
  group = GROUP,
  columns = WORLD_RECORD_COLUMNS,
  records = worldRecordRows,
  footer = HistoryTables.CountCells,
  rowColor = function(r)
    if r.isCurrent then return Widgets.COLORS.highlight end
    return HistoryTables.ClassColor(r.record)
  end,
  hint = worldRecordHint,
}))

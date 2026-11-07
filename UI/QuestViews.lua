-- Quest-Ansichten der Historie (Gruppe "Quests"):
--   Abgabe (Roadmap 345)  alle abgabebereiten Quests des eingeloggten Charakters mit Zone (Überschrift im Questlog),
--                         XP je Quest (QuestLog.RewardXp) und Anteil am aktuellen Level; Summe in der Fußzeile
--                         ("bringt N % Level"). Hilft beim Bündeln vor dem Ruhestein. Andere Charaktere: leer, weil
--                         nur der eigene Questlog lesbar ist.
--   Effizienz (Roadmap 347) je Quest über alle Charaktere: Abgaben, Ø Dauer, Ø XP, XP/min
--                         (History/QuestEfficiency.lua); sortierbar, zeigt Twinks, welche Quests sich lohnen.
local _, ns = ...
local L = ns.L
local Format = ns.Format
local QuestLog = ns.QuestLog
local HistoryTables = ns.HistoryTables

local QuestViews = {}
ns.QuestViews = QuestViews

local GROUP = "HISTORY_GROUP_QUESTS"
local LEFT = "LEFT"

local revision = 0  -- Stand des Questlogs: Tabelle filtert und sortiert nur nach Änderungen neu
local function bump() revision = revision + 1 end
ns.RegisterEvent("QUEST_LOG_UPDATE", bump)
ns.RegisterEvent("QUEST_TURNED_IN", bump)
ns.OnLevelStarted(bump)

local function levelXp()
  local max = UnitXPMax("player")
  return not ns.IsSecret(max) and type(max) == "number" and max or 0
end

-- Abgabebereite Quests: { questID, title, zone, xp, share (Anteil am Level, 0..) }
function QuestViews.TurnInRecords(characterKey)
  local records = {}
  if characterKey ~= ns.characterKey then return records end
  local max = levelXp()
  for _, entry in ipairs(QuestLog.Entries()) do
    if entry.ready then
      local xp = QuestLog.RewardXp(entry.questID) or 0
      table.insert(records, { questID = entry.questID, title = entry.title, zone = entry.header, xp = xp,
        share = max > 0 and xp / max or 0, level = entry.level })
    end
  end
  return records
end

local function percent(share)
  return Format.Percent(share, 1)
end

local TURN_IN_COLUMNS = {
  { header = "HISTORY_ZONE", width = 110, align = LEFT, value = function(r) return r.zone or "" end },
  { header = "HISTORY_QUEST", width = 170, align = LEFT, value = function(r) return r.title or L.UNKNOWN_NAME end },
  { header = "HISTORY_LEVEL", width = 40, value = function(r) return r.level or "" end,
    sort = function(r) return r.level end },
  { header = "HISTORY_XP", width = 64, value = function(r) return r.xp > 0 and Format.Number(r.xp) or "-" end,
    sort = function(r) return r.xp end },
  { header = "HISTORY_LEVEL_SHARE", width = 64, value = function(r) return percent(r.share) end,
    sort = function(r) return r.share end },
}

-- Fußzeile: Anzahl, XP-Summe, Anteil am Level
local function turnInFooter(columns, records)
  local cells = HistoryTables.CountCells(columns, records)
  local xp, share = 0, 0
  for _, record in ipairs(records) do
    xp, share = xp + record.xp, share + record.share
  end
  cells[4] = Format.Number(xp)
  cells[5] = percent(share)
  return cells
end

ns.HistoryWindow.AddView(ns.TableView.Create({
  tab = "HISTORY_TAB_TURN_IN",
  group = GROUP,
  columns = TURN_IN_COLUMNS,
  records = QuestViews.TurnInRecords,
  footer = turnInFooter,
  revision = function() return revision end,
  rowLink = function(r) return "quest:" .. r.questID end,
  hint = "TURN_IN_HINT",
}))

local EFFICIENCY_COLUMNS = {
  { header = "HISTORY_QUEST", width = 170, align = LEFT, value = function(r) return r.name or L.UNKNOWN_NAME end },
  { header = "HISTORY_TURN_INS", width = 56, value = function(r) return r.count end, sort = function(r) return r.count end },
  { header = "HISTORY_AVERAGE_TIME", width = 64, value = function(r)
      return r.averageSeconds and Format.Duration(r.averageSeconds) or "-"
    end, sort = function(r) return r.averageSeconds end },
  { header = "HISTORY_XP", width = 64, value = function(r)
      return r.averageXp and Format.Number(math.floor(r.averageXp + 0.5)) or "-"
    end, sort = function(r) return r.averageXp end },
  { header = "HISTORY_XP_PER_MINUTE", width = 64, value = function(r)
      return r.xpPerMinute and Format.Number(math.floor(r.xpPerMinute + 0.5)) or "-"
    end, sort = function(r) return r.xpPerMinute end },
}

ns.HistoryWindow.AddView(ns.TableView.Create({
  tab = "HISTORY_TAB_QUEST_EFFICIENCY",
  group = GROUP,
  columns = EFFICIENCY_COLUMNS,
  records = function() return ns.QuestEfficiency.GetRecords() end,
  footer = HistoryTables.CountCells,
  revision = ns.Journal.Revision,
  rowLink = function(r) return "quest:" .. r.questID end,
  hint = "QUEST_EFFICIENCY_HINT",
}))

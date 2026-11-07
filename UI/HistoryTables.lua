-- Tabellen der Historie: Level, Timeline, Sessions, Kills, Tode, Quests, Beute, Instanzen, Beinahe-Tode, Zonen, Vergleich.
-- Nur Spalten und Summenzeilen; die Tabelle selbst (Lazy Load, Sortieren, Filtern, CSV) ist TableView.lua.
-- Die Summenzeile gilt für die gefilterten Zeilen. Weitere Ansichten (z.B. SpeedrunViews.lua) bauen
-- Tabellen ebenfalls mit TableView.Create und nutzen ClassColor/CountCells von hier.
local _, ns = ...
local HistoryTables = {}
ns.HistoryTables = HistoryTables
local L = ns.L
local Format = ns.Format
local TableView = ns.TableView
local Experience = ns.Experience
local Stats = ns.Stats
local History = ns.History
local Journal = ns.Journal

local WHITE = { 1, 1, 1 }
local LEFT = "LEFT"

---------------------------------------------------------------------------
-- Spalten (Aufbau siehe TableView.lua)
---------------------------------------------------------------------------
local function counter(record, name)
  return record.counters[name] or 0
end

local function dateTime(format, timestamp)
  return timestamp and date(format, timestamp) or ""
end

local function durationColumn(width)
  return { header = "HISTORY_TIME", width = width, value = function(r)
    return r.seconds and Format.Duration(r.seconds) or "?"
  end, sort = function(r) return r.seconds end }
end

local function xpRateColumn(width)
  return { header = "HISTORY_XP_RATE", width = width, value = function(r)
    local rate = Experience.RecordRate(r)
    return rate and Format.Number(rate) or "-"
  end, sort = Experience.RecordRate }
end

local function counterColumn(header, name, width)
  return { header = header, width = width, value = function(r) return counter(r, name) end }
end

local function goldColumn(width)
  return { header = "HISTORY_GOLD", width = width, value = function(r)
    return Format.Gold(counter(r, Stats.MONEY_EARNED))
  end, sort = function(r) return counter(r, Stats.MONEY_EARNED) end }
end

-- Teil-Level (nur teilweise erfasst, Coverage.lua) mit Kennzeichen; Hinweis LEVELS_PARTIAL_HINT
local PARTIAL_MARK = "*"

local function levelColumn(width)
  return { header = "HISTORY_LEVEL", width = width, value = function(r)
    return (r.level or "") .. (r.partial and PARTIAL_MARK or "")
  end,
    sort = function(r) return r.level end }
end

local function zoneColumn(width)
  return { header = "HISTORY_ZONE", width = width, align = LEFT, value = function(r) return r.zone or "" end }
end

local function whenColumn(width)
  return { header = "HISTORY_WHEN", width = width, value = function(r)
    return dateTime(L.DATE_TIME_FORMAT, r.time)
  end, sort = function(r) return r.time end }
end

local function levelRange(r)
  if not r.startLevel then return "" end
  if r.endLevel and r.endLevel ~= r.startLevel then
    return r.startLevel .. "-" .. r.endLevel
  end
  return r.startLevel
end

local LEVEL_COLUMNS = {
  levelColumn(44),
  durationColumn(62),
  xpRateColumn(52),
  counterColumn("HISTORY_PVE", Stats.PVE_KILLS, 40),
  counterColumn("HISTORY_PVP", Stats.PVP_KILLS, 40),
  counterColumn("HISTORY_DEATHS", Stats.DEATHS, 40),
  counterColumn("HISTORY_QUESTS", Stats.QUESTS, 48),
  goldColumn(56),
}

-- Zeitaufteilung je Level (TimeBreakdown.lua); Rest = Spielzeit minus aller Anteile
local function timePartColumn(header, name, width)
  return { header = header, width = width, value = function(r)
    return Format.Duration(counter(r, name))
  end, sort = function(r) return counter(r, name) end }
end

local function restSeconds(r)
  return ns.TimeBreakdown.RestOf(r.seconds, function(name) return counter(r, name) end)
end

local TIME_COLUMNS = {
  levelColumn(44),
  durationColumn(62),
  timePartColumn("HISTORY_COMBAT", Stats.COMBAT_SECONDS, 62),
  timePartColumn("HISTORY_TAXI", Stats.TAXI_SECONDS, 62),
  timePartColumn("HISTORY_AFK", Stats.AFK_SECONDS, 62),
  timePartColumn("HISTORY_IDLE", Stats.IDLE_SECONDS, 62),
  timePartColumn("HISTORY_DEAD", Stats.DEAD_SECONDS, 62),
  { header = "HISTORY_REST", width = 62, value = function(r)
    local rest = restSeconds(r)
    return rest and Format.Duration(rest) or "?"
  end, sort = restSeconds },
}

-- XP-Quellen und Ort je Level (XpSources.lua): Anteile an der XP des Levels
local function xpPartColumn(header, name, width)
  return { header = header, width = width, value = function(r)
    return Format.Percent(counter(r, name), r.xp or 0)
  end, sort = function(r) return counter(r, name) end }
end

local XP_SOURCE_COLUMNS = {
  levelColumn(44),
  { header = "HISTORY_XP", width = 56, value = function(r) return Format.Number(r.xp or 0) end,
    sort = function(r) return r.xp end },
  xpPartColumn("HISTORY_XP_KILLS", Stats.XP_KILLS, 48),
  xpPartColumn("HISTORY_XP_QUESTS", Stats.XP_QUESTS, 48),
  xpPartColumn("HISTORY_XP_EXPLORE", Stats.XP_EXPLORE, 48),
  xpPartColumn("HISTORY_XP_GATHER", Stats.XP_GATHER, 48),
  xpPartColumn("HISTORY_XP_WORLD", Stats.XP_WORLD, 48),
  xpPartColumn("HISTORY_XP_DUNGEON", Stats.XP_DUNGEON, 52),
  xpPartColumn("HISTORY_XP_RAID", Stats.XP_RAID, 48),
  xpPartColumn("HISTORY_XP_BATTLEGROUND", Stats.XP_BATTLEGROUND, 52),
}

local SESSION_COLUMNS = {
  { header = "HISTORY_START", width = 80, value = function(r) return dateTime(L.DATE_FORMAT, r.startedAt) end,
    sort = function(r) return r.startedAt end },
  durationColumn(56),
  -- Angezeigt "5-6", sortiert nach Start- und dann End-Level als Zahl
  { header = "HISTORY_LEVEL", width = 44, value = levelRange,
    sort = function(r) return r.startLevel and (r.startLevel + (r.endLevel or r.startLevel) / 1000) end },
  xpRateColumn(48),
  counterColumn("HISTORY_PVE", Stats.PVE_KILLS, 36),
  counterColumn("HISTORY_PVP", Stats.PVP_KILLS, 36),
  counterColumn("HISTORY_DEATHS", Stats.DEATHS, 40),
  counterColumn("HISTORY_QUESTS", Stats.QUESTS, 44),
  goldColumn(52),
}

local MILESTONE_COLUMNS = {
  { header = "HISTORY_REACHED_LEVEL", width = 60, value = function(r) return r.reachedLevel end },
  { header = "HISTORY_REACHED", width = 100, value = function(r) return dateTime(L.DATE_FORMAT, r.reachedAt) end,
    sort = function(r) return r.reachedAt end },
  { header = "HISTORY_TOTAL_PLAYED", width = 90, value = function(r)
      return r.totalPlayed and Format.Duration(r.totalPlayed) or "?"
    end, sort = function(r) return r.totalPlayed end },
  { header = "HISTORY_LEVEL_DURATION", width = 80, value = function(r)
      return r.seconds and Format.Duration(r.seconds) or "?"
    end, sort = function(r) return r.seconds end },
}

-- Art eines Kills: PvP, sonst die Einstufung des Gegners (Elite, Rare, ...) oder PvE
local KIND_BY_CLASSIFICATION = {
  elite = "KIND_ELITE",
  rare = "KIND_RARE",
  rareelite = "KIND_RARE_ELITE",
  worldboss = "KIND_BOSS",
}

local function killKind(r)
  if r.kind == Journal.PVP then return L.KIND_PVP end
  local key = KIND_BY_CLASSIFICATION[r.classification]
  return key and L[key] or L.KIND_PVE
end

local KILL_COLUMNS = {
  whenColumn(100),
  { header = "HISTORY_NAME", width = 108, align = LEFT, value = function(r) return r.name or L.UNKNOWN_NAME end },
  { header = "HISTORY_KIND", width = 72, value = killKind },  -- "Rare-Elite" braucht Platz
  levelColumn(40),
  zoneColumn(126),
}

local DEATH_COLUMNS = {
  whenColumn(100),
  { header = "HISTORY_CAUSE", width = 130, align = LEFT, value = History.DeathCauseText },
  levelColumn(40),
  zoneColumn(100),
  { header = "HISTORY_PLACE", width = 60, value = function(r) return ns.DeathPlace.CoordinatesText(r) or "-" end },
  { header = "HISTORY_LAST_WORDS", width = 110, align = LEFT, value = function(r) return r.lastWords or "" end },
}

local QUEST_COLUMNS = {
  whenColumn(100),
  { header = "HISTORY_QUEST", width = 180, align = LEFT, value = function(r) return r.name or L.UNKNOWN_NAME end },
  { header = "HISTORY_XP", width = 60, value = function(r) return r.xp and Format.Number(r.xp) or "-" end,
    sort = function(r) return r.xp end },
  { header = "HISTORY_GOLD", width = 60, value = function(r) return r.money and Format.Gold(r.money) or "-" end,
    sort = function(r) return r.money end },
  levelColumn(40),
  zoneColumn(86),
}

local INSTANCE_COLUMNS = {
  whenColumn(100),
  { header = "HISTORY_INSTANCE", width = 100, align = LEFT, value = function(r) return r.name or "" end },
  durationColumn(60),
  { header = "HISTORY_XP", width = 60, value = function(r) return Format.Number(r.xp or 0) end,
    sort = function(r) return r.xp end },
  xpRateColumn(50),
  counterColumn("HISTORY_KILLS", "kills", 50),
  counterColumn("HISTORY_DEATHS", "deaths", 40),
  counterColumn("HISTORY_REPUTATION", "reputation", 40),
  levelColumn(40),
}

local LOOT_COLUMNS = {
  whenColumn(100),
  { header = "HISTORY_ITEM", width = 180, align = LEFT, value = function(r) return r.link or r.name or "" end },
  { header = "HISTORY_QUANTITY", width = 40, value = function(r) return r.quantity or 1 end },
  { header = "HISTORY_SOURCE", width = 130, align = LEFT, value = function(r) return r.source or "-" end },
  levelColumn(40),
}

local NEAR_DEATH_COLUMNS = {
  whenColumn(100),
  { header = "HISTORY_LOWEST_HEALTH", width = 70, value = function(r) return (r.lowestPercent or 0) .. "%" end,
    sort = function(r) return r.lowestPercent end },
  { header = "HISTORY_CAUSE", width = 180, align = LEFT, value = History.DeathCauseText },
  levelColumn(40),
  zoneColumn(110),
}

local ZONE_COLUMNS = {
  { header = "HISTORY_ZONE", width = 160, value = function(r) return r.zone or "" end },
  durationColumn(70),
  { header = "HISTORY_XP", width = 70, value = function(r) return Format.Number(r.xp or 0) end,
    sort = function(r) return r.xp end },
  xpRateColumn(60),
  counterColumn("HISTORY_KILLS", "kills", 50),
  counterColumn("HISTORY_DEATHS", "deaths", 40),
  counterColumn("HISTORY_REPUTATION", "reputation", 50),
}

-- Ruf je Fraktion (Reputation.lua)
local REPUTATION_COLUMNS = {
  { header = "HISTORY_FACTION", width = 220, align = LEFT, value = function(r) return r.faction end },
  { header = "HISTORY_REPUTATION", width = 80, value = function(r) return Format.Number(r.amount) end,
    sort = function(r) return r.amount end },
  { header = "HISTORY_WHEN", width = 100, value = function(r) return dateTime(L.DATE_TIME_FORMAT, r.last) end,
    sort = function(r) return r.last end },
}

local COMPARE_COLUMNS = {
  { header = "HISTORY_CHARACTER_NAME", width = 90, value = function(r) return History.DisplayName(r.key) end },
  levelColumn(40),
  { header = "HISTORY_LEVELS_DONE", width = 50, value = function(r) return r.levelsCompleted end },
  { header = "HISTORY_AVERAGE_LEVEL_TIME", width = 76, value = function(r)
      return r.averageLevelSeconds and Format.Duration(r.averageLevelSeconds) or "-"
    end, sort = function(r) return r.averageLevelSeconds end },
  { header = "HISTORY_XP_RATE", width = 52, value = function(r)
      return r.xpRate and Format.Number(r.xpRate) or "-"
    end, sort = function(r) return r.xpRate end },
  { header = "HISTORY_KILLS", width = 50, value = function(r)
      return counter(r, Stats.PVE_KILLS) + counter(r, Stats.PVP_KILLS)
    end },
  counterColumn("HISTORY_DEATHS", Stats.DEATHS, 36),
  goldColumn(50),
  { header = "HISTORY_COVERAGE", width = 50, value = function(r) return ns.Coverage.Text(r.coverage) end,
    sort = function(r) return r.coverage end },
  -- Geschätzter Erholungs-Pool (RestedEstimate.lua), für Twinks seit ihrem Logout hochgerechnet
  { header = "HISTORY_RESTED", width = 44, value = function(r) return ns.RestedEstimate.Text(r.key) end,
    sort = function(r) return ns.RestedEstimate.Get(r.key) end },
}

-- Geld nach Zeitraum (Money.lua): Einnahmen, Ausgaben, Saldo, Gold/h
local function signedGold(copper)
  return (copper >= 0 and "+" or "-") .. Format.Gold(math.abs(copper))
end

local MONEY_COLUMNS = {
  { header = "HISTORY_PERIOD", width = 140, align = LEFT, value = function(r) return L["MONEY_PERIOD_" .. r.period:upper()] end,
    sort = function(r) return r.seconds end },
  { header = "HISTORY_INCOME", width = 80, value = function(r) return Format.Gold(r.moneyIn) end,
    sort = function(r) return r.moneyIn end },
  { header = "HISTORY_SPENDING", width = 80, value = function(r) return Format.Gold(r.moneyOut) end,
    sort = function(r) return r.moneyOut end },
  { header = "HISTORY_BALANCE", width = 80, value = function(r) return signedGold(r.moneyIn - r.moneyOut) end,
    sort = function(r) return r.moneyIn - r.moneyOut end },
  { header = "HISTORY_GOLD_PER_HOUR", width = 70, value = function(r)
      local rate = ns.Money.PerHour(r.moneyIn, r.seconds)
      return rate and Format.Gold(rate) or "-"
    end, sort = function(r) return ns.Money.PerHour(r.moneyIn, r.seconds) or 0 end },
  durationColumn(70),
}

-- Summenzeile: Gold aller Charaktere (gelöschte zählen nicht, Twinks mit ihrem Stand beim letzten Logout)
local function moneyFooter(columns)
  local cells = {}
  for index = 1, #columns do cells[index] = "" end
  local total, count = ns.Money.TotalGold()
  cells[1] = string.format(L.MONEY_ALL_CHARACTERS, Format.Gold(total), count)
  return cells
end

-- Persönliche Rekorde (PersonalRecords.lua), über alle Charaktere; gelöschte Charaktere als "?"
local function recordHolder(r)
  if not r.characterKey or not History.GetCharacter(r.characterKey) then return r.characterKey and "?" or "" end
  return History.DisplayName(r.characterKey)
end

local PERSONAL_RECORD_COLUMNS = {
  { header = "HISTORY_RECORD", width = 170, align = LEFT, value = function(r) return r.label end },
  { header = "HISTORY_VALUE", width = 90, value = function(r) return r.value end, sort = function(r) return r.sortValue end },
  { header = "HISTORY_CHARACTER_NAME", width = 120, value = recordHolder },
  { header = "HISTORY_LEVEL", width = 40, value = function(r) return r.level or "" end },
  { header = "HISTORY_WHEN", width = 100, value = function(r) return dateTime(L.DATE_TIME_FORMAT, r.at) end,
    sort = function(r) return r.at end },
}

-- Vergleich: Zeilen in Klassenfarbe
local function classColor(record)
  local color = RAID_CLASS_COLORS and record.class and RAID_CLASS_COLORS[record.class]
  if color then return { color.r, color.g, color.b } end
  return WHITE
end

-- Summenzeile für Level und Sessions: Spaltenwerte der Summe, vorne "Gesamt"
local function summaryCells(columns, records)
  local summary = History.Summarize(records)
  local cells = {}
  for i, column in ipairs(columns) do
    cells[i] = column.value(summary)
  end
  cells[1] = L.HISTORY_TOTAL
  return cells
end

-- Summenzeile für Kills und Tode: nur die Anzahl, in der ersten Spalte, die breit genug ist
-- (in den Speedrun-Tabellen ist die erste Spalte nur ein Favoriten-Stern)
local COUNT_MIN_WIDTH = 80

local function countCells(columns, records)
  local cells = {}
  local target = 1
  for index, column in ipairs(columns) do
    if column.width >= COUNT_MIN_WIDTH then target = index break end
  end
  for index = 1, target - 1 do cells[index] = "" end
  cells[target] = string.format(L.HISTORY_COUNT, #records)
  return cells
end

HistoryTables.ClassColor = classColor
HistoryTables.CountCells = countCells

-- journal = Einträge aus dem Journal (ohne laufenden Eintrag): neu sortiert nur bei geändertem Journal-Stand
local function addTable(tab, group, columns, records, footer, journal, hint, rowLink)
  ns.HistoryWindow.AddView(TableView.Create({
    tab = tab, group = group, columns = columns, records = records, footer = footer, hint = hint,
    revision = journal and ns.Journal.Revision or nil, rowLink = rowLink,
  }))
end

-- Spiel-Links für den Tooltip einer Zeile: Gegenstand aus dem gespeicherten Link (ältere Einträge haben nur den
-- Namen), Quest als "quest:ID:Level" wie in Chat-Links (Classic leitet sie ebenfalls an SetHyperlink, ItemRef.lua);
-- Level ist die Stufe beim Abgeben, weil die Queststufe nicht im Journal steht
local function itemLink(record)
  return type(record.link) == "string" and record.link:match("|H(item:[^|]+)|h") or nil
end

local function questLink(record)
  if type(record.questID) ~= "number" then return nil end
  return string.format("quest:%d:%d", record.questID, record.level or -1)
end

local LEVELS, JOURNAL = "HISTORY_GROUP_LEVELS", "HISTORY_GROUP_JOURNAL"

addTable("HISTORY_TAB_LEVELS", LEVELS, LEVEL_COLUMNS, History.GetLevelRecords, summaryCells, false, "LEVELS_PARTIAL_HINT")
addTable("HISTORY_TAB_TIMELINE", LEVELS, MILESTONE_COLUMNS, History.GetMilestones, countCells)
addTable("HISTORY_TAB_TIME_SPLIT", LEVELS, TIME_COLUMNS, History.GetLevelRecords, summaryCells, false,
  "LEVELS_PARTIAL_HINT")
addTable("HISTORY_TAB_XP_SOURCES", LEVELS, XP_SOURCE_COLUMNS, History.GetLevelRecords, summaryCells, false,
  "LEVELS_PARTIAL_HINT")
-- Rekorde gelten für alle Charaktere, die Charakter-Auswahl spielt keine Rolle
ns.HistoryWindow.AddView(TableView.Create({
  tab = "HISTORY_TAB_PERSONAL_RECORDS",
  group = LEVELS,
  columns = PERSONAL_RECORD_COLUMNS,
  records = function() return ns.PersonalRecords.GetRows() end,
  footer = countCells,
  hint = "PERSONAL_RECORDS_HINT",
}))
addTable("HISTORY_TAB_SESSIONS", nil, SESSION_COLUMNS, History.GetSessionRecords, summaryCells)
addTable("HISTORY_TAB_KILLS", JOURNAL, KILL_COLUMNS, History.GetKillLog, countCells, true)
addTable("HISTORY_TAB_DEATHS", JOURNAL, DEATH_COLUMNS, History.GetDeathLog, countCells, true)
addTable("HISTORY_TAB_QUESTS", JOURNAL, QUEST_COLUMNS, History.GetQuestLog, countCells, true, nil, questLink)
addTable("HISTORY_TAB_LOOT", JOURNAL, LOOT_COLUMNS, History.GetLootLog, countCells, true, nil, itemLink)
addTable("HISTORY_TAB_INSTANCES", JOURNAL, INSTANCE_COLUMNS, History.GetInstanceLog, summaryCells)
-- Beinahe-Tode nur, wo der Client das Leben lesbar macht (Retail/Forever: geheim, die Liste bliebe immer leer)
if ns.NearDeath.IsAvailable() then
  addTable("HISTORY_TAB_NEAR_DEATHS", JOURNAL, NEAR_DEATH_COLUMNS, History.GetNearDeathLog, countCells, true)
end
addTable("HISTORY_TAB_ZONES", nil, ZONE_COLUMNS, ns.Zones.GetRecords, summaryCells)
addTable("HISTORY_TAB_REPUTATION", nil, REPUTATION_COLUMNS, ns.Reputation.GetRecords, countCells)
addTable("HISTORY_TAB_MONEY", nil, MONEY_COLUMNS, ns.Money.GetPeriodRecords, moneyFooter, false, "MONEY_HINT")

-- Vergleich gilt für alle Charaktere, die Charakter-Auswahl spielt hier keine Rolle
ns.HistoryWindow.AddView(TableView.Create({
  tab = "HISTORY_TAB_COMPARE",
  columns = COMPARE_COLUMNS,
  records = function() return History.GetCharacterComparison() end,
  footer = countCells,
  rowColor = classColor,
}))

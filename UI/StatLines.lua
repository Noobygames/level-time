-- Stats im Fenster. Einzige Stelle, an der festgelegt wird, welche Stats es gibt:
-- TimerWindow zeigt die Zeilen (rows) als Tabelle an, Options baut aus setting/label die Schalter.
-- Eintrag: setting = Schalter in ns.db (Default in Database.lua), label = Locale-Key des Schalters,
-- rows = feste Liste von Zeilen mit label (Locale-Key) und value(scope) -> Text für den Bereich.
-- available (optional) = Funktion; false, wenn der Client den Wert nicht liefern kann (Zeile und
-- Schalter entfallen dann).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    showXpRate = true,
    showXpGained = true,
    showLevelEta = true,
    showMaxLevelEta = false,
  },
})
local Format = ns.Format
local Stats = ns.Stats
local Experience = ns.Experience
local DeathCounter = ns.DeathCounter

local NO_VALUE = Format.NO_VALUE
-- Tode rot (Theme-Farbe bad), damit sie (z.B. im Stream) auffallen (Einstellung highlightDeaths)
local PENDING = Format.PENDING  -- noch nicht aussagekräftig (z.B. /played hat noch nicht geantwortet)

local function counter(name)
  return function(scope) return tostring(Stats.Get(scope, name)) end
end

-- Farbe nach Wert (Einstellung valueColors, Roadmap 361): über dem Vergleichswert gut, darunter schlecht, dazwischen
-- (VALUE_TOLERANCE) ungefärbt; Farben aus dem Theme (Farbsehschwäche: Blau/Orange)
local VALUE_TOLERANCE = 0.1
local function compared(text, value, reference)
  if not ns.db.valueColors or not value or not reference or reference <= 0 then return text end
  local ratio = value / reference
  if ratio >= 1 + VALUE_TOLERANCE then return ns.Theme.Hex("good") .. text .. "|r" end
  if ratio <= 1 - VALUE_TOLERANCE then return ns.Theme.Hex("bad") .. text .. "|r" end
  return text
end

-- XP/h des Bereichs, gefärbt gegen den Schnitt der letzten Level
local function xpRate(scope)
  if not Experience.IsLeveling() then return NO_VALUE end
  local rate = Experience.GetRatePerHour(scope)
  if not rate then return PENDING end
  return compared(Format.Number(rate), rate, ns.db.valueColors and ns.Forecast.AverageLevelXpRate() or nil)
end

-- Anzahl je Stunde im Bereich (Kills, Gegenstände), über dieselbe Spielzeit wie XP/h (ohne AFK/Leerlauf, wenn eingestellt)
local function perHour(counterName)
  return function(scope)
    local rate = Experience.CountRate(Stats.Get(scope, counterName), Experience.ScopeRateSeconds(scope))
    return rate and Format.Number(rate) or PENDING
  end
end

-- Unabhängig vom Bereich: Rate der letzten Minuten
-- gefärbt gegen die XP/h des laufenden Levels (schneller oder langsamer als bisher in diesem Level)
local function recentXpRate()
  if not Experience.IsLeveling() then return NO_VALUE end
  local rate = ns.RecentXpRate.Get()
  if not rate then return PENDING end
  return compared(Format.Number(rate), rate, ns.db.valueColors and Experience.GetRatePerHour(Stats.LEVEL) or nil)
end

-- Unabhängig vom Bereich: Summe bzw. hochgerechnete Rate eines Zählers in den letzten 15 Minuten (RecentCounts.lua)
local function recentCount(counterName)
  return function() return Format.Number(ns.RecentCounts.Count(counterName)) end
end

local function recentRate(counterName)
  return function()
    local rate = ns.RecentCounts.Rate(counterName)
    return rate and Format.Number(rate) or PENDING
  end
end

-- "~38": Kills bzw. Quests bis zum Level-Up beim Durchschnitt des Levels
local function countToLevel(xpCounter, countCounter)
  return function()
    if not Experience.IsLeveling() then return NO_VALUE end
    local count = Experience.CountToLevel(xpCounter, countCounter)
    return count and ("~" .. count) or NO_VALUE
  end
end

-- Questlog-XP (QuestLogXp.lua): fertige und offene Quests, und ob die Abgabe für das Level-Up reicht

local function questLogXp(index)
  return function()
    if not Experience.IsLeveling() then return NO_VALUE end
    local values = { ns.QuestLogXp.Get() }
    return Format.Number(values[index])
  end
end

local function questTurnInLevelUp()
  if not Experience.IsLeveling() then return NO_VALUE end
  local missing = ns.QuestLogXp.MissingAfterTurnIn()
  if missing <= 0 then
    return ns.Theme.Hex("good") .. string.format(ns.L.QUEST_XP_LEVEL_UP_YES, Format.Number(-missing)) .. "|r"
  end
  return string.format(ns.L.QUEST_XP_LEVEL_UP_NO, Format.Number(missing))
end

local function timeToLevel(scope)
  if not Experience.IsLeveling() then return NO_VALUE end
  local seconds = Experience.GetSecondsToLevel(scope)
  return seconds and Format.Duration(seconds) or PENDING
end

-- Prognose ist unabhängig vom Bereich (Level/Session)
local function timeToMaxLevel()
  if not Experience.IsLeveling() then return NO_VALUE end
  local seconds = ns.Forecast.SecondsToMaxLevel()
  return seconds and Format.Duration(seconds) or PENDING
end

local function deaths(scope)
  local count = Stats.Get(scope, Stats.DEATHS)
  local deadSeconds = DeathCounter.GetDeadSeconds(scope)
  local text = tostring(count)
  if deadSeconds >= 1 then
    text = string.format(ns.L.DEATHS_WITH_DEAD_TIME, count, Format.Duration(deadSeconds))  -- "2 (6m 38s tot)"
  end
  if count > 0 and ns.db.highlightDeaths then
    text = ns.Theme.Hex("bad") .. text .. "|r"
  end
  return text
end

-- Session-Ziel: "Level 30: 45 %, 1h 20m" bzw. "Level 30 erreicht"
local function goalText()
  local goal = ns.Goal.Get()
  if not goal then return NO_VALUE end
  if goal.reached then return string.format(ns.L.GOAL_DONE, goal.level) end
  local seconds = ns.Goal.GetSecondsLeft()
  return string.format(ns.L.GOAL_PROGRESS, goal.level, Format.Percent(ns.Goal.GetProgress(), 1),
    seconds and Format.Duration(seconds) or PENDING)
end

-- Unabhängig vom Bereich: seit dem letzten Tod des Charakters
local function timeWithoutDeath()
  local seconds = DeathCounter.GetSecondsSinceDeath()
  return seconds and Format.Duration(seconds) or NO_VALUE
end

local function killsPerDeath(scope)
  local ratio = DeathCounter.GetKillsPerDeath(scope)
  return ratio and string.format("%.1f", ratio) or NO_VALUE
end

-- Anteil einer XP-Quelle (Schlüssel von Experience.GetSources: kills, quests, explore, gather, other)
local function xpShare(source)
  return function(scope)
    local sources = Experience.GetSources(scope)
    if sources.total <= 0 then return NO_VALUE end
    return Format.Percent(sources[source], sources.total)
  end
end

-- Anteil der XP an einem Ort (Zähler aus XpSources.lua) an der XP des Bereichs
local function xpContextShare(counterName)
  return function(scope)
    local total = Stats.GetXp(scope)
    if total <= 0 then return NO_VALUE end
    return Format.Percent(math.min(total, Stats.Get(scope, counterName)), total)
  end
end

local function restedXp(scope)
  local rested = Stats.Get(scope, Stats.XP_RESTED)
  return string.format("%s (%s)", Format.Number(rested), Format.Percent(rested, Stats.GetXp(scope)))
end

-- Zeitaufteilung: "1h 20m (35%)" bezogen auf die Spielzeit des Bereichs
local function timeShare(getSeconds)
  return function(scope)
    local seconds = getSeconds(scope)
    if not seconds then return PENDING end
    return string.format("%s (%s)", Format.Duration(seconds), Format.Percent(seconds, Stats.GetSeconds(scope) or 0))
  end
end

local function timePart(counter)
  return timeShare(function(scope) return ns.TimeBreakdown.GetSeconds(scope, counter) end)
end

-- Aktive Zeit ohne den Buff (Roadmap 485)
local function withoutBuff(counter)
  return timeShare(function(scope) return ns.TimeBreakdown.WithoutBuff(scope, counter) end)
end

-- Noch verfügbare Erholt-XP, Anteil am aktuellen Level (bis 150 %); unabhängig vom Bereich
local function restedLeft()
  if not Experience.IsLeveling() then return NO_VALUE end
  local rested = GetXPExhaustion() or 0
  return string.format("%s (%s)", Format.Number(rested), Format.Percent(rested, UnitXPMax("player")))
end

local function money(counterName)
  return function(scope) return Format.Money(Stats.Get(scope, counterName)) end
end

local income = money(Stats.MONEY_EARNED)

-- Ruf je Stunde im Bereich (Spielzeit wie bei XP/h)
local function reputationRate(scope)
  local rate = Experience.CalculateRate(Stats.Get(scope, Stats.REPUTATION), Experience.ScopeRateSeconds(scope))
  return rate and Format.Number(rate) or NO_VALUE
end

-- Gold je Stunde im Bereich (Einnahmen, Spielzeit wie bei XP/h ohne AFK/Leerlauf, wenn eingestellt)
local function goldPerHour(scope)
  local rate = ns.Money.PerHour(Stats.Get(scope, Stats.MONEY_EARNED), Experience.ScopeRateSeconds(scope))
  return rate and Format.Money(rate) or NO_VALUE
end

-- Unabhängig vom Bereich: Instanzlimit "3/5, nächste in 14m" (siehe InstanceLimit.lua)
local function instanceLimit()
  local InstanceLimit = ns.InstanceLimit
  local count, limit = InstanceLimit.GetHourCount(), InstanceLimit.GetLimit()
  local wait = InstanceLimit.GetSecondsUntilNextFree()
  if not wait then return string.format(ns.L.INSTANCE_LIMIT_VALUE, count, limit) end
  return string.format(ns.L.INSTANCE_LIMIT_NEXT, count, limit, Format.Duration(wait))
end

-- Seit Mitternacht; mit Tageslimit (Classic) dazu die gleitenden 24 Stunden "4 (12/30 in 24 h)"
local function instancesToday()
  local InstanceLimit = ns.InstanceLimit
  local today, dailyLimit = InstanceLimit.GetTodayCount(), InstanceLimit.GetDailyLimit()
  if not dailyLimit then return tostring(today) end
  return string.format(ns.L.INSTANCES_TODAY_DAILY, today, InstanceLimit.GetDayCount(), dailyLimit)
end

-- Unabhängig vom Bereich: laufender Instanz-Lauf "12m 30s, 5.000 XP"
local function instanceRun()
  local run = ns.Instances.GetCurrentRun()
  if not run then return NO_VALUE end
  return string.format(ns.L.INSTANCE_RUN_VALUE, Format.Duration(ns.Instances.GetRunSeconds(run)), Format.Number(ns.Instances.Summarize(run)))
end

-- Stammdaten der Instanz des laufenden Laufs "5 Spieler, Reset: Täglich, Level 15-28" (InstanceInfo)
local function instanceInfo()
  local run = ns.Instances.GetCurrentRun()
  return run and ns.InstanceInfo.Describe(run.mapID, run.difficultyID) or NO_VALUE
end

local FIT_NAMES_SHOWN = 3
-- Text je Level und Sprache (Zusatz-Text als Schlüssel) gemerkt: das Fenster fragt die Zeile bei jedem Aktualisieren ab
local fitCache = { level = nil, suffix = nil, text = nil }

local function buildInstanceFit(level)
  local list = ns.InstanceInfo.ForLevel(level)
  if #list == 0 then return NO_VALUE end
  local names = {}
  for i = 1, math.min(#list, FIT_NAMES_SHOWN) do
    local entry = list[i]
    names[i] = string.format("%s (%d-%d)", ns.InstanceInfo.MapName(entry.mapID), entry.minLevel, entry.maxLevel)
  end
  local text = table.concat(names, ", ")
  if #list > FIT_NAMES_SHOWN then text = text .. string.format(ns.L.INSTANCE_FIT_MORE, #list - FIT_NAMES_SHOWN) end
  return text
end

-- Dungeons passend zum eigenen Level "Name (15-28), ... +2"; nur Clients mit Level-Spalten
local function instanceFit()
  local level = ns.level or 0
  local suffix = ns.L.INSTANCE_FIT_MORE
  if fitCache.level ~= level or fitCache.suffix ~= suffix then
    fitCache.level, fitCache.suffix, fitCache.text = level, suffix, buildInstanceFit(level)
  end
  return fitCache.text
end

-- Gewonnene XP im Bereich (Level, Session oder Instanz-Lauf), unabhängig von der Rate
local function xpGained(scope)
  return Format.Number(Stats.GetXp(scope))
end

-- Zeile, deren Wert nicht vom Bereich abhängt (Rate der letzten Minuten, Instanzlimit, Prognosen, ...): sie zeigt ihren
-- Wert auch dann, wenn der gewählte Bereich nicht offen ist (Reiter "Instanz" ohne Lauf), statt "-"
local function globalRow(label, value)
  return { label = label, value = value, global = true }
end

ns.STAT_LINES = {
  { setting = "showXpRate", group = "STAT_GROUP_XP", label = "STAT_XP_RATE", rows = { { label = "ROW_XP_RATE", value = xpRate } } },
  { setting = "showRecentXpRate", group = "STAT_GROUP_XP", label = "STAT_RECENT_XP_RATE",
    rows = { globalRow("ROW_RECENT_XP_RATE", recentXpRate) } },
  { setting = "showXpGained", group = "STAT_GROUP_XP", label = "STAT_XP_GAINED", rows = { { label = "ROW_XP_GAINED", value = xpGained } } },
  { setting = "showLevelEta", group = "STAT_GROUP_XP", label = "STAT_LEVEL_ETA", rows = { { label = "ROW_LEVEL_ETA", value = timeToLevel } } },
  { setting = "showKillsToLevel", group = "STAT_GROUP_XP", label = "STAT_KILLS_TO_LEVEL",
    rows = { globalRow("ROW_KILLS_TO_LEVEL", countToLevel(Stats.XP_KILLS, Stats.PVE_KILLS)) } },
  { setting = "showQuestsToLevel", group = "STAT_GROUP_XP", label = "STAT_QUESTS_TO_LEVEL",
    rows = { globalRow("ROW_QUESTS_TO_LEVEL", countToLevel(Stats.XP_QUESTS, Stats.QUESTS)) } },
  { setting = "showQuestLogXp", group = "STAT_GROUP_XP", label = "STAT_QUEST_LOG_XP", rows = {
    globalRow("ROW_QUEST_XP_READY", questLogXp(1)),
    globalRow("ROW_QUEST_XP_OPEN", questLogXp(2)),
    globalRow("ROW_QUEST_XP_LEVEL_UP", questTurnInLevelUp),
  } },
  { setting = "showMaxLevelEta", group = "STAT_GROUP_XP", label = "STAT_MAX_LEVEL_ETA",
    rows = { globalRow("ROW_MAX_LEVEL_ETA", timeToMaxLevel) } },
  { setting = "showSplits", group = "STAT_GROUP_PROGRESS", label = "STAT_SPLITS", rows = {
    globalRow("ROW_SPLIT_LEVEL", function() return ns.Splits.CurrentDeltaText() end),
    globalRow("ROW_SPLIT_TOTAL", function() return ns.Splits.TotalDeltaText() end),
  } },
  { setting = "showGoal", group = "STAT_GROUP_PROGRESS", label = "STAT_GOAL", rows = { globalRow("ROW_GOAL", goalText) } },
  { setting = "showPveKills", group = "STAT_GROUP_COMBAT", label = "STAT_PVE_KILLS",
    rows = { { label = "ROW_PVE_KILLS", value = counter(Stats.PVE_KILLS) } } },
  { setting = "showKillRate", group = "STAT_GROUP_COMBAT", label = "STAT_KILL_RATE",
    rows = { { label = "ROW_KILL_RATE", value = perHour(Stats.PVE_KILLS) } } },
  { setting = "showRecentKills", group = "STAT_GROUP_COMBAT", label = "STAT_RECENT_KILLS", rows = {
    globalRow("ROW_RECENT_KILLS", recentCount(Stats.PVE_KILLS)),
    globalRow("ROW_RECENT_KILL_RATE", recentRate(Stats.PVE_KILLS)),
  } },
  { setting = "showPvpKills", group = "STAT_GROUP_COMBAT", label = "STAT_PVP_KILLS",
    rows = { { label = "ROW_PVP_KILLS", value = counter(Stats.PVP_KILLS) } } },
  { setting = "showSpecialKills", group = "STAT_GROUP_COMBAT", label = "STAT_SPECIAL_KILLS", rows = {
    { label = "ROW_ELITE_KILLS", value = counter(Stats.ELITE_KILLS) },
    { label = "ROW_RARE_KILLS", value = counter(Stats.RARE_KILLS) },
  } },
  { setting = "showItemsLooted", group = "STAT_GROUP_LOOT", label = "STAT_ITEMS_LOOTED", rows = {
    { label = "ROW_ITEMS_LOOTED", value = function(scope) return Format.Number(Stats.Get(scope, Stats.ITEMS_LOOTED)) end },
    { label = "ROW_ITEM_RATE", value = perHour(Stats.ITEMS_LOOTED) },
  } },
  { setting = "showRecentItems", group = "STAT_GROUP_LOOT", label = "STAT_RECENT_ITEMS", rows = {
    globalRow("ROW_RECENT_ITEMS", recentCount(Stats.ITEMS_LOOTED)),
    globalRow("ROW_RECENT_ITEM_RATE", recentRate(Stats.ITEMS_LOOTED)),
  } },
  { setting = "showDeaths", group = "STAT_GROUP_COMBAT", label = "STAT_DEATHS", rows = { { label = "ROW_DEATHS", value = deaths } } },
  { setting = "showKillsPerDeath", group = "STAT_GROUP_COMBAT", label = "STAT_KILLS_PER_DEATH",
    rows = { { label = "ROW_KILLS_PER_DEATH", value = killsPerDeath } } },
  { setting = "showNearDeaths", group = "STAT_GROUP_COMBAT", label = "STAT_NEAR_DEATHS", available = ns.NearDeath.IsAvailable,
    rows = { { label = "ROW_NEAR_DEATHS", value = counter(Stats.NEAR_DEATHS) } } },
  { setting = "showDeathless", group = "STAT_GROUP_COMBAT", label = "STAT_DEATHLESS",
    rows = { globalRow("ROW_DEATHLESS", timeWithoutDeath) } },
  { setting = "showXpSources", group = "STAT_GROUP_XP", label = "STAT_XP_SOURCES", rows = {
    { label = "ROW_XP_KILLS", value = xpShare("kills") },
    { label = "ROW_XP_QUESTS", value = xpShare("quests") },
    { label = "ROW_XP_EXPLORE", value = xpShare("explore") },
    { label = "ROW_XP_GATHER", value = xpShare("gather") },
    { label = "ROW_XP_OTHER", value = xpShare("other") },
  } },
  { setting = "showXpContext", group = "STAT_GROUP_XP", label = "STAT_XP_CONTEXT", rows = {
    { label = "ROW_XP_WORLD", value = xpContextShare(Stats.XP_WORLD) },
    { label = "ROW_XP_DUNGEON", value = xpContextShare(Stats.XP_DUNGEON) },
    { label = "ROW_XP_RAID", value = xpContextShare(Stats.XP_RAID) },
    { label = "ROW_XP_BATTLEGROUND", value = xpContextShare(Stats.XP_BATTLEGROUND) },
  } },
  { setting = "showRested", group = "STAT_GROUP_XP", label = "STAT_RESTED", rows = { { label = "ROW_RESTED", value = restedXp } } },
  { setting = "showRestedLeft", group = "STAT_GROUP_XP", label = "STAT_RESTED_LEFT", rows = { globalRow("ROW_RESTED_LEFT", restedLeft) } },
  { setting = "showTimeBreakdown", group = "STAT_GROUP_TIME_MONEY", label = "STAT_TIME_BREAKDOWN", rows = {
    { label = "ROW_TIME_COMBAT", value = timePart(Stats.COMBAT_SECONDS) },
    { label = "ROW_TIME_TAXI", value = timePart(Stats.TAXI_SECONDS) },
    { label = "ROW_TIME_AFK", value = timePart(Stats.AFK_SECONDS) },
    { label = "ROW_TIME_IDLE", value = timePart(Stats.IDLE_SECONDS) },
    { label = "ROW_TIME_REST", value = timeShare(function(scope) return ns.TimeBreakdown.GetRestSeconds(scope) end) },
  } },
  { setting = "showWellFedTime", group = "STAT_GROUP_TIME_MONEY", label = "STAT_WELL_FED_TIME", rows = {
    { label = "ROW_WELL_FED", value = timePart(Stats.WELL_FED_SECONDS) },
    { label = "ROW_NOT_WELL_FED", value = withoutBuff(Stats.WELL_FED_SECONDS) },
  } },
  { setting = "showWellRestedTime", group = "STAT_GROUP_TIME_MONEY", label = "STAT_WELL_RESTED_TIME",
    available = ns.Client.IsForever, rows = {
    { label = "ROW_WELL_RESTED", value = timePart(Stats.WELL_RESTED_SECONDS) },
    { label = "ROW_NOT_WELL_RESTED", value = withoutBuff(Stats.WELL_RESTED_SECONDS) },
  } },
  { setting = "showInstanceRun", group = "STAT_GROUP_INSTANCE", label = "STAT_INSTANCE_RUN",
    rows = { globalRow("ROW_INSTANCE_RUN", instanceRun) } },
  { setting = "showInstanceInfo", group = "STAT_GROUP_INSTANCE", label = "STAT_INSTANCE_INFO",
    rows = { globalRow("ROW_INSTANCE_INFO", instanceInfo) } },
  { setting = "showInstanceFit", group = "STAT_GROUP_INSTANCE", label = "STAT_INSTANCE_FIT",
    available = ns.InstanceInfo.HasLevels, rows = { globalRow("ROW_INSTANCE_FIT", instanceFit) } },
  { setting = "showInstanceLimit", group = "STAT_GROUP_INSTANCE", label = "STAT_INSTANCE_LIMIT",
    rows = { globalRow("ROW_INSTANCE_LIMIT", instanceLimit) } },
  { setting = "showInstancesToday", group = "STAT_GROUP_INSTANCE", label = "STAT_INSTANCES_TODAY",
    rows = { globalRow("ROW_INSTANCES_TODAY", instancesToday) } },
  { setting = "showQuests", group = "STAT_GROUP_TIME_MONEY", label = "STAT_QUESTS", rows = { { label = "ROW_QUESTS", value = counter(Stats.QUESTS) } } },
  { setting = "showMoney", group = "STAT_GROUP_TIME_MONEY", label = "STAT_MONEY", rows = { { label = "ROW_MONEY", value = income } } },
  { setting = "showSpending", group = "STAT_GROUP_TIME_MONEY", label = "STAT_SPENDING", rows = {
    { label = "ROW_SPENT_REPAIR", value = money(Stats.SPENT_REPAIR) },
    { label = "ROW_SPENT_MERCHANT", value = money(Stats.SPENT_MERCHANT) },
    { label = "ROW_SPENT_TAXI", value = money(Stats.SPENT_TAXI) },
    { label = "ROW_SPENT_TRAINER", value = money(Stats.SPENT_TRAINER) },
    { label = "ROW_SPENT_OTHER", value = money(Stats.SPENT_OTHER) },
    { label = "ROW_JUNK_INCOME", value = money(Stats.MONEY_JUNK) },
  } },
  { setting = "showReputation", group = "STAT_GROUP_TIME_MONEY", label = "STAT_REPUTATION", rows = {
    { label = "ROW_REPUTATION", value = function(scope) return Format.Number(Stats.Get(scope, Stats.REPUTATION)) end },
    { label = "ROW_REPUTATION_RATE", value = reputationRate },
  } },
  { setting = "showIncome", group = "STAT_GROUP_TIME_MONEY", label = "STAT_INCOME", rows = {
    { label = "ROW_INCOME_LOOT", value = money(Stats.INCOME_LOOT) },
    { label = "ROW_INCOME_QUEST", value = money(Stats.INCOME_QUEST) },
    { label = "ROW_INCOME_MERCHANT", value = money(Stats.INCOME_MERCHANT) },
    { label = "ROW_INCOME_MAIL", value = money(Stats.INCOME_MAIL) },
    { label = "ROW_INCOME_AUCTION", value = money(Stats.INCOME_AUCTION) },
    { label = "ROW_INCOME_TRADE", value = money(Stats.INCOME_TRADE) },
    { label = "ROW_INCOME_OTHER", value = money(Stats.INCOME_OTHER) },
    { label = "ROW_GOLD_PER_HOUR", value = goldPerHour },
  } },
}

-- Gruppen für die Einstellungen: nur die Reihenfolge der Abschnitte (weicht von der Reihenfolge der Zeilen ab);
-- jede Stat-Zeile nennt ihre group. Dass jede group hier steht und jede Gruppe Zeilen hat, prüft
-- tests/stat_presets_test.lua, ebenso, dass die Voreinstellungen nur vorhandene Stat-Einstellungen nennen.
ns.STAT_GROUPS = { "STAT_GROUP_XP", "STAT_GROUP_PROGRESS", "STAT_GROUP_COMBAT", "STAT_GROUP_LOOT", "STAT_GROUP_INSTANCE",
  "STAT_GROUP_TIME_MONEY" }

-- Voreinstellungen: genau diese Zeilen sind an, alle anderen aus
ns.STAT_PRESETS = {
  { label = "PRESET_MINIMAL", settings = { "showXpRate", "showLevelEta" } },
  { label = "PRESET_LEVELING", settings = { "showXpRate", "showXpGained", "showLevelEta", "showMaxLevelEta",
    "showPveKills", "showDeaths", "showQuests", "showMoney" } },
  { label = "PRESET_DUNGEON", settings = { "showXpRate", "showXpGained", "showPveKills", "showDeaths",
    "showKillsPerDeath", "showNearDeaths", "showInstanceRun", "showInstanceLimit", "showInstancesToday" } },
  -- Farm-Runde (Wunsch auf CurseForge, Roadmap 382): Tempo der Kills und der Beute, Gold/h steht in showIncome
  { label = "PRESET_FARMING", settings = { "showPveKills", "showKillRate", "showRecentKills", "showItemsLooted",
    "showRecentItems", "showIncome" } },
}

-- Der Stand vor der letzten Voreinstellung liegt in db.presetBackup (Einstellung -> an/aus, wie streamBackup im
-- Profil), damit "Rückgängig" ihn auch nach /reload wiederherstellt
function ns.ApplyStatPreset(preset)
  local on = {}
  for _, setting in ipairs(preset.settings) do on[setting] = true end
  ns.SetBatch(function(db)
    local backup = {}
    for _, stat in ipairs(ns.STAT_LINES) do
      backup[stat.setting] = db[stat.setting] and true or false
      db[stat.setting] = on[stat.setting] or false
    end
    db.presetBackup = backup
  end)
  ns.Print(string.format(ns.L.PRESET_APPLIED, ns.L[preset.label]) .. " " .. ns.L.PRESET_APPLIED_UNDO)
end

-- Voreinstellung, deren Zeilen gerade genau an sind (alle anderen aus); nil = eigene Auswahl
function ns.ActiveStatPreset(db)
  for _, preset in ipairs(ns.STAT_PRESETS) do
    local on = {}
    for _, setting in ipairs(preset.settings) do on[setting] = true end
    local matches = true
    for _, stat in ipairs(ns.STAT_LINES) do
      if (db[stat.setting] and true or false) ~= (on[stat.setting] or false) then
        matches = false
        break
      end
    end
    if matches then return preset end
  end
  return nil
end

-- Stand vor der letzten Voreinstellung wiederherstellen; false, wenn es keinen gibt
function ns.UndoStatPreset()
  local backup = ns.db.presetBackup
  if not backup then
    ns.Print(ns.L.PRESET_NOTHING_TO_UNDO)
    return false
  end
  ns.SetBatch(function(db)
    for _, stat in ipairs(ns.STAT_LINES) do
      if backup[stat.setting] ~= nil then db[stat.setting] = backup[stat.setting] end
    end
    db.presetBackup = nil
  end)
  ns.Print(ns.L.PRESET_UNDONE)
  return true
end

-- Zeile eingeschaltet und im Client verfügbar
function ns.IsStatShown(stat, db)
  return db[stat.setting] and (not stat.available or stat.available()) or false
end

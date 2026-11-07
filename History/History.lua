-- Historie und Auswertung: Level-, Session-, Kill- und Tod-Einträge aller Charaktere.
--
-- Kill- und Tod-Einträge: siehe Journal.lua
-- Level-Eintrag:   { level, seconds, xp, counters, completedAt, totalPlayed }
-- Session-Eintrag: { startedAt, endedAt, seconds, startLevel, endLevel, xp, counters }
-- isCurrent markiert das noch laufende Level bzw. die laufende Session.
-- Für den eingeloggten Charakter sind das Live-Werte, für andere der Stand ihres letzten Logouts.
local _, ns = ...
local L = ns.L
local Stats = ns.Stats

local History = {}
ns.History = History

local function isLoggedIn(characterKey)
  return characterKey == ns.characterKey
end

-- Einträge einer Liste (älteste zuerst gespeichert), neueste zuerst
-- Umgedrehte Kopie (neueste zuerst)
local function newestFirst(list)
  local records, count = {}, #list
  for i = count, 1, -1 do
    records[count - i + 1] = list[i]
  end
  return records
end

-- Journal neueste zuerst: Journal.GetEntries liefert dieselbe Liste, solange sich nichts ändert, daher hier je Liste
-- zwischengespeichert (die Historie fragt jede Sekunde, Journale können sehr lang sein). Ergebnis nicht verändern.
local reversedJournals = setmetatable({}, { __mode = "k" })

local function journalNewestFirst(characterKey, logName)
  local list = ns.Journal.GetEntries(characterKey, logName)
  reversedJournals[list] = reversedJournals[list] or newestFirst(list)
  return reversedJournals[list]
end

function History.GetCharacter(characterKey)
  return ns.Database.GetCharacters()[characterKey]
end

-- Eingeloggter Charakter zuerst, danach alphabetisch
function History.GetCharacterKeys()
  local keys = {}
  for key in pairs(ns.Database.GetCharacters()) do
    if not isLoggedIn(key) then table.insert(keys, key) end
  end
  table.sort(keys)
  table.insert(keys, 1, ns.characterKey)
  return keys
end

-- Anzeigename "Name - Realm". Mit Streamer-Datenschutz (Einstellung streamerPrivacy) ohne Realm,
-- andere Charaktere nur als "Charakter N" (N = Platz in GetCharacterKeys), gegen Stream-Sniping.
function History.DisplayName(characterKey)
  local character = History.GetCharacter(characterKey)
  if not ns.db.streamerPrivacy then
    return (character.name or "?") .. " - " .. (character.realm or "?")
  end
  if isLoggedIn(characterKey) then
    return character.name or "?"
  end
  for index, key in ipairs(History.GetCharacterKeys()) do
    if key == characterKey then return string.format(L.HIDDEN_CHARACTER, index) end
  end
  return "?"
end

local function currentLevelRecord(characterKey)
  if isLoggedIn(characterKey) then
    return {
      level = ns.level,
      seconds = Stats.GetSeconds(Stats.LEVEL),
      xp = Stats.GetXp(Stats.LEVEL),
      counters = ns.TimeBreakdown.Snapshot(Stats.LEVEL),
      partial = ns.character.currentLevel.partial,
      isCurrent = true,
    }
  end
  local saved = History.GetCharacter(characterKey).currentLevel
  return { level = saved.level, seconds = saved.seconds, xp = saved.xp, counters = saved.counters,
    partial = saved.partial, isCurrent = true }
end

local function currentSessionRecord(characterKey)
  local session = History.GetCharacter(characterKey).currentSession
  if not session.startedAt then return nil end
  local record = ns.Session.ToRecord(session)
  if isLoggedIn(characterKey) then
    record.seconds = ns.Session.GetSeconds()
    record.endLevel = ns.level
    record.xp = Stats.GetXp(Stats.SESSION)
    record.counters = ns.TimeBreakdown.Snapshot(Stats.SESSION)
    record.isCurrent = true
  end
  return record
end

-- Neueste zuerst, laufendes Level vorne
function History.GetLevelRecords(characterKey)
  local records = {}
  for _, record in pairs(History.GetCharacter(characterKey).levelHistory) do
    table.insert(records, record)
  end
  table.sort(records, function(a, b) return a.level > b.level end)
  table.insert(records, 1, currentLevelRecord(characterKey))
  return records
end

-- Neueste zuerst, laufende (bzw. letzte) Session vorne
function History.GetSessionRecords(characterKey)
  local records = newestFirst(History.GetCharacter(characterKey).sessionHistory)
  local current = currentSessionRecord(characterKey)
  if current then table.insert(records, 1, current) end
  return records
end

-- Timeline: nur abgeschlossene Level, neueste zuerst. reachedLevel = das damit erreichte Level.
function History.GetMilestones(characterKey)
  local milestones = {}
  for _, record in ipairs(History.GetLevelRecords(characterKey)) do
    if not record.isCurrent then
      table.insert(milestones, {
        reachedLevel = record.level + 1,
        reachedAt = record.completedAt,
        totalPlayed = record.totalPlayed,
        seconds = record.seconds,
      })
    end
  end
  return milestones
end

-- Kills und Tode einzeln (Form siehe Journal.lua), neueste zuerst
function History.GetKillLog(characterKey)
  return journalNewestFirst(characterKey, "killLog")
end

function History.GetDeathLog(characterKey)
  return journalNewestFirst(characterKey, "deathLog")
end

function History.GetQuestLog(characterKey)
  return journalNewestFirst(characterKey, "questLog")
end

function History.GetLootLog(characterKey)
  return journalNewestFirst(characterKey, "lootLog")
end

function History.GetNearDeathLog(characterKey)
  return journalNewestFirst(characterKey, "nearDeathLog")
end

-- Instanz-Läufe, neueste zuerst; ein laufender (bzw. beim letzten Logout offener) Lauf steht vorne
function History.GetInstanceLog(characterKey)
  local character = History.GetCharacter(characterKey)
  local records = newestFirst(ns.Journal.GetEntries(characterKey, "instanceLog"))  -- Kopie: laufender Lauf kommt dazu
  local run = character.currentRun
  if run then
    local record = ns.Instances.ToRecord(run)
    table.insert(records, 1, {
      time = run.startedAt,
      name = run.name,
      seconds = ns.Instances.GetRunSeconds(run),
      level = run.level,
      xp = record.xp,
      counters = record.counters,
      isCurrent = true,
    })
  end
  return records
end

-- Vergleich aller Charaktere: eine Zeile je Charakter aus Level-Historie und laufendem Level.
-- Sortiert nach durchschnittlicher Zeit je abgeschlossenem Level (schnellster zuerst, ohne Daten zuletzt).
-- Eintrag: { key, name, realm, class, level, levelsCompleted, averageLevelSeconds, xpRate, counters, isCurrent }
local function compareRecord(characterKey)
  local character = History.GetCharacter(characterKey)
  local levelRecords = History.GetLevelRecords(characterKey)
  local summary = History.Summarize(levelRecords)

  local completedSeconds, completedCount = 0, 0
  for _, record in ipairs(levelRecords) do
    if not record.isCurrent and record.seconds then
      completedSeconds = completedSeconds + record.seconds
      completedCount = completedCount + 1
    end
  end

  return {
    key = characterKey,
    name = character.name,
    realm = character.realm,
    class = character.class,
    level = character.currentLevel.level,
    levelsCompleted = completedCount,
    averageLevelSeconds = completedCount > 0 and completedSeconds / completedCount or nil,
    xpRate = ns.Experience.RecordRate(summary),
    counters = summary.counters,
    coverage = ns.Coverage.Get(characterKey),
    isCurrent = isLoggedIn(characterKey),
  }
end

function History.GetCharacterComparison()
  local records = {}
  for _, key in ipairs(History.GetCharacterKeys()) do
    table.insert(records, compareRecord(key))
  end
  table.sort(records, function(a, b)
    if a.averageLevelSeconds and b.averageLevelSeconds then
      return a.averageLevelSeconds < b.averageLevelSeconds
    end
    if a.averageLevelSeconds or b.averageLevelSeconds then
      return a.averageLevelSeconds ~= nil
    end
    return (a.name or "") < (b.name or "")
  end)
  return records
end

-- Todesursache als Text: Umgebung (z.B. "Sturz"), "Verursacher (Zauber)" oder "Unbekannt"
function History.DeathCauseText(entry)
  if entry.environment then
    local key = "CAUSE_" .. string.upper(entry.environment)
    local text = L[key]
    return text ~= key and text or entry.environment  -- L liefert bei fehlendem Text den Schlüssel
  end
  if entry.killer and entry.spell then
    return string.format("%s (%s)", entry.killer, entry.spell)
  end
  return entry.killer or entry.spell or L.CAUSE_UNKNOWN
end

-- Auswertung: Summe über Einträge (Zeit, XP und alle Zähler). Für XP/h zählen nur Einträge mit
-- bekannter Dauer (ratedXp, ratedAfkSeconds, ratedIdleSeconds; siehe Experience.RecordRate), sonst wäre die Rate zu hoch.
function History.Summarize(records)
  local summary = { seconds = 0, xp = 0, counters = {}, count = #records, ratedXp = 0, ratedAfkSeconds = 0,
    ratedIdleSeconds = 0 }
  for _, record in ipairs(records) do
    summary.seconds = summary.seconds + (record.seconds or 0)
    summary.xp = summary.xp + (record.xp or 0)
    for counter, value in pairs(record.counters) do
      summary.counters[counter] = (summary.counters[counter] or 0) + value
    end
    if record.seconds then
      summary.ratedXp = summary.ratedXp + (record.xp or 0)
      summary.ratedAfkSeconds = summary.ratedAfkSeconds + (record.counters[ns.Stats.AFK_SECONDS] or 0)
      summary.ratedIdleSeconds = summary.ratedIdleSeconds + (record.counters[ns.Stats.IDLE_SECONDS] or 0)
    end
  end
  return summary
end

-- Läuft vor dem Zurücksetzen der Zähler. XP-Bedarf des alten Levels aus Experience.XpMaxOf, weil UnitXPMax hier
-- schon den des neuen liefern kann (Reihenfolge von PLAYER_XP_UPDATE und PLAYER_LEVEL_UP).
-- seconds/totalPlayed sind nil, falls /played noch nicht geantwortet hatte.
ns.OnLevelCompleted(function(completedLevel)
  ns.character.levelHistory[completedLevel] = {
    level = completedLevel,
    seconds = Stats.GetSeconds(Stats.LEVEL),
    xp = ns.Experience.XpMaxOf(completedLevel),
    counters = Stats.Snapshot(Stats.LEVEL),
    completedAt = time(),                           -- Zeitpunkt, an dem das nächste Level erreicht wurde
    totalPlayed = ns.PlayedTime.GetTotalSeconds(),  -- /played gesamt in diesem Moment
    partial = ns.character.currentLevel.partial,    -- nur teilweise erfasst, nie Bestzeit (Coverage.lua)
  }
end)

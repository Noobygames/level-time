-- Persönliche Rekorde über alle Charaktere (Roadmap 272), in LevelTimerStatsDB.personalRecords[kind] =
-- { value, characterKey, at, level }:
--   bestHour          meiste XP in 60 Minuten einer Session (gleitend über den XP-Verlauf in 5-min-Abschnitten, Session.lua)
--   bestSessionRate   beste XP/h einer Session ab 30 Minuten Spielzeit
--   biggestGain       größter einzelner XP-Gewinn
--   bestInstanceRate  beste XP/h eines beendeten Instanz-Laufs (ab 5 Minuten)
-- Dazu das schnellste Level je Levelnummer: Vergleich mit der Bestzeit aller Charaktere (levelHistory ohne Teil-Level);
-- die Liste dazu zeigt Speedrun > Rekorde. Ein gebrochener Rekord wird mit Einstellung announceRecords als Karte und
-- Chatzeile gemeldet (Alerts.Notify), aber nur, wenn es schon einen alten Wert gab, und laufende Werte (60 Minuten,
-- Session-XP/h) höchstens einmal je Session; gespeichert wird jeder neue Bestwert.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    announceRecords = false,
  },
})
local L = ns.L
local Stats = ns.Stats
local Format = ns.Format
local Experience = ns.Experience

local PersonalRecords = {}
ns.PersonalRecords = PersonalRecords

PersonalRecords.BEST_HOUR = "bestHour"
PersonalRecords.BEST_SESSION_RATE = "bestSessionRate"
PersonalRecords.BIGGEST_GAIN = "biggestGain"
PersonalRecords.BEST_INSTANCE_RATE = "bestInstanceRate"

local HOUR_SECONDS = 3600
local MIN_SESSION_SECONDS = 30 * 60   -- Session-XP/h erst ab 30 Minuten
local MIN_INSTANCE_SECONDS = 5 * 60   -- kürzere Läufe haben zufällige Raten
local SESSION_CHECK_INTERVAL = 60
local RECORD_COLOR = { 1, 0.5, 0 }

local function xpText(value) return Format.Number(value) end
local function rateText(value) return string.format(L.RECORD_RATE_VALUE, Format.Number(value)) end

-- Arten in der Reihenfolge der Tabelle; once = laufender Wert, höchstens eine Meldung je Session
PersonalRecords.KINDS = {
  { id = PersonalRecords.BEST_HOUR, label = "RECORD_BEST_HOUR", format = xpText, once = true },
  { id = PersonalRecords.BEST_SESSION_RATE, label = "RECORD_BEST_SESSION_RATE", format = rateText, once = true },
  { id = PersonalRecords.BIGGEST_GAIN, label = "RECORD_BIGGEST_GAIN", format = xpText },
  { id = PersonalRecords.BEST_INSTANCE_RATE, label = "RECORD_BEST_INSTANCE_RATE", format = rateText },
}
local KIND_BY_ID = {}
for _, kind in ipairs(PersonalRecords.KINDS) do KIND_BY_ID[kind.id] = kind end

local announcedThisSession = {}

local function store()
  LevelTimerStatsDB.personalRecords = LevelTimerStatsDB.personalRecords or {}
  return LevelTimerStatsDB.personalRecords
end

-- Gespeicherter Rekord einer Art oder nil
function PersonalRecords.Get(id)
  local record = store()[id]
  return type(record) == "table" and type(record.value) == "number" and record or nil
end

local function notifyRecord(title, text)
  ns.Alerts.Notify({ title = title, text = text, icon = ns.Alerts.ICONS.levelUp }, RECORD_COLOR)
end

local function announce(title, text)
  if not ns.db.announceRecords then return end
  notifyRecord(title, text)
end

-- Vorschau (Testen-Knopf): Rekordmeldung mit Beispielwerten für die erste Art
function PersonalRecords.PreviewAnnouncement()
  local kind = PersonalRecords.KINDS[1]
  notifyRecord(L.RECORD_TITLE, string.format(L.RECORD_BROKEN, L[kind.label], kind.format(120), kind.format(100)))
end

-- Neuen Wert prüfen; true, wenn er den Rekord bricht (dann gespeichert)
function PersonalRecords.Offer(id, value)
  if type(value) ~= "number" or value <= 0 then return false end
  local previous = PersonalRecords.Get(id)
  if previous and value <= previous.value then return false end
  store()[id] = { value = value, characterKey = ns.characterKey, at = time(), level = ns.level }
  local kind = KIND_BY_ID[id]
  ns.Debug("records", "%s: %s (before %s)", id, value, previous and previous.value or "-")
  if previous and not (kind.once and announcedThisSession[id]) then
    announcedThisSession[id] = true
    announce(L.RECORD_TITLE, string.format(L.RECORD_BROKEN, L[kind.label], kind.format(value), kind.format(previous.value)))
  end
  return true
end

---------------------------------------------------------------------------
-- Quellen der Werte
---------------------------------------------------------------------------
local STEPS_PER_HOUR = HOUR_SECONDS / ns.Session.TIMELINE_STEP

-- XP der letzten 60 Minuten der Session: die letzten STEPS_PER_HOUR Abschnitte des XP-Verlaufs
local function lastHourXp()
  local timeline = ns.character.currentSession.xpTimeline
  if not timeline then return 0 end
  local current = math.floor(ns.Session.GetSeconds() / ns.Session.TIMELINE_STEP) + 1
  local sum = 0
  for step = math.max(1, current - STEPS_PER_HOUR + 1), current do
    sum = sum + (timeline[step] or 0)
  end
  return sum
end

-- Session.lua trägt den Gewinn vorher in den Verlauf ein (lädt früher, Listener in Ladereihenfolge)
Stats.OnIncrement(function(counter)
  if counter == Stats.XP_GAINED then PersonalRecords.Offer(PersonalRecords.BEST_HOUR, lastHourXp()) end
end)

Experience.OnGain(function(amount)
  PersonalRecords.Offer(PersonalRecords.BIGGEST_GAIN, amount)
end)

ns.Every(SESSION_CHECK_INTERVAL, function()
  if ns.Session.GetSeconds() < MIN_SESSION_SECONDS then return end
  PersonalRecords.Offer(PersonalRecords.BEST_SESSION_RATE, Experience.GetRatePerHour(Stats.SESSION))
end)

ns.Journal.OnAdd(function(logName, entry)
  if logName ~= "instanceLog" or (entry.seconds or 0) < MIN_INSTANCE_SECONDS then return end
  PersonalRecords.Offer(PersonalRecords.BEST_INSTANCE_RATE, Experience.CalculateRate(entry.xp, entry.seconds))
end)

-- Schnellstes Level: Bestzeit aller anderen Einträge für dieses Level (ohne Teil-Level, Coverage.lua)
local function bestOtherLevelSeconds(level, own)
  local best
  for _, character in pairs(ns.Database.GetCharacters()) do
    local record = character.levelHistory and character.levelHistory[level]
    if record and record ~= own and record.seconds and not record.partial and (not best or record.seconds < best) then
      best = record.seconds
    end
  end
  return best
end

-- Läuft nach History.lua (lädt früher): der Eintrag des abgeschlossenen Levels steht schon in levelHistory
ns.OnLevelCompleted(function(completedLevel)
  local own = ns.character.levelHistory[completedLevel]
  if not own or not own.seconds or own.partial then return end
  local best = bestOtherLevelSeconds(completedLevel, own)
  if best and own.seconds < best then
    ns.Debug("records", "fastest level %s: %s (before %s)", completedLevel, own.seconds, best)
    announce(L.RECORD_TITLE, string.format(L.RECORD_FASTEST_LEVEL, completedLevel, Format.Duration(own.seconds),
      Format.Duration(best)))
  end
end)

ns.OnLogin(function() announcedThisSession = {} end)

---------------------------------------------------------------------------
-- Zeilen für die Historie (Unterreiter "Persönliche Rekorde"): { label, value, characterKey, at, level }
---------------------------------------------------------------------------
function PersonalRecords.GetRows()
  local rows = {}
  for _, kind in ipairs(PersonalRecords.KINDS) do
    local record = PersonalRecords.Get(kind.id)
    table.insert(rows, {
      label = L[kind.label],
      value = record and kind.format(record.value) or "-",
      sortValue = record and record.value,
      characterKey = record and record.characterKey,
      at = record and record.at,
      level = record and record.level,
    })
  end
  return rows
end

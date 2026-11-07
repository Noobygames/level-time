-- Vergleich mit Speedrun-Rekorden (Daten: SpeedrunRecords.lua, erzeugt von tools/records).
-- Rekorde gibt es nur je Abschnitt (1-10, 1-20, 1-60), nicht je Level. Verglichen wird daher die
-- /played-Zeit beim Erreichen des Levels: Sie zählt der Server ab Level 1, also auch dann richtig,
-- wenn das Addon erst später installiert wurde. Rekordzeiten sind Echtzeit, /played ist Spielzeit;
-- beides liegt nah beieinander, ist aber nicht exakt dasselbe.
-- Einstellung worldRecordScope: "overall" (schnellster Lauf) oder "class" (schnellster der eigenen Klasse).
local _, ns = ...

local WorldRecords = {
  OVERALL = "overall",
  CLASS = "class",
}
ns.WorldRecords = WorldRecords

local function data()
  return ns.SpeedrunRecordsData or { brackets = {} }
end

function WorldRecords.GetSource()
  local source = data()
  return source.source, source.fetched
end

local SECONDS_PER_DAY = 86400
local NOON = 12  -- Mittag des Stichtags, damit Zeitzonen den Tag nicht verschieben

-- Zeitpunkt des Stands (Mittag des Tags von "make records", Feld fetched = "JJJJ-MM-TT"); nil ohne Datum
function WorldRecords.GetFetchedAt()
  local _, fetched = WorldRecords.GetSource()
  local year, month, day = (fetched or ""):match("^(%d+)-(%d+)-(%d+)$")
  if not year then return nil end
  return time({ year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = NOON })
end

-- Stand als Datum in der eingestellten Sprache, "?" ohne Datum
function WorldRecords.GetFetchedText()
  local fetchedAt = WorldRecords.GetFetchedAt()
  return fetchedAt and date(ns.L.FULL_DATE_FORMAT, fetchedAt) or "?"
end

-- Alter der Rekord-Daten in ganzen Tagen; nil ohne Datum
function WorldRecords.GetAgeDays()
  local fetchedAt = WorldRecords.GetFetchedAt()
  if not fetchedAt then return nil end
  return math.max(0, math.floor((time() - fetchedAt) / SECONDS_PER_DAY))
end

-- Abschnitte lassen sich einzeln aus der Split-Liste nehmen (db.recordBrackets[label] = false)
function WorldRecords.IsBracketShown(label)
  return ns.db.recordBrackets[label] ~= false
end

-- Bezeichnungen aller Abschnitte in der Reihenfolge der Daten, z.B. für die Einstellungen
function WorldRecords.GetBracketLabels()
  local labels = {}
  for _, bracket in ipairs(data().brackets) do table.insert(labels, bracket.label) end
  return labels
end

-- Rekord eines Abschnitts für den gewählten Vergleich; ohne Klassenrekord der Gesamtrekord
function WorldRecords.RecordFor(bracket)
  if ns.db.worldRecordScope == WorldRecords.CLASS then
    return bracket.classes[ns.character.class] or bracket.best
  end
  return bracket.best
end

-- /played beim Erreichen des Levels; nil, solange es nicht erreicht oder nicht bekannt ist
local function playedWhenReached(level)
  local record = ns.character.levelHistory[level - 1]
  return record and record.totalPlayed
end

-- Je Abschnitt: { label, level, record, ownSeconds, delta, reached }.
-- Erreicht: eigene /played-Zeit beim Erreichen. Noch nicht erreicht: laufende /played-Zeit,
-- eine negative Abweichung heißt dann "noch im Rennen".
function WorldRecords.GetComparisons()
  local result = {}
  for _, bracket in ipairs(data().brackets) do
    local record = WorldRecords.RecordFor(bracket)
    local reached = ns.level >= bracket.level
    local own
    if reached then
      own = playedWhenReached(bracket.level)
    else
      own = ns.PlayedTime.GetTotalSeconds()
    end
    table.insert(result, {
      label = bracket.label,
      level = bracket.level,
      record = record,
      ownSeconds = own,
      delta = own and own - record.seconds or nil,
      reached = reached,
    })
  end
  return result
end

-- Alle Rekorde als Zeilen: je Abschnitt der Gesamtrekord und der jeder Klasse
-- { label, level, record, isOverall }
function WorldRecords.GetAllRecords()
  local rows = {}
  for _, bracket in ipairs(data().brackets) do
    table.insert(rows, { label = bracket.label, level = bracket.level, record = bracket.best, isOverall = true })
    local classes = {}
    for class in pairs(bracket.classes) do table.insert(classes, class) end
    table.sort(classes)
    for _, class in ipairs(classes) do
      table.insert(rows, { label = bracket.label, level = bracket.level, record = bracket.classes[class] })
    end
  end
  return rows
end

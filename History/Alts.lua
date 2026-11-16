-- Twink-Übersicht (Roadmap 321): alle Charaktere mit Ruhe-Schätzung (RestedEstimate.lua), Gold, /played und
-- zuletzt gesehen. Reihenfolge „Wer ist dran?“: meiste Ruhe-XP zuerst, bei Gleichstand am längsten nicht gespielt.
-- Beim Logout merkt sich jeder Charakter /played (character.played) und die Uhrzeit (character.lastSeen); Gold
-- speichert MoneyCounter.lua (character.money). Ältere Daten ohne lastSeen nehmen das Ende der letzten Session.
local _, ns = ...

local Alts = {}
ns.Alts = Alts

local SECONDS_PER_DAY = 24 * 3600
Alts.LONG_AWAY_DAYS = 30  -- ab so vielen Tagen ohne Login gilt ein Charakter als lange nicht gespielt

-- Zuletzt gesehen (Unix-Zeit); eingeloggter Charakter: jetzt
local function lastSeen(key, character)
  if key == ns.characterKey then return time() end
  if character.lastSeen then return character.lastSeen end
  local sessions = character.sessionHistory
  local last = type(sessions) == "table" and sessions[#sessions]
  return last and last.endedAt or nil
end

local function played(key, character)
  if key == ns.characterKey then return ns.PlayedTime.GetTotalSeconds() or character.played end
  return character.played
end

-- Ganze Tage seit dem letzten Login; nil ohne Daten, 0 für den eingeloggten Charakter
function Alts.DaysAway(record)
  if record.key == ns.characterKey or not record.lastSeen then return record.lastSeen and 0 or nil end
  return math.floor(math.max(0, time() - record.lastSeen) / SECONDS_PER_DAY)
end

function Alts.IsLongAway(record)
  local days = Alts.DaysAway(record)
  return days ~= nil and days >= Alts.LONG_AWAY_DAYS
end

-- „Wer ist dran?“: Ruhe-XP absteigend (ohne Schätzung ans Ende), dann am längsten nicht gespielt zuerst
local function whoIsNext(a, b)
  if (a.rested or -1) ~= (b.rested or -1) then return (a.rested or -1) > (b.rested or -1) end
  if (a.lastSeen or 0) ~= (b.lastSeen or 0) then return (a.lastSeen or 0) < (b.lastSeen or 0) end
  return a.key < b.key
end

-- Zeilen { key, class, level, money, played, lastSeen, rested } in der Reihenfolge „Wer ist dran?“
function Alts.GetRecords()
  local records = {}
  for _, key in ipairs(ns.History.GetCharacterKeys()) do
    local character = ns.History.GetCharacter(key)
    table.insert(records, { key = key, class = character.class, level = character.currentLevel.level,
      money = character.money, played = played(key, character), lastSeen = lastSeen(key, character),
      rested = (ns.RestedEstimate.Get(key)) })
  end
  table.sort(records, whoIsNext)
  return records
end

-- Zahl der lange nicht gespielten Charaktere (Hinweis unter der Tabelle)
function Alts.LongAwayCount(records)
  local count = 0
  for _, record in ipairs(records) do
    if Alts.IsLongAway(record) then count = count + 1 end
  end
  return count
end

ns.OnLogout(function()
  ns.character.played = ns.PlayedTime.GetTotalSeconds() or ns.character.played
  ns.character.lastSeen = time()
end)

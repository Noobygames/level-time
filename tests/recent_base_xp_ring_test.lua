-- Roadmap 354: "Kills/Quests bis Level-Up" aus einem Ring der letzten 50 Basis-XP-Werte statt jedes Mal den Eingang
-- rückwärts zu lesen; Ergebnis wie der alte Durchlauf, auch nach Kürzen und Charakterwechsel. Bracket-Prognose (PB,
-- Summe der Bestzeiten) einmal je Stand der Läufe.
local Experience = addon.Experience
local Journal = addon.Journal

wow.login({ level = 10, xp = 0, xpMax = 1000 })

-- Der alte Durchlauf als Vergleich
local function scan(logName, sampleSize)
  local log = addon.character[logName] or {}
  local sum, count = 0, 0
  for i = #log, 1, -1 do
    local entry = log[i]
    if type(entry.xp) == "number" and entry.xp > 0 and (logName ~= "killLog" or entry.kind == Journal.PVE) then
      sum = sum + entry.xp - (entry.rested or 0)
      count = count + 1
      if count >= sampleSize then break end
    end
  end
  return count > 0 and sum / count or nil
end

math.randomseed(7)
local mismatches = { count = 0, first = nil }
local function check(step)
  for _, logName in ipairs({ "killLog", "questLog" }) do
    for _, size in ipairs({ 1, 2, 5, 20, 49, 50 }) do
      if Experience.RecentBaseXp(logName, size) ~= scan(logName, size) then
        mismatches.count = mismatches.count + 1
        mismatches.first = mismatches.first or (step .. " " .. logName .. " " .. size)
      end
    end
  end
end

check("leer")
for step = 1, 300 do
  local roll = math.random(20)
  if roll <= 12 then
    local kind = math.random(5) == 1 and Journal.PVP or Journal.PVE
    local xp = math.random(4) > 1 and math.random(500) or nil
    Journal.AddKill(kind, "Wolf", nil, xp, xp and math.random(3) == 1 and math.floor(xp / 2) or nil)
  elseif roll <= 16 then
    Journal.AddQuest(step, "Quest", math.random(3) > 1 and math.random(2000) or nil, 0)
  elseif roll == 17 then
    table.remove(addon.character.killLog, 1)  -- gekürzter Eingang
  elseif roll == 18 then
    local log = addon.character.questLog
    for _ = 1, math.min(#log, 5) do table.remove(log, 1) end
  end
  if step % 3 == 0 then check(step) end
end
expect("Ring = Durchlauf (" .. tostring(mismatches.first) .. ")", mismatches.count, 0)

-- Neuer Eingang (z.B. anderer Charakter): neu gefüllt
addon.character.killLog = { { kind = Journal.PVE, xp = 300, rested = 100 } }
expect("neuer Eingang", Experience.RecentBaseXp("killLog", 20), 200)
Journal.AddKill(Journal.PVE, "Eber", nil, 100)
expect("danach angehängt", Experience.RecentBaseXp("killLog", 20), 150)

-- Bracket-Prognose: PB und Summe der Bestzeiten nur neu, wenn die Läufe neu gebaut werden
local BracketForecast = addon.BracketForecast
for level = 1, 9 do addon.character.levelHistory[level] = { level = level, seconds = 100 } end
addon.Runs.Invalidate()
expect("Summe der Bestzeiten", BracketForecast.SumOfBest(10), 900)
local reads = { count = 0 }
local getAll = addon.Runs.GetAll
local levelTimes = addon.Runs.LevelTimes
addon.Runs.LevelTimes = function(...)
  reads.count = reads.count + 1
  return levelTimes(...)
end
for _ = 1, 5 do
  BracketForecast.SumOfBest(10)
  BracketForecast.PersonalBest(10)
end
expect("ohne Änderung keine Level-Zeiten gelesen", reads.count, 0)
addon.character.levelHistory[5].seconds = 50
addon.Runs.Invalidate()
expect("nach Änderung neu", BracketForecast.SumOfBest(10), 850)
addon.Runs.LevelTimes = levelTimes
expect("GetAll unverändert", addon.Runs.GetAll, getAll)

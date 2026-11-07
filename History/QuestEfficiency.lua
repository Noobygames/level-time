-- Quest-Effizienz (Roadmap 347): je Quest-ID über alle eigenen Charaktere, wie oft sie abgegeben wurde, wie lange sie
-- im Schnitt von der Annahme bis zur Abgabe dauerte (Quest-Splits, Journal-Feld duration) und wie viel XP sie brachte;
-- daraus XP pro Minute. Nur eigene Daten (Journal questLog aller Charaktere, inklusive Archiv).
-- Neu berechnet nur bei neuem Journal-Stand (Journal.Revision) oder anderer Charakterzahl.
-- Tooltipzeile (Einstellung questEfficiencyTooltip, aus): an Quest-Links im GameTooltip
-- (hooksecurefunc(GameTooltip, "SetHyperlink"), alle Clients; Chat-Links, Historientabellen, Retail-/Forever-Questliste,
-- soweit sie den Link-Tooltip zeigt) "Bisher: Ø 3:40, 1.250 XP/min (3x)".
local _, ns = ...
local L = ns.L
local Format = ns.Format

local QuestEfficiency = {}
ns.QuestEfficiency = QuestEfficiency

local SECONDS_PER_MINUTE = 60
local cache, cachedFor

local function newStat(questID)
  return { questID = questID, count = 0, seconds = 0, timed = 0, xp = 0, rewarded = 0 }
end

local function finish(stat)
  stat.averageSeconds = stat.timed > 0 and stat.seconds / stat.timed or nil
  stat.averageXp = stat.rewarded > 0 and stat.xp / stat.rewarded or nil
  if stat.averageSeconds and stat.averageXp and stat.averageSeconds > 0 then
    stat.xpPerMinute = stat.averageXp / (stat.averageSeconds / SECONDS_PER_MINUTE)
  end
end

local function build()
  local stats, list = {}, {}
  for _, key in ipairs(ns.History.GetCharacterKeys()) do
    for _, entry in ipairs(ns.Journal.GetEntries(key, "questLog")) do
      local questID = entry.questID
      if type(questID) == "number" then
        local stat = stats[questID]
        if not stat then
          stat = newStat(questID)
          stats[questID] = stat
          list[#list + 1] = stat
        end
        stat.count = stat.count + 1
        stat.name = entry.name or stat.name
        if type(entry.duration) == "number" then
          stat.seconds, stat.timed = stat.seconds + entry.duration, stat.timed + 1
        end
        if type(entry.xp) == "number" and entry.xp > 0 then
          stat.xp, stat.rewarded = stat.xp + entry.xp, stat.rewarded + 1
        end
      end
    end
  end
  for _, stat in ipairs(list) do finish(stat) end
  return { byQuest = stats, list = list }
end

local function data()
  local key = ns.Journal.Revision() .. ":" .. #ns.History.GetCharacterKeys()
  if key ~= cachedFor then
    cache, cachedFor = build(), key
  end
  return cache
end

-- Alle Quests mit Abgaben (Liste, nicht verändern)
function QuestEfficiency.GetRecords()
  return data().list
end

function QuestEfficiency.Of(questID)
  return data().byQuest[questID]
end

-- "Ø 3:40, 1.250 XP/min (3x)"; nil ohne Daten
function QuestEfficiency.Text(questID)
  local stat = QuestEfficiency.Of(questID)
  if not stat then return nil end
  local parts = {}
  if stat.averageSeconds then table.insert(parts, string.format(L.QUEST_EFFICIENCY_AVERAGE, Format.Duration(stat.averageSeconds))) end
  if stat.xpPerMinute then
    table.insert(parts, string.format(L.QUEST_EFFICIENCY_RATE, Format.Number(math.floor(stat.xpPerMinute + 0.5))))
  end
  table.insert(parts, string.format(L.QUEST_EFFICIENCY_COUNT, stat.count))
  return string.format(L.QUEST_EFFICIENCY_LINE, table.concat(parts, ", "))
end

local hooked = false
local function hook()
  if hooked or type(GameTooltip) ~= "table" or type(GameTooltip.SetHyperlink) ~= "function" then return end
  hooked = true
  hooksecurefunc(GameTooltip, "SetHyperlink", function(tooltip, link)
    if not ns.db.questEfficiencyTooltip or ns.IsSecret(link) or type(link) ~= "string" then return end
    local questID = tonumber((link:match("quest:(%d+)")))
    local text = questID and QuestEfficiency.Text(questID)
    if not text then return end
    tooltip:AddLine(text, 0.6, 0.8, 1)
    tooltip:Show()
  end)
end

ns.RegisterApply(function(db)
  if db.questEfficiencyTooltip then hook() end
end)

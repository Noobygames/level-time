-- Zusatz-Tracker für Quests, die der Blizzard-Tracker nicht anzeigt (Einstellung questTracker, Standard aus): eine
-- Karte (Lib/Card.lua) mit Questlevel, Titel und Zielen aller Quests des Logs ohne Beobachtung. Nur Classic Era/TBC
-- (globale GetNumQuestWatches, Grenze MAX_WATCHABLE_QUESTS = 5); Forever lädt den Retail-Tracker mit 25 Plätzen
-- (Constants.QuestWatchConsts.MAX_QUEST_WATCHES), dort ist die Einstellung nicht wählbar.
-- Aktualisiert einmal je Sekunde, solange die Einstellung an ist. Position über Lib/Frames.lua (Id "questTracker").
local _, ns = ...
local L = ns.L
local Theme = ns.Theme
local QuestLog = ns.QuestLog

ns.RegisterDefaults({
  settings = {
    questTracker = false,
  },
})

local QuestTracker = {}
ns.QuestTracker = QuestTracker

local DEFAULT_POS = { "TOPRIGHT", "TOPRIGHT", -20, -300 }

local card = ns.Card.Create(ns.GlobalName("QuestTracker"))
local previewing = false

-- Nur Clients mit der alten 5er-Grenze (ohne C_QuestLog.GetNumQuestWatches)
function QuestTracker.IsAvailable()
  return GetNumQuestWatches ~= nil and GetQuestIndexForWatch ~= nil
    and not (C_QuestLog and C_QuestLog.GetNumQuestWatches)
end

-- Logindizes, die der Blizzard-Tracker zeigt
local function watchedIndexes()
  local watched = {}
  for slot = 1, (GetNumQuestWatches()) or 0 do watched[GetQuestIndexForWatch(slot)] = true end
  return watched
end

local function questLines(entry)
  local lines = { string.format("[%s] %s", entry.level or "?", entry.title or "?") }
  for _, objective in ipairs(QuestLog.Objectives(entry.questID)) do
    local color = objective.finished and "good" or "muted"
    lines[#lines + 1] = Theme.Hex(color) .. "  " .. (objective.text or "") .. "|r"
  end
  return lines
end

function QuestTracker.Refresh()
  if not ns.db then return end
  local lines = {}
  if previewing then
    lines[1] = L.QUEST_TRACKER_SAMPLE
  elseif ns.db.questTracker and QuestTracker.IsAvailable() then
    local watched = watchedIndexes()
    for _, entry in ipairs(QuestLog.Entries()) do
      if not watched[entry.index] then
        for _, line in ipairs(questLines(entry)) do lines[#lines + 1] = line end
      end
    end
  end
  if #lines == 0 then
    card.frame:Hide()
    return
  end
  card.Set({ color = { Theme.RGB("accent") }, title = L.QUEST_TRACKER_TITLE, body = table.concat(lines, "\n") })
  card.frame:Show()
end

-- Test-Zugriff auf die Karte (frame.title/.body)
function QuestTracker.Card()
  return card
end

ns.Frames.Register({
  id = "questTracker", frame = card.frame, label = "EDIT_FRAME_QUEST_TRACKER", default = DEFAULT_POS,
  settingsPage = "COMFORT_PAGE_QUEST_DISPLAY", clickable = true,
  preview = function(on)
    previewing = on and true or false
    QuestTracker.Refresh()
  end,
  hide = function()
    ns.Set("questTracker", false)
  end,
})

ns.Every(1, QuestTracker.Refresh, function(db) return db.questTracker end)
ns.RegisterApply(QuestTracker.Refresh)

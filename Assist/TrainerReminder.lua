-- Hinweis beim Level-Up, wenn beim Klassenlehrer neue Zauber warten (Einstellung remindTrainer).
-- Classic Era, TBC und WoW Forever: neue Ränge gibt es auf geraden Leveln. Retail lernt Zauber
-- automatisch, dort gibt es weder Hinweis noch Einstellung (TrainerReminder.IsAvailable).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    remindTrainer = false,
  },
})
local L = ns.L

local TrainerReminder = {}
ns.TrainerReminder = TrainerReminder

function TrainerReminder.IsAvailable()
  return not ns.Client.IsRetail()
end

function TrainerReminder.HasNewSpells(level)
  return level % 2 == 0
end

local function notifyTrainer(level)
  ns.Alerts.Notify({ title = L.NOTICE_TRAINER, text = string.format(L.REMIND_TRAINER, level),
    icon = ns.Alerts.ICONS.trainer }, ns.Alerts.REMINDER_COLOR)
end

-- Vorschau (Testen-Knopf): Lehrer-Hinweis für das aktuelle Level, ohne das Level-Up-Fenster
function TrainerReminder.Preview()
  notifyTrainer(ns.level)
end

ns.OnLevelStarted(function(newLevel)
  if not ns.db.remindTrainer or not TrainerReminder.IsAvailable() then return end
  if not TrainerReminder.HasNewSpells(newLevel) then return end
  local text = string.format(L.REMIND_TRAINER, newLevel)
  -- Das Level-Up-Fenster zeigt die neuen Fähigkeiten des Lehrers selbst (sofern bekannt): nur die Chatzeile, kein Popup
  if ns.db.levelUpWindow and #ns.TrainerCache.ForLevel(newLevel) > 0 then
    ns.Print(text)
    return
  end
  notifyTrainer(newLevel)
end)

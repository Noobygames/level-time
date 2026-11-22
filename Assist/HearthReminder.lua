-- Hinweis beim Betreten eines Gasthauses oder einer Hauptstadt (Einstellung remindHearth, LT-410):
-- wo der Ruhestein gerade gebunden ist, falls man ihn umbinden möchte.
-- IsResting() ist genau in Gasthäusern und Hauptstädten wahr, daher braucht es keine Liste der Städte.
-- PLAYER_UPDATE_RESTING (alle Clients) meldet den Wechsel; der Hinweis kommt je Betreten einmal.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    remindHearth = true,
  },
})
local L = ns.L

local HearthReminder = {}
ns.HearthReminder = HearthReminder

function HearthReminder.Notify()
  local location = GetBindLocation and GetBindLocation()
  if ns.IsSecret(location) or not location or location == "" then return end
  ns.Debug("hearth", "bound at %s", location)
  ns.Alerts.Notify({ title = L.NOTICE_HEARTH, text = string.format(L.REMIND_HEARTH, location),
    icon = ns.Alerts.ICONS.hearthstone }, ns.Alerts.REMINDER_COLOR, ns.Alerts.COLLECT)
end

-- Vorschau (Testen-Knopf)
HearthReminder.Preview = HearthReminder.Notify

local wasResting = false
local events = ns.NewEventGroup()
events.Add("PLAYER_UPDATE_RESTING", nil, function()
  local resting = IsResting() and true or false
  if resting and not wasResting then HearthReminder.Notify() end
  wasResting = resting
end)

-- Beim Einloggen im Gasthaus gilt als schon betreten: kein Hinweis, wenn der Spieler nur neu lädt
ns.OnLogin(function() wasResting = IsResting() and true or false end)
ns.RegisterApply(function(db) events.SetActive(db.remindHearth) end)

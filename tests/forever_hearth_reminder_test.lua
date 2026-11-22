-- Ruhestein-Hinweis (LT-410, WoW Forever): einmal je Betreten von Gasthaus/Hauptstadt, wieder nach dem Verlassen.
local notified = { n = 0, text = nil }
local function setResting(value)
  wow.state.resting = value
  wow.fire("PLAYER_UPDATE_RESTING")
end

wow.login()
local realNotify = addon.Alerts.Notify
addon.Alerts.Notify = function(entry, ...)
  if entry.title == addon.L.NOTICE_HEARTH then notified.n = notified.n + 1; notified.text = entry.text end
  return realNotify(entry, ...)
end

expect("Standard an", addon.db.remindHearth, true)
expect("draußen: still", notified.n, 0)

setResting(true)
expect("Gasthaus betreten: ein Hinweis", notified.n, 1)
expect("Text mit Bindeort", notified.text, string.format(addon.L.REMIND_HEARTH, "Orgrimmar"))
wow.fire("PLAYER_UPDATE_RESTING")
expect("kein Wiederholen beim Bleiben", notified.n, 1)

setResting(false)
setResting(true)
expect("erneut betreten: wieder", notified.n, 2)

addon.Set("remindHearth", false)
setResting(false)
setResting(true)
expect("aus: still", notified.n, 2)

-- Testen-Knöpfe auf der Seite Chat & Erinnerungen: jede Ausgabe wie echt, Gruppen-Ansagen und Instanzbericht nur
-- lokal mit Kennzeichnung "Vorschau", nie an Gruppe, Raid oder Chat gesendet.
local L = addon.L

wow.login({ level = 20 })
wow.state.inGroup = true
wow.state.role = "HEALER"
wow.state.instance = { name = "Die Todesminen", type = "party" }

local function printedCount(text)
  local count = 0
  for _, line in ipairs(wow.printed) do
    if line:find(text, 1, true) then count = count + 1 end
  end
  return count
end

-- Karten und Chatzeilen, die Alerts.Notify/Show bekommt
local cards = {}
local notify, show = addon.Alerts.Notify, addon.Alerts.Show
addon.Alerts.Notify = function(notices, color)
  if type(notices) == "string" or notices.text then notices = { notices } end
  for _, entry in ipairs(notices) do cards[#cards + 1] = entry.text or entry end
  return notify(notices, color)
end
addon.Alerts.Show = function(message, ...)
  cards[#cards + 1] = message
  return show(message, ...)
end

SlashCmdList.LEVELTIMER("config")
expectTrue("Reiter Chat & Erinnerungen", wow.click(L.OPTIONS_TAB_NOTIFICATIONS))

-- Login: Session-Vergleich (Beispielwerte), Rekordmeldung, Twink-Hinweis
wow.printed = {}
expectTrue("Login: Knopf", wow.clickOption("NOTIFICATION_TEST_LOGIN"))
expectTrue("Login: drei Ausgaben", #wow.printed >= 3)

-- Erinnerungen und Warnungen: jeder Klick eine Karte, nach dem Durchlauf wieder von vorn
for _, key in ipairs({ "NOTIFICATION_TEST_REMINDERS", "NOTIFICATION_TEST_WARNINGS" }) do
  local clicks, seen = 0, {}
  for _ = 1, 12 do
    cards = {}
    expectTrue(key .. ": Knopf", wow.clickOption(key))
    clicks = clicks + 1
    expectTrue(key .. ": Ausgabe bei Klick " .. clicks, #cards > 0)
    seen[cards[1]] = true
  end
  local distinct = 0
  for _ in pairs(seen) do distinct = distinct + 1 end
  expectTrue(key .. ": mehrere verschiedene Hinweise", distinct >= 3)
end

-- Gruppe: nur lokal, mit Kennzeichnung, nichts gesendet
wow.printed, wow.sentChat = {}, {}
expectTrue("Gruppe: Knopf", wow.clickOption("NOTIFICATION_TEST_GROUP"))
expectTrue("Gruppe: Ansagen gedruckt", printedCount(L.PREVIEW_TAG) >= 6)
expectTrue("Gruppe: Heiler-Aggro", printedCount(L.HEALER_AGGRO_ANNOUNCE) == 1)
expect("Gruppe: nichts gesendet", #wow.sentChat, 0)

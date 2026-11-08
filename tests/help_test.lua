-- Hilfe kurz (Alltagsbefehle) und vollständig (/lt help all), unbekannter Befehl eine Zeile, einmaliger Hinweis beim
-- ersten Start (UX S25, S27).
local L = addon.L
wow.login({ level = 10 })
expectTrue("Hinweis beim ersten Start", wow.printed[#wow.printed]:find(L.INTRO, 1, true) ~= nil)
local count = #wow.printed
wow.logout()
wow.login()
expect("Hinweis nur einmal", #wow.printed, count)

local function linesOf(text)
  local lines = 0
  for _ in text:gmatch("[^\n]+") do lines = lines + 1 end
  return lines
end

local before = #wow.printed
SlashCmdList.LEVELTIMER("help")
expect("kurze Hilfe", #wow.printed - before, linesOf(L.HELP))
expectTrue("kurze Hilfe: höchstens drei Zeilen", linesOf(L.HELP) <= 3)
expectTrue("verweist auf help all", wow.printed[#wow.printed]:find("/lt help all", 1, true) ~= nil)

before = #wow.printed
SlashCmdList.LEVELTIMER("help all")
expect("alle Befehle", #wow.printed - before, linesOf(L.HELP_ALL))

-- Alle Sprachen: debug nur in der langen Hilfe, compact so beschrieben wie die Meldung des Befehls
for _, language in ipairs({ "deDE", "enUS", "frFR", "esES" }) do
  local texts = addon.locales[language]
  expectTrue(language .. ": debug nicht in der kurzen Hilfe", not texts.HELP:find("debug", 1, true))
  expectTrue(language .. ": debug in help all", texts.HELP_ALL:find("debug", 1, true) ~= nil)
  expectTrue(language .. ": compact ohne alte Beschreibung", not texts.HELP_ALL:find("XP/h)", 1, true)
    and not texts.HELP_ALL:find("PX/h)", 1, true))
end

before = #wow.printed
SlashCmdList.LEVELTIMER("quatsch")
expect("unbekannter Befehl: eine Zeile", #wow.printed - before, 1)
expectTrue("nennt den Befehl", wow.printed[#wow.printed]:find(string.format(L.COMMAND_UNKNOWN, "quatsch"), 1, true) ~= nil)

before = #wow.printed
SlashCmdList.LEVELTIMER("runs falsch")
expect("unbekanntes Argument: eine Zeile", #wow.printed - before, 1)
expectTrue("nennt runs", wow.printed[#wow.printed]:find("runs falsch", 1, true) ~= nil)

expect("keine Fehler", #wow.errors, 0)

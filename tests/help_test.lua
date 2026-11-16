-- Hilfe kurz (Alltagsbefehle) und vollständig (/lt help all), unbekannter Befehl eine Zeile, Willkommenskarte statt Chatzeile beim
-- ersten Start (UX S25, S27).
local L = addon.L
wow.login({ level = 10 })
expect("keine Chatzeile beim ersten Start, die Willkommenskarte übernimmt", #wow.printed, 0)
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

-- Alle Sprachen: debug in keiner Hilfe (gehört zum lokalen Data Extractor), compact so beschrieben wie die Meldung des Befehls
for _, language in ipairs({ "deDE", "enUS", "frFR", "esES" }) do
  local texts = addon.locales[language]
  expectTrue(language .. ": debug nicht in der kurzen Hilfe", not texts.HELP:find("debug", 1, true))
  expectTrue(language .. ": debug nicht in help all", not texts.HELP_ALL:find("debug", 1, true))
  expectTrue(language .. ": compact ohne alte Beschreibung", not texts.HELP_ALL:find("XP/h)", 1, true)
    and not texts.HELP_ALL:find("PX/h)", 1, true))
  -- LT-65: runs und changelog in der kurzen Hilfe, eigene Dungeon-Gruppe und alle Befehle in help all
  for _, command in ipairs({ "runs", "changelog" }) do
    expectTrue(language .. ": kurze Hilfe nennt " .. command, texts.HELP:find(command, 1, true) ~= nil)
  end
  for _, command in ipairs({ "runs import", "report", "resetinstance", "transport master", "link", "changelog" }) do
    expectTrue(language .. ": help all nennt " .. command, texts.HELP_ALL:find(command, 1, true) ~= nil)
  end
  local dungeonLine = texts.HELP_ALL:match("\n([^\n]*resetinstance[^\n]*)")
  expectTrue(language .. ": Dungeon-Gruppe mit runs und report",
    dungeonLine ~= nil and dungeonLine:find("runs", 1, true) ~= nil and dungeonLine:find("report", 1, true) ~= nil)
  local speedrunLine = texts.HELP_ALL:match("\n(Speedrun[^\n]*)") or ""
  expectTrue(language .. ": runs nicht mehr unter Speedrun", not speedrunLine:find("runs", 1, true))
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

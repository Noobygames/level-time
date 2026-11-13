-- /lt debug: Logging an/aus und Testbefehle, die nichts an den Statistiken ändern.
local L = addon.L

-- Chatzeile seit index, die alle Textteile enthält (Farbcodes liegen dazwischen)
local function printedSince(index, ...)
  local parts = { ... }
  for i = index + 1, #wow.printed do
    local line, all = wow.printed[i], true
    for _, part in ipairs(parts) do
      if not line:find(part, 1, true) then all = false end
    end
    if all then return true end
  end
  return false
end

wow.login({ level = 10, playedSeconds = 600 })
addon.Set("alertStyle", "text")

-- Logging: nur eingeschaltet
local before = #wow.printed
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
expect("aus: kein Logging", printedSince(before, "[debug]"), false)
SlashCmdList.LEVELTIMER("debug")
before = #wow.printed
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
expectTrue("Zähler geloggt", printedSince(before, "[debug] stats:", "pveKills +1"))
expectTrue("Journal geloggt", printedSince(before, "[debug] journal:", "killLog: Wolf"))
SlashCmdList.LEVELTIMER("debug")

-- Testbefehle verändern keine Daten
local kills = addon.Stats.Get(addon.Stats.LEVEL, addon.Stats.PVE_KILLS)
local journalSize = #addon.character.killLog
local levels = 0
for _ in pairs(addon.character.levelHistory) do levels = levels + 1 end

before = #wow.printed
SlashCmdList.LEVELTIMER("debug state")
expectTrue("Zustand", printedSince(before, "[debug] core:", "Testchar-Testrealm level 10"))

before = #wow.printed
SlashCmdList.LEVELTIMER("debug levelup")
expectTrue("Zusammenfassung des laufenden Levels", printedSince(before, string.format(L.LEVEL_UP_SUMMARY:match("^[^%%]*"), 11)))
expect("Einblendung Level-Up", LevelTimerAlert.text:GetText(), string.format(L.ALERT_LEVEL_UP, 11))

SlashCmdList.LEVELTIMER("debug alert rare")
expect("Einblendung Rare, obwohl aus", LevelTimerAlert.text:GetText(), string.format(L.ALERT_RARE_KILL, "Hogger"))
SlashCmdList.LEVELTIMER("debug alert levelUp")
expect("Einblendung Level-Up per Befehl", LevelTimerAlert.text:GetText(), string.format(L.ALERT_LEVEL_UP, addon.level + 1))
before = #wow.printed
SlashCmdList.LEVELTIMER("debug alert quatsch")
expectTrue("unbekannte Art: Liste", printedSince(before, "kinds: elite, levelUp, loot, nearDeath, questComplete, questObjective, rare, rareSpotted"))

for _, command in ipairs({ "remind", "death", "splits" }) do
  before = #wow.printed
  SlashCmdList.LEVELTIMER("debug " .. command)
  expectTrue("Ausgabe " .. command, #wow.printed > before)
end

before = #wow.printed
SlashCmdList.LEVELTIMER("debug unbekannt")
expectTrue("Hilfe bei unbekanntem Befehl", printedSince(before, extractor.L.DEBUG_HELP))

expect("Kills unverändert", addon.Stats.Get(addon.Stats.LEVEL, addon.Stats.PVE_KILLS), kills)
expect("Journal unverändert", #addon.character.killLog, journalSize)
local levelsAfter = 0
for _ in pairs(addon.character.levelHistory) do levelsAfter = levelsAfter + 1 end
expect("keine Level-Historie geschrieben", levelsAfter, levels)
expect("Level unverändert", addon.level, 10)

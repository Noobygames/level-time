-- Session-Abschlusskarte: Werte der laufenden Session, beste Beute, gefährlichster Gegner.
local L = addon.L
local Journal = addon.Journal
local RecapWindow = addon.RecapWindow

local function row(label)
  for _, line in ipairs(RecapWindow.BuildRows()) do
    if line[1] == label then return line[2] end
  end
end

wow.login({ level = 10, xp = 0, xpMax = 1000 })

-- Beute und Tode aus einer früheren Session zählen nicht
Journal.AddLoot({ link = "[Altes Episches]", quality = 4 })
Journal.AddDeath({ killer = "Alter Feind" })
wow.advance(10)
SlashCmdList.LEVELTIMER("newsession")
wow.advance(1)

expect("ohne Beute", row(L.RECAP_BEST_LOOT), "-")
expect("ohne Gegner", row(L.RECAP_DANGER), "-")

wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
Journal.AddLoot({ link = "[Blauer Ring]", quality = 3 })
Journal.AddLoot({ link = "[Lila Schwert]", quality = 4 })
Journal.AddLoot({ link = "[Grüner Gürtel]", quality = 3 })
Journal.AddDeath({ killer = "Hogger" })
Journal.AddNearDeath(5, { killer = "Hogger" })
Journal.AddNearDeath(8, { killer = "Wolf" })
wow.levelUp(11)
wow.advance(3600)

expect("Charakter", row(L.RECAP_CHARACTER), "Testchar - Testrealm")
expect("Level-Spanne", row(L.RECAP_LEVELS), "10 > 11")
expect("Kills", row(L.RECAP_KILLS), "1")
expect("beste Beute = höchste Qualität", row(L.RECAP_BEST_LOOT), "[Lila Schwert]")
expect("gefährlichster Gegner", row(L.RECAP_DANGER), "Hogger (2)")
expect("Spielzeit", row(L.RECAP_TIME), addon.Format.Duration(3601))
-- Retail kann das Leben nicht verlässlich lesen: keine Zeile "Beinahe-Tode" mit falscher 0 (W10)
expect("Retail: keine Beinahe-Tode-Zeile", row(L.ROW_NEAR_DEATHS), nil)

-- Fenster per Befehl und Button, Datenschutz gilt auch hier
SlashCmdList.LEVELTIMER("recap")
expect("Fenster offen", LevelTimerRecap:IsShown(), true)
addon.Set("streamerPrivacy", true)
expect("ohne Realm", row(L.RECAP_CHARACTER), "Testchar")
SlashCmdList.LEVELTIMER("recap")
expect("Fenster zu", LevelTimerRecap:IsShown(), false)
SlashCmdList.LEVELTIMER("config")
expectTrue("Button in den Einstellungen", wow.click(L.RECAP_TITLE))
expect("Fenster per Button", LevelTimerRecap:IsShown(), true)

-- Roadmap 209: Chroma-Hintergrund wie das Zeitfenster, offene Karte zählt mit
addon.Set("windowBackground", "green")
expect("Chroma-Grün", LevelTimerRecap._backdropColor[2], 1)
expect("Chroma deckend", LevelTimerRecap._backdropColor[4], 1)
addon.Set("windowBackground", "default")
expect("eigener dunkler Hintergrund", LevelTimerRecap._backdropColor[4], 0.95)
local function shownValue(text)
  return wow.findFrame(function(frame) return frame._text == text end) ~= nil
end
local kills = addon.Stats.GetTotalKills(addon.Stats.SESSION)
expectTrue("Kills sichtbar", shownValue(tostring(kills)))
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Eber stirbt, Ihr bekommt 50 Erfahrung.")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Eber stirbt, Ihr bekommt 50 Erfahrung.")
wow.update(1.1)
expectTrue("Kills aktualisiert ohne neu öffnen", shownValue(tostring(kills + 2)))

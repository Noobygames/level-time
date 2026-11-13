-- Roadmap 480: Twink-Knopf im Postfach trägt in WoW Forever Vor- und Nachname ein
local Mail = addon.Mail

SendMailNameEditBox = CreateFrame("EditBox", "SendMailNameEditBox")
MailFrame = CreateFrame("Frame", "MailFrame")
SendMailFrame = CreateFrame("Frame", "SendMailFrame", MailFrame)

wow.login({ name = "Arthas", surname = "Menethil", realm = "Forever" })

expect("Nachname gespeichert", addon.character.surname, "Menethil")
expect("Schlüssel nur mit Vorname", addon.characterKey, "Arthas-Forever")

-- Twink mit Nachname aus früherem Login, Twink ohne Nachname (alte Daten) bleibt beim Vornamen
LevelTimerStatsDB.characters["Jaina-Forever"] = { name = "Jaina", surname = "Prachtmeer", realm = "Forever" }
LevelTimerStatsDB.characters["Uther-Forever"] = { name = "Uther", realm = "Forever" }

local alts = Mail.GetKnownAlts()
expect("zwei Twinks", #alts, 2)
expect("Twink mit Vor- und Nachname", alts[1].name, "Jaina Prachtmeer")
expect("Twink ohne bekannten Nachnamen", alts[2].name, "Uther")

addon.Set("mailAssist", true)
MailFrame:Show()
SendMailFrame:Show()
wow.fire("MAIL_SHOW")
LevelTimerMailAltButton._scripts.OnClick(LevelTimerMailAltButton)
expect("Empfängerfeld mit vollem Namen", SendMailNameEditBox:GetText(), "Jaina Prachtmeer")
expect("keine Lua-Fehler", #wow.errors, 0)

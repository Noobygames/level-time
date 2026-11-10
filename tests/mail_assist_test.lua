-- Tests für Assist/Mail.lua (Roadmap 450: Post-Helfer / Postal Light)
local L = addon.L
local Mail = addon.Mail

-- Setup Vor-Login
SendMailNameEditBox = CreateFrame("EditBox", "SendMailNameEditBox")
MailFrame = CreateFrame("Frame", "MailFrame")
InboxFrame = CreateFrame("Frame", "InboxFrame", MailFrame)
SendMailFrame = CreateFrame("Frame", "SendMailFrame", MailFrame)

wow.login({ name = "MainChar", realm = "Everlook", money = 1000 })

---------------------------------------------------------------------------
-- 1. Standardeinstellung: mailAssist == false
---------------------------------------------------------------------------
expect("Standardeinstellung mailAssist ist false", addon.db.mailAssist, false)
expect("anfangs nicht am Öffnen", Mail.IsOpening(), false)

---------------------------------------------------------------------------
-- 2. Mail.GetKnownAlts()
---------------------------------------------------------------------------
LevelTimerStatsDB.characters = {
  ["MainChar-Everlook"] = { name = "MainChar", realm = "Everlook", class = "WARRIOR" },
  ["Zul-Everlook"] = { name = "Zul", realm = "Everlook", class = "PRIEST" },
  ["Alice-Everlook"] = { name = "Alice", realm = "Everlook", class = "MAGE" },
  ["Bob-Razorfen"] = { name = "Bob", realm = "Razorfen", class = "ROGUE" },
}

local alts = Mail.GetKnownAlts()
expect("genau 2 Twinks auf demselben Realm", #alts, 2)
expect("erster Twink alphabetisch Alice", alts[1].name, "Alice")
expect("erster Twink Klasse MAGE", alts[1].class, "MAGE")
expect("erster Twink Schlüssel Alice-Everlook", alts[1].key, "Alice-Everlook")
expect("zweiter Twink alphabetisch Zul", alts[2].name, "Zul")
expect("zweiter Twink Klasse PRIEST", alts[2].class, "PRIEST")
expect("zweiter Twink Schlüssel Zul-Everlook", alts[2].key, "Zul-Everlook")

---------------------------------------------------------------------------
-- 3. Mail.FillRecipient(name)
---------------------------------------------------------------------------
Mail.FillRecipient("Alice")
expect("SendMailNameEditBox enthält Empfänger", SendMailNameEditBox:GetText(), "Alice")

---------------------------------------------------------------------------
-- 4. Knöpfe und Twink-Durchschalten
---------------------------------------------------------------------------
addon.Set("mailAssist", true)
MailFrame:Show()
InboxFrame:Show()
SendMailFrame:Show()
wow.fire("MAIL_SHOW")

local openAll = LevelTimerMailOpenAllButton
local altBtn = LevelTimerMailAltButton
expectTrue("Open All Knopf existiert", openAll ~= nil)
expectTrue("Open All Knopf ist sichtbar", openAll:IsShown())
expectTrue("Alt Knopf existiert", altBtn ~= nil)
expectTrue("Alt Knopf ist sichtbar", altBtn:IsShown())

-- Twink-Durchschalten per Klick auf LevelTimerMailAltButton
altBtn._scripts.OnClick(altBtn)
expect("erster Klick wählt ersten Twink (Alice)", SendMailNameEditBox:GetText(), "Alice")
altBtn._scripts.OnClick(altBtn)
expect("zweiter Klick wählt zweiten Twink (Zul)", SendMailNameEditBox:GetText(), "Zul")
altBtn._scripts.OnClick(altBtn)
expect("dritter Klick fängt wieder bei erstem Twink an (Alice)", SendMailNameEditBox:GetText(), "Alice")

---------------------------------------------------------------------------
-- 5. Alt-Klick zum Anhängen: Mail.TryAttachBagItem(bag, slot)
---------------------------------------------------------------------------
wow.mailAttached = {}
wow.state.altDown = false
SendMailFrame:Hide()
expect("SendMailFrame versteckt: kein Anhängen", Mail.TryAttachBagItem(0, 1), false)

SendMailFrame:Show()
expect("Alt nicht gedrückt: kein Anhängen", Mail.TryAttachBagItem(0, 1), false)

wow.state.altDown = true
expectTrue("Alt gedrückt und SendMailFrame sichtbar: Anhängen gelingt", Mail.TryAttachBagItem(0, 1))
expect("1 Gegenstand angehängt", #wow.mailAttached, 1)
expect("angehängte Tasche ist 0", wow.mailAttached[1].bag, 0)
expect("angehängter Platz ist 1", wow.mailAttached[1].slot, 1)
wow.state.altDown = false

---------------------------------------------------------------------------
-- 6. Mail.StartOpenAll() / Mail.StepOpenAll()
--    Plündert normale Post, überspringt Nachnahme (COD > 0)
---------------------------------------------------------------------------
wow.state.inbox = {
  { sender = "Hans", subject = "Gold", money = 250, CODAmount = 0, hasItem = 0 },
  { sender = "Betrüger", subject = "Nachnahme", money = 0, CODAmount = 5000, hasItem = 1 },
  { sender = "Gilde", subject = "Tränke", money = 100, CODAmount = 0, hasItem = 1 },
}
wow.state.freeSlots[0] = { 5, 0 }
wow.mailLooted = {}

Mail.StartOpenAll()
expectTrue("Öffnen gestartet", Mail.IsOpening())

-- 1. Schritt: Mail 3 (Gilde) plündern
Mail.StepOpenAll()
expect("1 Mail geplündert", #wow.mailLooted, 1)
expect("Index 3 geplündert", wow.mailLooted[1].index, 3)
expectTrue("weiterhin am Öffnen", Mail.IsOpening())

-- 2. Schritt: Mail 2 (Nachnahme) überspringen, Mail 1 (Hans) plündern
Mail.StepOpenAll()
expect("2 Mails geplündert", #wow.mailLooted, 2)
expect("Index 1 geplündert", wow.mailLooted[2].index, 1)

-- 3. Schritt: keine Mails mehr übrig, beenden
Mail.StepOpenAll()
expect("Öffnen beendet", Mail.IsOpening(), false)
expectTrue("Nachnahme übersprungen im Chat gemeldet",
  wow.printed[#wow.printed]:find(L.MAIL_SKIPPED_COD, 1, true) ~= nil)

---------------------------------------------------------------------------
-- 7. Anhalten bei vollen Taschen
---------------------------------------------------------------------------
wow.state.inbox = {
  { sender = "Loot", subject = "Item", money = 0, CODAmount = 0, hasItem = 1 },
}
wow.state.freeSlots[0] = { 0, 0 }  -- Taschen voll
Mail.StartOpenAll()
expectTrue("Öffnen gestartet mit vollen Taschen", Mail.IsOpening())
Mail.StepOpenAll()
expect("bei vollen Taschen gestoppt", Mail.IsOpening(), false)
expectTrue("Taschen voll im Chat gemeldet",
  wow.printed[#wow.printed]:find(L.MAIL_STOPPED_BAGS_FULL, 1, true) ~= nil)

---------------------------------------------------------------------------
-- 8. UI_ERROR_MESSAGE mit ERR_INV_FULL
---------------------------------------------------------------------------
wow.state.inbox = {
  { sender = "Loot2", subject = "Item2", money = 0, CODAmount = 0, hasItem = 1 },
}
wow.state.freeSlots[0] = { 5, 0 }
Mail.StartOpenAll()
expectTrue("Öffnen gestartet für Fehlertest", Mail.IsOpening())
wow.fire("UI_ERROR_MESSAGE", ERR_INV_FULL)
expect("UI_ERROR_MESSAGE stoppt Öffnen", Mail.IsOpening(), false)
expectTrue("Taschen voll im Chat nach UI_ERROR_MESSAGE",
  wow.printed[#wow.printed]:find(L.MAIL_STOPPED_BAGS_FULL, 1, true) ~= nil)

---------------------------------------------------------------------------
-- 9. MAIL_CLOSED stoppt Öffnen sofort
---------------------------------------------------------------------------
wow.state.inbox = {
  { sender = "Loot3", subject = "Item3", money = 50, CODAmount = 0, hasItem = 0 },
}
Mail.StartOpenAll()
expectTrue("Öffnen gestartet vor Schließen", Mail.IsOpening())
wow.fire("MAIL_CLOSED")
expect("MAIL_CLOSED stoppt Öffnen sofort", Mail.IsOpening(), false)

---------------------------------------------------------------------------
-- 10. Umschalttaste (Shift) verhindert Start über Knopf
---------------------------------------------------------------------------
wow.state.shiftDown = true
openAll._scripts.OnClick(openAll)
expect("Shift verhindert Start über Knopf", Mail.IsOpening(), false)
wow.state.shiftDown = false

---------------------------------------------------------------------------
-- 11. Ausschalten der Option blendet Knöpfe aus
---------------------------------------------------------------------------
addon.Set("mailAssist", false)
expect("Open All Knopf versteckt nach Deaktivierung", openAll:IsShown(), false)
expect("Alt Knopf versteckt nach Deaktivierung", altBtn:IsShown(), false)

expect("keine Lua-Fehler", #wow.errors, 0)

-- Letzter Chat nach /reload: beim Logout gemerkt, beim Login nach kurzer Pause wieder im Fenster;
-- nach langer Pause (echter Login) nicht. Spam-Filter für Betrunken-Meldungen und Zauber-Links im Kampf.
local chat1 = ChatFrame1

wow.login()
addon.Set("restoreChat", true)

chat1._messages = { "alt", "Hallo", wow.SECRET, "|Kq12|k: hi" }
for i = 1, addon.ChatHistory.MAX_LINES do table.insert(chat1._messages, "Zeile " .. i) end
ChatFrame2._messages = { "Kampflog-Zeile" }
wow.logout()
local saved = addon.character.chatHistory
expectTrue("gemerkt", saved ~= nil)
expect("nur die letzten Zeilen", #saved.frames[1], addon.ChatHistory.MAX_LINES)
expect("älteste gemerkte Zeile", saved.frames[1][1][1], "Zeile 1")
expect("Kampflog nicht gemerkt", saved.frames[2], nil)

-- /reload: Fenster leer, nach kurzer Pause wieder da
chat1._messages, ChatFrame2._messages = {}, {}
wow.advance(10)
wow.login()
expect("wiederhergestellt", #chat1._messages, addon.ChatHistory.MAX_LINES)
expect("Reihenfolge", chat1._messages[#chat1._messages], "Zeile " .. addon.ChatHistory.MAX_LINES)
expect("Speicher geleert", addon.character.chatHistory, nil)

-- Geheime und geschützte Zeilen werden nie gemerkt
chat1._messages = { "lesbar", wow.SECRET, "|Kq12|k: hi" }
wow.logout()
expect("nur lesbare Zeile", #addon.character.chatHistory.frames[1], 1)

-- Echter Login nach langer Pause: nichts
chat1._messages = {}
wow.advance(3600)
wow.login()
expect("nach langer Pause nichts", #chat1._messages, 0)

-- Ausgeschaltet: nichts gemerkt
addon.Set("restoreChat", false)
chat1._messages = { "Hallo" }
wow.logout()
expect("aus: nichts gemerkt", addon.character.chatHistory, nil)

---------------------------------------------------------------------------
-- Spam-Filter
---------------------------------------------------------------------------
DRUNK_MESSAGE_OTHER1 = "%s scheint beschwipst zu sein."
DRUNK_MESSAGE_ITEM_OTHER1 = "%s scheint vom Genuss von %s beschwipst zu sein."
local drunk = "Trinker scheint beschwipst zu sein."
local drunkItem = "Trinker scheint vom Genuss von Zwergenbier beschwipst zu sein."
expect("aus: Betrunken-Meldung bleibt", wow.chatFiltered("CHAT_MSG_SYSTEM", drunk), false)
addon.Set("filterDrunkSpam", true)
expect("Betrunken-Meldung weg", wow.chatFiltered("CHAT_MSG_SYSTEM", drunk), true)
expect("mit Getränk weg", wow.chatFiltered("CHAT_MSG_SYSTEM", drunkItem), true)
expect("andere Systemmeldung bleibt", wow.chatFiltered("CHAT_MSG_SYSTEM", "Ihr seid jetzt AFK."), false)
expect("geheime Meldung bleibt", wow.chatFiltered("CHAT_MSG_SYSTEM", wow.SECRET), false)

local spellLink = "Unterbrochen: |cff71d5ff|Hspell:2139:0|h[Gegenzauber]|h|r"
addon.Set("filterSpellLinks", true)
expect("außerhalb des Kampfs bleibt", wow.chatFiltered("CHAT_MSG_SAY", spellLink, "Magier-Realm"), false)
wow.state.inCombat = true
expect("im Kampf weg", wow.chatFiltered("CHAT_MSG_PARTY", spellLink, "Magier-Realm"), true)
expect("eigene bleibt", wow.chatFiltered("CHAT_MSG_PARTY", spellLink, wow.state.name .. "-Testrealm"), false)
expect("ohne Link bleibt", wow.chatFiltered("CHAT_MSG_PARTY", "Achtung, Pull!", "Magier-Realm"), false)
addon.Set("filterSpellLinks", false)
expect("aus: bleibt", wow.chatFiltered("CHAT_MSG_PARTY", spellLink, "Magier-Realm"), false)
wow.state.inCombat = false
expect("keine Fehler", #wow.errors, 0)

-- Infokarten (infoCards): Taste zeigt Name, Art, ID und Wowhead-Link aus dem Tooltip oder der Maus-Einheit
local L = addon.L
local shown = {}
local displayed = {}
TooltipUtil = {
  GetDisplayedItem = function() return displayed.itemName, displayed.itemLink, displayed.itemId end,
  GetDisplayedSpell = function() return displayed.spellName, displayed.spellId end,
  GetDisplayedUnit = function() return displayed.unitName, displayed.unit, displayed.guid end,
}

wow.login()
addon.Export.Show = function(heading, text) table.insert(shown, { heading = heading, text = text }) end

LevelTimer_InfoCard()
expect("aus: Hinweis", wow.printed[#wow.printed]:find(L.INFO_CARD_OFF, 1, true) ~= nil, true)
expect("aus: kein Fenster", #shown, 0)

addon.Set("infoCards", true)
GameTooltip:Show()
displayed.itemName, displayed.itemLink, displayed.itemId = "Leinenstoff", "|Hitem:2589::|h[Leinenstoff]|h", nil
LevelTimer_InfoCard()
expect("Titel", shown[1].heading, L.INFO_CARD_TITLE)
expectTrue("Gegenstands-ID aus dem Link", shown[1].text:find("https://www.wowhead.com/item=2589", 1, true) ~= nil)

displayed = { spellName = "Feuerball", spellId = 133 }
LevelTimer_InfoCard()
expectTrue("Zauber", shown[2].text:find("spell=133", 1, true) ~= nil)

displayed = { unitName = "Hogger", unit = "mouseover", guid = "Creature-0-1-0-12-448-0000ABCD" }
LevelTimer_InfoCard()
expectTrue("NPC-ID aus der GUID", shown[3].text:find("npc=448", 1, true) ~= nil)
expect("Spieler-GUID: keine NPC-ID", addon.InfoCard.NpcId("Player-1-0002"), nil)

displayed = { itemName = wow.SECRET, itemLink = wow.SECRET }
GameTooltip:Hide()
wow.state.units.mouseover = { name = "Fremder", guid = wow.SECRET }
LevelTimer_InfoCard()
expect("nichts Lesbares: kein Fenster", #shown, 3)
-- Ohne Tooltip: Maus-Einheit
wow.state.units.mouseover = { name = "Wolf", guid = "Creature-0-1-0-12-299-0000ABCD" }
LevelTimer_InfoCard()
expectTrue("Maus-Einheit", shown[4].text:find("npc=299", 1, true) ~= nil)

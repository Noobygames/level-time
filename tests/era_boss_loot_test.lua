-- LT-35: Boss-Beute-Vorschau in Classic Era: sortierte Drops je Boss und Instanz, Tooltip der Bosszeile im
-- Run-Fenster mit Links, Platzhalter für nicht geladene Items, Nachladen, unbekannte Items fallen weg, Einstellung aus;
-- LT-42: Symbol-Links mit Item-Tooltip in Bosszeile und Live-Karte, mehrere Wartende je ladendem Item
local BossLoot = addon.BossLoot
local L = addon.L

expectTrue("Beutedaten in Classic Era", BossLoot.IsAvailable())
local DEADMINES = { name = "Die Todesminen", type = "party", difficulty = 1, mapID = 36, maxPlayers = 5 }

-- Sortierung: höhere Qualität zuerst, dann bekannte Chance
local loot = addon.DungeonDB.loot
loot[990001] = { { 100, 3 }, { 101, 4, 5 }, { 102, 4, 20 }, { 103, 5 } }
local ids = {}
for index, drop in ipairs(BossLoot.Items(990001)) do ids[index] = drop[1] end
expect("legendär, episch nach Chance, rar", table.concat(ids, ","), "103,102,101,100")
expectTrue("Instanzbeute der Todesminen", #BossLoot.ForInstance(36) > 0)

-- Forever-eigene Items (ab 200000) kennt der Classic-Client nicht
wow.state.unknownItems = setmetatable({}, { __index = function(_, itemID) return itemID > 200000 end })
wow.state.itemLinks = { [5191] = "|cff0070dd[Cruel Barb]|r" }

wow.login({ level = 20, xp = 0, xpMax = 100000 })
-- Symbole (C_Item.GetItemIconByID) für alle Items, nach dem Login (setzt den Zustand neu)
wow.state.itemIcons = setmetatable({}, { __index = function(_, itemID) return 1000 + itemID end })
wow.state.instance = DEADMINES
wow.fire("PLAYER_ENTERING_WORLD")
wow.fire("PLAYER_STARTED_MOVING")
wow.advance(60)

-- LT-42: Live-Karte zeigt die Beute-Symbole des nächsten lebenden Bosses (Rhahk'Zor hat in den Daten vor allem
-- Forever-Items, deshalb hier alle Items bekannt), nicht die von Edwin
local unknownItems = wow.state.unknownItems
wow.state.unknownItems = {}
addon.InstanceRunTracker.Refresh()
local cardText = addon.InstanceRunTracker.Card().frame.body:GetText() or ""
expectTrue("Symbol-Links auf der Live-Karte", cardText:find("|Hitem:%d+|h|T%d+:16|t|h") ~= nil)
expectTrue("nicht Edwins Beute", not cardText:find("|Hitem:5191|h", 1, true))
wow.state.unknownItems = unknownItems
wow.fire("ENCOUNTER_END", 2747, "Edwin van Cleef", 1, 5, 1)
SlashCmdList.LEVELTIMER("runs")
local parts = addon.InstanceRunWindow.Parts()
local edwin
for _, row in ipairs(parts.bossRows) do
  if row.npcID == 639 then edwin = row end
end
expectTrue("Bosszeile für Edwin van Cleef (NPC 639)", edwin ~= nil)

-- Überfahren: Name, Überschrift, Link, Platzhalter für die übrigen drei Classic-Items, keine Forever-Items
edwin:GetScript("OnEnter")(edwin)
local lines = GameTooltip._lines
expect("Überschrift", lines[2], L.BOSS_LOOT_TITLE)
expect("Link des geladenen Items", lines[3], "|cff0070dd[Cruel Barb]|r")
expectTrue("Platzhalter für nicht geladene Items", lines[4]:find(L.BOSS_LOOT_LOADING, 1, true) ~= nil)
expect("nur die vier Classic-Items", #lines, 6)
expectTrue("Ladeauftrag für Item 5193", wow.state.itemLoads[5193] ~= nil)

-- Nachgeladen: der Tooltip baut sich mit dem Link neu auf
wow.state.itemLinks[5193] = "|cff0070dd[Smelting Pants]|r"
wow.state.itemLoads[5193]()
expect("Link nach dem Laden", GameTooltip._lines[4], "|cff0070dd[Smelting Pants]|r")

-- Mehr als MAX_LINES Drops: "+X weitere"
wow.state.unknownItems = {}
edwin:GetScript("OnEnter")(edwin)
local total = #BossLoot.Items(639)
expect("Überlaufzeile", GameTooltip._lines[#GameTooltip._lines],
  string.format(L.BOSS_LOOT_MORE, total - BossLoot.MAX_LINES))

-- LT-42: Beute-Symbole der Bosszeile sind Item-Links mit eigenem Tooltip, danach wieder der Zeilen-Tooltip
expectTrue("Symbol-Link in der Bosszeile", (edwin.loot:GetText() or ""):find("|Hitem:5191|h|T6191:16|t|h", 1, true) ~= nil)
expectTrue("keine Forever-Items als Symbol", not (edwin.loot:GetText() or ""):find("|Hitem:2%d%d%d%d%d|h"))
edwin:GetScript("OnHyperlinkEnter")(edwin, "item:5191")
expect("Item-Tooltip beim Überfahren", GameTooltip._hyperlink, "item:5191")
edwin:GetScript("OnHyperlinkLeave")(edwin)

-- LT-42: zwei Wartende auf dasselbe ladende Item: beide bauen nach dem Laden neu auf, derselbe nur einmal
wow.state.itemLinks = {}
local waits = { a = 0, b = 0 }
local waitDrops = { { 5193, 3 } }
local function waitA() waits.a = waits.a + 1 end
BossLoot.AddLines(GameTooltip, waitDrops, waitA)
BossLoot.AddLines(GameTooltip, waitDrops, waitA)
BossLoot.AddLines(GameTooltip, waitDrops, function() waits.b = waits.b + 1 end)
wow.state.itemLoads[5193]()
expect("erster Wartender einmal", waits.a, 1)
expect("zweiter Wartender", waits.b, 1)

-- Einstellung aus: kein Tooltip-Inhalt, keine Symbole
addon.Set("bossLoot", false)
expect("aus: keine Zeilen", BossLoot.AddLines(GameTooltip, BossLoot.Items(639)), false)
expect("aus: keine Symbole", BossLoot.IconLinks(BossLoot.Items(639), 16), nil)
expect("keine Lua-Fehler", #wow.errors, 0)

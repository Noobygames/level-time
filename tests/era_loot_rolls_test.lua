-- Würfeln um Beute in Classic Era über den Chat (Roadmap 364): jede Wahl, eigene und fremde Zeilen, gleiche
-- Gegenstände mehrfach, Abbruch, alle gepasst, Gewinnerzeile; Zähler am Blizzard-Fenster, Ersatzkarte, Tooltip,
-- Chatzeile und Journal-Felder.
local LootRolls = addon.LootRolls
local Display = addon.LootRollDisplay

local function link(id, color, name)
  return "|cff" .. color .. "|Hitem:" .. id .. "::::::::20:::::|h[" .. name .. "]|h|r"
end
local BELT = link(1234, "0070dd", "Gurt des Bären")   -- selten: landet im Beute-Journal
local RING = link(5678, "1eff00", "Ring der Wildnis")
local CLOAK = link(4321, "0070dd", "Umhang des Fuchses")

local function line(id, rest) return "|HlootHistory:" .. id .. "|h[Beute]|h: " .. rest end
local function chat(text) wow.fire("CHAT_MSG_LOOT", text) end
local function printedWith(text)
  for _, printed in ipairs(wow.printed) do
    if printed:find(text, 1, true) then return printed end
  end
end

wow.login({ inGroup = true, groupSize = 5, units = {
  party1 = { name = "Grimbar", class = "MAGE", isPlayer = true },
  party2 = { name = "Lyra", class = "WARRIOR", isPlayer = true },
  party3 = { name = "Tok", isPlayer = true },
  party4 = { name = "Vex", isPlayer = true },
} })
wow.state.lootRolls = {
  [1] = { link = BELT, name = "Gurt des Bären" },
  [2] = { link = BELT, name = "Gurt des Bären" },
  [3] = { link = RING, name = "Ring der Wildnis" },
  [4] = { link = CLOAK, name = "Umhang des Fuchses" },
}

-- Alles aus (auch die Wurf-Historie, Standard an): keine Events, keine Würfe
addon.Set("lootRollHistory", false)
wow.fire("START_LOOT_ROLL", 1, 60000)
expect("aus: kein Wurf", LootRolls.Get(1), nil)

for _, key in ipairs({ "lootRollCounts", "lootRollNames", "lootRollSummary", "lootRollJournal" }) do
  addon.db[key] = true
end
addon.ApplySettings()

wow.fire("START_LOOT_ROLL", 1, 60000)
wow.fire("START_LOOT_ROLL", 2, 60000)
local first, second = LootRolls.Get(1), LootRolls.Get(2)
expectTrue("zwei Würfe", first ~= nil and second ~= nil)
expect("Gegenstand aus dem Link", first.name, "Gurt des Bären")
expect("vor jeder Wahl warten alle", LootRolls.Counts(first).waiting, 5)

-- Gleicher Gegenstand zweimal: die Link-Nummer ordnet zu, sonst der älteste Wurf ohne Wahl dieses Spielers
chat(line(11, "Grimbar hat für " .. BELT .. " Bedarf ausgewählt"))
chat(line(12, "Grimbar hat für " .. BELT .. " Gier ausgewählt"))
expect("erste Zeile beim ersten Wurf", first.choices.Grimbar, "need")
expect("zweite Nummer beim zweiten Wurf", second.choices.Grimbar, "greed")
expect("Nummer gemerkt", first.historyId, 11)
chat(line(11, "Ihr habt für " .. BELT .. " Bedarf ausgewählt"))
expect("eigene Wahl", first.choices.Testchar, "need")
chat(line(11, "Tok passt auf: " .. BELT))
chat(line(11, "Vex passt automatisch auf " .. BELT .. ", weil er den Gegenstand nicht benutzen kann."))
expect("passen", first.choices.Tok, "pass")
expect("automatisch passen", first.choices.Vex, "pass")
-- Entzaubern hat im Classic-Format keine Nummer: ältester Wurf ohne Lyras Wahl, dann der nächste
chat("Lyra hat für '" .. BELT .. "' Entzauberung gewählt.")
chat("Lyra hat für '" .. BELT .. "' Entzauberung gewählt.")
expect("Entzaubern beim ersten", first.choices.Lyra, "disenchant")
expect("Entzaubern beim zweiten", second.choices.Lyra, "disenchant")

local counts = LootRolls.Counts(first)
expect("Bedarf 2", counts.need, 2)
expect("Passen 2", counts.pass, 2)
expect("Entzaubern 1", counts.disenchant, 1)
expect("keiner wartet", counts.waiting, 0)
expect("zweiter Wurf wartet auf 3", LootRolls.Counts(second).waiting, 3)
expect("Namen je Wahl", table.concat(LootRolls.NamesOf(first, "pass"), ","), "Tok,Vex")
expect("wartende Namen aus der Gruppe", table.concat(LootRolls.NamesOf(second, "waiting"), ","), "Testchar,Tok,Vex")
expectTrue("Zählerzeile mit Symbolen",
  Display.CountsLine(first):find("UI-GroupLoot-Dice-Up:14:14|t 2", 1, true) ~= nil)
expectTrue("Sanduhr in der Zeile", Display.CountsLine(second):find("mini-hourglass:14:14|t 3", 1, true) ~= nil)

-- Zähler unter Blizzards Fenster; Ersatzkarte nur für Würfe ohne sichtbares Fenster
GroupLootFrame1.rollID = 2
GroupLootFrame1:Show()
local row = Display.RowOf(GroupLootFrame1)
expectTrue("Zeile am Fenster", row ~= nil and row:IsShown())
expect("Gier-Zähler", row.cells.greed.text:GetText(), "1")
expect("Wartend-Zähler", row.cells.waiting.text:GetText(), "3")
expect("Entzaubern sichtbar, weil gewählt", row.cells.disenchant:IsShown(), true)
expect("Transmog ausgeblendet", row.cells.transmog:IsShown(), false)
expect("Karte: Wurf 1 ohne Fenster", LevelTimerLootRolls:IsShown(), true)
expectTrue("Karte nennt den Gegenstand", LevelTimerLootRolls.body:GetText():find("Gurt des Bären", 1, true) ~= nil)
GroupLootFrame2.rollID = 1
GroupLootFrame2:Show()
expect("Karte weg, beide Fenster sichtbar", LevelTimerLootRolls:IsShown(), false)

-- Tooltip: Namen in Klassenfarbe
row.cells.greed._scripts.OnEnter(row.cells.greed)
expect("Tooltip-Titel", GameTooltip:GetText(), "Gier: 1")
expect("Name in Klassenfarbe", (GameTooltip._lines or {})[1], "|cff3fc6eaGrimbar|r")

-- Würfe und Gewinner: Chatzeile mit Ergebnis
chat(line(11, "Wurf für Bedarf: 87 für " .. BELT .. " von Grimbar"))
chat(line(11, "Ihr habt Bedarf - 42 gewürfelt auf: " .. BELT))
expect("Wurf gemerkt", first.rolls.Grimbar, 87)
expect("eigener Wurf", first.rolls.Testchar, 42)
chat(line(11, "Grimbar hat gewonnen: " .. BELT .. " |cff818181(Bedarf - 87)|r"))
expect("fertig: vergessen", LootRolls.Get(1), nil)
expect("Gewinner", first.winner, "Grimbar")
expectTrue("Chatzeile", printedWith("gewinnt mit 87 (Bedarf). Bedarf 2, Entzauberung 1, Passen 2") ~= nil)
expect("Zeile am ersten Fenster weg", Display.RowOf(GroupLootFrame2):IsShown(), false)
expect("Ergebnis auf der Karte", LevelTimerLootRolls:IsShown(), true)
expectTrue("Gewinner auf der Karte", LevelTimerLootRolls.body:GetText():find("gewinnt mit 87", 1, true) ~= nil)

-- Abbruch (eigene Wahl getroffen): Blizzards Fenster ist zu, der Wurf läuft weiter und bleibt auf der Karte, bis
-- der Gewinner feststeht oder die Würfelzeit lange abgelaufen ist
wow.fire("START_LOOT_ROLL", 3, 60000)
expect("Karte für den Ring", LevelTimerLootRolls:IsShown(), true)
expectTrue("Links im Text mit Tooltip", LevelTimerLootRolls:GetScript("OnHyperlinkEnter") ~= nil)
wow.fire("CANCEL_LOOT_ROLL", 3)
expect("nach eigener Wahl bleibt die Karte", LevelTimerLootRolls:IsShown(), true)
wow.advance(60 + 31)
wow.update(1)
expect("ohne Ergebnis nach Ablauf weg", LevelTimerLootRolls:IsShown(), false)
expectTrue("Wurf wartet aufs Ergebnis", LootRolls.Get(3) ~= nil and LootRolls.Get(3).closed)
chat(line(13, "Alle haben gepasst auf: " .. RING))
expect("alle gepasst", LootRolls.Get(3), nil)
expectTrue("Chatzeile alle gepasst", printedWith("Ring der Wildnis]|h|r: alle haben gepasst.") ~= nil)

-- Selbst gewonnen: Gewinnerzeile vor der Beute
chat(line(12, "Ihr habt für " .. BELT .. " Gier ausgewählt"))
chat(line(12, "Ihr gewinnt: " .. BELT))
chat("Ihr erhaltet Beute: " .. BELT .. ".")
local loot = addon.character.lootLog
local entry = loot[#loot]
expect("Beute-Eintrag", entry.name, "Gurt des Bären")
expect("Wahl im Journal", entry.rollChoice, "greed")
expect("Gier im Journal", entry.rollGreed, 2)
expect("Entzaubern im Journal", entry.rollDisenchant, 1)
expect("Bedarf im Journal", entry.rollNeed, 0)

-- Beute vor der Gewinnerzeile (Retail-Reihenfolge)
wow.fire("START_LOOT_ROLL", 4, 60000)
chat(line(14, "Ihr habt für " .. CLOAK .. " Bedarf ausgewählt"))
chat("Ihr erhaltet Beute: " .. CLOAK .. ".")
chat(line(14, "Ihr habt gewonnen: " .. CLOAK .. " |cff818181(Bedarf - 64)|r"))
entry = loot[#loot]
expect("Umhang im Journal", entry.name, "Umhang des Fuchses")
expect("Wurf nachgetragen", entry.roll, 64)
expect("Wahl nachgetragen", entry.rollChoice, "need")

-- Historie > Beute zeigt den Wurf
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Beute", wow.click("Beute"))

-- Ergebnis des letzten Wurfs steht 10 s auf der Karte, danach ist sie leer
wow.advance(11)
wow.update(1)
expect("Ergebnis ausgeblendet", LevelTimerLootRolls:IsShown(), false)

-- Edit-Modus: Karte mit Beispielwürfen, danach wieder weg; Position und Größe über Lib/Frames.lua
expect("Karte angemeldet", addon.Frames.Get("lootRolls") ~= nil, true)
addon.EditMode.Enter()
expect("Beispielkarte im Edit-Modus", LevelTimerLootRolls:IsShown(), true)
expectTrue("Beispielwurf", LevelTimerLootRolls.body:GetText():find(addon.L.LOOT_ROLL_SAMPLE_ITEM_1, 1, true) ~= nil)
addon.EditMode.Leave()
expect("nach dem Edit-Modus weg", LevelTimerLootRolls:IsShown(), false)

-- Ausschalten vergisst alles
for _, key in ipairs({ "lootRollCounts", "lootRollNames", "lootRollSummary", "lootRollJournal" }) do
  addon.db[key] = false
end
addon.ApplySettings()
expect("aus: keine Würfe", #LootRolls.All(), 0)
expect("keine Lua-Fehler", #wow.errors, 0)

-- Würfelkarte: Symbol im Link-Text (Drüberfahren am Symbol zeigt den Tooltip), ohne Link Symbol + Name
local Display2 = addon.LootRollDisplay
expect("Symbol im Link", Display2.ItemText({ texture = 133001, link = "|cff1eff00|Hitem:5:0|h[Helm]|h|r" }),
  "|cff1eff00|Hitem:5:0|h|T133001:0|t[Helm]|h|r")
expect("ohne Link Symbol vor dem Namen", Display2.ItemText({ texture = 133001, name = "Helm" }), "|T133001:0|tHelm")
expect("ohne Symbol unverändert", Display2.ItemText({ link = "|Hitem:5|h[Helm]|h" }), "|Hitem:5|h[Helm]|h")

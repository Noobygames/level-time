-- Questgegner und Quest-Gegenstände lernen (Roadmap 341): Anstieg eines Ziels kurz nach Kill bzw. Beute, accountweit,
-- ab zwei Treffern; Classic Era ohne UnitIsRelatedToActiveQuest markiert dann gelernte Gegner und zeigt eine
-- Tooltipzeile.
local L = addon.L
local QuestMobs = addon.QuestMobs

local wolves = { text = "Wolf getötet: 0/8", finished = false, type = "monster" }
local pelts = { text = "Wolfspelz: 0/4", finished = false, type = "item" }
wow.state.questLog = {
  { title = "Wald von Elwynn", isHeader = true },
  { questID = 50, title = "Wölfe jagen", objectives = { wolves, pelts } },
}

local function questLogChanged()
  wow.fire("QUEST_LOG_UPDATE")
  wow.update(0.6)       -- QuestWatch liest ein
  wow.advance(1.1)
  wow.update(0.6)       -- QuestMobs ordnet zu
end
local function kill(name)
  wow.fire("CHAT_MSG_COMBAT_XP_GAIN", name .. " stirbt, Ihr bekommt 40 Erfahrung.")
end
local function loot(itemID, name)
  wow.fire("CHAT_MSG_LOOT", string.format(LOOT_ITEM_SELF, "|cffffffff|Hitem:" .. itemID .. "::::|h[" .. name .. "]|h|r"))
end

wow.login({ level = 10 })
expect("Classic: kein UnitIsRelatedToActiveQuest", addon.QuestMarks.HasClientQuestUnits(), false)

-- Aus: nichts gelernt
questLogChanged()
kill("Wolf")
wolves.text = "Wolf getötet: 1/8"
questLogChanged()
expect("aus: nichts", LevelTimerStatsDB.questMobs, nil)

addon.Set("questLearning", true)
questLogChanged()  -- erster Durchlauf: nur Stand
kill("Wolf")
wolves.text = "Wolf getötet: 2/8"
questLogChanged()
expect("ein Treffer", LevelTimerStatsDB.questMobs[50][1].mobs.Wolf, 1)
expect("einmal reicht nicht", QuestMobs.IsQuestMob("Wolf"), false)

-- Questlog-Änderung vor der Kill-Meldung zählt auch
wolves.text = "Wolf getötet: 3/8"
wow.fire("QUEST_LOG_UPDATE")
wow.update(0.6)
kill("Wolf")
wow.advance(1.1)
wow.update(0.6)
expect("zwei Treffer", LevelTimerStatsDB.questMobs[50][1].mobs.Wolf, 2)
expectTrue("gelernt", QuestMobs.IsQuestMob("Wolf"))
expect("Stand aus dem Log", (QuestMobs.ProgressOf("Wolf")), "3/8")

-- Kill weit vor dem Anstieg: kein Treffer
kill("Kobold")
wow.advance(10)
wolves.text = "Wolf getötet: 4/8"
questLogChanged()
expect("alter Kill zählt nicht", LevelTimerStatsDB.questMobs[50][1].mobs.Kobold, nil)

-- Grauer Gegner ohne XP: totes Ziel
wow.state.units.target = { name = "Junger Wolf", dead = true }
wolves.text = "Wolf getötet: 5/8"
questLogChanged()
expect("totes Ziel", LevelTimerStatsDB.questMobs[50][1].mobs["Junger Wolf"], 1)
wow.state.units.target = nil

-- Sammelziel: Beute mit Quelle (letzter Kill)
for count = 1, 2 do
  kill("Waldwolf")
  loot(7000, "Wolfspelz")
  pelts.text = "Wolfspelz: " .. count .. "/4"
  questLogChanged()
end
local data = LevelTimerStatsDB.questMobs[50][2]
expect("Gegenstand gelernt", data.items[7000], 2)
expect("Name des Gegenstands", data.itemNames[7000], "Wolfspelz")
expect("Quelle gelernt", data.mobs.Waldwolf, 2)
expect("Gegenstand offen", QuestMobs.ForItem(7000)[1].questID, 50)
expect("Gegenstände der Quest", QuestMobs.ItemsOf(50)[7000], "Wolfspelz")

-- Markierung ohne Client-Unterstützung: gelernte, lebende Nicht-Spieler
local plate = CreateFrame("Frame")
C_NamePlate = { GetNamePlateForUnit = function(unit) return unit == "nameplate1" and plate or nil end }
local created
local realCreate = CreateFrame
CreateFrame = function(kind, name, parent)
  local frame = realCreate(kind, name, parent)
  if parent == plate then created = frame end
  return frame
end
wow.state.units.nameplate1 = { name = "Wolf" }
addon.Set("questMarks", true)
addon.Set("questMarkProgress", true)
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
expectTrue("gelernter Gegner markiert", created ~= nil and created:IsShown())
expect("Stand aus dem Questlog", created.progress:GetText(), "5/8")

-- Tooltipzeile (Classic ohne Questzeilen im Tooltip)
expect("Tooltipzeile", addon.Tooltip.LearnedQuestLine("nameplate1"), string.format(L.TOOLTIP_QUEST_LINE, "Wölfe jagen (5/8)"))

-- Zielknopf ohne Client-Unterstützung: gelernte Namen (Roadmap 342)
addon.Set("questTargetButton", true)
expect("Zielknopf mit gelernten Namen", LevelTimerQuestTargetButton:GetAttribute("macrotext"),
  "/cleartarget\n/targetexact Waldwolf\n/targetexact Wolf")

-- Ziel erfüllt: nicht mehr offen
wolves.text, wolves.finished = "Wolf getötet: 8/8", true
questLogChanged()
expect("erfüllt: kein Questgegner", QuestMobs.IsQuestMob("Wolf"), false)
wow.update(5)
expect("erfüllt: Markierung weg", created:IsShown(), false)
wow.update(1)
expect("erfülltes Ziel fällt aus dem Zielknopf", LevelTimerQuestTargetButton:GetAttribute("macrotext"),
  "/cleartarget\n/targetexact Waldwolf")
expect("Fehler?", #wow.errors, 0)

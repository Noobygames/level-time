-- Dungeonquests hervorheben (WoW Forever, DungeonDB): Kurzname der Instanz in Questlog, Gespräch und Gruß, Zeile
-- "Dungeon: Name" im Quest-Tooltip (Chat-Link und Forever-Questlog). Todesminen (36): 167/168 von NPC 656.
local L = addon.L
local Tags = addon.DungeonQuestTags

function GetRealZoneText(mapID) return mapID == 36 and "Die Todesminen" or ("Instanz " .. tostring(mapID)) end
wow.state.questTitles[167] = "Die Bruderschaft"
wow.state.questTitles[168] = "Gesammelte Erinnerungen"

-- Blizzard-Rahmen wie im Client vor dem Login
GossipAvailableQuestButtonMixin = { Setup = function(self, info) self:SetText(info.title) end }
GossipActiveQuestButtonMixin = { Setup = function(self, info) self:SetText(info.title) end }
QuestFrameGreetingPanel = CreateFrame("Frame")
MAX_NUM_QUESTS = 1
local greetAvailable = CreateFrame("Button", "QuestTitleButton1")
greetAvailable.GetID = function() return 1 end
function QuestFrameGreetingPanel_OnShow() greetAvailable:SetText("Gesammelte Erinnerungen"); greetAvailable.isActive = 0 end
function QuestMapLogTitleButton_OnEnter(button) GameTooltip:SetOwner(button) end
function GameTooltip:SetHyperlink() self._lines = {} end
-- Forever-Tracker (Blizzard_ObjectiveTracker): UpdateSingle setzt die Kopfzeile mit Level und Typ; LayoutContents
-- ruft self.UpdateSingle über das Rahmenfeld
local trackerBlock = { HeaderText = CreateFrame("Frame") }
QuestObjectiveTracker = {
  GetExistingBlock = function(_, questID) return questID == 167 and trackerBlock or nil end,
  UpdateSingle = function(_, quest) trackerBlock.HeaderText:SetText("[20] " .. quest.title) return true end,
  LayoutContents = function(self) return self.UpdateSingle(self, { title = "Die Bruderschaft", GetID = function() return 167 end }) end,
}

wow.state.questLog = { { questID = 167, title = "Die Bruderschaft", level = 20, objectives = {} } }
wow.login({ level = 20 })
wow.fire("QUEST_LOG_UPDATE")

expectTrue("Forever: verfügbar", Tags.IsAvailable())
expect("Standard an", addon.db.dungeonQuestTags, true)
local tag = Tags.Tag(167)
expectTrue("Kurzname im Tag", tag:find("[DT]", 1, true) ~= nil)
expect("keine Dungeonquest", Tags.Tag(61), nil)

-- Gespräch: Kurzname angehängt, nicht doppelt
local gossip = CreateFrame("Button")
gossip.Setup = GossipAvailableQuestButtonMixin.Setup
gossip:Setup({ title = "Gesammelte Erinnerungen", questLevel = 18, questID = 168 })
expect("Gespräch", gossip:GetText(), "Gesammelte Erinnerungen " .. tag)
expect("nur einmal", Tags.Decorate(gossip:GetText(), { questID = 168 }), nil)
local plain = CreateFrame("Button")
plain.Setup = GossipAvailableQuestButtonMixin.Setup
plain:Setup({ title = "Briefe", questLevel = 4, questID = 61 })
expect("andere Quest unverändert", plain:GetText(), "Briefe")

-- Mit Questlevel: "[18] Titel [DT]"
addon.Set("questLevels", true)
gossip:Setup({ title = "Gesammelte Erinnerungen", questLevel = 18, questID = 168 })
expect("mit Questlevel", gossip:GetText(), "[18] Gesammelte Erinnerungen " .. tag)
addon.Set("questLevels", false)

-- Gruß: Zuordnung über den Titel unter den Quests des Gesprächspartners
wow.state.units.npc = { name = "Wilder Klippenschmied", guid = "Creature-0-1-0-0-656-0001" }
QuestFrameGreetingPanel_OnShow()
expect("Gruß", greetAvailable:GetText(), "Gesammelte Erinnerungen " .. tag)

-- Forever-Tracker: Kurzname angehängt, kein zweites Level (Blizzard zeigt es schon)
addon.Set("questLevels", true)
expect("Tracker-Rückgabe bleibt", QuestObjectiveTracker:LayoutContents(), true)
expect("Tracker", trackerBlock.HeaderText:GetText(), "[20] Die Bruderschaft " .. tag)
addon.Set("questLevels", false)

-- Tooltip: Chat-Link
GameTooltip:SetHyperlink("quest:167:20")
expect("Link-Tooltip", GameTooltip._lines[1], string.format(L.DUNGEON_QUEST_LINE, "Die Todesminen"))
GameTooltip:SetHyperlink("quest:61:20")
expect("Link ohne Dungeonquest", #GameTooltip._lines, 0)

-- Tooltip: Forever-Questlog
QuestMapLogTitleButton_OnEnter({ info = { questID = 167 } })
expect("Questlog-Tooltip", GameTooltip._lines[1], string.format(L.DUNGEON_QUEST_LINE, "Die Todesminen"))

-- Quest mit mehreren Zielinstanzen (Paladin 1806: Burg Schattenfang, Todesminen, Tiefschwarze Grotte): alle genannt
expect("drei Instanzen", table.concat(addon.DungeonQuests.Instances(1806), ","), "33,36,48")
local _, slashes = Tags.Tag(1806):gsub("/", "")
expect("Kurzname mit allen Instanzen", slashes, 2)
expectTrue("Tooltipzeile mit allen Instanzen", Tags.TooltipLine(1806):find(", ", 1, true) ~= nil)

-- Fraktions-Korrektur der Questgeber (2861 für beide Fraktionen): Allianz in Eisenschmiede, Horde in Unterstadt
expect("Allianz-Geber", addon.DungeonQuests.GiverPlace(2861).uiMapID, 1455)
wow.state.faction = "Horde"
expect("Horde-Geber", addon.DungeonQuests.GiverPlace(2861).uiMapID, 1458)
wow.state.faction = "Alliance"

-- Aus: nichts angehängt
addon.Set("dungeonQuestTags", false)
gossip:Setup({ title = "Gesammelte Erinnerungen", questLevel = 18, questID = 168 })
expect("aus: Gespräch unverändert", gossip:GetText(), "Gesammelte Erinnerungen")
GameTooltip:SetHyperlink("quest:167:20")
expect("aus: keine Tooltipzeile", #GameTooltip._lines, 0)
QuestObjectiveTracker:LayoutContents()
expect("aus: Tracker unverändert", trackerBlock.HeaderText:GetText(), "[20] Die Bruderschaft")

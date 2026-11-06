-- Quest-Level: "[12]" bzw. "[12+]" vor Questnamen in Gespräch, Gruß, Questlog und Tracker; nur per Hook nach Blizzards Aufbau
local QuestLevels = addon.QuestLevels

local function withId(frame, id)
  frame.GetID = function() return id end
  return frame
end

-- Blizzard-Rahmen wie im Client vor dem Login vorhanden (Classic-Varianten)
GossipAvailableQuestButtonMixin = { Setup = function(self, info) self:SetText(info.title) end }
GossipActiveQuestButtonMixin = { Setup = function(self, info) self:SetText(info.title) end }
QuestFrameGreetingPanel = CreateFrame("Frame")
MAX_NUM_QUESTS = 2
local greetActive = withId(CreateFrame("Button", "QuestTitleButton1"), 1)
local greetAvailable = withId(CreateFrame("Button", "QuestTitleButton2"), 1)
function QuestFrameGreetingPanel_OnShow()
  greetActive:SetText("Wölfe jagen"); greetActive.isActive = 1
  greetAvailable:SetText("Kisten holen"); greetAvailable.isActive = 0
end
QuestFrameGreetingPanel:SetScript("OnShow", QuestFrameGreetingPanel_OnShow)
function GetActiveLevel(index) return index == 1 and 7 or nil end
function GetAvailableLevel(index) return index == 1 and 9 or nil end

QUESTS_DISPLAYED = 2
QuestLogListScrollFrame = CreateFrame("Frame")
function FauxScrollFrame_GetOffset() return 0 end
local logLine1 = CreateFrame("Button", "QuestLogTitle1")
local logLine2 = CreateFrame("Button", "QuestLogTitle2")
function QuestLog_Update()
  logLine1:SetText("Elwynn")  -- Überschrift
  logLine2:SetText("  Die Kobolde")
end
QuestWatchFrame = CreateFrame("Frame")
local watchTitle = CreateFrame("Frame", "QuestWatchLine1")
local watchObjective = CreateFrame("Frame", "QuestWatchLine2")
function QuestWatch_Update()
  watchTitle:SetText("Die Kobolde")
  watchObjective:SetText(" - Kobold: 3/10")
end

wow.state.questLog = {
  { title = "Elwynn", isHeader = true },
  { title = "Die Kobolde", questID = 60, level = 12, suggestedGroup = 3, objectives = { { text = "Kobold: 3/10" } } },
}
wow.state.questWatches = { 2 }

wow.login({ level = 10 })

-- Hilfsfunktionen
expect("Tag", QuestLevels.Tag(12, false), "[12] ")
expect("Tag Gruppe", QuestLevels.Tag(12, true), "[12+] ")
expect("Einrückung bleibt", QuestLevels.Prefix("  Titel", 5), "  [5] Titel")
expect("nur einmal", QuestLevels.Prefix("[5] Titel", 5), nil)
expect("geheimes Level", QuestLevels.Prefix("Titel", wow.SECRET), nil)

-- Aus: Texte unverändert
local gossip = CreateFrame("Button")
gossip.Setup = GossipAvailableQuestButtonMixin.Setup  -- Template-Knopf entsteht nach dem Hook
gossip:Setup({ title = "Die Kobolde", questLevel = 12, questID = 60 })
expect("aus: Gespräch unverändert", gossip:GetText(), "Die Kobolde")
QuestLog_Update()
expect("aus: Questlog unverändert", logLine2:GetText(), "  Die Kobolde")

addon.Set("questLevels", true)

-- Gespräch: Level aus questInfo, Gruppe aus dem Questlog
local resized = 0
gossip.Resize = function() resized = resized + 1 end
gossip:Setup({ title = "Die Kobolde", questLevel = 12, questID = 60 })
expect("Gespräch mit Gruppe", gossip:GetText(), "[12+] Die Kobolde")
expect("Höhe angepasst", resized, 1)
local active = CreateFrame("Button")
active.Setup = GossipActiveQuestButtonMixin.Setup
active:Setup({ title = "Briefe", questLevel = 4, questID = 61 })
expect("aktive Quest ohne Gruppe", active:GetText(), "[4] Briefe")

-- Gruß: Skript und direkter Aufruf
QuestFrameGreetingPanel._scripts.OnShow(QuestFrameGreetingPanel)
expect("Gruß aktiv", greetActive:GetText(), "[7] Wölfe jagen")
expect("Gruß angeboten", greetAvailable:GetText(), "[9] Kisten holen")
QuestFrameGreetingPanel_OnShow()
expect("direkter Aufruf ebenso, nicht doppelt", greetActive:GetText(), "[7] Wölfe jagen")

-- Classic-Questlog: Überschrift bleibt, Quest mit Einrückung
QuestLog_Update()
expect("Überschrift unverändert", logLine1:GetText(), "Elwynn")
expect("Questlog", logLine2:GetText(), "  [12+] Die Kobolde")

-- Classic-Tracker: nur die Titelzeile
QuestWatch_Update()
expect("Tracker Titel", watchTitle:GetText(), "[12+] Die Kobolde")
expect("Tracker Ziel unverändert", watchObjective:GetText(), " - Kobold: 3/10")

-- Retail/Forever-Questlog: Pool mit Log-Index, C_QuestLog.GetInfo
local mainlineButton = { questLogIndex = 1, Text = CreateFrame("Frame") }
QuestScrollFrame = { titleFramePool = { EnumerateActive = function()
  local done = false
  return function() if not done then done = true; return mainlineButton end end
end } }
C_QuestLog.GetNumQuestLogEntries = function() return 1 end
C_QuestLog.GetInfo = function(index)
  if index == 1 then return { title = "Drachen", level = 30, suggestedGroup = 0, isHeader = false } end
end
function QuestLogQuests_Update() mainlineButton.Text:SetText("Drachen") end
wow.fire("ADDON_LOADED", "Blizzard_WorldMap")
QuestLogQuests_Update()
expect("Retail-Questlog", mainlineButton.Text:GetText(), "[30] Drachen")
C_QuestLog.GetInfo, C_QuestLog.GetNumQuestLogEntries = nil, nil

-- Ausgeschaltet: beim nächsten Aufbau weg
addon.Set("questLevels", false)
QuestLog_Update()
expect("aus: Questlog wieder ohne Level", logLine2:GetText(), "  Die Kobolde")

-- XP und Gold im Questlog-Tooltip und auf der Questkarte (Roadmap 486): Classic-Hook auf QuestLogTitleButton_OnEnter,
-- Retail/Forever-Knöpfe aus QuestScrollFrame.titleFramePool per HookScript
local L = addon.L
local QuestTooltip = addon.QuestTooltip

-- Blizzard-Rahmen wie im Client vor dem Login vorhanden
QuestLogListScrollFrame = CreateFrame("Frame")
function FauxScrollFrame_GetOffset() return 0 end
function QuestLogTitleButton_OnEnter() end
local classicLine = CreateFrame("Button", "QuestLogTitle2")
classicLine:SetID(2)

wow.state.questLog = {
  { title = "Elwynn", isHeader = true },
  { title = "Die Kobolde", questID = 60, rewardXp = 1250, rewardMoney = 12000 },
  { title = "Nur XP", questID = 61, rewardXp = 300 },
  { title = "Nichts", questID = 62 },
}

wow.login({ level = 10 })

local both = string.format(L.QUEST_REWARD_LINE, string.format(L.INSTANCE_REPORT_XP, addon.Format.Integer(1250))
  .. ", " .. addon.Format.Money(12000))
expect("XP und Gold", QuestTooltip.RewardText(60), both)
expect("nur XP", QuestTooltip.RewardText(61),
  string.format(L.QUEST_REWARD_LINE, string.format(L.INSTANCE_REPORT_XP, "300")))
expect("ohne Belohnung keine Zeile", QuestTooltip.RewardText(62), nil)
expect("unbekannte Quest", QuestTooltip.RewardText(nil), nil)

-- Aus (Standard): Classic-Zeile ohne eigene Zeile
GameTooltip._lines = {}
QuestLogTitleButton_OnEnter(classicLine)
expect("aus: keine Zeile", #GameTooltip._lines, 0)

-- An: Classic-Zeile bekommt die Belohnung, Überschrift nicht
addon.Set("questLogRewards", true)
QuestLogTitleButton_OnEnter(classicLine)
expect("Classic: Belohnung", GameTooltip._lines[1], both)
classicLine:SetID(1)
GameTooltip._lines = {}
QuestLogTitleButton_OnEnter(classicLine)
expect("Überschrift: nichts", #GameTooltip._lines, 0)

-- Retail/Forever: Pool-Knopf mit Log-Index, Hook nach dem Aufbau
local mainlineButton = CreateFrame("Button")
mainlineButton.questLogIndex = 3
-- Blizzards Handler hat den Tooltip schon aufgebaut und besitzt ihn
mainlineButton:SetScript("OnEnter", function(self)
  GameTooltip._lines = { "Nur XP" }
  GameTooltip.GetOwner = function() return self end
end)
QuestScrollFrame = { titleFramePool = { EnumerateActive = function()
  local done = false
  return function() if not done then done = true; return mainlineButton end end
end } }
function QuestLogQuests_Update() end
wow.fire("ADDON_LOADED", "Blizzard_WorldMap")
QuestLogQuests_Update()
QuestLogQuests_Update()  -- zweiter Aufbau hängt nicht doppelt an
mainlineButton._scripts.OnEnter(mainlineButton)
expect("Retail: Blizzard-Zeile bleibt", GameTooltip._lines[1], "Nur XP")
expect("Retail: Belohnung einmal", GameTooltip._lines[2],
  string.format(L.QUEST_REWARD_LINE, string.format(L.INSTANCE_REPORT_XP, "300")))
expect("Retail: nicht doppelt", #GameTooltip._lines, 2)

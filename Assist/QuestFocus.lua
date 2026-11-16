-- Quest-Fokus (LT-260): eine gewählte Quest je Sitzung. Die Questkarte (Assist/QuestMap.lua) blendet die Punkte anderer
-- Quests ab, der Questpfeil (Assist/QuestArrow.lua) zeigt zu ihr. Gewählt wird per Rechtsklick auf einen Questpunkt der
-- Weltkarte oder im Questlog; nochmal Rechtsklick hebt den Fokus auf, ebenso Abgabe oder Abbruch der Quest
-- (QUEST_TURNED_IN, QUEST_REMOVED: QuestLogDocumentation.lua in forever, classic_era, live).
-- Questlog je Client (wow-ui-source):
--   Era   Blizzard_UIPanels_Game/Vanilla/QuestLogFrame.lua: QuestLogTitleButton_OnClick(self, button), Knöpfe sind für
--         Rechtsklick angemeldet (QuestLogTitleButton_OnLoad), Index = self:GetID() + FauxScrollFrame_GetOffset(
--         QuestLogListScrollFrame); Rechtsklick wählt dort nur aus, deshalb Post-Hook.
--   Forever/Retail  Mainline/QuestMapFrame.lua: Rechtsklick öffnet ein Kontextmenü (Tag "MENU_QUEST_MAP_LOG_TITLE",
--         Besitzer = Titelknopf mit questID); eigener Eintrag über Menu.ModifyMenu (Blizzard_Menu/Menu.lua).
-- Nur aktiv, wenn Questkarte oder Questpfeil eingeschaltet ist.
local _, ns = ...
local L = ns.L

local QuestFocus = {}
ns.QuestFocus = QuestFocus

local FADED_ALPHA = 0.25  -- Punkte anderer Quests bei gesetztem Fokus
local LOG_MENU_TAG = "MENU_QUEST_MAP_LOG_TITLE"

local focused
local listeners = {}

function QuestFocus.IsUsed(db)
  return db ~= nil and (db.questMap or db.questArrow) and true or false
end

function QuestFocus.Get()
  return focused
end

function QuestFocus.OnChange(fn)
  table.insert(listeners, fn)
end

function QuestFocus.Set(questID)
  if questID == focused then return end
  focused = questID
  ns.Debug("questFocus", "focus %s", questID)
  for _, fn in ipairs(listeners) do fn(questID) end
end

function QuestFocus.Toggle(questID)
  QuestFocus.Set(questID ~= focused and questID or nil)
end

-- Deckkraft eines Punkts der Quest: voll ohne Fokus oder für die fokussierte Quest
function QuestFocus.AlphaFor(questID)
  if focused == nil or questID == focused then return 1 end
  return FADED_ALPHA
end

-- Text für Tooltip und Menü: fokussieren oder aufheben
function QuestFocus.ActionText(questID)
  return questID == focused and L.QUEST_FOCUS_CLEAR or L.QUEST_FOCUS_SET
end

local function clearIfFocused(questID)
  if not ns.IsSecret(questID) and questID == focused then QuestFocus.Set(nil) end
end
ns.RegisterEvent("QUEST_TURNED_IN", clearIfFocused)
ns.RegisterEvent("QUEST_REMOVED", clearIfFocused)

-- Era: Rechtsklick auf eine Quest im Questlog
local function onLogTitleClick(button, mouseButton)
  if mouseButton ~= "RightButton" or button.isHeader or not QuestFocus.IsUsed(ns.db) then return end
  local entry = ns.QuestLog.Entry(button:GetID() + FauxScrollFrame_GetOffset(QuestLogListScrollFrame))
  if entry then QuestFocus.Toggle(entry.questID) end
end

-- Forever/Retail: Eintrag im Kontextmenü einer Quest
local function onLogMenu(owner, root)
  local questID = owner and owner.questID
  if ns.IsSecret(questID) or type(questID) ~= "number" or not QuestFocus.IsUsed(ns.db) then return end
  root:CreateButton(QuestFocus.ActionText(questID), function() QuestFocus.Toggle(questID) end)
end

local hooked = false
ns.OnLogin(function()
  if hooked then return end
  hooked = true
  if Menu and Menu.ModifyMenu then
    Menu.ModifyMenu(LOG_MENU_TAG, function(owner, root) ns.SafeCall(onLogMenu, owner, root) end)
  end
  if QuestLogTitleButton_OnClick and FauxScrollFrame_GetOffset then
    hooksecurefunc("QuestLogTitleButton_OnClick", function(button, mouseButton)
      ns.SafeCall(onLogTitleClick, button, mouseButton)
    end)
  end
end)

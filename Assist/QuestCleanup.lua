-- Graue Quests aufräumen und "Questlog fast voll" (Roadmap 344).
--   questCleanupButton  Knopf "Graue Quests (N)" unter dem Questlog (Classic QuestLogFrame, Retail/Forever QuestMapFrame
--                       bzw. WorldMapFrame; HookScript("OnShow"), keine Blizzard-Funktion ersetzt). Klick listet die
--                       grauen Quests in einer Rückfrage; erst nach "Ja" werden sie abgebrochen, eine je ABANDON_STEP.
--                       Nie automatisch.
--   warnQuestLogFull    Hinweis, wenn nach einer Annahme höchstens FULL_MARGIN Plätze frei sind (einmal, bis wieder
--                       mehr frei ist).
-- Grau: Retail/Forever C_QuestLog.IsQuestTrivial(questID); Classic wie Blizzards GetRelativeDifficultyColor
-- (Blizzard_UIParent/Vanilla/UIParent.lua): Spielerlevel - Questlevel > GetQuestGreenRange().
-- Abbrechen: Retail/Forever C_QuestLog.SetSelectedQuest(questID), C_QuestLog.SetAbandonQuest(),
-- C_QuestLog.AbandonQuest() (QuestLogDocumentation, nicht geschützt; Blizzards Abbrechen-Dialog ruft dieselben auf);
-- Classic SelectQuestLogEntry(index), SetAbandonQuest(), AbandonQuest() (Vanilla/QuestLogFrame.xml).
-- Höchstzahl: QuestLog.MaxQuests (C_QuestLog.GetMaxNumQuestsCanAccept, sonst MAX_QUESTS).
local _, ns = ...
local L = ns.L
local QuestLog = ns.QuestLog
local Widgets = ns.Widgets

local QuestCleanup = {}
ns.QuestCleanup = QuestCleanup

QuestCleanup.FULL_MARGIN = 2
local ABANDON_STEP = 0.3     -- Sekunden zwischen zwei Abbrüchen (der Server braucht etwas)
local MAX_LISTED = 10        -- so viele Namen nennt die Rückfrage
local BUTTON_WIDTH, BUTTON_HEIGHT = 150, 22
local CONFIRM_POPUP = "LEVELTIMER_ABANDON_GRAY_QUESTS"
-- Questlog-Fenster je Client, das erste vorhandene bekommt den Knopf
local LOG_FRAMES = { "QuestLogFrame", "QuestMapFrame", "WorldMapFrame" }

local button
local warned = false

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

function QuestCleanup.IsGray(entry)
  if C_QuestLog and C_QuestLog.IsQuestTrivial then
    return readable(C_QuestLog.IsQuestTrivial(entry.questID)) == true
  end
  local level, playerLevel = entry.level, readable(UnitLevel("player"))
  if type(level) ~= "number" or level <= 0 or type(playerLevel) ~= "number" or not GetQuestGreenRange then
    return false
  end
  local range = readable(GetQuestGreenRange())
  return type(range) == "number" and playerLevel - level > range
end

function QuestCleanup.GrayQuests()
  local list = {}
  for _, entry in ipairs(QuestLog.Entries()) do
    if QuestCleanup.IsGray(entry) then table.insert(list, entry) end
  end
  return list
end

-- Eine Quest abbrechen; false, wenn der Client es nicht kann oder sie nicht mehr im Log ist
function QuestCleanup.Abandon(questID)
  local entry = QuestLog.Find(questID)
  if not entry then return false end
  if C_QuestLog and C_QuestLog.SetSelectedQuest and C_QuestLog.SetAbandonQuest and C_QuestLog.AbandonQuest then
    C_QuestLog.SetSelectedQuest(questID)
    C_QuestLog.SetAbandonQuest()
    C_QuestLog.AbandonQuest()
  elseif SelectQuestLogEntry and SetAbandonQuest and AbandonQuest then
    SelectQuestLogEntry(entry.index)
    SetAbandonQuest()
    AbandonQuest()
  else
    return false
  end
  ns.Debug("quests", "abandoned gray quest %s", questID)
  return true
end

-- Liste nacheinander abbrechen; jede Quest wird vorher noch einmal geprüft (noch da, noch grau)
local function abandonNext(questIDs)
  local questID = table.remove(questIDs, 1)
  if not questID then return end
  local entry = QuestLog.Find(questID)
  if entry and QuestCleanup.IsGray(entry) then QuestCleanup.Abandon(questID) end
  if #questIDs > 0 then C_Timer.After(ABANDON_STEP, function() ns.SafeCall(abandonNext, questIDs) end) end
end

StaticPopupDialogs[CONFIRM_POPUP] = {
  button1 = YES or "Yes",
  button2 = NO or "No",
  OnAccept = function(_, questIDs) abandonNext(questIDs) end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-- Rückfrage mit den Namen; abgebrochen wird erst beim Bestätigen
function QuestCleanup.Confirm()
  local gray = QuestCleanup.GrayQuests()
  if #gray == 0 then
    ns.Print(L.QUEST_CLEANUP_NONE)
    return
  end
  local names, questIDs = {}, {}
  for index, entry in ipairs(gray) do
    questIDs[index] = entry.questID
    if index <= MAX_LISTED then names[index] = entry.title or tostring(entry.questID) end
  end
  if #gray > MAX_LISTED then table.insert(names, "...") end
  StaticPopupDialogs[CONFIRM_POPUP].text = L.QUEST_CLEANUP_CONFIRM  -- aktuelle Sprache
  StaticPopup_Show(CONFIRM_POPUP, #gray, table.concat(names, "\n"), questIDs)
end

local function refreshButton()
  if not button then return end
  local show = ns.db and ns.db.questCleanupButton
  button:SetShown(show and true or false)
  if not show then return end
  local count = #QuestCleanup.GrayQuests()
  Widgets.SetButtonText(button, string.format(L.QUEST_CLEANUP_BUTTON, count), BUTTON_WIDTH)
  if count > 0 then button:Enable() else button:Disable() end
end

local function attach()
  if button then return end
  local parent
  for _, name in ipairs(LOG_FRAMES) do
    if type(_G[name]) == "table" then
      parent = _G[name]
      break
    end
  end
  if not parent then return end
  button = Widgets.CreateButton(parent, BUTTON_WIDTH, BUTTON_HEIGHT, QuestCleanup.Confirm)
  button:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, 0)
  parent:HookScript("OnShow", refreshButton)
  ns.Debug("quests", "cleanup button on %s", parent.GetName and parent:GetName() or "?")
  refreshButton()
end

---------------------------------------------------------------------------
-- Questlog fast voll
---------------------------------------------------------------------------
function QuestCleanup.CheckFull()
  local max = QuestLog.MaxQuests()
  if not max then return end
  local count = QuestLog.QuestCount()
  if count < max - QuestCleanup.FULL_MARGIN then
    warned = false
    return
  end
  if warned then return end
  warned = true
  ns.Alerts.Notify({ title = L.QUEST_LOG_FULL_TITLE, text = string.format(L.QUEST_LOG_FULL, count, max),
    icon = ns.Alerts.ICONS.questLog }, ns.Alerts.WARNING_COLOR)
end

ns.QuestWatch.Subscribe({
  enabled = function(db) return db.warnQuestLogFull end,
  onAccepted = function() QuestCleanup.CheckFull() end,
})

ns.RegisterEvent("QUEST_LOG_UPDATE", function()
  if button and button:IsShown() then refreshButton() end
end)
ns.RegisterEvent("ADDON_LOADED", function(name)
  if name == "Blizzard_WorldMap" and ns.db and ns.db.questCleanupButton then attach() end
end)
ns.RegisterApply(function(db)
  if db.questCleanupButton then attach() end
  refreshButton()
end)
ns.OnLogin(function() warned = false end)

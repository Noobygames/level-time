-- Belohnungsempfehlung (Roadmap 346, Einstellung rewardHint, aus): im Questfenster und in den Questdetails des
-- Questlogs bekommt die Wahl mit dem höchsten Händlerpreis ein Goldmünzen-Symbol und die benutzbare Wahl mit dem
-- größten Itemlevel-Gewinn gegenüber der angelegten Ausrüstung "+N" (Lib/QuestRewards.lua). Reine Anzeige, wählt nichts.
-- Anschluss: hooksecurefunc("QuestInfo_Display") (alle Zweige, Blizzard_UIPanels_Game/*/QuestInfo.lua): danach stehen
-- die Knöpfe in QuestInfoFrame.rewardsFrame.RewardButtons mit type == "choice" und GetID() = Nummer der Wahl;
-- QuestInfoFrame.questLog sagt, ob die Questdetails des Logs gezeigt werden. Eigene Kind-Texturen auf den Knöpfen,
-- keine Änderung an Blizzards Knöpfen. Retail/Forever laden Items nach (ContinueOnItemLoad): bei unbekannten Werten
-- wird bis zu RETRIES Mal nach RETRY_SECONDS neu bewertet.
local _, ns = ...
local QuestRewards = ns.QuestRewards

local RewardHint = {}
ns.RewardHint = RewardHint

local COIN_ICON = "Interface\\MoneyFrame\\UI-GoldIcon"
local COIN_SIZE = 14
local UPGRADE_COLOR = { 0.2, 1, 0.2 }
local RETRIES = 3
local RETRY_SECONDS = 0.3

local hooked = false
local marks = {}  -- [Knopf] = { coin, upgrade }

local function choiceButtons()
  local frame = type(QuestInfoFrame) == "table" and QuestInfoFrame or nil
  local rewards = frame and (type(frame.rewardsFrame) == "table" and frame.rewardsFrame or nil)
  local buttons = rewards and type(rewards.RewardButtons) == "table" and rewards.RewardButtons or {}
  local list = {}
  for _, button in ipairs(buttons) do
    if type(button) == "table" and button.type == QuestRewards.CHOICE and button:IsShown() then
      list[#list + 1] = button
    end
  end
  return list, frame and frame.questLog and true or false
end

local function marksOf(button)
  local mark = marks[button]
  if mark then return mark end
  mark = {}
  mark.coin = button:CreateTexture(nil, "OVERLAY")
  mark.coin:SetTexture(COIN_ICON)
  mark.coin:SetSize(COIN_SIZE, COIN_SIZE)
  mark.coin:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
  mark.upgrade = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  mark.upgrade:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 2)
  mark.upgrade:SetTextColor(unpack(UPGRADE_COLOR))
  mark.coin:Hide()
  mark.upgrade:Hide()
  marks[button] = mark
  return mark
end

local function hideAll()
  for _, mark in pairs(marks) do
    mark.coin:Hide()
    mark.upgrade:Hide()
  end
end

-- Symbole setzen; true, wenn alle Werte bekannt waren
function RewardHint.Update()
  hideAll()
  if not (ns.db and ns.db.rewardHint) then return true end
  local buttons, fromLog = choiceButtons()
  if #buttons < 2 then return true end  -- eine einzige Wahl braucht keine Empfehlung
  local count = 0
  for _, button in ipairs(buttons) do count = math.max(count, button:GetID()) end
  local valuable, value = QuestRewards.MostValuable(count, fromLog)
  local upgrade, gain = QuestRewards.BestUpgrade(count, fromLog)
  for _, button in ipairs(buttons) do
    local index = button:GetID()
    local mark = marksOf(button)
    mark.coin:SetShown(index == valuable and (value or 0) > 0)
    if index == upgrade then
      mark.upgrade:SetText("+" .. gain)
      mark.upgrade:Show()
    end
  end
  ns.Debug("quests", "reward hint: value %s (%s), upgrade %s (+%s), log %s", valuable, value, upgrade, gain, fromLog)
  return valuable ~= nil
end

local function updateWithRetries(left)
  if RewardHint.Update() or left <= 0 then return end
  C_Timer.After(RETRY_SECONDS, function() ns.SafeCall(updateWithRetries, left - 1) end)
end

local function hook()
  if hooked or type(QuestInfo_Display) ~= "function" then return end
  hooked = true
  hooksecurefunc("QuestInfo_Display", function() ns.SafeCall(updateWithRetries, RETRIES) end)
end

ns.RegisterApply(function(db)
  if db.rewardHint then hook() end
  if not db.rewardHint then hideAll() end
end)

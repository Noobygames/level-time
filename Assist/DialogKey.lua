-- DialogKey-Tastensteuerung für Quests und Gespräche (Roadmap 445): Leertaste drückt bei offenem QuestFrame
-- oder GossipFrame Weiter, Annehmen oder Abschließen; Zifferntasten 1-9 wählen Optionen und Belohnungen.
-- SetOverrideBindingClick bindet Leertaste und 1-9 an verdeckte Buttons auf LevelTimerDialogKeyFrame.
-- Bei Schließen des Dialogs, Kampfbeginn (PLAYER_REGEN_DISABLED) oder Deaktivieren werden alle Bindings gelöst.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    dialogKeys = false,
  },
})

local DialogKey = {}
ns.DialogKey = DialogKey

local dialogOpen = nil
local bindingsActive = false

local ownerFrame = CreateFrame("Frame", "LevelTimerDialogKeyFrame", UIParent)
ownerFrame:Hide()
DialogKey.ownerFrame = ownerFrame

local spaceButton = CreateFrame("Button", "LevelTimerDialogKeySpaceButton", ownerFrame)
spaceButton:SetScript("OnClick", function()
  DialogKey.PressSpace()
end)

local numButtons = {}
for i = 1, 9 do
  local btn = CreateFrame("Button", "LevelTimerDialogKeyButton" .. i, ownerFrame)
  local keyIndex = i
  btn:SetScript("OnClick", function()
    DialogKey.PressKey(keyIndex)
  end)
  numButtons[i] = btn
end

local function setBindings()
  if bindingsActive then return end
  if not SetOverrideBindingClick then return end
  SetOverrideBindingClick(ownerFrame, true, "SPACE", "LevelTimerDialogKeySpaceButton")
  for i = 1, 9 do
    SetOverrideBindingClick(ownerFrame, true, tostring(i), "LevelTimerDialogKeyButton" .. i)
  end
  bindingsActive = true
end

local function clearBindings()
  if ClearOverrideBindings and ownerFrame then
    ClearOverrideBindings(ownerFrame)
  end
  bindingsActive = false
  dialogOpen = nil
end

local function isBlocked()
  if not ns.db or not ns.db.dialogKeys then return true end
  if not dialogOpen then return true end
  if ns.InCombat() then return true end
  if IsShiftKeyDown and IsShiftKeyDown() then return true end
  if GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus() ~= nil then return true end
  return false
end

function DialogKey.PressSpace()
  if isBlocked() then return false end

  if dialogOpen == "detail" then
    if AcceptQuest then AcceptQuest() end
    return true
  elseif dialogOpen == "progress" then
    if IsQuestCompletable and IsQuestCompletable() then
      if CompleteQuest then CompleteQuest() end
      return true
    end
  elseif dialogOpen == "complete" then
    local numChoices = GetNumQuestChoices and GetNumQuestChoices() or 0
    if numChoices <= 1 then
      local choice = (numChoices == 1) and 1 or nil
      if GetQuestReward then GetQuestReward(choice) end
      return true
    end
  elseif dialogOpen == "gossip" then
    if C_GossipInfo then
      local active = C_GossipInfo.GetActiveQuests and C_GossipInfo.GetActiveQuests() or {}
      for _, quest in ipairs(active) do
        if quest.isComplete then
          if C_GossipInfo.SelectActiveQuest then
            C_GossipInfo.SelectActiveQuest(quest.questID)
            return true
          end
        end
      end
      local available = C_GossipInfo.GetAvailableQuests and C_GossipInfo.GetAvailableQuests() or {}
      if #available > 0 then
        if C_GossipInfo.SelectAvailableQuest then
          C_GossipInfo.SelectAvailableQuest(available[1].questID)
          return true
        end
      end
      local options = C_GossipInfo.GetOptions and C_GossipInfo.GetOptions() or {}
      if #options == 1 then
        local option = options[1]
        local optID = option.gossipOptionID or option.orderIndex
        if C_GossipInfo.SelectOption then
          C_GossipInfo.SelectOption(optID)
          return true
        elseif C_GossipInfo.SelectOptionByIndex and option.orderIndex then
          C_GossipInfo.SelectOptionByIndex(option.orderIndex)
          return true
        end
      end
    end
  elseif dialogOpen == "greeting" then
    local numActive = GetNumActiveQuests and GetNumActiveQuests() or 0
    if numActive > 0 and GetActiveTitle and SelectActiveQuest then
      for i = 1, numActive do
        local _, isComplete = GetActiveTitle(i)
        if isComplete then
          SelectActiveQuest(i)
          return true
        end
      end
    end
    local numAvailable = GetNumAvailableQuests and GetNumAvailableQuests() or 0
    if numAvailable > 0 and SelectAvailableQuest then
      SelectAvailableQuest(1)
      return true
    end
  end
  return false
end

function DialogKey.PressKey(index)
  if isBlocked() then return false end
  if not index or index < 1 or index > 9 then return false end

  if dialogOpen == "complete" then
    local numChoices = GetNumQuestChoices and GetNumQuestChoices() or 0
    if index <= numChoices then
      if GetQuestReward then GetQuestReward(index) end
      return true
    end
  elseif dialogOpen == "gossip" then
    if C_GossipInfo then
      local active = C_GossipInfo.GetActiveQuests and C_GossipInfo.GetActiveQuests() or {}
      local numActive = #active
      if index <= numActive then
        local q = active[index]
        if q and q.questID and C_GossipInfo.SelectActiveQuest then
          C_GossipInfo.SelectActiveQuest(q.questID)
          return true
        end
      end
      local available = C_GossipInfo.GetAvailableQuests and C_GossipInfo.GetAvailableQuests() or {}
      local numAvailable = #available
      if index <= numActive + numAvailable then
        local availIndex = index - numActive
        local q = available[availIndex]
        if q and q.questID and C_GossipInfo.SelectAvailableQuest then
          C_GossipInfo.SelectAvailableQuest(q.questID)
          return true
        end
      end
      local options = C_GossipInfo.GetOptions and C_GossipInfo.GetOptions() or {}
      local numOptions = #options
      if index <= numActive + numAvailable + numOptions then
        local optIndex = index - numActive - numAvailable
        local option = options[optIndex]
        if option then
          local optID = option.gossipOptionID or option.orderIndex
          if C_GossipInfo.SelectOption then
            C_GossipInfo.SelectOption(optID)
            return true
          elseif C_GossipInfo.SelectOptionByIndex and option.orderIndex then
            C_GossipInfo.SelectOptionByIndex(option.orderIndex)
            return true
          end
        end
      end
    end
  elseif dialogOpen == "greeting" then
    local numActive = GetNumActiveQuests and GetNumActiveQuests() or 0
    if index <= numActive then
      if SelectActiveQuest then
        SelectActiveQuest(index)
        return true
      end
    end
    local numAvailable = GetNumAvailableQuests and GetNumAvailableQuests() or 0
    if index <= numActive + numAvailable then
      local availIndex = index - numActive
      if SelectAvailableQuest then
        SelectAvailableQuest(availIndex)
        return true
      end
    end
  end
  return false
end

function DialogKey.GetDialogOpen()
  return dialogOpen
end

local function onDialogOpen(kind)
  dialogOpen = kind
  if ns.db and ns.db.dialogKeys and not ns.InCombat() then
    setBindings()
  end
end

ns.RegisterEvent("QUEST_DETAIL", function()
  onDialogOpen("detail")
end)

ns.RegisterEvent("QUEST_PROGRESS", function()
  onDialogOpen("progress")
end)

ns.RegisterEvent("QUEST_COMPLETE", function()
  onDialogOpen("complete")
end)

ns.RegisterEvent("QUEST_GREETING", function()
  onDialogOpen("greeting")
end)

ns.RegisterEvent("GOSSIP_SHOW", function()
  onDialogOpen("gossip")
end)

ns.RegisterEvent("QUEST_FINISHED", function()
  clearBindings()
end)

ns.RegisterEvent("GOSSIP_CLOSED", function()
  clearBindings()
end)

ns.RegisterEvent("PLAYER_REGEN_DISABLED", function()
  clearBindings()
end)

ns.RegisterApply(function(db)
  if not db.dialogKeys then
    clearBindings()
  elseif dialogOpen and not ns.InCombat() then
    setBindings()
  end
end)

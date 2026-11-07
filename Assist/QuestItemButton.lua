-- Quest-Item-Knopf (Roadmap 268, Einstellungen questItemButton und questTargetButton, Standard aus), wie Guidelime/RXP:
-- ein sicherer Knopf benutzt das Quest-Item der nächsten Quest, ein zweiter wählt einen Questgegner als Ziel.
-- Quellen:
--   Quest-Item  GetQuestLogSpecialItemInfo(questLogIndex) -> link, Symbol, Ladungen, showItemWhenComplete
--               (warcraft.wiki.gg: alle Clients; Blizzards ObjectiveTracker nutzt es in Retail/Forever). Benutzt wird
--               über SecureActionButtonTemplate type "item" mit "item:<ID>" (SECURE_ACTIONS.item ->
--               SecureCmdItemParse, Blizzard_FrameXML/SecureTemplates.lua in allen Zweigen); UseQuestLogSpecialItem
--               selbst ist geschützt.
--   "Nächste"   Retail/Forever C_QuestLog.GetDistanceSqToQuest (kleinster lesbarer Abstand); Classic kennt keinen
--               Abstand: die zuletzt angenommene Quest mit Item, sonst die erste im Log.
--   Ziel        Namensplaketten, die C_QuestLog.UnitIsRelatedToActiveQuest als Questgegner meldet (wie QuestMarks.lua,
--               nur wo es das gibt), Knopf type "macro" mit "/targetexact <Name>". Kein Lesen von Zieltexten.
-- Attribute, Anzeigen und Verstecken der sicheren Knöpfe nur außerhalb des Kampfs; im Kampf wird es gemerkt und bei
-- PLAYER_REGEN_ENABLED nachgeholt. Der Halter (verschiebbar über Widgets.CreateMover, Position questItemPos) wird
-- durch die sicheren Kinder selbst geschützt und deshalb ebenfalls nur außerhalb des Kampfs angefasst.
-- Klicks: RegisterForClicks("AnyUp", "AnyDown") und useOnKeyDown = false, damit genau ein Klick beim Loslassen auslöst
-- (SecureActionButton_OnClick in allen Zweigen).
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets

local QuestItem = {}
ns.QuestItem = QuestItem

local BUTTON_SIZE = 36
local GAP = 4
local LABEL_HEIGHT = 14  -- Griff zum Verschieben über den Knöpfen (nur im Verschiebe-Modus sichtbar)
local REFRESH_SECONDS = 1
local MAX_NAMEPLATES = 40
local DEFAULT_POS = { "CENTER", "CENTER", 0, -180 }
local MOVE_BACKGROUND = { 0, 0, 0, 0.6 }

local holder, itemButton, targetButton, mover
local shown = { itemId = nil, target = nil, texture = nil }  -- zuletzt gesetzte Attribute und Symbol
local pending = false                         -- im Kampf aufgeschoben
local acceptedAt = {}                         -- [questID] = GetTime() der Annahme

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function inCombat()
  return InCombatLockdown and InCombatLockdown()
end

function QuestItem.CanTarget()
  return ns.QuestMarks.IsAvailable()
end

-- Quests mit benutzbarem Item: { questID, index, link, itemId, texture }
function QuestItem.Candidates()
  local list = {}
  if not GetQuestLogSpecialItemInfo then return list end
  for _, entry in ipairs(ns.QuestLog.Entries()) do
    local link, texture = GetQuestLogSpecialItemInfo(entry.index)
    link, texture = readable(link), readable(texture)
    local itemId = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    if itemId then
      table.insert(list, { questID = entry.questID, index = entry.index, link = link, itemId = itemId, texture = texture })
    end
  end
  return list
end

local function distanceOf(questID)
  if not (C_QuestLog and C_QuestLog.GetDistanceSqToQuest) then return nil end
  local distance = readable(C_QuestLog.GetDistanceSqToQuest(questID))
  return type(distance) == "number" and distance or nil
end

-- Nächste Quest (Abstand), sonst die zuletzt angenommene, sonst die erste
function QuestItem.Pick()
  local best, bestDistance, bestAccepted
  for _, candidate in ipairs(QuestItem.Candidates()) do
    local distance = distanceOf(candidate.questID)
    local accepted = acceptedAt[candidate.questID] or 0
    local better
    if not best then
      better = true
    elseif distance and bestDistance then
      better = distance < bestDistance
    elseif distance or bestDistance then
      better = distance ~= nil
    else
      better = accepted > bestAccepted
    end
    if better then best, bestDistance, bestAccepted = candidate, distance, accepted end
  end
  return best
end

-- Name eines lebenden Questgegners auf einer Namensplakette
function QuestItem.TargetName()
  if not QuestItem.CanTarget() then return nil end
  for i = 1, MAX_NAMEPLATES do
    local unit = "nameplate" .. i
    if UnitExists(unit) and not UnitIsPlayer(unit) and not UnitIsDead(unit) then
      local related = C_QuestLog.UnitIsRelatedToActiveQuest(unit)
      local name = readable(UnitName(unit))
      if not ns.IsSecret(related) and related == true and type(name) == "string" and name ~= "" then
        return name
      end
    end
  end
end

local function createSecureButton(name, actionType)
  local button = CreateFrame("Button", name, holder, "SecureActionButtonTemplate")
  button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
  button:RegisterForClicks("AnyUp", "AnyDown")
  button:SetAttribute("useOnKeyDown", false)
  button:SetAttribute("type", actionType)
  button.icon = button:CreateTexture(nil, "ARTWORK")
  button.icon:SetAllPoints()
  button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  button:Hide()
  return button
end

local function showTooltip(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  if self == itemButton and self.link then
    GameTooltip:SetHyperlink(self.link)
  elseif self == targetButton and shown.target then
    GameTooltip:AddLine(string.format(L.QUEST_TARGET_TIP_LINE, shown.target))
  end
  GameTooltip:Show()
end

local function create()
  holder = CreateFrame("Frame", "LevelTimerQuestItemBar", UIParent)
  holder:SetSize(BUTTON_SIZE * 2 + GAP, BUTTON_SIZE + LABEL_HEIGHT)
  holder.background = holder:CreateTexture(nil, "BACKGROUND")
  holder.background:SetAllPoints()
  holder.background:SetColorTexture(unpack(MOVE_BACKGROUND))
  holder.background:Hide()
  holder.label = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  holder.label:SetPoint("TOP", 0, -1)
  holder.label:Hide()

  itemButton = createSecureButton("LevelTimerQuestItemButton", "item")
  itemButton:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
  itemButton.count = itemButton:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  itemButton.count:SetPoint("BOTTOMRIGHT", -2, 2)
  targetButton = createSecureButton("LevelTimerQuestTargetButton", "macro")
  targetButton:SetPoint("LEFT", itemButton, "RIGHT", GAP, 0)
  targetButton.icon:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
  for _, button in ipairs({ itemButton, targetButton }) do
    button:SetScript("OnEnter", showTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  end

  mover = Widgets.CreateMover(holder, {
    default = DEFAULT_POS,
    get = function() return ns.db and ns.db.questItemPos end,
    set = function(pos) ns.db.questItemPos = pos end,
    onMovingChanged = function(moving)
      holder.background:SetShown(moving)
      holder.label:SetShown(moving)
      QuestItem.Refresh()
    end,
  })
  holder:Hide()
end

local function itemCount(itemId)
  local count = C_Item and C_Item.GetItemCount and C_Item.GetItemCount(itemId)
  count = readable(count)
  return type(count) == "number" and count or 0
end

local function setItem(candidate)
  local itemId = candidate and candidate.itemId
  if itemId then
    if itemId ~= shown.itemId then itemButton:SetAttribute("item", "item:" .. itemId) end
    itemButton.link = candidate.link
    if candidate.texture ~= shown.texture then
      shown.texture = candidate.texture
      itemButton.icon:SetTexture(candidate.texture)
    end
    local count = itemCount(itemId)
    ns.Widgets.SetTextIfChanged(itemButton.count, count > 1 and tostring(count) or "")
    itemButton:Show()
  else
    itemButton.link = nil
    itemButton:Hide()
  end
  shown.itemId = itemId
end

local function setTarget(name)
  if name then
    if name ~= shown.target then targetButton:SetAttribute("macrotext", "/targetexact " .. name) end
    targetButton:Show()
  else
    targetButton:Hide()
  end
  shown.target = name
end

-- Stand neu bestimmen; nur außerhalb des Kampfs (sichere Knöpfe)
function QuestItem.Refresh()
  if not holder then return end
  if inCombat() then
    if not pending then ns.Debug("questitem", "in combat, update waits") end
    pending = true
    return
  end
  pending = false
  local db = ns.db
  local moving = mover.IsMoving()
  local itemBefore, targetBefore = shown.itemId, shown.target
  setItem(db and db.questItemButton and QuestItem.Pick() or nil)
  setTarget(db and db.questTargetButton and QuestItem.TargetName() or nil)
  if shown.itemId ~= itemBefore or shown.target ~= targetBefore then
    ns.Debug("questitem", "item %s (link %s), target %s", shown.itemId, itemButton.link, shown.target)
  end
  holder:SetShown(moving or shown.itemId ~= nil or shown.target ~= nil)
end

function QuestItem.SetMoving(enabled)
  if not holder or inCombat() then return end
  mover.SetMoving(enabled)
end

function QuestItem.IsMoving()
  return mover ~= nil and mover.IsMoving()
end

function QuestItem.ResetPosition()
  if not holder or inCombat() then return end
  mover.Reset()
end

create()

ns.RegisterEvent("QUEST_ACCEPTED", function(...)
  local questID = readable((select(select("#", ...), ...)))  -- Era: questIndex, questID; Retail/Forever: questID
  if type(questID) == "number" then acceptedAt[questID] = GetTime() end
end)
-- Einstellungen anwenden: Text, Position (Profilwechsel) und Knöpfe; im Kampf aufgeschoben
local function apply()
  if inCombat() then
    pending = true
    return
  end
  holder.label:SetText(L.QUEST_ITEM_MOVE_LABEL)
  mover.Sync()
  QuestItem.Refresh()
end

ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if pending then apply() end
end)

ns.Every(REFRESH_SECONDS, function()
  if ns.db.questItemButton or ns.db.questTargetButton or (holder and holder:IsShown()) then QuestItem.Refresh() end
end)

ns.RegisterApply(apply)

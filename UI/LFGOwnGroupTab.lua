-- Reiter Eigene Gruppe des Gruppensuche-Fensters (UI/LFGWindow.lua): eigenen Eintrag anlegen, ändern, entfernen.
-- Eintragen läuft nur aus dem Klick des eigenen Knopfs (Hardware-Ereignis, kein Taint).
local _, ns = ...
if not ns.Client.IsForever() then return end

local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme
local LFGSearch = ns.LFGSearch
local LFGTooltip = ns.LFGTooltip
local LFGWindow = ns.LFGWindow

local GAP, CONTROL_HEIGHT = LFGWindow.GAP, LFGWindow.CONTROL_HEIGHT
local ROLE_ORDER, SOLO_ROLE_KEYS = LFGWindow.ROLE_ORDER, LFGWindow.SOLO_ROLE_KEYS
local newButton, newCheck, retext = LFGWindow.NewButton, LFGWindow.NewCheck, LFGWindow.Retext
local pickFrom, nameOf, entriesOf = LFGWindow.PickFrom, LFGWindow.NameOf, LFGWindow.EntriesOf
local state = LFGWindow.State()
local parts = LFGWindow.Parts()
local listingTab = LFGWindow.listingContainer

local listingStatus = listingTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
listingStatus:SetPoint("TOPLEFT", 0, 0)
listingStatus:SetJustifyH("LEFT")
local listingNotice = listingTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
listingNotice:SetPoint("TOPLEFT", listingStatus, "BOTTOMLEFT", 0, -GAP)
listingNotice:SetTextColor(Theme.RGB("warning"))

local listingCategory = newButton(listingTab, 180, "LFG_CATEGORY", function(self)
  pickFrom(self, entriesOf(LFGSearch.Categories()), state.listingCategoryID, function(id)
    state.listingCategoryID, state.listingActivityID = id, nil
    LFGWindow.Refresh()
  end)
end)
listingCategory:SetPoint("TOPLEFT", 0, -(CONTROL_HEIGHT * 2 + GAP * 2))
local listingActivity = newButton(listingTab, 280, "LFG_ACTIVITY", function(self)
  if not state.listingCategoryID then return end
  pickFrom(self, entriesOf(LFGSearch.Activities(state.listingCategoryID)), state.listingActivityID, function(id)
    state.listingActivityID = id
    LFGWindow.Refresh()
  end)
end)
listingActivity:SetPoint("LEFT", listingCategory, "RIGHT", GAP, 0)

local roleChecks = {}
local roleLabel = listingTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
roleLabel:SetPoint("TOPLEFT", listingCategory, "BOTTOMLEFT", 0, -GAP * 2)
local previousCheck
for _, role in ipairs(ROLE_ORDER) do
  local check = Widgets.CreateCheckbox(listingTab, function() end)
  Widgets.AttachTooltip(check, function() return L.LFG_ROLES_SOLO end, function() return L.LFG_ROLES_SOLO_TIP end)
  check:SetPoint("LEFT", previousCheck or roleLabel, "RIGHT", previousCheck and 90 or GAP, 0)
  check.role = role
  roleChecks[role], previousCheck = check, check
end
local newPlayerCheck = newCheck(listingTab, "LFG_NEW_PLAYER_TOGGLE", function() end)
newPlayerCheck:SetPoint("TOPLEFT", roleLabel, "BOTTOMLEFT", 0, -GAP * 2)

local postButton = newButton(listingTab, 140, "LFG_POST", function()
  if not state.listingActivityID then return end
  local roles = {}
  for role, check in pairs(roleChecks) do roles[SOLO_ROLE_KEYS[role]] = check:GetChecked() and true or false end
  LFGSearch.Post({ activityID = state.listingActivityID, newPlayerFriendly = newPlayerCheck:GetChecked(), roles = roles })
end)
postButton:SetPrimary(true)
postButton:SetPoint("BOTTOMRIGHT", 0, 0)
local unlistButton = newButton(listingTab, 120, "LFG_UNLIST", function() LFGSearch.Unlist() end)
unlistButton:SetPoint("RIGHT", postButton, "LEFT", -GAP, 0)

LFGWindow.RegisterTab(LFGWindow.TAB_LISTING, function()
  local entry = LFGSearch.ActiveEntry()
  local canEdit = LFGSearch.CanEditListing()
  if entry and not state.listingActivityID then
    state.listingActivityID, state.listingCategoryID = entry.activityIDs[1], entry.categoryID
    newPlayerCheck:SetChecked(entry.newPlayerFriendly)
    local roles = LFGSearch.GetRoles()
    for role, check in pairs(roleChecks) do check:SetChecked(roles[SOLO_ROLE_KEYS[role]] == true) end
  end
  local activities = state.listingCategoryID and LFGSearch.Activities(state.listingCategoryID) or {}
  local activityName = nameOf(activities, state.listingActivityID)
  listingStatus:SetText(entry and string.format(L.LFG_LISTING_ACTIVE, activityName or "?") or L.LFG_LISTING_NONE)
  listingNotice:SetText(canEdit and "" or L.LFG_LEADER_ONLY)
  retext(listingCategory, nameOf(LFGSearch.Categories(), state.listingCategoryID) or L.LFG_CATEGORY)
  retext(listingActivity, activityName or L.LFG_ACTIVITY)
  roleLabel:SetText(L.LFG_ROLES_SOLO)
  for _, role in ipairs(ROLE_ORDER) do roleChecks[role].label:SetText(L[LFGTooltip.ROLE_TEXTS[role]]) end
  newPlayerCheck.label:SetText(L.LFG_NEW_PLAYER_TOGGLE)
  retext(postButton, entry and L.LFG_UPDATE or L.LFG_POST)
  retext(unlistButton)
  postButton:SetEnabled(canEdit and state.listingActivityID ~= nil)
  unlistButton:SetEnabled(canEdit and entry ~= nil)
end)

parts.postButton, parts.unlistButton, parts.listingStatus = postButton, unlistButton, listingStatus
parts.newPlayerCheck, parts.roleChecks, parts.listingNotice = newPlayerCheck, roleChecks, listingNotice

ns.RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE", function()
  state.listingActivityID = nil
  if LFGWindow.IsShown() and state.tab == LFGWindow.TAB_LISTING then LFGWindow.Refresh() end
end)

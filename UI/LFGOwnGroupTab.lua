-- Reiter Eigene Gruppe des Gruppensuche-Fensters (UI/LFGWindow.lua), aufgebaut wie Blizzards Eintragsfenster
-- (Blizzard_LFGVanilla_Listing.xml): runde Rollenknöpfe mit Haken (Tank, Heiler, Schaden) und Einsteigerfreundlich-Knopf
-- (Anführer-Symbol), Spielstil-Auswahl, "Alle Stufen anzeigen", Kategorie, Aktivitätsliste mit Haken und Level-Spanne
-- (nach Level absteigend), Voicechat, Zurück / Austragen / Eintragen. Mehrfachauswahl wie bei Blizzard.
-- Den Kommentar kann nur Blizzards gesichertes Eingabefeld setzen; ein eigenes Feld würde nicht gelesen.
-- Eintragen läuft nur aus dem Klick des eigenen Knopfs (Hardware-Ereignis, kein Taint).
local _, ns = ...
if not ns.Client.IsForever() then return end

local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme
local LFGSearch = ns.LFGSearch
local LFGTooltip = ns.LFGTooltip
local LFGWindow = ns.LFGWindow

local GAP = LFGWindow.GAP
local ROLE_ORDER, SOLO_ROLE_KEYS = LFGWindow.ROLE_ORDER, LFGWindow.SOLO_ROLE_KEYS
local newButton, retext = LFGWindow.NewButton, LFGWindow.Retext
local nameOf = LFGWindow.NameOf
local state = LFGWindow.State()
local parts = LFGWindow.Parts()
local listingTab = LFGWindow.listingContainer

local SIDE = 20                    -- Rand links und rechts
local ROLES_BOTTOM = 127           -- Unterkante des Rollenbereichs (Blizzard: -127)
local ROLE_SIZE, ROLE_STEP = 64, 104
local LEADER_SIZE = 84
local ROW_HEIGHT, VISIBLE_ROWS = 22, 12
local LIST_TOP = 218
local SCROLLBAR_SPACE = 14
local ROLE_ATLAS_NAMES = { TANK = "Tank", HEALER = "Healer", DAMAGER = "DPS" }
local FONT_TRIVIAL, FONT_DIFFICULT = "LFGActivityEntryTrivial", "LFGActivityEntryDifficult"  -- Blizzards Schriftfarben

local enum = Enum or {}
local PLAYSTYLE_ORDER = enum.LFGEntryGeneralPlaystyle and { enum.LFGEntryGeneralPlaystyle.Learning,
  enum.LFGEntryGeneralPlaystyle.FunRelaxed, enum.LFGEntryGeneralPlaystyle.FunSerious,
  enum.LFGEntryGeneralPlaystyle.Expert } or {}
local VOICE_NONE = enum.LFGEntryVoiceMode and enum.LFGEntryVoiceMode.None
local VOICE_LEGACY = enum.LFGEntryVoiceMode and enum.LFGEntryVoiceMode.Legacy

---------------------------------------------------------------------------
-- Hintergründe (Atlanten aus Blizzards Eintragsfenster)
---------------------------------------------------------------------------
local rolesBackground = listingTab:CreateTexture(nil, "BACKGROUND")
rolesBackground:SetAtlas("groupfinder-roles-background")
rolesBackground:SetPoint("TOPLEFT", 2, -25)
rolesBackground:SetPoint("TOPRIGHT", -2, -25)
rolesBackground:SetHeight(ROLES_BOTTOM - 25)
local listBackground = listingTab:CreateTexture(nil, "BACKGROUND")
listBackground:SetAtlas("groupfinder-background")
listBackground:SetPoint("TOPLEFT", 6, -ROLES_BOTTOM)
listBackground:SetPoint("BOTTOMRIGHT", -6, 4)

---------------------------------------------------------------------------
-- Rollen und Einsteigerfreundlich: runde Knöpfe mit Haken
---------------------------------------------------------------------------
local function newRoundButton(size, atlas, backgroundAtlas)
  local button = CreateFrame("Button", nil, listingTab)
  button:SetSize(size, size)
  if backgroundAtlas then
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAtlas(backgroundAtlas, true)
    background:SetPoint("CENTER")
  end
  if button.SetNormalAtlas then button:SetNormalAtlas(atlas) end
  local check = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
  check:SetSize(24, 24)
  check:SetPoint("BOTTOMLEFT", -5, -5)
  button:SetScript("OnClick", function() check:SetChecked(not check:GetChecked()) end)
  return button, check
end

local roleChecks = {}
for index, role in ipairs(ROLE_ORDER) do
  local name = ROLE_ATLAS_NAMES[role]
  local button, check = newRoundButton(ROLE_SIZE, "UI-LFG-RoleIcon-" .. name, "UI-LFG-RoleIcon-" .. name .. "-Background")
  button:SetPoint("TOPLEFT", 40 + (index - 1) * ROLE_STEP, -41)
  Widgets.AttachTooltip(button, function() return L[LFGTooltip.ROLE_TEXTS[role]] end,
    function() return L.LFG_ROLES_SOLO_TIP end)
  roleChecks[role] = check
end

local newPlayerButton, newPlayerCheck = newRoundButton(LEADER_SIZE, "UI-LFG-RoleIcon-Leader")
newPlayerButton:SetPoint("TOPRIGHT", -12, -30)
local newPlayerBadge = newPlayerButton:CreateTexture(nil, "OVERLAY")
newPlayerBadge:SetAtlas("newplayerchat-chaticon-newcomer")
newPlayerBadge:SetSize(20, 20)
newPlayerBadge:SetPoint("TOPRIGHT", -8, -7)
newPlayerCheck:ClearAllPoints()
newPlayerCheck:SetPoint("BOTTOMLEFT", 6, 5)
Widgets.AttachTooltip(newPlayerButton, function() return L.LFG_NEW_PLAYER_TOGGLE end,
  function() return L.LFG_NEW_PLAYER_TOGGLE_TIP end)

---------------------------------------------------------------------------
-- Status, Spielstil, Alle Stufen, Kategorie
---------------------------------------------------------------------------
local listingStatus = listingTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
listingStatus:SetPoint("TOPLEFT", SIDE, -(ROLES_BOTTOM + 8))
listingStatus:SetJustifyH("LEFT")

local function playstyleLabel(playstyle)
  return GetGeneralPlaystyleString and GetGeneralPlaystyleString(playstyle) or tostring(playstyle)
end

local playstyleDropdown = LFGWindow.NewDropdown(listingTab, 210, function()
  local entries = {}
  for _, playstyle in ipairs(PLAYSTYLE_ORDER) do table.insert(entries, { key = playstyle, text = playstyleLabel(playstyle) }) end
  return entries
end, function() return state.playstyle end, function(playstyle)
  state.playstyle = playstyle
  LFGWindow.Refresh()
end)
playstyleDropdown:SetPoint("TOPLEFT", SIDE, -(ROLES_BOTTOM + 28))
Widgets.AttachTooltip(playstyleDropdown, function() return L.LFG_PLAYSTYLE end, function() return L.LFG_PLAYSTYLE_TIP end)

local allLevelsCheck = LFGWindow.NewCheck(listingTab, "LFG_ALL_LEVELS", function(checked)
  state.showAllLevels, state.listingOffset = checked, 0
  LFGWindow.Refresh()
end)
allLevelsCheck:SetPoint("TOPRIGHT", -SIDE, -(ROLES_BOTTOM + 26))
allLevelsCheck.label:ClearAllPoints()
allLevelsCheck.label:SetPoint("RIGHT", allLevelsCheck, "LEFT", -2, 0)
allLevelsCheck.label:SetFontObject("GameFontNormalSmall")

local categoryDropdown = LFGWindow.NewDropdown(listingTab, 240, function()
  return LFGWindow.EntriesOf(LFGSearch.Categories())
end, function() return state.listingCategoryID end, function(id)
  state.listingCategoryID, state.listingActivities, state.listingOffset = id, {}, 0
  LFGWindow.Refresh()
end)
categoryDropdown:SetPoint("TOPLEFT", SIDE, -(ROLES_BOTTOM + 62))
Widgets.AttachTooltip(categoryDropdown, function() return L.LFG_CATEGORY end, function() return L.LFG_CATEGORY_TIP end)

---------------------------------------------------------------------------
-- Aktivitätsliste mit Haken, Level-Spanne rechts, Bildlaufleiste
---------------------------------------------------------------------------
local ROW_WIDTH = LFGWindow.WIDTH - 2 * SIDE - SCROLLBAR_SPACE
local rows = {}
parts.activityRows = rows

local function selectedIDs()
  local ids = {}
  for _, activity in ipairs(state.listingCategoryID and LFGSearch.Activities(state.listingCategoryID) or {}) do
    if state.listingActivities[activity.id] then table.insert(ids, activity.id) end
  end
  return ids
end

local function setSelected(activityID, selected)
  state.listingActivities[activityID] = selected or nil
  LFGWindow.Refresh()
end

local function createRow(index)
  local row = CreateFrame("Button", nil, listingTab)
  row:SetSize(ROW_WIDTH, ROW_HEIGHT)
  row:SetPoint("TOPLEFT", SIDE, -(LIST_TOP + (index - 1) * ROW_HEIGHT))
  row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
  row.check:SetSize(26, 26)
  row.check:SetPoint("LEFT", 4, 0)
  row.level = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.level:SetPoint("RIGHT", -4, 0)
  row.level:SetJustifyH("RIGHT")
  row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.name:SetPoint("LEFT", row.check, "RIGHT", 2, 0)
  row.name:SetPoint("RIGHT", row.level, "LEFT", -8, 0)
  row.name:SetJustifyH("LEFT")
  row.name:SetWordWrap(false)
  row.check:SetScript("OnClick", function(self) setSelected(row.activityID, self:GetChecked() and true) end)
  row:SetScript("OnClick", function() setSelected(row.activityID, not state.listingActivities[row.activityID]) end)
  row:HookScript("OnEnter", function() row.check:LockHighlight() end)
  row:HookScript("OnLeave", function() row.check:UnlockHighlight() end)
  rows[index] = row
  return row
end

-- Blizzards Schriftfarben: zu niedrig grau, zu hoch rot
local function levelFont(activity)
  local level = UnitLevel("player")
  return (activity.maxLevel ~= 0 and activity.maxLevel < level) and FONT_TRIVIAL
    or ((activity.minLevel ~= 0 and activity.minLevel > level) and FONT_DIFFICULT) or "GameFontNormal"
end

-- Sichtbare Aktivitäten: nach Level absteigend; ohne "Alle Stufen" nur passende und bereits gewählte
local function visibleActivities()
  local list = state.listingCategoryID and LFGSearch.Activities(state.listingCategoryID) or {}
  if state.showAllLevels then return list end
  local level, shown = UnitLevel("player"), {}
  for _, activity in ipairs(list) do
    if LFGSearch.ActivityFits(activity, level) or state.listingActivities[activity.id] then table.insert(shown, activity) end
  end
  return shown
end

local scrollBar
local function scrollTo(offset)
  state.listingOffset = offset
  LFGWindow.Refresh()
end
scrollBar = Widgets.CreateScrollBar(listingTab, scrollTo)
scrollBar:SetPoint("TOPRIGHT", -SIDE + 2, -LIST_TOP)
scrollBar:SetHeight(VISIBLE_ROWS * ROW_HEIGHT)
parts.listingScrollBar = scrollBar

listingTab:EnableMouseWheel(true)
listingTab:SetScript("OnMouseWheel", function(_, delta) scrollTo(state.listingOffset - delta) end)

local function refreshActivities()
  local list = visibleActivities()
  state.listingOffset = Widgets.ClampOffset(state.listingOffset, #list, VISIBLE_ROWS)
  for index = 1, VISIBLE_ROWS do
    local row, activity = rows[index] or createRow(index), list[state.listingOffset + index]
    row.activityID = activity and activity.id
    row:SetShown(activity ~= nil)
    if activity then
      row.name:SetFontObject(levelFont(activity))
      row.level:SetFontObject(levelFont(activity))
      row.name:SetText(activity.name)
      row.level:SetText(LFGWindow.LevelRange(activity.minLevel, activity.maxLevel))
      row.check:SetChecked(state.listingActivities[activity.id] == true)
    end
  end
  scrollBar:SetRange(math.max(0, #list - VISIBLE_ROWS))
  scrollBar:SetOffsetSilently(state.listingOffset)
end

---------------------------------------------------------------------------
-- Voicechat und Knöpfe
---------------------------------------------------------------------------
local voiceLabel = listingTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
local voiceDropdown = LFGWindow.NewDropdown(listingTab, 220, function()
  local entries = {}
  if VOICE_NONE then table.insert(entries, { key = VOICE_NONE, text = L.LFG_VOICE_NONE }) end
  if VOICE_LEGACY then table.insert(entries, { key = VOICE_LEGACY, text = L.LFG_VOICE_LEGACY }) end
  return entries
end, function() return state.voiceMode end, function(mode) state.voiceMode = mode end)
voiceDropdown:SetPoint("BOTTOMRIGHT", -SIDE, 56)
voiceLabel:SetPoint("RIGHT", voiceDropdown, "LEFT", -8, 0)
Widgets.AttachTooltip(voiceDropdown, function() return L.LFG_VOICE_CHAT end, function() return L.LFG_VOICE_CHAT_TIP end)

local listingNotice = listingTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
listingNotice:SetPoint("BOTTOMLEFT", SIDE, 88)
listingNotice:SetTextColor(Theme.RGB("warning"))

local backButton = newButton(listingTab, 111, "LFG_BACK", function() LFGWindow.SetTab(LFGWindow.TAB_SEARCH) end)
backButton:SetPoint("BOTTOMLEFT", 21, 16)
local postButton = newButton(listingTab, 109, "LFG_POST", function()
  local ids = selectedIDs()
  if #ids == 0 then return end
  local roles = {}
  for role, check in pairs(roleChecks) do roles[SOLO_ROLE_KEYS[role]] = check:GetChecked() and true or false end
  LFGSearch.Post({ activityIDs = ids, newPlayerFriendly = newPlayerCheck:GetChecked(), roles = roles,
    generalPlaystyle = state.playstyle, voiceMode = state.voiceMode })
end)
postButton:SetPoint("BOTTOMRIGHT", -21, 16)
local unlistButton = newButton(listingTab, 109, "LFG_UNLIST", function() LFGSearch.Unlist() end)
unlistButton:SetPoint("RIGHT", postButton, "LEFT", -GAP, 0)

-- Eigenen Eintrag (oder Soloaktionen) einmal in die Eingaben laden; nach LFG_LIST_ACTIVE_ENTRY_UPDATE erneut
local function loadFromEntry(entry)
  state.listingActivities = {}
  if entry then
    for _, activityID in ipairs(entry.activityIDs) do state.listingActivities[activityID] = true end
    state.listingCategoryID = entry.categoryID or state.listingCategoryID
    state.playstyle = entry.generalPlaystyle or state.playstyle
    state.voiceMode = entry.voiceMode
    newPlayerCheck:SetChecked(entry.newPlayerFriendly)
  end
  local roles = LFGSearch.GetRoles()
  for role, check in pairs(roleChecks) do check:SetChecked(roles[SOLO_ROLE_KEYS[role]] == true) end
  state.listingLoaded = true
end

-- Ein neuer Eintrag braucht einen Spielstil (wie bei Blizzard), sofern der Client Spielstile kennt
local function needsPlaystyle(entry)
  return entry == nil and #PLAYSTYLE_ORDER > 0 and not state.playstyle
end

LFGWindow.RegisterTab(LFGWindow.TAB_LISTING, function()
  local entry = LFGSearch.ActiveEntry()
  local canEdit = LFGSearch.CanEditListing()
  if not state.listingLoaded then loadFromEntry(entry) end
  if not state.listingCategoryID then
    local first = LFGSearch.Categories()[1]
    state.listingCategoryID = first and first.id
  end
  local ids = selectedIDs()
  local activityName = nameOf(LFGSearch.Activities(state.listingCategoryID or 0), ids[1])
  listingStatus:SetText(entry and string.format(L.LFG_LISTING_ACTIVE, activityName or "?") or L.LFG_LISTING_NONE)
  listingNotice:SetText(canEdit and "" or L.LFG_LEADER_ONLY)
  LFGWindow.RefreshDropdown(playstyleDropdown, L.LFG_PLAYSTYLE_REQUIRED)
  LFGWindow.RefreshDropdown(categoryDropdown, L.LFG_CATEGORY)
  LFGWindow.RefreshDropdown(voiceDropdown, L.LFG_VOICE_NONE)
  playstyleDropdown:SetShown(#PLAYSTYLE_ORDER > 0)
  voiceDropdown:SetShown(VOICE_NONE ~= nil)
  voiceLabel:SetShown(VOICE_NONE ~= nil)
  voiceLabel:SetText(L.LFG_VOICE_CHAT)
  allLevelsCheck.label:SetText(L.LFG_ALL_LEVELS)
  allLevelsCheck:SetChecked(state.showAllLevels)
  refreshActivities()
  retext(backButton)
  retext(postButton, entry and L.LFG_UPDATE or L.LFG_POST)
  retext(unlistButton)
  postButton:SetEnabled(canEdit and #ids > 0 and not needsPlaystyle(entry))
  unlistButton:SetEnabled(canEdit and entry ~= nil)
end)

parts.postButton, parts.unlistButton, parts.listingStatus, parts.backButton = postButton, unlistButton, listingStatus, backButton
parts.newPlayerCheck, parts.roleChecks, parts.listingNotice = newPlayerCheck, roleChecks, listingNotice
parts.playstyleDropdown, parts.categoryDropdown, parts.voiceDropdown = playstyleDropdown, categoryDropdown, voiceDropdown
parts.allLevelsCheck = allLevelsCheck

ns.RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE", function()
  state.listingLoaded = false
  if LFGWindow.IsShown() and state.tab == LFGWindow.TAB_LISTING then LFGWindow.Refresh() end
end)

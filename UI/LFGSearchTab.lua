-- Reiter Suchen des Gruppensuche-Fensters (UI/LFGWindow.lua): Kategorie und Aktivität (Blizzards Auswahlliste, nach
-- Level sortiert, mit Level-Spanne), Suchen-Knopf, "Passend für mich" (Aktivitäten und Gruppen nach Level),
-- seltene Filter unter "Weitere Filter" (Sprach-Chips, Gruppenart, aufgelöste Gruppen) und die Ergebnisliste mit
-- Bildlaufleiste; das Detail der gewählten Gruppe (Flüstern, Einladen) hängt als Seitenfenster rechts am Fenster.
-- Keine Bewerbungen: Forever nutzt Blizzards Vanilla-Stil, dort flüstert man dem Leiter oder lädt Einzelspieler ein.
local _, ns = ...
if not ns.Client.IsForever() then return end

local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme
local Format = ns.Format
local LFGSearch = ns.LFGSearch
local LFGData = ns.LFGData
local LFGTooltip = ns.LFGTooltip
local LFGWindow = ns.LFGWindow

local PAD, GAP, CONTROL_HEIGHT = LFGWindow.PAD, LFGWindow.GAP, LFGWindow.CONTROL_HEIGHT
local ROLE_ORDER, SOLO_ROLE_KEYS = LFGWindow.ROLE_ORDER, LFGWindow.SOLO_ROLE_KEYS
local newButton, newCheck, retext = LFGWindow.NewButton, LFGWindow.NewCheck, LFGWindow.Retext
local entriesOf = LFGWindow.EntriesOf
local state = LFGWindow.State()
local parts = LFGWindow.Parts()
local searchTab = LFGWindow.searchContainer

local FILTER_TOP = 34           -- unter dem Titel
local ROW_HEIGHT = 32
local VISIBLE_ROWS = 11
local DETAIL_WIDTH = 330
local SCROLLBAR_SPACE = 14      -- Bildlaufleiste (8) plus Abstand
local COLUMN_WIDTHS = { level = 78, roles = 96, age = 56 }
local LIST_GAP = 16              -- Abstand der Kopfzeile zur letzten Filterzeile (Trefferzahl steht darüber)
local CHIP_GAP = 4
local FILTER_WIDTH = LFGWindow.WIDTH - 2 * PAD
local WHEEL_STEP = 3
local ICON_SIZE = 18
local MAX_MEMBER_LINES = 10
local MAX_QUEST_LINES = 8
local FIT_ICON = { [LFGData.FITS] = "ReadyCheck-Ready", [LFGData.ABOVE] = "ReadyCheck-Waiting",
  [LFGData.BELOW] = "ReadyCheck-Waiting" }
local ROLE_ATLAS = { TANK = "groupfinder-icon-role-large-tank", HEALER = "groupfinder-icon-role-large-heal",
  DAMAGER = "groupfinder-icon-role-large-dps" }
local KIND_ORDER = { LFGSearch.KIND_ALL, LFGSearch.KIND_GROUPS, LFGSearch.KIND_SOLO }
local KIND_TEXTS = { all = "LFG_KIND_ALL", groups = "LFG_KIND_GROUPS", solo = "LFG_KIND_SOLO" }

local function colored(color, text) return Theme.Hex(color) .. text .. "|r" end
local function icon(atlas) return string.format("|A:%s:%d:%d|a", atlas, ICON_SIZE, ICON_SIZE) end
local function readyIcon(name) return string.format("|TInterface\\RaidFrame\\%s:%d|t", name, ICON_SIZE) end

local function levelRange(summary)
  return summary.levelLow == summary.levelHigh and tostring(summary.levelLow)
    or (summary.levelLow .. "-" .. summary.levelHigh)
end

---------------------------------------------------------------------------
-- Filterzeile
---------------------------------------------------------------------------
local categoryDropdown = LFGWindow.NewDropdown(searchTab, 150, function()
  return entriesOf(LFGSearch.Categories())
end, function() return state.categoryID end, function(id)
  state.categoryID, state.activityID = id, nil
  LFGWindow.Refresh()
end)
categoryDropdown:SetPoint("TOPLEFT", PAD, -FILTER_TOP)
Widgets.AttachTooltip(categoryDropdown, function() return L.LFG_CATEGORY end, function() return L.LFG_CATEGORY_TIP end)

-- Aktivitäten nach Level aufsteigend mit Level-Spanne; "Passend für mich" zeigt nur die zum Level passenden
local activityDropdown = LFGWindow.NewDropdown(searchTab, 210, function()
  local entries = LFGWindow.ActivityEntries(state.categoryID, state.fitOnly)
  table.insert(entries, 1, { key = 0, text = L.LFG_ALL_ACTIVITIES })
  return entries
end, function() return state.activityID or 0 end, function(id)
  state.activityID = id ~= 0 and id or nil
  LFGWindow.Refresh()
end)
activityDropdown:SetPoint("LEFT", categoryDropdown, "RIGHT", GAP, 0)
Widgets.AttachTooltip(activityDropdown, function() return L.LFG_ACTIVITY end, function() return L.LFG_ACTIVITY_TIP end)

local searchButton = newButton(searchTab, 90, "LFG_SEARCH_BUTTON", function()
  local activityIDs = state.activityID and { state.activityID }
  if not activityIDs and state.fitOnly then  -- Passend für mich: nur Aktivitäten, die zum Level passen
    local _, fitting = LFGWindow.ActivityEntries(state.categoryID, true)
    activityIDs = {}
    for _, activity in ipairs(fitting) do table.insert(activityIDs, activity.id) end
  end
  -- Zustand vor dem Aufruf setzen: das Ergebnisereignis kann schon während Search eintreffen
  state.status, state.offset, state.selected, state.results = "searching", 0, nil, {}
  if LFGSearch.Search(state.categoryID, activityIDs) then
    LFGWindow.Refresh()
  else
    state.status = "start"
  end
end)
searchButton:SetPoint("TOPRIGHT", -PAD, -FILTER_TOP)

local fitCheck = newCheck(searchTab, "LFG_FIT_ONLY", function(checked)
  state.fitOnly, state.offset = checked, 0
  local chosen = state.activityID and LFGWindow.ActivityOf(state.categoryID, state.activityID)
  if checked and chosen and not LFGSearch.ActivityFits(chosen, UnitLevel("player")) then state.activityID = nil end
  LFGWindow.Refresh()
end)
fitCheck:SetPoint("TOPLEFT", categoryDropdown, "BOTTOMLEFT", 0, -GAP)
local moreButton = newButton(searchTab, 150, "LFG_MORE_FILTERS", function()
  state.moreOpen = not state.moreOpen
  LFGWindow.Refresh()
end)
moreButton:SetPoint("TOPRIGHT", searchButton, "BOTTOMRIGHT", 0, -GAP)

-- Weitere Filter unter der zweiten Zeile: Sprachen (Chips brechen bei Platzmangel um), darunter Gruppenart und
-- aufgelöste Gruppen. Jede Zeile hängt an der Unterkante der vorigen, die Höhe folgt aus dem Inhalt.
local morePanel = CreateFrame("Frame", nil, searchTab)
morePanel:SetWidth(FILTER_WIDTH)
morePanel:SetPoint("TOPRIGHT", moreButton, "BOTTOMRIGHT", 0, -GAP)
local languageLabel = morePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
local languageChips = {}
local kindButton = newButton(morePanel, 120, "LFG_KIND", function()
  for index, kind in ipairs(KIND_ORDER) do
    if kind == state.kind then state.kind = KIND_ORDER[index % #KIND_ORDER + 1]; break end
  end
  state.offset = 0
  LFGWindow.Refresh()
end)
local delistedCheck = newCheck(morePanel, "LFG_HIDE_DELISTED", function(checked)
  state.hideDelisted, state.offset = checked, 0
  LFGWindow.Refresh()
end)

local function languageChip(index)
  if not languageChips[index] then
    local chip
    chip = Widgets.CreateChip(morePanel, "", function()
      LFGSearch.ToggleLanguage(chip.code)
      LFGWindow.Refresh()
    end)
    Widgets.AttachTooltip(chip, function() return L.LFG_LANGUAGES end, function() return L.LFG_LANGUAGE_CHIP_TIP end)
    languageChips[index] = chip
  end
  return languageChips[index]
end

-- Chips rechts neben der Beschriftung (Breite gemessen, fr/es länger), Umbruch auf eine neue Zeile unter der vorigen
local function layoutLanguages()
  languageLabel:SetText(L.LFG_LANGUAGES)
  local left = math.ceil(languageLabel:GetStringWidth()) + GAP
  local x, y, chipHeight = left, 0, 0
  for index, language in ipairs(LFGSearch.Languages()) do
    local chip = languageChip(index)
    chip.code = language.code
    chip:Show()
    chip:SetText(language.code:sub(1, 2):upper())
    chip:SetOn(language.enabled)
    chipHeight = chip:GetHeight()
    if x > left and x + chip:GetWidth() > FILTER_WIDTH then x, y = left, y + chipHeight + CHIP_GAP end
    chip:ClearAllPoints()
    chip:SetPoint("TOPLEFT", morePanel, "TOPLEFT", x, -y)
    x = x + chip:GetWidth() + CHIP_GAP
  end
  for index = #LFGSearch.Languages() + 1, #languageChips do languageChips[index]:Hide() end
  languageLabel:ClearAllPoints()
  languageLabel:SetPoint("LEFT", morePanel, "TOPLEFT", 0, -chipHeight / 2)
  return math.max(y + chipHeight, languageLabel:GetStringHeight() or 0)
end

local function layoutMore()
  local languagesHeight = layoutLanguages()
  retext(kindButton, string.format("%s: %s", L.LFG_KIND, L[KIND_TEXTS[state.kind]]))
  kindButton:ClearAllPoints()
  kindButton:SetPoint("TOPLEFT", morePanel, "TOPLEFT", 0, -(languagesHeight + GAP))
  morePanel:SetHeight(languagesHeight + GAP + CONTROL_HEIGHT)
  delistedCheck.label:SetText(L.LFG_HIDE_DELISTED)
  delistedCheck:SetChecked(state.hideDelisted)
  delistedCheck:ClearAllPoints()
  delistedCheck:SetPoint("LEFT", kindButton, "RIGHT", GAP, 0)
end

-- Zahl der aktiven weiteren Filter (Abweichungen vom Standard)
local function activeExtraFilters()
  local count = LFGSearch.ExtraLanguages()
  if state.kind ~= LFGSearch.KIND_ALL then count = count + 1 end
  if not state.hideDelisted then count = count + 1 end
  return count
end

---------------------------------------------------------------------------
-- Liste mit Bildlaufleiste
---------------------------------------------------------------------------
local listWidth = LFGWindow.WIDTH - 2 * PAD - SCROLLBAR_SPACE
local header = CreateFrame("Frame", nil, searchTab)
header:SetSize(listWidth, 20)
local headerCells = {}
local function headerCell(key, width, justify)
  local cell = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  cell.key = key
  cell:SetJustifyH(justify or "LEFT")
  if width then cell:SetWidth(width) end
  headerCells[#headerCells + 1] = cell
  return cell
end
local ageHeader = headerCell("LFG_COL_AGE", COLUMN_WIDTHS.age, "RIGHT")
ageHeader:SetPoint("RIGHT", header, "RIGHT", -4, 0)
local rolesHeader = headerCell("LFG_COL_ROLES", COLUMN_WIDTHS.roles)
rolesHeader:SetPoint("RIGHT", ageHeader, "LEFT", -8, 0)
local levelHeader = headerCell("LFG_COL_LEVEL", COLUMN_WIDTHS.level)
levelHeader:SetPoint("RIGHT", rolesHeader, "LEFT", -8, 0)
local titleHeader = headerCell("LFG_COL_TITLE")
titleHeader:SetPoint("LEFT", header, "LEFT", 8, 0)
titleHeader:SetPoint("RIGHT", levelHeader, "LEFT", -8, 0)
local countText = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
countText:SetPoint("BOTTOMRIGHT", header, "TOPRIGHT", -4, 2)
countText:SetTextColor(Theme.RGB("muted"))

local rows = {}
parts.rows = rows
local function createRow(index)
  local row = Widgets.CreateListRow(searchTab, ROW_HEIGHT)
  row:SetWidth(listWidth)
  row.age = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.age:SetWidth(COLUMN_WIDTHS.age)
  row.age:SetJustifyH("RIGHT")
  row.age:SetPoint("RIGHT", -4, 0)
  row.roles = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.roles:SetWidth(COLUMN_WIDTHS.roles)
  row.roles:SetJustifyH("LEFT")
  row.roles:SetPoint("RIGHT", row.age, "LEFT", -8, 0)
  row.level = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.level:SetWidth(COLUMN_WIDTHS.level)
  row.level:SetJustifyH("LEFT")
  row.level:SetPoint("RIGHT", row.roles, "LEFT", -8, 0)
  row.title = row.text  -- Titel in der oberen Zeile, darunter der Kommentar
  row.title:ClearAllPoints()
  row.title:SetPoint("TOPLEFT", 8, -4)
  row.title:SetPoint("RIGHT", row.level, "LEFT", -8, 0)
  row.title:SetWordWrap(false)
  row.comment = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.comment:SetPoint("BOTTOMLEFT", 8, 4)
  row.comment:SetPoint("RIGHT", row.level, "LEFT", -8, 0)
  row.comment:SetJustifyH("LEFT")
  row.comment:SetWordWrap(false)
  row.comment:SetTextColor(Theme.RGB("muted"))
  row:SetScript("OnClick", function(self)
    state.selected = self.resultID
    LFGWindow.Refresh()
  end)
  row:HookScript("OnEnter", function(self)
    if not self.summary then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.title:GetText() or "", Theme.RGB("accent"))
    if self.summary.comment and self.summary.comment ~= "" then GameTooltip:AddLine(self.summary.comment, 1, 1, 1, true) end
    GameTooltip:Show()
  end)
  row:HookScript("OnLeave", function() GameTooltip:Hide() end)
  rows[index] = row
  return row
end

local function rolesText(summary)
  local member = summary.members[1]
  local texts = {}
  if summary.numMembers == 1 and member and member.lfgRoles then
    for _, role in ipairs(ROLE_ORDER) do
      if member.lfgRoles[SOLO_ROLE_KEYS[role]] then table.insert(texts, icon(ROLE_ATLAS[role])) end
    end
  elseif summary.open then
    for _, role in ipairs(ROLE_ORDER) do
      local missing = summary.open[role]
      if missing and missing > 0 then table.insert(texts, missing .. icon(ROLE_ATLAS[role])) end
    end
    if #texts == 0 and summary.open.free > 0 then texts[1] = "+" .. summary.open.free end
  end
  return table.concat(texts, " ")
end

local function levelText(summary)
  if not summary.levelLow then return "" end
  local symbol = ""
  if summary.delisted or summary.noXpLow then symbol = readyIcon("ReadyCheck-NotReady")
  elseif FIT_ICON[summary.fit] then symbol = readyIcon(FIT_ICON[summary.fit]) end
  return symbol .. " " .. levelRange(summary)
end

local function titleOf(summary)
  local name = summary.title ~= "" and summary.title or nil
  local activity = summary.activityNames[1] or "?"
  if #summary.activityNames > 1 then activity = string.format("%s +%d", activity, #summary.activityNames - 1) end
  return (name or activity) .. (summary.leaderName and (" - " .. summary.leaderName) or "")
end

local function fillRow(row, summary)
  row.summary, row.resultID = summary, summary and summary.resultID
  row:SetShown(summary ~= nil)
  if not summary then return end
  row.title:SetText(titleOf(summary))
  row.comment:SetText(summary.comment or "")
  row.level:SetText(levelText(summary))
  row.roles:SetText(rolesText(summary))
  row.age:SetText(summary.age and Format.Duration(summary.age) or "")
  row.title:SetTextColor(Theme.RGB(summary.delisted and "muted" or "accent"))  -- RGB liefert drei Werte: nie in and/or
  row:SetSelected(summary.resultID == state.selected)
end

local scrollBar
local refreshList

local function scrollTo(offset)
  state.offset = offset
  refreshList()
end

scrollBar = Widgets.CreateScrollBar(searchTab, scrollTo)

-- Zeilen und Leiste hängen am Kopf, der Kopf an der letzten sichtbaren Filterzeile (mit oder ohne Weitere Filter)
for index = 1, VISIBLE_ROWS do
  createRow(index):SetPoint("TOPLEFT", rows[index - 1] or header, "BOTTOMLEFT", 0, 0)
end
scrollBar:SetPoint("TOPLEFT", header, "BOTTOMRIGHT", SCROLLBAR_SPACE - 8, 0)
scrollBar:SetHeight(VISIBLE_ROWS * ROW_HEIGHT)

local function layoutList()
  header:ClearAllPoints()
  header:SetPoint("TOPRIGHT", state.moreOpen and morePanel or moreButton, "BOTTOMRIGHT", -SCROLLBAR_SPACE, -LIST_GAP)
end

local emptyText = searchTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
emptyText:SetPoint("TOP", header, "BOTTOM", 0, -48)
emptyText:SetWidth(listWidth - 2 * PAD)
emptyText:SetTextColor(Theme.RGB("muted"))
parts.emptyText = emptyText

function refreshList()
  layoutList()
  for _, cell in ipairs(headerCells) do cell:SetText(L[cell.key]) end
  local total = #state.results
  state.offset = Widgets.ClampOffset(state.offset, total, VISIBLE_ROWS)
  for index = 1, VISIBLE_ROWS do fillRow(rows[index], state.results[state.offset + index]) end
  scrollBar:SetRange(math.max(0, total - VISIBLE_ROWS))
  scrollBar:SetOffsetSilently(state.offset)
  countText:SetText(total > 0 and string.format(L.LFG_COUNT, total) or "")
  local message = (total == 0) and L[({ start = "LFG_STATE_START", searching = "LFG_STATE_SEARCHING",
    failed = "LFG_STATE_FAILED", done = "LFG_STATE_NONE" })[state.status]] or ""
  emptyText:SetText(message)
end

searchTab:EnableMouseWheel(true)
searchTab:SetScript("OnMouseWheel", function(_, delta)
  scrollTo(state.offset - delta * WHEEL_STEP)
end)

---------------------------------------------------------------------------
-- Detail rechts
---------------------------------------------------------------------------
-- Seitenfenster rechts am Fenster (wie Blizzards Seitenfenster), nur sichtbar, solange eine Gruppe gewählt ist
local DETAIL_TOP = 34           -- unter dem Titel des Seitenfensters
local detail = CreateFrame("Frame", nil, LFGWindow.panel, "PortraitFrameTemplate")
detail:SetSize(DETAIL_WIDTH, LFGWindow.HEIGHT)
detail:SetPoint("TOPLEFT", LFGWindow.panel, "TOPRIGHT", -2, 0)
if detail.SetPortraitShown then detail:SetPortraitShown(false) end
if type(detail.CloseButton) == "table" then
  detail.CloseButton:SetScript("OnClick", function()
    state.selected = nil
    LFGWindow.Refresh()
  end)
end
detail:Hide()
parts.detail = detail

-- Kennzahlen als Label-Wert-Zeilen über dem Text: Level, offene Rollen, Alter
local DETAIL_FIELD_HEIGHT = 20
local detailFields = {}
for _, key in ipairs({ "level", "open", "age" }) do
  local line = Widgets.CreateLabelValue(detail)
  line:SetHeight(DETAIL_FIELD_HEIGHT)
  line:SetPoint("LEFT", 12, 0)
  line:SetPoint("RIGHT", -12, 0)
  detailFields[key] = line
end
parts.detailFields = detailFields

local detailText = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
detailText:SetPoint("RIGHT", -12, 0)
detailText:SetJustifyH("LEFT")
detailText:SetJustifyV("TOP")
detailText:SetSpacing(2)
parts.detailText = detailText

local whisperButton = newButton(detail, 100, "LFG_WHISPER", function()
  local summary = state.selected and LFGSearch.Summary(state.selected)
  if not (summary and summary.leaderName) then return end
  if ChatFrameUtil and ChatFrameUtil.SendTell then ChatFrameUtil.SendTell(summary.leaderName)
  elseif ChatFrame_SendTell then ChatFrame_SendTell(summary.leaderName) end
end)
whisperButton:SetPoint("BOTTOMLEFT", 12, 12)
local inviteButton = newButton(detail, 100, "LFG_INVITE", function()
  local summary = state.selected and LFGSearch.Summary(state.selected)
  if LFGSearch.CanInvite(summary) then C_PartyInfo.InviteUnit(summary.leaderName) end
end)
inviteButton:SetPoint("LEFT", whisperButton, "RIGHT", GAP, 0)

local function memberLine(member)
  local color = Theme.ClassColor(member.class, { 1, 1, 1 })
  local name = string.format("|cff%02x%02x%02x%s|r", color[1] * 255, color[2] * 255, color[3] * 255, member.name or "?")
  local role = LFGTooltip.ROLE_TEXTS[member.role] and (" - " .. L[LFGTooltip.ROLE_TEXTS[member.role]]) or ""
  local where = (member.level and tostring(member.level) or "?") .. (member.area and (" · " .. member.area) or "")
  return string.format("%s%s  %s", name, role, colored("muted", where))
end

local function questLine(quest)
  local state_ = L[LFGTooltip.QUEST_STATE_TEXTS[quest.state]]
  local text = quest.takeable and state_ or (state_ .. ", " .. L.LFG_QUEST_NOT_TAKEABLE)
  local symbol = quest.state == LFGData.BOSS_DEAD and readyIcon("ReadyCheck-NotReady")
    or (quest.state == LFGData.DOABLE and readyIcon("ReadyCheck-Ready") or readyIcon("ReadyCheck-Waiting"))
  return string.format("%s %s - %s", symbol, quest.title or tostring(quest.questID),
    colored(LFGTooltip.QUEST_STATE_COLORS[quest.state], text))
end

local function detailLines(summary)
  local lines = { colored("accent", titleOf(summary)) }
  local function add(text) table.insert(lines, text) end
  if summary.comment and summary.comment ~= "" then add(summary.comment) end
  if summary.delisted then add(colored("bad", readyIcon("ReadyCheck-NotReady") .. " " .. L.LFG_DELISTED)) end
  if summary.noXpLow then
    add(colored("bad", readyIcon("ReadyCheck-NotReady") .. " " .. string.format(L.LFG_NO_XP, summary.noXpLow, summary.noXpHigh)))
  end
  add("")
  add(colored("muted", string.format(L.LFG_MEMBERS, summary.numMembers or #summary.members)))
  for index = 1, math.min(#summary.members, MAX_MEMBER_LINES) do add(memberLine(summary.members[index])) end
  if #summary.killedBosses > 0 then
    add(colored("muted", string.format(L.LFG_BOSSES_KILLED, table.concat(summary.killedBosses, ", "))))
  end
  if #summary.quests > 0 then
    add("")
    add(colored("info", string.format(L.LFG_QUESTS, #summary.quests)))
    for index = 1, math.min(#summary.quests, MAX_QUEST_LINES) do add(questLine(summary.quests[index])) end
  end
  if summary.friends + summary.guild > 0 then add(colored("success", string.format(L.LFG_SOCIAL, summary.friends, summary.guild))) end
  local flags = {}
  if summary.newPlayerFriendly then table.insert(flags, L.LFG_NEW_PLAYER) end
  if summary.autoAccept then table.insert(flags, L.LFG_AUTO_ACCEPT) end
  if summary.crossFaction then table.insert(flags, L.LFG_CROSS_FACTION) end
  if summary.requiredItemLevel and summary.requiredItemLevel > 0 then
    table.insert(flags, string.format(L.LFG_ITEM_LEVEL, summary.requiredItemLevel))
  end
  if summary.voiceChat and summary.voiceChat ~= "" then table.insert(flags, string.format(L.LFG_VOICE, summary.voiceChat)) end
  if #flags > 0 then add(""); add(colored("muted", table.concat(flags, " · "))) end
  return lines
end

-- Werte der Kennzahlen (leer = Zeile ausgeblendet)
local function detailFieldValues(summary)
  local level, open
  if summary.levelLow then
    local fit = summary.fit and string.format(L[LFGTooltip.FIT_TEXTS[summary.fit]], summary.ownLevel) or ""
    level = levelRange(summary) .. "  " .. colored(LFGTooltip.FIT_COLORS[summary.fit] or "muted", fit)
  end
  open = summary.open and LFGTooltip.OpenRolesText(summary.open)
  return { level = level, open = open ~= "" and open or nil, age = summary.age and Format.Duration(summary.age) or nil }
end

local DETAIL_FIELDS = { { "level", "LFG_COL_LEVEL" }, { "open", "LFG_COL_ROLES" }, { "age", "LFG_COL_AGE" } }

local function refreshDetail()
  local summary = state.selected and LFGSearch.Summary(state.selected)
  detail:SetShown(summary ~= nil)
  if summary and detail.SetTitle then detail:SetTitle(titleOf(summary)) end
  retext(whisperButton)
  retext(inviteButton)
  whisperButton:SetEnabled(summary ~= nil and summary.leaderName ~= nil and not summary.delisted)
  inviteButton:SetEnabled(LFGSearch.CanInvite(summary))
  local values = summary and detailFieldValues(summary) or {}
  local previous
  for _, field in ipairs(DETAIL_FIELDS) do
    local line, value = detailFields[field[1]], values[field[1]]
    line:SetShown(value ~= nil)
    if value then
      line:SetValues(L[field[2]], value)
      line:ClearAllPoints()
      line:SetPoint("TOPLEFT", previous or detail, previous and "BOTTOMLEFT" or "TOPLEFT", previous and 0 or 12,
        previous and 0 or -DETAIL_TOP)
      line:SetPoint("RIGHT", -12, 0)
      previous = line
    end
  end
  detailText:ClearAllPoints()
  detailText:SetPoint("TOPLEFT", previous or detail, previous and "BOTTOMLEFT" or "TOPLEFT", previous and 0 or 12,
    previous and -8 or -DETAIL_TOP)
  detailText:SetPoint("RIGHT", -12, 0)
  if summary then detailText:SetText(table.concat(detailLines(summary), "\n")) end
end

---------------------------------------------------------------------------
-- Anzeige und Ereignisse
---------------------------------------------------------------------------
LFGWindow.RegisterTab(LFGWindow.TAB_SEARCH, function()
  if not state.categoryID then
    local first = LFGSearch.Categories()[1]
    state.categoryID = first and first.id
  end
  LFGWindow.RefreshDropdown(categoryDropdown, L.LFG_CATEGORY)
  LFGWindow.RefreshDropdown(activityDropdown, L.LFG_ALL_ACTIVITIES)
  fitCheck.label:SetText(L.LFG_FIT_ONLY)
  fitCheck:SetChecked(state.fitOnly)
  retext(searchButton)
  retext(moreButton, string.format(L.LFG_MORE_FILTERS, activeExtraFilters()))
  morePanel:SetShown(state.moreOpen)
  if state.moreOpen then layoutMore() end
  if state.status == "done" or state.status == "failed" or state.status == "start" then
    state.results = state.status == "done"
      and LFGSearch.Results({ kind = state.kind, hideDelisted = state.hideDelisted, fitOnly = state.fitOnly }) or {}
  end
  refreshList()
  refreshDetail()
end)

parts.searchButton, parts.whisperButton, parts.inviteButton = searchButton, whisperButton, inviteButton
parts.categoryDropdown, parts.activityDropdown = categoryDropdown, activityDropdown
parts.fitCheck, parts.moreButton, parts.kindButton = fitCheck, moreButton, kindButton
parts.scrollBar, parts.languageChips, parts.languageLabel = scrollBar, languageChips, languageLabel
parts.morePanel, parts.header, parts.delistedCheck = morePanel, header, delistedCheck

local function refreshIfShown()
  if LFGWindow.IsShown() then LFGWindow.Refresh() end
end
ns.RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED", function()
  state.status = "done"
  refreshIfShown()
end)
ns.RegisterEvent("LFG_LIST_SEARCH_FAILED", function()
  state.status = "failed"
  refreshIfShown()
end)
ns.RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED", function(resultID)
  LFGSearch.Invalidate(resultID)
  if state.tab == LFGWindow.TAB_SEARCH then refreshIfShown() end
end)

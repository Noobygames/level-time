-- Reiter Suchen des Gruppensuche-Fensters (UI/LFGWindow.lua): Kategorie und Aktivität (Blizzards Auswahlliste, nach
-- Level sortiert, mit Level-Spanne), Suchen-Knopf, "Passend für mich" (Aktivitäten und Gruppen nach Level),
-- seltene Filter unter "Weitere Filter" (eigene Ansicht an Stelle der Liste, UI/LFGFilterView.lua) und die Ergebnisliste
-- mit Bildlaufleiste; Flüstern und Einladen unten im Fenster, das Detail der gewählten Gruppe hängt als Seitenfenster rechts.
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
local LFGFilters = ns.LFGFilters

local PAD, GAP = LFGWindow.PAD, LFGWindow.GAP
local ROLE_ORDER, SOLO_ROLE_KEYS = LFGWindow.ROLE_ORDER, LFGWindow.SOLO_ROLE_KEYS
local newButton, newCheck, retext = LFGWindow.NewButton, LFGWindow.NewCheck, LFGWindow.Retext
local entriesOf = LFGWindow.EntriesOf
local state = LFGWindow.State()
local parts = LFGWindow.Parts()
local searchTab = LFGWindow.searchContainer

local SEARCH_TIMEOUT = 15        -- Sekunden ohne Antwort, dann gilt die Suche als gescheitert (erneut suchen möglich)
local FILTER_TOP = 60           -- unter dem Porträtring (der überdeckte bei 34 den Anfang der Kategorie)
local CARD_HEIGHT = 76          -- Blizzards LFGBrowseNestedSearchEntryTemplate (72) plus Abstand zur nächsten Karte
local CARD_GAP = 4
local SECTION_HEIGHT = 36       -- Blizzards LFGBrowseSearchEntryGroupingTemplate
local LIST_HEIGHT = 352          -- Höhe der Liste (wie zuvor 11 Zeilen zu 32)
local DETAIL_WIDTH = 330
local SCROLLBAR_SPACE = 14      -- Bildlaufleiste (8) plus Abstand
local COLUMN_WIDTHS = { age = 56 }
local LIST_GAP = 16              -- Abstand der Kopfzeile zur letzten Filterzeile (Trefferzahl steht darüber)
local WHEEL_STEP = 3
local ICON_SIZE = 18
local ROLE_ICON_SIZE = 27       -- wie Blizzards Rollen-Symbole je Platz (LFGVanillaListGroupDataDisplayTemplate)
local MAX_MEMBER_LINES = 10
local MAX_QUEST_LINES = 8
local FIT_ICON = { [LFGData.FITS] = "ReadyCheck-Ready", [LFGData.ABOVE] = "ReadyCheck-Waiting",
  [LFGData.BELOW] = "ReadyCheck-Waiting" }
local ROLE_ATLAS = LFGWindow.ROLE_ATLAS

local function colored(color, text) return Theme.Hex(color) .. text .. "|r" end
local function icon(atlas, size) return string.format("|A:%s:%d:%d|a", atlas, size or ICON_SIZE, size or ICON_SIZE) end
local function readyIcon(name) return string.format("|TInterface\\RaidFrame\\%s:%d|t", name, ICON_SIZE) end

local function levelRange(summary)
  return summary.levelLow == summary.levelHigh and tostring(summary.levelLow)
    or (summary.levelLow .. "-" .. summary.levelHigh)
end

-- Hintergrundbild wie im Reiter Eigene Gruppe (Blizzards Atlas aus dem Eintragsfenster), unter dem Fensterkopf
local BACKGROUND_TOP, BACKGROUND_INSET = 25, 6
local background = searchTab:CreateTexture(nil, "BACKGROUND")
background:SetAtlas("groupfinder-background")
background:SetPoint("TOPLEFT", BACKGROUND_INSET, -BACKGROUND_TOP)
background:SetPoint("BOTTOMRIGHT", -BACKGROUND_INSET, 4)

---------------------------------------------------------------------------
-- Filterzeile
---------------------------------------------------------------------------
local categoryDropdown = LFGWindow.NewDropdown(searchTab, 140, function()
  return entriesOf(LFGSearch.Categories())
end, function() return state.categoryID end, function(id)
  state.categoryID, state.activityID = id, nil
  LFGWindow.Refresh()
end)
categoryDropdown:SetPoint("TOPLEFT", searchTab, "TOPLEFT", PAD, -FILTER_TOP)
Widgets.AttachTooltip(categoryDropdown, function() return L.LFG_CATEGORY end, function() return L.LFG_CATEGORY_TIP end)

-- Aktivitäten nach Level aufsteigend mit Level-Spanne; "Passend für mich" zeigt nur die zum Level passenden
local activityDropdown = LFGWindow.NewDropdown(searchTab, 168, function()
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
  state.status, state.offset, state.selected, state.results, state.lines = "searching", 0, nil, {}, {}
  state.moreOpen = false  -- nach der Suche zählt die Liste
  state.searchToken = (state.searchToken or 0) + 1
  if LFGSearch.Search(state.categoryID, activityIDs) then
    local token = state.searchToken
    C_Timer.After(SEARCH_TIMEOUT, function()
      if state.status ~= "searching" or state.searchToken ~= token then return end
      ns.Debug("lfg", "search timed out after %s seconds", SEARCH_TIMEOUT)
      state.status = "failed"
      if LFGWindow.IsShown() then LFGWindow.Refresh() end
    end)
    LFGWindow.Refresh()
  else
    state.status = "start"
  end
end, "SEARCH")
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

-- Weitere Filter: eigene Ansicht an Stelle der Liste (UI/LFGFilterView.lua)
local filterView = ns.LFGFilterView.Create(searchTab, state, function() LFGWindow.Refresh() end)

-- Zahl der aktiven weiteren Filter (Abweichungen vom Standard)
local function activeExtraFilters()
  return LFGSearch.ExtraLanguages() + LFGFilters.ActiveCount(LFGFilters.Get())
end

-- Rollenabfrage an die eigene Gruppe wie Blizzards Knopf (nur Leiter oder Assistent)
local rolePollButton = newButton(searchTab, 110, "LFG_ROLE_POLL", function()
  if InitiateRolePoll then InitiateRolePoll() end
end, "ROLE_POLL")
rolePollButton:SetPoint("RIGHT", moreButton, "LEFT", -GAP, 0)
local function canRolePoll()
  return InitiateRolePoll ~= nil and IsInGroup() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player"))
end

---------------------------------------------------------------------------
-- Liste mit Bildlaufleiste (LT-326, LT-305): zwei einklappbare Abschnitte Gruppen / Einzelspieler (Reihenfolge nach
-- der eigenen Lage, LFGSearch.Sections), je Treffer eine gerahmte Karte wie Blizzards "Suche nach Gruppe"
-- (LFGBrowseNestedSearchEntryTemplate): Krone und Leitername in Klassenfarbe, Aktivität und Level-Spanne, Spielstil
-- oder Kommentar, rechts je Platz ein Rollen-Symbol (Einzelspieler: angebotene Rollen), Alter und Passung.
-- Flüstern und Einladen stehen unten im Fenster und wirken auf die gewählte Karte.
---------------------------------------------------------------------------
local listWidth = LFGWindow.WIDTH - 2 * PAD - SCROLLBAR_SPACE
local header = CreateFrame("Frame", nil, searchTab)  -- Anker der Liste unter den Filtern, trägt die Trefferzahl
header:SetSize(listWidth, 1)
local countText = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
countText:SetPoint("BOTTOMRIGHT", header, "TOPRIGHT", -4, 2)
countText:SetTextColor(Theme.RGB("muted"))

-- Abschnittsnamen wie Blizzards Liste (LFG_LIST_CATEGORY_*), sonst unsere
local SECTION_TEXTS = { [LFGSearch.KIND_GROUPS] = { "LFG_LIST_CATEGORY_GROUPS", "LFG_KIND_GROUPS" },
  [LFGSearch.KIND_SOLO] = { "LFG_LIST_CATEGORY_SOLO_PLAYERS", "LFG_KIND_SOLO" } }
local function sectionName(kind) return LFGWindow.Text(SECTION_TEXTS[kind][1], SECTION_TEXTS[kind][2]) end
-- Blizzards Atlanten (Blizzard_LFGVanilla_Browse.xml, Mainline): Karte, Abschnittskopf, Krone, leerer Platz
local ATLAS = {
  card = "common-button-list-mid2", cardHover = "common-button-list-mid2-hover",
  cardSelected = "common-button-list-mid2-selected", section = "common-button-list-collapseExpand",
  collapse = "common-button-list-minus", expand = "common-button-list-plus",
  leader = "groupfinder-icon-leader", emptySlot = "groupfinder-icon-emptyslot",
}
local LEADER_ICON = string.format("|A:%s:14:14|a ", ATLAS.leader)
local FALLBACK_COLOR = { card = { 0, 0, 0, 0.35 }, section = { 0, 0, 0, 0.5 }, cardHover = { 1, 1, 1, 0.08 },
  cardSelected = { 1, 0.82, 0, 0.15 } }
local DELISTED_ALPHA = 0.5      -- wie Blizzard bei aufgelösten Gruppen
local SECTION_ICON_SIZE = 12
local CARD_PARTS = { "age", "level", "roles", "title", "activity", "comment" }

-- Atlas setzen; fehlt er im Client, eine schlichte Fläche (Ersatz ohne Blizzard-Grafik)
local function setAtlas(texture, key)
  if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(ATLAS[key]) then
    texture:SetAtlas(ATLAS[key])
    return
  end
  local color = FALLBACK_COLOR[key] or { 0, 0, 0, 0 }
  texture:SetColorTexture(color[1], color[2], color[3], color[4])
end

-- Zeilen der Liste: Abschnittsköpfe und Karten in Anzeigereihenfolge (eingeklappte Abschnitte ohne Karten) und alle
-- Treffer in derselben Reihenfolge
local function buildLines(sections)
  local lines, flat, counts = {}, {}, { [LFGSearch.KIND_GROUPS] = 0, [LFGSearch.KIND_SOLO] = 0 }
  for _, section in ipairs(sections) do
    counts[section.kind] = #section.items
    if #section.items > 0 then
      lines[#lines + 1] = { kind = section.kind, count = #section.items }
      for _, summary in ipairs(section.items) do
        flat[#flat + 1] = summary
        if not state.collapsed[section.kind] then lines[#lines + 1] = { summary = summary } end
      end
    end
  end
  return lines, flat, counts
end

local function heightOf(line) return line.summary and CARD_HEIGHT or SECTION_HEIGHT end

-- Größter sinnvoller Versatz: ab dieser Zeile passt der Rest der Liste in die Höhe
local function maxOffset(lines)
  local used = 0
  for index = #lines, 1, -1 do
    used = used + heightOf(lines[index])
    if used > LIST_HEIGHT then return index end
  end
  return 0
end

local function newText(row, font)
  local fontString = row:CreateFontString(nil, "OVERLAY", font)
  fontString:SetJustifyH("LEFT")
  fontString:SetWordWrap(false)
  return fontString
end

-- Eine Zeile ist Karte oder Abschnittskopf (Blizzards Vorlagen nachgebaut, ohne deren Daten-Mixin)
local rows = {}
parts.rows = rows
local function createRow(index)
  local row = CreateFrame("Button", nil, searchTab)
  row:SetSize(listWidth, CARD_HEIGHT)
  row.background = row:CreateTexture(nil, "BACKGROUND")
  row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
  row.highlight:SetBlendMode("ADD")
  row.selectedTexture = row:CreateTexture(nil, "OVERLAY")
  row.selectedTexture:SetBlendMode("ADD")
  row.selectedTexture:SetAllPoints(row.background)
  setAtlas(row.selectedTexture, "cardSelected")
  row.selected = false
  row.age = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.age:SetWidth(COLUMN_WIDTHS.age)
  row.age:SetJustifyH("RIGHT")
  row.age:SetPoint("TOPRIGHT", -10, -12)
  row.level = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")  -- Passung (Symbol) unter dem Alter
  row.level:SetWidth(COLUMN_WIDTHS.age)
  row.level:SetJustifyH("RIGHT")
  row.level:SetPoint("TOPRIGHT", row.age, "BOTTOMRIGHT", 0, -4)
  row.roles = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")  -- je Platz ein Rollen-Symbol
  row.roles:SetJustifyH("RIGHT")
  row.roles:SetPoint("RIGHT", row, "RIGHT", -(COLUMN_WIDTHS.age + 14), CARD_GAP / 2)
  row.title = newText(row, "GameFontNormalLarge")  -- Leitername, darunter Aktivität und Spielstil
  row.title:SetPoint("TOPLEFT", 10, -10)
  row.title:SetPoint("RIGHT", row.roles, "LEFT", -8, 0)
  row.activity = newText(row, "GameFontDisable")
  row.activity:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -4)
  row.activity:SetPoint("RIGHT", row.roles, "LEFT", -8, 0)
  row.comment = newText(row, "GameFontHighlightSmall")
  row.comment:SetPoint("TOPLEFT", row.activity, "BOTTOMLEFT", 0, -4)
  row.comment:SetPoint("RIGHT", row.roles, "LEFT", -8, 0)
  -- Abschnittskopf: Name mit Zahl links, Blizzards Plus/Minus rechts
  row.sectionLabel = newText(row, "GameFontNormal")
  row.sectionLabel:SetPoint("LEFT", 12, -4)
  row.sectionIcon = row:CreateTexture(nil, "ARTWORK")
  row.sectionIcon:SetSize(SECTION_ICON_SIZE, SECTION_ICON_SIZE)
  row.sectionIcon:SetPoint("RIGHT", -12, -4)
  row:SetScript("OnClick", function(self)
    if self.section then
      state.collapsed[self.section] = not state.collapsed[self.section]
    else
      state.selected = self.resultID
    end
    LFGWindow.Refresh()
  end)
  row:SetScript("OnEnter", function(self)
    if self.section then  -- Abschnittskopf: erklärt das Ein- und Ausklappen
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(sectionName(self.section), Theme.RGB("accent"))
      GameTooltip:AddLine(L.LFG_SECTION_TIP, 1, 1, 1, true)
      GameTooltip:Show()
      return
    end
    local summary = self.summary
    if not summary then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.activity:GetText() or "", Theme.RGB("accent"))
    if summary.comment and summary.comment ~= "" then GameTooltip:AddLine(summary.comment, 1, 1, 1, true) end
    if (summary.friends or 0) + (summary.guild or 0) > 0 then
      local r, g, b = Theme.RGB("success")
      GameTooltip:AddLine(string.format(L.LFG_SOCIAL, summary.friends, summary.guild), r, g, b)
    end
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)
  rows[index] = row
  return row
end

-- Rollen-Symbole wie Blizzards Aufzählung: je Mitglied die Rolle (Tank, Heiler, Schaden), freie Plätze leer;
-- Einzelspieler zeigen die angebotenen Rollen
local function rolesText(summary)
  local texts = {}
  local member = summary.members[1]
  if summary.numMembers == 1 and member and member.lfgRoles then
    for _, role in ipairs(ROLE_ORDER) do
      if member.lfgRoles[SOLO_ROLE_KEYS[role]] then table.insert(texts, icon(ROLE_ATLAS[role], ROLE_ICON_SIZE)) end
    end
    return table.concat(texts, "")
  end
  for _, role in ipairs(ROLE_ORDER) do
    for _, groupMember in ipairs(summary.members) do
      if groupMember.role == role then table.insert(texts, icon(ROLE_ATLAS[role], ROLE_ICON_SIZE)) end
    end
  end
  for _ = 1, summary.open and summary.open.free or 0 do table.insert(texts, icon(ATLAS.emptySlot, ROLE_ICON_SIZE)) end
  return table.concat(texts, "")
end

local function fitSymbol(summary)
  if not summary.levelLow then return "" end
  if summary.delisted or summary.noXpLow then return readyIcon("ReadyCheck-NotReady") end
  return FIT_ICON[summary.fit] and readyIcon(FIT_ICON[summary.fit]) or ""
end

-- Titel fürs Seitenfenster: Gruppenname oder Aktivität, mit Leiter
local function titleOf(summary)
  local name = summary.title ~= "" and summary.title or nil
  local activity = summary.activityNames[1] or "?"
  if #summary.activityNames > 1 then activity = string.format("%s +%d", activity, #summary.activityNames - 1) end
  return (name or activity) .. (summary.leaderName and (" - " .. summary.leaderName) or "")
end

-- Gruppenname (falls gesetzt), Aktivität (mit Zahl weiterer) und Level-Spanne
local function activityText(summary)
  local activity = summary.activityNames[1] or "?"
  if #summary.activityNames > 1 then activity = string.format("%s +%d", activity, #summary.activityNames - 1) end
  if summary.title and summary.title ~= "" then activity = summary.title .. " - " .. activity end
  return summary.levelLow and (activity .. "   " .. levelRange(summary)) or activity
end

-- Spielstil (grün) oder sonst der Kommentar (grau)
local function styleText(summary)
  if summary.generalPlaystyle then return colored("success", LFGWindow.PlaystyleLabel(summary.generalPlaystyle)) end
  return colored("muted", summary.comment or "")
end

-- Karte und Kopf teilen sich die Zeile: Teile, Hintergrund (Blizzards Atlas) und Höhe umschalten
local function setKind(row, card)
  for _, key in ipairs(CARD_PARTS) do row[key]:SetShown(card) end
  row.sectionLabel:SetShown(not card)
  row.sectionIcon:SetShown(not card)
  row:SetHeight(card and CARD_HEIGHT or SECTION_HEIGHT)
  row.background:ClearAllPoints()
  row.background:SetPoint("TOPLEFT", 0, card and 0 or -8)  -- Kopf wie Blizzard 8 unter der Oberkante
  row.background:SetPoint("BOTTOMRIGHT", 0, card and CARD_GAP or 0)
  row.highlight:SetAllPoints(row.background)
  setAtlas(row.background, card and "card" or "section")
  setAtlas(row.highlight, card and "cardHover" or "section")
end

local function setSelected(row, selected)
  row.selected = selected
  row.selectedTexture:SetShown(selected)
end

local function fillSection(row, line)
  row.section, row.summary, row.resultID = line.kind, nil, nil
  setKind(row, false)
  row.sectionLabel:SetText(string.format("%s (%d)", sectionName(line.kind), line.count))
  row.collapsed = state.collapsed[line.kind] == true
  setAtlas(row.sectionIcon, row.collapsed and "expand" or "collapse")
  setSelected(row, false)
end

local function fillCard(row, summary)
  row.section, row.summary, row.resultID = false, summary, summary.resultID  -- false statt nil: Feld immer gesetzt
  row.collapsed = false
  setKind(row, true)
  local leader = summary.members[1]
  local name = summary.leaderName or "?"
  row.title:SetText((summary.numMembers or 0) > 1 and (LEADER_ICON .. name) or name)
  if summary.delisted then
    row.title:SetTextColor(Theme.RGB("muted"))  -- RGB liefert drei Werte: nie in and/or
  else
    local color = Theme.ClassColor(leader and leader.class)
    if color then row.title:SetTextColor(color[1], color[2], color[3]) else row.title:SetTextColor(Theme.RGB("accent")) end
  end
  row.activity:SetText(activityText(summary))
  row.comment:SetText(styleText(summary))
  row.roles:SetText(rolesText(summary))
  row.roles:SetAlpha(summary.delisted and DELISTED_ALPHA or 1)
  row.level:SetText(fitSymbol(summary))
  row.age:SetText(summary.age and Format.Duration(summary.age) or "")
  setSelected(row, summary.resultID == state.selected)
end

local scrollBar
local refreshList

local function scrollTo(offset)
  state.offset = offset
  refreshList()
end

scrollBar = Widgets.CreateScrollBar(searchTab, scrollTo)
scrollBar:SetPoint("TOPLEFT", header, "BOTTOMRIGHT", SCROLLBAR_SPACE - 8, 0)
scrollBar:SetHeight(LIST_HEIGHT)

header:SetPoint("TOPRIGHT", moreButton, "BOTTOMRIGHT", -SCROLLBAR_SPACE, -LIST_GAP)
filterView.frame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)

local emptyText = searchTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
emptyText:SetPoint("TOP", header, "BOTTOM", 0, -48)
emptyText:SetWidth(listWidth - 2 * PAD)
emptyText:SetTextColor(Theme.RGB("muted"))
parts.emptyText = emptyText

function refreshList()
  local lines = state.moreOpen and {} or state.lines  -- offene Filteransicht ersetzt die Liste
  state.offset = math.max(0, math.min(state.offset or 0, maxOffset(lines)))
  local y, used = 0, 0
  for lineIndex = state.offset + 1, #lines do
    local line = lines[lineIndex]
    if y + heightOf(line) > LIST_HEIGHT then break end
    used = used + 1
    local row = rows[used] or createRow(used)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -y)
    if line.summary then fillCard(row, line.summary) else fillSection(row, line) end
    row:Show()
    y = y + heightOf(line)
  end
  for rest = used + 1, #rows do
    rows[rest].section, rows[rest].summary, rows[rest].resultID = false, nil, nil
    rows[rest]:Hide()
  end
  scrollBar:SetRange(maxOffset(lines))  -- blendet die Leiste ohne Bildlauf selbst aus
  scrollBar:SetOffsetSilently(state.offset)
  local total = #state.results
  countText:SetText(total > 0 and string.format(L.LFG_COUNT_SPLIT, state.counts[LFGSearch.KIND_GROUPS],
    state.counts[LFGSearch.KIND_SOLO]) or "")
  local message = (total == 0 and not state.moreOpen) and L[({ start = "LFG_STATE_START",
    searching = "LFG_STATE_SEARCHING", failed = "LFG_STATE_FAILED", done = "LFG_STATE_NONE" })[state.status]] or ""
  emptyText:SetText(message)
end

-- Treffer neu zusammenstellen (nach Suche oder Filter); ohne fertige Suche leer
local function collectResults()
  local sections = state.status == "done"
    and LFGSearch.Sections({ fitOnly = state.fitOnly, filters = LFGFilters.Get() }) or {}
  state.lines, state.results, state.counts = buildLines(sections)
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
-- Ohne Porträt: auch der Rahmen ohne Ring (sonst überdeckt der leere Ring oben links die erste Zeile)
if detail.SetBorder then detail:SetBorder("ButtonFrameTemplateNoPortrait") end
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

-- Aktionen unten im Fenster wie Blizzards SendMessageButton / GroupInviteButton, wirken auf die gewählte Karte
local whisperButton = newButton(searchTab, 100, "LFG_WHISPER", function()
  local summary = state.selected and LFGSearch.Summary(state.selected)
  if not (summary and summary.leaderName) then return end
  if ChatFrameUtil and ChatFrameUtil.SendTell then ChatFrameUtil.SendTell(summary.leaderName)
  elseif ChatFrame_SendTell then ChatFrame_SendTell(summary.leaderName) end
end, "SEND_MESSAGE")
whisperButton:SetPoint("BOTTOMLEFT", PAD, PAD)
local inviteButton = newButton(searchTab, 100, "LFG_INVITE", function()
  local summary = state.selected and LFGSearch.Summary(state.selected)
  if LFGSearch.CanInvite(summary) then C_PartyInfo.InviteUnit(summary.leaderName) end
end, "GROUP_INVITE")
inviteButton:SetPoint("BOTTOMRIGHT", -PAD, PAD)

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
  retext(rolePollButton)
  rolePollButton:SetEnabled(canRolePoll())
  filterView.frame:SetShown(state.moreOpen)
  if state.moreOpen then filterView.Refresh() end
  if state.status == "done" or state.status == "failed" or state.status == "start" then
    collectResults()
  end
  refreshList()
  refreshDetail()
end)

parts.searchButton, parts.whisperButton, parts.inviteButton = searchButton, whisperButton, inviteButton
parts.categoryDropdown, parts.activityDropdown = categoryDropdown, activityDropdown
parts.fitCheck, parts.moreButton, parts.filterView = fitCheck, moreButton, filterView
parts.scrollBar, parts.header, parts.countText, parts.rolePollButton = scrollBar, header, countText, rolePollButton

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

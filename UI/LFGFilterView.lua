-- "Weitere Filter" des Reiters Suchen (UI/LFGSearchTab.lua): eigene Ansicht an Stelle der Trefferliste, bis man sie
-- wieder zuklappt oder sucht. Abschnitte mit Überschrift (Tooltip) und Blizzard-Kästchen, die bei Platzmangel umbrechen;
-- Auswahl immer per Haken, nie nur per Farbe. Texte aus Blizzards Client-Sprache, wo es sie gibt (LFGWindow.Text).
-- Abschnitte (LT-347, LT-352): Anzeige (Art, aufgelöste, Freunde/Gilde zuerst), Gruppen nach Rolle, Spieler nach Rolle
-- und Level, Klassen, Spielstil, Sprachen; Zurücksetzen. Die Regeln stehen in Assist/LFGFilters.lua (gespeichert pro
-- Account), die Sprachen in Assist/LFGSearch.lua; diese Datei baut nur die Bedienung.
local _, ns = ...
if not ns.Client.IsForever() then return end

local L = ns.L
local Widgets = ns.Widgets
local LFGSearch = ns.LFGSearch
local LFGFilters = ns.LFGFilters
local LFGWindow = ns.LFGWindow

local GAP, CONTROL_HEIGHT = LFGWindow.GAP, LFGWindow.CONTROL_HEIGHT
local ROW_HEIGHT = 24            -- Zeile mit Kästchen
local HEADER_HEIGHT = 18
local SECTION_GAP = 8
local ITEM_GAP = 12              -- Abstand zwischen zwei Kästchen einer Zeile
local CHECK_WIDTH = 26 + Widgets.CHECKBOX_LABEL_GAP  -- Kästchen plus Abstand zur Beschriftung
local CLASS_COLUMNS = 4
local DROPDOWN_WIDTH = 160
local LEVEL_BOX_WIDTH = 36
local MAX_LEVEL_DIGITS = 2
local ROLE_TEXTS = ns.LFGTooltip.ROLE_TEXTS
local KIND_ENTRIES = {
  { key = LFGFilters.KIND_ALL, text = function() return L.LFG_KIND_ALL end },
  { key = LFGFilters.KIND_GROUPS, text = function() return LFGWindow.Text("LFG_LIST_CATEGORY_GROUPS", "LFG_KIND_GROUPS") end },
  { key = LFGFilters.KIND_SOLO, text = function() return LFGWindow.Text("LFG_LIST_CATEGORY_SOLO_PLAYERS", "LFG_KIND_SOLO") end },
}

local LABEL_ICON_SIZE = 16
local CLASS_ICONS = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local CLASS_ICONS_SIZE = 256   -- Pixel der Klassen-Textur (für die Ausschnitt-Koordinaten im |T-Markup)

local function roleName(role) return LFGWindow.Text(role, ROLE_TEXTS[role]) end
-- Beschriftung mit Rollen-Symbol davor
local function withRoleIcon(role, text)
  return string.format("|A:%s:%d:%d|a %s", LFGWindow.ROLE_ATLAS[role], LABEL_ICON_SIZE, LABEL_ICON_SIZE, text)
end
-- Klassenname mit Klassen-Symbol davor (ohne CLASS_ICON_TCOORDS nur der Name)
local function className(class)
  -- Blizzards Klassennamen nur in Client-Sprache, sonst unsere (CLASS_NAME_<KLASSE>)
  local blizzard = ns.SpeaksClientLanguage() and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]
  local name = blizzard or L["CLASS_NAME_" .. class]
  local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
  if not coords then return name end
  local s = CLASS_ICONS_SIZE
  return string.format("|T%s:%d:%d:0:0:%d:%d:%d:%d:%d:%d|t %s", CLASS_ICONS, LABEL_ICON_SIZE, LABEL_ICON_SIZE, s, s,
    coords[1] * s, coords[2] * s, coords[3] * s, coords[4] * s, name)
end

local LFGFilterView = {}
ns.LFGFilterView = LFGFilterView

-- Baut die Ansicht in parent; onChange() nach jeder Änderung (Liste neu filtern). Rückgabe: { frame, Refresh, parts }
function LFGFilterView.Create(parent, state, onChange)
  local frame = CreateFrame("Frame", nil, parent)
  frame:Hide()
  local view = { frame = frame, parts = {} }
  local width = LFGWindow.WIDTH - 2 * LFGWindow.PAD
  frame:SetWidth(width)
  local headers, checks = {}, {}
  local function filters() return LFGFilters.Get() end
  local function changed()
    state.offset = 0
    onChange()
  end

  -- Überschrift eines Abschnitts mit Tooltip L[key .. "_TIP"]
  local function header(key)
    local holder = CreateFrame("Frame", nil, frame)
    holder:SetSize(width, HEADER_HEIGHT)
    holder.text = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    holder.text:SetPoint("LEFT")
    holder.key = key
    Widgets.AttachTooltip(holder, function() return L[key] end, function() return L[key .. "_TIP"] end)
    headers[#headers + 1] = holder
    return holder
  end

  -- Kästchen; get() liefert den Haken, set(checked) speichert ihn
  local function newCheck(key, textFn, get, set)
    local check = LFGWindow.NewCheck(frame, key, function(checked)
      set(checked)
      changed()
    end)
    check.textFn, check.get = textFn or function() return L[key] end, get
    checks[#checks + 1] = check
    return check
  end

  -- Kästchen für einen Schlüssel einer Menge in den Filtern (z. B. openRoles.TANK)
  local function setCheck(key, textFn, field, member)
    return newCheck(key, textFn, function() return filters()[field][member] == true end,
      function(checked) filters()[field][member] = checked or nil end)
  end

  local function place(holder, top)
    holder.text:SetText(L[holder.key])
    holder:ClearAllPoints()
    holder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -top)
    return top + HEADER_HEIGHT + 4
  end

  local function show(check, x, y)
    check.label:SetText(check.textFn())
    check:SetChecked(check.get())
    check:ClearAllPoints()
    check:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -y)
    check:Show()
    return CHECK_WIDTH + math.ceil(check.label:GetStringWidth())
  end

  -- Kästchen nebeneinander ab x/top, Umbruch, wenn die Breite (gemessen, fr/es länger) nicht reicht; Rückgabe neues y
  local function flow(list, top, startX)
    local x, rowY = startX or 0, top
    for _, check in ipairs(list) do
      check.label:SetText(check.textFn())
      local itemWidth = CHECK_WIDTH + math.ceil(check.label:GetStringWidth())
      if x > 0 and x + itemWidth > width then x, rowY = 0, rowY + ROW_HEIGHT end
      x = x + show(check, x, rowY) + ITEM_GAP
    end
    return rowY + ROW_HEIGHT, x
  end

  local function newDropdown(entriesFn, get, set, key)
    local dropdown = LFGWindow.NewDropdown(frame, DROPDOWN_WIDTH, entriesFn, get, function(value)
      set(value)
      changed()
    end)
    Widgets.AttachTooltip(dropdown, function() return L[key] end, function() return L[key .. "_TIP"] end)
    return dropdown
  end

  -- Anzeige: Art (Auswahlliste), aufgelöste Gruppen, Freunde/Gilde zuerst
  local showHeader = header("LFG_FILTER_SHOW")
  local kindDropdown = newDropdown(function()
    local entries = {}
    for _, entry in ipairs(KIND_ENTRIES) do entries[#entries + 1] = { key = entry.key, text = entry.text() } end
    return entries
  end, function() return filters().kind end, function(kind) filters().kind = kind end, "LFG_KIND")
  local delistedCheck = newCheck("LFG_HIDE_DELISTED", nil, function() return filters().hideDelisted end,
    function(checked) filters().hideDelisted = checked end)
  local socialCheck = newCheck("LFG_SOCIAL_FIRST", nil, function() return filters().socialFirst end,
    function(checked) filters().socialFirst = checked end)

  -- Gruppen nach Rolle: Rolle frei (eine reicht), hat Tank/Heiler (alle gewählten)
  local groupHeader = header("LFG_FILTER_GROUP_ROLES")
  local groupChecks = {}
  for _, role in ipairs(LFGFilters.ROLES) do
    table.insert(groupChecks, setCheck("LFG_FILTER_OPEN_ROLE",
      function() return withRoleIcon(role, string.format(L.LFG_FILTER_OPEN_ROLE_FMT, roleName(role))) end,
      "openRoles", role))
  end
  for _, role in ipairs(LFGFilters.HAS_ROLES) do
    table.insert(groupChecks, setCheck("LFG_FILTER_HAS_ROLE",
      function() return withRoleIcon(role, string.format(L.LFG_FILTER_HAS_ROLE_FMT, roleName(role))) end,
      "hasRoles", role))
  end

  -- Einzelspieler nach Rolle und Level
  local playerHeader = header("LFG_FILTER_PLAYERS")
  local playerChecks = {}
  for _, role in ipairs(LFGFilters.ROLES) do
    table.insert(playerChecks, setCheck("LFG_FILTER_PLAYER_ROLE", function() return withRoleIcon(role, roleName(role)) end,
      "playerRoles", role))
  end
  local levelLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  local function levelBox(field)
    local box = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    box:SetSize(LEVEL_BOX_WIDTH, ROW_HEIGHT)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetMaxLetters(MAX_LEVEL_DIGITS)
    box.field = field
    -- leer = offen; erst beim Verlassen oder Enter übernehmen, damit die Liste nicht bei jeder Ziffer springt
    local function commit(self)
      local value = tonumber(self:GetText())
      filters()[field] = (value and value > 0) and value or false
      changed()
    end
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusLost", commit)
    Widgets.AttachTooltip(box, function() return L.LFG_FILTER_LEVEL end, function() return L.LFG_FILTER_LEVEL_TIP end)
    return box
  end
  local levelMinBox, levelMaxBox = levelBox("levelMin"), levelBox("levelMax")
  local levelDash = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  levelDash:SetText("-")

  -- Klassen: abgewählte blenden Einzelspieler dieser Klasse und Gruppen mit ihr aus
  local classHeader = header("LFG_FILTER_CLASSES")
  local classChecks = {}
  for _, class in ipairs(LFGFilters.CLASSES) do
    table.insert(classChecks, newCheck("LFG_FILTER_CLASS", function() return className(class) end,
      function() return not filters().hiddenClasses[class] end,
      function(checked) filters().hiddenClasses[class] = (not checked) or nil end))
  end

  -- Spielstil (Alle oder einer von Blizzards Spielstilen)
  local playstyleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  local playstyleDropdown = newDropdown(function()
    local entries = { { key = false, text = L.LFG_KIND_ALL } }
    for _, playstyle in ipairs(LFGWindow.PLAYSTYLE_ORDER) do
      table.insert(entries, { key = playstyle, text = LFGWindow.PlaystyleLabel(playstyle) })
    end
    return entries
  end, function() return filters().playstyle end, function(playstyle) filters().playstyle = playstyle end,
    "LFG_FILTER_PLAYSTYLE")

  -- Sprachen: je Sprache ein Kästchen mit Blizzards Namen; Pflichtsprachen sind immer an
  local languageHeader = header("LFG_LANGUAGES")
  local languageChecks = {}
  local function languageCheck(index)
    if not languageChecks[index] then
      local check
      check = newCheck("LFG_LANGUAGE_CHIP", nil, function() return check.enabled end,
        function() LFGSearch.ToggleLanguage(check.code) end)
      languageChecks[index] = check
    end
    return languageChecks[index]
  end

  local resetButton = LFGWindow.NewButton(frame, 120, "LFG_FILTER_RESET", function()
    LFGFilters.Reset()
    changed()
  end, "RESET")

  function view.Refresh()
    for _, check in ipairs(checks) do check:Hide() end
    -- Anzeige
    local y = place(showHeader, 0)
    LFGWindow.RefreshDropdown(kindDropdown, L.LFG_KIND_ALL)
    kindDropdown:ClearAllPoints()
    kindDropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -y)
    local checksBottom = flow({ delistedCheck, socialCheck }, y + (CONTROL_HEIGHT - ROW_HEIGHT) / 2, DROPDOWN_WIDTH + GAP)
    y = math.max(y + CONTROL_HEIGHT, checksBottom) + SECTION_GAP
    -- Gruppen nach Rolle
    y = flow(groupChecks, place(groupHeader, y)) + SECTION_GAP
    -- Spieler: Rollen, dann Level von - bis in derselben Zeile, falls Platz
    local rowEnd
    y, rowEnd = flow(playerChecks, place(playerHeader, y))
    levelLabel:SetText(L.LFG_FILTER_LEVEL)
    local levelWidth = math.ceil(levelLabel:GetStringWidth()) + 2 * LEVEL_BOX_WIDTH + 3 * GAP + GAP
    local levelY, levelX = y - ROW_HEIGHT, rowEnd
    if levelX + levelWidth > width then levelX, levelY, y = 0, y, y + ROW_HEIGHT end
    levelLabel:ClearAllPoints()
    levelLabel:SetPoint("LEFT", frame, "TOPLEFT", levelX, -(levelY + ROW_HEIGHT / 2))
    levelMinBox:ClearAllPoints()
    levelMinBox:SetPoint("LEFT", levelLabel, "RIGHT", GAP + 4, 0)
    levelDash:ClearAllPoints()
    levelDash:SetPoint("LEFT", levelMinBox, "RIGHT", 4, 0)
    levelMaxBox:ClearAllPoints()
    levelMaxBox:SetPoint("LEFT", levelDash, "RIGHT", GAP, 0)
    for _, box in ipairs({ levelMinBox, levelMaxBox }) do
      if not (box.HasFocus and box:HasFocus()) then box:SetText(filters()[box.field] and tostring(filters()[box.field]) or "") end
    end
    y = y + SECTION_GAP
    -- Klassen in festen Spalten; so viele Spalten (höchstens CLASS_COLUMNS), wie der breiteste Name samt Symbol zulässt
    y = place(classHeader, y)
    local widest = 0
    for _, check in ipairs(classChecks) do widest = math.max(widest, show(check, 0, y)) end
    local columns = math.max(1, math.min(CLASS_COLUMNS, math.floor((width + ITEM_GAP) / (widest + ITEM_GAP))))
    local columnWidth = math.floor(width / columns)
    for index, check in ipairs(classChecks) do
      local column, row = (index - 1) % columns, math.floor((index - 1) / columns)
      show(check, column * columnWidth, y + row * ROW_HEIGHT)
    end
    y = y + math.ceil(#classChecks / columns) * ROW_HEIGHT + SECTION_GAP
    -- Spielstil, rechts daneben Zurücksetzen
    LFGWindow.Retext(resetButton)
    resetButton:ClearAllPoints()
    resetButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -y)
    playstyleLabel:SetText(L.LFG_FILTER_PLAYSTYLE)
    playstyleLabel:ClearAllPoints()
    playstyleLabel:SetPoint("LEFT", frame, "TOPLEFT", 0, -(y + CONTROL_HEIGHT / 2))
    LFGWindow.RefreshDropdown(playstyleDropdown, L.LFG_KIND_ALL)
    playstyleDropdown:ClearAllPoints()
    playstyleDropdown:SetPoint("LEFT", playstyleLabel, "RIGHT", GAP, 0)
    playstyleDropdown:SetShown(#LFGWindow.PLAYSTYLE_ORDER > 0)
    playstyleLabel:SetShown(#LFGWindow.PLAYSTYLE_ORDER > 0)
    y = y + CONTROL_HEIGHT + SECTION_GAP
    -- Sprachen
    y = place(languageHeader, y)
    local list = {}
    for index, language in ipairs(LFGSearch.Languages()) do
      local check = languageCheck(index)
      check.code, check.enabled = language.code, language.enabled
      check.textFn = function() return ns.LFGLanguages.Name(language.code) end
      check:SetEnabled(not language.fixed)
      list[#list + 1] = check
    end
    frame:SetHeight(flow(list, y))
  end

  view.parts.kindDropdown, view.parts.delistedCheck, view.parts.socialCheck = kindDropdown, delistedCheck, socialCheck
  view.parts.groupChecks, view.parts.playerChecks, view.parts.classChecks = groupChecks, playerChecks, classChecks
  view.parts.levelMinBox, view.parts.levelMaxBox, view.parts.playstyleDropdown = levelMinBox, levelMaxBox, playstyleDropdown
  view.parts.languageChecks, view.parts.headers, view.parts.resetButton = languageChecks, headers, resetButton
  return view
end

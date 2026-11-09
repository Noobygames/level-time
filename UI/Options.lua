-- Einstellungsfenster mit Reitern: Allgemein, Statistiken, Chat & Erinnerungen, Einblendungen, Komfort, Speedrun,
-- Profile; alle außer Profile mit Seitenleiste (Kategorien als Unterseiten). Darunter auf allen Reitern: Historie,
-- Layout bearbeiten, Zusammenfassung, Neue Session. Oben links die Suche über alle Einstellungen (OptionsBuilder).
-- Nur der Inhalt; Aufbau, Tooltips, Breite und Aktualisierung übernimmt Lib/OptionsBuilder.lua.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local TimerWindow = ns.TimerWindow
local Alerts = ns.Alerts
local Builder = ns.OptionsBuilder

local MAX_PROFILE_ROWS = 6     -- so viele Profile listet der Reiter "Profile"
local ROW_PROFILE = 20
local PROFILE_NAME_WIDTH = 160
local PROFILE_SAVE_WIDTH = 120
local PROFILE_LABEL_OFFSET = 4  -- Beschriftung "Neues Profil:" mittig zur Höhe des Felds
local PROFILE_BOX_BORDER = 6    -- InputBoxTemplate zeichnet seinen Rand links außerhalb
local DELETE_PROFILE_POPUP = ns.PopupKey("DELETE_PROFILE")
local QUEST_EXCLUDE_WIDTH = 200  -- Eingabefeld für die eigene Sperrliste der Quest-Automatik

local builder = Builder.New({
  name = ns.GlobalName("Options"),
  alpha = 0.95,
  title = function() return ns.DISPLAY_NAME .. " - " .. L.SETTINGS end,
  -- Schalter "Erweitert" oben rechts: aus = selten genutzte Bausteine verborgen
  advanced = {
    label = "OPTIONS_ADVANCED",
    get = function(db) return db.optionsAdvanced end,
    set = function(on) ns.Set("optionsAdvanced", on) end,
  },
})
local addPage, finishPage, addSection, addSlider = builder.AddPage, builder.FinishPage, builder.AddSection, builder.AddSlider
local addToggles, addButton, addFooterButton = builder.AddToggles, builder.AddButton, builder.AddFooterButton
local addChooser, addHint = builder.AddChooser, builder.AddHint
local toggle, localized = Builder.Toggle, Builder.Localized

-- Baustein nur im Modus "Erweitert" (Roadmap 402): selten gebraucht, für Feineinstellungen
local function advanced(definition)
  definition.advanced = true
  return definition
end

-- Baustein, der nur wirkt, wenn eine der Einstellungen an ist: sonst ausgegraut (enabled), damit kein Haken gesetzt
-- und doch wirkungslos aussieht (z.B. Flugzeit-Tooltip ohne Flugzeiten)
local function requires(definition, ...)
  local settings = { ... }
  definition.enabled = function(db)
    for _, setting in ipairs(settings) do
      if db[setting] then return true end
    end
    return false
  end
  return definition
end

-- Sprachnamen stehen immer in der eigenen Sprache
local function addLanguageChooser()
  local choices = {}
  for i, language in ipairs(ns.languages) do
    choices[i] = { value = language.code, name = function() return language.name end }
  end
  addChooser({ label = "LANGUAGE", setting = "language", choices = choices })
end

-- Vergleich der Splits; ein fester Charakter wird per /lt compare Name gewählt
local function addSplitComparisonChooser()
  local Splits = ns.Splits
  addChooser({ label = "SPLIT_COMPARISON", setting = "splitComparison", choices = {
    { value = Splits.BEST, name = localized("COMPARE_CHOICE_BEST") },
    { value = Splits.PERSONAL_BEST, name = localized("COMPARE_CHOICE_PB") },
    { value = Splits.RUN, name = localized("COMPARE_CHOICE_RUN") },
  } })
end

-- Speedrun-Rekorde: schnellster Lauf insgesamt oder der eigenen Klasse
local function addWorldRecordScopeChooser()
  local WorldRecords = ns.WorldRecords
  addChooser({ label = "WORLD_RECORD_SCOPE", setting = "worldRecordScope", choices = {
    { value = WorldRecords.CLASS, name = localized("WORLD_RECORD_OWN_CLASS") },
    { value = WorldRecords.OVERALL, name = localized("WORLD_RECORD_ALL_CLASSES") },
  } })
end

-- SSF-Regelhelfer: aus oder eine Kategorie (SsfRules.lua)
local function addSsfCategoryChooser()
  local choices = { { value = ns.SsfRules.OFF, name = localized("SSF_CATEGORY_OFF") } }
  for _, category in ipairs(ns.SsfRules.ORDER) do
    table.insert(choices, { value = category, name = function() return category end })
  end
  addChooser({ label = "SSF_CATEGORY", setting = "ssfCategory", choices = choices })
end

-- Level-Up-Ansage: aus, Gruppe oder Gilde
local function addAnnounceChooser()
  local Summary = ns.LevelUpSummary
  addChooser({ label = "LEVEL_UP_ANNOUNCE", setting = "levelUpAnnounce", choices = {
    { value = Summary.ANNOUNCE_OFF, name = localized("ANNOUNCE_OFF") },
    { value = Summary.ANNOUNCE_PARTY, name = localized("ANNOUNCE_PARTY") },
    { value = Summary.ANNOUNCE_GUILD, name = localized("ANNOUNCE_GUILD") },
  } })
end

-- Hintergrund des Fensters: Standard oder Chroma-Farbe für Streams
local function addBackgroundChooser()
  addChooser({ label = "WINDOW_BACKGROUND", setting = "windowBackground", choices = {
    { value = TimerWindow.BACKGROUND_DEFAULT, name = localized("BACKGROUND_DEFAULT") },
    { value = "green", name = localized("BACKGROUND_GREEN") },
    { value = "magenta", name = localized("BACKGROUND_MAGENTA") },
  } })
end

-- Kontur der Schrift (Aussehen; auf der Stream-Seite als Abkürzung, weil OBS-Szenen sie brauchen)
local function addOutlineChooser(isAdvanced)
  local outlines = {}
  for i, key in ipairs(ns.Theme.OUTLINE_ORDER) do
    outlines[i] = { value = key, name = localized("OUTLINE_" .. key:upper()) }
  end
  addChooser({ label = "THEME_OUTLINE", setting = "themeOutline", choices = outlines, advanced = isAdvanced })
end

-- Abkürzung zu den Layouts, die sich für OBS eignen (alle Layouts: Allgemein > Layout)
local STREAM_LAYOUTS = { "text", "clock", "table" }
local function addStreamLayoutChooser()
  local choices = {}
  for i, id in ipairs(STREAM_LAYOUTS) do
    choices[i] = { value = id, name = localized(ns.WindowLayouts.Get(id).label) }
  end
  addChooser({ label = "STREAM_LAYOUT", setting = "windowLayout", choices = choices })
end

-- Profile: Liste (Klick wechselt, Rechtsklick löscht), Name + Speichern, Export und Import
local confirmProfileDelete = Widgets.ConfirmPopup(DELETE_PROFILE_POPUP, "PROFILE_DELETE_CONFIRM", function(name)
  if ns.Profiles.Delete(name) then ns.Print(string.format(L.PROFILE_DELETED, ns.Profiles.DisplayName(name))) end
  ns.ApplySettings()
end)

-- Profil nach Rückfrage löschen (Rechtsklick in der Liste und /lt profile delete); nicht löschbare melden sich sofort
function ns.ConfirmProfileDelete(name)
  if not ns.Profiles.CanDelete(name) then
    ns.Print(L.PROFILE_NOT_DELETED)
    return
  end
  confirmProfileDelete(ns.Profiles.DisplayName(name), name)
end

local OVERWRITE_PROFILE_POPUP = ns.PopupKey("OVERWRITE_PROFILE")
local onProfileSaved  -- Rückruf des laufenden Speicherns (leert z.B. das Namensfeld)

local function saveProfile(name)
  if ns.Profiles.SaveAs(name) then
    ns.Print(string.format(L.PROFILE_SAVED, name))
    if onProfileSaved then onProfileSaved() end
    ns.ApplySettings()
  end
end

local confirmOverwrite = Widgets.ConfirmPopup(OVERWRITE_PROFILE_POPUP, "PROFILE_OVERWRITE_CONFIRM", saveProfile)

-- Einstellungen als Profil speichern (Button und /lt profile save); leerer Name meldet sich, ein vorhandenes
-- Profil wird erst nach Rückfrage überschrieben. onSaved läuft nach dem Speichern.
function ns.ConfirmProfileSave(name, onSaved)
  name = strtrim(name or "")
  onProfileSaved = onSaved
  if name == "" then
    ns.Print(L.PROFILE_NAME_EMPTY)
  elseif ns.Profiles.Exists(name) then
    confirmOverwrite(name, name)
  else
    saveProfile(name)
  end
end

-- Liste der Profile: MAX_PROFILE_ROWS Zeilen; mehr Profile per Mausrad oder Scrollleiste erreichbar
local function addProfileList()
  local Profiles = ns.Profiles
  local page = builder.Page()
  local listOffset = 0
  local scrollBar

  local function maxOffset()
    return math.max(0, #Profiles.GetNames() - MAX_PROFILE_ROWS)
  end

  local function scrollTo(offset)
    listOffset = Widgets.ClampOffset(offset, #Profiles.GetNames(), MAX_PROFILE_ROWS)
    builder.Refresh(ns.db)
  end

  scrollBar = Widgets.CreateScrollBar(page, scrollTo)
  scrollBar:SetPoint("TOPRIGHT", page, "TOPRIGHT", -Builder.MARGIN, builder.RowY())
  scrollBar:SetHeight(MAX_PROFILE_ROWS * ROW_PROFILE)
  builder.OnRefresh(function()
    listOffset = math.min(listOffset, maxOffset())
    scrollBar:SetRange(maxOffset())
    scrollBar:SetOffsetSilently(listOffset)
  end)

  for index = 1, MAX_PROFILE_ROWS do
    local tab = Widgets.CreateTab(builder.Page(), "GameFontHighlight", function(self, mouseButton)
      local name = self.profileName
      if mouseButton == "RightButton" then
        ns.ConfirmProfileDelete(name)
      else
        Profiles.Switch(name)
      end
    end)
    tab:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    tab:EnableMouseWheel(true)
    tab:SetScript("OnMouseWheel", function(_, delta) scrollTo(listOffset - delta) end)
    builder.AddRow(tab, ROW_PROFILE)
    builder.AddTooltip(tab, "PROFILE_LIST_TIP", function() return Profiles.DisplayName(tab.profileName) end)
    builder.OnRefresh(function()
      local name = Profiles.GetNames()[listOffset + index]
      tab.profileName = name
      tab:SetShown(name ~= nil)
      if name then
        tab:SetLabel(Profiles.DisplayName(name))
        tab:SetActive(name == Profiles.GetActive())
      end
    end)
  end
end

-- Import-Fenster für Profile (auch /lt profile import); das neue Profil wird nicht sofort aktiv
function ns.ShowProfileImport()
  ns.Export.ShowImport(L.PROFILE_IMPORT, function(text)
    local name = ns.Profiles.Import(text)
    if not name then return L.PROFILE_IMPORT_INVALID, false end
    ns.ApplySettings()
    return string.format(L.PROFILE_IMPORTED, name), true
  end)
end

-- Wer das aktive Profil nutzt (UX S28): "Aktiv: Name (genutzt von N Charakteren)", die Namen im Tooltip
local MAX_PROFILE_USER_NAMES = 15  -- mehr Namen im Tooltip nur als Anzahl

local function profileUsageText()
  local Profiles = ns.Profiles
  local active = Profiles.GetActive()
  local count = #Profiles.CharactersOf(active)
  return string.format(count == 1 and L.PROFILE_ACTIVE_USED_ONE or L.PROFILE_ACTIVE_USED, Profiles.DisplayName(active), count)
end

local function profileUsersTip()
  local keys = ns.Profiles.CharactersOf(ns.Profiles.GetActive())
  local names = {}
  for i = 1, math.min(#keys, MAX_PROFILE_USER_NAMES) do names[i] = ns.History.DisplayName(keys[i]) end
  if #keys > MAX_PROFILE_USER_NAMES then
    table.insert(names, string.format(L.PROFILE_USERS_MORE, #keys - MAX_PROFILE_USER_NAMES))
  end
  return L.PROFILE_ACTIVE_TIP .. (#names > 0 and "\n\n" .. table.concat(names, "\n") or "")
end

local function addProfileUsage()
  local page = builder.Page()
  local line = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  line:SetJustifyH("LEFT")
  builder.AddRow(line, ROW_PROFILE, true)
  -- Tooltip braucht eine Mausfläche über der Zeile
  local hover = CreateFrame("Frame", nil, page)
  hover:SetAllPoints(line)
  hover:EnableMouse(true)
  Widgets.AttachTooltip(hover, profileUsageText, profileUsersTip)
  builder.OnRefresh(function() line:SetText(profileUsageText()) end)
  builder.profileUsage = line  -- Tests
end

-- Name + Speichern: Beschriftung vor dem Feld, Knopf erst mit Namen bedienbar (UX S28)
local function addProfileSaver()
  local page = builder.Page()
  local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  label:SetPoint("TOPLEFT", Builder.MARGIN, builder.RowY() - PROFILE_LABEL_OFFSET)
  local nameBox = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
  nameBox:SetSize(PROFILE_NAME_WIDTH, Builder.BUTTON_HEIGHT)
  nameBox:SetAutoFocus(false)
  nameBox:SetPoint("LEFT", label, "RIGHT", Builder.CHOOSER_TAB_GAP + PROFILE_BOX_BORDER, 0)  -- Rand links außerhalb
  local saveButton = Widgets.CreateButton(page, PROFILE_SAVE_WIDTH, Builder.BUTTON_HEIGHT, function()
    ns.ConfirmProfileSave(nameBox:GetText(), function() nameBox:SetText("") end)
  end)
  saveButton:SetPoint("LEFT", nameBox, "RIGHT", Builder.CHOOSER_TAB_GAP, 0)
  builder.AddTooltip(saveButton, "PROFILE_SAVE_TIP", localized("PROFILE_SAVE"))
  builder.AddTooltip(nameBox, "PROFILE_NEW_NAME_TIP", localized("PROFILE_NEW_NAME"))
  local function updateSaveButton()
    saveButton:SetEnabled(strtrim(nameBox:GetText() or "") ~= "")
  end
  nameBox:SetScript("OnTextChanged", updateSaveButton)
  nameBox:SetScript("OnEnterPressed", function() saveButton:Click() end)
  nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  builder.Advance(Builder.ROW_BUTTON)
  builder.OnRefresh(function()
    label:SetText(L.PROFILE_NEW_NAME)
    Widgets.SetButtonText(saveButton, L.PROFILE_SAVE, PROFILE_SAVE_WIDTH)
    updateSaveButton()
  end)
  builder.profileNameBox, builder.profileSaveButton = nameBox, saveButton  -- Tests
end

local function percent(value)
  return value .. "%"
end

local function toPercent(fraction)
  return math.floor(fraction * 100 + 0.5)
end

-- Aussehen aller Anzeigen (Theme.lua): Preset, Akzentfarbe, Schriftart, -größe und Kontur
local function addThemeSection()
  local Theme = ns.Theme
  local presets = {}
  for i, key in ipairs(Theme.ORDER) do
    presets[i] = { value = key, name = localized("THEME_PRESET_" .. key:upper()) }
  end
  addChooser({ label = "THEME", setting = "theme", choices = presets })
  local accents = {}
  for i, key in ipairs(Theme.ACCENT_ORDER) do
    accents[i] = { value = key, name = localized(key == "" and "ACCENT_DEFAULT" or "ACCENT_" .. key:upper()) }
  end
  addChooser({ label = "THEME_ACCENT", setting = "themeAccent", choices = accents })
  builder.AddCycleButton({
    label = "THEME_FONT",
    advanced = true,
    setting = "themeFont",
    choices = Theme.FontChoices,
    get = function(db) return db.themeFont end,
    set = function(key) ns.Set("themeFont", key) end,
    nameOf = function(key) return key == "" and L.THEME_FONT_DEFAULT or key end,
  })
  addSlider({
    label = "THEME_FONT_SIZE",
    setting = "themeFontSize",
    min = Theme.MIN_FONT_OFFSET,
    max = Theme.MAX_FONT_OFFSET,
    step = 1,
    get = function(db) return db.themeFontSize end,
    set = function(value) ns.SetDeferred("themeFontSize", value) end,
    format = function(value) return value > 0 and "+" .. value or tostring(value) end,
  })
  addOutlineChooser()
  -- Lesbarkeit: Untergrenze der effektiven Schriftgröße (auch gegen kleine Anzeigen), Balkentextur, Farbe nach Wert
  builder.AddCycleButton({
    label = "THEME_MIN_FONT_SIZE",
    advanced = true,
    setting = "themeMinFontSize",
    choices = function()
      local choices = {}
      for i, size in ipairs(Theme.MIN_READABLE_SIZES) do choices[i] = { key = size } end
      return choices
    end,
    get = function(db) return db.themeMinFontSize end,
    set = function(size) ns.Set("themeMinFontSize", size) end,
    nameOf = function(size) return size == 0 and L.THEME_MIN_FONT_OFF or string.format(L.FONT_POINTS, size) end,
  })
  builder.AddCycleButton({
    label = "THEME_BAR_TEXTURE",
    advanced = true,
    setting = "themeBarTexture",
    choices = Theme.BarTextureChoices,
    get = function(db) return db.themeBarTexture end,
    set = function(key) ns.Set("themeBarTexture", key) end,
    nameOf = function(key)
      if key == "" then return L.BAR_TEXTURE_FLAT end
      for _, bar in ipairs(Theme.BUILTIN_BARS) do
        if bar.key == key then return L["BAR_TEXTURE_" .. key:upper()] end
      end
      return key
    end,
  })
  addToggles({ advanced(toggle("VALUE_COLORS", "valueColors")) })
end

-- Sichtbarkeitsregel einer Anzeige (DisplayVisibility.lua) als Zyklus-Button: Linksklick nächste, Rechtsklick vorige
local function addVisibilityCycle(label, setting)
  builder.AddCycleButton({
    label = label,
    setting = setting,
    choices = function()
      local choices = {}
      for i, mode in ipairs(ns.DisplayVisibility.MODES) do choices[i] = { key = mode } end
      return choices
    end,
    get = function(db) return db[setting] end,
    set = function(key) ns.Set(setting, key) end,
    nameOf = function(key) return L["VISIBILITY_" .. key:upper()] end,
  })
end

-- Anzeige: Layout des Hauptfensters (UI/Layouts/), Einstellungen nur des gewählten Layouts (sonst ausgegraut),
-- gewählte Werte. Wirkt sofort, auch im Edit-Modus (Vorschau = das echte Fenster).
local function addDisplaySection()
  local Layouts, WindowModel = ns.WindowLayouts, ns.WindowModel
  addSection("SECTION_DISPLAY")
  local choices = {}
  for i, id in ipairs(Layouts.ORDER) do choices[i] = { value = id, name = localized(Layouts.Get(id).label) } end
  addChooser({ label = "WINDOW_LAYOUT", setting = "windowLayout", choices = choices })
  local function layoutIs(...)
    local ids = { ... }
    return function(db)
      for _, id in ipairs(ids) do
        if Layouts.Get(db.windowLayout).id == id then return true end
      end
      return false
    end
  end

  -- Gewählte Werte (compactRows) für Kompakt, Uhr und XP-Balken: je Stelle ein Zyklus-Button über alle Zeilen
  local function rowChoices()
    local list = { { key = "" } }
    for _, row in ipairs(WindowModel.AllRows()) do
      if WindowModel.IsRowAvailable(row.key) then table.insert(list, { key = row.key }) end
    end
    return list
  end
  local usesChosenRows = function(db) return Layouts.Get(db.windowLayout).source == WindowModel.CHOSEN end
  for index = 1, WindowModel.MAX_CHOSEN_ROWS do
    builder.AddCycleButton({
      label = "CHOSEN_ROW_" .. index,
      setting = "compactRows",
      choices = rowChoices,
      get = function(db) return WindowModel.ChosenRowKey(db, index) end,
      set = function(key) WindowModel.SetChosenRow(ns.db, index, key) end,
      nameOf = function(key) return key == "" and L.CHOSEN_ROW_NONE or L[key] end,
      enabled = usesChosenRows,
    })
  end
  local textToggle = toggle("TEXT_LABELS", "textLabels")
  textToggle.enabled = layoutIs("text")
  textToggle.advanced = true
  addToggles({ textToggle })
  addSlider({
    label = "TILE_COLUMNS",
    advanced = true,
    setting = "tileColumns",
    min = Layouts.Tiles.MIN_COLUMNS,
    max = Layouts.Tiles.MAX_COLUMNS,
    step = 1,
    get = function(db) return db.tileColumns end,
    set = function(value) ns.SetDeferred("tileColumns", value) end,
    format = tostring,
    enabled = layoutIs("tiles"),
  })
  local textModes = {}
  for i, mode in ipairs(Layouts.XpBar.MODES) do textModes[i] = { value = mode, name = localized("XPBAR_TEXT_" .. mode:upper()) } end
  addChooser({ label = "XPBAR_TEXT", setting = "xpbarText", choices = textModes, enabled = layoutIs("xpbar") })
  addSlider({
    label = "XPBAR_WIDTH",
    advanced = true,
    setting = "xpbarWidth",
    min = Layouts.XpBar.MIN_WIDTH,
    max = Layouts.XpBar.MAX_WIDTH,
    step = 20,
    get = function(db) return db.xpbarWidth end,
    set = function(value) ns.SetDeferred("xpbarWidth", value) end,
    format = tostring,
    enabled = layoutIs("xpbar"),
  })
end

-- Sichtbarkeit des Hauptfensters (immer, im Kampf, ...) und Deckkraft beim Ausblenden
local function addVisibilitySection()
  addVisibilityCycle("WINDOW_VISIBILITY", "windowVisibility")
  addSlider({
    label = "FADE_ALPHA",
    advanced = true,
    setting = "fadeAlpha",
    min = 0,
    max = 100,
    step = 5,
    get = function(db) return toPercent(db.fadeAlpha) end,
    set = function(value) ns.SetDeferred("fadeAlpha", value / 100) end,
    format = percent,
  })
end

-- Reihenfolge der Stat-Zeilen (rowOrder): Stat wählen (nur eingeschaltete), dann nach oben oder unten
local function addRowOrderSection()
  local WindowModel = ns.WindowModel
  local selected  -- gewählte Stat-Einstellung; ohne Wahl die erste eingeschaltete
  local function current(db)
    local shown = WindowModel.ShownStats(db)
    for _, stat in ipairs(shown) do
      if stat.setting == selected then return selected end
    end
    return shown[1] and shown[1].setting or ""
  end
  addSection("SECTION_ROW_ORDER", { advanced = true })
  builder.AddCycleButton({
    label = "ROW_ORDER_STAT",
    advanced = true,
    setting = "rowOrder",
    choices = function()
      local list = {}
      for i, stat in ipairs(WindowModel.ShownStats(ns.db)) do list[i] = { key = stat.setting, label = stat.label } end
      if #list == 0 then list[1] = { key = "" } end
      return list
    end,
    get = current,
    set = function(key)
      selected = key
      builder.Refresh(ns.db)
    end,
    nameOf = function(key)
      for _, stat in ipairs(ns.STAT_LINES) do
        if stat.setting == key then return L[stat.label] end
      end
      return L.ROW_ORDER_NONE
    end,
  })
  local function move(delta)
    return function()
      selected = current(ns.db)
      if selected ~= "" then WindowModel.MoveStat(ns.db, selected, delta) end
    end
  end
  builder.AddButtonRow({
    { label = "ROW_ORDER_UP", onClick = move(-1) },
    { label = "ROW_ORDER_DOWN", onClick = move(1) },
    { label = "ROW_ORDER_RESET", onClick = function() ns.Set("rowOrder", "") end },
  }, { advanced = true })
end

-- Größe einer Anzeige (Lib/Frames.lua, db.frames[id].scale); der Edit-Modus kann sie auch per Mausrad ändern;
-- enabled(db) optional (ausgegraut, solange die Anzeige aus ist), isAdvanced optional (nur mit allen Optionen)
local function addFrameScaleSlider(label, id, enabled, isAdvanced)
  local Frames = ns.Frames
  addSlider({
    label = label,
    advanced = isAdvanced,
    enabled = enabled,
    min = toPercent(Frames.MIN_SCALE),
    max = toPercent(Frames.MAX_SCALE),
    step = 5,
    get = function() return toPercent(Frames.GetScale(id)) end,
    set = function(value) Frames.SetScale(id, value / 100) end,
    format = percent,
    reset = { get = function() return Frames.GetStoredScale(id) end, set = function(scale) Frames.SetStoredScale(id, scale) end,
      default = function() return nil end },
  })
end

---------------------------------------------------------------------------
-- Inhalt
---------------------------------------------------------------------------

-- Jeder größere Reiter hat eine Seitenleiste mit Kategorien wie Komfort (Leatrix-Stil); die Fensterhöhe richtet
-- sich nach der längsten Unterseite. Kategorie-Namen: OPTIONS_PAGE_* (Komfort: COMFORT_PAGE_*).
local addSubPage, finishSubPages = builder.AddSubPage, builder.FinishSubPages

-- Quest-XP auf dem XP-Balken: nur mit Balken (Schalter oder Layout "xpbar", das ihn immer zeigt)
local function requiresBar(definition)
  definition.enabled = function(db) return db.showXpBar or ns.WindowLayouts.Get(db.windowLayout).alwaysXpBar == true end
  return definition
end

-- Minimap-Button an/aus (Zurücksetzen je Unterseite): nur hide, nicht die Position am Rand
local minimapReset = {
  get = function() return ns.db.minimap.hide end,
  set = function(hidden) ns.db.minimap.hide = hidden end,
  default = function() return ns.Database.SettingDefault("minimap").hide end,
}

-- Allgemein: Hauptfenster (mit Minimap-Knopf), Layout, Aussehen, Sprache, Stream
addPage("SECTION_GENERAL")
addSubPage("OPTIONS_PAGE_WINDOW")
addFrameScaleSlider("WINDOW_SIZE", "main")
addSlider({
  label = "BG_OPACITY",
  setting = "bgAlpha",
  min = 0,
  max = 100,
  step = 5,
  get = function(db) return toPercent(db.bgAlpha) end,
  set = function(value) ns.SetDeferred("bgAlpha", value / 100) end,
  format = percent,
})
addToggles({
  toggle("SHOW_TIMER", "showTimer"),
  toggle("LOCK_FRAME", "locked"),
  toggle("SHOW_XP_BAR", "showXpBar"),
  toggle("AUTO_INSTANCE_TAB", "autoInstanceTab"),
  advanced(requiresBar(toggle("QUEST_XP_ON_BAR", "questXpOnBar"))),
  advanced(toggle("EDIT_MODE_WITH_BLIZZARD", "editModeWithBlizzard", function() return EditModeManagerFrame ~= nil end)),
  -- Knopf an der Minimap gehört zu den Level-Time-Fenstern, nicht zur Sprache (UX S20)
  { label = "SHOW_MINIMAP", get = function(db) return not db.minimap.hide end,
    set = function(checked) ns.SetMinimapHidden(not checked) end, reset = minimapReset },
})
addVisibilitySection()
addHint("OPTIONS_HINT")
addSubPage("OPTIONS_PAGE_LAYOUT")
addDisplaySection()
addSubPage("OPTIONS_PAGE_LOOK")
addThemeSection()
addSubPage("SECTION_LANGUAGE")
addLanguageChooser()
-- Stream: alles, was nur für Streams gedacht ist (Speedrun hat einen eigenen Reiter), dazu Abkürzungen zu Layout und
-- Kontur, die für OBS zählen (UX S18)
addSubPage("OPTIONS_TAB_STREAM")
addHint("STREAM_MODE_HINT")
addToggles({
  { label = "STREAM_MODE", get = function() return ns.StreamMode.IsEnabled() end,
    set = function(checked) ns.StreamMode.SetEnabled(checked) end },
  toggle("STREAMER_PRIVACY", "streamerPrivacy"),
  toggle("HIGHLIGHT_DEATHS", "highlightDeaths"),
  -- Abkürzung zu "Minimap-Knopf anzeigen" (Allgemein > Hauptfenster), umgekehrt formuliert
  { label = "STREAM_HIDE_MINIMAP", get = function(db) return db.minimap.hide end,
    set = function(checked) ns.SetMinimapHidden(checked) end, reset = minimapReset },
})
addSection("SECTION_STREAM_OBS")
addHint("STREAM_OBS_HINT")
addStreamLayoutChooser()
addBackgroundChooser()
addOutlineChooser()
finishSubPages()
finishPage()

-- Statistiken: Voreinstellungen über allen Kategorien, dann je Stat-Gruppe eine Unterseite mit einem Schalter je
-- Stat-Zeile direkt aus ns.STAT_LINES; Reihenfolge und Berechnung eigene Unterseiten
local STAT_GROUP_PAGES = {
  STAT_GROUP_XP = "OPTIONS_PAGE_STAT_XP",
  STAT_GROUP_PROGRESS = "OPTIONS_PAGE_STAT_PROGRESS",
  STAT_GROUP_COMBAT = "OPTIONS_PAGE_STAT_COMBAT",
  STAT_GROUP_LOOT = "OPTIONS_PAGE_STAT_LOOT",
  STAT_GROUP_INSTANCE = "OPTIONS_PAGE_STAT_INSTANCE",
  STAT_GROUP_TIME_MONEY = "OPTIONS_PAGE_STAT_TIME_MONEY",
}
addPage("STATISTICS")
addSection("SECTION_STAT_PRESETS")
local presetButtons = {}
for i, preset in ipairs(ns.STAT_PRESETS) do
  presetButtons[i] = { label = preset.label, onClick = function() ns.ApplyStatPreset(preset) end }
end
table.insert(presetButtons, { label = "PRESET_UNDO", onClick = function() ns.UndoStatPreset() end })
builder.AddButtonRow(presetButtons)
for _, group in ipairs(ns.STAT_GROUPS) do
  addSubPage(STAT_GROUP_PAGES[group] or group)  -- neue Gruppe ohne eigenen Kurznamen: Gruppenname
  local statToggles = {}
  for _, line in ipairs(ns.STAT_LINES) do
    if line.group == group then table.insert(statToggles, toggle(line.label, line.setting, line.available)) end
  end
  addToggles(statToggles)
  if group == "STAT_GROUP_INSTANCE" then
    addButton("INSTANCE_RESET", function() ns.Instances.ConfirmReset() end)
  end
end
addSubPage("OPTIONS_PAGE_ROW_ORDER")
addRowOrderSection()
addSubPage("OPTIONS_PAGE_CALCULATION")
addToggles({ advanced(toggle("XP_RATE_WITHOUT_AFK", "xpRateWithoutAfk")) })
addSlider({
  label = "IDLE_LIMIT",
  advanced = true,
  setting = "idleMinutes",
  min = ns.TimeBreakdown.MIN_IDLE_MINUTES,
  max = ns.TimeBreakdown.MAX_IDLE_MINUTES,
  step = 1,
  get = function(db) return db.idleMinutes end,
  set = function(value) ns.SetDeferred("idleMinutes", value) end,
  format = function(value) return value == 0 and L.IDLE_LIMIT_OFF or string.format(L.MINUTES, value) end,
})
addSlider({
  label = "TO_LEVEL_SAMPLES",
  advanced = true,
  setting = "toLevelSamples",
  min = ns.Experience.MIN_TO_LEVEL_SAMPLES,
  max = ns.Experience.MAX_TO_LEVEL_SAMPLES,
  step = 5,
  get = function(db) return db.toLevelSamples end,
  set = function(value) ns.SetDeferred("toLevelSamples", value) end,
  format = function(value)
    return value == 0 and L.TO_LEVEL_SAMPLES_LEVEL or string.format(L.TO_LEVEL_SAMPLES_VALUE, value)
  end,
})
finishSubPages()
finishPage()

-- Chat & Erinnerungen: Login und Rekorde, Erinnerungen, Warnungen, Gruppe und Heiler (Quest-Hinweise stehen unter
-- Komfort > Quests, alles zum Level-Up unter Einblendungen > Level-Up)
addPage("OPTIONS_TAB_NOTIFICATIONS")
addSubPage("OPTIONS_PAGE_LOGIN")
addHint("LEVEL_UP_MOVED_HINT")  -- alles zum Level-Up steht gesammelt unter Einblendungen > Level-Up
addSection("SECTION_AT_LOGIN")
addToggles({ toggle("RESTED_ALT_NOTICE_TOGGLE", "restedAltNotice"),
  toggle("SESSION_COMPARE_TOGGLE", "sessionCompareLogin") })
addSection("SECTION_PERSONAL_RECORDS")
addToggles({ toggle("ANNOUNCE_RECORDS_TOGGLE", "announceRecords") })

addSubPage("OPTIONS_PAGE_REMINDERS")
addSection("SECTION_REMINDERS")
addToggles({
  toggle("REMIND_FOOD_TOGGLE", "remindFood"),
  toggle("REMIND_CAMP_TOGGLE", "remindCamp", ns.BuffReminder.HasCampSystem),
  toggle("REMIND_SLEEPING_BAG_TOGGLE", "remindSleepingBag", ns.BuffReminder.HasSleepingBagSystem),
  toggle("REMIND_CHARGED_TOGGLE", "remindCharged", ns.BuffReminder.HasChargedSystem),
  toggle("REMIND_TRAINER_TOGGLE", "remindTrainer", ns.TrainerReminder.IsAvailable),
})
-- Wiederholung gilt für alle Buff-Erinnerungen (auch die Klassen-Buffs darunter)
addSlider({
  label = "REMINDER_INTERVAL",
  advanced = true,
  setting = "reminderInterval",
  min = ns.BuffReminder.MIN_INTERVAL,
  max = ns.BuffReminder.MAX_INTERVAL,
  step = 1,
  get = function(db) return db.reminderInterval end,
  set = function(value) ns.SetDeferred("reminderInterval", value) end,
  format = function(value) return string.format(L.MINUTES, value) end,
})
-- Klassen-Buffs: nur die der eigenen Klasse; Beschriftung mit den Zaubernamen in der Sprache des Clients
local classReminders = ns.ClassBuffs.ForPlayerClass()
if #classReminders > 0 then
  addSection("SECTION_CLASS_REMINDERS")
  local classToggles = {}
  for _, reminder in ipairs(classReminders) do
    local classToggle = toggle("REMIND_CLASS_TOGGLE", reminder.setting)
    classToggle.text = function() return ns.ClassBuffs.Label(reminder) end
    classToggle.tip = ns.ClassBuffs.TipKey(reminder)
    table.insert(classToggles, classToggle)
  end
  addToggles(classToggles)
end
-- Pausen-Erinnerung (BreakReminder.lua)
addSection("SECTION_BREAKS")
addToggles({ toggle("REMIND_BREAK_TOGGLE", "remindBreak") })
addSlider(requires({
  label = "BREAK_MINUTES",
  advanced = true,
  setting = "breakMinutes",
  min = ns.BreakReminder.MIN_MINUTES,
  max = ns.BreakReminder.MAX_MINUTES,
  step = 15,
  get = function(db) return db.breakMinutes end,
  set = function(value) ns.SetDeferred("breakMinutes", value) end,
  format = function(value) return string.format(L.MINUTES, value) end,
}, "remindBreak"))

addSubPage("OPTIONS_PAGE_WARNINGS")
addHint("WARN_LOOK_HINT")
addToggles({
  toggle("WARN_BAGS_FULL_TOGGLE", "warnBagsFull"),
  toggle("WARN_DURABILITY_TOGGLE", "warnDurability"),
  toggle("WARN_AMMO_TOGGLE", "warnAmmo", ns.GearWarnings.ShowsAmmoOptions),
  toggle("WARN_INSTANCE_LIMIT_TOGGLE", "warnInstanceLimit"),
  toggle("WARN_AGGRO_TOGGLE", "warnAggro"),
  toggle("WARN_BREATH_TOGGLE", "warnBreath"),
  toggle("EMERGENCY_TOGGLE", "emergencyHighlight", ns.Emergency.IsAvailable),
})
addSlider(requires({
  label = "WARN_BREATH_BELOW",
  advanced = true,
  setting = "breathWarnSeconds",
  min = ns.BreathWarning.MIN_SECONDS,
  max = ns.BreathWarning.MAX_SECONDS,
  step = 1,
  get = function(db) return db.breathWarnSeconds end,
  set = function(value) ns.SetDeferred("breathWarnSeconds", value) end,
  format = function(value) return string.format(L.SECONDS_SHORT, value) end,
}, "warnBreath"))
-- Munition: nur für Jäger
if ns.GearWarnings.ShowsAmmoOptions() then
  addSlider(requires({
    label = "WARN_AMMO_BELOW",
    setting = "ammoLow",
    min = ns.GearWarnings.MIN_AMMO,
    max = ns.GearWarnings.MAX_AMMO,
    step = 20,
    get = function(db) return db.ammoLow end,
    set = function(value) ns.SetDeferred("ammoLow", value) end,
    format = function(value) return string.format(L.AMMO_COUNT, value) end,
  }, "warnAmmo"))
  addSlider(requires({
    label = "WARN_AMMO_CRITICAL_BELOW",
    advanced = true,
    setting = "ammoCritical",
    min = 0,
    max = ns.GearWarnings.MAX_CRITICAL_AMMO,
    step = 10,
    get = function(db) return db.ammoCritical end,
    set = function(value) ns.SetDeferred("ammoCritical", value) end,
    format = function(value) return value == 0 and L.AMMO_OFF or string.format(L.AMMO_COUNT, value) end,
  }, "warnAmmo"))
  addSlider(requires({
    label = "WARN_AMMO_REPEAT",
    advanced = true,
    setting = "ammoRepeat",
    min = 0,
    max = ns.GearWarnings.MAX_AMMO_REPEAT,
    step = 1,
    get = function(db) return db.ammoRepeat end,
    set = function(value) ns.SetDeferred("ammoRepeat", value) end,
    format = function(value) return value == 0 and L.AMMO_ONCE or string.format(L.MINUTES, value) end,
  }, "warnAmmo"))
end

-- Gruppe und Heiler: Ansagen im Gruppenchat
addSubPage("OPTIONS_PAGE_GROUP")
addToggles({
  toggle("LOW_MANA_TOGGLE", "announceLowMana"),
  toggle("CC_ANNOUNCE_TOGGLE", "announceControlLoss"),
  toggle("CC_OVER_TOGGLE", "announceControlOver"),
  toggle("HEALER_AGGRO_TOGGLE", "announceHealerAggro"),
  toggle("INSTANCE_REPORT_TOGGLE", "announceInstanceReport"),
  toggle("INSTANCE_REPORT_LOOT_TOGGLE", "instanceReportLoot"),
})
addChooser(requires({
  label = "INSTANCE_REPORT_LOOT_QUALITY",
  advanced = true,
  setting = "instanceReportLootQuality",
  choices = {
    { value = 3, name = localized("INSTANCE_REPORT_LOOT_RARE") },
    { value = 4, name = localized("INSTANCE_REPORT_LOOT_EPIC") },
  },
}, "instanceReportLoot"))
addSlider(requires({
  label = "INSTANCE_REPORT_LOOT_MAX",
  advanced = true,
  setting = "instanceReportLootMax",
  min = 1,
  max = 10,
  step = 1,
  get = function(db) return db.instanceReportLootMax end,
  set = function(value) ns.SetDeferred("instanceReportLootMax", value) end,
  format = function(value) return tostring(value) end,
}, "instanceReportLoot"))
addSlider(requires({
  label = "LOW_MANA_BELOW",
  advanced = true,
  setting = "lowManaPercent",
  min = ns.ManaCallout.MIN_PERCENT,
  max = ns.ManaCallout.MAX_PERCENT,
  step = 5,
  get = function(db) return db.lowManaPercent end,
  set = function(value) ns.SetDeferred("lowManaPercent", value) end,
  format = percent,
}, "announceLowMana"))
finishSubPages()
finishPage()

-- Einblendungen: welche Ereignisse, Aussehen und Position (Hinweise aus Chat & Erinnerungen nutzen dieselbe) und
-- alles zum Level-Up an einem Ort: Fenster, Einblendung, Chatzeile und Ansage (UX S11). Timer und Flüge stehen unter
-- Komfort > Timer & Flüge.
addPage("OPTIONS_TAB_ALERTS")
addSubPage("OPTIONS_PAGE_ALERT_KINDS")
addSection("SECTION_ALERTS")
addToggles({
  toggle("ALERT_TOGGLE_RARE", "alertRareKill"),
  toggle("ALERT_TOGGLE_ELITE", "alertEliteKill"),
  toggle("ALERT_TOGGLE_LOOT", "alertEpicLoot"),
  toggle("ALERT_TOGGLE_NEAR_DEATH", "alertNearDeath", ns.NearDeath.IsAvailable),
  toggle("ALERT_TOGGLE_RARE_SPOTTED", "alertRareSpotted"),
  requires(toggle("ALERT_TOGGLE_RARE_FLASH", "alertRareFlash"), "alertRareSpotted"),
})
addHint("QUEST_ALERTS_HINT")  -- Quest-Einblendungen stehen bei den Quests, die zum Level-Up auf der Seite Level-Up
addSubPage("OPTIONS_PAGE_ALERT_LOOK")
addChooser({ label = "ALERT_STYLE", setting = "alertStyle", choices = {
  { value = Alerts.STYLE_BANNER, name = localized("ALERT_STYLE_BANNER") },
  { value = Alerts.STYLE_TEXT, name = localized("ALERT_STYLE_TEXT") },
} })
addFrameScaleSlider("ALERT_SCALE", "alert")
addSlider({
  label = "ALERT_DURATION",
  advanced = true,
  setting = "alertDuration",
  min = Alerts.MIN_DURATION,
  max = Alerts.MAX_DURATION,
  step = 1,
  get = function(db) return db.alertDuration end,
  set = function(value) ns.SetDeferred("alertDuration", value) end,
  format = function(value) return string.format(L.SECONDS_SHORT, value) end,
})
addToggles({ toggle("ALERT_SOUND", "alertSound") })
addButton("ALERT_PREVIEW", function() Alerts.Preview() end)
addSubPage("OPTIONS_PAGE_LEVEL_UP")
addSection("SECTION_LEVEL_UP_WINDOW")
addToggles({
  toggle("LEVEL_UP_WINDOW_TOGGLE", "levelUpWindow"),
  requires(toggle("LEVEL_UP_HIDE_BLIZZARD", "levelUpHideBlizzard"), "levelUpWindow"),
  requires(toggle("LEVEL_UP_COMPACT", "levelUpCompact"), "levelUpWindow"),
  requires(toggle("LEVEL_UP_SOUND", "levelUpSound"), "levelUpWindow"),
})
local function levelUpWindowOn(db) return db.levelUpWindow end
addChooser({ label = "LEVEL_UP_THEME", setting = "levelUpTheme", enabled = levelUpWindowOn, choices = {
  { value = "modern", name = localized("THEME_MODERN") },
  { value = "alliance", name = localized("THEME_ALLIANCE") },
  { value = "horde", name = localized("THEME_HORDE") },
} })
addFrameScaleSlider("LEVEL_UP_SCALE", "levelUp", levelUpWindowOn)
addSlider(requires({
  label = "LEVEL_UP_DURATION",
  advanced = true,
  setting = "levelUpDuration",
  min = ns.LevelUpWindow.MIN_DURATION,
  max = ns.LevelUpWindow.MAX_DURATION,
  step = 1,
  get = function(db) return db.levelUpDuration end,
  set = function(value) ns.SetDeferred("levelUpDuration", value) end,
  format = function(value) return string.format(L.SECONDS_SHORT, value) end,
}, "levelUpWindow"))
addButton("LEVEL_UP_PREVIEW", function() ns.LevelUpWindow.Preview() end)
if ns.TrainerCache.IsAvailable() then addHint("LEVEL_UP_TRAINER_HINT") end

addSection("SECTION_LEVEL_UP_BANNER")
-- Die Einblendung kommt nur ohne Level-Up-Fenster (das zeigt dieselben Zuwächse, AlertTriggers.lua)
local levelUpBanner = toggle("ALERT_TOGGLE_LEVEL_UP", "alertLevelUp")
levelUpBanner.enabled = function(db) return not db.levelUpWindow end
addToggles({ levelUpBanner })
addHint("LEVEL_UP_BANNER_HINT")
addSection("SECTION_LEVEL_UP_CHAT")
addToggles({ toggle("LEVEL_UP_SUMMARY_TOGGLE", "levelUpSummary"), toggle("LEVEL_UP_GAINS_TOGGLE", "levelUpGains") })
addAnnounceChooser()
finishSubPages()
finishPage()

-- Komfort: Seitenleiste mit Kategorien wie bei Leatrix Plus
addPage("OPTIONS_TAB_COMFORT")
addHint("COMFORT_HINT")
addSubPage("COMFORT_PAGE_AUTOMATION")
addHint("AUTOMATION_QUESTS_HINT")  -- Quest-Automatik steht bei den Quests
addSection("SECTION_MERCHANT")
addToggles({
  toggle("AUTO_REPAIR", "autoRepair"),
  requires(toggle("AUTO_REPAIR_GUILD", "autoRepairGuild", ns.Client.HasGuildBank), "autoRepair"),
  toggle("AUTO_SELL_JUNK", "autoSellJunk"),
  toggle("TRAIN_ALL_TOGGLE", "trainAllButton", ns.TrainerCache.IsAvailable),
})
addSection("SECTION_CHARACTER")
addToggles({
  toggle("AUTO_ACCEPT_SUMMON", "autoAcceptSummon"),
  toggle("AUTO_ACCEPT_RESURRECT", "autoAcceptResurrect"),
  advanced(toggle("AUTO_RELEASE_PVP", "autoReleasePvP")),
})
addSubPage("COMFORT_PAGE_SOCIAL")
addSection("SECTION_DECLINE")
addToggles({
  toggle("DECLINE_TRADES", "declineTrades"),
  toggle("DECLINE_GROUP_INVITES", "declineGroupInvites"),
  toggle("DECLINE_GUILD_INVITES", "declineGuildInvites"),
  toggle("DECLINE_DUELS", "declineDuels"),
  toggle("DECLINE_SHARED_QUESTS", "declineSharedQuests"),
  advanced(toggle("BLOCK_FRIEND_REQUESTS", "blockFriendRequests", ns.Social.CanBlockFriendRequests)),
})
-- Einladungen: Vertraute = Freunde, Gilde und wahlweise Communities (Friends.lua); declineGroupInvites lehnt sie dann nicht ab
addSection("SECTION_INVITES")
addToggles({
  toggle("ACCEPT_FRIEND_INVITES", "acceptFriendInvites"),
  toggle("INVITE_INFO_TOGGLE", "inviteInfo"),
  toggle("INVITE_FROM_WHISPER", "inviteFromWhisper"),
  advanced(toggle("FRIENDLY_COMMUNITIES", "friendlyCommunities", ns.Friends.CanUseCommunities)),
})
builder.AddTextInput({
  label = "INVITE_KEYWORD",
  advanced = true,
  setting = "inviteKeyword",
  get = function(db) return db.inviteKeyword end,
  set = function(text) ns.Set("inviteKeyword", strtrim(text)) end,
})
addSubPage("COMFORT_PAGE_CHAT")
addSection("SECTION_CHAT")
addToggles({
  toggle("CHAT_COPY_TOGGLE", "chatCopyButton"),
  toggle("RESTORE_CHAT", "restoreChat"),
  toggle("FILTER_DRUNK_SPAM", "filterDrunkSpam"),
  toggle("FILTER_SPELL_LINKS", "filterSpellLinks"),
  advanced(toggle("UNIVERSAL_GROUP_COLOR", "universalGroupColor", ns.ChatColors.IsAvailable)),
})
addSection("SECTION_CHAT_WINDOWS")
addToggles({
  toggle("HIDE_COMBAT_LOG_TAB", "hideCombatLogTab"),
  toggle("HIDE_CHAT_BUTTONS", "hideChatButtons"),
  advanced(toggle("CHAT_EDIT_BOX_TOP", "chatEditBoxTop")),
  advanced(toggle("CHAT_ARROW_KEYS", "chatArrowKeys")),
  toggle("NO_CHAT_FADE", "noChatFade"),
  advanced(toggle("UNCLAMP_CHAT", "unclampChat")),
  advanced(toggle("CHAT_FONT_OVERRIDE", "chatFontOverride", ns.ChatFontSize.IsAvailable)),
})
if ns.ChatFontSize.IsAvailable() then
  addSlider({
    label = "CHAT_FONT_SIZE",
    advanced = true,
    min = ns.ChatFontSize.MIN,
    max = ns.ChatFontSize.MAX,
    step = 1,
    get = function(db) return db.chatFontSize end,
    set = function(value) ns.SetDeferred("chatFontSize", value) end,
    format = function(value) return tostring(value) end,
    enabled = function(db) return db.chatFontOverride end,
  })
end
addSubPage("COMFORT_PAGE_INTERFACE")
addSection("SECTION_SCREEN_TEXT")
addToggles({
  toggle("HIDE_ERRORS", "hideErrors"),
  toggle("HIDE_ZONE_TEXT", "hideZoneText"),
})
-- Schwarze Ränder über der Spielwelt (unter der Oberfläche)
addSection("SECTION_SCREEN_BORDERS")
addToggles({ toggle("SCREEN_BORDERS", "screenBorders") })
addSlider({
  label = "SCREEN_BORDER_TOP",
  advanced = true,
  min = 0,
  max = ns.ScreenBorders.MAX_SIZE,
  step = ns.ScreenBorders.STEP,
  get = function(db) return db.screenBorderTop end,
  set = function(value) ns.SetDeferred("screenBorderTop", value) end,
  format = function(value) return tostring(value) end,
  enabled = function(db) return db.screenBorders end,
})
addSlider({
  label = "SCREEN_BORDER_BOTTOM",
  advanced = true,
  min = 0,
  max = ns.ScreenBorders.MAX_SIZE,
  step = ns.ScreenBorders.STEP,
  get = function(db) return db.screenBorderBottom end,
  set = function(value) ns.SetDeferred("screenBorderBottom", value) end,
  format = function(value) return tostring(value) end,
  enabled = function(db) return db.screenBorders end,
})
addSlider({
  label = "SCREEN_BORDER_SIDES",
  advanced = true,
  min = 0,
  max = ns.ScreenBorders.MAX_SIZE,
  step = ns.ScreenBorders.STEP,
  get = function(db) return db.screenBorderSides end,
  set = function(value) ns.SetDeferred("screenBorderSides", value) end,
  format = function(value) return tostring(value) end,
  enabled = function(db) return db.screenBorders end,
})
addSection("SECTION_ACTION_BARS")
addToggles({
  toggle("HIDE_KEYBIND_TEXT", "hideKeybindText"),
  toggle("HIDE_MACRO_TEXT", "hideMacroText"),
  toggle("RANGE_COLOR", "rangeColor"),
})
-- Ausblenden (UX S15: alles an einem Ort): ein Schalter je Element der Liste in BlizzardHide.lua, auch die mit eigener
-- Einstellung (Erfahrungs-, Ruf- und Haltungsleiste, Kalender, Chat-Knöpfe; Kalender und Chat-Knöpfe stehen zusätzlich
-- bei Minimap und Chat); auch im Edit-Modus direkt am Element schaltbar. In Gruppen mit einklappbaren Überschriften
-- (Roadmap 406); unbekannte Einträge landen unter "Weitere"
local BLIZZARD_GROUPS = {
  { section = "SECTION_BLIZZ_UNIT_FRAMES", labels = { "BLIZZ_FRAME_PLAYER", "BLIZZ_FRAME_TARGET", "BLIZZ_FRAME_FOCUS",
    "BLIZZ_FRAME_PARTY", "BLIZZ_FRAME_PET", "BLIZZ_FRAME_BOSS", "BLIZZ_FRAME_ARENA", "BLIZZ_FRAME_CAST_BAR" } },
  { section = "SECTION_BLIZZ_MINIMAP_BUFFS", labels = { "BLIZZ_FRAME_MINIMAP", "BLIZZ_FRAME_ZONE_TEXT", "BLIZZ_FRAME_CLOCK",
    "BLIZZ_FRAME_CALENDAR", "BLIZZ_FRAME_BUFFS", "BLIZZ_FRAME_DEBUFFS", "BLIZZ_FRAME_TRACKER" } },
  { section = "SECTION_BLIZZ_BARS", labels = { "BLIZZ_FRAME_MAIN_BAR", "BLIZZ_FRAME_BAR", "BLIZZ_FRAME_BAR_ART",
    "BLIZZ_FRAME_STANCE", "BLIZZ_FRAME_PET_BAR", "BLIZZ_FRAME_MICRO_MENU", "BLIZZ_FRAME_BAGS", "BLIZZ_FRAME_XP_BAR",
    "BLIZZ_FRAME_REP_BAR" } },
}

-- Blizzard-Meldungen und -Effekte (HideFrames.lua): nur Schalter für Frames, die es im Client gibt (z.B. Boss-Banner
-- und Ereignis-Einblendungen nicht in Classic)
local function addBlizzardMessages()
  local HideFrames = ns.HideFrames
  addSection("SECTION_HIDE_FRAMES", { collapsible = true })
  addToggles({
    toggle("HIDE_BOSS_BANNER", "hideBossBanner", HideFrames.HasBossBanner),
    toggle("HIDE_EVENT_TOASTS", "hideEventToasts", HideFrames.HasEventToasts),
    toggle("HIDE_ALERTS", "hideAlerts", HideFrames.HasAlerts),
    advanced(toggle("HIDE_REST_ANIMATION", "hideRestAnimation", HideFrames.HasRestAnimation)),
    advanced(toggle("HIDE_PORTRAIT_NUMBERS", "hidePortraitNumbers", HideFrames.HasPortraitNumbers)),
  })
end
local function addBlizzardHideGroups()
  local groupOf = {}
  for index, group in ipairs(BLIZZARD_GROUPS) do
    for _, label in ipairs(group.labels) do groupOf[label] = index end
  end
  local lists, rest = {}, {}
  for _, entry in ipairs(ns.BlizzardHide.Toggles()) do
    if not entry.setting then entry.resetKeys = { "hiddenBlizzardFrames" } end
    local index = groupOf[entry.label]
    if index then
      lists[index] = lists[index] or {}
      table.insert(lists[index], entry)
    else
      table.insert(rest, entry)
    end
  end
  for index, group in ipairs(BLIZZARD_GROUPS) do
    if lists[index] then
      addSection(group.section, { collapsible = true })
      addToggles(lists[index])
    end
  end
  if #rest > 0 then
    addSection("SECTION_BLIZZ_OTHER", { collapsible = true })
    addToggles(rest)
  end
end

addSubPage("COMFORT_PAGE_HIDE")
addSection("SECTION_BLIZZARD_FRAMES")
addHint("BLIZZARD_FRAMES_HINT")
addBlizzardHideGroups()
addBlizzardMessages()
-- Quests: Automatik, Hinweise, Markierungen, Anzeigen und Helfer rund um den Questlog (alles zu Quests an einem Ort)
addSubPage("COMFORT_PAGE_QUESTS")
addSection("COMFORT_PAGE_AUTOMATION", { collapsible = true })
addToggles({
  toggle("AUTO_ACCEPT_QUESTS", "autoAcceptQuests"),
  toggle("AUTO_ACCEPT_SHARED", "autoAcceptShared"),
  toggle("AUTO_TURN_IN", "autoTurnIn"),
  requires(toggle("AUTO_CHOOSE_REWARD", "autoChooseReward"), "autoTurnIn"),
  toggle("SKIP_GOSSIP", "skipGossip"),
})
builder.AddTextInput({
  label = "QUEST_EXCLUDE",
  advanced = true,
  setting = "questExclude",
  width = QUEST_EXCLUDE_WIDTH,
  get = function(db) return db.questExclude end,
  set = function(text) ns.Set("questExclude", strtrim(text)) end,
})
addSection("SECTION_QUEST_NOTICES", { collapsible = true })
addToggles({
  toggle("QUEST_PROGRESS_TOGGLE", "announceQuestProgress"),
  toggle("WARN_QUEST_LOG_FULL_TOGGLE", "warnQuestLogFull"),
  toggle("ALERT_TOGGLE_QUEST_COMPLETE", "alertQuestComplete"),
  toggle("ALERT_TOGGLE_QUEST_OBJECTIVE", "alertQuestObjective"),
})
addSection("SECTION_QUEST_LEARNING", { collapsible = true })
addToggles({ toggle("QUEST_LEARNING_TOGGLE", "questLearning"), toggle("QUEST_MAP_TOGGLE", "questMap") })
addSection("SECTION_QUEST_LOG", { collapsible = true })
addToggles({ toggle("QUEST_CLEANUP_TOGGLE", "questCleanupButton"), toggle("QUEST_LEFTOVERS_TOGGLE", "questLeftovers") })
-- Quest-Anzeige: Questlevel, Quest-Buttons, Tooltips und Markierungen an Gegnern und NPCs
addSubPage("COMFORT_PAGE_QUEST_DISPLAY")
addSection("SECTION_QUEST_DISPLAY")
addToggles({
  toggle("QUEST_LEVELS_TOGGLE", "questLevels"),
  toggle("QUEST_ITEM_TOGGLE", "questItemButton"),
  toggle("QUEST_TARGET_TOGGLE", "questTargetButton"),
  advanced(requires(toggle("QUEST_TARGET_MARKER_TOGGLE", "questTargetMarker"), "questTargetButton")),
  advanced(requires(toggle("QUEST_ZONE_ONLY_TOGGLE", "questButtonsZoneOnly"), "questItemButton", "questTargetButton")),
  toggle("REWARD_HINT_TOGGLE", "rewardHint"),
  toggle("QUEST_EFFICIENCY_TOGGLE", "questEfficiencyTooltip"),
  toggle("QUEST_ITEM_TOOLTIP_TOGGLE", "questItemTooltip"),
})
if ns.QuestTextSize.IsAvailable() then
  addToggles({ advanced(toggle("QUEST_TEXT_RESIZE", "questTextResize")) })
  addSlider({
    label = "QUEST_TEXT_SIZE",
    advanced = true,
    min = ns.QuestTextSize.MIN,
    max = ns.QuestTextSize.MAX,
    step = 1,
    get = function(db) return db.questTextSize end,
    set = function(value) ns.SetDeferred("questTextSize", value) end,
    format = function(value) return tostring(value) end,
    enabled = function(db) return db.questTextResize end,
  })
end
if ns.QuestMarks.IsAvailable() then
  addSection("SECTION_QUEST_MARKS")
  addToggles({ toggle("QUEST_MARKS_TOGGLE", "questMarks"),
    requires(toggle("QUEST_MARK_PROGRESS_TOGGLE", "questMarkProgress"), "questMarks") })
  addSlider(requires({
    label = "QUEST_MARK_SCALE",
    advanced = true,
    setting = "questMarkScale",
    min = toPercent(ns.QuestMarks.MIN_SCALE),
    max = toPercent(ns.QuestMarks.MAX_SCALE),
    step = 5,
    get = function(db) return toPercent(db.questMarkScale) end,
    set = function(value) ns.SetDeferred("questMarkScale", value / 100) end,
    format = percent,
  }, "questMarks"))
end
addSubPage("COMFORT_PAGE_FRAMES")
addSection("SECTION_CHARACTER_FRAME")
addToggles({
  toggle("CHARACTER_DURABILITY", "characterDurability", ns.CharacterFrameExtras.IsAvailable),
  toggle("CHARACTER_VOLUME", "characterVolume", ns.CharacterFrameExtras.IsAvailable),
  toggle("DRESS_UP_BUTTONS", "dressUpButtons"),
})
addSection("SECTION_UNIT_FRAMES")
addToggles({
  toggle("CLASS_COLOR_FRAMES", "classColorFrames", ns.ClassColors.IsAvailable),
  toggle("CLASS_COLOR_PLAYER_FRAME", "classColorPlayerFrame", ns.ClassColors.CanColorPlayerFrame),
  toggle("DRUID_MANA_BAR", "druidManaBar", ns.DruidManaBar.IsAvailable),
})
if ns.PlayerChain.IsAvailable() then
  local chains = {}
  for _, value in ipairs(ns.PlayerChain.ORDER) do
    table.insert(chains, { value = value, name = localized("PLAYER_CHAIN_" .. value:upper()) })
  end
  addChooser({ label = "PLAYER_CHAIN", setting = "playerChain", choices = chains, advanced = true })
end
addSection("SECTION_TOOLTIP")
addToggles({
  toggle("TOOLTIP_CLASS_COLORS", "tooltipClassColors"),
  toggle("TOOLTIP_TARGET_TOGGLE", "tooltipTarget"),
  toggle("TOOLTIP_HIDE_IN_COMBAT", "tooltipHideInCombat"),
  toggle("TOOLTIP_KILLS_TO_LEVEL_TOGGLE", "tooltipKillsToLevel"),
  advanced(toggle("TOOLTIP_GUILD_RANK_TOGGLE", "tooltipGuildRank")),
  toggle("INFO_CARDS", "infoCards"),
})
local tooltipAnchors = {}
for _, value in ipairs(ns.Tooltip.ANCHOR_ORDER) do
  table.insert(tooltipAnchors, { value = value, name = localized("TOOLTIP_ANCHOR_" .. value:upper()) })
end
addChooser({ label = "TOOLTIP_ANCHOR", setting = "tooltipAnchor", choices = tooltipAnchors, advanced = true })
addSlider({
  label = "TOOLTIP_SCALE",
  advanced = true,
  min = toPercent(ns.Tooltip.MIN_SCALE),
  max = toPercent(ns.Tooltip.MAX_SCALE),
  step = 5,
  get = function(db) return toPercent(db.tooltipScale) end,
  set = function(value) ns.SetDeferred("tooltipScale", value / 100) end,
  format = percent,
})
-- Minimap: Mausrad und Zoom-Knöpfe nur in Classic (Retail/Forever haben beides schon anders gelöst)
local MinimapTweaks = ns.MinimapTweaks
addSection("SECTION_MINIMAP")
addToggles({
  toggle("MINIMAP_WHEEL_ZOOM", "minimapWheelZoom", MinimapTweaks.CanWheelZoom),
  toggle("MINIMAP_HIDE_ZOOM_BUTTONS", "minimapHideZoomButtons", MinimapTweaks.HasZoomButtons),
  toggle("MINIMAP_HIDE_CALENDAR", "minimapHideCalendar", MinimapTweaks.HasCalendarButton),
  advanced(toggle("MINIMAP_SQUARE", "minimapSquare", MinimapTweaks.CanSquare)),
})
addSection("SECTION_WORLD_MAP")
addToggles({ toggle("MAP_COORDS_TOGGLE", "mapCoordinates"), toggle("DEATH_MAP_TOGGLE", "deathMap"),
  toggle("CORPSE_ARROW_TOGGLE", "corpseArrow") })
-- Blizzard-Fenster verschieben und skalieren (UX S16: bei den übrigen Fenstern statt unter Oberfläche)
addSection("SECTION_WINDOWS")
addToggles({ toggle("MOVE_FRAMES", "moveFrames") })
addButton("MOVE_FRAMES_RESET", function() ns.MoveFrames.Reset() end)
-- Beute (UX S16): Plündern, Würfeln und Beute-Glitzer zusammen statt verteilt auf System und Oberfläche
addSubPage("COMFORT_PAGE_LOOT")
addSection("SECTION_LOOT")
addToggles({
  toggle("FASTER_LOOT", "fasterLoot"),
  toggle("SKIP_LOOT_CONFIRM", "skipLootConfirm"),
})
addSection("SECTION_LOOT_ROLLS")
addToggles({
  toggle("LOOT_ROLL_COUNTS_TOGGLE", "lootRollCounts"),
  requires(toggle("LOOT_ROLL_NAMES_TOGGLE", "lootRollNames"), "lootRollCounts"),
  toggle("LOOT_ROLL_SUMMARY_TOGGLE", "lootRollSummary"),
  advanced(toggle("LOOT_ROLL_JOURNAL_TOGGLE", "lootRollJournal")),
  toggle("LOOT_ROLL_HISTORY_TOGGLE", "lootRollHistory"),
})
addFrameScaleSlider("LOOT_ROLL_CARD_SCALE", "lootRolls", nil, true)
-- Beute-Glitzer: Quest-Gegenstände nur, wo es die CVar gibt (WoW Forever), Annähern nur mit Soft-Targeting-API
local LootSparkles = ns.LootSparkles
if LootSparkles.HasQuestItemSparkle() or LootSparkles.CanSoftTarget() then
  addSection("SECTION_LOOT_SPARKLES")
  addToggles({
    toggle("LOOT_SPARKLE_QUEST_ITEMS", "lootSparkleQuestItems", LootSparkles.HasQuestItemSparkle),
    toggle("LOOT_SPARKLE_ORE", "lootSparkleOre", LootSparkles.CanSoftTarget),
    toggle("LOOT_SPARKLE_HERBS", "lootSparkleHerbs", LootSparkles.CanSoftTarget),
    toggle("LOOT_SPARKLE_QUEST_OBJECTS", "lootSparkleQuestObjects", LootSparkles.CanSoftTarget),
    toggle("LOOT_SPARKLE_CORPSES", "lootSparkleCorpses", LootSparkles.CanSoftTarget),
  })
  if LootSparkles.CanSoftTarget() then
    addSlider(requires({
      label = "LOOT_SPARKLE_SCALE",
      advanced = true,
      setting = "lootSparkleScale",
      min = toPercent(ns.LootSparkle.MIN_SCALE),
      max = toPercent(ns.LootSparkle.MAX_SCALE),
      step = 5,
      get = function(db) return toPercent(db.lootSparkleScale) end,
      set = function(value) ns.SetDeferred("lootSparkleScale", value / 100) end,
      format = percent,
    }, "lootSparkleOre", "lootSparkleHerbs", "lootSparkleQuestObjects", "lootSparkleCorpses"))
  end
end
-- Zeit-Anzeigen (Lib/TimerDisplay.lua): Größe und Vorschau; Texte <PREFIX>_SCALE, _PREVIEW. Verschieben und
-- Zurücksetzen übernimmt der Edit-Modus (Button unten)
local function addTimerDisplayControls(prefix, display, frameId)
  addFrameScaleSlider(prefix .. "_SCALE", frameId, nil, true)
  addButton(prefix .. "_PREVIEW", function() display.Preview() end)
end

-- Timer & Flüge (UX S11: dort, wo man Komfort-Helfer sucht): Lagerfeuer und Schlafsack (nur WoW Forever), Essen (wo
-- der Client die Buffs "Essen" und "Satt" kennt) und Flugzeiten (immer)
addSubPage("COMFORT_PAGE_TIMERS")
if ns.CampFire.IsAvailable() then
  addSection("SECTION_CAMP")
  addToggles({
    toggle("CAMP_COUNTDOWN_TOGGLE", "campCountdown"),
    toggle("CAMP_HINT_TOGGLE", "campHint"),
    requires(toggle("CAMP_SOUND", "campSound"), "campCountdown"),
  })
  addSlider(requires({
    label = "CAMP_HINT_PAUSE",
    advanced = true,
    setting = "campHintPause",
    min = ns.CampFire.MIN_HINT_PAUSE,
    max = ns.CampFire.MAX_HINT_PAUSE,
    step = 1,
    get = function(db) return db.campHintPause end,
    set = function(value) ns.SetDeferred("campHintPause", value) end,
    format = function(value) return string.format(L.MINUTES, value) end,
  }, "campHint"))
  addTimerDisplayControls("CAMP", ns.CampDisplay, "camp")
end
if ns.FoodTimer.IsAvailable() then
  addSection("SECTION_FOOD")
  addToggles({
    toggle("FOOD_TIMER_TOGGLE", "foodTimer"),
    requires(toggle("FOOD_SOUND", "foodSound"), "foodTimer"),
  })
  addTimerDisplayControls("FOOD", ns.FoodDisplay, "food")
end
if ns.SleepTimer.IsAvailable() then
  addSection("SECTION_SLEEP")
  addToggles({
    toggle("SLEEP_TIMER_TOGGLE", "sleepTimer"),
    toggle("SLEEP_STACK_NOTICE", "sleepStackNotice"),
    toggle("SLEEP_TIMER_SOUND", "sleepTimerSound"),
  })
  addTimerDisplayControls("SLEEP", ns.SleepDisplay, "sleep")
end

-- Flugzeiten: eigene Messung je Strecke (wie Leatrix Plus "Show flight times")
addSection("SECTION_FLIGHTS")
addToggles({
  toggle("FLIGHT_TIMER_TOGGLE", "flightTimer"),
  requires(toggle("FLIGHT_SOUND", "flightSound"), "flightTimer"),
  requires(toggle("FLIGHT_TOOLTIP_TOGGLE", "flightTimeTooltip"), "flightTimer"),
})
addTimerDisplayControls("FLIGHT", ns.FlightDisplay, "flight")

-- Schiffe und Zeppeline (Roadmap 440): gelernte Abfahrtszeiten, nicht in Retail
if ns.Transports.IsAvailable() then
  addSection("SECTION_TRANSPORT")
  addToggles({
    toggle("TRANSPORT_TIMERS_TOGGLE", "transportTimers"),
    requires(toggle("TRANSPORT_MINIMAP_TOGGLE", "transportMinimap"), "transportTimers"),
    requires(toggle("TRANSPORT_NAMEPLATE_TOGGLE", "transportNameplate"), "transportTimers"),
    requires(toggle("TRANSPORT_TOOLTIP_TOGGLE", "transportTooltip"), "transportTimers"),
    requires(toggle("TRANSPORT_SHARE_TOGGLE", "transportShare"), "transportTimers"),
  })
  addHint("TRANSPORT_NAMEPLATE_HINT")
  addFrameScaleSlider("TRANSPORT_SCALE", "transport", nil, true)
end
addSubPage("COMFORT_PAGE_SYSTEM")
addSection("SECTION_DIALOGS")
addToggles({
  toggle("EASY_DELETE", "easyDelete"),
  toggle("FASTER_MOVIE_SKIP", "fasterMovieSkip"),
})
addSection("SECTION_COMBAT_GROUP")
addToggles({
  toggle("COMBAT_PLATES", "combatPlates"),
  advanced(toggle("NO_RAID_RESTRICTIONS", "noRaidRestrictions", ns.RaidRestrictions.IsAvailable)),
  toggle("READY_TIMER", "readyTimer"),
})
if ns.AddonListSort.IsAvailable() then
  addSection("SECTION_ADDON_LIST")
  addToggles({ advanced(toggle("SORT_ADDON_LIST", "sortAddonList")) })
end
-- Grafik und Ton: Kamera, Bildschirmeffekte, Wetter, Stummschalten
addSubPage("COMFORT_PAGE_GRAPHICS")
addSection("SECTION_CAMERA")
addToggles({ toggle("MAX_CAMERA_ZOOM", "maxCameraZoom") })
addSection("SECTION_GRAPHICS")
addToggles({
  toggle("NO_DRUNKEN_HAZE", "noDrunkenHaze"),
  toggle("NO_SCREEN_EFFECTS", "noScreenEffects"),
  advanced(toggle("SET_WEATHER_DENSITY", "setWeatherDensity")),
})
addSlider(requires({
  label = "WEATHER_DENSITY",
  advanced = true,
  setting = "weatherDensity",
  min = ns.ScreenEffects.MIN_WEATHER,
  max = ns.ScreenEffects.MAX_WEATHER,
  step = 1,
  get = function(db) return db.weatherDensity end,
  set = function(value) ns.SetDeferred("weatherDensity", value) end,
  format = function(value) return tostring(value) end,
}, "setWeatherDensity"))
-- Stummschalten nur, wo MuteSoundFile existiert
local muteToggles = { toggle("SILENCE_RESTED_EMOTES", "silenceRestedEmotes") }
for _, group in ipairs(ns.Sounds.MUTE_GROUPS) do
  table.insert(muteToggles, advanced(toggle(group.label, group.setting, ns.Sounds.CanMute)))
end
addSection("SECTION_SOUND")
addToggles(muteToggles)
finishSubPages()
finishPage()

-- Speedrun: Split-Liste, Vergleich, Speedrun-Rekorde, Screenshots, SSF
addPage("OPTIONS_TAB_SPEEDRUN")
addSubPage("OPTIONS_PAGE_SPLIT_LIST")
addSection("SECTION_SPLIT_LIST")
addToggles({
  toggle("SHOW_SPLIT_LIST", "showSplitList"),
  requires(toggle("SHOW_SPLIT_HEADER", "splitListHeader"), "showSplitList"),
  requires(toggle("SHOW_SPLIT_TOTAL", "splitListShowTotal"), "showSplitList"),
  requires(toggle("SHOW_SPLIT_PLAYED", "splitListShowPlayed"), "showSplitList"),
  requires(toggle("SHOW_SPLIT_FORECAST", "splitListShowForecast"), "showSplitList"),
  requires(toggle("SHOW_CUSTOM_SPLITS", "splitListShowCustom"), "showSplitList"),
})
addFrameScaleSlider("SPLIT_LIST_SIZE", "splitList", function(db) return db.showSplitList end)
addVisibilityCycle("SPLIT_LIST_VISIBILITY", "splitListVisibility")
addSlider(requires({
  label = "SPLIT_LIST_ROWS",
  setting = "splitListRows",
  min = ns.SplitList.MIN_ROWS,
  max = ns.SplitList.MAX_ROWS,
  step = 1,
  get = function(db) return db.splitListRows end,
  set = function(value) ns.SetDeferred("splitListRows", value) end,
  format = tostring,
}, "showSplitList"))
-- Vergleich: wogegen die Splits laufen, Toleranz, Hinweise bei Bestzeiten, Rennen gegen Freunde
addSubPage("OPTIONS_PAGE_COMPARE")
addSplitComparisonChooser()
addToggles({
  advanced(toggle("PB_SAME_CLASS", "pbSameClass")),
  toggle("GOLD_SPLIT_NOTICE", "goldSplitNotice"),
  toggle("QUEST_SPLIT_NOTICE", "questSplitNotice"),
  toggle("FRIEND_RACE", "friendRace"),
})
addSlider({
  label = "SPLIT_TOLERANCE",
  advanced = true,
  setting = "splitTolerancePercent",
  min = 0,
  max = ns.Splits.MAX_TOLERANCE_PERCENT,
  step = 1,
  get = function(db) return db.splitTolerancePercent end,
  set = function(value) ns.SetDeferred("splitTolerancePercent", value) end,
  format = function(value) return value == 0 and L.TOLERANCE_OFF or percent(value) end,
})
addSubPage("OPTIONS_PAGE_RECORDS")
addSection("SECTION_WORLD_RECORDS")
local recordToggles = {
  toggle("SHOW_WORLD_RECORDS", "showWorldRecords"),
  advanced(toggle("SHOW_RECORDS_AGE", "showRecordsAge")),
}
-- Ein Schalter je Abschnitt der Rekord-Daten (1-10, 1-20, ...)
for _, label in ipairs(ns.WorldRecords.GetBracketLabels()) do
  table.insert(recordToggles, {
    text = function() return string.format(L.WORLD_RECORD_ROW, label) end,
    tip = "RECORD_BRACKET_TIP",
    advanced = true,
    setting = "recordBrackets",
    get = function(db) return db.recordBrackets[label] ~= false end,
    set = function(checked)
      ns.db.recordBrackets[label] = checked
      ns.ApplySettings()
    end,
  })
end
addToggles(recordToggles)
addWorldRecordScopeChooser()
addSubPage("OPTIONS_PAGE_SCREENSHOTS")
addSection("SECTION_SCREENSHOTS")
addToggles({
  toggle("MILESTONE_SCREENSHOTS", "milestoneScreenshots"),
  toggle("SCREENSHOT_FIRST_DUNGEON", "screenshotFirstDungeon"),
  toggle("SCREENSHOT_EPIC_LOOT", "screenshotEpicLoot"),
})
addSubPage("OPTIONS_PAGE_SSF")
addSection("SECTION_SSF")
addSsfCategoryChooser()
addHint("SSF_HINT")
finishSubPages()
finishPage()

-- Profile: Einstellungen benannt speichern, je Charakter wählen, als Text teilen
addPage("OPTIONS_TAB_PROFILES")
addSection("SECTION_PROFILES")
addProfileUsage()
addProfileList()
addProfileSaver()
addButton("PROFILE_EXPORT", function()
  local Profiles = ns.Profiles
  ns.Export.Show(Profiles.DisplayName(Profiles.GetActive()), Profiles.Export(Profiles.GetActive()))
end)
addButton("PROFILE_IMPORT", function() ns.ShowProfileImport() end)
addHint("PROFILE_HINT")
finishPage()

addFooterButton("HISTORY", function() ns.ToggleHistory() end)
-- Edit-Modus auf allen Reitern: verschieben, skalieren und zurücksetzen aller Anzeigen (UI/EditMode.lua)
addFooterButton("EDIT_MODE", function()
  builder.panel:Hide()  -- Platz für die Anzeigen
  ns.EditMode.Enter()
end)
addFooterButton("RECAP_TITLE", function() ns.ToggleRecap() end)
-- Neue Session nur nach Rückfrage (archiviert sofort und setzt die Werte zurück); /lt newsession ist schon eindeutig
local NEW_SESSION_POPUP = ns.PopupKey("NEW_SESSION")
local confirmNewSession = Widgets.ConfirmPopup(NEW_SESSION_POPUP, "NEW_SESSION_CONFIRM", function() ns.StartNewSession() end)
addFooterButton("NEW_SESSION", function()
  confirmNewSession(ns.Format.Duration(ns.Stats.GetSeconds(ns.Stats.SESSION) or 0))
end)

builder.Finish()
ns.RegisterApply(builder.RefreshIfShown)
ns.OptionsWindow = builder  -- Seiten, Suche und Hervorhebung (Tests)

-- Einstellungen auf einem Reiter oder einer Unterseite öffnen (Locale-Key wie bei addPage/addSubPage), z.B. aus dem
-- Menü des Edit-Modus; ohne Key bleibt die zuletzt gezeigte Seite
function ns.ShowOptionsPage(pageKey)
  if not ns.db then return end
  builder.Refresh(ns.db)
  builder.panel:Show()
  if pageKey then builder.ShowPage(pageKey) end
end

-- Rechtsklick auf eine Anzeige (Lib/Frames.lua): ihre Seite öffnen; ist genau sie schon offen, schließen
function ns.ToggleOptionsPage(pageKey)
  if not ns.db then return end
  local tab, sub = builder.CurrentPage()
  if builder.panel:IsShown() and (sub or tab) == pageKey then
    builder.panel:Hide()
  else
    ns.ShowOptionsPage(pageKey)
  end
end

function ns.ToggleOptions()
  if not ns.db then return end
  local panel = builder.panel
  if panel:IsShown() then
    panel:Hide()
  else
    builder.Refresh(ns.db)
    panel:Show()
  end
end

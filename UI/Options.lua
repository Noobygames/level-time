-- Einstellungsfenster mit Reitern: Allgemein (Fenster, Sprache), Statistiken, Hinweise, Einblendungen, Komfort, Stream, Speedrun, Profile.
-- Darunter auf allen Reitern: Neue Session, Zusammenfassung, Historie.
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
local DELETE_PROFILE_POPUP = "LEVELTIMER_DELETE_PROFILE"
local QUEST_EXCLUDE_WIDTH = 200  -- Eingabefeld für die eigene Sperrliste der Quest-Automatik

local builder = Builder.New({
  name = "LevelTimerOptions",
  alpha = 0.95,
  title = function() return ns.DISPLAY_NAME .. " - " .. L.SETTINGS end,
})
local addPage, finishPage, addSection, addSlider = builder.AddPage, builder.FinishPage, builder.AddSection, builder.AddSlider
local addToggles, addButton, addFooterButton = builder.AddToggles, builder.AddButton, builder.AddFooterButton
local addChooser, addHint = builder.AddChooser, builder.AddHint
local toggle, localized = Builder.Toggle, Builder.Localized

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

-- Profile: Liste (Klick wechselt, Rechtsklick löscht), Name + Speichern, Export und Import
StaticPopupDialogs[DELETE_PROFILE_POPUP] = {
  button1 = YES or "Yes",
  button2 = NO or "No",
  OnAccept = function(_, name)
    if ns.Profiles.Delete(name) then ns.Print(string.format(L.PROFILE_DELETED, ns.Profiles.DisplayName(name))) end
    ns.ApplySettings()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-- Profil nach Rückfrage löschen (Rechtsklick in der Liste und /lt profile delete); nicht löschbare melden sich sofort
function ns.ConfirmProfileDelete(name)
  if not ns.Profiles.CanDelete(name) then
    ns.Print(L.PROFILE_NOT_DELETED)
    return
  end
  StaticPopupDialogs[DELETE_PROFILE_POPUP].text = L.PROFILE_DELETE_CONFIRM  -- aktuelle Sprache
  StaticPopup_Show(DELETE_PROFILE_POPUP, ns.Profiles.DisplayName(name), nil, name)
end

local OVERWRITE_PROFILE_POPUP = "LEVELTIMER_OVERWRITE_PROFILE"
local onProfileSaved  -- Rückruf des laufenden Speicherns (leert z.B. das Namensfeld)

local function saveProfile(name)
  if ns.Profiles.SaveAs(name) then
    ns.Print(string.format(L.PROFILE_SAVED, name))
    if onProfileSaved then onProfileSaved() end
    ns.ApplySettings()
  end
end

StaticPopupDialogs[OVERWRITE_PROFILE_POPUP] = {
  button1 = YES or "Yes",
  button2 = NO or "No",
  OnAccept = function(_, name) saveProfile(name) end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-- Einstellungen als Profil speichern (Button und /lt profile save); leerer Name meldet sich, ein vorhandenes
-- Profil wird erst nach Rückfrage überschrieben. onSaved läuft nach dem Speichern.
function ns.ConfirmProfileSave(name, onSaved)
  name = strtrim(name or "")
  onProfileSaved = onSaved
  if name == "" then
    ns.Print(L.PROFILE_NAME_EMPTY)
  elseif ns.Profiles.Exists(name) then
    StaticPopupDialogs[OVERWRITE_PROFILE_POPUP].text = L.PROFILE_OVERWRITE_CONFIRM  -- aktuelle Sprache
    StaticPopup_Show(OVERWRITE_PROFILE_POPUP, name, nil, name)
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
    listOffset = math.max(0, math.min(maxOffset(), offset))
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

local function addProfileSaver()
  local page = builder.Page()
  local nameBox = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
  nameBox:SetSize(PROFILE_NAME_WIDTH, Builder.BUTTON_HEIGHT)
  nameBox:SetAutoFocus(false)
  nameBox:SetPoint("TOPLEFT", Builder.MARGIN + 6, builder.RowY())  -- Vorlage zeichnet ihren Rand links außerhalb
  local saveButton = Widgets.CreateButton(page, PROFILE_SAVE_WIDTH, Builder.BUTTON_HEIGHT, function()
    ns.ConfirmProfileSave(nameBox:GetText(), function() nameBox:SetText("") end)
  end)
  saveButton:SetPoint("LEFT", nameBox, "RIGHT", Builder.CHOOSER_TAB_GAP, 0)
  builder.AddTooltip(saveButton, "PROFILE_SAVE_TIP", localized("PROFILE_SAVE"))
  nameBox:SetScript("OnEnterPressed", function() saveButton:Click() end)
  nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  builder.Advance(Builder.ROW_BUTTON)
  builder.OnRefresh(function() Widgets.SetButtonText(saveButton, L.PROFILE_SAVE, PROFILE_SAVE_WIDTH) end)
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
  addSection("SECTION_THEME")
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
    choices = Theme.FontChoices,
    get = function(db) return db.themeFont end,
    set = function(key) ns.Set("themeFont", key) end,
    nameOf = function(key) return key == "" and L.THEME_FONT_DEFAULT or key end,
  })
  addSlider({
    label = "THEME_FONT_SIZE",
    min = Theme.MIN_FONT_OFFSET,
    max = Theme.MAX_FONT_OFFSET,
    step = 1,
    get = function(db) return db.themeFontSize end,
    set = function(value) ns.SetDeferred("themeFontSize", value) end,
    format = function(value) return value > 0 and "+" .. value or tostring(value) end,
  })
  local outlines = {}
  for i, key in ipairs(Theme.OUTLINE_ORDER) do
    outlines[i] = { value = key, name = localized("OUTLINE_" .. key:upper()) }
  end
  addChooser({ label = "THEME_OUTLINE", setting = "themeOutline", choices = outlines })
end

-- Sichtbarkeitsregel einer Anzeige (DisplayVisibility.lua) als Zyklus-Button: Linksklick nächste, Rechtsklick vorige
local function addVisibilityCycle(label, setting)
  builder.AddCycleButton({
    label = label,
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
-- gewählte Werte, Sichtbarkeit. Wirkt sofort, auch im Edit-Modus (Vorschau = das echte Fenster).
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
      choices = rowChoices,
      get = function(db) return WindowModel.ChosenRowKey(db, index) end,
      set = function(key) WindowModel.SetChosenRow(ns.db, index, key) end,
      nameOf = function(key) return key == "" and L.CHOSEN_ROW_NONE or L[key] end,
      enabled = usesChosenRows,
    })
  end
  local textToggle = toggle("TEXT_LABELS", "textLabels")
  textToggle.enabled = layoutIs("text")
  addToggles({ textToggle })
  addSlider({
    label = "TILE_COLUMNS",
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
    min = Layouts.XpBar.MIN_WIDTH,
    max = Layouts.XpBar.MAX_WIDTH,
    step = 20,
    get = function(db) return db.xpbarWidth end,
    set = function(value) ns.SetDeferred("xpbarWidth", value) end,
    format = tostring,
    enabled = layoutIs("xpbar"),
  })
  addVisibilityCycle("WINDOW_VISIBILITY", "windowVisibility")
  addSlider({
    label = "FADE_ALPHA",
    min = 0,
    max = 100,
    step = 5,
    get = function(db) return toPercent(db.fadeAlpha) end,
    set = function(value) ns.SetDeferred("fadeAlpha", value / 100) end,
    format = function(value) return value .. "%" end,
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
  addSection("SECTION_ROW_ORDER")
  builder.AddCycleButton({
    label = "ROW_ORDER_STAT",
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
  })
end

-- Größe einer Anzeige (Lib/Frames.lua, db.frames[id].scale); der Edit-Modus kann sie auch per Mausrad ändern
local function addFrameScaleSlider(label, id)
  local Frames = ns.Frames
  addSlider({
    label = label,
    min = toPercent(Frames.MIN_SCALE),
    max = toPercent(Frames.MAX_SCALE),
    step = 5,
    get = function() return toPercent(Frames.GetScale(id)) end,
    set = function(value) Frames.SetScale(id, value / 100) end,
    format = percent,
  })
end

---------------------------------------------------------------------------
-- Inhalt
---------------------------------------------------------------------------

-- Allgemein: Fenster und grundlegende Einstellungen
addPage("SECTION_GENERAL")
addSection("SECTION_WINDOW")
addFrameScaleSlider("WINDOW_SIZE", "main")
addSlider({
  label = "BG_OPACITY",
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
  toggle("QUEST_XP_ON_BAR", "questXpOnBar"),
  toggle("EDIT_MODE_WITH_BLIZZARD", "editModeWithBlizzard", function() return EditModeManagerFrame ~= nil end),
})
addHint("OPTIONS_HINT")
addDisplaySection()
addThemeSection()
addSection("SECTION_LANGUAGE")
addLanguageChooser()
addToggles({
  { label = "SHOW_MINIMAP", get = function(db) return not db.minimap.hide end,
    set = function(checked) ns.SetMinimapHidden(not checked) end },
})
finishPage()

-- Statistiken: ein Schalter je Stat-Zeile, direkt aus ns.STAT_LINES
addPage("STATISTICS")
addSection("SECTION_STAT_PRESETS")
local presetButtons = {}
for i, preset in ipairs(ns.STAT_PRESETS) do
  presetButtons[i] = { label = preset.label, onClick = function() ns.ApplyStatPreset(preset) end }
end
table.insert(presetButtons, { label = "PRESET_UNDO", onClick = function() ns.UndoStatPreset() end })
builder.AddButtonRow(presetButtons)
for _, group in ipairs(ns.STAT_GROUPS) do
  addSection(group)
  local statToggles = {}
  for _, line in ipairs(ns.STAT_LINES) do
    if line.group == group then table.insert(statToggles, toggle(line.label, line.setting, line.available)) end
  end
  addToggles(statToggles)
  if group == "STAT_GROUP_INSTANCE" then
    addButton("INSTANCE_RESET", function() ns.ConfirmInstanceReset() end)
  end
end
addRowOrderSection()
addSection("SECTION_CALCULATION")
addToggles({ toggle("XP_RATE_WITHOUT_AFK", "xpRateWithoutAfk") })
addSlider({
  label = "IDLE_LIMIT",
  min = ns.TimeBreakdown.MIN_IDLE_MINUTES,
  max = ns.TimeBreakdown.MAX_IDLE_MINUTES,
  step = 1,
  get = function(db) return db.idleMinutes end,
  set = function(value) ns.SetDeferred("idleMinutes", value) end,
  format = function(value) return value == 0 and L.IDLE_LIMIT_OFF or string.format(L.MINUTES, value) end,
})
addSlider({
  label = "TO_LEVEL_SAMPLES",
  min = ns.Experience.MIN_TO_LEVEL_SAMPLES,
  max = ns.Experience.MAX_TO_LEVEL_SAMPLES,
  step = 5,
  get = function(db) return db.toLevelSamples end,
  set = function(value) ns.SetDeferred("toLevelSamples", value) end,
  format = function(value)
    return value == 0 and L.TO_LEVEL_SAMPLES_LEVEL or string.format(L.TO_LEVEL_SAMPLES_VALUE, value)
  end,
})
finishPage()

-- Hinweise: Level-Up im Chat und Erinnerungen an Buffs
addPage("OPTIONS_TAB_NOTIFICATIONS")
addSection("SECTION_LEVEL_UP")
addToggles({ toggle("LEVEL_UP_SUMMARY_TOGGLE", "levelUpSummary"), toggle("LEVEL_UP_GAINS_TOGGLE", "levelUpGains"),
  toggle("RESTED_ALT_NOTICE_TOGGLE", "restedAltNotice"), toggle("SESSION_COMPARE_TOGGLE", "sessionCompareLogin") })
addAnnounceChooser()
addSection("SECTION_PERSONAL_RECORDS")
addToggles({ toggle("ANNOUNCE_RECORDS_TOGGLE", "announceRecords") })
addSection("SECTION_REMINDERS")
addToggles({
  toggle("REMIND_FOOD_TOGGLE", "remindFood"),
  toggle("REMIND_CAMP_TOGGLE", "remindCamp", ns.BuffReminder.HasCampSystem),
  toggle("REMIND_CHARGED_TOGGLE", "remindCharged", ns.BuffReminder.HasChargedSystem),
})
-- Klassen-Hinweise: nur die der eigenen Klasse; Beschriftung mit den Zaubernamen in der Sprache des Clients
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
addSlider({
  label = "REMINDER_INTERVAL",
  min = ns.BuffReminder.MIN_INTERVAL,
  max = ns.BuffReminder.MAX_INTERVAL,
  step = 1,
  get = function(db) return db.reminderInterval end,
  set = function(value) ns.SetDeferred("reminderInterval", value) end,
  format = function(value) return string.format(L.MINUTES, value) end,
})
-- Pausen-Erinnerung (BreakReminder.lua)
addToggles({ toggle("REMIND_BREAK_TOGGLE", "remindBreak") })
addSlider({
  label = "BREAK_MINUTES",
  min = ns.BreakReminder.MIN_MINUTES,
  max = ns.BreakReminder.MAX_MINUTES,
  step = 15,
  get = function(db) return db.breakMinutes end,
  set = function(value) ns.SetDeferred("breakMinutes", value) end,
  format = function(value) return string.format(L.MINUTES, value) end,
})
addSection("SECTION_WARNINGS")
addHint("WARN_LOOK_HINT")
addToggles({
  toggle("WARN_BAGS_FULL_TOGGLE", "warnBagsFull"),
  toggle("WARN_DURABILITY_TOGGLE", "warnDurability"),
  toggle("REMIND_TRAINER_TOGGLE", "remindTrainer", ns.TrainerReminder.IsAvailable),
  toggle("WARN_AMMO_TOGGLE", "warnAmmo", ns.GearWarnings.ShowsAmmoOptions),
  toggle("WARN_INSTANCE_LIMIT_TOGGLE", "warnInstanceLimit"),
  toggle("WARN_AGGRO_TOGGLE", "warnAggro"),
  toggle("WARN_BREATH_TOGGLE", "warnBreath"),
  toggle("EMERGENCY_TOGGLE", "emergencyHighlight", ns.Emergency.IsAvailable),
  toggle("LOW_MANA_TOGGLE", "announceLowMana"),
  toggle("CC_ANNOUNCE_TOGGLE", "announceControlLoss"),
  toggle("CC_OVER_TOGGLE", "announceControlOver"),
  toggle("HEALER_AGGRO_TOGGLE", "announceHealerAggro"),
  toggle("QUEST_PROGRESS_TOGGLE", "announceQuestProgress"),
  toggle("WARN_QUEST_LOG_FULL_TOGGLE", "warnQuestLogFull"),
  toggle("INSTANCE_REPORT_TOGGLE", "announceInstanceReport"),
})
addSlider({
  label = "WARN_BREATH_BELOW",
  min = ns.BreathWarning.MIN_SECONDS,
  max = ns.BreathWarning.MAX_SECONDS,
  step = 1,
  get = function(db) return db.breathWarnSeconds end,
  set = function(value) ns.SetDeferred("breathWarnSeconds", value) end,
  format = function(value) return string.format(L.SECONDS_SHORT, value) end,
})
addSlider({
  label = "LOW_MANA_BELOW",
  min = ns.ManaCallout.MIN_PERCENT,
  max = ns.ManaCallout.MAX_PERCENT,
  step = 5,
  get = function(db) return db.lowManaPercent end,
  set = function(value) ns.SetDeferred("lowManaPercent", value) end,
  format = percent,
})
-- Munition: nur für Jäger
if ns.GearWarnings.ShowsAmmoOptions() then
  addSlider({
    label = "WARN_AMMO_BELOW",
    min = ns.GearWarnings.MIN_AMMO,
    max = ns.GearWarnings.MAX_AMMO,
    step = 20,
    get = function(db) return db.ammoLow end,
    set = function(value) ns.SetDeferred("ammoLow", value) end,
    format = function(value) return string.format(L.AMMO_COUNT, value) end,
  })
  addSlider({
    label = "WARN_AMMO_CRITICAL_BELOW",
    min = 0,
    max = ns.GearWarnings.MAX_CRITICAL_AMMO,
    step = 10,
    get = function(db) return db.ammoCritical end,
    set = function(value) ns.SetDeferred("ammoCritical", value) end,
    format = function(value) return value == 0 and L.AMMO_OFF or string.format(L.AMMO_COUNT, value) end,
  })
  addSlider({
    label = "WARN_AMMO_REPEAT",
    min = 0,
    max = ns.GearWarnings.MAX_AMMO_REPEAT,
    step = 1,
    get = function(db) return db.ammoRepeat end,
    set = function(value) ns.SetDeferred("ammoRepeat", value) end,
    format = function(value) return value == 0 and L.AMMO_ONCE or string.format(L.MINUTES, value) end,
  })
end
finishPage()

-- Timer: Lagerfeuer (nur WoW Forever), Essen und Flüge (überall, daher gibt es den Reiter immer)
do
  addPage("OPTIONS_TAB_TIMERS")
  -- Größe und Vorschau einer Zeit-Anzeige (Lib/TimerDisplay.lua); Texte <PREFIX>_SCALE, _PREVIEW. Verschieben und
  -- Zurücksetzen übernimmt der Edit-Modus (Button unten)
  local function addTimerDisplayControls(prefix, display, frameId)
    addFrameScaleSlider(prefix .. "_SCALE", frameId)
    addButton(prefix .. "_PREVIEW", function() display.Preview() end)
  end


  -- Lagerfeuer-Anzeige: nur in WoW Forever (dort gibt es den Lagerfeuer-Buff)
  if ns.CampFire.IsAvailable() then
    addSection("SECTION_CAMP")
    addToggles({
      toggle("CAMP_COUNTDOWN_TOGGLE", "campCountdown"),
      toggle("CAMP_HINT_TOGGLE", "campHint"),
      toggle("CAMP_SOUND", "campSound"),
    })
    addSlider({
      label = "CAMP_HINT_PAUSE",
      min = ns.CampFire.MIN_HINT_PAUSE,
      max = ns.CampFire.MAX_HINT_PAUSE,
      step = 1,
      get = function(db) return db.campHintPause end,
      set = function(value) ns.SetDeferred("campHintPause", value) end,
      format = function(value) return string.format(L.MINUTES, value) end,
    })
    addTimerDisplayControls("CAMP", ns.CampDisplay, "camp")
  end

  -- Essen-Timer: überall, wo der Client die Buffs "Essen" und "Satt" kennt
  if ns.FoodTimer.IsAvailable() then
    addSection("SECTION_FOOD")
    addToggles({
      toggle("FOOD_TIMER_TOGGLE", "foodTimer"),
      toggle("FOOD_SOUND", "foodSound"),
    })
    addTimerDisplayControls("FOOD", ns.FoodDisplay, "food")
  end

  -- Flugzeiten: eigene Messung je Strecke (wie Leatrix Plus "Show flight times", ohne mitgelieferte Daten)
  addSection("SECTION_FLIGHT")
  addToggles({
    toggle("FLIGHT_TIMER_TOGGLE", "flightTimer"),
    toggle("FLIGHT_SOUND", "flightSound"),
  })
  addTimerDisplayControls("FLIGHT", ns.FlightDisplay, "flight")
  finishPage()
end

-- Komfort: Seitenleiste mit Kategorien wie bei Leatrix Plus (Automatik, Sozial, Chat, Oberfläche, System)
addPage("OPTIONS_TAB_COMFORT")
addHint("COMFORT_HINT")
local addSubPage, finishSubPages = builder.AddSubPage, builder.FinishSubPages
addSubPage("COMFORT_PAGE_AUTOMATION")
addSection("SECTION_MERCHANT")
addToggles({
  toggle("AUTO_REPAIR", "autoRepair"),
  toggle("AUTO_REPAIR_GUILD", "autoRepairGuild", ns.Client.HasGuildBank),
  toggle("AUTO_SELL_JUNK", "autoSellJunk"),
  toggle("TRAIN_ALL_TOGGLE", "trainAllButton", ns.TrainerCache.IsAvailable),
})
addSection("SECTION_QUESTS")
addToggles({
  toggle("AUTO_ACCEPT_QUESTS", "autoAcceptQuests"),
  toggle("AUTO_ACCEPT_SHARED", "autoAcceptShared"),
  toggle("AUTO_TURN_IN", "autoTurnIn"),
  toggle("AUTO_CHOOSE_REWARD", "autoChooseReward"),
  toggle("SKIP_GOSSIP", "skipGossip"),
})
builder.AddTextInput({
  label = "QUEST_EXCLUDE",
  width = QUEST_EXCLUDE_WIDTH,
  get = function(db) return db.questExclude end,
  set = function(text) ns.Set("questExclude", strtrim(text)) end,
})
addSection("SECTION_CHARACTER")
addToggles({
  toggle("AUTO_ACCEPT_SUMMON", "autoAcceptSummon"),
  toggle("AUTO_ACCEPT_RESURRECT", "autoAcceptResurrect"),
  toggle("AUTO_RELEASE_PVP", "autoReleasePvP"),
})
addSubPage("COMFORT_PAGE_SOCIAL")
addSection("SECTION_DECLINE")
addToggles({
  toggle("DECLINE_TRADES", "declineTrades"),
  toggle("DECLINE_GROUP_INVITES", "declineGroupInvites"),
  toggle("DECLINE_GUILD_INVITES", "declineGuildInvites"),
  toggle("DECLINE_DUELS", "declineDuels"),
  toggle("DECLINE_SHARED_QUESTS", "declineSharedQuests"),
  toggle("BLOCK_FRIEND_REQUESTS", "blockFriendRequests", ns.Social.CanBlockFriendRequests),
})
-- Einladungen: Vertraute = Freunde und Gilde (Friends.lua); declineGroupInvites lehnt sie dann nicht ab
addSection("SECTION_INVITES")
addToggles({
  toggle("ACCEPT_FRIEND_INVITES", "acceptFriendInvites"),
  toggle("INVITE_INFO_TOGGLE", "inviteInfo"),
  toggle("INVITE_FROM_WHISPER", "inviteFromWhisper"),
})
builder.AddTextInput({
  label = "INVITE_KEYWORD",
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
  toggle("UNIVERSAL_GROUP_COLOR", "universalGroupColor", ns.ChatColors.IsAvailable),
})
addSection("SECTION_CHAT_WINDOWS")
addToggles({
  toggle("HIDE_COMBAT_LOG_TAB", "hideCombatLogTab"),
  toggle("HIDE_CHAT_BUTTONS", "hideChatButtons"),
  toggle("CHAT_EDIT_BOX_TOP", "chatEditBoxTop"),
  toggle("CHAT_ARROW_KEYS", "chatArrowKeys"),
  toggle("NO_CHAT_FADE", "noChatFade"),
})
addSubPage("COMFORT_PAGE_INTERFACE")
addSection("SECTION_SCREEN_TEXT")
addToggles({
  toggle("HIDE_ERRORS", "hideErrors"),
  toggle("HIDE_ZONE_TEXT", "hideZoneText"),
})
addSection("SECTION_ACTION_BARS")
addToggles({
  toggle("HIDE_KEYBIND_TEXT", "hideKeybindText"),
  toggle("HIDE_MACRO_TEXT", "hideMacroText"),
  toggle("RANGE_COLOR", "rangeColor"),
})
-- Nur Schalter für Frames, die es im Client gibt (z.B. Boss-Banner und Ereignis-Einblendungen nicht in Classic)
local HideFrames = ns.HideFrames
addSection("SECTION_HIDE_FRAMES")
addToggles({
  toggle("HIDE_BOSS_BANNER", "hideBossBanner", HideFrames.HasBossBanner),
  toggle("HIDE_EVENT_TOASTS", "hideEventToasts", HideFrames.HasEventToasts),
  toggle("HIDE_ALERTS", "hideAlerts", HideFrames.HasAlerts),
  toggle("HIDE_STANCE_BAR", "hideStanceBar", HideFrames.HasStanceBar),
  toggle("HIDE_REST_ANIMATION", "hideRestAnimation", HideFrames.HasRestAnimation),
  toggle("HIDE_PORTRAIT_NUMBERS", "hidePortraitNumbers", HideFrames.HasPortraitNumbers),
})
addSection("SECTION_WINDOWS")
addToggles({ toggle("MOVE_FRAMES", "moveFrames") })
addButton("MOVE_FRAMES_RESET", function() ns.MoveFrames.Reset() end)
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
    addSlider({
      label = "LOOT_SPARKLE_SCALE",
      min = toPercent(ns.LootSparkle.MIN_SCALE),
      max = toPercent(ns.LootSparkle.MAX_SCALE),
      step = 5,
      get = function(db) return toPercent(db.lootSparkleScale) end,
      set = function(value) ns.SetDeferred("lootSparkleScale", value / 100) end,
      format = percent,
    })
  end
end
-- Quests: Markierungen, Anzeigen und Helfer rund um den Questlog
addSubPage("COMFORT_PAGE_QUESTS")
addSection("SECTION_QUEST_LEARNING")
addToggles({ toggle("QUEST_LEARNING_TOGGLE", "questLearning"), toggle("QUEST_MAP_TOGGLE", "questMap") })
addSection("SECTION_QUEST_LOG")
addToggles({ toggle("QUEST_CLEANUP_TOGGLE", "questCleanupButton"), toggle("QUEST_LEFTOVERS_TOGGLE", "questLeftovers") })
addSection("SECTION_QUEST_DISPLAY")
addToggles({
  toggle("QUEST_LEVELS_TOGGLE", "questLevels"),
  toggle("QUEST_ITEM_TOGGLE", "questItemButton"),
  toggle("QUEST_TARGET_TOGGLE", "questTargetButton"),
  toggle("QUEST_TARGET_MARKER_TOGGLE", "questTargetMarker"),
  toggle("REWARD_HINT_TOGGLE", "rewardHint"),
  toggle("QUEST_EFFICIENCY_TOGGLE", "questEfficiencyTooltip"),
  toggle("QUEST_ITEM_TOOLTIP_TOGGLE", "questItemTooltip"),
})
if ns.QuestMarks.IsAvailable() then
  addSection("SECTION_QUEST_MARKS")
  addToggles({ toggle("QUEST_MARKS_TOGGLE", "questMarks"), toggle("QUEST_MARK_PROGRESS_TOGGLE", "questMarkProgress") })
  addSlider({
    label = "QUEST_MARK_SCALE",
    min = toPercent(ns.QuestMarks.MIN_SCALE),
    max = toPercent(ns.QuestMarks.MAX_SCALE),
    step = 5,
    get = function(db) return toPercent(db.questMarkScale) end,
    set = function(value) ns.SetDeferred("questMarkScale", value / 100) end,
    format = percent,
  })
end
addSubPage("COMFORT_PAGE_FRAMES")
addSection("SECTION_CHARACTER_FRAME")
addToggles({
  toggle("CHARACTER_DURABILITY", "characterDurability", ns.CharacterFrameExtras.IsAvailable),
  toggle("CHARACTER_VOLUME", "characterVolume", ns.CharacterFrameExtras.IsAvailable),
})
addSection("SECTION_UNIT_FRAMES")
addToggles({ toggle("CLASS_COLOR_FRAMES", "classColorFrames", ns.ClassColors.IsAvailable) })
addSection("SECTION_TOOLTIP")
addToggles({
  toggle("TOOLTIP_CLASS_COLORS", "tooltipClassColors"),
  toggle("TOOLTIP_TARGET_TOGGLE", "tooltipTarget"),
  toggle("TOOLTIP_HIDE_IN_COMBAT", "tooltipHideInCombat"),
  toggle("TOOLTIP_KILLS_TO_LEVEL_TOGGLE", "tooltipKillsToLevel"),
})
-- Minimap: Mausrad und Zoom-Knöpfe nur in Classic (Retail/Forever haben beides schon anders gelöst)
local MinimapTweaks = ns.MinimapTweaks
addSection("SECTION_MINIMAP")
addToggles({
  toggle("MINIMAP_WHEEL_ZOOM", "minimapWheelZoom", MinimapTweaks.CanWheelZoom),
  toggle("MINIMAP_HIDE_ZOOM_BUTTONS", "minimapHideZoomButtons", MinimapTweaks.HasZoomButtons),
  toggle("MINIMAP_HIDE_CALENDAR", "minimapHideCalendar", MinimapTweaks.HasCalendarButton),
})
addSection("SECTION_WORLD_MAP")
addToggles({ toggle("MAP_COORDS_TOGGLE", "mapCoordinates"), toggle("DEATH_MAP_TOGGLE", "deathMap"),
  toggle("CORPSE_ARROW_TOGGLE", "corpseArrow") })
addSubPage("COMFORT_PAGE_SYSTEM")
addSection("SECTION_LOOT")
addToggles({
  toggle("FASTER_LOOT", "fasterLoot"),
  toggle("SKIP_LOOT_CONFIRM", "skipLootConfirm"),
})
addSection("SECTION_DIALOGS")
addToggles({
  toggle("EASY_DELETE", "easyDelete"),
  toggle("FASTER_MOVIE_SKIP", "fasterMovieSkip"),
})
addSection("SECTION_CAMERA")
addToggles({ toggle("MAX_CAMERA_ZOOM", "maxCameraZoom") })
addSection("SECTION_GRAPHICS")
addToggles({
  toggle("NO_DRUNKEN_HAZE", "noDrunkenHaze"),
  toggle("NO_SCREEN_EFFECTS", "noScreenEffects"),
  toggle("SET_WEATHER_DENSITY", "setWeatherDensity"),
})
addSlider({
  label = "WEATHER_DENSITY",
  min = ns.ScreenEffects.MIN_WEATHER,
  max = ns.ScreenEffects.MAX_WEATHER,
  step = 1,
  get = function(db) return db.weatherDensity end,
  set = function(value) ns.SetDeferred("weatherDensity", value) end,
  format = function(value) return tostring(value) end,
})
-- Stummschalten nur, wo MuteSoundFile existiert
local muteToggles = { toggle("SILENCE_RESTED_EMOTES", "silenceRestedEmotes") }
for _, group in ipairs(ns.Sounds.MUTE_GROUPS) do
  table.insert(muteToggles, toggle(group.label, group.setting, ns.Sounds.CanMute))
end
addSection("SECTION_SOUND")
addToggles(muteToggles)
addSection("SECTION_COMBAT_GROUP")
addToggles({
  toggle("COMBAT_PLATES", "combatPlates"),
  toggle("NO_RAID_RESTRICTIONS", "noRaidRestrictions", ns.RaidRestrictions.IsAvailable),
})
if ns.AddonListSort.IsAvailable() then
  addSection("SECTION_ADDON_LIST")
  addToggles({ toggle("SORT_ADDON_LIST", "sortAddonList") })
end
finishSubPages()
finishPage()

-- Stream: alles, was nur für Streams gedacht ist (Speedrun hat einen eigenen Reiter)
addPage("OPTIONS_TAB_STREAM")
addSection("SECTION_STREAM")
addToggles({
  { label = "STREAM_MODE", get = function() return ns.StreamMode.IsEnabled() end,
    set = function(checked) ns.StreamMode.SetEnabled(checked) end },
  toggle("STREAMER_PRIVACY", "streamerPrivacy"),
  toggle("HIGHLIGHT_DEATHS", "highlightDeaths"),
  -- Abkürzung zu "Minimap-Button anzeigen" (Allgemein), umgekehrt formuliert
  { label = "STREAM_HIDE_MINIMAP", get = function(db) return db.minimap.hide end,
    set = function(checked) ns.SetMinimapHidden(checked) end },
})
addBackgroundChooser()
finishPage()

-- Einblendungen: welche Arten, Aussehen und Position (Hinweise aus dem Reiter Hinweise nutzen dieselbe)
addPage("OPTIONS_TAB_ALERTS")
addSection("SECTION_ALERTS")
addToggles({
  toggle("ALERT_TOGGLE_LEVEL_UP", "alertLevelUp"),
  toggle("ALERT_TOGGLE_RARE", "alertRareKill"),
  toggle("ALERT_TOGGLE_ELITE", "alertEliteKill"),
  toggle("ALERT_TOGGLE_LOOT", "alertEpicLoot"),
  toggle("ALERT_TOGGLE_NEAR_DEATH", "alertNearDeath", ns.NearDeath.IsAvailable),
  toggle("ALERT_TOGGLE_RARE_SPOTTED", "alertRareSpotted"),
  toggle("ALERT_TOGGLE_RARE_FLASH", "alertRareFlash"),
  toggle("ALERT_TOGGLE_QUEST_COMPLETE", "alertQuestComplete"),
  toggle("ALERT_TOGGLE_QUEST_OBJECTIVE", "alertQuestObjective"),
})
addSection("SECTION_LEVEL_UP_WINDOW")
addToggles({
  toggle("LEVEL_UP_WINDOW_TOGGLE", "levelUpWindow"),
  toggle("LEVEL_UP_HIDE_BLIZZARD", "levelUpHideBlizzard"),
  toggle("LEVEL_UP_COMPACT", "levelUpCompact"),
  toggle("LEVEL_UP_SOUND", "levelUpSound"),
})
addChooser({ label = "LEVEL_UP_THEME", setting = "levelUpTheme", choices = {
  { value = "modern", name = localized("THEME_MODERN") },
  { value = "alliance", name = localized("THEME_ALLIANCE") },
  { value = "horde", name = localized("THEME_HORDE") },
} })
addFrameScaleSlider("LEVEL_UP_SCALE", "levelUp")
addSlider({
  label = "LEVEL_UP_DURATION",
  min = ns.LevelUpWindow.MIN_DURATION,
  max = ns.LevelUpWindow.MAX_DURATION,
  step = 1,
  get = function(db) return db.levelUpDuration end,
  set = function(value) ns.SetDeferred("levelUpDuration", value) end,
  format = function(value) return string.format(L.SECONDS_SHORT, value) end,
})
addButton("LEVEL_UP_PREVIEW", function() ns.LevelUpWindow.Preview() end)
if ns.TrainerCache.IsAvailable() then addHint("LEVEL_UP_TRAINER_HINT") end
addSection("SECTION_ALERT_LOOK")
addChooser({ label = "ALERT_STYLE", setting = "alertStyle", choices = {
  { value = Alerts.STYLE_BANNER, name = localized("ALERT_STYLE_BANNER") },
  { value = Alerts.STYLE_TEXT, name = localized("ALERT_STYLE_TEXT") },
} })
addFrameScaleSlider("ALERT_SCALE", "alert")
addSlider({
  label = "ALERT_DURATION",
  min = Alerts.MIN_DURATION,
  max = Alerts.MAX_DURATION,
  step = 1,
  get = function(db) return db.alertDuration end,
  set = function(value) ns.SetDeferred("alertDuration", value) end,
  format = function(value) return string.format(L.SECONDS_SHORT, value) end,
})
addToggles({ toggle("ALERT_SOUND", "alertSound") })
addButton("ALERT_PREVIEW", function() Alerts.Preview() end)
finishPage()

-- Speedrun: Splits, Split-Liste und Speedrun-Rekorde
addPage("OPTIONS_TAB_SPEEDRUN")
addSection("SECTION_SPLIT_LIST")
addToggles({
  toggle("SHOW_SPLIT_LIST", "showSplitList"),
  toggle("SHOW_SPLIT_TOTAL", "splitListShowTotal"),
  toggle("SHOW_SPLIT_PLAYED", "splitListShowPlayed"),
  toggle("GOLD_SPLIT_NOTICE", "goldSplitNotice"),
  toggle("SHOW_SPLIT_FORECAST", "splitListShowForecast"),
  toggle("SHOW_CUSTOM_SPLITS", "splitListShowCustom"),
  toggle("QUEST_SPLIT_NOTICE", "questSplitNotice"),
  toggle("FRIEND_RACE", "friendRace"),
})
addSplitComparisonChooser()
addToggles({ toggle("PB_SAME_CLASS", "pbSameClass") })
addSlider({
  label = "SPLIT_TOLERANCE",
  min = 0,
  max = ns.Splits.MAX_TOLERANCE_PERCENT,
  step = 1,
  get = function(db) return db.splitTolerancePercent end,
  set = function(value) ns.SetDeferred("splitTolerancePercent", value) end,
  format = function(value) return value == 0 and L.TOLERANCE_OFF or percent(value) end,
})
addFrameScaleSlider("SPLIT_LIST_SIZE", "splitList")
addVisibilityCycle("SPLIT_LIST_VISIBILITY", "splitListVisibility")
addSlider({
  label = "SPLIT_LIST_ROWS",
  min = ns.SplitList.MIN_ROWS,
  max = ns.SplitList.MAX_ROWS,
  step = 1,
  get = function(db) return db.splitListRows end,
  set = function(value) ns.SetDeferred("splitListRows", value) end,
  format = tostring,
})
addSection("SECTION_WORLD_RECORDS")
local recordToggles = {
  toggle("SHOW_WORLD_RECORDS", "showWorldRecords"),
  toggle("SHOW_RECORDS_AGE", "showRecordsAge"),
}
-- Ein Schalter je Abschnitt der Rekord-Daten (1-10, 1-20, ...)
for _, label in ipairs(ns.WorldRecords.GetBracketLabels()) do
  table.insert(recordToggles, {
    text = function() return string.format(L.WORLD_RECORD_ROW, label) end,
    tip = "RECORD_BRACKET_TIP",
    get = function(db) return db.recordBrackets[label] ~= false end,
    set = function(checked)
      ns.db.recordBrackets[label] = checked
      ns.ApplySettings()
    end,
  })
end
addToggles(recordToggles)
addWorldRecordScopeChooser()
addSection("SECTION_SCREENSHOTS")
addToggles({
  toggle("MILESTONE_SCREENSHOTS", "milestoneScreenshots"),
  toggle("SCREENSHOT_FIRST_DUNGEON", "screenshotFirstDungeon"),
  toggle("SCREENSHOT_EPIC_LOOT", "screenshotEpicLoot"),
})
addSection("SECTION_SSF")
addSsfCategoryChooser()
addHint("SSF_HINT")
finishPage()

-- Profile: Einstellungen benannt speichern, je Charakter wählen, als Text teilen
addPage("OPTIONS_TAB_PROFILES")
addSection("SECTION_PROFILES")
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
local NEW_SESSION_POPUP = "LEVELTIMER_NEW_SESSION"
StaticPopupDialogs[NEW_SESSION_POPUP] = {
  button1 = YES or "Yes",
  button2 = NO or "No",
  OnAccept = function() ns.StartNewSession() end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}
addFooterButton("NEW_SESSION", function()
  StaticPopupDialogs[NEW_SESSION_POPUP].text = L.NEW_SESSION_CONFIRM  -- aktuelle Sprache
  StaticPopup_Show(NEW_SESSION_POPUP, ns.Format.Duration(ns.Stats.GetSeconds(ns.Stats.SESSION) or 0))
end)

builder.Finish()
ns.RegisterApply(builder.RefreshIfShown)

-- Einstellungen auf einem Reiter öffnen (Locale-Key wie bei addPage), z.B. aus dem Menü des Edit-Modus
function ns.ShowOptionsPage(pageKey)
  if not ns.db then return end
  builder.Refresh(ns.db)
  builder.panel:Show()
  if pageKey then builder.ShowPage(pageKey) end
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

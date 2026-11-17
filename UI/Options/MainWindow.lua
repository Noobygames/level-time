-- Optionen, Reiter Hauptfenster: Fenster, Layout, Aussehen, Statistik-Zeilen (je Gruppe), Reihenfolge, Berechnung.
local _, ns = ...
local O = ns.OptionsCore
local L = ns.L
local builder, addPage, finishPage, addSection, addSlider = O.builder, O.addPage, O.finishPage, O.addSection, O.addSlider
local addToggles, addButton, addChooser, addSubPage = O.addToggles, O.addButton, O.addChooser, O.addSubPage
local finishSubPages, toggle, localized, advanced = O.finishSubPages, O.toggle, O.localized, O.advanced
local percent, toPercent, addVisibilityDropdown = O.percent, O.toPercent, O.addVisibilityDropdown
local addFrameScaleSlider, addOutlineChooser = O.addFrameScaleSlider, O.addOutlineChooser

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
  builder.AddDropdown({
    label = "THEME_FONT",
    advanced = true,
    setting = "themeFont",
    choices = function()
      local choices = Theme.FontChoices()
      for _, choice in ipairs(choices) do choice.font = Theme.FontPath(choice.key) end  -- Eintrag in seiner Schrift
      return choices
    end,
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
  builder.AddDropdown({
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
  builder.AddDropdown({
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

  -- Gewählte Werte (compactRows) für Kompakt, Uhr und XP-Balken: je Stelle eine Auswahlliste über alle Zeilen
  local function rowChoices()
    local list = { { key = "" } }
    for _, row in ipairs(WindowModel.AllRows()) do
      if WindowModel.IsRowAvailable(row.key) then table.insert(list, { key = row.key }) end
    end
    return list
  end
  local usesChosenRows = function(db) return Layouts.Get(db.windowLayout).source == WindowModel.CHOSEN end
  for index = 1, WindowModel.MAX_CHOSEN_ROWS do
    builder.AddDropdown({
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
  addVisibilityDropdown("WINDOW_VISIBILITY", "windowVisibility")
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

-- Quest-XP auf dem XP-Balken: nur mit Balken (Schalter oder Layout "xpbar", das ihn immer zeigt)
local function requiresBar(definition)
  definition.enabled = function(db) return db.showXpBar or ns.WindowLayouts.Get(db.windowLayout).alwaysXpBar == true end
  return definition
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
  builder.AddDropdown({
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

-- Hauptfenster: Fenster (mit den Voreinstellungen der Werte darüber), Layout, Aussehen, dann je Stat-Gruppe eine
-- Unterseite mit einem Schalter je Stat-Zeile direkt aus ns.STAT_LINES; Reihenfolge und Berechnung
addPage("OPTIONS_TAB_MAIN")
addSection("SECTION_STAT_PRESETS")
local presetButtons = {}
for i, preset in ipairs(ns.STAT_PRESETS) do
  presetButtons[i] = { label = preset.label, onClick = function() ns.ApplyStatPreset(preset) end }
end
table.insert(presetButtons, { label = "PRESET_UNDO", onClick = function() ns.UndoStatPreset() end })
builder.AddButtonRow(presetButtons)
addSubPage("OPTIONS_PAGE_WINDOW")
addFrameScaleSlider("WINDOW_SIZE", "main")
O.addFramePreview("MAIN_WINDOW_PREVIEW", "main")
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
})
addVisibilitySection()
addSubPage("OPTIONS_PAGE_LAYOUT")
addDisplaySection()
addSubPage("OPTIONS_PAGE_LOOK")
addThemeSection()
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

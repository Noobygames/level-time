-- Optionen, Reiter Allgemein: Hauptfenster, Layout, Aussehen, Sprache, Stream.
local _, ns = ...
local O = ns.OptionsCore
local L = ns.L
local TimerWindow = ns.TimerWindow
local builder, addPage, finishPage, addSection, addSlider, addToggles, addButton, addChooser, addHint, addSubPage, finishSubPages, toggle, localized, advanced, requires, percent, toPercent, addVisibilityCycle, addFrameScaleSlider = O.builder, O.addPage, O.finishPage, O.addSection, O.addSlider, O.addToggles, O.addButton, O.addChooser, O.addHint, O.addSubPage, O.finishSubPages, O.toggle, O.localized, O.advanced, O.requires, O.percent, O.toPercent, O.addVisibilityCycle, O.addFrameScaleSlider

-- Sprachnamen stehen immer in der eigenen Sprache
local function addLanguageChooser()
  local choices = {}
  for i, language in ipairs(ns.languages) do
    choices[i] = { value = language.code, name = function() return language.name end }
  end
  addChooser({ label = "LANGUAGE", setting = "language", choices = choices })
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
  toggle("SHOW_DEATH_CARD", "showDeathCard"),
  toggle("SHOW_MAX_LEVEL_CARD", "showMaxLevelCard"),
  toggle("OBS_SIGNAL", "obsSignal"),
  toggle("SHOW_SPELL_HISTORY", "showSpellHistory"),
})
addSlider(requires({
  label = "OBS_SIGNAL_SIZE",
  advanced = true,
  setting = "obsSignalSize",
  min = 8,
  max = 64,
  step = 4,
  get = function(db) return db.obsSignalSize end,
  set = function(value) ns.SetDeferred("obsSignalSize", value) end,
  format = function(value) return tostring(value) end,
}, "obsSignal"))
O.addFramePreview("OBS_SIGNAL_PREVIEW", "obsSignal")
O.addFramePreview("SPELL_HISTORY_PREVIEW", "spellHistory")
addSlider(requires({
  label = "SPELL_HISTORY_COUNT",
  setting = "spellHistoryCount",
  min = 3,
  max = 10,
  step = 1,
  get = function(db) return db.spellHistoryCount end,
  set = function(value) ns.SetDeferred("spellHistoryCount", value) end,
  format = function(value) return tostring(value) end,
}, "showSpellHistory"))
addSlider(requires({
  label = "SPELL_HISTORY_FADE",
  advanced = true,
  setting = "spellHistoryFadeSeconds",
  min = 0,
  max = 30,
  step = 5,
  get = function(db) return db.spellHistoryFadeSeconds end,
  set = function(value) ns.SetDeferred("spellHistoryFadeSeconds", value) end,
  format = function(value) return value == 0 and L.SPELL_HISTORY_PERMANENT or string.format(L.SECONDS_SHORT, value) end,
}, "showSpellHistory"))
builder.AddTextInput({
  label = "STREAM_LINK",
  setting = "streamLink",
  width = 180,
  get = function(db) return db.streamLink end,
  set = function(text) ns.Set("streamLink", text) end,
})
addChooser({
  label = "STREAM_LINK_CHANNEL",
  setting = "streamLinkChannel",
  choices = {
    { value = "off", name = localized("STREAM_LINK_CHANNEL_OFF") },
    { value = "party", name = localized("STREAM_LINK_CHANNEL_PARTY") },
    { value = "guild", name = localized("STREAM_LINK_CHANNEL_GUILD") },
  },
})
addSlider({
  label = "STREAM_LINK_MINUTES",
  advanced = true,
  setting = "streamLinkMinutes",
  min = 15,
  max = 120,
  step = 15,
  get = function(db) return db.streamLinkMinutes end,
  set = function(value) ns.SetDeferred("streamLinkMinutes", value) end,
  format = function(value) return string.format(L.MINUTES, value) end,
  enabled = function(db) return db.streamLinkChannel ~= "off" end,
})
addButton("STREAM_LINK_COPY", function()
  if ns.StreamLink then ns.StreamLink.OpenCopy() end
end)
addSection("SECTION_STREAM_OBS")
addHint("STREAM_OBS_HINT")
addStreamLayoutChooser()
addBackgroundChooser()
addOutlineChooser()
finishSubPages()
finishPage()

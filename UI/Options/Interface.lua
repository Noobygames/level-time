-- Optionen, Reiter Oberfläche: Oberfläche, Ausblenden, Rahmen, Tooltip & Karten, Grafik & Ton, Beute-Glitzer.
local _, ns = ...
local O = ns.OptionsCore
local L = ns.L
local addPage, finishPage, addSection, addSlider = O.addPage, O.finishPage, O.addSection, O.addSlider
local addToggles, addButton, addChooser, addHint, addSubPage = O.addToggles, O.addButton, O.addChooser, O.addHint, O.addSubPage
local finishSubPages, toggle, localized, advanced, requires = O.finishSubPages, O.toggle, O.localized, O.advanced, O.requires
local percent, toPercent = O.percent, O.toPercent

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


addPage("OPTIONS_TAB_INTERFACE")
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
  toggle("COMFORT_COOLDOWN_NUMBERS", "cooldownNumbers"),
})
addSubPage("COMFORT_PAGE_HIDE")
addSection("SECTION_BLIZZARD_FRAMES")
addHint("BLIZZARD_FRAMES_HINT")
addBlizzardHideGroups()
addBlizzardMessages()
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
  toggle("COMFORT_TARGET_RANGE", "showTargetRange"),
  toggle("SWING_TIMER", "swingTimer", ns.SwingTimer.IsAvailable),
})
O.addFramePreview("TARGET_RANGE_PREVIEW", "targetRange")
-- Gewählte Buffs bei eingeklappter Buffleiste (Roadmap 500)
addToggles({ toggle("COLLAPSED_BUFFS", "collapsedBuffs") })
O.builder.AddTextInput({
  label = "COLLAPSED_BUFFS_LIST",
  setting = "collapsedBuffsList",
  get = function(db) return db.collapsedBuffsList end,
  set = function(text) ns.Set("collapsedBuffsList", strtrim(text)) end,
})
O.addFramePreview("COLLAPSED_BUFFS_PREVIEW", "collapsedBuffs")
-- Schwungbalken anpassen (Roadmap 489): ausgegraut, solange die Balken aus sind
local function addSwingTimerOptions()
  local SwingTimer = ns.SwingTimer
  O.addFramePreview("SWING_TIMER_PREVIEW", "swingTimer")
  addToggles({
    requires(toggle("SWING_TIMER_MAIN", "swingTimerMain"), "swingTimer"),
    requires(toggle("SWING_TIMER_OFF", "swingTimerOff"), "swingTimer"),
    requires(toggle("SWING_TIMER_RANGED", "swingTimerRanged"), "swingTimer"),
    requires(toggle("SWING_TIMER_COMBAT_ONLY", "swingTimerCombatOnly"), "swingTimer"),
    requires(toggle("SWING_TIMER_HIDE_BLIZZARD", "swingTimerHideBlizzard", function()
      return ns.CVars.Exists(SwingTimer.BLIZZARD_CVAR)
    end), "swingTimer"),
  })
  local function sizeSlider(label, setting, min, max)
    addSlider(requires({
      label = label, setting = setting, min = min, max = max, step = 2,
      get = function(db) return db[setting] end,
      set = function(value) ns.SetDeferred(setting, value) end,
      format = tostring,
    }, "swingTimer"))
  end
  sizeSlider("SWING_TIMER_WIDTH", "swingTimerWidth", SwingTimer.MIN_WIDTH, SwingTimer.MAX_WIDTH)
  sizeSlider("SWING_TIMER_HEIGHT", "swingTimerHeight", SwingTimer.MIN_HEIGHT, SwingTimer.MAX_HEIGHT)
  local function choicesOf(values, prefix)
    local choices = {}
    for i, value in ipairs(values) do choices[i] = { value = value, name = localized(prefix .. value:upper()) } end
    return choices
  end
  addChooser(requires({ label = "SWING_TIMER_TEXT", setting = "swingTimerText",
    choices = choicesOf(SwingTimer.TEXT_MODES, "SWING_TIMER_TEXT_") }, "swingTimer"))
  addChooser(requires({ label = "SWING_TIMER_LAYOUT", setting = "swingTimerLayout",
    choices = choicesOf(SwingTimer.LAYOUTS, "SWING_TIMER_LAYOUT_") }, "swingTimer"))
  -- Farben: Akzentfarben des Themes, "" = Standardfarbe der Hand
  local colors = {}
  for i, key in ipairs(SwingTimer.COLOR_ORDER) do
    colors[i] = { value = key, name = localized(key == "" and "SWING_TIMER_COLOR_DEFAULT" or "ACCENT_" .. key:upper()) }
  end
  for _, hand in ipairs({ SwingTimer.MAIN, SwingTimer.OFF, SwingTimer.RANGED }) do
    addChooser(requires({ label = "SWING_TIMER_COLOR_" .. hand:upper(), setting = SwingTimer.COLOR_SETTING[hand],
      choices = colors, advanced = true }, "swingTimer"))
  end
end
if ns.SwingTimer.IsAvailable() then addSwingTimerOptions() end
if ns.PlayerChain.IsAvailable() then
  local chains = {}
  for _, value in ipairs(ns.PlayerChain.ORDER) do
    table.insert(chains, { value = value, name = localized("PLAYER_CHAIN_" .. value:upper()) })
  end
  addChooser({ label = "PLAYER_CHAIN", setting = "playerChain", choices = chains, advanced = true })
end
addSubPage("COMFORT_PAGE_MAPS")
addSection("SECTION_TOOLTIP")
addToggles({
  toggle("TOOLTIP_CLASS_COLORS", "tooltipClassColors"),
  toggle("TOOLTIP_TARGET_TOGGLE", "tooltipTarget"),
  toggle("TOOLTIP_HIDE_IN_COMBAT", "tooltipHideInCombat"),
  toggle("TOOLTIP_KILLS_TO_LEVEL_TOGGLE", "tooltipKillsToLevel"),
  toggle("TOOLTIP_KILL_COUNT_TOGGLE", "tooltipKillCount"),
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
  toggle("MINIMAP_BUTTON_BAR", "minimapButtonBar", ns.MinimapBar.IsAvailable),
  advanced(toggle("MINIMAP_SQUARE", "minimapSquare", MinimapTweaks.CanSquare)),
})
addSection("SECTION_WORLD_MAP")
addToggles({ toggle("MAP_COORDS_TOGGLE", "mapCoordinates"), toggle("DEATH_MAP_TOGGLE", "deathMap"),
  toggle("CORPSE_ARROW_TOGGLE", "corpseArrow"), toggle("MAP_REVEAL_TOGGLE", "mapReveal", function() return ns.MapOverlayData ~= nil end) })
-- Blizzard-Fenster verschieben und skalieren (UX S16: bei den übrigen Fenstern statt unter Oberfläche)
addSection("SECTION_WINDOWS")
addToggles({ toggle("MOVE_FRAMES", "moveFrames"), toggle("REMEMBER_TRACKER_COLLAPSE", "rememberTrackerCollapse") })
addButton("MOVE_FRAMES_RESET", function() ns.MoveFrames.Reset() end)
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

-- Grafikdetails (nur WoW Forever): Hauptschalter, Regler je CVar, Nachschärfen, empfohlene Werte
local ForeverGraphics = ns.ForeverGraphics
if ForeverGraphics.IsAvailable() then
  addHint("FOREVER_GRAPHICS_HINT")
  addToggles({ toggle("FOREVER_GRAPHICS", "foreverGraphics") })
  addSection("SECTION_GRAPHICS_DISTANCE")
  local function addGraphicsSliders(list, requiredSetting)
    for _, slider in ipairs(list) do
      addSlider(requires({
        label = slider.label,
        setting = slider.setting,
        min = slider.min,
        max = slider.max,
        step = slider.step,
        get = function(db) return db[slider.setting] end,
        set = function(value) ns.SetDeferred(slider.setting, value) end,
        format = slider.format and function(value) return string.format(slider.format, value) end or tostring,
      }, requiredSetting))
    end
  end
  addGraphicsSliders(ForeverGraphics.SLIDERS, "foreverGraphics")
  addSection("SECTION_GRAPHICS_IMAGE")
  addToggles({
    toggle(ForeverGraphics.SHARPEN.label, ForeverGraphics.SHARPEN.setting),  -- wirkt auch ohne Beyond Ultra
    requires(toggle(ForeverGraphics.PAUSE.label, ForeverGraphics.PAUSE.setting), "foreverGraphics"),
  })
  addSection("SECTION_GRAPHICS_HDR")
  addToggles({ toggle(ForeverGraphics.HDR.label, ForeverGraphics.HDR.setting) })  -- wirkt auch ohne Beyond Ultra
  addGraphicsSliders(ForeverGraphics.HDR_SLIDERS, ForeverGraphics.HDR.setting)
  addButton("GRAPHICS_RECOMMENDED", ForeverGraphics.ApplyRecommended)
end
-- Beute-Glitzer: Quest-Gegenstände nur, wo es die CVar gibt (WoW Forever), Annähern nur mit Soft-Targeting-API
local LootSparkles = ns.LootSparkles
if LootSparkles.HasQuestItemSparkle() or LootSparkles.CanSoftTarget() then
  addSubPage("OPTIONS_PAGE_LOOT_SPARKLES")
  addToggles({
    toggle("LOOT_SPARKLE_QUEST_ITEMS", "lootSparkleQuestItems", LootSparkles.HasQuestItemSparkle),
    toggle("LOOT_SPARKLE_ORE", "lootSparkleOre", LootSparkles.CanSoftTarget),
    toggle("LOOT_SPARKLE_HERBS", "lootSparkleHerbs", LootSparkles.CanSoftTarget),
    toggle("LOOT_SPARKLE_CHESTS", "lootSparkleChests", LootSparkles.CanSoftTarget),
    toggle("LOOT_SPARKLE_BOBBER", "lootSparkleBobber", LootSparkles.CanSoftTarget),
    toggle("LOOT_SPARKLE_QUEST_OBJECTS", "lootSparkleQuestObjects", LootSparkles.CanSoftTarget),
    toggle("LOOT_SPARKLE_CORPSES", "lootSparkleCorpses", LootSparkles.CanSoftTarget),
  })
  if LootSparkles.CanSoftTarget() then
    addToggles({
      toggle("LOOT_SPARKLE_CATEGORY_COLORS", "lootSparkleCategoryColors"),
      advanced(toggle("LOOT_SPARKLE_HIDE_UNTRAINED", "lootSparkleHideUntrained", LootSparkles.CanSoftTarget)),
    })
    -- Auswahlliste statt Reiter: viele Stile passen nicht in eine Reiterzeile; Überschriften je Gruppe (Formen, Klassisch)
    O.addDropdown(requires({
      label = "LOOT_SPARKLE_STYLE",
      setting = "lootSparkleStyle",
      choices = function()
        local choices = {}
        for i, value in ipairs(ns.LootSparkle.STYLES) do
          choices[i] = { key = value, group = L["LOOT_SPARKLE_GROUP_" .. ns.LootSparkleStyles.Get(value).group:upper()] }
        end
        return choices
      end,
      get = function(db) return db.lootSparkleStyle end,
      set = function(key) ns.Set("lootSparkleStyle", key) end,
      nameOf = function(key) return L["LOOT_SPARKLE_STYLE_" .. key:upper()] end,
    }, "lootSparkleOre", "lootSparkleHerbs", "lootSparkleChests", "lootSparkleBobber", "lootSparkleQuestObjects", "lootSparkleCorpses"))
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
    }, "lootSparkleOre", "lootSparkleHerbs", "lootSparkleChests", "lootSparkleBobber", "lootSparkleQuestObjects", "lootSparkleCorpses"))
    addButton("LOOT_SPARKLE_PREVIEW", function() ns.LootSparkle.Preview() end)
  end
end
finishSubPages()
finishPage()

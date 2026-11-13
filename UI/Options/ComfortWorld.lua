-- Optionen, Reiter Komfort (3/3): Fenster, Tooltip & Karten, Beute, Beute-Glitzer, Timer, Reisen, System, Grafik
-- (lange Seiten in Unterseiten geteilt, Roadmap 465) und Ton; schließt den Reiter ab.
local _, ns = ...
local O = ns.OptionsCore
local L = ns.L
local finishPage, addSection, addSlider, addToggles, addButton, addChooser, addHint, addSubPage, finishSubPages, toggle, localized, advanced, requires, percent, toPercent, addFrameScaleSlider = O.finishPage, O.addSection, O.addSlider, O.addToggles, O.addButton, O.addChooser, O.addHint, O.addSubPage, O.finishSubPages, O.toggle, O.localized, O.advanced, O.requires, O.percent, O.toPercent, O.addFrameScaleSlider

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
local worldMapToggles = { toggle("MAP_COORDS_TOGGLE", "mapCoordinates"), toggle("DEATH_MAP_TOGGLE", "deathMap"),
  toggle("CORPSE_ARROW_TOGGLE", "corpseArrow") }
-- Dungeon-Eingänge nur mit gepflegten Eingangsdaten (WoW Forever)
if ns.DungeonEntrances.IsAvailable() then
  table.insert(worldMapToggles, toggle("DUNGEON_ENTRANCES_TOGGLE", "dungeonEntrances"))
end
addToggles(worldMapToggles)
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
O.addFramePreview("LOOT_ROLL_PREVIEW", "lootRolls")
-- Beute-Glitzer: Quest-Gegenstände nur, wo es die CVar gibt (WoW Forever), Annähern nur mit Soft-Targeting-API
local LootSparkles = ns.LootSparkles
if LootSparkles.HasQuestItemSparkle() or LootSparkles.CanSoftTarget() then
  addSubPage("COMFORT_PAGE_SPARKLES")
  addSection("SECTION_LOOT_SPARKLES")
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

-- Reisen: Flugzeiten (eigene Messung je Strecke wie Leatrix Plus "Show flight times"), Schiffe und Zeppeline
addSubPage("COMFORT_PAGE_TRAVEL")
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
    requires(toggle("TRANSPORT_WORLDMAP_TOGGLE", "transportWorldMap"), "transportTimers"),
    requires(toggle("TRANSPORT_NAMEPLATE_TOGGLE", "transportNameplate"), "transportTimers"),
    requires(toggle("TRANSPORT_TOOLTIP_TOGGLE", "transportTooltip"), "transportTimers"),
    requires(toggle("TRANSPORT_SHARE_TOGGLE", "transportShare"), "transportTimers"),
  })
  addHint("TRANSPORT_NAMEPLATE_HINT")
  addFrameScaleSlider("TRANSPORT_SCALE", "transport", nil, true)
  O.addFramePreview("TRANSPORT_PREVIEW", "transport")
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
  toggle("COMFORT_THREAT_NUMERIC", "threatShowNumeric"),
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

-- Grafikdetails (nur WoW Forever): Hauptschalter, Regler je CVar, Nachschärfen, empfohlene Werte
local ForeverGraphics = ns.ForeverGraphics
if ForeverGraphics.IsAvailable() then
  addSubPage("COMFORT_PAGE_GRAPHICS_DETAIL")
  addHint("FOREVER_GRAPHICS_HINT")
  addToggles({ toggle("FOREVER_GRAPHICS", "foreverGraphics") })
  addSection("SECTION_GRAPHICS_DISTANCE")
  for _, slider in ipairs(ForeverGraphics.SLIDERS) do
    addSlider(requires({
      label = slider.label,
      setting = slider.setting,
      min = slider.min,
      max = slider.max,
      step = slider.step,
      get = function(db) return db[slider.setting] end,
      set = function(value) ns.SetDeferred(slider.setting, value) end,
      format = tostring,
    }, "foreverGraphics"))
  end
  addSection("SECTION_GRAPHICS_IMAGE")
  addToggles({ requires(toggle(ForeverGraphics.SHARPEN.label, ForeverGraphics.SHARPEN.setting), "foreverGraphics") })
  addButton("GRAPHICS_RECOMMENDED", ForeverGraphics.ApplyRecommended)
end
finishSubPages()
finishPage()

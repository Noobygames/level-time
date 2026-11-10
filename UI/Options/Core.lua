-- Einstellungsfenster mit Reitern: Allgemein, Statistiken, Chat & Erinnerungen, Einblendungen, Komfort, Speedrun,
-- Profile; alle außer Profile mit Seitenleiste (Kategorien als Unterseiten). Darunter auf allen Reitern: Historie,
-- Layout bearbeiten, Zusammenfassung, Neue Session. Oben links die Suche über alle Einstellungen (OptionsBuilder).
-- Nur der Inhalt; Aufbau, Tooltips, Breite und Aktualisierung übernimmt Lib/OptionsBuilder.lua.
-- Dies ist der gemeinsame Teil (Builder, Hilfsbausteine); jeder Reiter steht in einer eigenen Datei in UI/Options/.
local _, ns = ...
local L = ns.L
local Builder = ns.OptionsBuilder

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
local addSubPage, finishSubPages = builder.AddSubPage, builder.FinishSubPages

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

local function percent(value)
  return value .. "%"
end

local function toPercent(fraction)
  return math.floor(fraction * 100 + 0.5)
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

-- Größe einer Anzeige (Lib/Frames.lua, db.frames[id].scale); der Edit-Modus kann sie auch per Mausrad ändern;
-- enabled(db) optional (ausgegraut, solange die Anzeige aus ist), isAdvanced optional (nur mit allen Optionen)
-- Knopf "Vorschau" für eine verschiebbare Anzeige (ns.Frames.Preview: Beispielinhalt für ein paar Sekunden)
local function addFramePreview(label, id)
  addButton(label, function() ns.Frames.Preview(id) end)
end

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

-- Gemeinsame Bausteine für die Reiter-Dateien (UI/Options/*.lua)
ns.OptionsCore = {
  builder = builder,
  addPage = addPage, finishPage = finishPage, addSection = addSection, addSlider = addSlider,
  addToggles = addToggles, addButton = addButton, addFooterButton = addFooterButton,
  addChooser = addChooser, addCycle = builder.AddCycleButton, addFramePreview = addFramePreview, addHint = addHint, addSubPage = addSubPage, finishSubPages = finishSubPages,
  toggle = toggle, localized = localized, advanced = advanced, requires = requires,
  percent = percent, toPercent = toPercent,
  addVisibilityCycle = addVisibilityCycle, addFrameScaleSlider = addFrameScaleSlider,
}

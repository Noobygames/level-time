-- Theme: Farb-Tokens, Preset-Wechsel, Akzent- und Schrift-Überschreibungen, Rahmenstile und der Rand bei Deckkraft 0.
local Theme = addon.Theme
local window = LevelTimerFrame
wow.login()

-- Standard "classic" = der bisherige Look: Grün/Rot der Split-Abweichungen und das Gold des Fensters
expect("Standard-Preset", LevelTimerDB.theme, "classic")
expect("schneller grün", Theme.Hex("good"), "|cff40ff40")
expect("langsamer rot", Theme.Hex("bad"), "|cffff4040")
expect("gleichauf gelb", Theme.Hex("neutral"), "|cffffd040")
expect("Gold-Split lila", Theme.Hex("best"), "|cffc070ff")
expect("Split-Abweichung nutzt das Token", addon.Format.SplitDelta(-5), "|cff40ff40-5" .. addon.L.UNIT_SECOND_SHORT .. "|r")
expect("Widgets-Farbe ist das Theme-Token", addon.Widgets.COLORS.highlight, Theme.COLORS.accent)
expectNear("Akzent wie früher", Theme.COLORS.accent[1], 0.96)
expectTrue("Fenster mit Tooltip-Rand", window._borderColor[4] == 1)

-- Deckkraft 0: kein schwebender Goldrand
addon.Set("bgAlpha", 0)
expect("Deckkraft 0: Grund unsichtbar", window._backdropColor[4], 0)
expect("Deckkraft 0: Rand unsichtbar", window._borderColor[4], 0)
addon.Set("bgAlpha", 0.8)
expect("Deckkraft zurück: Rand da", window._borderColor[4], 1)

-- Farbsehschwäche: Blau statt Grün, Orange statt Rot; gemerkte Tabellen folgen an Ort und Stelle
local good = Theme.COLORS.good
addon.Set("theme", "colorblind")
expectTrue("schneller jetzt blau", Theme.Hex("good") ~= "|cff40ff40" and good[3] > good[2])
expectTrue("langsamer jetzt orange", Theme.COLORS.bad[2] > 0.5)
expectTrue("Split-Abweichung folgt", addon.Format.SplitDelta(-5):find(Theme.Hex("good"), 1, true) == 1)

-- Flach: Grund und 1-px-Rand aus eigenen Texturen statt Backdrop
addon.Set("theme", "flat")
local parts = window.themeParts
expectTrue("flach: eigene Teile", parts ~= nil)
expect("flach: Grund sichtbar", parts.background:IsShown(), true)
expect("flach: Deckkraft aus bgAlpha", parts.background._colorTexture[4], 0.8)
expect("flach: Rand sichtbar", parts.lines.TOP:IsShown(), true)
local options = LevelTimerOptions
expectTrue("Einstellungsfenster folgt dem Preset", options.themeParts ~= nil and options.themeParts.lines.LEFT:IsShown())

-- Minimal: kein Rand, halbe Deckkraft
addon.Set("theme", "minimal")
expect("minimal: kein Rand", window.themeParts.lines.TOP:IsShown(), false)
expectNear("minimal: halbe Deckkraft", window.themeParts.background._colorTexture[4], 0.4)

-- Chroma bleibt deckend ohne Rand, auch im flachen Stil
addon.Set("theme", "flat")
addon.Set("windowBackground", "green")
expect("Chroma: deckend", window.themeParts.background._colorTexture[4], 1)
expect("Chroma: grün", window.themeParts.background._colorTexture[2], 1)
expect("Chroma: kein Rand", window.themeParts.lines.TOP:IsShown(), false)
addon.Set("windowBackground", "default")

-- Zurück auf classic: wieder Backdrop, eigene Teile versteckt, Farben wie vorher
addon.Set("theme", "classic")
expect("classic: Teile versteckt", window.themeParts.background:IsShown(), false)
expect("classic: grün wie vorher", Theme.Hex("good"), "|cff40ff40")

-- Akzent überschreibt nur den Akzent
addon.Set("themeAccent", "blue")
expectNear("Akzent blau", Theme.COLORS.accent[3], 1)
expectNear("Gold bleibt", Theme.COLORS.gold[2], 0.82)
addon.Set("themeAccent", "class")
expectTrue("Klassenfarbe ohne Fehler", Theme.COLORS.accent[1] ~= nil)
addon.Set("themeAccent", "")
expectNear("Akzent zurück", Theme.COLORS.accent[1], 0.96)

-- Schrift: Größe, Kontur und Schriftart wirken auf die eigenen Font-Objekte, nicht auf Blizzards
local label = _G[Theme.Font("label")]
local face, size, flags = label:GetFont()
expect("Grundgröße aus dem Blizzard-Objekt", size, 12)
expect("ohne Kontur", flags, "")
addon.Set("themeFontSize", 3)
addon.Set("themeOutline", "thick")
face, size, flags = label:GetFont()
expect("Größe + Versatz", size, 15)
expect("dicke Kontur", flags, "THICKOUTLINE")
expect("Blizzard-Objekt unverändert", select(2, GameFontNormalSmall:GetFont()), 12)
addon.Set("themeFont", "Arial Narrow")
expect("Schriftart aus der Liste", (label:GetFont()), "Fonts\\ARIALN.TTF")
addon.Set("themeFont", "Gibt es nicht")
expect("unbekannte Schrift: Client-Schrift", (label:GetFont()), face)
expect("Name bleibt gemerkt", LevelTimerDB.themeFont, "Gibt es nicht")

-- LibSharedMedia nur, wenn ein anderes Addon sie geladen hat
local choices = #Theme.FontChoices()
LibStub = function(name, silent)
  if name ~= "LibSharedMedia-3.0" then return nil end
  return {
    List = function() return { "Arial Narrow", "Expressway" } end,
    Fetch = function(_, _, key) return key == "Expressway" and "Interface\\AddOns\\SM\\Expressway.ttf" or nil end,
  }
end
expect("LSM-Schrift ergänzt, Doppelte nicht", #Theme.FontChoices(), choices + 1)
addon.Set("themeFont", "Expressway")
expect("LSM-Schrift aufgelöst", (label:GetFont()), "Interface\\AddOns\\SM\\Expressway.ttf")
LibStub = nil

-- Import: unbekannte Werte fliegen raus, Versatz begrenzt
local clean = addon.Database.SanitizeSettings({ theme = 5, themeFontSize = 99, themeOutline = "thick" })
expect("Preset falscher Typ verworfen", clean.theme, nil)
expect("Versatz begrenzt", clean.themeFontSize, 8)
expect("Kontur bleibt", clean.themeOutline, "thick")

-- Einstellungen: Auswahl per Klick
addon.ToggleOptions()
expectTrue("Preset-Auswahl", wow.click(addon.L.THEME_PRESET_FLAT))
expect("per Klick flach", LevelTimerDB.theme, "flat")
expectTrue("Kontur-Auswahl", wow.click(addon.L.OUTLINE_NONE))
expect("per Klick ohne Kontur", LevelTimerDB.themeOutline, "none")
addon.ToggleOptions()

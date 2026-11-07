-- Roadmap 361: Mindestschriftgröße (auch gegen kleine Anzeigen), Balkentexturen (eigene TGA, LibSharedMedia wenn
-- geladen), Farbe nach Wert (XP/h gegen den Schnitt), LiveSplit-Farben für den Gesamtstand, farbsehschwäche-tauglich.
local Theme, Frames, Format = addon.Theme, addon.Frames, addon.Format

-- Fremdes Addon hat LibSharedMedia geladen (wir bündeln es nicht)
local media = { statusbar = { "Fremd-Balken" } }
LibStub = function(name, silent)
  if name ~= "LibSharedMedia-3.0" then return nil end
  return {
    List = function(_, kind) return media[kind] or {} end,
    Fetch = function(_, kind, key) return kind == "statusbar" and key == "Fremd-Balken" and "Interface\\Fremd" or nil end,
  }
end

wow.login()

---------------------------------------------------------------------------
-- Mindestschriftgröße
---------------------------------------------------------------------------
addon.Set("themeFontSize", -4)
local _, small = LevelTimerFont_small:GetFont()
expectTrue("ohne Untergrenze klein", small < 10)
expect("ohne Untergrenze: Anzeigen bis 50 %", Theme.MinReadableScale(), nil)
addon.Set("themeMinFontSize", 10)
_, small = LevelTimerFont_small:GetFont()
expect("Untergrenze greift", small, 10)
expect("kleinste Schrift = Untergrenze: nicht verkleinern", Theme.MinReadableScale(), 1)
Frames.SetScale("main", 0.5)
expect("Hauptfenster bleibt lesbar", LevelTimerFrame:GetScale(), 1)
addon.Set("themeFontSize", 2)
expectTrue("größere Schrift erlaubt Verkleinern", Theme.MinReadableScale() < 1)
addon.Set("themeMinFontSize", 0)
Frames.SetScale("main", 0.5)
expect("ohne Untergrenze wieder 50 %", LevelTimerFrame:GetScale(), 0.5)

---------------------------------------------------------------------------
-- Balkentexturen
---------------------------------------------------------------------------
local keys = {}
for _, choice in ipairs(Theme.BarTextureChoices()) do keys[choice.key] = true end
expectTrue("einfarbig", keys[""])
expectTrue("eigene Texturen", keys.smooth and keys.gloss and keys.blizzard)
expectTrue("LibSharedMedia-Balken", keys["Fremd-Balken"])

addon.Set("showXpBar", true)
local fill = addon.TimerWindow.Elements().xpBar.fill
expect("Standard einfarbig", fill._texture, "Interface\\Buttons\\WHITE8x8")
addon.Set("themeBarTexture", "smooth")
expectTrue("eigene TGA", fill._texture:find("Media\\BarSmooth", 1, true) ~= nil)
addon.Set("themeBarTexture", "Fremd-Balken")
expect("LibSharedMedia-Pfad", fill._texture, "Interface\\Fremd")
media.statusbar = {}
addon.Set("themeBarTexture", "fehlt")
expect("unbekannt: einfarbig", fill._texture, "Interface\\Buttons\\WHITE8x8")
addon.Set("themeBarTexture", "")

---------------------------------------------------------------------------
-- Farbe nach Wert: XP/h gegen den Schnitt der letzten Level
---------------------------------------------------------------------------
local xpRateRow
for _, line in ipairs(addon.STAT_LINES) do
  if line.setting == "showXpRate" then xpRateRow = line.rows[1] end
end
addon.Experience.GetRatePerHour = function() return 1200 end
addon.Forecast.AverageLevelXpRate = function() return 1000 end
expect("aus: ungefärbt", xpRateRow.value(addon.Stats.LEVEL), Format.Number(1200))
addon.Set("valueColors", true)
expect("über dem Schnitt: gut", xpRateRow.value(addon.Stats.LEVEL), Theme.Hex("good") .. Format.Number(1200) .. "|r")
addon.Forecast.AverageLevelXpRate = function() return 1400 end
expect("darunter: schlecht", xpRateRow.value(addon.Stats.LEVEL), Theme.Hex("bad") .. Format.Number(1200) .. "|r")
addon.Forecast.AverageLevelXpRate = function() return 1250 end
expect("im Band: ungefärbt", xpRateRow.value(addon.Stats.LEVEL), Format.Number(1200))
addon.Forecast.AverageLevelXpRate = function() return nil end
expect("ohne Schnitt: ungefärbt", xpRateRow.value(addon.Stats.LEVEL), Format.Number(1200))

---------------------------------------------------------------------------
-- LiveSplit-Farben und Farbsehschwäche
---------------------------------------------------------------------------
local losing = Format.SplitDelta(-30, Format.SPLIT_AHEAD_LOSING)
expectTrue("vorn, verliert: helles Grün", losing:find(Theme.Hex("goodLosing"), 1, true) == 1)
expectTrue("Vorzeichen bleibt", losing:find("-", 1, true) ~= nil)
expectTrue("hinten, holt auf", Format.SplitDelta(30, Format.SPLIT_BEHIND_GAINING):find(Theme.Hex("badGaining"), 1, true) == 1)
local classicGood = Theme.Hex("good")
addon.Set("theme", "colorblind")
expectTrue("Farbsehschwäche: anderes Gut", Theme.Hex("good") ~= classicGood)
local r, g, b = Theme.RGB("goodLosing")
expectTrue("Farbsehschwäche: hell blau statt grün", b > g and b > r)
addon.Set("windowBackground", "green")
expectTrue("Chroma-Grün: kein helles Grün", Format.SplitDelta(-30, Format.SPLIT_AHEAD_LOSING):find(Theme.Hex("goodOnChroma"), 1, true) == 1)

expect("keine Fehler", #wow.errors, 0)

-- Roadmap 360-362: Hauptfenster aus Modell und Layouts. Modell (Zeilen je Bereich, Reihenfolge, Kurzlabels), jedes
-- Layout baut ohne Fehler und passt in fr/es, kein Neuzeichnen ohne Änderung, Prognose/Splits einmal je Takt,
-- Sichtbarkeitsregeln und ausgegraute Einstellungen.
local L = addon.L
local WindowModel = addon.WindowModel
local Layouts = addon.WindowLayouts
local window = LevelTimerFrame

wow.state.xp, wow.state.xpMax, wow.state.rested = 250, 1000, 0
wow.login({ level = 20, playedSeconds = 3600 })
wow.update(1)

---------------------------------------------------------------------------
-- Modell
---------------------------------------------------------------------------
local db = addon.db
addon.ApplyStatPreset(addon.STAT_PRESETS[2])  -- Leveln: XP/h, XP, Level-Up in, Max-Level in, Kills, Tode, Quests, Gold
local model = WindowModel.New():Build(db, WindowModel.VISIBLE)
local keys = {}
for index, row in ipairs(model.rows) do keys[index] = row.key end
expect("Zeilen in STAT_LINES-Reihenfolge", table.concat(keys, ","),
  "ROW_XP_RATE,ROW_XP_GAINED,ROW_LEVEL_ETA,ROW_MAX_LEVEL_ETA,ROW_PVE_KILLS,ROW_DEATHS,ROW_QUESTS,ROW_MONEY")
expect("Kurzlabel vorhanden", model.rows[3].shortLabel, L.ROW_LEVEL_ETA_SHORT)
expect("ohne Kurzlabel: normale Beschriftung", model.rows[1].shortLabel, L.ROW_XP_RATE)
expect("Reiter Level", model.tabs[1].text, string.format(L.TAB_LEVEL, 20))
expect("Level aktiv", model.tabs[1].active, true)

-- Instanz-Bereich ohne Lauf: Zeit "keine Instanz", Werte "-"
db.windowScope = "instance"
model:Build(db, WindowModel.VISIBLE)
expect("Instanz ohne Lauf: Zeit", model.time.text, L.INSTANCE_NONE)
expect("Instanz ohne Lauf: Wert", model.rows[1].value, "-")
db.windowScope = "level"

-- Reihenfolge: Tode nach oben (über die eingeschalteten), dann zurück
expectTrue("nach oben", WindowModel.MoveStat(db, "showDeaths", -1))
model:Invalidate()
model:Build(db, WindowModel.VISIBLE)
expect("Tode vor Kills", model.rows[5].key .. "," .. model.rows[6].key, "ROW_DEATHS,ROW_PVE_KILLS")
expect("Reihenfolge gespeichert", WindowModel.ParseList(db.rowOrder)[1], "showXpRate")
expectTrue("ganz oben geht nicht weiter", not WindowModel.MoveStat(db, "showXpRate", -1))
addon.Set("rowOrder", "")

-- Gewählte Zeilen (compactRows): unabhängig von den Schaltern, höchstens drei, unbekannte entfallen
db.compactRows = "ROW_DEATHS,KAPUTT,ROW_XP_SOURCES,ROW_XP_KILLS,ROW_GOAL,ROW_QUESTS"
model:Build(db, WindowModel.CHOSEN)
keys = {}
for index, row in ipairs(model.rows) do keys[index] = row.key end
expect("gewählte Zeilen", table.concat(keys, ","), "ROW_DEATHS,ROW_XP_KILLS,ROW_GOAL")
WindowModel.SetChosenRow(db, 2, "")
expect("Stelle geleert (ungültige entfallen)", db.compactRows, "ROW_DEATHS,ROW_GOAL")
addon.Set("compactRows", "ROW_XP_RATE")

---------------------------------------------------------------------------
-- Jedes Layout: baut ohne Fehler, Inhalt passt in de/fr/es (Breite >= gemessene Breite der sichtbaren Texte)
---------------------------------------------------------------------------
-- Sichtbare Texte des Fensters (ohne Kacheln, die messen gegen ihre Kachel)
local function shownTexts(el)
  local list = { el.time, el.big, el.sub }
  for _, row in ipairs(el.rows) do
    table.insert(list, row.label)
    table.insert(list, row.value)
  end
  for _, field in ipairs(el.fields) do table.insert(list, field) end
  local shown = {}
  for _, fontString in ipairs(list) do
    if fontString:IsShown() and fontString._text ~= "" then table.insert(shown, fontString) end
  end
  return shown
end
local checked = { count = 0 }

for _, language in ipairs({ "deDE", "frFR", "esES" }) do
  addon.Set("language", language)
  for _, id in ipairs(Layouts.ORDER) do
    addon.Set("windowLayout", id)
    wow.update(0.3)
    expect(language .. " " .. id .. ": aktiv", addon.TimerWindow.ActiveLayout(), id)
    expectTrue(language .. " " .. id .. ": Höhe", window:GetHeight() > 0)
    local active = Layouts.Get(id)
    local wanted = active.Measure(addon.TimerWindow.Elements(), addon.TimerWindow.Model(), addon.db)
    expectTrue(language .. " " .. id .. ": Breite reicht", window:GetWidth() >= wanted)
    -- Kein sichtbarer Text des Fensters ist breiter als das Fenster, keine Kachel-Beschriftung breiter als die Kachel
    for _, fontString in ipairs(shownTexts(addon.TimerWindow.Elements())) do
      checked.count = checked.count + 1
      expectTrue(language .. " " .. id .. ": " .. fontString._text, fontString:GetStringWidth() <= window:GetWidth())
    end
    for _, tile in ipairs(addon.TimerWindow.Elements().tiles) do
      if tile.frame:IsShown() then
        checked.count = checked.count + 1
        expectTrue(language .. " Kachel " .. tile.label._text, tile.label:GetStringWidth() <= tile.frame:GetWidth())
      end
    end
  end
end
addon.Set("language", "deDE")
expectTrue("Texte geprüft", checked.count > 100)

-- Leiste mit Kurzlabels: in fr schmaler als mit den vollen Beschriftungen
addon.Set("language", "frFR")
addon.Set("windowLayout", "bar")
local elements = addon.TimerWindow.Elements()
local short = elements.rows[3].label:GetText()
expect("Leiste: Kurzlabel", short, L.ROW_LEVEL_ETA_SHORT)
expectTrue("Kurzlabel ist kürzer", #short < #L.ROW_LEVEL_ETA)
addon.Set("language", "deDE")

-- Text: ohne Grund und Rand, Bezeichnungen abschaltbar; Chroma bleibt
addon.Set("windowLayout", "text")
expect("Text: kein Grund", window._backdropColor[4], 0)
expect("Text: Kontur", elements.rows[1].value._fontObject, addon.Theme.Font("small", true))
addon.Set("textLabels", false)
expect("Text: ohne Bezeichnung", elements.rows[1].label:IsShown(), false)
addon.Set("textLabels", true)
addon.Set("windowBackground", "green")
expect("Text mit Chroma: deckend", window._backdropColor[4], 1)
addon.Set("windowBackground", "default")

-- Kacheln: Spalten aus der Einstellung
addon.Set("windowLayout", "tiles")
addon.Set("tileColumns", 2)
local twoColumns = window:GetWidth()
addon.Set("tileColumns", 4)
expectTrue("mehr Spalten = breiter", window:GetWidth() > twoColumns)
expect("erste Kachel = Zeit mit Bereich", elements.tiles[1].label:GetText(), string.format(L.TAB_LEVEL, 20))

-- XP-Balken-Layout: Texte immer / bei Mauskontakt / nie
addon.Set("windowLayout", "xpbar")
expect("Balken: feste Breite", window:GetWidth(), addon.db.xpbarWidth)
expect("Balken: Texte", elements.fields[2]:IsShown(), true)
addon.Set("xpbarText", "never")
expect("nie: versteckt", elements.fields[2]:IsShown(), false)
addon.Set("xpbarText", "mouseover")
expect("Maus: erst versteckt", elements.fields[2]:IsShown(), false)
window._scripts.OnEnter(window)
expect("Maus: bei Kontakt sichtbar", elements.fields[2]:IsShown(), true)
window._scripts.OnLeave(window)
expect("Maus: danach versteckt", elements.fields[2]:IsShown(), false)
addon.Set("xpbarText", "always")

-- Uhr: gewählte Werte in der Unterzeile
addon.Set("windowLayout", "clock")
expectTrue("Uhr: Unterzeile mit XP/h", elements.sub:GetText():find(L.ROW_XP_RATE, 1, true) ~= nil)

---------------------------------------------------------------------------
-- Kein Neuzeichnen ohne Änderung; Prognose einmal je Takt
---------------------------------------------------------------------------
addon.Set("windowLayout", "table")
addon.Set("showMaxLevelEta", true)
addon.Goal.Set(60)
addon.Set("showGoal", true)
wow.update(0.3)
local value = elements.rows[1].value
local setTexts = { count = 0 }
local original = value.SetText
value.SetText = function(self, text)
  setTexts.count = setTexts.count + 1
  original(self, text)
end
local renders = addon.TimerWindow.RenderCount()
wow.update(0.3)
wow.update(0.3)
expect("unveränderter Wert: kein SetText", setTexts.count, 0)
expect("nichts geändert: kein Neuzeichnen", addon.TimerWindow.RenderCount(), renders)
value.SetText = nil

-- Max-Level-Zeile und Session-Ziel (Level 60) fragen dieselbe Prognose ab: einmal je Takt
local computed = { count = 0 }
local secondsToLevel = addon.Experience.GetSecondsToLevel
addon.Experience.GetSecondsToLevel = function(scope)
  if scope == addon.Stats.LEVEL then computed.count = computed.count + 1 end
  return secondsToLevel(scope)
end
addon.Set("showLevelEta", false)
wow.update(0.3)
computed.count = 0
wow.advance(1)
wow.update(0.3)
expect("Prognose einmal je Takt", computed.count, 1)
-- Roadmap 380: innerhalb derselben Sekunde ohne Ereignis keine Werte lesen; viele Frames, wenige Takte
computed.count = 0
for _ = 1, 60 do wow.update(0.016) end
expect("gleiche Sekunde, kein Ereignis: nichts gelesen", computed.count, 0)
for _ = 1, 10 do
  wow.advance(0.25)
  for _ = 1, 16 do wow.update(0.016) end
end
expectTrue("2,5 s mit 160 Frames: höchstens drei Takte lesen", computed.count <= 3)
computed.count = 0
wow.fire("PLAYER_XP_UPDATE", "player")
wow.update(0.3)
expect("Ereignis: sofort gelesen", computed.count, 1)
-- Außerhalb eines Takts rechnet sie immer neu (Ereignisse dürfen nichts Veraltetes sehen)
computed.count = 0
addon.Forecast.SecondsToLevel(60)
addon.Forecast.SecondsToLevel(60)
expect("außerhalb des Takts: jedes Mal", computed.count, 2)
addon.Experience.GetSecondsToLevel = secondsToLevel

-- Split gesamt: einmal je Takt, auch wenn Fenster-Zeile und Split-Liste fragen
local totals = { count = 0 }
local levelDelta = addon.Splits.GetCurrentDelta
addon.Splits.GetCurrentDelta = function() totals.count = totals.count + 1 return levelDelta() end
addon.TickCache.Run(function()
  addon.Splits.GetTotalDelta()
  addon.Splits.GetTotalDelta()
end)
expect("Split gesamt einmal je Takt", totals.count, 1)
addon.Splits.GetCurrentDelta = levelDelta

---------------------------------------------------------------------------
-- Sichtbarkeitsregeln
---------------------------------------------------------------------------
addon.Set("fadeAlpha", 0.3)
addon.Set("windowVisibility", "outOfCombat")
expect("nicht im Kampf: voll", window:GetAlpha(), 1)
wow.state.inCombat = true
wow.fire("PLAYER_REGEN_DISABLED")
expect("im Kampf: abgeblendet", window:GetAlpha(), 0.3)
expect("abgeblendet, nicht versteckt", window:IsShown(), true)
wow.state.inCombat = false
wow.fire("PLAYER_REGEN_ENABLED")
expect("nach dem Kampf: voll", window:GetAlpha(), 1)

addon.Set("windowVisibility", "inCombat")
expect("nur im Kampf: außerhalb abgeblendet", window:GetAlpha(), 0.3)
addon.Set("fadeAlpha", 0)
expect("Deckkraft 0: versteckt", window:IsShown(), false)
wow.state.inCombat = true
wow.fire("PLAYER_REGEN_DISABLED")
expect("im Kampf: da", window:IsShown(), true)
wow.state.inCombat = false
wow.fire("PLAYER_REGEN_ENABLED")

addon.Set("windowVisibility", "instanceOnly")
expect("außerhalb der Instanz versteckt", window:IsShown(), false)
wow.state.instance = { name = "Todesminen", type = "party" }
wow.fire("PLAYER_ENTERING_WORLD")
expect("in der Instanz da", window:IsShown(), true)
wow.state.instance = nil
wow.fire("ZONE_CHANGED_NEW_AREA")
expect("wieder draußen versteckt", window:IsShown(), false)

addon.Set("windowVisibility", "mouseover")
expect("Maus: da, aber durchsichtig", window:IsShown() and window:GetAlpha(), 0)
window._scripts.OnEnter(window)
expect("Maus darüber: voll", window:GetAlpha(), 1)
window._scripts.OnLeave(window)
expect("Maus weg: durchsichtig", window:GetAlpha(), 0)

-- Edit-Modus zeigt das Fenster immer voll
addon.Set("windowVisibility", "instanceOnly")
SlashCmdList.LEVELTIMER("edit")
expect("Edit-Modus: sichtbar", window:IsShown(), true)
expect("Edit-Modus: voll", window:GetAlpha(), 1)
SlashCmdList.LEVELTIMER("edit")
expect("nach dem Edit-Modus wieder versteckt", window:IsShown(), false)

-- Split-Liste mit eigener Regel
addon.Set("showSplitList", true)
addon.Set("splitListVisibility", "inCombat")
expect("Split-Liste außerhalb des Kampfs versteckt", LevelTimerSplits:IsShown(), false)
wow.state.inCombat = true
wow.fire("PLAYER_REGEN_DISABLED")
expect("Split-Liste im Kampf da", LevelTimerSplits:IsShown(), true)
wow.state.inCombat = false
wow.fire("PLAYER_REGEN_ENABLED")
addon.Set("splitListVisibility", "always")

-- Nur beim Leveln: auf Max-Level ausgeblendet
addon.Set("windowVisibility", "hideAtMaxLevel")
expect("beim Leveln da", window:IsShown(), true)

addon.Set("windowVisibility", "always")
addon.Set("windowLayout", "table")
wow.levelUp(60)
wow.update(0.3)
expect("Max-Level: Balken weg", elements.xpBar.background:IsShown(), false)

-- Nur beim Leveln: auf Max-Level versteckt (fadeAlpha 0)
addon.Set("windowVisibility", "hideAtMaxLevel")
expect("Max-Level: versteckt", window:IsShown(), false)

-- Einstellungen: was nur ein anderes Layout nutzt, ist ausgegraut und nicht bedienbar
SlashCmdList.LEVELTIMER("config")
local tileSlider = wow.findFrame(function(frame)
  local label = rawget(frame, "label")
  return label and label._text == L.TILE_COLUMNS and rawget(frame, "slider") ~= nil
end)
expectTrue("Regler Spalten gefunden", tileSlider ~= nil)
addon.Set("windowLayout", "table")
expect("Tabelle: Spalten ausgegraut", tileSlider:GetAlpha(), 0.4)
expect("Tabelle: Regler gesperrt", tileSlider.slider:IsMouseEnabled(), false)
addon.Set("windowLayout", "tiles")
expect("Kacheln: Spalten bedienbar", tileSlider:GetAlpha(), 1)
expectTrue("Layout-Auswahl: Kacheln", wow.click(L.LAYOUT_TABLE))
expect("Auswahl schaltet", addon.db.windowLayout, "table")
SlashCmdList.LEVELTIMER("config")

expect("Fehlerfrei", #wow.errors, 0)

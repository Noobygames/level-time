-- Roadmap 338: Einstellungen ändern ohne unnötige Arbeit. ns.Set mit gleichem Wert wendet nichts an, Regler
-- (ns.SetDeferred) wenden einmal je Frame an, das geschlossene Optionsfenster aktualisiert erst beim Öffnen, und die
-- Textbreiten werden nur gemessen, wenn sich ein Text geändert hat (Sprachwechsel).
local L = addon.L

wow.login()

local applies = { count = 0 }
addon.RegisterApply(function() applies.count = applies.count + 1 end)

-- Gleicher Wert: kein Apply; anderer Wert: genau einer
addon.Set("compactMode", addon.db.compactMode)
expect("gleicher Wert: kein Apply", applies.count, 0)
addon.Set("compactMode", not addon.db.compactMode)
expect("neuer Wert: ein Apply", applies.count, 1)
-- Tabellen (Positionen) werden oft an Ort und Stelle geändert: immer anwenden
local position = { "CENTER", "CENTER", 0, 0 }
addon.Set("alertPos", position)
addon.Set("alertPos", position)
expect("Tabellen: immer angewendet", applies.count, 3)

-- Regler: viele Änderungen in einem Frame, ein Apply im nächsten Frame; der Wert steht sofort in db
applies.count = 0
for value = 50, 70 do addon.SetDeferred("bgAlpha", value / 100) end
expect("Wert sofort gesetzt", addon.db.bgAlpha, 0.7)
expect("noch kein Apply", applies.count, 0)
wow.update(0.02)
expect("ein Apply im nächsten Frame", applies.count, 1)
wow.update(0.02)
expect("danach keiner mehr", applies.count, 1)
-- Ein sofortiger Apply erledigt einen ausstehenden mit
addon.SetDeferred("bgAlpha", 0.5)
addon.Set("compactMode", not addon.db.compactMode)
wow.update(0.02)
expect("ausstehender Apply mit erledigt", applies.count, 2)

-- Geschlossenes Optionsfenster: Schalter erst beim Öffnen aktuell
local function checkbox(labelKey)
  return wow.findFrame(function(frame)
    local label = rawget(frame, "label")
    return label and label._text == L[labelKey] and frame._scripts.OnClick ~= nil
  end)
end
SlashCmdList.LEVELTIMER("config")
local compact = checkbox("COMPACT_MODE")
expectTrue("Schalter gefunden", compact ~= nil)
addon.ToggleOptions()
expect("Fenster zu", LevelTimerOptions:IsShown(), false)
local before = compact:GetChecked()
addon.Set("compactMode", not addon.db.compactMode)
expect("geschlossen: nicht aktualisiert", compact:GetChecked(), before)
LevelTimerOptions:Show()
expect("beim Öffnen aktualisiert", compact:GetChecked(), addon.db.compactMode)

-- Offen: Wertänderung misst keine Texte, Sprachwechsel schon
local measured = { count = 0 }
local label = compact.label
local width = label.GetStringWidth
label.GetStringWidth = function(self)
  measured.count = measured.count + 1
  return width(self)
end
addon.Set("compactMode", not addon.db.compactMode)
expect("offen: Schalter aktualisiert", compact:GetChecked(), addon.db.compactMode)
expect("Wertänderung: keine Messung", measured.count, 0)
addon.Set("language", "enUS")
expectTrue("Sprachwechsel: gemessen", measured.count > 0)
expect("englische Beschriftung", label:GetText(), addon.L.COMPACT_MODE)
addon.Set("language", "deDE")

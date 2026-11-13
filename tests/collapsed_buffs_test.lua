-- Gewählte Buffs bei eingeklappter Buffleiste (Roadmap 500): nur eingeklappt sichtbar, Stapel und Restzeit,
-- Auswahl per Spell-ID (über den Namen, alle Ränge) oder Name, gesperrte Auren und Einstellung aus = nichts.
local CollapsedBuffs = addon.CollapsedBuffs
local WATER_SHIELD, WATER_SHIELD_RANK2 = 52127, 52129

wow.state.spellNames[WATER_SHIELD] = "Wasserschild"
local bar = { expanded = true }  -- Tabelle statt Bool-Local (gopher-lua, siehe unit_events_test.lua)
BuffFrame = CreateFrame("Frame", "BuffFrame", UIParent)
BuffFrame.IsExpanded = function() return bar.expanded end

wow.state.buffs = {
  { name = "Wasserschild", spellId = WATER_SHIELD_RANK2, icon = 132315, applications = 3, duration = 600,
    expirationTime = GetTime() + 540 },
  { name = "Satt", spellId = 19705, duration = 0, expirationTime = 0 },
}
wow.login()
local frame = CollapsedBuffs.Frame()
local function tick()
  wow.advance(1)
  wow.update(1)
end

tick()
expect("ausgeklappt: nichts", CollapsedBuffs.ShownCount(), 0)

bar.expanded = false
tick()
expect("eingeklappt: Wasserschild (anderer Rang, per Name)", CollapsedBuffs.ShownCount(), 1)
local count, time = CollapsedBuffs.IconTexts(1)
expect("Stapel sichtbar", count, "3")
expect("Restzeit in Minuten", time, "9m")
expectTrue("Anzeige sichtbar", frame:IsShown())

-- Eigene Liste: Name statt ID
addon.Set("collapsedBuffsList", "satt")
tick()
expect("Liste per Name", CollapsedBuffs.ShownCount(), 1)
addon.Set("collapsedBuffsList", "")
tick()
expect("leere Liste", CollapsedBuffs.ShownCount(), 0)
addon.Set("collapsedBuffsList", "52127; Satt")
tick()
expect("beide", CollapsedBuffs.ShownCount(), 2)

-- Gesperrte Auren (Kampf in Retail/Forever): keine alten Stände zeigen
wow.state.aurasSecret = true
wow.fire("UNIT_AURA", "player")
tick()
expect("gesperrt: nichts", CollapsedBuffs.ShownCount(), 0)
wow.state.aurasSecret = false
wow.fire("UNIT_AURA", "player")

addon.Set("collapsedBuffs", false)
tick()
expect("aus: nichts", CollapsedBuffs.ShownCount(), 0)
addon.Set("collapsedBuffs", true)
tick()
expect("wieder an", CollapsedBuffs.ShownCount(), 2)

-- Vorschau aus den Einstellungen zeigt ein Beispiel, auch ausgeklappt
bar.expanded = true
tick()
expect("ausgeklappt: wieder nichts", CollapsedBuffs.ShownCount(), 0)
expectTrue("Vorschau", addon.Frames.Preview("collapsedBuffs"))
expect("Vorschau zeigt ein Symbol", CollapsedBuffs.ShownCount(), 1)
wow.runTimers()
expect("Vorschau vorbei", CollapsedBuffs.ShownCount(), 0)

-- Client ohne einklappbare Leiste
BuffFrame = nil
expect("ohne BuffFrame: unbekannt", CollapsedBuffs.IsBarCollapsed(), nil)

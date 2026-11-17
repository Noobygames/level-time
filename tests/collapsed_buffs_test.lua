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
-- LT-349: im Kampf gibt Blizzard einzelne Auren frei; per Spell-ID abgefragt erscheint der Schild trotzdem
addon.Set("collapsedBuffsList", "52129")
tick()
expect("gesperrt, Schild freigegeben", CollapsedBuffs.ShownCount(), 1)
expect("Stapel im Kampf", (CollapsedBuffs.IconTexts(1)), "3")
wow.state.secretSpellAuras = { [52129] = true }
tick()
expect("Schild geheim: nichts", CollapsedBuffs.ShownCount(), 0)
wow.state.secretSpellAuras = nil
addon.Set("collapsedBuffsList", "52127; Satt")
wow.state.aurasSecret = false
wow.fire("UNIT_AURA", "player")

-- Geheime Stapelzahl: Anzeigetext von Blizzard wird durchgereicht, ohne Vergleich
local shield = wow.state.buffs[1]
shield.applications, shield.auraInstanceID = wow.SECRET, 7
C_UnitAuras.GetAuraApplicationDisplayCount = function(unit, id, min) return unit == "player" and id == 7 and min == 2 and "3" or "" end
wow.fire("UNIT_AURA", "player")
tick()
expect("geheimer Stapel per Blizzard-Text", (CollapsedBuffs.IconTexts(1)), "3")
shield.applications = 3

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

-- Angedockt hinter den letzten sichtbaren Blizzard-Buff, solange nie verschoben
BuffFrame.AuraContainer = CreateFrame("Frame", nil, BuffFrame)
local shownBuff, hiddenBuff = CreateFrame("Button"), CreateFrame("Button")
hiddenBuff:Hide()
BuffFrame.auraFrames = { shownBuff, hiddenBuff }
bar.expanded = false
tick()
local _, dockedTo, relPoint = frame:GetPoint(1)
expectTrue("angedockt an letzten sichtbaren Buff", dockedTo == shownBuff)
expect("links daneben", relPoint, "TOPLEFT")
addon.Frames.SetPosition("collapsedBuffs", "CENTER", "CENTER", 10, 20)
tick()
_, dockedTo = frame:GetPoint(1)
expectTrue("verschoben: eigene Position", dockedTo ~= shownBuff)
addon.Frames.Reset("collapsedBuffs")
tick()
_, dockedTo = frame:GetPoint(1)
expectTrue("zurückgesetzt: wieder angedockt", dockedTo == shownBuff)

-- Client ohne einklappbare Leiste
BuffFrame = nil
expect("ohne BuffFrame: unbekannt", CollapsedBuffs.IsBarCollapsed(), nil)

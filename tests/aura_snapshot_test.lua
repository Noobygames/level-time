-- Gemeinsamer Aura-Schnappschuss (Lib/Auras.lua): ein Scan je Aura-Änderung statt je Modul und Prüfung.
local Auras = addon.Auras
local scan = { calls = 0 }  -- Tabelle statt Zahl-Local (gopher-lua, siehe unit_events_test.lua)
local getAura = C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex = function(...)
  scan.calls = scan.calls + 1
  return getAura(...)
end

wow.state.buffs = { "Satt", { name = "Lagervorteile", spellId = 1229741 } }
wow.login()
scan.calls = 0

expect("Name gefunden", Auras.FindByName("Satt").name, "Satt")
expect("Spell-ID gefunden", Auras.FindBySpellId(1229741).name, "Lagervorteile")
expect("fehlt", Auras.FindByName("Seelenstärke"), false)
expectTrue("Has", Auras.Has(function(aura) return aura.name == "Satt" end))
local readCalls = scan.calls
expect("ein Scan für alle Abfragen (2 Buffs + Ende)", readCalls, 3)
expect("Buff-Hinweis nutzt denselben Schnappschuss", addon.BuffReminder.IsFoodMissing(), false)
expect("kein weiterer Scan", scan.calls, readCalls)

-- UNIT_AURA für andere Einheiten ändert nichts, für den Spieler wird neu gelesen
wow.fire("UNIT_AURA", "party1")
Auras.FindByName("Satt")
expect("party1: kein neuer Scan", scan.calls, readCalls)
wow.state.buffs = {}  -- der Stub meldet UNIT_AURA für den Spieler
expect("nach UNIT_AURA neu gelesen", Auras.FindByName("Satt"), false)
expect("Buff-Hinweis sieht es", addon.BuffReminder.IsFoodMissing(), true)

-- Sicherheitsnetz: höchstens MAX_SNAPSHOT_AGE alt, auch ohne Event
local before = scan.calls
Auras.Snapshot()
expect("frisch: kein Scan", scan.calls, before)
wow.advance(Auras.MAX_SNAPSHOT_AGE + 0.1)
Auras.Snapshot()
expect("zu alt: neu gelesen", scan.calls, before + 1)

-- Gesperrte Auren (Kampf in Retail/Forever): kein Schnappschuss, danach kein veralteter Stand
wow.state.aurasSecret = true
expect("gesperrt: nil", Auras.Snapshot(), nil)
expect("gesperrt: Name nicht feststellbar", Auras.FindByName("Satt"), nil)
wow.state.aurasSecret = false
before = scan.calls
Auras.Snapshot()
expect("nach der Sperre neu gelesen", scan.calls, before + 1)

-- Geheimer Name mitten in der Liste: nicht feststellbar, und nicht gemerkt
wow.state.buffs = { "Satt", { name = wow.SECRET, spellId = 5 } }
expect("geheimer Buff: nil", Auras.Snapshot(), nil)
before = scan.calls
Auras.Snapshot()
expectTrue("ungültiges Ergebnis wird nicht gemerkt", scan.calls > before)

-- Essen-Timer aus: liest gar keine Buffs
wow.state.buffs = { { name = "Essen", spellId = 433, expirationTime = GetTime() + 18, duration = 18 } }
addon.Set("foodTimer", false)
wow.advance(Auras.MAX_SNAPSHOT_AGE + 1)
before = scan.calls
addon.FoodTimer.Check()
expect("Essen-Timer aus: kein Scan", scan.calls, before)
addon.Set("foodTimer", true)
addon.FoodTimer.Check()
expectTrue("Essen-Timer an: gelesen", scan.calls > before)
expect("Countdown läuft", LevelTimerFood and LevelTimerFood:IsShown(), true)

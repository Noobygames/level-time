-- Schwungbalken (Roadmap 452, Classic): Kampflog startet Haupt-/Nebenhand, Fähigkeiten "beim nächsten Schlag"
-- die Haupthand, Automatischer Schuss den Fernkampf; ohne Kampflog läuft die Haupthand im Takt weiter
local SwingTimer = addon.SwingTimer
local PLAYER = "Player-1-0001"
local HEROIC_STRIKE = 78

wow.state.guid = PLAYER
wow.state.spellNames[HEROIC_STRIKE] = "Heldenhafter Stoß"
wow.state.attackSpeed = { 2.6, 1.8 }
wow.state.rangedSpeed = 3
wow.login({ level = 20 })
expect("Era: verfügbar", SwingTimer.IsAvailable(), true)
expectTrue("Einstellung in den Optionen", #addon.OptionsWindow.Search(addon.L.SWING_TIMER) > 0)

-- Aus: nichts läuft
local function swing(subevent, source, ...)
  wow.state.combatLog = { wow.state.now, subevent, false, source, "Ich", 0, 0, "Creature-9", "Eber", 0, 0, ... }
  wow.fire("COMBAT_LOG_EVENT_UNFILTERED")
end
swing("SWING_DAMAGE", PLAYER, 50, 0, 1, 0, 0, 0, false, false, false, false)
expect("aus: kein Schwung", SwingTimer.Remaining(SwingTimer.MAIN), nil)

addon.Set("swingTimer", true)
-- Haupthand: SWING_DAMAGE mit isOffHand (Feld 21) = false
swing("SWING_DAMAGE", PLAYER, 50, 0, 1, 0, 0, 0, false, false, false, false)
expectNear("Haupthand startet mit Tempo", (SwingTimer.Remaining(SwingTimer.MAIN)), 2.6, 0.001)
expectTrue("Anzeige sichtbar", SwingTimer.Frame():IsShown())
-- Nebenhand: SWING_MISSED mit isOffHand (Feld 13) = true
swing("SWING_MISSED", PLAYER, "MISS", true)
expectNear("Nebenhand startet", (SwingTimer.Remaining(SwingTimer.OFF)), 1.8, 0.001)
-- fremde Schläge zählen nicht
wow.advance(1)
swing("SWING_DAMAGE", "Player-1-0002", 50, 0, 1, 0, 0, 0, false, false, false, false)
expectNear("fremder Schlag ändert nichts", (SwingTimer.Remaining(SwingTimer.MAIN)), 1.6, 0.001)
-- Heldenhafter Stoß ersetzt den Haupthand-Schlag
swing("SPELL_DAMAGE", PLAYER, HEROIC_STRIKE, "Heldenhafter Stoß", 1, 120)
expectNear("nächster Schlag startet neu", (SwingTimer.Remaining(SwingTimer.MAIN)), 2.6, 0.001)

-- Fernkampf: Automatischer Schuss
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", 75)
expectNear("Fernkampf startet", (SwingTimer.Remaining(SwingTimer.RANGED)), 3, 0.001)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", 133)
expectNear("anderer Zauber ändert nichts", (SwingTimer.Remaining(SwingTimer.RANGED)), 3, 0.001)

-- Ablauf: Balken verschwinden, wenn kein Schwung mehr läuft
wow.advance(5)
local frame = SwingTimer.Frame()
frame._scripts.OnUpdate(frame, 0.1)
expect("Haupthand abgelaufen", SwingTimer.Remaining(SwingTimer.MAIN), nil)
expect("Anzeige weg", SwingTimer.Frame():IsShown(), false)

-- Geheimes Tempo: kein Schwung statt Fehler
wow.state.attackSpeed = { wow.SECRET }
swing("SWING_DAMAGE", PLAYER, 50, 0, 1, 0, 0, 0, false, false, false, false)
expect("geheimes Tempo: nichts", SwingTimer.Remaining(SwingTimer.MAIN), nil)
wow.state.attackSpeed = { 2.6, 1.8 }

-- Anpassung (Roadmap 489): Größe, Anordnung, Text, Hände einzeln, nur im Kampf, Farbe
local mainBar, offBar = SwingTimer.Bar(SwingTimer.MAIN), SwingTimer.Bar(SwingTimer.OFF)
local function update() frame._scripts.OnUpdate(frame, 0.1) end
addon.Set("swingTimerWidth", 100)
addon.Set("swingTimerHeight", 20)
expect("Breite", mainBar:GetWidth(), 100)
expect("untereinander: Leiste so breit wie ein Balken", frame:GetWidth(), 100)
addon.Set("swingTimerLayout", "horizontal")
expect("nebeneinander: drei Balken breit", frame:GetWidth(), 3 * 100 + 2 * 2)
addon.Set("swingTimerRanged", false)
expect("ohne Fernkampf nur zwei Plätze", frame:GetWidth(), 2 * 100 + 2)
swing("SWING_DAMAGE", PLAYER, 50, 0, 1, 0, 0, 0, false, false, false, false)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-3", 75)
update()
expect("Fernkampf aus: Balken verborgen", SwingTimer.Bar(SwingTimer.RANGED):IsShown(), false)
expectTrue("Fernkampf läuft trotzdem", SwingTimer.Remaining(SwingTimer.RANGED) ~= nil)
expect("Text: Restzeit", mainBar.text:GetText(), "2.6")
addon.Set("swingTimerText", "both")
update()
expect("Text: Rest / Dauer", mainBar.text:GetText(), "2.6 / 2.6")
addon.Set("swingTimerText", "none")
update()
expect("Text aus", mainBar.text:GetText(), "")
wow.state.inCombat = false
addon.Set("swingTimerCombatOnly", true)
update()
expect("nur im Kampf: außerhalb verborgen", frame:IsShown(), false)
expectTrue("Schwung läuft weiter", SwingTimer.Remaining(SwingTimer.MAIN) ~= nil)
addon.Set("swingTimerColorOff", "blue")
local r, g, b = offBar:GetStatusBarColor()
expect("Farbe Nebenhand aus dem Theme", r .. "," .. g .. "," .. b, "0.35,0.65,1")
expect("Era kennt Blizzards Schwungbalken nicht", addon.CVars.Exists(SwingTimer.BLIZZARD_CVAR), false)

addon.Set("swingTimer", false)
expect("keine Lua-Fehler", #wow.errors, 0)

-- Lagerfeuer in WoW Forever (Szenarien forever_* laden als Forever): Hinweis bei Feuer in der Nähe ohne
-- Lagervorteile, Countdown beim einladenden Lagerfeuer, "Lagervorteile aktiv" danach, Vorschau und Position.
local L = addon.L
local Camp = addon.CampFire
local Display = addon.CampDisplay
local NEARBY, INVITING, BENEFITS = 1283391, 1229739, 1229741

local played = {}
function PlaySound(id) table.insert(played, id) end

wow.login({ level = 30 })
expectTrue("als Forever erkannt", Camp.IsAvailable())
local camp = LevelTimerCamp

local function aura(spellId, name, duration, expiration)
  return { spellId = spellId, name = name, duration = duration or 0, expirationTime = expiration or 0 }
end
local function nearby() return aura(NEARBY, "Lagerfeuer in der Nähe") end
local function benefits(expiration) return aura(BENEFITS, "Lagervorteile", 3600, expiration) end
local function inviting(expiration) return aura(INVITING, "Einladendes Lagerfeuer", 60, expiration) end
local function shownText(text)
  return wow.findFrame(function(frame) return frame._text == text end) ~= nil
end
local function tick() camp._scripts.OnUpdate(camp, 1) end

---------------------------------------------------------------------------
-- Hinweis: Feuer in der Nähe, keine Lagervorteile
---------------------------------------------------------------------------
expect("zunächst versteckt", camp:IsShown(), false)
wow.state.buffs = { nearby() }
Camp.Check()
expect("Hinweis sichtbar", camp:IsShown(), true)
expectTrue("Hinweistext", shownText(L.CAMP_HINT_TEXT))

wow.state.buffs = { nearby(), benefits(GetTime() + 3000) }
Camp.Check()
expect("mit Lagervorteilen kein Hinweis", camp:IsShown(), false)

-- Hinweis steht nur kurz und kommt erst nach der Pause wieder
wow.state.buffs = { nearby() }
Camp.Check()
expect("Hinweis erscheint", camp:IsShown(), true)
wow.advance(9)
Camp.Check()
expect("Hinweis verschwindet nach ein paar Sekunden", camp:IsShown(), false)
wow.advance(60)
Camp.Check()
expect("Pause läuft noch", camp:IsShown(), false)
wow.state.buffs = {}
Camp.Check()
wow.state.buffs = { nearby() }
Camp.Check()
expect("Wiederkommen in der Pause: kein Hinweis", camp:IsShown(), false)
wow.advance(5 * 60)
Camp.Check()
expect("nach der Pause wieder da", camp:IsShown(), true)

addon.Set("campHint", false)
wow.state.buffs = { nearby() }
Camp.Check()
expect("Hinweis abgeschaltet", camp:IsShown(), false)
addon.Set("campHint", true)

---------------------------------------------------------------------------
-- Countdown: Restzeit aus der Ablaufzeit des Buffs
---------------------------------------------------------------------------
local oldExpiration = GetTime() + 3000
wow.state.buffs = { nearby(), benefits(oldExpiration), inviting(GetTime() + 60) }
Camp.Check()
expect("Countdown sichtbar", camp:IsShown(), true)
expectTrue("60 s", shownText(addon.Format.Duration(60)))
wow.advance(20)
Camp.Check()
tick()
expectTrue("nach 20 s noch 40 s", shownText(addon.Format.Duration(40)))

-- Ohne Aura-Änderung arbeitet die Prüfung nicht (Roadmap 391): kein neuer Zustand, keine Anzeige-Aufrufe
local shows = { count = 0 }
local show = Display.Show
Display.Show = function(...)
  shows.count = shows.count + 1
  return show(...)
end
for _ = 1, 10 do
  wow.advance(0.5)
  Camp.Check()
end
expect("Countdown ohne Änderung: Anzeige nicht angefasst", shows.count, 0)
tick()
expectTrue("Countdown läuft in der Anzeige weiter", shownText(addon.Format.Duration(35)))
Display.Show = show

-- Countdown vorbei, Lagervorteile erneuert: kurz "aktiv", mit Ton wenn gewünscht
addon.Set("campSound", true)
wow.advance(40)
wow.state.buffs = { nearby(), benefits(GetTime() + 3600) }
Camp.Check()
expect("Meldung nach dem Countdown", camp:IsShown(), true)
expectTrue("Lagervorteile aktiv", shownText(L.CAMP_DONE))
expect("Ton gespielt", #played, 1)
Camp.Check()
expectTrue("bleibt stehen", camp:IsShown())
wow.advance(5)
tick()
expect("danach weg", camp:IsShown(), false)
addon.Set("campSound", false)

-- Zum ersten Mal am Feuer (noch keine Lagervorteile): die neuen Vorteile werden gemeldet
wow.state.buffs = { nearby(), inviting(GetTime() + 60) }
Camp.Check()
wow.advance(60)
wow.state.buffs = { nearby(), benefits(GetTime() + 3600) }
Camp.Check()
expectTrue("erste Lagervorteile gemeldet", shownText(L.CAMP_DONE) and camp:IsShown())
wow.advance(5)
tick()

-- Vorzeitig aufgestanden: keine Meldung, Lagervorteile unverändert
local unchanged = GetTime() + 3000
wow.state.buffs = { nearby(), benefits(unchanged), inviting(GetTime() + 60) }
Camp.Check()
wow.advance(15)
wow.state.buffs = { nearby(), benefits(unchanged) }
Camp.Check()
wow.advance(5)
Camp.Check()
expect("kein Countdown mehr", camp:IsShown(), false)
expect("keine falsche Erfolgsmeldung", shownText(L.CAMP_DONE) and camp:IsShown(), false)

-- Lagervorteile mit unlesbarer Ablaufzeit: ob der Countdown sie erneuert hat, ist nicht feststellbar, also keine Meldung
local secretBenefits = aura(BENEFITS, "Lagervorteile", 3600, wow.SECRET)
wow.state.buffs = { nearby(), secretBenefits, inviting(GetTime() + 60) }
Camp.Check()
wow.advance(10)
wow.state.buffs = { nearby(), secretBenefits }
Camp.Check()
wow.advance(5)
Camp.Check()
expect("unbekannte Ablaufzeit: keine Meldung", camp:IsShown(), false)

-- Countdown abgeschaltet
addon.Set("campCountdown", false)
wow.state.buffs = { nearby(), inviting(GetTime() + 60) }
Camp.Check()
expect("Countdown abgeschaltet", camp:IsShown(), false)
addon.Set("campCountdown", true)

---------------------------------------------------------------------------
-- Gesperrte Auren und andere Clients
---------------------------------------------------------------------------
wow.state.buffs = { nearby() }
wow.state.aurasSecret = true
Camp.Check()
expect("gesperrte Auren: nichts, kein Fehler", camp:IsShown(), false)
wow.state.aurasSecret = false

wow.state.interface = 11509
Camp.Check()
expect("nicht in Forever", camp:IsShown(), false)
wow.state.interface = 16001

---------------------------------------------------------------------------
-- Vorschau, Verschieben, Größe
---------------------------------------------------------------------------
Display.Preview()
expectTrue("Vorschau 1: Hinweis", shownText(L.CAMP_HINT_TEXT) and camp:IsShown())
Display.Preview()
expectTrue("Vorschau 2: Countdown", shownText(L.CAMP_TITLE_COUNTDOWN))
Display.Preview()
expectTrue("Vorschau 3: aktiv", shownText(L.CAMP_DONE))
wow.state.buffs = {}
Camp.Check()
expectTrue("echte Zustände stören die Vorschau nicht", camp:IsShown())
wow.advance(9)
tick()
expect("Vorschau endet", camp:IsShown(), false)

local EditMode, Frames = addon.EditMode, addon.Frames
EditMode.Enter()
expect("Edit-Modus zeigt den Countdown", camp:IsShown(), true)
local overlay = EditMode.Overlay("camp")
overlay._scripts.OnDragStart(overlay)
overlay._scripts.OnDragStop(overlay)
expectTrue("Position gespeichert", LevelTimerDB.frames.camp.point ~= nil)
EditMode.Leave()
expect("danach versteckt", camp:IsShown(), false)

LevelTimerDB.frames.camp = { point = "TOP", relPoint = "TOP", x = 100, y = -200 }
addon.ApplySettings()  -- neue Tabelle übernehmen
Frames.SetScale("camp", 2)
expect("Größe: Abstand x umgerechnet", LevelTimerDB.frames.camp.x, 50)
expect("Größe: Abstand y umgerechnet", LevelTimerDB.frames.camp.y, -100)
Frames.Reset("camp")
expect("Position zurückgesetzt", LevelTimerDB.frames.camp, nil)

---------------------------------------------------------------------------
-- Einstellungen
---------------------------------------------------------------------------
SlashCmdList.LEVELTIMER("config")
expectTrue("Unterseite Timer & Flüge", addon.OptionsWindow.ShowPage("COMFORT_PAGE_TIMERS"))
expectTrue("Button Vorschau", wow.clickOption("CAMP_PREVIEW"))
expect("Vorschau zeigt Anzeige", camp:IsShown(), true)
-- Layout bearbeiten (unten auf jedem Reiter): alle Anzeigen auf einmal, auch das Lagerfeuer
expectTrue("Button Layout bearbeiten", wow.click(L.EDIT_MODE))
expect("Lagerfeuer im Edit-Modus", camp:IsShown(), true)
expectTrue("Lagerfeuer hat eine Fläche", EditMode.Overlay("camp"):IsShown())
EditMode.Leave()
expect("Edit-Modus aus: Anzeige weg", camp:IsShown(), false)

-- Beide Anzeigen aus: keine Buff-Abfrage, die Anzeige verschwindet; Einschalten beginnt neu
local scans = { count = 0 }
local getAura = C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex = function(...)
  scans.count = scans.count + 1
  return getAura(...)
end
wow.state.buffs = { nearby(), inviting(GetTime() + 60) }
addon.Set("campCountdown", true)
Camp.Check()
expect("an: Countdown", camp:IsShown(), true)
addon.Set("campCountdown", false)
addon.Set("campHint", false)
expect("aus: Anzeige weg", camp:IsShown(), false)
wow.state.buffs = { nearby(), inviting(GetTime() + 50) }
local scansBefore = scans.count
Camp.Check()
expect("aus: keine Abfrage", scans.count, scansBefore)
addon.Set("campCountdown", true)
Camp.Check()
expect("wieder an: Countdown", camp:IsShown(), true)
C_UnitAuras.GetAuraDataByIndex = getAura

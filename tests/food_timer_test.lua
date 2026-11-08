-- Essen-Timer: Countdown beim Essen ("Essen", 18 s), "Satt aktiv" wenn "Satt" kommt, auch schon während des Essens.
local L = addon.L
local FoodTimer = addon.FoodTimer
local Display = addon.FoodDisplay
local EATING, WELL_FED = 433, 19705

local played = {}
function PlaySound(id) table.insert(played, id) end

wow.login({ level = 20 })
expectTrue("verfügbar", FoodTimer.IsAvailable())
local food = LevelTimerFood

local function aura(spellId, name, duration, expiration)
  return { spellId = spellId, name = name, duration = duration or 0, expirationTime = expiration or 0 }
end
local function eating(remaining) return aura(EATING, "Essen", 18, GetTime() + remaining) end
local function wellFed(expiration) return aura(555, "Satt", 3600, expiration) end
local function shownText(text)
  return wow.findFrame(function(frame) return frame._text == text end) ~= nil
end
local function tick() food._scripts.OnUpdate(food, 1) end

expect("zunächst versteckt", food:IsShown(), false)

-- Essen: Countdown mit der Restzeit
wow.state.buffs = { eating(18) }
FoodTimer.Check()
expect("Countdown sichtbar", food:IsShown(), true)
expectTrue("18 s", shownText(addon.Format.Duration(18)))
wow.advance(8)
wow.state.buffs = { eating(10) }
FoodTimer.Check()
tick()
expectTrue("nach 8 s noch 10 s", shownText(addon.Format.Duration(10)))

-- "Satt" kommt schon vor dem Ende des Essens: Countdown endet mit "Satt aktiv", Ton wenn gewünscht
addon.Set("foodSound", true)
wow.state.buffs = { eating(9), wellFed(GetTime() + 3600) }
FoodTimer.Check()
expectTrue("Satt aktiv", shownText(L.FOOD_DONE))
expect("Ton gespielt", #played, 1)
FoodTimer.Check()
wow.state.buffs = { eating(8), wellFed(GetTime() + 3600) }
FoodTimer.Check()
expectTrue("Countdown kehrt nicht zurück", shownText(L.FOOD_DONE))
expect("Ton nur einmal", #played, 1)
wow.advance(5)
tick()
expect("danach weg", food:IsShown(), false)
addon.Set("foodSound", false)

-- Aufgestanden ohne "Satt": keine Meldung
wow.state.buffs = { eating(18) }
FoodTimer.Check()
wow.advance(5)
wow.state.buffs = {}
FoodTimer.Check()
wow.advance(5)
FoodTimer.Check()
expect("nichts mehr", food:IsShown(), false)
expect("keine falsche Meldung", shownText(L.FOOD_DONE) and food:IsShown(), false)

-- Essen zu Ende, "Satt" kommt kurz danach
wow.state.buffs = { eating(2) }
FoodTimer.Check()
wow.advance(2)
wow.state.buffs = { wellFed(GetTime() + 3600) }
FoodTimer.Check()
expect("Satt nach dem Essen", food:IsShown(), true)
expectTrue("Satt aktiv nach dem Essen", shownText(L.FOOD_DONE))
wow.advance(5)
tick()

-- Schon satt: nur Erneuerung zählt
local old = GetTime() + 1000
wow.state.buffs = { eating(18), wellFed(old) }
FoodTimer.Check()
expectTrue("Countdown trotz altem Satt", shownText(addon.Format.Duration(18)))
wow.state.buffs = { eating(17), wellFed(old) }
FoodTimer.Check()
expect("unverändertes Satt: Countdown läuft weiter", food:IsShown(), true)
expectTrue("immer noch Countdown", not shownText(L.FOOD_DONE) or food:IsShown())
wow.state.buffs = { eating(5), wellFed(GetTime() + 3600) }
FoodTimer.Check()
expectTrue("erneuertes Satt", shownText(L.FOOD_DONE))
wow.advance(5)
tick()

-- Satt mit unlesbarer Ablaufzeit: nicht feststellbar, keine Meldung
wow.state.buffs = {}
FoodTimer.Check()  -- Mahlzeit vorbei
wow.state.buffs = { eating(18), wellFed(wow.SECRET) }
FoodTimer.Check()
wow.state.buffs = { eating(10), wellFed(wow.SECRET) }
FoodTimer.Check()
expect("unlesbar: Countdown bleibt", food:IsShown(), true)
wow.state.buffs = {}
FoodTimer.Check()
wow.advance(5)
FoodTimer.Check()
expect("unlesbar: keine Meldung", food:IsShown(), false)

-- Ausgeschaltet, gesperrte Auren
addon.Set("foodTimer", false)
wow.state.buffs = { eating(18) }
FoodTimer.Check()
expect("abgeschaltet", food:IsShown(), false)
addon.Set("foodTimer", true)
wow.state.aurasSecret = true
FoodTimer.Check()
expect("gesperrte Auren: nichts, kein Fehler", food:IsShown(), false)
wow.state.aurasSecret = false

-- Vorschau, Verschieben, Größe
Display.Preview()
expectTrue("Vorschau 1: Countdown", shownText(L.FOOD_TITLE_COUNTDOWN) and food:IsShown())
Display.Preview()
expectTrue("Vorschau 2: Satt aktiv", shownText(L.FOOD_DONE))
addon.EditMode.Enter()
expect("Edit-Modus zeigt den Countdown", food:IsShown(), true)
local overlay = addon.EditMode.Overlay("food")
overlay._scripts.OnDragStart(overlay)
overlay._scripts.OnDragStop(overlay)
expectTrue("Position gespeichert", LevelTimerDB.frames.food.point ~= nil)
addon.EditMode.Leave()
expect("Verlassen versteckt", food:IsShown(), false)
addon.Frames.Reset("food")
expect("Position zurückgesetzt", LevelTimerDB.frames.food, nil)

-- Einstellungen
SlashCmdList.LEVELTIMER("config")
expectTrue("Reiter Timer", wow.click(L.OPTIONS_TAB_TIMERS))
expectTrue("Button Vorschau", wow.clickOption("FOOD_PREVIEW"))
expect("Vorschau zeigt Anzeige", food:IsShown(), true)

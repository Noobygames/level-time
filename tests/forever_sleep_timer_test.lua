-- Schlafsack-Timer (WoW Forever, Roadmap 430): /schlafen (Emote "SLEEP") mit Schlafsack in der Tasche oder Benutzen
-- des Schlafsacks startet 180 s Countdown; jeder neue Stapel "Gut erholt" kommt als Hinweis und steht im Titel;
-- nach 180 s "Fertig ausgeruht"; Bewegen, Kampf, Aufstehen oder Springen brechen ab; ohne Schlafsack kein Start.
local L = addon.L
local SleepTimer = addon.SleepTimer
local BAG, WELL_RESTED, BAG_SPELL = 211527, 429959, 436000

local played = {}
function PlaySound(id) table.insert(played, id) end

wow.state.itemIcons[BAG] = 133650
wow.state.itemCounts = { [BAG] = 1 }
wow.state.itemSpells = { [BAG] = { name = "Gemütlicher Schlafsack", id = BAG_SPELL } }
wow.login({ level = 20 })
expectTrue("Forever: verfügbar", SleepTimer.IsAvailable())
expect("Standard an", addon.db.sleepTimer, true)
expect("Hinweis je Stapel standardmäßig an", addon.db.sleepStackNotice, true)
expect("Ton standardmäßig aus", addon.db.sleepTimerSound, false)
expect("Zauber des Items", SleepTimer.ItemSpellId(), BAG_SPELL)
local card = LevelTimerSleep

local function wellRested(stacks)
  wow.state.buffs = { { name = "Gut erholt", spellId = WELL_RESTED, duration = 7200,
    expirationTime = GetTime() + 7200, applications = stacks } }
end
-- seconds vergehen; Prüfung (ns.Every) und Anzeige laufen einmal
local function wait(seconds)
  wow.advance(seconds)
  wow.update(seconds)
end
local function stackNotices()
  local count = 0
  for _, line in ipairs(wow.printed) do
    if line:find(string.format(L.SLEEP_STACK, 1):gsub("1$", ""), 1, true) then count = count + 1 end
  end
  return count
end
local function sleep() C_ChatInfo.PerformEmote("SLEEP") end

expect("zunächst versteckt", card:IsShown(), false)

---------------------------------------------------------------------------
-- Start per /schlafen, Stapel 1 -> 2 -> 3, fertig nach 180 s
---------------------------------------------------------------------------
wow.state.buffs = {}
sleep()
expect("Emote kommt beim Client an", wow.emotes[#wow.emotes], "SLEEP")
expect("Timer läuft", SleepTimer.State() and SleepTimer.State().signal, "emote")
expect("Karte sichtbar", card:IsShown(), true)
expect("Titel", card.title:GetText(), L.SLEEP_TITLE)
expect("Restzeit 180 s", card.time:GetText(), string.format(L.SECONDS_SHORT, 180))

wait(30)
expect("nach 30 s noch 150 s", card.time:GetText(), string.format(L.SECONDS_SHORT, 150))
expect("noch kein Hinweis", stackNotices(), 0)

addon.Alerts.Clear()
wellRested(0)  -- Buff ohne Stapelzahl zählt als 1
wait(1)
expect("Stapel 1 gemeldet", stackNotices(), 1)
expectTrue("Chatzeile ×1", wow.printed[#wow.printed]:find(string.format(L.SLEEP_STACK, 1), 1, true) ~= nil)
expect("Titel mit Stapel", card.title:GetText(), string.format(L.SLEEP_TITLE_STACKS, 1))
expect("Hinweiskarte", LevelTimerNotice.title:GetText(), string.format(L.SLEEP_STACK, 1))

addon.Set("sleepTimerSound", true)
wellRested(2)
wait(30)
expect("Stapel 2 gemeldet", stackNotices(), 2)
expect("Ton bei Stapel", #played, 1)
wait(1)
expect("gleicher Stapel: kein neuer Hinweis", stackNotices(), 2)
wellRested(3)
wait(30)
expect("Stapel 3 gemeldet", stackNotices(), 3)
expect("Titel mit 3 Stapeln", card.title:GetText(), string.format(L.SLEEP_TITLE_STACKS, 3))

wait(90)
expect("nach 182 s fertig", card.title:GetText(), L.SLEEP_DONE)
expect("Ton am Ende", #played, 3)
wait(2)
expect("Bewegen nach dem Ende bricht nichts mehr ab", (function()
  wow.fire("PLAYER_STARTED_MOVING")
  return card.title:GetText()
end)(), L.SLEEP_DONE)
wait(5)
expect("Fertig-Karte verschwindet", card:IsShown(), false)
expect("Timer vorbei", SleepTimer.State(), nil)
addon.Set("sleepTimerSound", false)

---------------------------------------------------------------------------
-- Start per Benutzen des Schlafsacks; Abbruch durch Bewegen
---------------------------------------------------------------------------
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", 12345)
expect("anderer Zauber startet nichts", SleepTimer.State(), nil)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", BAG_SPELL)
expect("Item startet den Timer", SleepTimer.State() and SleepTimer.State().signal, "item")
wait(10)
wow.fire("PLAYER_STARTED_MOVING")
expect("Bewegen bricht ab", SleepTimer.State(), nil)
expect("Abbruch angezeigt", card.title:GetText(), L.SLEEP_CANCELLED)
wait(5)
expect("Abbruch-Karte verschwindet", card:IsShown(), false)

-- Abbruch durch Kampf
sleep()
expectTrue("läuft wieder", SleepTimer.State() ~= nil)
wow.state.inCombat = true
wow.fire("PLAYER_REGEN_DISABLED")
expect("Kampf bricht ab", SleepTimer.State(), nil)
expect("Abbruch im Kampf angezeigt", card.title:GetText(), L.SLEEP_CANCELLED)
sleep()
expect("im Kampf kein Start", SleepTimer.State(), nil)
wow.state.inCombat = false

-- Aufstehen per Taste oder /aufstehen, Springen
sleep()
SitStandOrDescendStart()
expect("Sitz-/Aufsteh-Taste bricht ab", SleepTimer.State(), nil)
sleep()
C_ChatInfo.PerformEmote("STAND")
expect("/aufstehen bricht ab", SleepTimer.State(), nil)
sleep()
JumpOrAscendStart()
expect("Springen bricht ab", SleepTimer.State(), nil)

-- Andere Emotes starten nichts; doppeltes /schlafen startet nicht neu
C_ChatInfo.PerformEmote("DANCE")
expect("/tanzen startet nichts", SleepTimer.State(), nil)
sleep()
local startedAt = SleepTimer.State().startedAt
wait(5)
sleep()
expect("zweites /schlafen läuft weiter", SleepTimer.State().startedAt, startedAt)
SleepTimer.Cancel("test")
wait(5)

---------------------------------------------------------------------------
-- Ohne Schlafsack in der Tasche: /schlafen ist nur ein Emote
---------------------------------------------------------------------------
wow.state.itemCounts[BAG] = 0
sleep()
expect("ohne Schlafsack kein Start", SleepTimer.State(), nil)
expect("ohne Schlafsack keine Karte", card:IsShown(), false)
wow.state.itemCounts[BAG] = 1

-- Ausgeschaltet: kein Start, laufender Timer verschwindet
sleep()
addon.Set("sleepTimer", false)
expect("ausgeschaltet: Timer weg", SleepTimer.State(), nil)
expect("ausgeschaltet: Karte weg", card:IsShown(), false)
sleep()
expect("ausgeschaltet: kein Start", SleepTimer.State(), nil)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-3", BAG_SPELL)
expect("ausgeschaltet: Item startet nichts", SleepTimer.State(), nil)
addon.Set("sleepTimer", true)

-- Stapel-Hinweis abschaltbar
addon.Set("sleepStackNotice", false)
wow.state.buffs = {}
sleep()
wellRested(1)
wait(1)
expect("ohne Stapel-Hinweis keine Chatzeile", stackNotices(), 3)
expect("Titel zeigt den Stapel trotzdem", card.title:GetText(), string.format(L.SLEEP_TITLE_STACKS, 1))
SleepTimer.Cancel("test")
addon.Set("sleepStackNotice", true)

-- Vorschau und Edit-Modus
wait(5)
addon.SleepDisplay.Preview()
expect("Vorschau: Countdown", card.title:GetText(), L.SLEEP_TITLE)
addon.SleepDisplay.Preview()
expect("Vorschau: fertig", card.title:GetText(), L.SLEEP_DONE)
addon.SleepDisplay.Preview()
expect("Vorschau: abgebrochen", card.title:GetText(), L.SLEEP_CANCELLED)
expectTrue("im Edit-Modus registriert", addon.Frames.Get("sleep") ~= nil)

-- Einstellungen: Timer-Seite, durchsuchbar
expectTrue("Einstellung durchsuchbar", #addon.OptionsWindow.Search(L.SLEEP_TIMER_TOGGLE) > 0)
expect("keine Lua-Fehler", #wow.errors, 0)

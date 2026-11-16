-- Schlafsack-Timer (WoW Forever, Roadmap 430): Benutzen des Schlafsacks rollt ihn nur aus (Hinweis, kein Countdown,
-- Laufen bricht nichts ab); /schlafen (Emote "SLEEP") mit Schlafsack in der Tasche oder nach dem Ausrollen startet den
-- Countdown: 180 s unter 3 Stapeln "Gut erholt", bei 3 Stapeln 60 s bis zur Auffrischung. Fertig bei Stapel 3, bei
-- erkannter Auffrischung mit 3 Stapeln oder wenn die Zeit um ist; Bewegen, Kampf, Aufstehen oder Springen brechen ab;
-- ohne Schlafsack kein Start. Fremde Emotes ("READ") landen nicht im Debug-Log.
wow.loadExtractor()  -- Debug-Log und Profiler liegen im lokalen Data Extractor
local L = addon.L
local SleepTimer = addon.SleepTimer
local BAG, WELL_RESTED, BAG_SPELL = 211527, 429959, 429961

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

-- "Gut erholt" mit stacks Stapeln, läuft in remaining Sekunden ab (Standard volle 2 Stunden)
local function wellRested(stacks, remaining)
  wow.state.buffs = { { name = "Gut erholt", spellId = WELL_RESTED, duration = 7200,
    expirationTime = GetTime() + (remaining or 7200), applications = stacks } }
end
-- seconds vergehen; Prüfung (ns.Every) und Anzeige laufen einmal
local function wait(seconds)
  wow.advance(seconds)
  wow.update(seconds)
end
local function countPrinted(text)
  local count = 0
  for _, line in ipairs(wow.printed) do
    if line:find(text, 1, true) then count = count + 1 end
  end
  return count
end
local STACK_PREFIX = L.SLEEP_STACK:match("^(.-)%%d")
local function stackNotices() return countPrinted(STACK_PREFIX) end
local function stacksTitle(stacks) return string.format(L.SLEEP_TITLE_STACKS, stacks, SleepTimer.MAX_STACKS) end
local function sleep() C_ChatInfo.PerformEmote("SLEEP") end
local function seconds(value) return addon.Format.Duration(value) end

expect("zunächst versteckt", card:IsShown(), false)

---------------------------------------------------------------------------
-- Benutzen des Schlafsacks rollt ihn nur aus: Hinweis, kein Countdown, Laufen bricht nichts ab
---------------------------------------------------------------------------
wow.state.buffs = {}
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", 12345)
expect("anderer Zauber: nichts ausgerollt", SleepTimer.RolledOut(), false)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", BAG_SPELL)
expect("Item startet keinen Countdown", SleepTimer.State(), nil)
expect("Item: ausgerollt", SleepTimer.RolledOut(), true)
expect("Hinweis ausgerollt", card.title:GetText(), L.SLEEP_ROLLED_OUT)
wow.state.moving = true
wow.fire("PLAYER_STARTED_MOVING")
wait(14)
expect("Laufen zum Sack bricht nichts ab", card.title:GetText() ~= L.SLEEP_CANCELLED, true)
expect("noch ausgerollt", SleepTimer.RolledOut(), true)
wow.state.moving = false

---------------------------------------------------------------------------
-- /schlafen nach dem Ausrollen (Sack nicht mehr in der Tasche); Stapel 1 -> 2 -> 3, fertig bei Stapel 3
---------------------------------------------------------------------------
wow.state.itemCounts[BAG] = 0
sleep()
expect("Emote kommt beim Client an", wow.emotes[#wow.emotes], "SLEEP")
expect("Timer läuft nach dem Ausrollen", SleepTimer.State() and SleepTimer.State().signal, "emote")
expect("unter 3 Stapeln 180 s", SleepTimer.State().duration, SleepTimer.DURATION)
expect("Karte sichtbar", card:IsShown(), true)
expect("Titel", card.title:GetText(), L.SLEEP_TITLE)
expect("Restzeit 180 s", card.time:GetText(), seconds(180))

wait(30)
expect("nach 30 s noch 150 s", card.time:GetText(), seconds(150))
expect("noch kein Hinweis", stackNotices(), 0)

addon.Alerts.Clear()
wellRested(0)  -- Buff ohne Stapelzahl zählt als 1
wait(1)
expect("Stapel 1 gemeldet", stackNotices(), 1)
expectTrue("Chatzeile ×1/3", wow.printed[#wow.printed]:find(string.format(L.SLEEP_STACK, 1, 3), 1, true) ~= nil)
expect("Titel mit Stapel", card.title:GetText(), stacksTitle(1))
expect("Hinweiskarte", LevelTimerNotice.title:GetText(), string.format(L.SLEEP_STACK, 1, 3))

addon.Set("sleepTimerSound", true)
wellRested(2)
wait(30)
expect("Stapel 2 gemeldet", stackNotices(), 2)
expect("Ton bei Stapel", #played, 1)
wait(1)
expect("gleicher Stapel: kein neuer Hinweis", stackNotices(), 2)
wellRested(3)
wait(1)
expect("Stapel 3 gemeldet", stackNotices(), 3)
expect("bei Stapel 3 sofort fertig", card.title:GetText(), L.SLEEP_DONE)
expect("ein Ton für Stapel 3 und Ende", #played, 2)
wait(1)
wow.fire("PLAYER_STARTED_MOVING")
expect("Bewegen nach dem Ende bricht nichts mehr ab", card.title:GetText(), L.SLEEP_DONE)
wait(5)
expect("Fertig-Karte verschwindet", card:IsShown(), false)
expect("Timer vorbei", SleepTimer.State(), nil)
addon.Set("sleepTimerSound", false)
wow.state.itemCounts[BAG] = 1

---------------------------------------------------------------------------
-- Schon 3 Stapel: 60 s bis zur Auffrischung; erkannte Auffrischung beendet sofort
---------------------------------------------------------------------------
wellRested(3, 3000)
sleep()
expect("bei 3 Stapeln 60 s", SleepTimer.State().duration, SleepTimer.REFRESH_SECONDS)
expect("Restzeit 60 s", card.time:GetText(), seconds(60))
expect("Titel ×3/3", card.title:GetText(), stacksTitle(3))
wait(30)
expect("nach 30 s noch 30 s", card.time:GetText(), seconds(30))
expect("noch nicht aufgefrischt", countPrinted(L.SLEEP_REFRESHED), 0)
wait(29)
wellRested(3)  -- Ablauf springt auf volle 2 Stunden, Stapel bleiben
wait(0.5)
expect("Auffrischung gemeldet", countPrinted(L.SLEEP_REFRESHED), 1)
expect("Auffrischung: fertig", card.title:GetText(), L.SLEEP_DONE)
expect("Stapel unverändert: kein Stapel-Hinweis", stackNotices(), 3)
wait(6)
expect("danach vorbei", SleepTimer.State(), nil)

-- 3 Stapel, Auffrischung nicht erkennbar (Buff schon voll): fertig nach 60 s
wellRested(3)
sleep()
wait(59)
expect("nach 59 s noch nicht fertig", card.title:GetText(), stacksTitle(3))
wait(2)
expect("nach 61 s fertig", card.title:GetText(), L.SLEEP_DONE)
wait(6)

-- Unter 3 Stapeln ohne neuen Stapel: fertig nach 180 s
wellRested(1)
sleep()
wait(179)
expect("nach 179 s noch nicht fertig", card.title:GetText(), stacksTitle(1))
wait(2)
expect("nach 181 s fertig", card.title:GetText(), L.SLEEP_DONE)
wait(6)
expect("180-s-Lauf vorbei", SleepTimer.State(), nil)

---------------------------------------------------------------------------
-- Abbrüche
---------------------------------------------------------------------------
sleep()
wait(10)
wow.fire("PLAYER_STARTED_MOVING")
expect("Bewegen bricht ab", SleepTimer.State(), nil)
expect("Abbruch angezeigt", card.title:GetText(), L.SLEEP_CANCELLED)
wait(5)
expect("Abbruch-Karte verschwindet", card:IsShown(), false)

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
-- Ohne Schlafsack in der Tasche und lange nach dem Ausrollen: /schlafen ist nur ein Emote
---------------------------------------------------------------------------
wait(SleepTimer.ROLLED_OUT_SECONDS)
wow.state.itemCounts[BAG] = 0
sleep()
expect("ohne Schlafsack kein Start", SleepTimer.State(), nil)
expect("ohne Schlafsack keine Karte", card:IsShown(), false)
wow.state.itemCounts[BAG] = 1

---------------------------------------------------------------------------
-- Debug-Log: nur SLEEP/STAND und Emotes rund ums Liegen
---------------------------------------------------------------------------
SlashCmdList.LEVELTIMER("debug")  -- Chat-Logging an
C_ChatInfo.PerformEmote("READ")
expect("READ nicht geloggt", countPrinted("emote READ"), 0)
sleep()
expect("SLEEP geloggt", countPrinted("emote SLEEP"), 1)
C_ChatInfo.PerformEmote("READ")
expect("READ während des Liegens geloggt", countPrinted("emote READ"), 1)
SleepTimer.Cancel("test")
wait(10)
C_ChatInfo.PerformEmote("READ")
expect("READ danach wieder still", countPrinted("emote READ"), 1)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-3", BAG_SPELL)
C_ChatInfo.PerformEmote("READ")
expect("READ kurz nach dem Ausrollen geloggt", countPrinted("emote READ"), 2)
wait(SleepTimer.PROBE_SECONDS + 1)
C_ChatInfo.PerformEmote("READ")
expect("READ 16 s nach dem Ausrollen still", countPrinted("emote READ"), 2)
SlashCmdList.LEVELTIMER("debug")  -- und wieder aus
wait(5)

-- Ausgeschaltet: kein Start, laufender Timer verschwindet
sleep()
addon.Set("sleepTimer", false)
expect("ausgeschaltet: Timer weg", SleepTimer.State(), nil)
expect("ausgeschaltet: Karte weg", card:IsShown(), false)
sleep()
expect("ausgeschaltet: kein Start", SleepTimer.State(), nil)
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-4", BAG_SPELL)
expect("ausgeschaltet: Item zeigt nichts", card:IsShown(), false)
addon.Set("sleepTimer", true)

-- Hinweise abschaltbar
addon.Set("sleepStackNotice", false)
wow.state.buffs = {}
wow.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-5", BAG_SPELL)
expect("ohne Hinweise keine Ausrollen-Karte", card:IsShown(), false)
local notices = stackNotices()
sleep()
wellRested(1)
wait(1)
expect("ohne Stapel-Hinweis keine Chatzeile", stackNotices(), notices)
expect("Titel zeigt den Stapel trotzdem", card.title:GetText(), stacksTitle(1))
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

-- Schlafsack-Timer (nur WoW Forever, Roadmap 430): wer sich nach dem Ausrollen des "Gemütlichen Schlafsacks"
-- (Item 211527) mit /schlafen hinlegt, sieht eine Karte (UI/SleepDisplay.lua), die herunterzählt: so lange liegen
-- bleiben. "Gut erholt" (Spell 429959) stapelt bis MAX_STACKS; jeder neue Stapel steht im Titel ("×N/3") und kommt
-- als kurzer Hinweis (sleepStackNotice). Ablauf laut Debug-Log des Spielers (WoW Forever):
--   Item benutzen  rollt den Schlafsack nur aus ("Sack ausrollen"), der Spieler läuft danach hin. Das startet keinen
--                  Countdown (Bewegen bricht nichts ab), nur einen kurzen Hinweis "ausgerollt" (sleepStackNotice).
--   /schlafen      startet den Countdown: DURATION Sekunden, bei schon MAX_STACKS Stapeln nur REFRESH_SECONDS, denn
--                  dann frischt das Liegen den Buff nach etwa 60 s auf volle 2 Stunden auf (Stapel bleiben gleich,
--                  expirationTime springt nach oben).
--   Ende           "Fertig ausgeruht", sobald MAX_STACKS erreicht sind, die Auffrischung bei MAX_STACKS erkannt wurde
--                  oder die Zeit um ist. Bewegen, Springen, Aufstehen, Kampf oder Tod brechen ab.
-- Startsignale (geprüft im Blizzard-Code, Gethe/wow-ui-source Branch forever):
--   C_ChatInfo.PerformEmote(token, ...)  /schlafen ruft im Chat-Eingabefeld PerformEmote mit dem Token "SLEEP" auf
--                                        (ChatFrameEditBox.lua, EMOTE88_TOKEN), das Emote-Menü ebenso. DoEmote ist dort
--                                        nur eine Deprecation-Hülle um PerformEmote, daher nur ohne PerformEmote gehookt.
--   UNIT_SPELLCAST_SUCCEEDED (player)    der Zauber des Items laut C_Item.GetItemSpell (Ausrollen, im Spiel 429961)
-- Mit dem Emote startet der Timer nur, wenn der Schlafsack in der Tasche ist oder vor kurzem ausgerollt wurde. Stapel
-- und Ablauf kommen aus aura.applications/expirationTime (Felder wie in BuffFrame.lua); ein Buff ohne Stapel (0)
-- zählt als 1. Prüfung 430.sleep.state, Proben in DebugChecks.lua.
-- Einstellungen: sleepTimer, sleepTimerSound (Ton bei jedem Stapel, bei der Auffrischung und am Ende),
-- sleepStackNotice (Hinweise zu Stapeln, Auffrischung und Ausrollen).
local _, ns = ...
local Auras = ns.Auras
local BuffReminder = ns.BuffReminder

local SleepTimer = {}
ns.SleepTimer = SleepTimer

SleepTimer.DURATION = 180            -- Sekunden liegen bleiben unter MAX_STACKS (Wunsch des Spielers)
SleepTimer.MAX_STACKS = 3            -- "Gut erholt" stapelt bis 3 (vom Spieler bestätigt)
SleepTimer.REFRESH_SECONDS = 60      -- bei MAX_STACKS frischt das Liegen den Buff nach so vielen Sekunden auf
SleepTimer.REFRESH_JUMP = 30         -- um so viele Sekunden muss der Ablauf ohne Stapeländerung springen (Auffrischung)
SleepTimer.ROLLED_OUT_SECONDS = 300  -- so lange nach dem Ausrollen startet /schlafen auch ohne Schlafsack in der
                                     -- Tasche (wie lange der ausgerollte Sack liegt, ist nicht geprüft)
SleepTimer.ITEM_ID = BuffReminder.SLEEPING_BAG_ITEM_ID
SleepTimer.WELL_RESTED_SPELL_ID = BuffReminder.WELL_RESTED_SPELL_ID
SleepTimer.SLEEP_EMOTE = "SLEEP"     -- EMOTE88_TOKEN
SleepTimer.PROBE_SECONDS = 15        -- so lange nach einem Startsignal schreiben die Debug-Proben Zauber und Auren mit
local STAND_EMOTE = "STAND"
local CHECK_INTERVAL = 0.5
local STACK_GRACE = 5                -- Sekunden nach dem Ende, in denen ein letzter Stapel noch gemeldet wird

function SleepTimer.IsAvailable()
  return ns.Client.IsForever()
end

function SleepTimer.OwnsBag()
  local count = BuffReminder.SleepingBagCount()
  return count ~= nil and count > 0
end

-- Spell-ID des Schlafsacks (Benutzen), nil solange der Client das Item nicht kennt
function SleepTimer.ItemSpellId()
  if not C_Item or not C_Item.GetItemSpell then return nil end
  local ok, _, spellId = pcall(C_Item.GetItemSpell, SleepTimer.ITEM_ID)
  if not ok or ns.IsSecret(spellId) or type(spellId) ~= "number" then return nil end
  return spellId
end

-- "Gut erholt": Stapel (0 = kein Buff, nil = nicht lesbar) und Ablauf (expirationTime, nil = unbekannt)
local function readWellRested()
  local aura = Auras.FindBySpellId(SleepTimer.WELL_RESTED_SPELL_ID)
  if aura == nil then return nil end
  if not aura then return 0 end
  local count = aura.applications
  if ns.IsSecret(count) or type(count) ~= "number" then return nil end
  local expiration = aura.expirationTime
  if ns.IsSecret(expiration) or type(expiration) ~= "number" or expiration <= 0 then expiration = nil end
  return math.max(count, 1), expiration
end

function SleepTimer.Stacks()
  return (readWellRested())
end

local RESTING, FINISHED = "resting", "finished"
local running        -- { phase, startedAt, signal, stacks, expiration, duration, finishedAt } bis Ende der Nachfrist
local lastSignalAt   -- GetTime() des letzten Startsignals (auch ignorierter), für die Debug-Proben
local rolledOutAt    -- GetTime() des letzten Ausrollens per Item
local runEvents = ns.NewEventGroup()    -- Abbruch-Signale, nur solange der Spieler liegt
local startEvents = ns.NewEventGroup()  -- Benutzen des Items, solange die Einstellung an ist

function SleepTimer.State()
  return running
end

-- Schlafsack vor höchstens seconds Sekunden ausgerollt?
local function rolledOutWithin(seconds)
  return rolledOutAt ~= nil and GetTime() - rolledOutAt <= seconds
end

function SleepTimer.RolledOut()
  return rolledOutWithin(SleepTimer.ROLLED_OUT_SECONDS)
end

-- true, solange die Debug-Proben mitschreiben sollen (Timer läuft oder Startsignal vor kurzem)
function SleepTimer.Probing()
  return running ~= nil or (lastSignalAt ~= nil and GetTime() - lastSignalAt <= SleepTimer.PROBE_SECONDS)
end

local function titleFor(stacks)
  if stacks and stacks > 0 then return string.format(ns.L.SLEEP_TITLE_STACKS, stacks, SleepTimer.MAX_STACKS) end
  return ns.L.SLEEP_TITLE
end

local COUNTDOWN = { kind = "countdown", spellId = SleepTimer.WELL_RESTED_SPELL_ID }

local function showCountdown()
  COUNTDOWN.duration = running.duration
  COUNTDOWN.remaining = math.max(0, running.duration - (GetTime() - running.startedAt))
  COUNTDOWN.title = titleFor(running.stacks)  -- gleicher Titel = nur Restzeit nachführen (TimerDisplay.Show)
  ns.SleepDisplay.Show(COUNTDOWN)
end

local function setRunning(state)
  running = state
  runEvents.SetActive(state ~= nil and state.phase == RESTING)
  ns.RefreshTasks()
end

-- Hinweis (Karte und Chatzeile, sleepStackNotice) samt Ton; ohne Ton, wenn gleich "fertig" mit eigenem Ton folgt
local function announce(text, withSound)
  if ns.db.sleepStackNotice then
    ns.Alerts.Notify({ text = text, icon = SleepTimer.WELL_RESTED_SPELL_ID }, ns.Theme.COLORS.success)
  end
  if withSound and ns.db.sleepTimerSound then ns.Alerts.PlaySound() end
end

-- Ende des Liegens: "done" (fertig), "off" (Einstellung aus, ohne Anzeige) oder ein Abbruchgrund
local function finish(reason)
  if not running or running.phase ~= RESTING then return end
  ns.Debug("sleep", "ended: %s after %s s, well rested stacks %s (started by %s)", reason,
    math.floor(GetTime() - running.startedAt), running.stacks, running.signal)
  if reason == "done" then
    running.phase = FINISHED
    running.finishedAt = GetTime()
    setRunning(running)
    ns.SleepDisplay.ShowDone(ns.L.SLEEP_DONE)
    return
  end
  setRunning(nil)
  if reason == "off" then
    ns.SleepDisplay.Show(nil)
  else
    ns.SleepDisplay.ShowCancelled()
  end
end

-- Startsignal (das Emote); true, wenn der Timer jetzt läuft
function SleepTimer.Start(signal)
  lastSignalAt = GetTime()
  if not SleepTimer.IsAvailable() or not ns.db or not ns.db.sleepTimer then return false end
  if running and running.phase == RESTING then
    ns.Debug("sleep", "%s ignored: already resting", signal)
    return false
  end
  if not SleepTimer.OwnsBag() and not SleepTimer.RolledOut() then
    ns.Debug("sleep", "%s ignored: no sleeping bag in the bags", signal)
    return false
  end
  if UnitAffectingCombat("player") or UnitIsDeadOrGhost("player") or (IsPlayerMoving and IsPlayerMoving()) then
    ns.Debug("sleep", "%s ignored: in combat, dead or moving", signal)
    return false
  end
  local stacks, expiration = readWellRested()
  stacks = stacks or 0
  local duration = stacks >= SleepTimer.MAX_STACKS and SleepTimer.REFRESH_SECONDS or SleepTimer.DURATION
  ns.Debug("sleep", "started by %s, well rested stacks %s, countdown %s s", signal, stacks, duration)
  setRunning({ phase = RESTING, startedAt = GetTime(), signal = signal, stacks = stacks, expiration = expiration,
    duration = duration })
  showCountdown()
  return true
end

-- Schlafsack per Item ausgerollt: noch kein Countdown, der Spieler läuft erst hin
function SleepTimer.RollOut()
  if not SleepTimer.IsAvailable() or not ns.db or not ns.db.sleepTimer then return end
  rolledOutAt = GetTime()
  lastSignalAt = rolledOutAt
  ns.Debug("sleep", "sleeping bag rolled out, well rested stacks %s", SleepTimer.Stacks())
  if running and running.phase == RESTING then return end
  if ns.db.sleepStackNotice then ns.SleepDisplay.ShowHint(ns.L.SLEEP_ROLLED_OUT) end
end

function SleepTimer.Cancel(reason)
  finish(reason)
end

-- Neue Stapel und Auffrischung erkennen; true, wenn das Liegen damit fertig ist
local function trackWellRested()
  local stacks, expiration = readWellRested()
  if not stacks then return false end
  local previous, previousExpiration = running.stacks, running.expiration
  running.stacks, running.expiration = stacks, expiration
  local seconds = math.floor(GetTime() - running.startedAt)
  local atMax = stacks >= SleepTimer.MAX_STACKS
  if stacks ~= previous then
    ns.Debug("sleep", "well rested stacks %s -> %s after %s s", previous, stacks, seconds)
    if stacks < previous then return false end
    announce(string.format(ns.L.SLEEP_STACK, stacks, SleepTimer.MAX_STACKS), not atMax)
    return atMax
  end
  if stacks > 0 and expiration and previousExpiration
    and expiration - previousExpiration > SleepTimer.REFRESH_JUMP then
    ns.Debug("sleep", "well rested refreshed after %s s (stacks %s, expiration +%s s)", seconds, stacks,
      math.floor(expiration - previousExpiration))
    announce(ns.L.SLEEP_REFRESHED, not atMax)
    return atMax
  end
  return false
end

function SleepTimer.Check()
  if not running then return end
  local complete = trackWellRested()
  if running.phase == FINISHED then
    if GetTime() - running.finishedAt >= STACK_GRACE then setRunning(nil) end
    return
  end
  if complete or GetTime() - running.startedAt >= running.duration then
    finish("done")
    return
  end
  showCountdown()
end

ns.Every(CHECK_INTERVAL, SleepTimer.Check, function() return running ~= nil end)

---------------------------------------------------------------------------
-- Signale
---------------------------------------------------------------------------
-- Andere Addons und Makros rufen ständig Emotes auf (z.B. "READ"): nur die eigenen und solche rund ums Liegen loggen
local function logsEmote(token)
  return token == SleepTimer.SLEEP_EMOTE or token == STAND_EMOTE or running ~= nil
    or rolledOutWithin(SleepTimer.PROBE_SECONDS)
end

local function onEmote(token)
  if not ns.db or not ns.db.sleepTimer or type(token) ~= "string" or ns.IsSecret(token) then return end
  if ns.DebugActive() and logsEmote(token) then
    ns.Debug("sleep", "emote %s (sleeping bag in bags %s)", token, SleepTimer.OwnsBag())
  end
  if token == SleepTimer.SLEEP_EMOTE then
    SleepTimer.Start("emote")
  elseif token == STAND_EMOTE then
    finish("stand")
  end
end

local function onSpellCast(_, _, spellId)
  if ns.IsSecret(spellId) or spellId == nil then return end
  local itemSpell = SleepTimer.ItemSpellId()
  if itemSpell and spellId == itemSpell then SleepTimer.RollOut() end
end

local function hookIfPresent(owner, name, hook)
  if type(owner) == "table" and type(owner[name]) == "function" then hooksecurefunc(owner, name, hook) end
end

if SleepTimer.IsAvailable() then
  if C_ChatInfo and C_ChatInfo.PerformEmote then
    hooksecurefunc(C_ChatInfo, "PerformEmote", onEmote)
  else
    hookIfPresent(_G, "DoEmote", onEmote)
  end
  -- Aufstehen ohne Bewegung: Sitz-/Springen-Tasten (JumpOrAscendStart ist in den Forever-Docs nicht gelistet,
  -- daher nur, wenn vorhanden)
  hookIfPresent(_G, "SitStandOrDescendStart", function() finish("stand") end)
  hookIfPresent(_G, "ToggleSit", function() finish("stand") end)
  hookIfPresent(_G, "JumpOrAscendStart", function() finish("jump") end)

  startEvents.Add("UNIT_SPELLCAST_SUCCEEDED", "player", onSpellCast)
  runEvents.Add("PLAYER_STARTED_MOVING", nil, function() finish("moving") end)
  runEvents.Add("PLAYER_REGEN_DISABLED", nil, function() finish("combat") end)
  runEvents.Add("PLAYER_DEAD", nil, function() finish("dead") end)
end

local function reset()
  setRunning(nil)
  lastSignalAt = nil
  rolledOutAt = nil
end

ns.OnLogin(reset)
ns.OnLogout(reset)

ns.RegisterApply(function(db)
  startEvents.SetActive(SleepTimer.IsAvailable() and db.sleepTimer)
  if not db.sleepTimer and running then
    finish("off")
    setRunning(nil)
    ns.SleepDisplay.Show(nil)
  end
end)

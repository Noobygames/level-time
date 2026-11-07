-- Schlafsack-Timer (nur WoW Forever, Roadmap 430): wer sich mit dem "Gemütlichen Schlafsack" (Item 211527) schlafen
-- legt, sieht eine Karte (UI/SleepDisplay.lua), die DURATION Sekunden herunterzählt: so lange liegen bleiben. Jeder
-- neue Stapel von "Gut erholt" (Spell 429959) steht im Titel und kommt als kurzer Hinweis (sleepStackNotice), danach
-- "Fertig ausgeruht". Bewegen, Springen, Aufstehen, Kampf oder Tod brechen ab ("Ausruhen abgebrochen").
-- Startsignale (geprüft im Blizzard-Code, Gethe/wow-ui-source Branch forever):
--   C_ChatInfo.PerformEmote(token, ...)  /schlafen ruft im Chat-Eingabefeld PerformEmote mit dem Token "SLEEP" auf
--                                        (ChatFrameEditBox.lua, EMOTE88_TOKEN), das Emote-Menü ebenso. DoEmote ist dort
--                                        nur eine Deprecation-Hülle um PerformEmote, daher nur ohne PerformEmote gehookt.
--   UNIT_SPELLCAST_SUCCEEDED (player)    der Zauber des Items laut C_Item.GetItemSpell (Benutzen des Schlafsacks)
-- Mit dem Emote startet der Timer nur, wenn der Schlafsack in der Tasche ist. Stapel kommen aus aura.applications
-- (Feld wie in BuffFrame.lua); ein Buff ohne Stapel (0) zählt als 1. Ob "Gut erholt" im Spiel wirklich stapelt und
-- welche Aura das Schlafen selbst hat, schreibt das Debug-Log mit (Prüfung 430.sleep.state, Proben in DebugChecks.lua).
-- Einstellungen: sleepTimer, sleepTimerSound (Ton bei jedem Stapel und am Ende), sleepStackNotice.
local _, ns = ...
local Auras = ns.Auras
local BuffReminder = ns.BuffReminder

local SleepTimer = {}
ns.SleepTimer = SleepTimer

SleepTimer.DURATION = 180         -- Sekunden liegen bleiben (Wunsch des Spielers)
SleepTimer.ITEM_ID = BuffReminder.SLEEPING_BAG_ITEM_ID
SleepTimer.WELL_RESTED_SPELL_ID = BuffReminder.WELL_RESTED_SPELL_ID
SleepTimer.SLEEP_EMOTE = "SLEEP"  -- EMOTE88_TOKEN
SleepTimer.PROBE_SECONDS = 15     -- so lange nach einem Startsignal schreiben die Debug-Proben Zauber und Auren mit
local STAND_EMOTE = "STAND"
local CHECK_INTERVAL = 0.5
local STACK_GRACE = 5             -- Sekunden nach dem Ende, in denen ein letzter Stapel noch gemeldet wird

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

-- Stapel von "Gut erholt": 0 = kein Buff, nil = nicht lesbar
function SleepTimer.Stacks()
  local aura = Auras.FindBySpellId(SleepTimer.WELL_RESTED_SPELL_ID)
  if aura == nil then return nil end
  if not aura then return 0 end
  local count = aura.applications
  if ns.IsSecret(count) or type(count) ~= "number" then return nil end
  return math.max(count, 1)
end

local RESTING, FINISHED = "resting", "finished"
local running        -- { phase, startedAt, signal, stacks } von Start bis zum Ende der Nachfrist
local lastSignalAt   -- GetTime() des letzten Startsignals (auch ignorierter), für die Debug-Proben
local runEvents = ns.NewEventGroup()    -- Abbruch-Signale, nur solange der Spieler liegt
local startEvents = ns.NewEventGroup()  -- Benutzen des Items, solange die Einstellung an ist

function SleepTimer.State()
  return running
end

-- true, solange die Debug-Proben mitschreiben sollen (Timer läuft oder Startsignal vor kurzem)
function SleepTimer.Probing()
  return running ~= nil or (lastSignalAt ~= nil and GetTime() - lastSignalAt <= SleepTimer.PROBE_SECONDS)
end

local function titleFor(stacks)
  if stacks and stacks > 0 then return string.format(ns.L.SLEEP_TITLE_STACKS, stacks) end
  return ns.L.SLEEP_TITLE
end

local COUNTDOWN = { kind = "countdown", spellId = SleepTimer.WELL_RESTED_SPELL_ID, duration = SleepTimer.DURATION }

local function showCountdown()
  COUNTDOWN.remaining = math.max(0, SleepTimer.DURATION - (GetTime() - running.startedAt))
  COUNTDOWN.title = titleFor(running.stacks)  -- gleicher Titel = nur Restzeit nachführen (TimerDisplay.Show)
  ns.SleepDisplay.Show(COUNTDOWN)
end

local function setRunning(state)
  running = state
  runEvents.SetActive(state ~= nil and state.phase == RESTING)
  ns.RefreshTasks()
end

local function announceStack(stacks)
  if ns.db.sleepStackNotice then
    ns.Alerts.Notify({ text = string.format(ns.L.SLEEP_STACK, stacks), icon = SleepTimer.WELL_RESTED_SPELL_ID },
      ns.Theme.COLORS.success)
  end
  if ns.db.sleepTimerSound then ns.Alerts.PlaySound() end
end

-- Ende des Liegens: "done" (Zeit um), "off" (Einstellung aus, ohne Anzeige) oder ein Abbruchgrund
local function finish(reason)
  if not running or running.phase ~= RESTING then return end
  ns.Debug("sleep", "ended: %s after %s s, well rested stacks %s (started by %s)", reason,
    math.floor(GetTime() - running.startedAt), running.stacks, running.signal)
  if reason == "done" then
    running.phase = FINISHED
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

-- Startsignal ("emote" oder "item"); true, wenn der Timer jetzt läuft
function SleepTimer.Start(signal)
  lastSignalAt = GetTime()
  if not SleepTimer.IsAvailable() or not ns.db or not ns.db.sleepTimer then return false end
  if running and running.phase == RESTING then
    ns.Debug("sleep", "%s ignored: already resting", signal)
    return false
  end
  if signal ~= "item" and not SleepTimer.OwnsBag() then
    ns.Debug("sleep", "%s ignored: no sleeping bag in the bags", signal)
    return false
  end
  if UnitAffectingCombat("player") or UnitIsDeadOrGhost("player") or (IsPlayerMoving and IsPlayerMoving()) then
    ns.Debug("sleep", "%s ignored: in combat, dead or moving", signal)
    return false
  end
  local stacks = SleepTimer.Stacks()
  ns.Debug("sleep", "started by %s, well rested stacks %s", signal, stacks)
  setRunning({ phase = RESTING, startedAt = GetTime(), signal = signal, stacks = stacks or 0 })
  showCountdown()
  return true
end

function SleepTimer.Cancel(reason)
  finish(reason)
end

function SleepTimer.Check()
  if not running then return end
  local stacks = SleepTimer.Stacks()
  if stacks and stacks ~= running.stacks then
    ns.Debug("sleep", "well rested stacks %s -> %s after %s s", running.stacks, stacks,
      math.floor(GetTime() - running.startedAt))
    local rose = stacks > running.stacks
    running.stacks = stacks
    if rose then announceStack(stacks) end
  end
  local elapsed = GetTime() - running.startedAt
  if running.phase == FINISHED then
    if elapsed >= SleepTimer.DURATION + STACK_GRACE then setRunning(nil) end
    return
  end
  if elapsed >= SleepTimer.DURATION then
    finish("done")
    return
  end
  showCountdown()
end

ns.Every(CHECK_INTERVAL, SleepTimer.Check, function() return running ~= nil end)

---------------------------------------------------------------------------
-- Signale
---------------------------------------------------------------------------
local function onEmote(token)
  if not ns.db or not ns.db.sleepTimer or type(token) ~= "string" or ns.IsSecret(token) then return end
  if ns.DebugActive() then ns.Debug("sleep", "emote %s (sleeping bag in bags %s)", token, SleepTimer.OwnsBag()) end
  if token == SleepTimer.SLEEP_EMOTE then
    SleepTimer.Start("emote")
  elseif token == STAND_EMOTE then
    finish("stand")
  end
end

local function onSpellCast(_, _, spellId)
  if ns.IsSecret(spellId) or spellId == nil then return end
  local itemSpell = SleepTimer.ItemSpellId()
  if itemSpell and spellId == itemSpell then SleepTimer.Start("item") end
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

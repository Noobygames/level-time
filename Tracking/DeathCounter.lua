-- Zählt eigene Tode, die Zeit tot bzw. als Geist und schreibt jeden Tod mit Ursache ins Journal.
-- Ursache = letzter Treffer vor dem Tod aus dem Kampflog. Wo der Client das Kampflog
-- nicht an Addons gibt (Retail, WoW Forever), kommt sie aus dem Death Recap (DeathRecap.lua).
-- Totstellen (Jäger) löst PLAYER_DEAD nicht aus.
local _, ns = ...
local Stats = ns.Stats
local Journal = ns.Journal
local DeathRecap = ns.DeathRecap

local DeathCounter = {}
ns.DeathCounter = DeathCounter

local LAST_HIT_MAX_AGE = 10  -- Sekunden; ältere Treffer gelten nicht mehr als Todesursache
local RECAP_RETRY_DELAY = 1  -- Sekunden; der Recap kann beim Tod noch fehlen

local deadSince   -- GetTime() beim Tod, nil solange lebendig
local lastHit     -- { killer, spell, environment, at } des letzten Schadens am Spieler
local playerGUID  -- einmal beim Login gemerkt; das Kampflog feuert sehr oft

-- Inklusive der laufenden Zeit, falls man gerade tot ist
function DeathCounter.GetDeadSeconds(scope)
  local running = (deadSince and Stats.IsCounting(scope)) and (GetTime() - deadSince) or 0
  return Stats.Get(scope, Stats.DEAD_SECONDS) + running
end

-- Gespielte Zeit seit dem letzten Tod (Hardcore-Anzeige), über alle Level und Sessions.
-- Grundlage: /played beim Tod (character.lastDeathPlayed). Noch nie gestorben = gesamte Spielzeit.
-- nil, solange /played nicht geantwortet hat oder der letzte Tod vor dieser Funktion lag.
function DeathCounter.GetSecondsSinceDeath()
  local total = ns.PlayedTime.GetTotalSeconds()
  if not total then return nil end
  local lastDeath = ns.character.lastDeathPlayed
  if lastDeath then return math.max(0, total - lastDeath) end
  if #ns.character.deathLog > 0 then return nil end
  return total
end

-- Kills pro Tod, nil solange man im Bereich nicht gestorben ist
function DeathCounter.GetKillsPerDeath(scope)
  local deaths = Stats.Get(scope, Stats.DEATHS)
  if deaths == 0 then return nil end
  return Stats.GetTotalKills(scope) / deaths
end

---------------------------------------------------------------------------
-- Letzter Treffer: Schadens-Events aus dem Kampflog, deren Ziel der Spieler ist
---------------------------------------------------------------------------
local SPELL_DAMAGE_EVENTS = {
  RANGE_DAMAGE = true,
  SPELL_DAMAGE = true,
  SPELL_PERIODIC_DAMAGE = true,
}

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

-- Feldreihenfolge von CombatLogGetCurrentEventInfo: 2 = Event, 5 = Verursacher, 8 = Ziel-GUID,
-- ab 12 je nach Event (Zauber: 12 = ID, 13 = Name; Umgebung: 12 = Art)
-- C_CombatLog.GetCurrentEventInfo in allen Clients; das globale CombatLogGetCurrentEventInfo gibt es nur
-- als Kompatibilitäts-Alias (Blizzard_DeprecatedCombatLog, nur mit CVar loadDeprecationFallbacks)
local getCombatLogEventInfo = (C_CombatLog and C_CombatLog.GetCurrentEventInfo) or CombatLogGetCurrentEventInfo

-- Ein Treffer-Speicher, wiederverwendet: das Kampflog feuert im Raid oder Schlachtfeld hunderte Male pro Sekunde,
-- davon trifft nur ein kleiner Teil den Spieler. PeekLastHit gibt eine Kopie heraus.
local hitMemory = {}

local function rememberHit(killer, spell, environment)
  hitMemory.killer, hitMemory.spell, hitMemory.environment, hitMemory.at = killer, spell, environment, GetTime()
  lastHit = hitMemory
end

local isSecret = issecretvalue  -- nil in Clients ohne geheime Werte (Classic Era, TBC)

-- Läuft für jedes Kampflog-Event, daher zuerst der billigste Abbruch (Ziel ist nicht der Spieler). Eigener Frame
-- ohne ns.SafeCall je Event: der pcall um den Abruf fängt Client-Fehler ab, der Rest kann nicht scheitern.
local function onCombatLogEvent()
  local ok, _, subevent, _, _, sourceName, _, _, destGUID, _, _, _, extra1, extra2 =
    pcall(getCombatLogEventInfo)
  if not ok or (isSecret and isSecret(destGUID)) or destGUID ~= playerGUID or not playerGUID then return end

  if subevent == "ENVIRONMENTAL_DAMAGE" then
    rememberHit(nil, nil, readable(extra1))
  elseif subevent == "SWING_DAMAGE" then
    rememberHit(readable(sourceName), nil, nil)
  elseif SPELL_DAMAGE_EVENTS[subevent] then
    rememberHit(readable(sourceName), readable(extra2), nil)
  end
end

if getCombatLogEventInfo then
  local combatLogFrame = CreateFrame("Frame")
  if pcall(combatLogFrame.RegisterEvent, combatLogFrame, "COMBAT_LOG_EVENT_UNFILTERED") then
    ns.SetEventScript(combatLogFrame, "COMBAT_LOG_EVENT_UNFILTERED DeathCounter", onCombatLogEvent)
  end
end

-- Letzter Treffer, falls frisch genug: { killer, spell, environment } (Felder können fehlen)
function DeathCounter.PeekLastHit()
  if lastHit and GetTime() - lastHit.at <= LAST_HIT_MAX_AGE then
    return { killer = lastHit.killer, spell = lastHit.spell, environment = lastHit.environment }
  end
  return {}
end

local function takeDeathCause()
  local cause = DeathCounter.PeekLastHit()
  lastHit = nil
  return cause
end

local function isKnown(cause)
  return cause.killer ~= nil or cause.spell ~= nil or cause.environment ~= nil
end

-- Ohne Kampflog-Ursache den Death Recap fragen, einmal verzögert, falls er noch nicht bereit ist
local function fillCauseFromRecap(entry)
  local cause = DeathRecap.GetLastCause()
  if cause then
    ns.Debug("death", "cause from death recap: %s / %s / %s", cause.killer, cause.spell, cause.environment)
    Journal.SetDeathCause(entry, cause)
    return
  end
  ns.Debug("death", "death recap not ready, retry in %s s", RECAP_RETRY_DELAY)
  C_Timer.After(RECAP_RETRY_DELAY, function()
    local delayed = DeathRecap.GetLastCause()
    ns.Debug("death", "death recap retry: %s", delayed and delayed.killer or "no cause")
    if delayed and not isKnown(entry) then
      Journal.SetDeathCause(entry, delayed)
    end
  end)
end

---------------------------------------------------------------------------
-- Tod und Wiederbelebung
---------------------------------------------------------------------------
local function finishDeadTime()
  if not deadSince then return end
  Stats.Increment(Stats.DEAD_SECONDS, GetTime() - deadSince)
  deadSince = nil
end

ns.RegisterEvent("PLAYER_DEAD", function()
  if deadSince then return end  -- schon tot (z.B. Login als Geist), nicht doppelt zählen
  Stats.Increment(Stats.DEATHS)
  -- Vor der ersten /played-Antwort ist der Wert nil: den alten nicht damit überschreiben
  ns.character.lastDeathPlayed = ns.PlayedTime.GetTotalSeconds() or ns.character.lastDeathPlayed
  local cause = takeDeathCause()
  ns.Debug("death", "died, combat log cause: %s / %s / %s", cause.killer, cause.spell, cause.environment)
  local entry = Journal.AddDeath(cause)
  if not isKnown(cause) and DeathRecap.IsAvailable() then
    fillCauseFromRecap(entry)
  end
  deadSince = GetTime()
end)

-- PLAYER_ALIVE kommt auch beim Freilassen des Geistes, daher prüfen, ob man wirklich lebt
local function onPossiblyAlive()
  if not UnitIsDeadOrGhost("player") then
    finishDeadTime()
  end
end

ns.RegisterEvent("PLAYER_ALIVE", onPossiblyAlive)
ns.RegisterEvent("PLAYER_UNGHOST", onPossiblyAlive)

-- Spieler-GUID merken. Als Geist eingeloggt: Zeit seit Login weiterzählen (Offline-Zeit zählt nicht)
ns.OnLogin(function()
  playerGUID = UnitGUID("player")
  if UnitIsDeadOrGhost("player") then
    deadSince = GetTime()
  end
end)

-- Laufende Zeit vor dem Speichern verbuchen; nach dem Login zählt sie neu weiter
ns.OnLogout(finishDeadTime)

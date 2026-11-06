-- Beinahe-Tode: Das Leben fällt unter LOW_HEALTH, man stirbt aber nicht. Gezählt wird, sobald das Leben
-- wieder über RECOVERED_HEALTH steigt (Abstand verhindert Mehrfachzählung bei schwankendem Leben).
-- Stirbt man vorher, ist es ein Tod und kein Beinahe-Tod.
local _, ns = ...
local Stats = ns.Stats
local Journal = ns.Journal
local DeathCounter = ns.DeathCounter

local LOW_HEALTH = 0.10
local RECOVERED_HEALTH = 0.30
local RESURRECT_GRACE = 15  -- Sekunden nach einer Wiederbelebung (Geistheiler, Seelenstein: wenig Leben)

local episode  -- { lowest, cause } solange das Leben kritisch ist
local resurrectedAt  -- GetTime() der letzten Wiederbelebung

local NearDeath = {}
ns.NearDeath = NearDeath
NearDeath.LOW_HEALTH = LOW_HEALTH  -- Schwelle auch für den Notfall-Hinweis (Emergency.lua)

-- In Retail und WoW Forever liefert UnitHealth laut generierter Doku immer geheime Werte
-- (SecretReturns = true, ohne Bedingung); Beinahe-Tode lassen sich dort nicht erkennen, Zeile,
-- Schalter und Einblendung entfallen. Classic Era und TBC kennen das nicht.
function NearDeath.IsAvailable()
  return not (ns.Client.IsRetail() or ns.Client.IsForever())
end

-- Anteil des Lebens oder nil, wenn der Client den Wert verbirgt
function NearDeath.HealthFraction()
  local health, maxHealth = UnitHealth("player"), UnitHealthMax("player")
  if ns.IsSecret(health) or ns.IsSecret(maxHealth) or not maxHealth or maxHealth == 0 then return nil end
  return health / maxHealth
end

local function onHealthChanged(unit)
  if unit ~= "player" then return end
  if UnitIsDeadOrGhost("player") then
    episode = nil
    return
  end
  local fraction = NearDeath.HealthFraction()
  if not fraction then return end

  if not episode then
    local justResurrected = resurrectedAt and GetTime() - resurrectedAt < RESURRECT_GRACE
    if fraction <= LOW_HEALTH and not justResurrected then
      episode = { lowest = fraction, cause = DeathCounter.PeekLastHit() }
    end
    return
  end

  episode.lowest = math.min(episode.lowest, fraction)
  if fraction >= RECOVERED_HEALTH then
    Stats.Increment(Stats.NEAR_DEATHS)
    Journal.AddNearDeath(math.floor(episode.lowest * 100 + 0.5), episode.cause)
    episode = nil
  end
end

ns.RegisterEvent("UNIT_HEALTH", onHealthChanged)
ns.RegisterEvent("UNIT_HEALTH_FREQUENT", onHealthChanged)  -- ältere Clients melden Änderungen hierüber
ns.RegisterEvent("PLAYER_DEAD", function() episode = nil end)

-- Wiederbelebt mit wenig Leben ist kein Beinahe-Tod. PLAYER_ALIVE kommt auch beim Freilassen des Geistes.
local function onPossiblyResurrected()
  if not UnitIsDeadOrGhost("player") then resurrectedAt = GetTime() end
end
ns.RegisterEvent("PLAYER_ALIVE", onPossiblyResurrected)
ns.RegisterEvent("PLAYER_UNGHOST", onPossiblyResurrected)

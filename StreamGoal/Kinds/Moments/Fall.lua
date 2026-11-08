-- Moment "Tief fallen" (Bingo "Von einer Klippe fallen"): ein freier Fall von mindestens FALL_SECONDS (IsFalling, alle
-- Clients; bei rund 19 Metern pro Sekunde² Fallbeschleunigung etwa 20 Meter, ab etwa 1,2 Sekunden gibt es Fallschaden).
-- Ein Sprung dauert unter einer Sekunde und zählt nicht. Nicht auf Flugrouten (UnitOnTaxi) und nicht beim Gleiten
-- (Retail: C_PlayerInfo.GetGlidingInfo, wo vorhanden). Fallschaden selbst steht nur im Kampflog (in Retail und Forever
-- für Addons gesperrt), daher die Falldauer. Gezählt wird bei der Landung (auch wenn der Fall tödlich war).
local _, ns = ...
local LT = ns.LT
local Moments = ns.Moments

local Fall = {}
ns.FallMoment = Fall

Fall.FALL_SECONDS = 1.5
Fall.POLL_SECONDS = 0.1
local MODE = "fall"

local fallingSince  -- GetTime() seit Beginn des Falls, nil = am Boden

local function readable(value)
  if LT.IsSecret(value) then return nil end
  return value
end

local function gliding()
  local info = C_PlayerInfo and C_PlayerInfo.GetGlidingInfo
  return info ~= nil and readable((info())) == true
end

function Fall.Check()
  local falling = readable(IsFalling()) == true and readable(UnitOnTaxi("player")) ~= true and not gliding()
  local now = GetTime()
  if falling then
    fallingSince = fallingSince or now
    return
  end
  if fallingSince and now - fallingSince >= Fall.FALL_SECONDS then
    ns.Debug("moment", "fell %s s", now - fallingSince)
    Moments.Count(MODE, 1)
  end
  fallingSince = nil
end

Moments.Register(MODE, {
  label = "SG_MOMENT_FALL",
  title = "SG_GOAL_MOMENT_FALL",
  icon = "Interface\\Icons\\Spell_Magic_FeatherFall",
  available = function() return IsFalling ~= nil end,
  task = { seconds = Fall.POLL_SECONDS, fn = Fall.Check },
  onActive = function(isActive) if not isActive then fallingSince = nil end end,
})

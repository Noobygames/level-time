-- Moment "Schwimmen gehen": IsSwimming (alle Clients) mindestens SWIM_SECONDS am Stück; ein kurzer Sprung ins Wasser
-- oder durch eine Pfütze zählt nicht. Ein Bad zählt einmal, bis der Spieler wieder an Land ist.
local _, ns = ...
local LT = ns.LT
local Moments = ns.Moments

local Swim = {}
ns.SwimMoment = Swim

Swim.SWIM_SECONDS = 3
Swim.POLL_SECONDS = 1
local MODE = "swim"

local swimmingSince, counted

function Swim.Check()
  local swimming = IsSwimming()
  if LT.IsSecret(swimming) or not swimming then
    swimmingSince, counted = nil, false
    return
  end
  local now = GetTime()
  swimmingSince = swimmingSince or now
  if not counted and now - swimmingSince >= Swim.SWIM_SECONDS then
    counted = true
    Moments.Count(MODE, 1)
  end
end

Moments.Register(MODE, {
  label = "SG_MOMENT_SWIM",
  title = "SG_GOAL_MOMENT_SWIM",
  icon = "Interface\\Icons\\Spell_Frost_WindWalkOn",
  available = function() return IsSwimming ~= nil end,
  task = { seconds = Swim.POLL_SECONDS, fn = Swim.Check },
  onActive = function(isActive) if not isActive then swimmingSince, counted = nil, false end end,
})

-- Hardcore-Schutz (Roadmap 449, Einstellungen warnWildernessLogout und warnFalling, Standard aus):
-- Warnt beim Starten eines Logouts in der Wildnis (20s Countdown) und bei langem freiem Fall (>= 2.5s).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    warnWildernessLogout = false,
    warnFalling = false,
  },
})
local L = ns.L
local Alerts = ns.Alerts

local HardcoreSafeguard = {}
ns.HardcoreSafeguard = HardcoreSafeguard

local FALL_MIN_DURATION = 2.5
local FALL_REPEAT_INTERVAL = 10
local LOGOUT_REPEAT_INTERVAL = 5

local fallStart
local lastFallAlert = 0
local lastWildernessAlert = 0

local function isEligible()
  if UnitOnTaxi and UnitOnTaxi("player") then return false end
  if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return false end
  return true
end

function HardcoreSafeguard.WarnWildernessLogout()
  if not ns.db or not ns.db.warnWildernessLogout then return false end
  if IsResting and IsResting() then return false end
  if not isEligible() then return false end

  local now = GetTime()
  if now - lastWildernessAlert < LOGOUT_REPEAT_INTERVAL then return false end
  lastWildernessAlert = now

  ns.Debug("warnings", "wilderness logout warning")
  Alerts.Notify({
    title = L.WARN_WILDERNESS_LOGOUT_TITLE,
    text = L.WARN_WILDERNESS_LOGOUT_TEXT,
    icon = Alerts.ICONS.camp,
  }, Alerts.WARNING_COLOR)
  if Alerts.PlaySound then Alerts.PlaySound() end
  if FlashClientIcon then FlashClientIcon() end
  return true
end

function HardcoreSafeguard.CheckFalling()
  if not ns.db or not ns.db.warnFalling then
    fallStart = nil
    return
  end

  local isFalling = IsFalling and IsFalling()
  if not isFalling or not isEligible() then
    fallStart = nil
    return
  end

  local now = GetTime()
  fallStart = fallStart or now
  if now - fallStart >= FALL_MIN_DURATION and (now - lastFallAlert >= FALL_REPEAT_INTERVAL) then
    lastFallAlert = now
    ns.Debug("warnings", "falling warning (duration %s)", now - fallStart)
    Alerts.Notify({
      title = L.WARN_FALLING_TITLE,
      text = L.WARN_FALLING_TEXT,
      icon = Alerts.ICONS.nearDeath,
    }, Alerts.WARNING_COLOR)
    if Alerts.PlaySound then Alerts.PlaySound() end
    if FlashClientIcon then FlashClientIcon() end
  end
end

ns.Every(0.5, HardcoreSafeguard.CheckFalling, function()
  return ns.db and ns.db.warnFalling
end)

ns.RegisterEvent("PLAYER_CAMPING", function()
  HardcoreSafeguard.WarnWildernessLogout()
end)

if type(Logout) == "function" then
  hooksecurefunc("Logout", function()
    HardcoreSafeguard.WarnWildernessLogout()
  end)
end

ns.OnLogin(function()
  fallStart = nil
  lastFallAlert = 0
  lastWildernessAlert = 0
end)

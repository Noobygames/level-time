-- Aggro-Hinweis (Einstellung warnAggro, Standard aus): in einer Gruppe eine Einblendung, sobald ein Gegner den
-- Spieler wirklich angreift, z.B. für Heiler und Fernkämpfer. Allein und als zugewiesener Tank nicht.
-- Nicht über UnitThreatSituation("player") allein: das Debug-Log (WoW Forever 1.60.1) zeigte dort oft Stufe 3, obwohl
-- kein Gegner den Spieler als Ziel hatte. Gezählt wird deshalb nur ein Gegner unter Ziel, Fokus, Maus und
-- Namensplaketten, der im Kampf ist, den Spieler als Ziel hat (UnitIsUnit(<einheit>target, "player")) und laut
-- UnitDetailedThreatSituation von ihm "getankt" wird; ist das Ziel geheim, genügt "getankt" (siehe attacksPlayer).
-- Gewarnt wird erst, wenn das AGGRO_CONFIRM_SECONDS anhält (kurze Zielwechsel beim Pull), und höchstens alle
-- REPEAT_SECONDS. Geprüft wird alle CHECK_SECONDS, nur im Kampf in einer Gruppe.
local _, ns = ...
local L = ns.L

local AggroWarning = {}
ns.AggroWarning = AggroWarning

local CHECK_SECONDS = 0.5
local AGGRO_CONFIRM_SECONDS = 1.5
local REPEAT_SECONDS = 5
local TANK_ROLE = "TANK"
local NAMEPLATE_UNITS = 40
local FIXED_UNITS = { "target", "focus", "mouseover" }

local aggroSince   -- GetTime(), seit dem ein Gegner den Spieler angreift
local warned       -- für diese Aggro schon gewarnt
local lastShown

-- Wert nur, wenn er lesbar ist
local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

-- Greift diese Einheit den Spieler an? Feindlich, nicht außer Kampf, und: Spieler als Ziel (wenn lesbar) und laut
-- Bedrohung von ihm getankt. In Forever-Instanzen ist das Ziel des Gegners geheim (Debug-Log), "getankt"
-- (1. Wert von UnitDetailedThreatSituation) aber lesbar: dann entscheidet das allein.
local function attacksPlayer(unit)
  if not UnitExists(unit) or not UnitCanAttack("player", unit) or readable(UnitAffectingCombat(unit)) == false then
    return false
  end
  local targetsPlayer = readable(UnitIsUnit(unit .. "target", "player"))
  if targetsPlayer == false then return false end
  local tanking = UnitDetailedThreatSituation and readable((UnitDetailedThreatSituation("player", unit)))
  if targetsPlayer == true then return tanking ~= false end
  return tanking == true
end

-- true, wenn ein sichtbarer Gegner den Spieler angreift
function AggroWarning.HasAggro()
  for _, unit in ipairs(FIXED_UNITS) do
    if attacksPlayer(unit) then return true end
  end
  for index = 1, NAMEPLATE_UNITS do
    if attacksPlayer("nameplate" .. index) then return true end
  end
  return false
end

local function isTank()
  if not UnitGroupRolesAssigned then return false end
  local role = UnitGroupRolesAssigned("player")
  return not ns.IsSecret(role) and role == TANK_ROLE
end

local function active()
  return ns.db.warnAggro and IsInGroup() and not isTank() and UnitAffectingCombat("player")
end

function AggroWarning.Check()
  if not active() or not AggroWarning.HasAggro() then
    aggroSince, warned = nil, false
    return
  end
  local now = GetTime()
  aggroSince = aggroSince or now
  if warned or now - aggroSince < AGGRO_CONFIRM_SECONDS then return end
  if lastShown and now - lastShown < REPEAT_SECONDS then return end
  warned, lastShown = true, now
  ns.Debug("warnings", "aggro")
  ns.Alerts.Notify({ title = L.NOTICE_AGGRO, text = L.WARN_AGGRO, icon = ns.Alerts.ICONS.aggro },
    ns.Alerts.WARNING_COLOR)
end

ns.Every(CHECK_SECONDS, AggroWarning.Check)

ns.OnLogin(function()
  aggroSince, warned, lastShown = nil, false, nil
end)

-- Aggro-Hinweis (Einstellung warnAggro, Standard aus): in einer Gruppe eine Einblendung, sobald ein Gegner den
-- Spieler angreift (er "tankt"), z.B. für Heiler und Fernkämpfer, die Aggro gezogen haben. Allein, als
-- zugewiesener Tank und bei gesperrter Bedrohung nicht.
-- UnitThreatSituation("player") ohne zweites Argument = höchste Stufe gegenüber allen Gegnern:
-- 0/1 = keine Aggro, 2 = tankt unsicher, 3 = tankt sicher (warcraft.wiki.gg/wiki/API_UnitThreatSituation).
-- UNIT_THREAT_SITUATION_UPDATE kommt mit "player", wenn sich die Stufe ändert. Im Spiel geprüft (WoW Forever
-- 1.60.1): im Kampf lesbar, nicht geheim (C_Secrets.ShouldUnitThreatStateBeSecret false).
-- Gewarnt wird beim Wechsel zu Aggro, höchstens alle REPEAT_SECONDS (die Stufe springt beim Abgeben hin und her).
local _, ns = ...
local L = ns.L

local AggroWarning = {}
ns.AggroWarning = AggroWarning

local TANKING = 2          -- ab dieser Stufe greift ein Gegner den Spieler an
local REPEAT_SECONDS = 5
local TANK_ROLE = "TANK"

local hadAggro = false
local lastShown

-- true = ein Gegner greift den Spieler an; nil = nicht lesbar
function AggroWarning.HasAggro()
  local situation = UnitThreatSituation and UnitThreatSituation("player")
  if ns.IsSecret(situation) then return nil end
  return situation ~= nil and situation >= TANKING
end

local function isTank()
  if not UnitGroupRolesAssigned then return false end
  local role = UnitGroupRolesAssigned("player")
  return not ns.IsSecret(role) and role == TANK_ROLE
end

local function shouldWarn()
  return ns.db.warnAggro and IsInGroup() and not isTank()
    and (not lastShown or GetTime() - lastShown >= REPEAT_SECONDS)
end

function AggroWarning.Check()
  local aggro = AggroWarning.HasAggro()
  if aggro == nil then return end
  if aggro and not hadAggro and shouldWarn() then
    ns.Debug("warnings", "aggro")
    lastShown = GetTime()
    ns.Alerts.Notify({ title = L.NOTICE_AGGRO, text = L.WARN_AGGRO, icon = ns.Alerts.ICONS.aggro },
      ns.Alerts.WARNING_COLOR)
  end
  hadAggro = aggro
end

ns.RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", function(unit)
  if unit == "player" then AggroWarning.Check() end
end)
ns.RegisterEvent("PLAYER_REGEN_ENABLED", function() hadAggro = false end)

ns.OnLogin(function()
  hadAggro, lastShown = false, nil
end)

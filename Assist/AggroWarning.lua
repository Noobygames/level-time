-- Aggro-Hinweis (Einstellung warnAggro, Standard aus): in einer Gruppe eine Einblendung, sobald ein Gegner den
-- Spieler wirklich angreift, z.B. für Heiler und Fernkämpfer. Allein und als zugewiesener Tank nicht.
-- Nicht über UnitThreatSituation("player") allein: das Debug-Log (WoW Forever 1.60.1) zeigte dort oft Stufe 3, obwohl
-- kein Gegner den Spieler als Ziel hatte. Gezählt wird deshalb nur ein Gegner unter Ziel, Fokus, Maus und
-- Namensplaketten, der im Kampf ist, den Spieler als Ziel hat (UnitIsUnit(<einheit>target, "player")) und laut
-- UnitDetailedThreatSituation von ihm "getankt" wird; ist das Ziel geheim, genügt "getankt" (siehe attacksPlayer).
-- Gewarnt wird erst, wenn das AGGRO_CONFIRM_SECONDS anhält (kurze Zielwechsel beim Pull), und höchstens alle
-- REPEAT_SECONDS. Geprüft wird alle CHECK_SECONDS, nur im Kampf in einer Gruppe.
-- Heiler-Ansage (eigene Einstellung announceHealerAggro): mit der Rolle Heiler in Dungeon oder Schlachtzug geht nach
-- HEALER_ANNOUNCE_SECONDS Aggro "Heiler hat Aggro!" an die Gruppe, einmal je Aggro, höchstens alle
-- HEALER_REPEAT_SECONDS; nicht bei gesperrtem Chat (GroupChat.Locked).
local _, ns = ...
local L = ns.L

local AggroWarning = {}
ns.AggroWarning = AggroWarning

local CHECK_SECONDS = 0.5
local AGGRO_CONFIRM_SECONDS = 1.5
local REPEAT_SECONDS = 5
local HEALER_ANNOUNCE_SECONDS = 2
local HEALER_REPEAT_SECONDS = 10
local TANK_ROLE = "TANK"
local FIXED_UNITS = { "target", "focus", "mouseover" }
local TARGET_OF = ns.NamePlates.TARGET_OF  -- vorberechnet: kein unit .. "target" je Prüfung

local aggroSince   -- GetTime(), seit dem ein Gegner den Spieler angreift
local warned       -- für diese Aggro schon gewarnt
local lastShown
local announced    -- für diese Aggro schon an die Gruppe gemeldet
local lastAnnounced

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
  local targetsPlayer = readable(UnitIsUnit(TARGET_OF[unit] or unit .. "target", "player"))
  if targetsPlayer == false then return false end
  local tanking = UnitDetailedThreatSituation and readable((UnitDetailedThreatSituation("player", unit)))
  if targetsPlayer == true then return tanking ~= false end
  return tanking == true
end

-- true, wenn ein sichtbarer Gegner den Spieler angreift (Namensplaketten nur die gerade sichtbaren)
function AggroWarning.HasAggro()
  for _, unit in ipairs(FIXED_UNITS) do
    if attacksPlayer(unit) then return true end
  end
  for unit in pairs(ns.NamePlates.Active()) do
    if attacksPlayer(unit) then return true end
  end
  return false
end

local function isTank()
  if not UnitGroupRolesAssigned then return false end
  local role = UnitGroupRolesAssigned("player")
  return not ns.IsSecret(role) and role == TANK_ROLE
end

local function enabled(db)
  return db.warnAggro or db.announceHealerAggro
end

local function wanted()
  return enabled(ns.db) and IsInGroup() and not isTank() and UnitAffectingCombat("player")
end

-- Eigene Einblendung nach AGGRO_CONFIRM_SECONDS
local function warnSelf(now)
  if not ns.db.warnAggro or warned or now - aggroSince < AGGRO_CONFIRM_SECONDS then return end
  if lastShown and now - lastShown < REPEAT_SECONDS then return end
  warned, lastShown = true, now
  ns.Debug("warnings", "aggro")
  ns.Alerts.Notify({ title = L.NOTICE_AGGRO, text = L.WARN_AGGRO, icon = ns.Alerts.ICONS.aggro },
    ns.Alerts.WARNING_COLOR)
end

-- Heiler: nach HEALER_ANNOUNCE_SECONDS an die Gruppe
local function announceHealer(now)
  if not ns.db.announceHealerAggro or announced or now - aggroSince < HEALER_ANNOUNCE_SECONDS then return end
  if lastAnnounced and now - lastAnnounced < HEALER_REPEAT_SECONDS then return end
  if not ns.GroupRole.IsHealerInGroupInstance() or ns.GroupChat.Locked() then return end
  local chatType = ns.GroupChat.PartyChannel()
  if not chatType then return end
  announced, lastAnnounced = true, now
  ns.Debug("announce", "healer aggro")
  ns.GroupChat.Send(L.HEALER_AGGRO_ANNOUNCE, chatType)
end

function AggroWarning.Check()
  if not wanted() or not AggroWarning.HasAggro() then
    aggroSince, warned, announced = nil, false, false
    return
  end
  local now = GetTime()
  aggroSince = aggroSince or now
  warnSelf(now)
  announceHealer(now)
end

ns.Every(CHECK_SECONDS, AggroWarning.Check, enabled)

-- Ausgeschaltet läuft die Prüfung nicht; eine laufende Aggro gilt danach als vorbei (wie bei Check ohne wanted)
ns.RegisterApply(function(db)
  if not enabled(db) then aggroSince, warned, announced = nil, false, false end
end)

ns.OnLogin(function()
  aggroSince, warned, lastShown, announced, lastAnnounced = nil, false, nil, false, nil
end)

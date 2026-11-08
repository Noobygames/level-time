-- Moment "Anderen Spieler heilen oder wiederbeleben": ein hilfreicher Zauber (C_Spell.IsSpellHelpful, in allen vier
-- Clients dokumentiert) des Spielers auf einen anderen Spieler, der beim Wirken tot war (Wiederbelebung) oder Leben
-- verloren hatte (UnitHealth < UnitHealthMax: Heilung). Kein Kampflog nötig:
--   UNIT_SPELLCAST_SENT(player, Zielname, castGUID, spellID)  Ziel und Zustand beim Wirken; das Ziel wird über den
--                        Namen unter Ziel, Maus, Fokus und Gruppe gesucht
--   UNIT_SPELLCAST_SUCCEEDED(player, castGUID, spellID)      zählt den gemerkten Zauber, abgebrochene verfallen
-- Ein Buff auf einen verletzten Spieler zählt mit (der Client sagt nicht, ob ein Zauber heilt). Wo Retail oder Forever
-- Ziel oder Leben geheim halten (Instanzen, Kampf), zählt nichts.
local _, ns = ...
local LT = ns.LT
local Moments = ns.Moments

local Heal = {}
ns.HealMoment = Heal

Heal.PENDING_SECONDS = 15  -- so lange wartet ein gesendeter Zauber auf sein Gelingen (Wiederbeleben dauert bis 10 s)
local MODE = "heal"
local CANDIDATES = { "target", "mouseover", "focus" }
for index = 1, 4 do table.insert(CANDIDATES, "party" .. index) end
for index = 1, 40 do table.insert(CANDIDATES, "raid" .. index) end

local pending = {}  -- [castGUID] = { kind, at }

local function readable(value)
  if LT.IsSecret(value) then return nil end
  return value
end

local function matchesName(unit, wanted)
  local name, realm = UnitName(unit)
  name, realm = readable(name), readable(realm)
  if type(name) ~= "string" then return false end
  if name == wanted then return true end
  return type(realm) == "string" and realm ~= "" and name .. "-" .. realm == wanted
end

-- Anderer Spieler mit diesem Namen unter den bekannten Einheiten, sonst nil
function Heal.UnitByName(name)
  if type(name) ~= "string" or name == "" then return nil end
  for _, unit in ipairs(CANDIDATES) do
    if readable(UnitExists(unit)) == true and matchesName(unit, name) then
      if readable(UnitIsPlayer(unit)) ~= true or readable(UnitIsUnit(unit, "player")) ~= false then return nil end
      return unit
    end
  end
end

-- "res", "heal" oder nil: was der Zauber an dieser Einheit bewirken kann
function Heal.Classify(unit)
  if readable(UnitCanAssist("player", unit)) ~= true then return nil end
  if readable(UnitIsDeadOrGhost(unit)) == true then return "res" end
  local health, healthMax = readable(UnitHealth(unit)), readable(UnitHealthMax(unit))
  if type(health) == "number" and type(healthMax) == "number" and health < healthMax then return "heal" end
end

local function prune(now)
  for guid, entry in pairs(pending) do
    if now - entry.at > Heal.PENDING_SECONDS then pending[guid] = nil end
  end
end

local function onSent(_, targetName, castGUID, spellID)
  if LT.IsSecret(targetName) or LT.IsSecret(castGUID) or LT.IsSecret(spellID) or not castGUID then return end
  local helpful = readable(C_Spell.IsSpellHelpful(spellID))
  if not helpful then return end
  local unit = Heal.UnitByName(targetName)
  local kind = unit and Heal.Classify(unit)
  ns.Debug("moment", "helpful spell %s on %s (unit %s): %s", spellID, targetName, unit, kind)
  local now = GetTime()
  prune(now)
  if kind then pending[castGUID] = { kind = kind, at = now } end
end

local function onSucceeded(_, castGUID)
  if LT.IsSecret(castGUID) or not castGUID or not pending[castGUID] then return end
  ns.Debug("moment", "%s on another player done", pending[castGUID].kind)
  pending[castGUID] = nil
  Moments.Count(MODE, 1)
end

local events = LT.NewEventGroup()
events.Add("UNIT_SPELLCAST_SENT", "player", onSent)
events.Add("UNIT_SPELLCAST_SUCCEEDED", "player", onSucceeded)

Moments.Register(MODE, {
  label = "SG_MOMENT_HEAL",
  title = "SG_GOAL_MOMENT_HEAL",
  icon = "Interface\\Icons\\Spell_Holy_Heal",
  available = function() return C_Spell ~= nil and C_Spell.IsSpellHelpful ~= nil and UnitCanAssist ~= nil end,
  events = events,
  onActive = function(isActive) if not isActive then pending = {} end end,
})

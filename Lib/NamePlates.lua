-- Sichtbare Namensplaketten und vorberechnete Einheiten-Namen, damit regelmäßige Prüfungen (Aggro-Hinweis) nicht
-- je Lauf 40 Plätze abfragen und Strings wie "nameplate" .. i oder unit .. "target" bauen.
-- Die Menge kommt aus NAME_PLATE_UNIT_ADDED/REMOVED und wird bei PLAYER_ENTERING_WORLD (auch nach /reload) aus den
-- Plätzen neu aufgebaut. Kennt der Client die Events nicht, liefert Active() alle Plätze (wie früher).
local _, ns = ...

local NamePlates = {}
ns.NamePlates = NamePlates

NamePlates.MAX = 40
NamePlates.UNITS = {}       -- "nameplate1" .. "nameplate40"
NamePlates.TARGET_OF = {}   -- Einheit -> ihr Ziel ("target" -> "targettarget", "nameplate3" -> "nameplate3target")
for index = 1, NamePlates.MAX do
  NamePlates.UNITS[index] = "nameplate" .. index
end
for _, unit in ipairs({ "target", "focus", "mouseover", "player", "pet" }) do
  NamePlates.TARGET_OF[unit] = unit .. "target"
end
for _, unit in ipairs(NamePlates.UNITS) do
  NamePlates.TARGET_OF[unit] = unit .. "target"
end

local active = {}       -- [Einheit] = true
local allSlots = {}     -- Rückfall ohne Events: alle Plätze
for _, unit in ipairs(NamePlates.UNITS) do allSlots[unit] = true end
local tracking = false

-- Sichtbare Plaketten als Menge [Einheit] = true (nicht verändern)
function NamePlates.Active()
  return tracking and active or allSlots
end

local function rebuild()
  for unit in pairs(active) do active[unit] = nil end
  for _, unit in ipairs(NamePlates.UNITS) do
    local exists = UnitExists(unit)
    if not ns.IsSecret(exists) and exists then active[unit] = true end
  end
end

local added = ns.RegisterEvent("NAME_PLATE_UNIT_ADDED", function(unit)
  if unit and not ns.IsSecret(unit) then active[unit] = true end
end)
local removed = ns.RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(unit)
  if unit and not ns.IsSecret(unit) then active[unit] = nil end
end)
tracking = added and removed
ns.RegisterEvent("PLAYER_ENTERING_WORLD", rebuild)

-- Namensplaketten nur im Kampf (Reiter Komfort, System; combatPlates, Standard aus): gegnerische Plaketten (CVar
-- nameplateShowEnemies) beim Kampfbeginn an, nach dem Kampf aus. Die CVar ist im Kampf geschützt; laut
-- warcraft.wiki.gg (API InCombatLockdown) beginnt die Sperre erst nach PLAYER_REGEN_DISABLED und endet vor
-- PLAYER_REGEN_ENABLED, in beiden Handlern darf sie also geändert werden. Läuft gerade die Sperre (Einstellung im
-- Kampf geändert), wird es nach dem Kampf nachgeholt.
-- Ausschalten stellt den Wert des Spielers wieder her (CVars.lua). Classic Era und TBC speichern die CVar je
-- Charakter, Retail und WoW Forever je Account (Console variables, Retail- und Classic-Liste auf warcraft.wiki.gg).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    combatPlates = false,
  },
})

local CombatPlates = {}
ns.CombatPlates = CombatPlates

local CVAR = "nameplateShowEnemies"
local SHOWN, HIDDEN = 1, 0

local function scope()
  local Client = ns.Client
  if Client.IsClassicEra() or Client.IsBurningCrusade() then return ns.CVars.CHARACTER end
  return ns.CVars.ACCOUNT
end

local function isEnabled()
  return ns.db ~= nil and ns.db.combatPlates == true
end

local pending = false  -- im Kampf nicht möglich gewesen, nach dem Kampf nachholen

-- inCombat: Plaketten zeigen; nil = aktueller Kampfzustand
local function update(inCombat)
  if InCombatLockdown() then
    pending = true
    return
  end
  pending = false
  if isEnabled() then
    if inCombat == nil then inCombat = UnitAffectingCombat("player") == true end
    ns.CVars.Override(CVAR, inCombat and SHOWN or HIDDEN, scope())
  else
    ns.CVars.Restore(CVAR, scope())
  end
end

ns.RegisterApply(function() update() end)

ns.RegisterEvent("PLAYER_REGEN_DISABLED", function()
  if isEnabled() then update(true) end
end)

ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if isEnabled() or pending then update(false) end
end)

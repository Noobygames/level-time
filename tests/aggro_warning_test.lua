-- Aggro-Hinweis: nur eingeschaltet, in einer Gruppe, im Kampf, nicht als Tank; nur wenn ein Gegner den Spieler
-- wirklich als Ziel hat und das kurz anhält
local L = addon.L

local function shown()
  local count = 0
  for _, line in ipairs(wow.printed) do
    if line:find(L.WARN_AGGRO, 1, true) then count = count + 1 end
  end
  return count
end

local me = { name = "Nerzal" }

-- Gegner als Ziel; attacking = hat den Spieler als Ziel
local function enemy(attacking, tanking)
  wow.state.units.target = { name = "Hyäne", hostile = true, combat = true, tanking = tanking }
  wow.state.units.targettarget = attacking and me or { name = "Tank" }
end

local function tick(seconds)
  wow.advance(seconds)
  addon.AggroWarning.Check()
end

wow.login({ level = 20 })
wow.state.units.player = me
wow.state.inGroup, wow.state.inCombat = true, true

enemy(true, true)
tick(2)
expect("aus: still", shown(), 0)

addon.Set("warnAggro", true)
enemy(false, true)
tick(0.5)
tick(2)
expect("Gegner greift anderen an: still", shown(), 0)

enemy(true, true)
tick(0.5)
expect("noch nicht bestätigt", shown(), 0)
tick(1.5)
expect("Aggro bestätigt: Hinweis", shown(), 1)
expect("als Karte", LevelTimerNotice.body:GetText(), L.WARN_AGGRO)
tick(1)
expect("bleibt Aggro: kein zweiter", shown(), 1)

enemy(false, true)
tick(0.5)
enemy(true, true)
tick(0.5)
tick(1.5)
expect("kurz weg und zurück: Pause", shown(), 1)
enemy(false, true)
tick(6)
enemy(true, true)
tick(0.5)
tick(1.5)
expect("später wieder gezogen", shown(), 2)

enemy(true, false)
wow.state.units.targettarget = me
tick(0.5)
tick(6)
expect("Ziel ja, aber nicht getankt: still", shown(), 2)

enemy(true, wow.SECRET)
wow.state.units.targettarget = me
tick(6)
tick(2)
expect("Bedrohung geheim, Ziel lesbar: zählt", shown(), 3)

-- Forever-Instanz: Ziel des Gegners geheim, "getankt" entscheidet
enemy(false, true); tick(6)
wow.state.units.target.tanking = true
wow.state.units.targettarget = nil
local isUnit = UnitIsUnit
UnitIsUnit = function(a, b) if a == "targettarget" then return wow.SECRET end return isUnit(a, b) end
tick(0.5); tick(2)
expect("Ziel geheim, getankt: Hinweis", shown(), 4)
wow.state.units.target.tanking = false
tick(6); tick(2)
expect("Ziel geheim, nicht getankt: still", shown(), 4)
UnitIsUnit = isUnit

wow.state.role = "TANK"
enemy(false, true); tick(6); enemy(true, true); tick(0.5); tick(2)
expect("Tank: still", shown(), 4)
wow.state.role = nil

wow.state.inGroup = false
enemy(false, true); tick(6); enemy(true, true); tick(0.5); tick(2)
expect("allein: still", shown(), 4)
expect("keine Fehler", #wow.errors, 0)

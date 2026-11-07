-- Essen-Timer: während der Charakter isst, zeigt eine Karte (UI/FoodDisplay.lua) die Restzeit des Buffs "Essen"
-- ("so lange noch sitzen bleiben"), danach kurz "Satt aktiv". Einstellung foodTimer, Ton foodSound.
-- Spell-IDs (im Spiel per Aura-Liste ermittelt): 433 "Essen" (Food), 18 s, läuft nur beim Sitzen und Essen;
-- "Satt" (Well Fed) erkennt man wie in BuffReminder über den Namen des Zaubers 19705, weil die vielen Essens-Buffs
-- alle so heißen. Kommt "Satt" schon vor dem Ende des Essens, endet der Countdown sofort mit "Satt aktiv".
-- Getrunkenes ("Trinken") hat einen anderen Buff und zählt nicht. Bei gesperrten Auren passiert nichts.
local _, ns = ...
local Auras = ns.Auras

local FoodTimer = {}
ns.FoodTimer = FoodTimer

FoodTimer.EATING_SPELL_ID = 433
FoodTimer.WELL_FED_SPELL_ID = 19705
local CHECK_INTERVAL = 0.5
local GRANT_WINDOW = 3  -- Sekunden nach dem Ende des Essens, in denen "Satt" noch eintreffen darf

local function spellName(spellId)
  return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellId)
end

function FoodTimer.IsAvailable()
  return spellName(FoodTimer.EATING_SPELL_ID) ~= nil and spellName(FoodTimer.WELL_FED_SPELL_ID) ~= nil
end

-- Liest die Buffs: ok (false bei gesperrten Auren), Zustand des Essens (nil oder
-- { kind = "countdown", remaining, duration, spellId }) und der Buff "Satt" (oder nil)
local function readBuffs()
  local eatingName, wellFedName = spellName(FoodTimer.EATING_SPELL_ID), spellName(FoodTimer.WELL_FED_SPELL_ID)
  if not eatingName or not wellFedName then return false end
  local buffs = Auras.Snapshot()
  if not buffs then return false end
  local eating, wellFed = buffs.byName[eatingName], buffs.byName[wellFedName]
  local state
  if eating and not UnitIsDeadOrGhost("player") then
    local remaining, duration = Auras.RemainingSeconds(eating)
    if remaining then
      state = { kind = "countdown", remaining = remaining, duration = duration, spellId = eating.spellId }
    end
  end
  return true, state, wellFed
end

local function expirationOf(aura)
  local expiration = aura and aura.expirationTime
  if ns.IsSecret(expiration) or type(expiration) ~= "number" then return nil end
  return expiration
end

local NO_BUFF, UNKNOWN_EXPIRATION = false, "unknown"

-- Ausgangslage von "Satt": keins, Ablaufzeit oder unbekannt (kein "x and false or y": false wäre hier ein Wert)
local function baselineOf(wellFed)
  if not wellFed then return NO_BUFF end
  return expirationOf(wellFed) or UNKNOWN_EXPIRATION
end
local wasEating
local wellFedAtStart = NO_BUFF  -- "Satt" beim Start des Essens: keins, Ablaufzeit oder unbekannt
local endedAt                   -- GetTime(), seit nicht mehr gegessen wird, bis das Ergebnis feststeht
local mealDone = false          -- "Satt" ist für diese Mahlzeit schon gemeldet

-- Hat das Essen "Satt" gebracht? Neu oder erneuert (spätere Ablaufzeit)
local function wellFedGranted(wellFed)
  if not wellFed then return false end
  if wellFedAtStart == NO_BUFF then return true end
  if wellFedAtStart == UNKNOWN_EXPIRATION then return false end  -- nicht feststellbar: lieber keine Meldung
  local expiration = expirationOf(wellFed)
  return expiration ~= nil and expiration > wellFedAtStart + 1
end

-- Zustand einer Mahlzeit vergessen (Login, Einstellung aus): Einschalten wirkt wie ein frischer Login
local function reset()
  wasEating, wellFedAtStart, endedAt, mealDone = nil, NO_BUFF, nil, false
end

function FoodTimer.Check()
  if not ns.db or not ns.db.foodTimer then return end
  local ok, state, wellFed = readBuffs()
  if not ok then return end
  local eating = state ~= nil

  if eating and not wasEating then
    wellFedAtStart = baselineOf(wellFed)
    endedAt, mealDone = nil, false
  elseif not eating and wasEating then
    endedAt = GetTime()
  end
  wasEating = eating

  local finished = false
  if not mealDone and (eating or endedAt) and wellFedGranted(wellFed) then
    finished, mealDone, endedAt = true, true, nil
  elseif endedAt and GetTime() - endedAt > GRANT_WINDOW then
    endedAt = nil  -- aufgestanden, bevor es fertig war
  end

  if mealDone then state = nil end
  ns.FoodDisplay.Show(state)
  if finished then
    ns.Debug("food", "well fed granted")
    ns.FoodDisplay.ShowDone()
  end
end

ns.Every(CHECK_INTERVAL, FoodTimer.Check, function(db) return db.foodTimer end)

ns.OnLogin(reset)

-- Ausgeschaltet liest der Timer keine Buffs mehr; der Zustand beginnt beim Einschalten neu
ns.RegisterApply(function(db)
  if db.foodTimer then return end
  reset()
  ns.FoodDisplay.Show(nil)
end)

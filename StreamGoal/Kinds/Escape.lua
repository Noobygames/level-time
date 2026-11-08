-- Zielart Weglaufen (Roadmap 439): N-mal vor einem Gegner weglaufen. Ohne Kampflog (Retail und Forever sperren es für
-- Addons), nur mit lesbaren Werten, die alle vier Clients haben:
--   Angreifer   alle CHECK_SECONDS im Kampf (PLAYER_REGEN_DISABLED bis _ENABLED): Ziel, Fokus, Maus und sichtbare
--               Namensplaketten. Ein feindlicher NPC (UnitCanAttack, kein Spieler, nicht von Spielern gesteuert), der
--               lebt, im Kampf ist und den Spieler als Ziel hat (UnitIsUnit(<einheit>target, "player")), ist ein
--               Angreifer, gemerkt über seine GUID mit erstem und letztem Mal.
--   Mindestens  MIN_ATTACK_SECONDS Angriff (erstes bis letztes Mal): ein Körperzug oder ein einzelner Schlag zählt nicht.
--   Weglaufen   (a) Kampfende: PLAYER_REGEN_ENABLED, der Spieler lebt, und ein Angreifer mit Mindestdauer ist nicht
--               gestorben: nicht tot gesehen (UnitIsDead bei Sicht oder beim Entfernen seiner Plakette) und, wenn er
--               zuletzt nicht mehr zu sehen war, kein Kill-Eintrag mit seinem Namen und kein namenloser Kill (geheime
--               Meldung) während des Kampfs im Journal von Level Time.
--               (b) Aggro abgenommen: ein Angreifer lebt, ist im Kampf und hat seit CONFIRM_SECONDS ein anderes Ziel
--               (nicht der Spieler, nicht sein Begleiter), und kein sichtbarer Gegner greift den Spieler mehr an. Ohne
--               Ziel (Flucht bei wenig Leben, Kontrolle) zählt das nicht.
--   Nie         in Instanzen (IsInInstance nicht "none": Dungeon, Schlachtzug, Szenario, Schlachtfeld, Arena; auch nicht,
--               wenn der Kampf dort begann), nach dem Tod im Kampf und nach Totstellen, Verschwinden, Schattenhaftigkeit
--               oder Unsichtbarkeit (UnitIsFeignDeath, Zauber in COMBAT_DROP_SPELLS): das ist Abschütteln, kein
--               Weglaufen. Je Kampf zählt höchstens ein Weglaufen.
-- Grenzen: ein Gegner, der bei wenig Leben selbst flieht und außer Sicht stirbt, ist nicht zu unterscheiden; sieht man
-- ihn nicht mehr und meldet der Client Kills nur namenlos, zählt der Kampf nicht (lieber zu wenig als zu viel).
-- Entscheidungen stehen mit ihren Eingaben im Debug-Log (Bereich goal:escape), Prüfung 439.goals.escape.
-- params: keine
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Kinds = ns.Kinds

local Escape = {}
ns.EscapeGoals = Escape

Escape.CHECK_SECONDS = 0.5
Escape.MIN_ATTACK_SECONDS = 2
Escape.CONFIRM_SECONDS = 2
-- Zauber, die den Kampf ohne Weglaufen beenden (Spell-IDs Classic/TBC-Ränge und Retail; im Spiel zu prüfen, Debug-Check
-- 439.goals.escape): Verschwinden (Rang 1-3), Totstellen, Schattenhaftigkeit (Classic, Retail), Unsichtbarkeit
Escape.COMBAT_DROP_SPELLS = { [1856] = true, [1857] = true, [26889] = true, [5384] = true, [20580] = true,
  [58984] = true, [66] = true }
local ICON = "Interface\\Icons\\Ability_Rogue_Sprint"
local OUTDOORS = "none"
local FIXED_UNITS = { "target", "focus", "mouseover" }
local TARGET_OF = LT.NamePlates.TARGET_OF

local fight  -- laufender Kampf: { attackers = { [GUID] = Angreifer }, killed = { [Name] = true }, ... }

local function readable(value)
  if LT.IsSecret(value) then return nil end
  return value
end

local function outdoors()
  local _, instanceType = IsInInstance()
  return readable(instanceType) == OUTDOORS
end

local function playerDead()
  return readable(UnitIsDeadOrGhost("player")) == true
end

local function feigning()
  return UnitIsFeignDeath ~= nil and readable(UnitIsFeignDeath("player")) == true
end

Goals.RegisterKind("escape", {
  label = "SG_KIND_ESCAPE",
  group = "combat",
  usage = "SG_USAGE_ESCAPE",
  color = LT.Theme.COLORS.warning,
  icon = ICON,
  editable = { "amount" },
  form = { amount = "SG_FORM_AMOUNT" },
  parse = function(args) return {}, tonumber(args[1]) end,
  prepare = function(_, target) return target or Kinds.DEFAULT_AMOUNT end,
  validate = function(_, target) return Kinds.ValidAmount(target) end,
  title = function(goal) return Kinds.Counted("SG_GOAL_ESCAPE", goal.target) end,
  body = function() return ns.L.SG_ESCAPE_BODY end,
})

---------------------------------------------------------------------------
-- Einheiten lesen
---------------------------------------------------------------------------
-- Zustand einer Einheit aus Sicht des Spielers: "attacking" (greift ihn an), "dead", "other" (kämpft mit jemand
-- anderem), "idle" (außer Kampf: abgebrochen, zurückgelaufen), "unsure" (im Kampf ohne lesbares Ziel); nil = kein
-- feindlicher NPC oder nicht lesbar
function Escape.StateOf(unit)
  if readable(UnitExists(unit)) ~= true or readable(UnitIsPlayer(unit)) ~= false then return nil end
  if UnitPlayerControlled and readable(UnitPlayerControlled(unit)) ~= false then return nil end  -- Begleiter
  if readable(UnitCanAttack("player", unit)) ~= true then return nil end
  local dead = readable(UnitIsDead(unit))
  if dead == nil then return nil end
  if dead then return "dead" end
  local targetUnit = TARGET_OF[unit] or unit .. "target"
  local targetsPlayer = readable(UnitIsUnit(targetUnit, "player"))
  local inCombat = readable(UnitAffectingCombat(unit))
  if targetsPlayer and inCombat ~= false then return "attacking" end
  if inCombat == false then return "idle" end
  if inCombat and readable(UnitExists(targetUnit)) == true and targetsPlayer == false
    and readable(UnitIsUnit(targetUnit, "pet")) == false then
    return "other"
  end
  return "unsure"
end

local function attackedLongEnough(attacker)
  return attacker.last - attacker.since >= Escape.MIN_ATTACK_SECONDS
end

-- Eine Einheit ansehen und ihren Angreifer (falls bekannt oder neu) fortschreiben; Rückgabe: greift den Spieler an
local function observe(unit, now)
  local state = Escape.StateOf(unit)
  if not state then return false end
  local guid = readable(UnitGUID(unit))
  if type(guid) ~= "string" then return false end
  local attacker = fight.attackers[guid]
  if state == "attacking" then
    if not attacker then
      attacker = { since = now, name = readable(UnitName(unit)) }
      fight.attackers[guid] = attacker
    end
    attacker.last, attacker.otherSince = now, nil
  elseif attacker then
    attacker.dead = attacker.dead or state == "dead"
    if state == "other" then attacker.otherSince = attacker.otherSince or now else attacker.otherSince = nil end
  end
  if attacker and state ~= "dead" then attacker.seenIn = fight.scans end  -- in diesem Durchgang lebend gesehen
  return state == "attacking"
end

-- Alle sichtbaren Einheiten ansehen; Rückgabe: irgendeine greift den Spieler an
local function scan(now)
  fight.scans = fight.scans + 1
  local attacked = false
  for _, unit in ipairs(FIXED_UNITS) do
    if observe(unit, now) then attacked = true end
  end
  for unit in pairs(LT.NamePlates.Active()) do
    if observe(unit, now) then attacked = true end
  end
  return attacked
end

---------------------------------------------------------------------------
-- Entscheidung
---------------------------------------------------------------------------
local function count(how, attacker)
  fight.counted = true
  ns.Debug("escape", "escaped (%s) from %s after %s s", how, attacker.name, attacker.last - attacker.since)
  Goals.Add("escape", function() return true end, 1)
end

-- Darf dieser Kampf (noch) zählen? Grund als Text für das Debug-Log, nil = ja
local function blocker()
  if fight.counted then return "counted" end
  if fight.indoors or not outdoors() then return "instance" end
  if fight.died or playerDead() then return "death" end
  if fight.dropped or feigning() then return "combat drop" end
end

-- Ist der Angreifer am Kampfende sicher nicht gestorben? finalScan = Durchgang beim Kampfende (nil = keiner)
local function survived(attacker, finalScan)
  if attacker.dead then return false end
  if finalScan and attacker.seenIn == finalScan then return true end  -- beim Kampfende lebend gesehen
  return not (attacker.name and fight.killed[attacker.name]) and not fight.namelessKill
end

-- Aggro abgenommen: ein Angreifer mit Mindestdauer kämpft seit CONFIRM_SECONDS mit jemand anderem
local function checkAggroTaken(now)
  for _, attacker in pairs(fight.attackers) do
    if attacker.otherSince and now - attacker.otherSince >= Escape.CONFIRM_SECONDS and not attacker.dead
      and attackedLongEnough(attacker) then
      count("aggro taken", attacker)
      return
    end
  end
end

function Escape.Check()
  if not fight or fight.counted then return end
  if not outdoors() then
    fight.indoors = true
    return
  end
  local now = GetTime()
  if not scan(now) and not blocker() then checkAggroTaken(now) end
end

local function startFight()
  if not ns.db or not Goals.HasActive("escape") then return end
  fight = { attackers = {}, killed = {}, scans = 0, indoors = not outdoors() }
  Escape.Check()
end

local function endFight()
  if not fight then return end
  local now = GetTime()
  local finalScan
  if not fight.counted and outdoors() then
    scan(now)
    finalScan = fight.scans
  end
  local reason = blocker()
  for guid, attacker in pairs(fight.attackers) do
    local long, alive = attackedLongEnough(attacker), survived(attacker, finalScan)
    ns.Debug("escape", "combat end: %s (%s) attacked %s s, dead %s, seen alive %s, killed %s, nameless kill %s",
      attacker.name, guid, attacker.last - attacker.since, attacker.dead, finalScan ~= nil and attacker.seenIn == finalScan,
      attacker.name and fight.killed[attacker.name], fight.namelessKill)
    if not reason and long and alive then
      count("combat end", attacker)
      break
    end
  end
  if reason then ns.Debug("escape", "combat end not counted: %s", reason) end
  fight = nil
end

-- Plakette verschwindet: stirbt der Gegner, ist er hier noch als tot lesbar; sonst ist er nur außer Sicht
local function onPlateRemoved(unit)
  if not fight or not unit or LT.IsSecret(unit) then return end
  local guid = readable(UnitGUID(unit))
  local attacker = guid and fight.attackers[guid]
  if attacker and readable(UnitIsDead(unit)) == true then attacker.dead = true end
end

local function onKill(logName, entry)
  if not fight or logName ~= "killLog" or entry.kind ~= "pve" then return end
  if entry.name then fight.killed[entry.name] = true else fight.namelessKill = true end
end

local function onSpellCast(_, _, spellID)
  if fight and not LT.IsSecret(spellID) and Escape.COMBAT_DROP_SPELLS[spellID] then
    ns.Debug("escape", "combat drop spell %s", spellID)
    fight.dropped = true
  end
end

-- Zustand für den Debug-Check 439.goals.escape
function Escape.Snapshot()
  local units = {}
  for _, unit in ipairs(FIXED_UNITS) do
    units[unit] = Escape.StateOf(unit) or false
  end
  local attackers = 0
  for _ in pairs(fight and fight.attackers or {}) do attackers = attackers + 1 end
  return { fighting = fight ~= nil, attackers = attackers, outdoors = outdoors(), units = units,
    feignDeath = UnitIsFeignDeath ~= nil, playerControlled = UnitPlayerControlled ~= nil }
end

---------------------------------------------------------------------------
-- Ereignisse nur, solange ein Weglaufen-Ziel läuft
---------------------------------------------------------------------------
local events = LT.NewEventGroup()
events.Add("PLAYER_REGEN_DISABLED", nil, startFight)
events.Add("PLAYER_REGEN_ENABLED", nil, endFight)
events.Add("PLAYER_DEAD", nil, function() if fight then fight.died = true end end)
events.Add("NAME_PLATE_UNIT_REMOVED", nil, onPlateRemoved)
events.Add("UNIT_SPELLCAST_SUCCEEDED", "player", onSpellCast)
LT.Journal.OnAdd(onKill)

local function running()
  return ns.db ~= nil and Goals.HasActive("escape")
end

local function update()
  local active = running()
  events.SetActive(active)
  if not active then fight = nil end
  LT.RefreshTasks()
end

-- /reload mitten im Kampf: der Kampf beginnt mit der ersten Prüfung
LT.Every(Escape.CHECK_SECONDS, function()
  if not fight and running() and readable(UnitAffectingCombat("player")) then startFight() end
  Escape.Check()
end, running)
Goals.OnChange(update)
LT.OnLogin(function()
  fight = nil
  update()
end)

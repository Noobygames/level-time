-- Zuwachs beim Level-Up: Lebenspunkte, Mana und Werte (Stärke, Beweglichkeit, Ausdauer, Intelligenz) vorher -> nachher.
-- Quelle: die Zuwächse im Ereignis PLAYER_LEVEL_UP (Level, Leben, Kraft, Talente, PvP-Plätze, Stärke, Beweglichkeit,
-- Ausdauer, Intelligenz). Den neuen Gesamtwert liest der Client erst kurz danach, daher wartet die Meldung DELAY Sekunden;
-- der alte Wert ist neu minus Zuwachs (gleiche Ausrüstung vorausgesetzt). Buffs zählen nie: Werte ohne Buffs, Leben und
-- Mana nur ohne Buff auf Ausdauer bzw. Intelligenz, sonst steht dort nur der Zuwachs. Ohne Zuwächse im Ereignis (ältere
-- Clients) kommt die Meldung sofort ohne Zeilen.
--   LevelGains.OnReady(fn(level, gains))  gains = { rows = { { label, delta, from, to } }, talents } oder nil
--   LevelGains.Lines(gains)               fertige Textzeilen
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    levelUpGains = true,
  },
})
local L = ns.L

local LevelGains = { DELAY = 1 }
ns.LevelGains = LevelGains

local listeners = {}

function LevelGains.OnReady(listener)
  table.insert(listeners, listener)
end

local function notify(level, gains)
  for _, listener in ipairs(listeners) do ns.SafeCall(listener, level, gains) end
end

-- UnitStat(unit, index): Wert ohne Buffs, Wert mit Buffs, positive, negative Buffs; 1 = Stärke ... 4 = Intelligenz.
-- Angezeigt wird der Wert ohne Buffs (Ausrüstung zählt), Essen, Flaschen und Segen verfälschen ihn nicht.
local function stat(index)
  return function() return (UnitStat("player", index)) end
end

-- Wirkt gerade ein Buff oder Debuff auf den Wert? Leben hängt an der Ausdauer, Mana an der Intelligenz. Der Client nennt
-- keinen Wert ohne Buffs, daher zeigen Leben und Mana dann nur den Zuwachs.
local function statBuffed(index)
  return function()
    local _, _, positive, negative = UnitStat("player", index)
    return type(positive) ~= "number" or type(negative) ~= "number" or ns.IsSecret(positive) or ns.IsSecret(negative)
      or positive ~= 0 or negative ~= 0
  end
end

-- Reihenfolge der Zeilen; key = Name im Ereignis, current() liest den Wert jetzt, buffed() (optional) = Buffs verfälschen ihn
local ROWS = {
  { key = "health", label = "GAIN_HEALTH", current = function() return UnitHealthMax("player") end, buffed = statBuffed(3) },
  { key = "power", label = "GAIN_MANA", current = function() return UnitPowerMax and UnitPowerMax("player") end,
    buffed = statBuffed(4) },
  { key = "strength", label = "GAIN_STRENGTH", current = stat(1) },
  { key = "agility", label = "GAIN_AGILITY", current = stat(2) },
  { key = "stamina", label = "GAIN_STAMINA", current = stat(3) },
  { key = "intellect", label = "GAIN_INTELLECT", current = stat(4) },
}

-- Wert lesen; nil (nur der Zuwachs wird gezeigt), wenn Buffs ihn verfälschen oder Retail ihn im Kampf geheim hält
local function readCurrent(row)
  if row.buffed and row.buffed() then return nil end
  local value = row.current and row.current()
  if type(value) ~= "number" or ns.IsSecret(value) then return nil end
  return value
end

-- deltas = { health, power, strength, ... }; current(row) liefert den Gesamtwert. nil, wenn nichts zugelegt hat
local function buildGains(deltas, current)
  local rows = {}
  for _, row in ipairs(ROWS) do
    local delta = deltas[row.key]
    if type(delta) == "number" and delta > 0 then
      local to = current(row)
      table.insert(rows, { label = L[row.label], delta = delta, to = to, from = to and to - delta })
    end
  end
  local talents = deltas.talents
  if #rows == 0 and not (type(talents) == "number" and talents > 0) then return nil end
  return { rows = rows, talents = talents and talents > 0 and talents or nil }
end

-- Ganze Zahlen ohne "k": Leben und Werte sollen exakt lesbar sein
local function exact(value)
  return string.format("%d", math.floor(value + 0.5))
end

function LevelGains.Lines(gains)
  local lines = {}
  for _, row in ipairs(gains.rows) do
    if row.to then
      table.insert(lines, string.format("%s %s -> %s (+%s)",
        row.label, exact(row.from), exact(row.to), exact(row.delta)))
    else
      table.insert(lines, string.format("%s +%s", row.label, exact(row.delta)))
    end
  end
  if gains.talents then table.insert(lines, string.format(L.GAIN_TALENTS, gains.talents)) end
  return lines
end

-- Beispiel für die Fehlersuche (/lt debug levelup): übliche Zuwächse auf die aktuellen Werte
local SAMPLE_DELTAS = { health = 90, power = 40, strength = 2, agility = 1, stamina = 3, intellect = 2, talents = 1 }

function LevelGains.Sample()
  return buildGains(SAMPLE_DELTAS, readCurrent)
end

ns.RegisterEvent("PLAYER_LEVEL_UP", function(level, health, power, talents, _, strength, agility, stamina, intellect)
  local deltas = { health = health, power = power, talents = talents,
    strength = strength, agility = agility, stamina = stamina, intellect = intellect }
  ns.Debug("gains", "level %s: health %s, power %s, talents %s, str %s, agi %s, sta %s, int %s",
    level, health, power, talents, strength, agility, stamina, intellect)
  if health == nil then
    notify(level, nil)
    return
  end
  C_Timer.After(LevelGains.DELAY, function() notify(level, buildGains(deltas, readCurrent)) end)
end)

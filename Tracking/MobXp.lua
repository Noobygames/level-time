-- XP je Gegner und Kills bis zum Level-Up für den Einheiten-Tooltip (Roadmap 274, wie XToLevel).
-- Gelernt: Basis-XP (ohne Erholungsbonus) der letzten LEARN_SAMPLES Kills mit gleichem Namen, gleicher Gegnerstufe
-- und gleicher eigener Stufe aus dem Kill-Journal (Eingang). Ohne Kill die Classic-Formel aus warcraft.wiki.gg
-- "Mob experience" (Azeroth: 5 * Stufe + 45, höhere Gegner +5 % je Stufe bis +4, niedrigere über die Null-Differenz,
-- grau = 0, Elite doppelt); in Retail skalieren Gegner und XP, dort nur gelernte Werte.
-- Hinweis: TBC-Gegner in der Scherbenwelt geben mehr (Basis + 235), bis zum ersten Kill ist die Schätzung dort zu niedrig.
local _, ns = ...

local MobXp = {}
ns.MobXp = MobXp

MobXp.LEARN_SAMPLES = 5      -- so viele Kills desselben Gegners gehen in den Schnitt
local BASE_PER_LEVEL, BASE_OFFSET = 5, 45
local HIGHER_BONUS_PER_LEVEL = 0.05
local MAX_HIGHER_LEVELS = 4  -- rote Gegner geben so viel wie orange (Stufe + 4)
local ELITE_FACTOR = 2

-- Null-Differenz (ZD) je eigener Stufe: { bis Stufe, ZD }; darüber DEFAULT_ZERO_DIFFERENCE
local ZERO_DIFFERENCE = {
  { 7, 5 }, { 9, 6 }, { 11, 7 }, { 15, 8 }, { 19, 9 }, { 29, 11 }, { 39, 12 }, { 44, 13 }, { 49, 14 }, { 54, 15 },
  { 59, 16 },
}
local DEFAULT_ZERO_DIFFERENCE = 17

local function zeroDifference(playerLevel)
  for _, step in ipairs(ZERO_DIFFERENCE) do
    if playerLevel <= step[1] then return step[2] end
  end
  return DEFAULT_ZERO_DIFFERENCE
end

-- Höchste Gegnerstufe ohne XP (grau)
function MobXp.GrayLevel(playerLevel)
  if playerLevel <= 5 then return 0 end
  if playerLevel <= 39 then return playerLevel - math.floor(playerLevel / 10) - 5 end
  if playerLevel <= 59 then return playerLevel - math.floor(playerLevel / 5) - 1 end
  return playerLevel - 9
end

-- Basis-XP eines Kills nach der Classic-Formel
function MobXp.Formula(playerLevel, mobLevel, classification)
  if mobLevel <= MobXp.GrayLevel(playerLevel) then return 0 end
  local base = playerLevel * BASE_PER_LEVEL + BASE_OFFSET
  local xp
  if mobLevel >= playerLevel then
    xp = base * (1 + HIGHER_BONUS_PER_LEVEL * math.min(mobLevel - playerLevel, MAX_HIGHER_LEVELS))
  else
    xp = base * (1 - (playerLevel - mobLevel) / zeroDifference(playerLevel))
  end
  if ns.Classification.IsElite(classification) then xp = xp * ELITE_FACTOR end
  return math.max(0, math.floor(xp))
end

---------------------------------------------------------------------------
-- Gelernte Werte: einmal aus dem Eingang aufgebaut, danach mit jedem neuen Kill ergänzt
---------------------------------------------------------------------------
local learned  -- [Schlüssel] = Liste der Basis-XP, neueste zuletzt (höchstens LEARN_SAMPLES)

local function keyOf(name, mobLevel, playerLevel)
  return name .. "#" .. tostring(mobLevel) .. "#" .. tostring(playerLevel)
end

local function learn(entry)
  if entry.kind ~= ns.Journal.PVE or not entry.name or type(entry.xp) ~= "number" or entry.xp <= 0 then return end
  local key = keyOf(entry.name, entry.mobLevel, entry.level)
  local samples = learned[key] or {}
  samples[#samples + 1] = entry.xp - (entry.rested or 0)
  if #samples > MobXp.LEARN_SAMPLES then table.remove(samples, 1) end
  learned[key] = samples
end

local function ensureLearned()
  if learned then return end
  learned = {}
  for _, entry in ipairs(ns.character.killLog or {}) do learn(entry) end
end

-- Schnitt der gelernten Basis-XP oder nil
function MobXp.Learned(name, mobLevel, playerLevel)
  ensureLearned()
  local samples = learned[keyOf(name, mobLevel, playerLevel)]
  if not samples or #samples == 0 then return nil end
  local sum = 0
  for _, xp in ipairs(samples) do sum = sum + xp end
  return sum / #samples
end

-- Basis-XP eines Gegners und ob sie geschätzt ist (Formel); nil ohne Grundlage
function MobXp.BaseXp(name, mobLevel, classification)
  local learnedXp = name and MobXp.Learned(name, mobLevel, ns.level)
  if learnedXp then return learnedXp, false end
  if ns.Client.IsRetail() or not mobLevel then return nil end
  return MobXp.Formula(ns.level, mobLevel, classification), true
end

local function readable(value)
  return value ~= nil and not ns.IsSecret(value)
end

-- Kills bis zum Level-Up an dieser Einheit: count, estimated, mobLevel; nil wenn nicht sinnvoll
-- (kein Leveln, Spieler, nicht angreifbar, tot, geheime Werte, graue Gegner)
function MobXp.KillsToLevel(unit)
  if not ns.Experience.IsLeveling() then return nil end
  local exists, isPlayer, canAttack = UnitExists(unit), UnitIsPlayer(unit), UnitCanAttack("player", unit)
  if not readable(exists) or not exists or not readable(isPlayer) or isPlayer then return nil end
  if not readable(canAttack) or not canAttack then return nil end
  local dead = UnitIsDead(unit)
  if not readable(dead) or dead then return nil end
  local name, mobLevel, classification = UnitName(unit), UnitLevel(unit), UnitClassification(unit)
  if not readable(name) or not readable(mobLevel) or not readable(classification) then return nil end
  if type(mobLevel) ~= "number" or mobLevel <= 0 then mobLevel = nil end  -- "??"
  local baseXp, estimated = MobXp.BaseXp(name, mobLevel, classification)
  if not baseXp or baseXp <= 0 then return nil end
  local remainingXp = UnitXPMax("player") - UnitXP("player")
  return ns.Experience.CountForXp(remainingXp, baseXp, GetXPExhaustion() or 0), estimated, mobLevel
end

ns.Journal.OnAdd(function(logName, entry)
  if logName == "killLog" and learned then learn(entry) end
end)

ns.OnLogin(function() learned = nil end)

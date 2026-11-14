-- NPCs (X.db.npcs[npcID]): Name, Level, Einstufung, Typ, Fraktion, Lebenspunkte und Kraft je Level, Orte, Kills und
-- Kill-XP. Quellen: Ziel, Mouseover und Interaktionsziel (mit Ort, weil nah), Namensplaketten (ohne Ort, weil bis
-- 40 Meter weit). Kill-XP aus der Chatzeile COMBATLOG_XPGAIN_FIRSTPERSON (Name -> zuletzt gesehener NPC dieses
-- Namens); gespeichert wird nur Grund-XP ohne Erholungs- oder Gruppenbonus, je "Spielerlevel:Gegnerlevel".
-- Felder: names, levels[level], classification, creatureType, family, faction, reaction, health[level],
-- power[level], powerType, spots/maps (X.AddSpot), seen, kills, xp["spieler:gegner"], instances[mapID], boss (war auf
-- einem Bossrahmen, INSTANCE_ENCOUNTER_ENGAGE_UNIT).
local _, X = ...

local Units = {}
X.Units = Units

local OBSERVE_SECONDS = 10  -- dieselbe Einheit (GUID) höchstens so oft auswerten
local RECENT_SECONDS = 120  -- so lange gilt ein gesehener Name für Kill-XP
local DEFAULT_BOSS_FRAMES = 5  -- Bossrahmen, wenn der Client MAX_BOSS_FRAMES nicht setzt
local SPOT_UNITS = { target = true, mouseover = true, softinteract = true, softenemy = true }

local observedAt = {}       -- GUID -> GetTime(); geleert bei jedem Ladebildschirm
local recentByName = {}     -- Name -> { id, level, time }
Units.lastKill = nil        -- { id, time } für Quests und Beute

local function readUnit(fn, unit)
  if type(fn) ~= "function" then return nil end
  local ok, value = pcall(fn, unit)
  return ok and X.Readable(value) or nil
end

-- Einheit auswerten; Rückgabe npcID oder nil (Spieler, Begleiter, geheime GUID)
function Units.Observe(unit)
  if not X.db then return nil end
  local guid = readUnit(UnitGUID, unit)
  local kind, id = X.ParseGuid(guid)
  if kind ~= "Creature" or not id then return nil end
  local now = GetTime()
  if observedAt[guid] and now - observedAt[guid] < OBSERVE_SECONDS then return id end
  observedAt[guid] = now

  local record = X.Record("npcs", id)
  X.SetName(record, readUnit(UnitName, unit))
  local level = readUnit(UnitLevel, unit)
  if type(level) == "number" then
    record.levels = record.levels or {}
    X.Increment(record.levels, level)
    local health, power = readUnit(UnitHealthMax, unit), readUnit(UnitPowerMax, unit)
    if type(health) == "number" and health > 0 then
      record.health = record.health or {}
      record.health[level] = math.max(record.health[level] or 0, health)
    end
    if type(power) == "number" and power > 0 then
      record.power = record.power or {}
      record.power[level] = math.max(record.power[level] or 0, power)
      record.powerType = readUnit(UnitPowerType, unit)
    end
    recentByName[readUnit(UnitName, unit) or ""] = { id = id, level = level, time = now }
  end
  record.classification = readUnit(UnitClassification, unit) or record.classification
  record.creatureType = readUnit(UnitCreatureType, unit) or record.creatureType
  record.family = readUnit(UnitCreatureFamily, unit) or record.family
  record.faction = readUnit(UnitFactionGroup, unit) or record.faction
  local reaction = UnitReaction and X.Readable(UnitReaction(unit, "player"))
  if type(reaction) == "number" then record.reaction = reaction end
  X.Increment(record, "seen")
  if SPOT_UNITS[unit] then X.AddSpot(record) end
  local mapID = X.InstanceMap()
  if mapID then
    record.instances = record.instances or {}
    record.instances[mapID] = true
  end
  return id
end

for _, event in ipairs({ "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "PLAYER_SOFT_INTERACT_CHANGED" }) do
  X.On(event, function()
    local unit = event == "PLAYER_TARGET_CHANGED" and "target" or event == "UPDATE_MOUSEOVER_UNIT" and "mouseover"
      or "softinteract"
    Units.Observe(unit)
  end)
end
X.On("NAME_PLATE_UNIT_ADDED", Units.Observe)

-- Bossrahmen (boss1..bossN) beim Kampfbeginn: diese NPCs sind Bosse (Event fehlt in Classic Era, dort ohne Flagge)
X.On("INSTANCE_ENCOUNTER_ENGAGE_UNIT", function()
  for index = 1, MAX_BOSS_FRAMES or DEFAULT_BOSS_FRAMES do
    local id = Units.Observe("boss" .. index)
    if id then X.Record("npcs", id).boss = true end
  end
end)
X.On("PLAYER_ENTERING_WORLD", function() observedAt = {} end)

---------------------------------------------------------------------------
-- Kill-XP
---------------------------------------------------------------------------
local xpFormat = COMBATLOG_XPGAIN_FIRSTPERSON
local xpPattern, xpOrder = X.PatternFromFormat(xpFormat)

-- npcID zu einem Namen, wenn er kürzlich gesehen wurde
function Units.RecentByName(name)
  local seen = name and recentByName[name]
  if seen and GetTime() - seen.time <= RECENT_SECONDS then return seen end
end

X.On("CHAT_MSG_COMBAT_XP_GAIN", function(text)
  local args = X.MatchFormat(text, xpPattern, xpOrder)
  if not args or not X.db then return end
  local name, xp = args[1], tonumber(args[2])
  local seen = Units.RecentByName(name)
  if not seen or not xp then return end
  local record = X.Record("npcs", seen.id)
  X.Increment(record, "kills")
  Units.lastKill = { id = seen.id, time = GetTime() }
  -- nur die reine Grundzeile: mit Bonus (Erholung, Gruppe) wäre der Wert nicht vergleichbar
  if text == string.format(xpFormat, name, xp) then
    local playerLevel = X.Readable(UnitLevel("player"))
    record.xp = record.xp or {}
    record.xp[tostring(playerLevel) .. ":" .. tostring(seen.level)] = xp
  end
end)

-- Zuletzt besiegter Gegner, wenn höchstens maxAge Sekunden her
function Units.LastKill(maxAge)
  local kill = Units.lastKill
  if kill and GetTime() - kill.time <= maxAge then return kill.id end
end

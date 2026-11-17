-- Auswertung für den Dungeon-Recap (LT-334, UI/DungeonRecapWindow.lua): liest die Zahlen aus Tracking/RunMeter.lua
-- (record.recapPlayers / record.recapMobs, Format siehe dort) und bildet daraus die Auszeichnungen. Nur, was die Daten
-- hergeben: eine Auszeichnung erscheint nur, wenn ihr Wert größer als 0 ist (Boss-Splits: mindestens zwei Kills).
-- Auszeichnung = { id, who = Name, class = Klassendatei oder nil, value = Zahl, encounterID = bei "fastestBoss" }.
local _, ns = ...
local InstanceBosses = ns.InstanceBosses
local InstanceRuns = ns.InstanceRuns

local InstanceRecap = {}
ns.InstanceRecap = InstanceRecap

local FIELD_SEPARATOR, ROW_SEPARATOR = ":", ";"

-- Text an einem einzelnen Trennzeichen teilen (leere Teile bleiben; ohne gmatch, siehe Stub-Hinweis in CLAUDE.md)
local function split(text, separator)
  local parts, start = {}, 1
  while true do
    local at = text:find(separator, start, true)
    if not at then
      if start <= #text then parts[#parts + 1] = text:sub(start) end
      return parts
    end
    parts[#parts + 1] = text:sub(start, at - 1)
    start = at + 1
  end
end

-- Ids der Auszeichnungen in Anzeigereihenfolge
InstanceRecap.FASTEST_BOSS = "fastestBoss"
InstanceRecap.MOST_DEATHS = "mostDeaths"
InstanceRecap.DANGEROUS_MOB = "dangerousMob"
InstanceRecap.DAMAGE = "damage"
InstanceRecap.BOSS_DAMAGE = "bossDamage"
InstanceRecap.HEALING = "healing"
InstanceRecap.INTERRUPTS = "interrupts"
InstanceRecap.TANK = "tank"
InstanceRecap.LOOT_LUCK = "lootLuck"

local PLAYER_FIELDS = { "name", "class", "damage", "healing", "interrupts", "taken", "deaths", "bossDamage" }

-- Spieler des Laufs nach Schaden sortiert: { { name, class, damage, healing, interrupts, taken, deaths, bossDamage } }
function InstanceRecap.Players(record)
  local players = {}
  for _, text in ipairs(split(record.recapPlayers or "", ROW_SEPARATOR)) do
    local player = {}
    for index, value in ipairs(split(text, FIELD_SEPARATOR)) do
      local field = PLAYER_FIELDS[index]
      if field then player[field] = (index <= 2) and value or (tonumber(value) or 0) end
    end
    if player.name and player.name ~= "" then
      if player.class == "" then player.class = nil end
      for index = 3, #PLAYER_FIELDS do player[PLAYER_FIELDS[index]] = player[PLAYER_FIELDS[index]] or 0 end
      players[#players + 1] = player
    end
  end
  return players
end

-- Gegner mit dem meisten Schaden an dir: { { name, damage } }, größter zuerst
function InstanceRecap.Mobs(record)
  local mobs = {}
  for _, text in ipairs(split(record.recapMobs or "", ROW_SEPARATOR)) do
    local name, damage = text:match("^(.-):(%d+)$")
    if name then mobs[#mobs + 1] = { name = name, damage = tonumber(damage) } end
  end
  return mobs
end

-- Spieler, der in der Zahl field vorn liegt (größter Wert über 0; bei Gleichstand der erste), oder nil
local function top(players, field)
  local best
  for _, player in ipairs(players) do
    if player[field] > 0 and (not best or player[field] > best[field]) then best = player end
  end
  return best
end

-- Bester Spieler (Schaden plus Heilung), nur ab zwei Spielern; nil sonst
function InstanceRecap.Mvp(players)
  if #players < 2 then return nil end
  local best, bestScore = nil, 0
  for _, player in ipairs(players) do
    local score = player.damage + player.healing
    if score > bestScore then best, bestScore = player, score end
  end
  return best and best.name or nil
end

-- Boss mit der kürzesten Zeit seit dem vorigen Kill (der erste ab der ersten Bewegung): encounterID, Sekunden; nil bei
-- weniger als zwei Kills oder ohne passende Splits
function InstanceRecap.FastestBoss(record)
  local ids = {}
  for id in string.gmatch(record.bosses or "", "%d+") do ids[#ids + 1] = tonumber(id) end
  local splits = InstanceRuns.Splits(record)
  local previous, bestID, bestSeconds = 0, nil, nil
  for _, id in ipairs(ids) do
    if splits[id] then
      local duration = splits[id] - previous
      if not InstanceBosses.IsRare(id) and duration > 0 and (not bestSeconds or duration < bestSeconds) then
        bestID, bestSeconds = id, duration
      end
      previous = splits[id]
    end
  end
  if #ids < 2 then return nil end
  return bestID, bestSeconds
end

-- Wer gewann die meisten Gruppenwürfe? loot = InstanceRuns.Loot(...); name, Zahl oder nil
function InstanceRecap.LootLuck(loot)
  local wins, best, bestCount = {}, nil, 0
  for _, item in ipairs(loot or {}) do
    local winner = item.roll and item.roll.winner
    if winner then
      wins[winner] = (wins[winner] or 0) + 1
      if wins[winner] > bestCount then best, bestCount = winner, wins[winner] end
    end
  end
  return best, bestCount
end

-- Klasse eines Spielers aus den Messerzahlen (nil, wenn er dort fehlt)
local function classOf(players, name)
  for _, player in ipairs(players) do
    if player.name == name then return player.class end
  end
end

-- Auszeichnungen des Laufs in Anzeigereihenfolge
function InstanceRecap.Awards(record, loot)
  local players = InstanceRecap.Players(record)
  local awards = {}
  local function add(id, who, class, value, encounterID)
    if who then awards[#awards + 1] = { id = id, who = who, class = class, value = value, encounterID = encounterID } end
  end
  local bossID, bossSeconds = InstanceRecap.FastestBoss(record)
  add(InstanceRecap.FASTEST_BOSS, bossID and (InstanceBosses.Name(bossID) or "?"), nil, bossSeconds, bossID)
  local function addTop(id, field)
    local player = top(players, field)
    if player then add(id, player.name, player.class, player[field]) end
  end
  addTop(InstanceRecap.MOST_DEATHS, "deaths")
  local mob = InstanceRecap.Mobs(record)[1]
  if mob then add(InstanceRecap.DANGEROUS_MOB, mob.name, nil, mob.damage) end
  addTop(InstanceRecap.DAMAGE, "damage")
  addTop(InstanceRecap.BOSS_DAMAGE, "bossDamage")
  addTop(InstanceRecap.HEALING, "healing")
  addTop(InstanceRecap.INTERRUPTS, "interrupts")
  addTop(InstanceRecap.TANK, "taken")
  local lucky, count = InstanceRecap.LootLuck(loot)
  if lucky then add(InstanceRecap.LOOT_LUCK, lucky, classOf(players, lucky), count) end
  return awards
end

-- Zeitunterschied zum besten anderen Lauf derselben Instanz in Sekunden (negativ = schneller) oder nil ohne Vergleich;
-- records neueste zuerst, index = Lauf darin
function InstanceRecap.TimeDelta(records, index)
  local best = InstanceRuns.Reference(records, index, InstanceRuns.BEST)
  if not best then return nil end
  return InstanceRuns.Seconds(records[index]) - InstanceRuns.Seconds(best)
end

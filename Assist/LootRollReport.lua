-- Ergebnis eines Beute-Wurfs (Roadmap 364, Einstellungen lootRollSummary und lootRollJournal, Standard aus):
-- Chatzeile "Gegenstand: Name gewinnt mit 87 (Bedarf). Bedarf 2, Gier 1, Passen 2" und, für selbst gewonnene
-- Würfe, Wahl, Wurf und Zählung am Beute-Eintrag des Journals (Journal.SetLootRoll). Die Gewinnerzeile kommt vor
-- oder nach "Ihr erhaltet Beute"; beide Reihenfolgen werden zusammengeführt (Gegenstand gleich, höchstens
-- MATCH_SECONDS auseinander). Das Journal führt nur Beute ab "selten" (Loot.lua); gewöhnlichere Gewinne bleiben ohne.
local _, ns = ...
local L = ns.L
local LootRolls = ns.LootRolls
local Journal = ns.Journal

local LootRollReport = {}
ns.LootRollReport = LootRollReport

local MATCH_SECONDS = 10   -- Gewinn und Beute-Eintrag so weit auseinander gelten als derselbe Gegenstand
local RECENT_LOOT = 5      -- so viele jüngste Beute-Einträge werden beim Gewinn durchsucht

-- Klassenfarbe als |cffRRGGBB
local function byte(part) return math.floor(part * 255) end

function LootRollReport.ColoredName(roll, name)
  return LootRollReport.ClassColoredName(LootRolls.ClassOf(roll, name), name)
end

-- Name in der Farbe einer Klasse (Klassen-Kürzel wie RAID_CLASS_COLORS), ohne bekannte Klasse unverändert
function LootRollReport.ClassColoredName(class, name)
  local color = RAID_CLASS_COLORS and class and RAID_CLASS_COLORS[class]
  if not color then return name end
  return string.format("|cff%02x%02x%02x%s|r", byte(color.r), byte(color.g), byte(color.b), name)
end

function LootRollReport.KindLabel(kind)
  return L["LOOT_ROLL_KIND_" .. kind:upper()]
end

-- "Bedarf 2, Gier 1, Passen 2" (nur Wahlen mit mindestens einer Stimme)
function LootRollReport.CountsText(counts)
  local parts = {}
  for _, kind in ipairs(LootRolls.KINDS) do
    if counts[kind] > 0 then
      parts[#parts + 1] = string.format(L.LOOT_ROLL_COUNT, LootRollReport.KindLabel(kind), counts[kind])
    end
  end
  return table.concat(parts, L.LOOT_ROLL_COUNT_SEPARATOR)
end

-- itemText: Gegenstand schon aufbereitet (z. B. mit Symbol für die Würfelkarte), sonst Link oder Name
function LootRollReport.SummaryText(roll, itemText)
  local item = itemText or roll.link or roll.name or "?"
  if roll.allPassed then return string.format(L.LOOT_ROLL_SUMMARY_ALL_PASSED, item) end
  if not roll.winner then return string.format(L.LOOT_ROLL_SUMMARY_UNKNOWN, item) end
  local kind = LootRolls.WinnerKind(roll)
  local detail = ""
  if kind and roll.winnerRoll then
    detail = string.format(L.LOOT_ROLL_WITH_ROLL, roll.winnerRoll, LootRollReport.KindLabel(kind))
  elseif kind then
    detail = string.format(L.LOOT_ROLL_WITH_KIND, LootRollReport.KindLabel(kind))
  end
  local text = string.format(L.LOOT_ROLL_SUMMARY_WON, item, LootRollReport.ColoredName(roll, roll.winner), detail)
  local counts = LootRollReport.CountsText(LootRolls.Counts(roll))
  if counts ~= "" then text = text .. " " .. counts end
  return text
end

---------------------------------------------------------------------------
-- Journal: Ergebnis eigener Gewinne am Beute-Eintrag
---------------------------------------------------------------------------
local pending = {}  -- gewonnene Würfe, deren Beute-Eintrag noch fehlt: { result, itemString, itemId, at }

local function linkMatches(item, link)
  if type(link) ~= "string" then return false end
  local text = link:match("|H(item:[^|]+)|h")
  if item.itemString and text then return text == item.itemString end
  return item.itemId ~= nil and tonumber((link:match("item:(%d+)"))) == item.itemId
end

local function attach(entry, item)
  ns.Debug("lootroll", "journal: %s won with %s (%s)", entry.link, item.result.roll, item.result.choice)
  Journal.SetLootRoll(entry, item.result)
end

-- Beute-Eintrag schon da (Gewinnerzeile nach "Ihr erhaltet Beute")?
local function attachToRecent(item)
  local log = ns.character.lootLog
  local now = time()
  for index = #log, math.max(1, #log - RECENT_LOOT + 1), -1 do
    local entry = log[index]
    if now - (entry.time or 0) > MATCH_SECONDS then return false end
    if entry.rollChoice == nil and entry.roll == nil and linkMatches(item, entry.link) then
      attach(entry, item)
      return true
    end
  end
  return false
end

local function remember(roll)
  local item = { itemString = roll.itemString, itemId = roll.itemId, at = GetTime(),
    result = { choice = LootRolls.WinnerKind(roll), roll = roll.winnerRoll, counts = LootRolls.Counts(roll) } }
  if not attachToRecent(item) then table.insert(pending, item) end
end

Journal.OnAdd(function(logName, entry)
  if logName ~= "lootLog" or #pending == 0 then return end
  local now = GetTime()
  for index = #pending, 1, -1 do
    local item = pending[index]
    if now - item.at > MATCH_SECONDS then
      table.remove(pending, index)
    elseif linkMatches(item, entry.link) then
      table.remove(pending, index)
      attach(entry, item)
      return
    end
  end
end)

LootRolls.OnComplete(function(roll)
  local db = ns.db
  if db.lootRollSummary then ns.Print(LootRollReport.SummaryText(roll)) end
  local self = UnitName("player")
  if db.lootRollJournal and roll.winner and not ns.IsSecret(self) and roll.winner == self then remember(roll) end
end)

ns.OnLogin(function() pending = {} end)

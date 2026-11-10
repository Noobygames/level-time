-- Loot-Journal: eigene Beute ab Qualität "selten" (blau) mit Zeitpunkt, Anzahl und vermuteter Quelle.
-- Quelle: eine eben abgegebene Quest (Belohnung) oder der letzte Kill der vergangenen Minute.
local _, ns = ...
local ChatPatterns = ns.ChatPatterns
local Journal = ns.Journal

local Loot = {}
ns.Loot = Loot

local MIN_QUALITY = 3            -- 3 = selten, 4 = episch, 5 = legendär
local QUEST_SOURCE_MAX_AGE = 5   -- Sekunden: Beute so kurz nach einer Abgabe gilt als Belohnung
local KILL_SOURCE_MAX_AGE = 60   -- Sekunden: Beute so kurz nach einem Kill gilt als dessen Beute

-- Speziellere Formate (mit Anzahl) zuerst, sonst passt das einfache Format auch auf sie
local lootFormats = ChatPatterns.CompileGlobals({
  "LOOT_ITEM_SELF_MULTIPLE",
  "LOOT_ITEM_SELF",
  "LOOT_ITEM_PUSHED_SELF_MULTIPLE",
  "LOOT_ITEM_PUSHED_SELF",
}, ChatPatterns.LINK)
-- Erhaltene statt erbeutete Gegenstände (Questbelohnung, Kauf, Behälter)
local PUSHED_FORMATS = { LOOT_ITEM_PUSHED_SELF_MULTIPLE = true, LOOT_ITEM_PUSHED_SELF = true }

-- Qualität aus der Farbe des Links, falls der Client das Item noch nicht kennt
local QUALITY_BY_COLOR = {
  ["0070dd"] = 3,
  ["a335ee"] = 4,
  ["ff8000"] = 5,
  ["e6cc80"] = 6,
  ["00ccff"] = 7,
}

function Loot.QualityOf(link)
  local quality = ns.Items.GetQuality(link)
  if quality then return quality end
  local qualityTag = link:match("|cnIQ(%d+):")  -- neueres Linkformat
  if qualityTag then return tonumber(qualityTag) end
  local color = link:match("|cff(%x%x%x%x%x%x)")
  return color and QUALITY_BY_COLOR[color:lower()]
end

local function lastEntry(log)
  return log[#log]
end

local function guessSource()
  local now = time()
  local quest = lastEntry(ns.character.questLog)
  if quest and now - quest.time <= QUEST_SOURCE_MAX_AGE then
    return quest.name
  end
  local kill = lastEntry(ns.character.killLog)
  if kill and now - kill.time <= KILL_SOURCE_MAX_AGE then
    return kill.name
  end
  return nil
end

-- Jede eigene Beute (alle Qualitäten), z.B. zum Lernen von Quest-Gegenständen: listener(link, quantity, pushed);
-- pushed = erhaltener Gegenstand ("Ihr erhaltet einen Gegenstand"), auch Käufe beim Händler
local selfLootListeners = {}
function Loot.OnSelfLoot(listener)
  ns.RememberSource(listener, "Loot.lua")
  table.insert(selfLootListeners, listener)
end

if #lootFormats > 0 then
  ns.RegisterEvent("CHAT_MSG_LOOT", function(message)
    if ns.IsSecret(message) then return end
    local args, format = ChatPatterns.MatchAny(message, lootFormats)
    if not args then return end

    local link = args[1]
    local quantity, pushed = tonumber(args[2]) or 1, PUSHED_FORMATS[format.name] or false
    for _, listener in ipairs(selfLootListeners) do ns.SafeCall(listener, link, quantity, pushed) end
    local quality = Loot.QualityOf(link)
    if not quality or quality < MIN_QUALITY then return end

    Journal.AddLoot({
      link = link,
      name = link:match("%[(.-)%]") or link,
      quality = quality,
      quantity = quantity,
      source = guessSource(),
      value = ns.Items.GetSellPrice(link),  -- je Stück; nil, solange der Client das Item nicht kennt
    })
  end)
end

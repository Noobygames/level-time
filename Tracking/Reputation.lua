-- Ruf (Roadmap 278): Rufgewinne aus CHAT_MSG_COMBAT_FACTION_CHANGE, erkannt an FACTION_STANDING_INCREASED und seinen
-- Varianten (GlobalStrings aller Clients, Ketho/BlizzardInterfaceResources: Classic "Your %s reputation has increased
-- by %d.", Retail/Anniversary "Reputation with %s increased by %d.", Retail zusätzlich die Kriegsmeute-Form
-- _ACCOUNT_WIDE; Boni hängen als Text hinten an). Zähler REPUTATION läuft je Level, Session, Instanz-Lauf und Zone
-- (Zones.lua), je Fraktion in character.reputationGains[Fraktion] = { amount, last }. Verluste und Meldungen ohne
-- Menge (_GENERIC) zählen nicht. Geheime Meldungen (Forever/Retail in Instanzen) werden übergangen.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    showReputation = false,
  },
  counters = {
    reputation = 0,
  },
})
local Stats = ns.Stats
local ChatPatterns = ns.ChatPatterns

local Reputation = {}
ns.Reputation = Reputation

-- Die Bonus-Formen enden auf " (+%.1f ...)"; ChatPatterns kennt nur %s/%d, daher zählt nur der Teil davor
-- (die Muster sind nur am Anfang verankert). Kriegsmeute-Form zuerst, sie ist die speziellere.
local FORMAT_NAMES = { "FACTION_STANDING_INCREASED_ACCOUNT_WIDE", "FACTION_STANDING_INCREASED",
  "FACTION_STANDING_INCREASED_ACH_BONUS", "FACTION_STANDING_INCREASED_BONUS", "FACTION_STANDING_INCREASED_DOUBLE_BONUS" }
local BONUS_SUFFIX = "^(.-) %("

local formats = {}
for _, name in ipairs(FORMAT_NAMES) do
  local format = _G[name]
  if type(format) == "string" then
    formats[#formats + 1] = ChatPatterns.Compile(format:match(BONUS_SUFFIX) or format)
  end
end

-- Fraktion und Menge aus einer Rufmeldung, nil wenn es kein Gewinn mit Menge ist
function Reputation.Parse(message)
  if ns.IsSecret(message) or type(message) ~= "string" then return nil end
  local args = ChatPatterns.MatchAny(message, formats)
  local amount = args and tonumber(args[2])
  if not args or not args[1] or not amount or amount <= 0 then return nil end
  return args[1], amount
end

function Reputation.Add(faction, amount)
  Stats.Increment(Stats.REPUTATION, amount)
  local gains = ns.character.reputationGains or {}
  ns.character.reputationGains = gains
  local entry = gains[faction] or { amount = 0 }
  entry.amount = entry.amount + amount
  entry.last = time()
  gains[faction] = entry
  ns.Debug("reputation", "%s +%s", faction, amount)
end

-- Fraktionen eines Charakters als Historien-Einträge { faction, amount, last }, meiste zuerst
function Reputation.GetRecords(characterKey)
  local character = ns.History.GetCharacter(characterKey)
  local records = {}
  for faction, entry in pairs(character and character.reputationGains or {}) do
    records[#records + 1] = { faction = faction, amount = entry.amount or 0, last = entry.last }
  end
  table.sort(records, function(a, b) return a.amount > b.amount end)
  return records
end

ns.RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE", function(message)
  local faction, amount = Reputation.Parse(message)
  if faction then Reputation.Add(faction, amount) end
end)

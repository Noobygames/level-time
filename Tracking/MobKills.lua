-- Wie oft der Charakter Gegner eines Namens getötet hat (Roadmap 499, Tooltip-Zeile "12-mal getötet").
-- Quelle: PvE-Einträge des Kill-Journals samt Archiv (Journal.GetEntries; nur Kills mit XP landen dort). Die Zählung je
-- Name wird einmal aufgebaut und danach mit jedem neuen Kill (Journal.OnAdd) ergänzt, weil Tooltips sehr oft fragen;
-- ändert sich das Archiv (Umzug, Laden), wird neu gezählt.
local _, ns = ...

local MobKills = {}
ns.MobKills = MobKills

local counts         -- [Name] = Kills, nil = noch nicht aufgebaut
local countsVersion  -- Archiv-Stand, zu dem counts passt

local function count(entry)
  if entry.kind ~= ns.Journal.PVE or type(entry.name) ~= "string" then return end
  counts[entry.name] = (counts[entry.name] or 0) + 1
end

local function ensureCounts()
  local version = ns.JournalArchive.Version()
  if counts and countsVersion == version then return end
  counts = {}
  for _, entry in ipairs(ns.Journal.GetEntries(ns.characterKey, "killLog")) do count(entry) end
  countsVersion = ns.JournalArchive.Version()  -- GetEntries kann das Archiv erst laden
end

-- Kills dieses Charakters an Gegnern mit diesem Namen (0 ohne Kill)
function MobKills.Count(name)
  if type(name) ~= "string" or not ns.characterKey then return 0 end
  ensureCounts()
  return counts[name] or 0
end

ns.Journal.OnAdd(function(logName, entry)
  if logName == "killLog" and counts then count(entry) end
end)

ns.OnLogin(function() counts = nil end)

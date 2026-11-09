-- Aktuelle XP/h: Rate über die letzten WINDOW Sekunden statt über das ganze Level bzw. die Session,
-- damit Einbrüche (Laufwege, Flugrouten, Pausen) sofort sichtbar sind.
-- Alle SAMPLE_INTERVAL Sekunden wird gemerkt, wie viel XP seit dem letzten Messpunkt dazukam
-- (aus dem Session-Zähler xpGained, der auch über Level-Ups weiterzählt). Zuwächse statt Stände,
-- weil eine neue Session (/lt newsession) den Zähler auf 0 setzt: dann zählt der neue Stand als
-- Zuwachs (erkannt an currentSession.startedAt). Die Rate = Summe der Zuwächse im Fenster / Zeit seit dem ältesten Messpunkt.
-- Nach Login oder /reload beginnt das Fenster neu.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    showRecentXpRate = false,
  },
})
local Stats = ns.Stats

local RecentXpRate = {}
ns.RecentXpRate = RecentXpRate

RecentXpRate.WINDOW = 15 * 60    -- Sekunden
local SAMPLE_INTERVAL = 30       -- Sekunden zwischen zwei Messpunkten
local MIN_SPAN = 60              -- darunter schwankt die Rate zu stark
local SECONDS_PER_HOUR = 3600

local samples = {}  -- { at = GetTime(), gained = XP seit dem vorigen Messpunkt }, älteste zuerst
local lastXp = 0    -- Session-XP beim letzten Messpunkt
local lastSession   -- startedAt der Session beim letzten Messpunkt

-- XP seit dem letzten Messpunkt; in einer neuen Session zählt der Zähler ab 0
local function gainedSinceSample()
  local xp = Stats.Get(Stats.SESSION, Stats.XP_GAINED)
  if ns.character.currentSession.startedAt ~= lastSession then return xp, xp end
  return xp - lastXp, xp
end

-- Messpunkt merken und alles verwerfen, was älter als das Fenster ist
function RecentXpRate.Sample()
  local now = GetTime()
  local gained, xp = gainedSinceSample()
  lastXp = xp
  lastSession = ns.character.currentSession.startedAt
  table.insert(samples, { at = now, gained = gained })
  while now - samples[1].at > RecentXpRate.WINDOW do
    table.remove(samples, 1)
  end
end

-- XP pro Stunde im Fenster; nil, solange weniger als MIN_SPAN Sekunden gemessen sind.
-- Der Zuwachs des ältesten Messpunkts liegt vor dem Fenster und zählt nicht mit.
function RecentXpRate.Get()
  local oldest = samples[1]
  if not oldest then return nil end
  local span = GetTime() - oldest.at
  if span < MIN_SPAN then return nil end
  local total = gainedSinceSample()
  for index = 2, #samples do
    total = total + samples[index].gained
  end
  return total / span * SECONDS_PER_HOUR
end

ns.Every(SAMPLE_INTERVAL, RecentXpRate.Sample)

ns.OnLogin(function()
  samples = {}
  lastXp = Stats.Get(Stats.SESSION, Stats.XP_GAINED)
  lastSession = ns.character.currentSession.startedAt
  RecentXpRate.Sample()
end)

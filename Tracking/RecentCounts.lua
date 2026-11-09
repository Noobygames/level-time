-- Kills und erbeutete Gegenstände der letzten WINDOW Sekunden und das daraus hochgerechnete Tempo je Stunde, damit
-- man beim Farmen sieht, ob das Tempo gerade hält (Wunsch auf CurseForge, Roadmap 382). Wie RecentXpRate unabhängig
-- vom Bereich und nur seit Login bzw. /reload: die Zeitpunkte liegen im Speicher (Ringpuffer je Zähler, Lib/RecentCounter.lua), gefüllt über
-- Stats.OnIncrement. Abfragen kosten je Anzeige-Takt einen Vergleich, solange nichts aus dem Fenster fällt.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    showRecentKills = false,
    showRecentItems = false,
  },
})
local Stats = ns.Stats

local RecentCounts = {}
ns.RecentCounts = RecentCounts

RecentCounts.WINDOW = 15 * 60  -- Sekunden
local MIN_SPAN = 60            -- darunter schwankt die Hochrechnung zu stark
local SECONDS_PER_HOUR = 3600

-- Zähler (Schlüssel aus Stats.lua), deren letzte Minuten gezählt werden
local recent = {
  [Stats.PVE_KILLS] = ns.RecentCounter.New(RecentCounts.WINDOW),
  [Stats.ITEMS_LOOTED] = ns.RecentCounter.New(RecentCounts.WINDOW),
}
local startedAt = 0  -- GetTime() beim Login: bis das erste Fenster voll ist, zählt die Zeit seitdem

Stats.OnIncrement(function(counter, amount)
  local window = recent[counter]
  if window then window:Add(GetTime(), amount) end
end)

-- Summe des Zählers in den letzten WINDOW Sekunden
function RecentCounts.Count(counter)
  return recent[counter]:Count(GetTime())
end

-- Hochgerechnet auf eine Stunde; im ersten Fenster nach Login über die Zeit seitdem. nil unter MIN_SPAN Sekunden.
function RecentCounts.Rate(counter)
  local now = GetTime()
  local span = math.min(RecentCounts.WINDOW, now - startedAt)
  if span < MIN_SPAN then return nil end
  return recent[counter]:Count(now) / span * SECONDS_PER_HOUR
end

ns.OnLogin(function()
  startedAt = GetTime()
  for _, window in pairs(recent) do window:Reset() end
end)

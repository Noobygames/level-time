-- Auswertung pro Zone: Spielzeit, XP, Kills und Tode je Zone, gesamt pro Charakter
-- (ns.character.zoneStats[zone] = { seconds, xp, kills, deaths, reputation }; reputation fehlt bei älteren Zonen).
-- Zeit wird beim Zonenwechsel und beim Logout verbucht; XP, Kills und Tode zählen über Stats.OnIncrement.
local _, ns = ...
local Stats = ns.Stats
local History = ns.History

local Zones = {}
ns.Zones = Zones

-- Welche Zähler in welches Zonenfeld fließen
local ZONE_FIELDS = {
  [Stats.XP_GAINED] = "xp",
  [Stats.PVE_KILLS] = "kills",
  [Stats.PVP_KILLS] = "kills",
  [Stats.DEATHS] = "deaths",
  [Stats.REPUTATION] = "reputation",
}

local currentZone  -- Name der Zone, in der man gerade ist (nil wenn unbekannt)
local enteredAt    -- GetTime() seit dem die laufende Zeit gezählt wird

local function zoneName()
  local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText())
  if ns.IsSecret(zone) or not zone or zone == "" then return nil end
  return zone
end

local function entryFor(zone)
  local zones = ns.character.zoneStats
  zones[zone] = zones[zone] or { seconds = 0, xp = 0, kills = 0, deaths = 0, reputation = 0 }
  return zones[zone]
end

-- Laufende Zeit der aktuellen Zone gutschreiben und neu zu zählen beginnen
local function bookTime()
  if currentZone and enteredAt then
    local entry = entryFor(currentZone)
    entry.seconds = entry.seconds + GetTime() - enteredAt
  end
  enteredAt = GetTime()
end

-- Die laufende Zone steht sofort in der Liste, auch ohne XP, Kill oder Tod
local function enterZone()
  currentZone = zoneName()
  if currentZone then entryFor(currentZone) end
end

local function onZoneChanged()
  bookTime()
  enterZone()
end

ns.OnLogin(function()
  enterZone()
  enteredAt = GetTime()
end)
ns.OnLogout(bookTime)
ns.RegisterEvent("ZONE_CHANGED_NEW_AREA", onZoneChanged)
ns.RegisterEvent("PLAYER_ENTERING_WORLD", onZoneChanged)

Stats.OnIncrement(function(counter, amount)
  local field = ZONE_FIELDS[counter]
  if field and currentZone then
    local entry = entryFor(currentZone)
    entry[field] = (entry[field] or 0) + amount
  end
end)

-- Einträge in Historien-Form: { zone, seconds, xp, counters = { kills, deaths }, isCurrent },
-- sortiert nach XP pro Stunde (Zonen ohne XP zuletzt, dann nach Spielzeit)
function Zones.GetRecords(characterKey)
  local isLoggedIn = characterKey == ns.characterKey
  local records = {}
  for zone, entry in pairs(History.GetCharacter(characterKey).zoneStats) do
    local isCurrent = isLoggedIn and zone == currentZone
    local seconds = entry.seconds + (isCurrent and enteredAt and (GetTime() - enteredAt) or 0)
    table.insert(records, {
      zone = zone,
      seconds = seconds,
      xp = entry.xp,
      counters = { kills = entry.kills, deaths = entry.deaths, reputation = entry.reputation or 0 },
      isCurrent = isCurrent,
    })
  end

  local function rate(record)
    return record.seconds > 0 and record.xp / record.seconds or 0
  end
  table.sort(records, function(a, b)
    if rate(a) ~= rate(b) then return rate(a) > rate(b) end
    return a.seconds > b.seconds
  end)
  return records
end

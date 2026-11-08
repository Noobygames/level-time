-- Flug-Anzeige: geschätzte Restzeit mit "~" und leiser Farbe, gemessene normal
local Theme = addon.Theme

local function openMap(current)
  wow.state.taxiNodes = {
    { name = "Crossroads, Brachland", x = 0.55735743045807, y = 0.53047657012939, id = 25 },
    { name = "Camp Taurajo, Brachland", x = 0.52804720401764, y = 0.61013436317444, id = 77 },
  }
  wow.state.taxiNodes[current].type = "CURRENT"
  wow.state.taxiNodes[3 - current].type = "REACHABLE"
  wow.state.taxiMapID = 1411
  wow.fire("TAXIMAP_OPENED", 1)
end

local function takeoff(slot)
  TakeTaxiNode(slot)
  wow.state.onTaxi = true
  wow.advance(1)
  wow.update(1)
end

local function land(seconds)
  wow.advance(seconds)
  wow.state.onTaxi = false
  wow.fire("PLAYER_CONTROL_GAINED")
end

local function sameColor(color, token)
  local expected = Theme.COLORS[token]
  return color and color[1] == expected[1] and color[2] == expected[2] and color[3] == expected[3]
end

wow.login({ level = 20 })
addon.Set("flightTimer", true)

openMap(1)
takeoff(2)
land(90)

-- Gegenrichtung: geschätzt
openMap(2)
takeoff(1)
expect("geschätzt mit ~", LevelTimerFlight.time:GetText(), "~" .. addon.Format.Duration(90))
expectTrue("leise Farbe", sameColor(LevelTimerFlight.title._textColor, "muted"))
land(95)
expect("Gegenrichtung jetzt gemessen", LevelTimerStatsDB.flights.retail["1411"].routes["77>25"].seconds, 96)

-- Gemessen: normale Farbe, ohne ~
openMap(2)
takeoff(1)
expect("gemessen ohne ~", LevelTimerFlight.time:GetText(), addon.Format.Duration(95))
expectTrue("normale Farbe", sameColor(LevelTimerFlight.title._textColor, "info"))
land(94)
expect("keine Fehler", #wow.errors, 0)

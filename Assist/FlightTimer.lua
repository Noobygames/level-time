-- Flugzeiten (Einstellung flightTimer, Standard an): misst jeden Flug selbst und zeigt beim nächsten Flug derselben
-- Strecke die Restzeit (UI/FlightDisplay.lua) plus eine Chatzeile beim Abflug. Keine mitgelieferten Daten: die
-- erste Strecke wird gemessen ("hint"), danach ist sie bekannt.
-- Ablauf wie Blizzards TaxiFrame (alle Clients; im Spiel geprüft in WoW Forever 1.60.1, Debug-Log):
--   TAXIMAP_OPENED   Start = Knoten mit TaxiNodeGetType(i) == "CURRENT" (TaxiNodeName)
--   TakeTaxiNode(i)  Ziel = TaxiNodeName(i) (hooksecurefunc, kein Eingriff in den Flug)
--   Landung          PLAYER_CONTROL_GAINED, sobald UnitOnTaxi("player") false ist
-- Gespeichert account-weit: LevelTimerStatsDB.flightTimes["Start > Ziel"] = Sekunden (letzte Messung; Namen in der
-- Sprache des Clients). Ein /reload im Flug verliert die Messung, die bekannte Zeit gilt dann ab dem Neuladen nicht.
local _, ns = ...
local L = ns.L

local FlightTimer = {}
ns.FlightTimer = FlightTimer

local CURRENT_NODE = "CURRENT"
local MIN_FLIGHT_SECONDS = 5       -- kürzere "Flüge" (abgebrochen) werden nicht gemerkt
local LANDING_CHECK_SECONDS = 1    -- wie oft im Flug geprüft wird, ob man gelandet ist

local origin       -- Name des Knotens, an dem die Flugkarte offen ist
local flight       -- { from, to, startedAt, known } während des Flugs

local function times()
  LevelTimerStatsDB.flightTimes = LevelTimerStatsDB.flightTimes or {}
  return LevelTimerStatsDB.flightTimes
end

function FlightTimer.RouteKey(from, to)
  return from .. " > " .. to
end

-- Bekannte Dauer einer Strecke in Sekunden oder nil
function FlightTimer.Get(from, to)
  if not from or not to then return nil end
  return times()[FlightTimer.RouteKey(from, to)]
end

local function currentNode()
  if not NumTaxiNodes then return nil end
  for index = 1, NumTaxiNodes() do
    if TaxiNodeGetType(index) == CURRENT_NODE then return TaxiNodeName(index) end
  end
  return nil
end

local function show()
  if not ns.db.flightTimer or not flight then return end
  if flight.known then
    local remaining = flight.known - (GetTime() - flight.startedAt)
    ns.FlightDisplay.Show({ kind = "countdown", spellId = ns.FlightDisplay.ICON, title = flight.to,
      remaining = math.max(0, remaining), duration = flight.known })
  else
    ns.FlightDisplay.Show({ kind = "hint", spellId = ns.FlightDisplay.ICON, title = flight.to })
  end
end

local function onTakeoff(index)
  local to = TaxiNodeName(index)
  if not origin or not to or ns.IsSecret(to) then return end
  flight = { from = origin, to = to, startedAt = GetTime(), known = FlightTimer.Get(origin, to) }
  ns.Debug("flight", "takeoff %s, known %s", FlightTimer.RouteKey(origin, to), flight.known)
  if ns.db.flightTimer then
    if flight.known then
      ns.Print(string.format(L.FLIGHT_STARTED, to, ns.Format.Duration(flight.known)))
    else
      ns.Print(string.format(L.FLIGHT_STARTED_UNKNOWN, to))
    end
  end
  show()
end

local function onLanded()
  if not flight or UnitOnTaxi("player") then return end
  local seconds = GetTime() - flight.startedAt
  local landed = flight
  flight = nil
  -- Noch nicht abgeflogen (Kontrolle kurz zurück vor dem Start): nichts messen
  if seconds < MIN_FLIGHT_SECONDS then
    ns.FlightDisplay.Show(nil)
    return
  end
  times()[FlightTimer.RouteKey(landed.from, landed.to)] = math.floor(seconds + 0.5)
  ns.Debug("flight", "landed %s after %s s", FlightTimer.RouteKey(landed.from, landed.to), seconds)
  if ns.db.flightTimer then ns.FlightDisplay.ShowDone(ns.FlightDisplay.ICON, landed.to) end
end

ns.RegisterEvent("TAXIMAP_OPENED", function() origin = currentNode() end)
ns.RegisterEvent("PLAYER_CONTROL_GAINED", onLanded)
if hooksecurefunc and TakeTaxiNode then hooksecurefunc("TakeTaxiNode", onTakeoff) end

-- Restzeit nachführen und verpasste Landung erkennen (z.B. Kontrolle schon vorher zurück)
ns.Every(LANDING_CHECK_SECONDS, function()
  if not flight then return end
  if GetTime() - flight.startedAt >= MIN_FLIGHT_SECONDS and not UnitOnTaxi("player") then
    onLanded()
    return
  end
  show()
end)

ns.OnLogin(function()
  origin, flight = nil, nil
end)

-- Zwischenspeicher für einen Anzeige-Takt: Mehrere Zeilen eines Fensters fragen im selben Takt dieselben teuren
-- Werte ab (Prognose bis Max-Level und Session-Ziel, Split-Vergleich, XP-Quellen). TickCache.Run(fn) führt fn als
-- einen Takt aus; mit TickCache.Memo(fn) umhüllte Funktionen rechnen darin je Argument nur einmal.
-- Außerhalb eines Takts rufen sie fn immer direkt auf (Ereignisse ändern die Eingaben, nichts bleibt veraltet).
local _, ns = ...

local TickCache = {}
ns.TickCache = TickCache

local active = false
local stamp = 0
local NIL = {}  -- Platzhalter: auch nil-Ergebnisse gelten als berechnet

-- fn als einen Takt ausführen (geschützt: ein Fehler beendet den Takt trotzdem). Verschachtelt = derselbe Takt.
function TickCache.Run(fn)
  if active then return fn() end
  active = true
  stamp = stamp + 1
  ns.SafeCall(fn)
  active = false
end

function TickCache.IsActive()
  return active
end

-- fn(argument) mit höchstens einem Argument; im Takt je Argument einmal berechnet
function TickCache.Memo(fn)
  local values, valuesStamp = {}, 0
  return function(argument)
    if not active then return fn(argument) end
    if valuesStamp ~= stamp then
      values, valuesStamp = {}, stamp
    end
    local key = argument == nil and NIL or argument
    local value = values[key]
    if value == nil then
      value = fn(argument)
      values[key] = value == nil and NIL or value
      return value
    end
    if value == NIL then return nil end
    return value
  end
end

-- Welcher Client läuft. Für Funktionen, die es nur in einem Client gibt (z.B. Camp-Buffs in
-- WoW Forever); deren Einstellungen erscheinen in anderen Clients gar nicht.
-- Grundlage ist die Interface-Version (4. Wert von GetBuildInfo), z.B. 16001 = WoW Forever 1.60.1.
-- Gleiche Zuordnung wie beim BigWigs-Packager (16xxx = forever).
local _, ns = ...

local Client = {}
ns.Client = Client

local FOREVER_FIRST, FOREVER_LAST = 16000, 16999

function Client.GetInterfaceVersion()
  return select(4, GetBuildInfo())
end

function Client.IsForever()
  local version = Client.GetInterfaceVersion()
  return version >= FOREVER_FIRST and version <= FOREVER_LAST
end

-- Retail (Mainline, 10.x und neuer): z.B. 120105
local RETAIL_FIRST = 100000

function Client.IsRetail()
  return Client.GetInterfaceVersion() >= RETAIL_FIRST
end

-- Classic Era (1.x ohne WoW Forever): z.B. 11509
local CLASSIC_ERA_LAST = 19999

function Client.IsClassicEra()
  return Client.GetInterfaceVersion() <= CLASSIC_ERA_LAST and not Client.IsForever()
end

-- Burning Crusade (Classic, Anniversary): z.B. 20506
local BURNING_CRUSADE_FIRST, BURNING_CRUSADE_LAST = 20000, 29999

function Client.IsBurningCrusade()
  local version = Client.GetInterfaceVersion()
  return version >= BURNING_CRUSADE_FIRST and version <= BURNING_CRUSADE_LAST
end

-- Gildenbank (Reparatur aus der Gildenkasse); Classic Era hat keine
function Client.HasGuildBank()
  return CanGuildBankRepair ~= nil and not Client.IsClassicEra()
end

-- Flavor wie der Ordner der Installation (_forever_, _classic_era_, _anniversary_, _retail_): Schlüssel der
-- mitgelieferten Flugzeiten (Assist/FlightTimesData.lua, tools/flights), weil Strecken je Client abweichen können
function Client.Flavor()
  if Client.IsForever() then return "forever" end
  if Client.IsRetail() then return "retail" end
  if Client.IsBurningCrusade() then return "anniversary" end
  if Client.IsClassicEra() then return "classic_era" end
  return "other"
end

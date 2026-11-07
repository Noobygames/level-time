-- Todesursache aus Blizzards Death Recap. Clients mit Retail-API (Retail, WoW Forever) geben
-- das Kampflog nicht an Addons, der Recap des letzten Todes ist aber abrufbar. Erkannt wird
-- die API, nicht der Client: fehlt C_DeathRecap, liefert GetLastCause nil und DeathCounter
-- bleibt beim Kampflog.
local _, ns = ...

local DeathRecap = {}
ns.DeathRecap = DeathRecap

-- Wie Blizzards Recap-Fenster (Blizzard_DeathRecap): der erste Eintrag ist der tödliche Treffer
local KILLING_BLOW_INDEX = 1

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function toCause(event)
  if readable(event.event) == "ENVIRONMENTAL_DAMAGE" then
    return { environment = readable(event.environmentalType) }
  end
  return { killer = readable(event.sourceName), spell = readable(event.spellName) }
end

local function hasCause(cause)
  return cause.killer ~= nil or cause.spell ~= nil or cause.environment ~= nil
end

function DeathRecap.IsAvailable()
  return C_DeathRecap ~= nil and C_DeathRecap.GetRecapEvents ~= nil
end

-- Ursache des letzten Todes { killer, spell, environment } oder nil (keine API, kein Recap, nur geheime Werte).
-- Ohne recapID liefert der Client den Recap des letzten Todes: recapID ist laut DeathRecapDocumentation.lua (live und
-- forever) Nilable, Blizzards Recap-Fenster ruft GetRecapEvents(self:GetRecapID()) ebenfalls mit nil auf (Roadmap 180).
function DeathRecap.GetLastCause()
  if not DeathRecap.IsAvailable() then return nil end
  local ok, events = pcall(C_DeathRecap.GetRecapEvents)
  ns.Debug("death", "recap: ok %s, %s, events %s", ok, type(events), type(events) == "table" and #events or events)
  if not ok or type(events) ~= "table" then return nil end
  local event = events[KILLING_BLOW_INDEX]
  if not event then return nil end
  local cause = toCause(event)
  return hasCause(cause) and cause or nil
end

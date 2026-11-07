-- Buffs des Spielers lesen, mit den Vorsichtsmaßnahmen aller Clients: In Retail und WoW Forever sind Auren
-- bei Kampf-, Bosskampf-, Mythisch+- oder PvP-Beschränkungen geheim; GetAuraDataByIndex bricht dann für
-- Addons mit einem Fehler ab (RequiresUnitAuraAccess, im Spiel beim Bosskampf gemeldet).
-- C_Secrets.ShouldAurasBeSecret sagt das vorher. Jede Abfrage liefert nil, wenn sich nichts feststellen lässt
-- (nicht gleichbedeutend mit "kein Buff").
-- Gemeinsamer Schnappschuss: Essen-Timer, Lagerfeuer, Buff-Hinweise und Klassenbuffs fragen alle paar Zehntel-
-- sekunden; gelesen wird nur einmal je Aura-Änderung (UNIT_AURA für den Spieler) und höchstens MAX_SNAPSHOT_AGE alt,
-- falls ein Client ein Event auslässt. Restzeiten rechnet Auras.RemainingSeconds aus expirationTime, dafür braucht es
-- keinen neuen Scan. Bei gesperrten Auren gibt es keinen Schnappschuss (nil, nie ein veralteter Stand).
local _, ns = ...

local Auras = {}
ns.Auras = Auras

local MAX_AURAS = 40
Auras.MAX_SNAPSHOT_AGE = 2  -- Sekunden

function Auras.Restricted()
  return C_Secrets ~= nil and C_Secrets.ShouldAurasBeSecret ~= nil and C_Secrets.ShouldAurasBeSecret()
end

-- list = Buffs in Client-Reihenfolge, byName = erster Buff je Name, bySpellId = letzter Buff je Spell-ID
-- (Tabellen werden wiederverwendet, nicht verändern)
local snapshot = { list = {}, byName = {}, bySpellId = {} }
local snapshotValid = false
local snapshotAt

local function clear(map)
  for key in pairs(map) do map[key] = nil end
end

function Auras.Invalidate()
  snapshotValid = false
end

-- Alle Buffs einlesen; false, wenn der Client sie verbirgt (Beschränkung beginnt mitten im Lesen, geheime Werte)
local function readBuffs()
  local list, byName, bySpellId = snapshot.list, snapshot.byName, snapshot.bySpellId
  for index = #list, 1, -1 do list[index] = nil end
  clear(byName)
  clear(bySpellId)
  for index = 1, MAX_AURAS do
    local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", index, "HELPFUL")
    if not ok then return false end
    if not aura then return true end
    local name, spellId = aura.name, aura.spellId
    if ns.IsSecret(name) or ns.IsSecret(spellId) then return false end
    list[#list + 1] = aura
    if name ~= nil and byName[name] == nil then byName[name] = aura end
    if spellId ~= nil then bySpellId[spellId] = aura end
  end
  return true
end

-- Schnappschuss der Buffs oder nil, wenn der Client Auren verbirgt
function Auras.Snapshot()
  if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex or Auras.Restricted() then
    snapshotValid = false
    return nil
  end
  if snapshotValid and GetTime() - snapshotAt <= Auras.MAX_SNAPSHOT_AGE then return snapshot end
  snapshotValid = readBuffs()
  snapshotAt = GetTime()
  return snapshotValid and snapshot or nil
end

ns.RegisterUnitEvent("UNIT_AURA", "player", Auras.Invalidate)

-- Geht die Buffs des Spielers durch; visit(aura) liefert true zum Abbrechen.
-- Rückgabe: true, wenn gelesen (vollständig oder bis zum Abbruch), nil wenn der Client Auren verbirgt.
function Auras.ForEachBuff(visit)
  local buffs = Auras.Snapshot()
  if not buffs then return nil end
  local list = buffs.list
  for index = 1, #list do
    if visit(list[index]) then return true end
  end
  return true
end

-- true/false, ob ein Buff mit matches(aura) aktiv ist; nil, wenn der Client Auren verbirgt
function Auras.Has(matches)
  local buffs = Auras.Snapshot()
  if not buffs then return nil end
  local list = buffs.list
  for index = 1, #list do
    if matches(list[index]) then return true end
  end
  return false
end

-- Erster aktiver Buff mit diesem Namen, false = keiner, nil = nicht feststellbar
function Auras.FindByName(name)
  local buffs = Auras.Snapshot()
  if not buffs then return nil end
  return buffs.byName[name] or false
end

-- Aktiver Buff mit dieser Spell-ID, false = keiner, nil = nicht feststellbar
function Auras.FindBySpellId(spellId)
  local buffs = Auras.Snapshot()
  if not buffs then return nil end
  return buffs.bySpellId[spellId] or false
end

-- { [spellId] = aura } der aktiven Buffs unter den gesuchten Spell-IDs; nil, wenn der Client Auren verbirgt
function Auras.FindBySpellIds(spellIds)
  local buffs = Auras.Snapshot()
  if not buffs then return nil end
  local found = {}
  for _, spellId in ipairs(spellIds) do found[spellId] = buffs.bySpellId[spellId] end
  return found
end

-- Einzelne Buffs per Spell-ID, auch wenn die Buff-Liste gesperrt ist (Retail/WoW Forever im Kampf): Blizzard gibt
-- manche Auren trotzdem frei, C_Secrets.ShouldSpellAuraBeSecret(spellId) sagt welche; dann liefert
-- C_UnitAuras.GetPlayerAuraBySpellID die Aura oder nil. Rückgabe: true = einer aktiv, false = sicher keiner,
-- nil = nicht feststellbar (mindestens einer geheim oder die Abfrage scheitert).
local function spellAuraSecret(spellId)
  if not C_Secrets or not C_Secrets.ShouldSpellAuraBeSecret then return false end
  local ok, secret = pcall(C_Secrets.ShouldSpellAuraBeSecret, spellId)
  return not ok or ns.IsSecret(secret) or secret == true
end

function Auras.HasPlayerSpell(spellIds)
  if not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then return nil end
  local unknown = false
  for _, spellId in ipairs(spellIds) do
    if spellAuraSecret(spellId) then
      unknown = true
    else
      local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellId)
      if not ok or ns.IsSecret(aura) then
        unknown = true
      elseif aura ~= nil then
        return true
      end
    end
  end
  if unknown then return nil end
  return false
end

-- Verbleibende Sekunden und Gesamtdauer eines Buffs mit Ablaufzeit; nil bei unbegrenzten oder geheimen Werten
function Auras.RemainingSeconds(aura)
  local expiration, duration = aura.expirationTime, aura.duration
  if ns.IsSecret(expiration) or ns.IsSecret(duration) then return nil end
  if type(expiration) ~= "number" or expiration <= 0 or type(duration) ~= "number" then return nil end
  return math.max(0, expiration - GetTime()), duration
end

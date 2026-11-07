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
-- Stand des Schnappschusses (Roadmap 372): steigt nur, wenn sich Buffs (Spell-ID, Ablaufzeit, Stapel) oder die
-- Lesbarkeit geändert haben, nicht bei jedem Neu-Lesen nach MAX_SNAPSHOT_AGE. Wer nur bei Änderungen arbeiten will,
-- vergleicht Auras.Version() nach Auras.Snapshot().
local version = 0
local signature = {}   -- Spell-ID, Ablaufzeit und Stapel je Buff des letzten Stands, flach hintereinander
local signatureLength = 0
local readableBefore

local function clear(map)
  for key in pairs(map) do map[key] = nil end
end

function Auras.Invalidate()
  snapshotValid = false
end

function Auras.Version()
  return version
end

local SECRET = {}  -- Platzhalter für geheime Werte (nicht vergleichbar); Änderungen daran bleiben unbemerkt

local function comparable(value)
  if ns.IsSecret(value) then return SECRET end
  return value
end

-- Hat sich der eingelesene Stand gegenüber dem letzten geändert? Merkt sich dabei den neuen.
local function updateSignature(list)
  local changed = #list * 3 ~= signatureLength
  local slot = 0
  for index = 1, #list do
    local aura = list[index]
    local a, b, c = aura.spellId, comparable(aura.expirationTime), comparable(aura.applications)
    if signature[slot + 1] ~= a or signature[slot + 2] ~= b or signature[slot + 3] ~= c then changed = true end
    signature[slot + 1], signature[slot + 2], signature[slot + 3] = a, b, c
    slot = slot + 3
  end
  for index = signatureLength, slot + 1, -1 do signature[index] = nil end
  signatureLength = slot
  return changed
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

local function noteReadable(readable)
  if readable ~= readableBefore then
    readableBefore = readable
    version = version + 1
  end
end

-- Schnappschuss der Buffs oder nil, wenn der Client Auren verbirgt
function Auras.Snapshot()
  if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex or Auras.Restricted() then
    snapshotValid = false
    noteReadable(false)
    return nil
  end
  if snapshotValid and GetTime() - snapshotAt <= Auras.MAX_SNAPSHOT_AGE then return snapshot end
  snapshotValid = readBuffs()
  snapshotAt = GetTime()
  noteReadable(snapshotValid)
  if snapshotValid and updateSignature(snapshot.list) then version = version + 1 end
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

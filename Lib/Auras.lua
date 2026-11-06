-- Buffs des Spielers lesen, mit den Vorsichtsmaßnahmen aller Clients: In Retail und WoW Forever sind Auren
-- bei Kampf-, Bosskampf-, Mythisch+- oder PvP-Beschränkungen geheim; GetAuraDataByIndex bricht dann für
-- Addons mit einem Fehler ab (RequiresUnitAuraAccess, im Spiel beim Bosskampf gemeldet).
-- C_Secrets.ShouldAurasBeSecret sagt das vorher. Jede Abfrage liefert nil, wenn sich nichts feststellen lässt
-- (nicht gleichbedeutend mit "kein Buff").
local _, ns = ...

local Auras = {}
ns.Auras = Auras

local MAX_AURAS = 40

function Auras.Restricted()
  return C_Secrets ~= nil and C_Secrets.ShouldAurasBeSecret ~= nil and C_Secrets.ShouldAurasBeSecret()
end

-- Geht die Buffs des Spielers durch; visit(aura) liefert true zum Abbrechen.
-- Rückgabe: true, wenn gelesen (vollständig oder bis zum Abbruch), nil wenn der Client Auren verbirgt.
function Auras.ForEachBuff(visit)
  if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex or Auras.Restricted() then return nil end
  for index = 1, MAX_AURAS do
    -- Geschützt, falls die Beschränkung zwischen Prüfung und Abfrage beginnt
    local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", index, "HELPFUL")
    if not ok then return nil end
    if not aura then return true end
    if ns.IsSecret(aura.name) or ns.IsSecret(aura.spellId) then return nil end
    if visit(aura) then return true end
  end
  return true
end

-- true/false, ob ein Buff mit matches(aura) aktiv ist; nil, wenn der Client Auren verbirgt
function Auras.Has(matches)
  local found = false
  local read = Auras.ForEachBuff(function(aura)
    if matches(aura) then
      found = true
      return true
    end
  end)
  if read == nil then return nil end
  return found
end

-- { [spellId] = aura } der aktiven Buffs unter den gesuchten Spell-IDs; nil, wenn der Client Auren verbirgt
function Auras.FindBySpellIds(spellIds)
  local wanted, found = {}, {}
  for _, spellId in ipairs(spellIds) do wanted[spellId] = true end
  local read = Auras.ForEachBuff(function(aura)
    if wanted[aura.spellId] then found[aura.spellId] = aura end
  end)
  if read == nil then return nil end
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

-- Umkehrbares Setzen von CVars (Komfort-Einstellungen). Beim ersten Überschreiben wird der Wert des Spielers gemerkt
-- und gespeichert, damit er auch nach /reload oder einem neuen Login zurückkommt, wenn die Einstellung ausgeht.
--   CVars.Override(name, value, scope, assumedOriginal)  setzt value; merkt vorher das Original (nur beim ersten Mal)
--   CVars.Restore(name, scope)                           setzt das gemerkte Original zurück und vergisst es; ohne
--                                                         gemerktes Original passiert nichts (nie ändern, wenn aus)
-- scope: CVars.ACCOUNT (Standard, LevelTimerDB.cvarOriginals, nicht Teil der Profile) oder CVars.CHARACTER
-- (ns.character.cvarOriginals) für CVars, die der Client je Charakter speichert.
-- assumedOriginal: Wert, der als Original gilt, wenn die CVar schon den gewünschten Wert hat und nichts gemerkt ist
-- (Daten aus Versionen, die das Original noch nicht gespeichert haben).
-- Unbekannte CVars (C_CVar.GetCVar liefert nil, z.B. in einem anderen Client) werden übergangen.
local _, ns = ...

local CVars = {}
ns.CVars = CVars

CVars.ACCOUNT = "account"
CVars.CHARACTER = "character"
CVars.STORE_KEY = "cvarOriginals"

local getCVar = C_CVar and C_CVar.GetCVar or GetCVar
local rawSetCVar = C_CVar and C_CVar.SetCVar or SetCVar
local writing = false  -- eigene Änderung läuft: CVAR_UPDATE kommt synchron, Debug-Proben übergehen das Echo

local function setCVar(name, value)
  writing = true
  local ok, err = pcall(rawSetCVar, name, value)
  writing = false
  if not ok then error(err, 0) end
end

-- true, während Level Time selbst eine CVar setzt (eigenes CVAR_UPDATE-Echo)
function CVars.IsWriting()
  return writing
end

local function owner(scope)
  if scope == CVars.CHARACTER then return ns.character end
  return ns.db
end

local function originals(scope, create)
  local data = owner(scope)
  if not data then return nil end
  if create and type(data[CVars.STORE_KEY]) ~= "table" then data[CVars.STORE_KEY] = {} end
  return data[CVars.STORE_KEY]
end

-- Der Client liefert Zahlen teils anders formatiert zurück ("2.600000" statt "2.6")
local function sameValue(a, b)
  if a == b then return true end
  local numberA, numberB = tonumber(a), tonumber(b)
  return numberA ~= nil and numberA == numberB
end

function CVars.Get(name)
  return getCVar(name)
end

function CVars.Exists(name)
  return getCVar(name) ~= nil
end

function CVars.IsOverridden(name, scope)
  local store = originals(scope)
  return store ~= nil and store[name] ~= nil
end

-- true, wenn die CVar existiert und jetzt den Wert hat
function CVars.Override(name, value, scope, assumedOriginal)
  local current = getCVar(name)
  if current == nil then return false end
  local wanted = tostring(value)
  local store = originals(scope, true)
  if not store then return false end
  if store[name] == nil then
    local alreadyOurs = sameValue(current, wanted) and assumedOriginal ~= nil
    store[name] = alreadyOurs and tostring(assumedOriginal) or current
  end
  if not sameValue(current, wanted) then
    setCVar(name, wanted)
    ns.Debug("comfort", "cvar %s = %s (original %s)", name, wanted, store[name])
  end
  return true
end

function CVars.Restore(name, scope)
  local store = originals(scope)
  local original = store and store[name]
  if original == nil then return false end
  store[name] = nil
  if next(store) == nil then owner(scope)[CVars.STORE_KEY] = nil end
  if not sameValue(getCVar(name), original) then setCVar(name, original) end
  ns.Debug("comfort", "cvar %s restored to %s", name, original)
  return true
end

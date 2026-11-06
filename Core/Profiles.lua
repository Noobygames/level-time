-- Einstellungs-Profile: benannte Sätze von Einstellungen, je Charakter eines gewählt.
-- ns.db (LevelTimerDB) bleibt der aktive Stand; Profile sind Kopien in LevelTimerDB.profiles.
-- Beim Wechsel und beim Logout wird der aktive Stand ins aktive Profil zurückgeschrieben,
-- beim Login lädt jeder Charakter sein Profil (LevelTimerDB.characterProfiles).
-- Export/Import als Text (Serializer) überträgt Profile in andere Clients oder Accounts.
local _, ns = ...
local L = ns.L
local Serializer = ns.Serializer

local Profiles = {
  DEFAULT = "Default",  -- angezeigt als L.PROFILE_DEFAULT
}
ns.Profiles = Profiles

local KIND = "profile"
-- Verwaltung der Profile selbst, gehört zu keinem Profil
-- cvarOriginals: Werte des Spielers vor unseren CVar-Änderungen (CVars.lua), gehören zum Account, nicht zum Profil
local META_KEYS = {
  profiles = true, activeProfile = true, characterProfiles = true, schemaVersion = true, cvarOriginals = true,
}

local function deepCopy(value)
  if type(value) ~= "table" then return value end
  local copy = {}
  for key, entry in pairs(value) do copy[key] = deepCopy(entry) end
  return copy
end

-- Aktuelle Einstellungen ohne Verwaltungsdaten
local function snapshot()
  local settings = {}
  for key, value in pairs(ns.db) do
    if not META_KEYS[key] then settings[key] = deepCopy(value) end
  end
  return settings
end

-- Einstellungen eines Profils in ns.db übernehmen; fehlende Werte aus den Defaults
local function load(settings)
  for key in pairs(ns.db) do
    if not META_KEYS[key] then ns.db[key] = nil end
  end
  for key, value in pairs(settings) do
    if not META_KEYS[key] then ns.db[key] = deepCopy(value) end
  end
  ns.Database.ApplySettingDefaults(ns.db)
end

local function profiles()
  ns.db.profiles = ns.db.profiles or {}
  ns.db.characterProfiles = ns.db.characterProfiles or {}
  ns.db.activeProfile = ns.db.activeProfile or Profiles.DEFAULT
  return ns.db.profiles
end

-- Aktiven Stand ins aktive Profil schreiben
local function storeActive()
  profiles()[ns.db.activeProfile] = snapshot()
end

function Profiles.GetActive()
  profiles()
  return ns.db.activeProfile
end

-- Anzeigename (das Standardprofil in der gewählten Sprache)
function Profiles.DisplayName(name)
  return name == Profiles.DEFAULT and L.PROFILE_DEFAULT or name
end

-- Eingegebener Name -> gespeicherter Name: der angezeigte Name des Standardprofils ("Standard",
-- "Par défaut", ...) meint das Standardprofil, ohne Groß-/Kleinschreibung
local function storedName(name)
  if name and name:lower() == L.PROFILE_DEFAULT:lower() then return Profiles.DEFAULT end
  return name
end

-- Namen aller Profile, Standard zuerst, sonst alphabetisch
function Profiles.GetNames()
  storeActive()
  local names = {}
  for name in pairs(profiles()) do
    if name ~= Profiles.DEFAULT then table.insert(names, name) end
  end
  table.sort(names)
  table.insert(names, 1, Profiles.DEFAULT)
  return names
end

local function assignToCharacter(name)
  profiles()
  ns.db.characterProfiles[ns.characterKey] = name
end

-- Zu einem anderen Profil wechseln; false, wenn es das Profil nicht gibt
function Profiles.Switch(name)
  name = storedName(name)
  local all = profiles()
  if not all[name] then return false end
  if name ~= ns.db.activeProfile then
    storeActive()
    load(all[name])
    ns.db.activeProfile = name
  end
  assignToCharacter(name)
  ns.Debug("profiles", "switched to %s", name)
  ns.ApplySettings()
  return true
end

-- Aktuelle Einstellungen als (neues oder vorhandenes) Profil speichern und dieses aktivieren
function Profiles.SaveAs(name)
  name = storedName(name and strtrim(name) or "")
  if name == "" then return false end
  storeActive()
  profiles()[name] = snapshot()
  ns.db.activeProfile = name
  assignToCharacter(name)
  return true
end

-- Gibt es schon ein Profil mit diesem Namen (der angezeigte Standardname zählt)?
function Profiles.Exists(name)
  return profiles()[storedName(name and strtrim(name) or "")] ~= nil
end

-- Löschen; das Standard- und das aktive Profil bleiben. Charaktere damit nutzen wieder Standard.
function Profiles.Delete(name)
  name = storedName(name)
  if name == Profiles.DEFAULT or name == Profiles.GetActive() or not profiles()[name] then return false end
  profiles()[name] = nil
  for characterKey, assigned in pairs(ns.db.characterProfiles) do
    if assigned == name then ns.db.characterProfiles[characterKey] = nil end
  end
  return true
end

function Profiles.Export(name)
  storeActive()
  local settings = profiles()[name]
  if not settings then return nil end
  return Serializer.Encode(KIND, { name = name, settings = settings })
end

-- Freier Name: "Name", sonst "Name 2", "Name 3", ...
local function freeName(name)
  local all, candidate, counter = profiles(), name, 1
  while all[candidate] do
    counter = counter + 1
    candidate = name .. " " .. counter
  end
  return candidate
end

-- Profil aus Text anlegen (nicht aktivieren). Rückgabe: Name des neuen Profils oder nil
function Profiles.Import(text)
  local data = Serializer.Decode(KIND, text)
  if type(data) ~= "table" or type(data.name) ~= "string" or data.name == ""
    or type(data.settings) ~= "table" then return nil end
  local name = freeName(storedName(data.name))  -- "Standard" meint das Standardprofil, hieße der Import sonst unerreichbar
  -- Nur bekannte Einstellungen mit passendem Typ: ein falscher Wert würde sonst bei jedem Login
  -- das Anwenden der Einstellungen abbrechen
  local settings = ns.Database.SanitizeSettings(data.settings)
  for key in pairs(META_KEYS) do settings[key] = nil end
  profiles()[name] = settings
  return name
end

-- Login: Profil des Charakters laden (vor dem ersten ApplySettings, also vor allen Fenstern).
-- Ohne eigene Wahl (oder wenn sein Profil gelöscht ist) gilt das Standardprofil, sonst würden
-- Änderungen eines neuen Charakters das zuletzt aktive Profil eines anderen überschreiben.
ns.OnLogin(function()
  local all = profiles()
  local assigned = ns.db.characterProfiles[ns.characterKey]
  if not (assigned and all[assigned]) then assigned = Profiles.DEFAULT end
  if assigned and assigned ~= ns.db.activeProfile and all[assigned] then
    storeActive()
    load(all[assigned])
    ns.db.activeProfile = assigned
    ns.Debug("profiles", "loaded profile %s for %s", assigned, ns.characterKey)
  end
  storeActive()
end)

ns.OnLogout(storeActive)

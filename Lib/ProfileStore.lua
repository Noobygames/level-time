-- Einstellungs-Profile allgemein: benannte Kopien der Einstellungen, je Charakter eines gewählt. Die Einstellungen
-- selbst bleiben der aktive Stand; Profile liegen darin unter profiles, das aktive unter activeProfile, die Wahl je
-- Charakter unter characterProfiles. Beim Wechsel und beim Speichern wird der aktive Stand ins aktive Profil
-- zurückgeschrieben. Export/Import als Text (Lib/Serializer.lua).
-- Kein Zugriff auf ns.db: alles Addon-Spezifische kommt über host (siehe ProfileStore.New).
local _, ns = ...

local ProfileStore = {}
ns.ProfileStore = ProfileStore

local KIND = "profile"  -- Kennung im Serializer-Text
-- Verwaltung der Profile selbst, gehört zu keinem Profil
local OWN_META_KEYS = { "profiles", "activeProfile", "characterProfiles", "schemaVersion" }

local deepCopy = ns.Database.CopyValue  -- Core/Database.lua lädt vorher (.toc)

-- host = {
--   db()             -> aktive Einstellungen (Tabelle, wird an Ort und Stelle geändert)
--   characterKey()   -> Schlüssel des eingeloggten Charakters
--   normalize(db)    Einstellungen eines geladenen Profils vervollständigen (alte Schlüssel, Defaults)
--   sanitize(t)      -> nur gültige Einstellungen eines Imports
--   apply()          Einstellungen anwenden
--   metaKeys         weitere Schlüssel, die zu keinem Profil gehören (Liste)
--   defaultName      gespeicherter Name des Standardprofils
--   defaultLabel()   -> angezeigter Name des Standardprofils in der gewählten Sprache
--   debug(fmt, ...)  optional: Protokollzeile
-- }
function ProfileStore.New(host)
  local store = { DEFAULT = host.defaultName }
  local metaKeys = {}
  for _, key in ipairs(OWN_META_KEYS) do metaKeys[key] = true end
  for _, key in ipairs(host.metaKeys or {}) do metaKeys[key] = true end
  local debug = host.debug or function() end

  -- Aktuelle Einstellungen ohne Verwaltungsdaten
  local function snapshot()
    local settings = {}
    for key, value in pairs(host.db()) do
      if not metaKeys[key] then settings[key] = deepCopy(value) end
    end
    return settings
  end

  -- Einstellungen eines Profils übernehmen; fehlende Werte ergänzt host.normalize
  local function load(settings)
    local db = host.db()
    for key in pairs(db) do
      if not metaKeys[key] then db[key] = nil end
    end
    for key, value in pairs(settings) do
      if not metaKeys[key] then db[key] = deepCopy(value) end
    end
    host.normalize(db)
  end

  local function profiles()
    local db = host.db()
    db.profiles = db.profiles or {}
    db.characterProfiles = db.characterProfiles or {}
    db.activeProfile = db.activeProfile or store.DEFAULT
    return db.profiles
  end

  -- Aktiven Stand ins aktive Profil schreiben
  local function storeActive()
    profiles()[host.db().activeProfile] = snapshot()
  end
  store.StoreActive = storeActive

  function store.GetActive()
    profiles()
    return host.db().activeProfile
  end

  -- Anzeigename (das Standardprofil in der gewählten Sprache)
  function store.DisplayName(name)
    return name == store.DEFAULT and host.defaultLabel() or name
  end

  -- Eingegebener Name -> gespeicherter Name: der angezeigte Name des Standardprofils ("Standard",
  -- "Par défaut", ...) meint das Standardprofil, ohne Groß-/Kleinschreibung
  local function storedName(name)
    if name and name:lower() == host.defaultLabel():lower() then return store.DEFAULT end
    return name
  end

  -- Namen aller Profile, Standard zuerst, sonst alphabetisch
  function store.GetNames()
    storeActive()
    local names = {}
    for name in pairs(profiles()) do
      if name ~= store.DEFAULT then table.insert(names, name) end
    end
    table.sort(names)
    table.insert(names, 1, store.DEFAULT)
    return names
  end

  -- Charakter-Schlüssel, die das Profil nutzen (alphabetisch): eigene Wahl oder, ohne gültige Wahl, das
  -- Standardprofil (wie LoadForCharacter). Bekannte Charaktere liefert host.characterKeys() (optional)
  function store.CharactersOf(name)
    local all = profiles()
    local assignments = host.db().characterProfiles
    local keys, seen = {}, {}
    local function consider(key)
      if seen[key] then return end
      seen[key] = true
      local assigned = assignments[key]
      if not (assigned and all[assigned]) then assigned = store.DEFAULT end
      if assigned == name then table.insert(keys, key) end
    end
    for _, key in ipairs(host.characterKeys and host.characterKeys() or {}) do consider(key) end
    for key in pairs(assignments) do consider(key) end
    table.sort(keys)
    return keys
  end

  local function assignToCharacter(name)
    profiles()
    host.db().characterProfiles[host.characterKey()] = name
  end

  -- Zu einem anderen Profil wechseln; false, wenn es das Profil nicht gibt
  function store.Switch(name)
    name = storedName(name)
    local all = profiles()
    if not all[name] then return false end
    if name ~= host.db().activeProfile then
      storeActive()
      load(all[name])
      host.db().activeProfile = name
    end
    assignToCharacter(name)
    debug("switched to %s", name)
    host.apply()
    return true
  end

  -- Aktuelle Einstellungen als (neues oder vorhandenes) Profil speichern und dieses aktivieren
  function store.SaveAs(name)
    name = storedName(name and strtrim(name) or "")
    if name == "" then return false end
    storeActive()
    profiles()[name] = snapshot()
    host.db().activeProfile = name
    assignToCharacter(name)
    return true
  end

  -- Gibt es schon ein Profil mit diesem Namen (der angezeigte Standardname zählt)?
  function store.Exists(name)
    return profiles()[storedName(name and strtrim(name) or "")] ~= nil
  end

  -- Löschbar ist jedes vorhandene Profil außer dem Standard- und dem aktiven
  function store.CanDelete(name)
    name = storedName(name or "")
    return name ~= store.DEFAULT and name ~= store.GetActive() and profiles()[name] ~= nil
  end

  -- Löschen; das Standard- und das aktive Profil bleiben. Charaktere damit nutzen wieder Standard.
  function store.Delete(name)
    if not store.CanDelete(name) then return false end
    name = storedName(name)
    profiles()[name] = nil
    local assignments = host.db().characterProfiles
    for characterKey, assigned in pairs(assignments) do
      if assigned == name then assignments[characterKey] = nil end
    end
    return true
  end

  function store.Export(name)
    storeActive()
    local settings = profiles()[name]
    if not settings then return nil end
    return ns.Serializer.Encode(KIND, { name = name, settings = settings })
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
  function store.Import(text)
    local data = ns.Serializer.Decode(KIND, text)
    if type(data) ~= "table" or type(data.name) ~= "string" or data.name == ""
      or type(data.settings) ~= "table" then return nil end
    local name = freeName(storedName(data.name))  -- "Standard" meint das Standardprofil, hieße der Import sonst unerreichbar
    -- Nur bekannte Einstellungen mit passendem Typ: ein falscher Wert würde sonst bei jedem Login
    -- das Anwenden der Einstellungen abbrechen
    local settings = host.sanitize(data.settings)
    for key in pairs(metaKeys) do settings[key] = nil end
    profiles()[name] = settings
    return name
  end

  -- Login: Profil des Charakters laden (vor dem ersten Anwenden der Einstellungen).
  -- Ohne eigene Wahl (oder wenn sein Profil gelöscht ist) gilt das Standardprofil, sonst würden
  -- Änderungen eines neuen Charakters das zuletzt aktive Profil eines anderen überschreiben.
  function store.LoadForCharacter()
    local all = profiles()
    local db = host.db()
    local assigned = db.characterProfiles[host.characterKey()]
    if not (assigned and all[assigned]) then assigned = store.DEFAULT end
    if assigned and assigned ~= db.activeProfile and all[assigned] then
      storeActive()
      load(all[assigned])
      db.activeProfile = assigned
      debug("loaded profile %s for %s", assigned, host.characterKey())
    end
    storeActive()
  end

  return store
end

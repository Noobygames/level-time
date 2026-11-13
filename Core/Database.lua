-- Gespeicherte Daten:
--   LevelTimerDB       Account: Einstellungen
--   LevelTimerStatsDB  Account: Statistiken, je Charakter ("Name-Realm") getrennt
--   LevelTimerCharDB   veraltet (pro Charakter); wird beim Login in LevelTimerStatsDB übernommen
local _, ns = ...

local Database = {}
ns.Database = Database

local SETTINGS_DEFAULTS = {
  language = ns.DefaultLanguage(),
  minimap = { hide = false, angle = 225 },
  -- Einstellungsfenster: true = alle Bausteine, false = Modus "Einfach" (Roadmap 402). Neue Installationen starten
  -- einfach (UX S1); wer den Schlüssel noch nicht gespeichert hat, aber schon Einstellungen hat, behält "alle"
  -- (keepAllOptionsForExisting)
  optionsAdvanced = false,
}

-- Zähler für Level und Session gleichermaßen. Schlüssel siehe Stats.lua; Module melden ihre Zähler selbst an
-- (Database.RegisterDefaults).
local COUNTER_DEFAULTS = {}

local CHARACTER_DEFAULTS = {
  currentLevel = {
    level = 0,    -- Level, auf das sich die Zähler beziehen
    seconds = 0,  -- letzte bekannte Spielzeit auf dem Level (für die Anzeige anderer Charaktere)
    xp = 0,       -- letzte bekannte XP auf dem Level
    counters = COUNTER_DEFAULTS,
  },
  currentSession = {
    seconds = 0,  -- gespielte Zeit bis zum letzten Logout; startedAt fehlt, solange keine Session lief
    counters = COUNTER_DEFAULTS,
  },
  levelHistory = {},    -- abgeschlossene Level, Schlüssel = Level
  sessionHistory = {},  -- beendete Sessions, älteste zuerst
  killLog = {},         -- getötete Kreaturen und Spieler, älteste zuerst (siehe Journal.lua)
  deathLog = {},        -- eigene Tode mit Ursache, älteste zuerst (siehe Journal.lua)
  questLog = {},        -- abgegebene Quests, älteste zuerst (siehe Journal.lua)
  instanceLog = {},     -- beendete Instanz-Läufe, älteste zuerst (siehe Instances.lua)
  instanceVisits = {},  -- zuletzt betretene Instanz-Kopie je Name: { zoneUID, leftAt } (siehe InstanceCopy.lua)
  lootLog = {},         -- seltene und bessere Beute, älteste zuerst (siehe Loot.lua)
  nearDeathLog = {},    -- Beinahe-Tode, älteste zuerst (siehe NearDeath.lua)
  rollLog = {},         -- abgeschlossene Gruppen-Würfe um Beute, älteste zuerst (siehe RollLog.lua)
  zoneStats = {},       -- Spielzeit, XP, Kills und Tode je Zone (siehe Zones.lua)
  questStarts = {},     -- /played bei Annahme je Quest-ID, bis zur Abgabe (QuestSplits.lua)
  customSplits = {},    -- eigene Splits { name, played, time, level }, älteste zuerst (CustomSplits.lua)
  ssfLogouts = 0,       -- echte Logouts seit Beginn der Aufzeichnung (SSF-Regelhelfer, SsfRules.lua)
  dailyStats = {},      -- Tageswerte, Schlüssel "JJJJ-MM-TT" (siehe Daily.lua)
}

-- Migrationen für die Daten eines Charakters, Schlüssel = Zielversion.
-- Laufen auch für frische (leere) Daten und müssen daher fehlende Felder vertragen.
Database.CHARACTER_SCHEMA_VERSION = 5

-- Tageseintrag für die Migrationen v4/v5, ohne Fachmodul (Daily.lua lädt später und gehört zur Historie). Form und
-- Schlüssel wie Daily.Entry/Daily.DayKey zum Zeitpunkt der Migration; Daily ergänzt später fehlende Felder.
local MIGRATION_DAY_FIELDS = { seconds = 0, kills = 0, deaths = 0, xp = 0, moneyIn = 0, moneyOut = 0 }
local DAY_KEY_FORMAT = "%Y-%m-%d"

local function migrationDayEntry(dailyStats, timestamp)
  local key = date(DAY_KEY_FORMAT, timestamp)
  local entry = dailyStats[key] or {}
  for field, default in pairs(MIGRATION_DAY_FIELDS) do
    entry[field] = entry[field] or default
  end
  dailyStats[key] = entry
  return entry
end

local characterMigrations = {
  [2] = function(data)  -- kills (nur PvE) -> counters.pveKills
    data.counters = data.counters or {}
    data.counters.pveKills = data.kills
    data.kills = nil
  end,
  [3] = function(data)  -- flache Level-Daten -> currentLevel + levelHistory (Sessions sind neu)
    data.currentLevel = { level = data.level, counters = data.counters }
    data.levelHistory = data.history
    data.level, data.counters, data.history = nil, nil, nil
  end,
  [4] = function(data)  -- Tageswerte neu: Spielzeit bisheriger Sessions ihrem Starttag zuordnen
    data.dailyStats = data.dailyStats or {}
    for _, session in ipairs(data.sessionHistory or {}) do
      if session.startedAt and session.seconds then
        local entry = migrationDayEntry(data.dailyStats, session.startedAt)
        entry.seconds = entry.seconds + session.seconds
      end
    end
  end,
  [5] = function(data)  -- Tageswerte zählen Kills und Tode: aus dem vorhandenen Journal übernehmen
    data.dailyStats = data.dailyStats or {}
    for _, kill in ipairs(data.killLog or {}) do
      local entry = migrationDayEntry(data.dailyStats, kill.time)
      entry.kills = entry.kills + 1
    end
    for _, death in ipairs(data.deathLog or {}) do
      local entry = migrationDayEntry(data.dailyStats, death.time)
      entry.deaths = entry.deaths + 1
    end
  end,
}

-- Migrationen für die Einstellungen, Schlüssel = Zielversion
local SETTINGS_SCHEMA_VERSION = 8
local OLD_DEFAULT_FONT_SIZE = 16

-- Wendet fn auf die Einstellungen und alle darin gespeicherten Kopien an (Profile, Stream-Sicherung)
local function forEachSettingsCopy(settings, fn)
  fn(settings)
  for _, profile in pairs(settings.profiles or {}) do
    if type(profile) == "table" then fn(profile) end
  end
  if type(settings.streamBackup) == "table" then fn(settings.streamBackup) end
end

local settingsMigrations = {
  [2] = function(settings)  -- feste Schriftgröße der Zeitanzeige -> Skalierung des ganzen Fensters
    forEachSettingsCopy(settings, function(values)
      if values.fontSize then
        values.scale = values.fontSize / OLD_DEFAULT_FONT_SIZE
      end
      values.fontSize = nil
    end)
  end,
  -- Zeilen mit mehreren Werten wurden aufgeteilt; neue Schalter übernehmen den alten Zustand:
  -- Kills -> PvE + PvP, XP/h -> + Zeit bis Level-Up, Tode -> + Kills pro Tod
  [3] = function(settings)
    forEachSettingsCopy(settings, function(values)
      if values.showKills ~= nil then
        values.showPveKills = values.showKills
        values.showPvpKills = values.showKills
      end
      if values.showXpRate ~= nil then
        values.showLevelEta = values.showXpRate
      end
      if values.showDeaths ~= nil then
        values.showKillsPerDeath = values.showDeaths
      end
      values.showKills = nil
    end)
  end,
  -- Level-Up-Ansage in /sagen entfernt (kam außerhalb von Instanzen nicht an): aus, auch in Profilen
  [4] = function(settings)
    forEachSettingsCopy(settings, function(values)
      if values.levelUpAnnounce == "say" then values.levelUpAnnounce = "off" end
    end)
  end,
  -- "Kills/Quests bis Level-Up" aufgeteilt (wer keine Quests macht, will die Zeile nicht sehen): beide übernehmen den alten Zustand
  [5] = function(settings)
    forEachSettingsCopy(settings, function(values)
      if values.showCountToLevel ~= nil then
        values.showKillsToLevel = values.showCountToLevel
        values.showQuestsToLevel = values.showCountToLevel
      end
      values.showCountToLevel = nil
    end)
  end,
  -- Ein Positionssystem (Lib/Frames.lua): xxxPos/xxxScale je Anzeige -> frames[id]. Die Stream-Sicherung verliert
  -- sie nur (ältere Versionen sicherten dort die Größe; zurückgespielt würde frames sonst alle Positionen ersetzen)
  [6] = function(settings)
    forEachSettingsCopy(settings, function(values)
      Database.MoveLegacyFrameKeys(values)
      if values == settings.streamBackup then values.frames = nil end
    end)
  end,
  -- Eine Anordnung statt zweier Schalter (windowLayout): horizontalLayout -> "bar", compactMode -> "compact"
  [7] = function(settings)
    forEachSettingsCopy(settings, function(values) Database.MoveLegacyLayoutKeys(values) end)
  end,
  -- Neuer Standard-Glitzerstil "finder" (Zielsucher): bisher wurde der alte Standard "aura" mit abgespeichert, eine
  -- ausdrückliche Wahl ist davon nicht zu unterscheiden. "aura" wird deshalb einmalig auf den neuen Standard gesetzt;
  -- jede andere Wahl bleibt, und "aura" bleibt danach unter "Klassisch" wählbar.
  [8] = function(settings)
    forEachSettingsCopy(settings, function(values)
      if values.lootSparkleStyle == "aura" then values.lootSparkleStyle = "finder" end
    end)
  end,
}

-- Migrationen und Defaults allgemein in Lib/Migrate.lua
local migrate = ns.Migrate.Run
local applyDefaults = ns.Migrate.ApplyDefaults

local function isFiniteNumber(value)
  return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Gültige Ankerpunkte (FramePoint): SetPoint mit etwas anderem wirft bei jedem Anwenden einen Fehler
local FRAME_POINTS = {
  TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
  BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

-- Einstellungen ohne Default, mit Prüfung ihrer Form
local function isPosition(value)
  return type(value) == "table" and FRAME_POINTS[value[1]] == true and FRAME_POINTS[value[2]] == true
    and isFiniteNumber(value[3]) and isFiniteNumber(value[4])
end

local function isLevelTimes(value)
  if type(value) ~= "table" then return false end
  for level, seconds in pairs(value) do
    if type(level) ~= "number" or not isFiniteNumber(seconds) or seconds <= 0 then return false end
  end
  return true
end

-- Erlaubte Bereiche von Zahlen-Einstellungen (wie die Regler und Fenster sie vorgeben); Importe werden begrenzt.
-- Module melden ihre Bereiche selbst an (Database.RegisterDefaults).
local SETTING_RANGES = {}

local OPTIONAL_SETTINGS = {
  frames = function(value)  -- Position und Größe je Anzeige (Lib/Frames.lua), Id -> Eintrag
    if type(value) ~= "table" then return false end
    for id, entry in pairs(value) do  -- ungültige Einträge einzeln entfernen, gültige behalten
      value[id] = type(id) == "string" and Database.SanitizeFrameEntry(entry) or nil
    end
    return true
  end,
  hiddenBlizzardFrames = function(value)  -- ausgeblendete Blizzard-Elemente (BlizzardHide.lua), Id -> true
    if type(value) ~= "table" then return false end
    local BlizzardHide = ns.BlizzardHide  -- lädt später; beim Laden der Daten genügt die Form
    for id, hidden in pairs(value) do  -- unbekannte Ids und andere Werte einzeln entfernen
      if type(id) ~= "string" or hidden ~= true or (BlizzardHide and not BlizzardHide.IsOwnId(id)) then
        value[id] = nil
      end
    end
    return true
  end,
  movedFrames = function(value)  -- gemerkte Fensterpositionen (MoveFrames.lua), Name -> Position
    if type(value) ~= "table" then return false end
    for name, pos in pairs(value) do  -- ungültige Einträge einzeln entfernen, gültige behalten
      if type(name) ~= "string" or not isPosition(pos) then value[name] = nil end
    end
    return true
  end,
  movedFrameScales = function(value)  -- gemerkte Fenstergrößen (MoveFrames.lua), Name -> Faktor
    if type(value) ~= "table" then return false end
    for name, scale in pairs(value) do
      if type(name) ~= "string" or not isFiniteNumber(scale) or scale <= 0 then value[name] = nil end
    end
    return true
  end,
  presetBackup = function(value)  -- Zeilen vor der letzten Voreinstellung (StatLines.lua), Einstellung -> an/aus
    if type(value) ~= "table" then return false end
    for key, on in pairs(value) do
      if type(key) ~= "string" or type(on) ~= "boolean" then value[key] = nil end
    end
    return true
  end,
  splitReference = function(value)  -- fester Vergleichslauf (Splits.lua)
    return type(value) == "table" and type(value.name) == "string" and isLevelTimes(value.times)
  end,
}

local sanitizeSettings

-- Ein Eintrag von db.frames: { point, relPoint, x, y, scale }; Position nur vollständig und gültig, Größe begrenzt.
-- nil, wenn nichts Gültiges bleibt
local FRAME_SCALE_RANGE = { 0.5, 2 }  -- wie Frames.MIN_SCALE/MAX_SCALE (Lib/Frames.lua lädt später)

function Database.SanitizeFrameEntry(entry)
  if type(entry) ~= "table" then return nil end
  local clean = {}
  if FRAME_POINTS[entry.point] and FRAME_POINTS[entry.relPoint] and isFiniteNumber(entry.x) and isFiniteNumber(entry.y) then
    clean.point, clean.relPoint, clean.x, clean.y = entry.point, entry.relPoint, entry.x, entry.y
  end
  if isFiniteNumber(entry.scale) then
    clean.scale = math.max(FRAME_SCALE_RANGE[1], math.min(FRAME_SCALE_RANGE[2], entry.scale))
  end
  return next(clean) and clean or nil
end

-- Frühere Schlüssel je Anzeige (Position als { Punkt, Bezugspunkt, x, y } und eigene Größe) -> frames[id]
local LEGACY_FRAME_KEYS = {
  { id = "main", pos = "pos", scale = "scale" },
  { id = "splitList", pos = "splitListPos", scale = "splitListScale" },
  { id = "alert", pos = "alertPos", scale = "alertScale" },
  { id = "levelUp", pos = "levelUpPos", scale = "levelUpScale" },
  { id = "camp", pos = "campPos", scale = "campScale" },
  { id = "food", pos = "foodPos", scale = "foodScale" },
  { id = "flight", pos = "flightPos", scale = "flightScale" },
  { id = "questItem", pos = "questItemPos" },
}

-- Alte Schlüssel einmal lesen und löschen; ein schon vorhandener Eintrag in frames gewinnt. Läuft in der Migration
-- (auch für Profile und die Stream-Sicherung), beim Import und beim Laden eines Profils.
function Database.MoveLegacyFrameKeys(values)
  for _, legacy in ipairs(LEGACY_FRAME_KEYS) do
    local pos, scale = values[legacy.pos], legacy.scale and values[legacy.scale]
    if pos ~= nil or scale ~= nil then
      local frames = type(values.frames) == "table" and values.frames or {}
      local existing = frames[legacy.id]
      local entry = type(existing) == "table" and existing or {}
      if isPosition(pos) and entry.point == nil then
        entry.point, entry.relPoint, entry.x, entry.y = pos[1], pos[2], pos[3], pos[4]
      end
      if entry.scale == nil then entry.scale = scale end
      frames[legacy.id] = Database.SanitizeFrameEntry(entry)
      if next(frames) then values.frames = frames end
    end
    values[legacy.pos] = nil
    if legacy.scale then values[legacy.scale] = nil end
  end
end

-- Frühere Schalter der Anordnung (bis Settings-Schema 6) -> windowLayout; ein schon gesetztes windowLayout gewinnt.
-- Läuft in der Migration, beim Import und beim Laden eines Profils (wie MoveLegacyFrameKeys).
function Database.MoveLegacyLayoutKeys(values)
  if values.windowLayout == nil then
    if values.horizontalLayout == true then
      values.windowLayout = "bar"
    elseif values.compactMode == true then
      values.windowLayout = "compact"
    end
  end
  values.horizontalLayout = nil
  values.compactMode = nil
end

-- Alle Umzüge alter Schlüssel (Positionen, Anordnung)
function Database.MoveLegacyKeys(values)
  Database.MoveLegacyFrameKeys(values)
  Database.MoveLegacyLayoutKeys(values)
end

-- Ein Wert passt, wenn er den Typ des Defaults hat (verschachtelt geprüft) bzw. die Form einer
-- optionalen Einstellung
local function sanitizeValue(key, value)
  local default = SETTINGS_DEFAULTS[key]
  if default == nil then
    if key == "streamBackup" then  -- frühere Werte der Stream-Einstellungen (StreamMode.lua), nie Positionen
      if type(value) ~= "table" then return nil end
      local backup = sanitizeSettings(value)
      backup.frames = nil
      return backup
    end
    local check = OPTIONAL_SETTINGS[key]
    if not (check and check(value)) then return nil end
    local range = SETTING_RANGES[key]
    if range and type(value) == "number" then return math.max(range[1], math.min(range[2], value)) end
    return value
  end
  if type(value) ~= type(default) then return nil end
  if type(value) == "number" then
    if not isFiniteNumber(value) then return nil end
    local range = SETTING_RANGES[key]
    if range then return math.max(range[1], math.min(range[2], value)) end
  end
  if type(default) == "table" and next(default) ~= nil then
    local copy = {}
    for innerKey, innerDefault in pairs(default) do
      local inner = value[innerKey]
      if type(inner) == type(innerDefault) then copy[innerKey] = inner end
    end
    return copy
  end
  return value
end

-- Nur bekannte Einstellungen mit passendem Typ, z.B. aus einem importierten Profil
function sanitizeSettings(settings)
  local source = {}  -- Kopie: alte Positions-Schlüssel (Profile älterer Versionen) ziehen nach frames um
  for key, value in pairs(settings) do source[key] = value end
  Database.MoveLegacyKeys(source)
  local clean = {}
  for key, value in pairs(source) do
    if type(key) == "string" then clean[key] = sanitizeValue(key, value) end
  end
  return clean
end
Database.SanitizeSettings = sanitizeSettings

-- Fehlende Einstellungen mit Defaults füllen (z.B. nach dem Laden eines Profils)
-- Tiefe Kopie (Tabellen der Einstellungen), andere Werte unverändert
function Database.CopyValue(value)
  if type(value) ~= "table" then return value end
  local copy = {}
  for key, inner in pairs(value) do copy[key] = Database.CopyValue(inner) end
  return copy
end

-- Standardwert einer Einstellung als eigene Kopie (Zurücksetzen je Unterseite der Einstellungen)
function Database.SettingDefault(key)
  return Database.CopyValue(SETTINGS_DEFAULTS[key])
end

function Database.ApplySettingDefaults(settings)
  return applyDefaults(settings, SETTINGS_DEFAULTS)
end

function Database.NewCounters()
  return applyDefaults({}, COUNTER_DEFAULTS)
end

-- Module melden eigene Standardwerte beim Laden an (vor dem Login, also vor Database.Load):
-- defaults = { settings = { Schlüssel = Standard }, ranges = { Schlüssel = { min, max } }, counters = { ... } }.
-- Ein Schlüssel darf nur einmal vorkommen (hier oder in einem Modul); doppelt ist ein Fehler beim Laden.
function Database.RegisterDefaults(defaults)
  for key, value in pairs(defaults.settings or {}) do
    assert(SETTINGS_DEFAULTS[key] == nil, "setting default registered twice: " .. key)
    SETTINGS_DEFAULTS[key] = value
  end
  for key, range in pairs(defaults.ranges or {}) do
    assert(SETTING_RANGES[key] == nil, "setting range registered twice: " .. key)
    SETTING_RANGES[key] = range
  end
  for key, value in pairs(defaults.counters or {}) do
    assert(COUNTER_DEFAULTS[key] == nil, "counter default registered twice: " .. key)
    COUNTER_DEFAULTS[key] = value
  end
end
ns.RegisterDefaults = Database.RegisterDefaults

-- Erster Start des Addons auf diesem Account (LevelTimerStatsDB.introShown noch nicht gesetzt)?
function Database.IsFirstStart()
  return not LevelTimerStatsDB.introShown
end

-- Wie IsFirstStart, merkt sich den Start aber: true genau einmal
function Database.TakeFirstStart()
  if not Database.IsFirstStart() then return false end
  LevelTimerStatsDB.introShown = true
  return true
end

-- Flache Kopie eines Zählersatzes (Stats.Snapshot, Stand eines Instanz-Laufs)
function Database.CopyCounters(counters)
  local copy = {}
  for counter, value in pairs(counters) do
    copy[counter] = value
  end
  return copy
end

function Database.CharacterKey(name, realm)
  return name .. "-" .. realm
end

-- Neu erstellter Charakter mit dem Namen eines gelöschten: andere GUID als gespeichert; ältere Daten ohne GUID:
-- gespeichertes Level höher als das aktuelle (unsicher bei einem Level-Squish, daher die GUID). Zuhörer
-- (Runs.lua, JournalArchive.lua) bekommen Daten und Schlüssel: sichern den alten Versuch bzw. löschen sein Archiv,
-- dann beginnen die Daten neu.
local replacedListeners = {}

function Database.OnCharacterReplaced(listener)
  table.insert(replacedListeners, listener)
end

-- GUID des Spielers; nil, wenn unbekannt oder geheim
local function playerGuid()
  local guid = UnitGUID("player")
  if ns.IsSecret(guid) then return nil end
  return guid
end

local function isReplacedCharacter(data, guid)
  if data.guid and guid then return data.guid ~= guid end
  local savedLevel = data.currentLevel and data.currentLevel.level
  return savedLevel ~= nil and savedLevel > UnitLevel("player")
end

-- Neue Daten erben die gemerkten CVar-Originale (Lib/CVars.lua), sonst bleiben unsere Werte für immer gesetzt
local function freshCharacterData(old)
  local originals = old and old.cvarOriginals
  return { cvarOriginals = type(originals) == "table" and originals or nil }
end

-- Migration und Defaults eines Eintrags; false, wenn er defekt ist (Fehler geht an den Fehler-Handler)
local function upgradeCharacter(data)
  return xpcall(function()
    migrate(data, characterMigrations, Database.CHARACTER_SCHEMA_VERSION)
    applyDefaults(data, CHARACTER_DEFAULTS)
  end, geterrorhandler())
end

-- Daten des eingeloggten Charakters holen oder anlegen. Alte Daten aus
-- LevelTimerCharDB werden dabei einmalig übernommen und durchlaufen dieselben Migrationen.
local function loadCharacter(stats)
  local name, realm = UnitName("player"), GetRealmName()
  local key = Database.CharacterKey(name, realm)

  local guid = playerGuid()
  local data = stats.characters[key]
  local inherited
  if data and isReplacedCharacter(data, guid) then
    for _, listener in ipairs(replacedListeners) do
      ns.SafeCall(listener, data, key)
    end
    inherited = freshCharacterData(data)
    data = nil
  end
  if not data then
    data = LevelTimerCharDB or inherited or {}
    stats.characters[key] = data
  end
  LevelTimerCharDB = nil

  -- Defekter Eintrag darf den Login nicht abbrechen: der Charakter beginnt neu
  if not upgradeCharacter(data) then
    data = freshCharacterData(data)
    stats.characters[key] = data
    upgradeCharacter(data)
  end

  data.guid = guid or data.guid
  data.name, data.realm = name, realm
  data.class = select(2, UnitClass("player"))
  return key, data
end

-- Bestehende Einstellungen ohne optionsAdvanced stammen aus der Zeit, als "alle Optionen" der Standard war:
-- dabei bleiben (auch in gespeicherten Profilen), nur neue Installationen starten im Modus "Einfach". Die
-- Stream-Sicherung bleibt außen vor: sie enthält nur Stream-Werte und spielt beim Ausschalten alles zurück
local function keepAllOptionsForExisting(settings)
  if next(settings) == nil then return end
  local function keep(values)
    if values.optionsAdvanced == nil then values.optionsAdvanced = true end
  end
  keep(settings)
  for _, profile in pairs(type(settings.profiles) == "table" and settings.profiles or {}) do
    if type(profile) == "table" then keep(profile) end
  end
end

-- Erst ab PLAYER_LOGIN aufrufen, vorher hat der Client die SavedVariables nicht geladen.
-- Rückgabe: Einstellungen, Schlüssel und Daten des eingeloggten Charakters.
function Database.Load()
  LevelTimerDB = LevelTimerDB or {}
  keepAllOptionsForExisting(LevelTimerDB)
  migrate(LevelTimerDB, settingsMigrations, SETTINGS_SCHEMA_VERSION)
  applyDefaults(LevelTimerDB, SETTINGS_DEFAULTS)
  LevelTimerStatsDB = applyDefaults(LevelTimerStatsDB or {}, { characters = {} })
  -- Auch andere Charaktere auf den aktuellen Stand bringen: die Historie zeigt sie, und Daten aus
  -- älteren Versionen haben sonst Lücken (z.B. fehlende Journale)
  -- Ein defekter Eintrag darf nicht alle Module lahmlegen: Fehler melden, Charakter überspringen
  for _, data in pairs(LevelTimerStatsDB.characters) do
    upgradeCharacter(data)
  end
  local characterKey, character = loadCharacter(LevelTimerStatsDB)
  return LevelTimerDB, characterKey, character
end

function Database.GetCharacters()
  return LevelTimerStatsDB.characters
end

-- Entfernt alle Statistiken eines Charakters (Einstellungen bleiben unberührt)
-- Zuhörer (JournalArchive.lua) löschen, was sie zu dem Charakter außerhalb von LevelTimerStatsDB speichern
local deletedListeners = {}

function Database.OnCharacterDeleted(listener)
  table.insert(deletedListeners, listener)
end

function Database.DeleteCharacter(characterKey)
  local characters = LevelTimerStatsDB.characters
  -- Eingeloggter Charakter beginnt sofort neu (ns.DeleteCharacter) und behält seine CVar-Originale
  characters[characterKey] = characterKey == ns.characterKey and freshCharacterData(characters[characterKey]) or nil
  for _, listener in ipairs(deletedListeners) do
    ns.SafeCall(listener, characterKey)
  end
end

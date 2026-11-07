-- Kern von Level Time Goals: bindet die Bausteine von Level Time (LevelTimerAPI) und lädt die gespeicherten Daten.
-- Das Addon hängt per "## Dependencies: LevelTimer" von Level Time ab; Ereignisse, Login, Karten, Fenster,
-- Tabellen und Texte kommen von dort, hier liegt nur, was zu den Zielen gehört.
--
-- Gespeichert wird in StreamGoalDB (Account): { schemaVersion, nextId, goals = { Ziel, ... }, packs, settings }.
-- Es existiert erst ab PLAYER_LOGIN (ns.OnLogin), vorher nie anfassen.
local _, ns = ...

local LT = LevelTimerAPI
ns.LT = LT
ns.L = LT.L
ns.DISPLAY_NAME = "Level Time Goals"

local PREFIX = "|cfff4c95d" .. ns.DISPLAY_NAME .. ":|r "

function ns.Print(message)
  print(PREFIX .. message)
end

-- Technische Zeile für /lt debug (Bereich "goal:<area>")
function ns.Debug(area, format, ...)
  LT.Debug("goal:" .. area, format, ...)
end

ns.SCHEMA_VERSION = 1
-- Einstellungen in StreamGoalDB.settings (Seite im Einstellungsfenster: Options.lua); Position und Größe des Trackers
-- stehen in settings.frame (Lib/Frames.lua von Level Time)
ns.SETTING_DEFAULTS = {
  showTracker = true,
  sound = true,          -- Ton beim Erreichen
  doneAlert = true,      -- Einblendung von Level Time beim Erreichen
  doneChat = true,       -- Chatzeile beim Erreichen
  maxCards = 6,          -- so viele Karten zeigt der Tracker, der Rest als "+n weitere"
  cardColors = "kind",   -- "kind" = Farbe der Zielart, "accent" = Akzentfarbe des Themes für alle
}
ns.MIN_CARDS, ns.MAX_CARDS = 1, 6

-- Nach jeder Änderung der Einstellungen (und bei Sprach- oder Theme-Wechsel in Level Time): Anzeigen neu aufbauen
local applyListeners = {}

function ns.RegisterApply(listener)
  table.insert(applyListeners, listener)
end

function ns.ApplySettings()
  if not ns.db then return end
  for _, listener in ipairs(applyListeners) do LT.SafeCall(listener) end
end

-- Einstellung ändern; unveränderte Werte lösen kein Neuaufbauen aus
function ns.SetSetting(key, value)
  local settings = ns.db.settings
  if settings[key] == value then return end
  settings[key] = value
  ns.Debug("settings", "%s = %s", key, value)
  ns.ApplySettings()
end

function ns.SettingDefault(key)
  return ns.SETTING_DEFAULTS[key]
end

local function fillDefaults(target, defaults)
  for key, value in pairs(defaults) do
    if target[key] == nil then target[key] = value end
  end
end

-- Läuft bei jedem Login (und nach ns.DeleteCharacter erneut): fehlende Felder ergänzen, nie überschreiben
LT.OnLogin(function()
  StreamGoalDB = StreamGoalDB or {}
  local db = StreamGoalDB
  db.schemaVersion = math.max(db.schemaVersion or 0, ns.SCHEMA_VERSION)
  db.nextId = db.nextId or 1
  db.goals = db.goals or {}
  db.packs = type(db.packs) == "table" and db.packs or {}  -- eigene Vorlagen (Packs.lua)
  db.settings = db.settings or {}
  fillDefaults(db.settings, ns.SETTING_DEFAULTS)
  -- Früher pos = { Punkt, Bezugspunkt, x, y } und scale; jetzt ein Eintrag wie bei Level Time (Lib/Frames.lua)
  local settings = db.settings
  if settings.pos ~= nil or settings.scale ~= nil then
    local pos = type(settings.pos) == "table" and settings.pos or {}
    settings.frame = settings.frame or LT.Database.SanitizeFrameEntry({
      point = pos[1], relPoint = pos[2], x = pos[3], y = pos[4], scale = settings.scale,
    })
    settings.pos, settings.scale = nil, nil
  end
  ns.db = db
end)

LT.RegisterApply(function() ns.ApplySettings() end)

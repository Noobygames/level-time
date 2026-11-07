-- Kern von Level Time: Namen, Schnittstelle für Schwester-Addons, was beim Login geladen wird, Löschen eines
-- Charakters und der Level-Up-Ablauf. Die allgemeinen Bausteine (Events, Apply, Login-Callbacks) stehen in
-- Lib/Lifecycle.lua.
local _, ns = ...

-- Name, den Spieler sehen (CurseForge-Projekt, Addon-Liste, Fenster, Chat). Technische Namen
-- (Ordner, .toc, SavedVariables, Frame-Namen, /lt) bleiben LevelTimer, sonst gingen Daten verloren.
ns.DISPLAY_NAME = "Level Time"

-- Technische Addon-Id: Grundlage aller globalen Namen (Rahmen, StaticPopup-Schlüssel, LDB-Objekt, Addon-Nachrichten).
-- Fest statt addonName, damit ein umbenannter Ordner keine gespeicherten Positionen oder Namen ändert.
ns.ADDON_ID = "LevelTimer"
local POPUP_PREFIX = ns.ADDON_ID:upper() .. "_"

-- Globaler Rahmenname: "LevelTimer" .. suffix (z.B. GlobalName("Alert") = "LevelTimerAlert")
function ns.GlobalName(suffix)
  return ns.ADDON_ID .. suffix
end

-- Schlüssel in StaticPopupDialogs: "LEVELTIMER_" .. suffix
function ns.PopupKey(suffix)
  return POPUP_PREFIX .. suffix
end

-- Schnittstelle für Schwester-Addons (z.B. StreamGoal, per "## Dependencies: LevelTimer"): der Namespace mit allen
-- Bausteinen (Card, Widgets, TableView, Alerts, Journal, Format, ...), Events, Login und Level-Up. Die Tabelle ist
-- dieselbe, die die Module füllen; sie steht beim Laden des anderen Addons vollständig bereit.
LevelTimerAPI = ns

ns.SetChatName(ns.DISPLAY_NAME)

---------------------------------------------------------------------------
-- Login. Nach dem Login stehen bereit:
--   ns.db            Einstellungen (Account)
--   ns.characterKey  "Name-Realm" des eingeloggten Charakters
--   ns.character     Statistiken des eingeloggten Charakters
--   ns.level         aktuelles Level
---------------------------------------------------------------------------
local function loadCharacter()
  ns.db, ns.characterKey, ns.character = ns.Database.Load()
  ns.level = UnitLevel("player")
  ns.Debug("core", "login %s level %s", ns.characterKey, ns.level)
end

local function startTracking()
  ns.RunLogin(loadCharacter)
end

ns.RegisterEvent("PLAYER_LOGIN", startTracking)

-- Statistiken eines Charakters löschen. Beim eingeloggten Charakter beginnt die Aufzeichnung
-- sofort neu (wie bei einem frischen Login); alle Module initialisieren sich über OnLogin.
function ns.DeleteCharacter(characterKey)
  ns.Database.DeleteCharacter(characterKey)
  if characterKey == ns.characterKey then
    startTracking()
  end
end

---------------------------------------------------------------------------
-- Level-Up in zwei Phasen, damit die Reihenfolge nicht von der Ladereihenfolge abhängt:
-- 1. OnLevelCompleted(oldLevel): Werte des alten Levels sind noch vollständig (z.B. Historie sichern)
-- 2. OnLevelStarted(newLevel): Zähler für das neue Level zurücksetzen
---------------------------------------------------------------------------
local levelCompletedCallbacks = {}
local levelStartedCallbacks = {}

function ns.OnLevelCompleted(callback)
  ns.AddCallback(levelCompletedCallbacks, callback)
end

function ns.OnLevelStarted(callback)
  ns.AddCallback(levelStartedCallbacks, callback)
end

ns.RegisterEvent("PLAYER_LEVEL_UP", function(newLevel)
  ns.Debug("core", "level up %s -> %s", ns.level, newLevel)
  ns.RunCallbacks(levelCompletedCallbacks, ns.level)
  ns.level = newLevel
  ns.RunCallbacks(levelStartedCallbacks, newLevel)
end)

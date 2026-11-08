-- Roadmap 405: "Standard" unter der Seitenleiste setzt nur die Einstellungen der gezeigten Unterseite zurück (nach
-- Rückfrage), "Rückgängig" stellt sie wieder her; andere Unterseiten bleiben unberührt.
local L = addon.L
local options = addon.OptionsWindow
local db = function() return LevelTimerDB end

-- Sichtbarer Button mit diesem Text (Text steht im label des Buttons)
local function shownButton(text)
  return wow.findFrame(function(f)
    local label = rawget(f, "label")
    return label and label._text == text and f:IsVisible() and f._scripts.OnClick ~= nil
  end)
end

wow.login()
SlashCmdList.LEVELTIMER("config")

-- Werte ändern: Stil & Position der Einblendungen und eine Einstellung einer anderen Unterseite
addon.Set("alertStyle", "text")
addon.Set("alertDuration", 7)
addon.Set("alertSound", true)
addon.Frames.SetScale("alert", 1.4)
addon.Set("alertLevelUp", true)  -- Unterseite "Ereignisse"

options.ShowPage("OPTIONS_PAGE_ALERT_LOOK")
expectTrue("Bausteine mit Standardwerten", options.ResetCount("OPTIONS_PAGE_ALERT_LOOK") >= 4)
expect("Rückgängig noch versteckt", shownButton(L.OPTIONS_RESET_UNDO), nil)

-- Klick: erst Rückfrage mit dem Namen der Unterseite
wow.popup = nil
local resetButton = shownButton(L.OPTIONS_RESET_PAGE)
expectTrue("Standard-Button sichtbar", resetButton ~= nil)
resetButton._scripts.OnClick(resetButton, "LeftButton")
expectTrue("Rückfrage", wow.popup ~= nil)
expect("Rückfrage nennt die Kategorie", wow.popup.text, L.OPTIONS_PAGE_ALERT_LOOK)
expect("noch nichts geändert", db().alertStyle, "text")
StaticPopupDialogs[wow.popup.name].OnAccept(nil, wow.popup.data)

expect("Stil zurück", db().alertStyle, "banner")
expect("Dauer zurück", db().alertDuration, 3)
expect("Ton zurück", db().alertSound, false)
expect("Größe zurück", addon.Frames.GetScale("alert"), 1)
expect("andere Unterseite unberührt", db().alertLevelUp, true)
local printed = wow.printed[#wow.printed]
expectTrue("Chatzeile", printed and printed:find(L.OPTIONS_PAGE_ALERT_LOOK, 1, true) ~= nil)
local undo = shownButton(L.OPTIONS_RESET_UNDO)
expectTrue("Rückgängig sichtbar", undo ~= nil)

-- Rückgängig
undo._scripts.OnClick(undo, "LeftButton")
expect("Stil wieder", db().alertStyle, "text")
expect("Dauer wieder", db().alertDuration, 7)
expect("Ton wieder", db().alertSound, true)
expectNear("Größe wieder", addon.Frames.GetScale("alert"), 1.4)
expect("Rückgängig weg", undo:IsShown(), false)

-- Unterseite mit Tabellen-Einstellung und Minimap: Hauptfenster (Minimap-Knopf), Rekorde
addon.SetMinimapHidden(true)
expectTrue("Hauptfenster", options.ResetPage("OPTIONS_PAGE_WINDOW"))
expect("Minimap wieder an", db().minimap.hide, false)
db().recordBrackets["1-10"] = false
expectTrue("Rekorde", options.ResetPage("OPTIONS_PAGE_RECORDS"))
expect("Abschnitte wieder alle", next(db().recordBrackets), nil)

-- Unbekannte Seite, Seite ohne Einstellungen
expect("unbekannt", options.ResetPage("GIBT_ES_NICHT"), false)

LevelTimerOptions:Hide()
expect("keine Fehler", #wow.errors, 0)

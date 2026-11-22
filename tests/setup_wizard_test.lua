-- LT-301: Einrichtungsassistent (Retail): einmal für alle Spieler nach dem Login (nicht im Kampf, nicht über dem Level-Up-
-- Fenster), Schritte mit Zurück/Weiter/Überspringen, "Kein Fenster" blendet das Hauptfenster aus (Tracking läuft weiter),
-- nur Schalter für Features des Clients, später /lt setup, Minimap-Knopf standardmäßig an.
local L = addon.L
local Wizard = addon.SetupWizard

-- Spieler mit alter Willkommenskarte (introShown) sehen den Assistenten trotzdem einmal
wow.login()
expect("Minimap-Knopf an", LevelTimerDB.minimap.hide, false)
LevelTimerStatsDB.introShown = true
LevelTimerStatsDB.setupWizardSeen = nil
wow.state.combatLockdown = true
wow.runTimers()
expect("im Kampf nicht", LevelTimerSetup:IsShown(), false)
wow.state.combatLockdown = false
local levelUpShown = addon.LevelUpWindow.IsShown
addon.LevelUpWindow.IsShown = function() return true end
wow.runTimers()
expect("nicht über dem Level-Up-Fenster", LevelTimerSetup:IsShown(), false)
addon.LevelUpWindow.IsShown = levelUpShown
wow.runTimers()
expect("danach da", LevelTimerSetup:IsShown(), true)
expect("gemerkt", LevelTimerStatsDB.setupWizardSeen, true)

-- Retail: Dungeon-Schritt nur mit dem Recap-Schalter (LT-406)
local state = Wizard.State()
expect("Schritte", table.concat(state.steps, ","),
  "language,presets,window,dungeons,quests,hints,timers,comfort,interface,finish")
expect("Schritt 1", state.step, "language")
wow.click(L.SETUP_BACK)  -- im ersten Schritt wirkungslos
expect("noch Schritt 1", Wizard.State().step, "language")

-- LT-308: Sprache wählbar, Automatisch folgt dem Client
expect("Sprache automatisch", LevelTimerDB.language, addon.AUTO_LANGUAGE)
expectTrue("Sprache Deutsch", wow.click("Deutsch"))
expect("Sprache gespeichert", LevelTimerDB.language, "deDE")
expect("Sprache wirkt", addon.Language(), "deDE")
expectTrue("Sprache Automatisch", wow.click(addon.L.LANGUAGE_AUTO))
expect("Automatisch = Client", addon.Language(), addon.DefaultLanguage())
wow.click(L.SETUP_NEXT)
expect("Schritt 2", Wizard.State().step, "presets")

-- Schritt 1: Voreinstellung wirkt sofort
expectTrue("Voreinstellung Minimal", wow.click(L.PRESET_MINIMAL))
expect("Minimal: Tode aus", LevelTimerDB.showDeaths, false)

-- Schritt 2: Layout und "Kein Fenster"
expectTrue("Weiter", wow.click(L.SETUP_NEXT))
expect("Schritt 2", Wizard.State().step, "window")
local layout = addon.WindowLayouts.Get("tiles")
expectTrue("Layout Kacheln", wow.click(L[layout.label]))
expect("Layout gesetzt", LevelTimerDB.windowLayout, "tiles")
expect("Fenster an", LevelTimerDB.showTimer, true)
expectTrue("Kein Fenster", wow.click(L.SETUP_NO_WINDOW))
expect("Hauptfenster aus", LevelTimerDB.showTimer, false)
expect("Fenster versteckt", LevelTimerFrame:IsShown(), false)
-- zurückholen: /lt show und Minimap-Knopf (Rechtsklick)
SlashCmdList.LEVELTIMER("show")
expect("/lt show", LevelTimerDB.showTimer, true)
wow.click(L.SETUP_NO_WINDOW)
addon.LauncherClicks.Handle("RightButton")
expect("Rechtsklick holt es zurück", LevelTimerDB.showTimer, true)
expect("Auswahl bleibt Kacheln", LevelTimerDB.windowLayout, "tiles")

-- Dungeons: ohne Guide-Daten nur der Recap
wow.click(L.SETUP_NEXT)
local dungeonShown = {}
for _, check in ipairs(Wizard.State().toggles) do
  if check:IsShown() then dungeonShown[#dungeonShown + 1] = check.def.label end
end
expect("Retail: nur Recap", table.concat(dungeonShown, ","), "DUNGEON_RECAP_AUTO_OPEN_TOGGLE")

-- Quests: nur Schalter dieses Clients
wow.click(L.SETUP_NEXT)
local toggles = Wizard.State().toggles
local shown = {}
for _, check in ipairs(toggles) do
  if check:IsShown() then shown[#shown + 1] = check.def.label end
end
expect("Retail: nur Quest-Markierungen und Route", table.concat(shown, ","), "QUEST_MARKS_TOGGLE,SHOW_ROUTE_REPLAY")
for _, check in ipairs(toggles) do
  expectTrue("Tooltip " .. check.def.label, L[check.def.label .. "_TIP"] ~= check.def.label .. "_TIP")
end
local marks = toggles[2]
marks:SetChecked(false)
marks._scripts.OnClick(marks)
expect("Quest-Markierungen aus", LevelTimerDB.questMarks, false)

-- Hinweise, Komfort, Oberfläche und Fertig mit Zusammenfassung
for _, step in ipairs({ "hints", "timers", "comfort", "interface", "finish" }) do
  wow.click(L.SETUP_NEXT)
  expect("Schritt " .. step, Wizard.State().step, step)
  if step == "timers" then
    -- Zeit-Anzeigen: Flugzeit mit Vorschau-Knopf in der Zeile
    local flight
    for _, toggle in ipairs(Wizard.State().toggles) do
      if toggle.def.label == "FLIGHT_TIMER_TOGGLE" then flight = toggle end
    end
    expectTrue("Flug-Vorschau sichtbar", flight.previewButton and flight.previewButton:IsShown())
    flight.previewButton._scripts.OnClick(flight.previewButton)
    expect("Vorschau ohne Fehler", #wow.errors, 0)
  end
end
local finish = Wizard.State()
expect("Fertig-Schritt", finish.step, "finish")
expect("Zusammenfassung Fenster", finish.summary[2].value:GetText(), L[layout.label])
expect("kein Stream-Schalter mehr", finish.stream, nil)
expectTrue("Position anpassen", wow.click(L.SETUP_EDIT_MODE))
expect("Assistent zu", LevelTimerSetup:IsShown(), false)
expect("Edit-Modus an", addon.EditMode.IsActive(), true)
addon.EditMode.Leave()

-- Später: /lt setup, Knopf in den Einstellungen, Überspringen
wow.logout()
wow.login()
wow.runTimers()
expect("zweiter Login: nicht noch einmal", LevelTimerSetup:IsShown(), false)
SlashCmdList.LEVELTIMER("setup")
expect("/lt setup", LevelTimerSetup:IsShown(), true)
expect("beginnt vorn", Wizard.State().step, "language")
wow.click(L.SETUP_SKIP)
expect("Überspringen schließt", LevelTimerSetup:IsShown(), false)
SlashCmdList.LEVELTIMER("config")
addon.OptionsWindow.ShowPage("SECTION_GENERAL")
expectTrue("Knopf in den Einstellungen", wow.click(L.SETUP_OPEN))
expect("Assistent offen", LevelTimerSetup:IsShown(), true)
for _ = 1, #Wizard.State().steps do Wizard.State().next._scripts.OnClick() end  -- "Fertig" heißt auch ein Knopf des Edit-Modus
expect("Fertig schließt", LevelTimerSetup:IsShown(), false)

expect("keine Fehler", #wow.errors, 0)

-- Icons (LT-303): Pfad setzt das Icon, unbekannter Atlas oder leere Quelle verstecken es (Fallback ohne Icon)
local tex = { SetTexture = function(self, t) self.tex = t end, SetSize = function() end,
  SetShown = function(self, v) self.shown = v end }
expect("Icon-Pfad", addon.Widgets.SetIcon(tex, "Interface/Icons/INV_Misc_Key_05", 24), true)
expect("Icon-Pfad gesetzt", tex.tex, "Interface/Icons/INV_Misc_Key_05")
expect("Atlas ohne Client-Atlas: Fallback", addon.Widgets.SetIcon(tex, "gibt-es-nicht", 24), false)
expect("Fallback versteckt", tex.shown, false)
expect("leere Quelle", addon.Widgets.SetIcon(tex, nil, 24), false)

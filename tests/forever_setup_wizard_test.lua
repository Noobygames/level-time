-- LT-301, WoW Forever: der Assistent hat Dungeon-Schritt und Dungeonquest-Schalter, beim ersten Start keine Chatzeile
local L = addon.L
local Wizard = addon.SetupWizard
wow.login()
wow.runTimers()
expect("keine Chatzeile", #wow.printed, 0)
expect("Assistent beim ersten Start", LevelTimerSetup:IsShown(), true)
expect("Schritte", table.concat(Wizard.State().steps, ","),
  "language,presets,window,dungeons,quests,hints,timers,comfort,interface,graphics,finish")
expect("Hinweise standardmäßig an", LevelTimerDB.dungeonQuestZoneHint and LevelTimerDB.dungeonQuestAcceptHint, true)

wow.click(L.SETUP_NEXT)
wow.click(L.SETUP_NEXT)
wow.click(L.SETUP_NEXT)
expect("Dungeon-Schritt", Wizard.State().step, "dungeons")
local labels = {}
for _, toggle in ipairs(Wizard.State().toggles) do
  if toggle:IsShown() then labels[#labels + 1] = toggle.def.label end
end
local check = Wizard.State().toggles[1]
expect("Dungeonquest-Schalter", check.def.label, "WELCOME_DUNGEONS_CHECK")
check:SetChecked(false)
check._scripts.OnClick(check)
expect("Zonen-Hinweis aus", LevelTimerDB.dungeonQuestZoneHint, false)
expect("Annahme-Hinweis aus", LevelTimerDB.dungeonQuestAcceptHint, false)

-- LT-406: Dungeon Guide (mit Vorschau-Knopf) und Recap
local joined = table.concat(labels, ",")
expectTrue("Guide-Schalter", joined:find("SETUP_DUNGEON_GUIDE_TOGGLE", 1, true) ~= nil)
expectTrue("Recap-Schalter", joined:find("DUNGEON_RECAP_AUTO_OPEN_TOGGLE", 1, true) ~= nil)
for _, toggle in ipairs(Wizard.State().toggles) do
  if toggle.def.label == "SETUP_DUNGEON_GUIDE_TOGGLE" then
    expect("Guide an", toggle:GetChecked() == true, true)
    toggle:SetChecked(false)
    toggle._scripts.OnClick(toggle)
    expect("Guide aus", LevelTimerDB.dungeonGuideAuto, false)
    toggle.previewButton._scripts.OnClick(toggle.previewButton)
    expectTrue("Vorschau öffnet den Guide", addon.DungeonGuideWindow.IsShown())
    addon.DungeonGuideWindow.Hide()
  end
end
expectTrue("Gruppensuche-Tooltip da", table.concat(labels, ","):find("LFG_TOOLTIP_TOGGLE", 1, true) ~= nil)
for _, toggle in ipairs(Wizard.State().toggles) do
  expectTrue("Tooltip " .. toggle.def.label, L[toggle.def.label .. "_TIP"] ~= toggle.def.label .. "_TIP")
end

for _ = 1, 6 do wow.click(L.SETUP_NEXT) end  -- Quests, Hinweise, Zeit-Anzeigen, Komfort, Oberfläche, Grafik
expect("Grafik-Schritt", Wizard.State().step, "graphics")
local ultra = Wizard.State().toggles[1]
expect("Beyond Ultra aus", ultra:GetChecked() == true, false)
ultra:SetChecked(true)
ultra._scripts.OnClick(ultra)
expect("Beyond Ultra an", LevelTimerDB.foreverGraphics, true)
expect("empfohlene Werte gesetzt", LevelTimerDB.graphicsTerrainDistance, addon.ForeverGraphics.SLIDERS[6].recommended)
ultra:SetChecked(false)
ultra._scripts.OnClick(ultra)
expect("Beyond Ultra wieder aus", LevelTimerDB.foreverGraphics, false)
for _, toggle in ipairs(Wizard.State().toggles) do
  expectTrue("Tooltip " .. toggle.def.label, L[toggle.def.label .. "_TIP"] ~= toggle.def.label .. "_TIP")
end
wow.click(L.SETUP_NEXT)
expect("Fertig-Schritt", Wizard.State().step, "finish")
expectTrue("Alle Einstellungen", wow.click(L.SETUP_ALL_SETTINGS))
expect("Assistent zu", LevelTimerSetup:IsShown(), false)
expect("keine Fehler", #wow.errors, 0)

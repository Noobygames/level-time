-- Roadmap 404: Rechtsklick auf eine Anzeige öffnet außerhalb des Edit-Modus deren Unterseite der Einstellungen
-- (zentral in Lib/Frames.lua); ein zweiter Rechtsklick schließt sie. Die Einblendung bleibt klickdurchlässig.
wow.login()
local options = addon.OptionsWindow
local Frames = addon.Frames

local function rightClick(frame)
  frame._scripts.OnMouseUp(frame, "RightButton")
end

local cases = {
  { id = "main", tab = "SECTION_GENERAL", sub = "OPTIONS_PAGE_WINDOW" },
  { id = "splitList", tab = "OPTIONS_TAB_SPEEDRUN", sub = "OPTIONS_PAGE_SPLIT_LIST" },
  { id = "levelUp", tab = "OPTIONS_TAB_ALERTS", sub = "OPTIONS_PAGE_LEVEL_UP_WINDOW" },
  { id = "flight", tab = "OPTIONS_TAB_ALERTS", sub = "OPTIONS_PAGE_FLIGHTS" },
  { id = "lootRolls", tab = "OPTIONS_TAB_COMFORT", sub = "COMFORT_PAGE_SYSTEM" },
}
for _, case in ipairs(cases) do
  local frame = Frames.Get(case.id).frame
  expectTrue(case.id .. ": nimmt die Maus", frame:IsMouseEnabled())
  rightClick(frame)
  expect(case.id .. ": Einstellungen offen", LevelTimerOptions:IsShown(), true)
  local tab, sub = options.CurrentPage()
  expect(case.id .. ": Reiter", tab, case.tab)
  expect(case.id .. ": Unterseite", sub, case.sub)
  rightClick(frame)
  expect(case.id .. ": zweiter Rechtsklick schließt", LevelTimerOptions:IsShown(), false)
end

-- Andere Seite offen: Rechtsklick springt um statt zu schließen
addon.ShowOptionsPage("OPTIONS_PAGE_COMPARE")
rightClick(LevelTimerFrame)
local _, sub = options.CurrentPage()
expect("springt auf die Seite des Fensters", sub, "OPTIONS_PAGE_WINDOW")
expect("bleibt offen", LevelTimerOptions:IsShown(), true)
LevelTimerOptions:Hide()

-- Linksklick tut das nicht; Level-Reiter gibt den Rechtsklick weiter
LevelTimerFrame._scripts.OnMouseUp(LevelTimerFrame, "LeftButton")
expect("Linksklick öffnet nichts", LevelTimerOptions:IsShown(), false)

-- Einblendung: kein Mausziel (klickdurchlässig)
expect("Einblendung nimmt keine Maus", LevelTimerAlert:IsMouseEnabled(), false)

-- Im Edit-Modus gehört der Rechtsklick dem Menü der Fläche, nicht der Anzeige
addon.EditMode.Enter()
rightClick(LevelTimerFrame)
expect("Edit-Modus: keine Einstellungen", LevelTimerOptions:IsShown(), false)
addon.EditMode.Leave()

expect("keine Fehler", #wow.errors, 0)

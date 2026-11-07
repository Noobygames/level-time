-- Roadmap 402: Schalter "Erweitert" oben rechts. Aus = Modus "Einfach": advanced-Bausteine verborgen, folgende rücken
-- nach, Unterseiten ohne sichtbaren Baustein fallen aus der Seitenleiste; die Suche findet alles und schaltet um.
local L = addon.L
local options = addon.OptionsWindow

wow.login()
SlashCmdList.LEVELTIMER("config")

local function entryOf(labelKey)
  for _, entry in ipairs(options.Search(L[labelKey])) do
    if entry.tipKey == labelKey .. "_TIP" then return entry end
  end
end

expect("Standard: Erweitert", LevelTimerDB.optionsAdvanced, true)
local mode = options.modeCheckbox
expect("Schalter an", mode:GetChecked(), true)
expectTrue("Schalter auffindbar", entryOf("OPTIONS_ADVANCED") ~= nil)

options.ShowPage("OPTIONS_PAGE_REMINDERS")
local interval = entryOf("REMINDER_INTERVAL")
local breakToggle = entryOf("REMIND_BREAK_TOGGLE")
local breakY = breakToggle.cell.y
expectTrue("Intervall sichtbar", interval.left:IsVisible())

-- Einfach
mode:SetChecked(false)
mode._scripts.OnClick(mode)
expect("Einstellung aus", LevelTimerDB.optionsAdvanced, false)
expect("Intervall verborgen", interval.left:IsShown(), false)
expectTrue("Pause rückt hoch", breakToggle.cell.y > breakY)
expectTrue("Pause sichtbar", breakToggle.left:IsVisible())

-- Seitenleiste: Berechnung und Reihenfolge haben nur erweiterte Bausteine
local calc = options.Search(L.OPTIONS_PAGE_CALCULATION)
local calcPage
for _, entry in ipairs(calc) do
  if entry.isPage and entry.sub and entry.sub.key == "OPTIONS_PAGE_CALCULATION" then calcPage = entry end
end
expectTrue("Seite Berechnung gefunden", calcPage ~= nil)
expect("Berechnung fällt aus der Seitenleiste", calcPage.left:IsShown(), false)
options.ShowPage("OPTIONS_PAGE_STAT_XP")
expect("XP-Seite bleibt", entryOf("STAT_XP_RATE").left:IsVisible(), true)

-- Schalter einer Gruppe: der erweiterte fehlt, die übrigen rücken nach
options.ShowPage("OPTIONS_PAGE_WINDOW")
expect("Blizzard-Edit-Modus verborgen", entryOf("QUEST_XP_ON_BAR").left:IsShown(), false)
expectTrue("Sperren sichtbar", entryOf("LOCK_FRAME").left:IsVisible())

-- Suche nach einem verborgenen Baustein schaltet auf Erweitert
options.Reveal(entryOf("IDLE_LIMIT"))
expect("wieder Erweitert", LevelTimerDB.optionsAdvanced, true)
local _, sub = options.CurrentPage()
expect("Seite Berechnung gezeigt", sub, "OPTIONS_PAGE_CALCULATION")
expect("Berechnung wieder in der Seitenleiste", calcPage.left:IsShown(), true)
options.ShowPage("OPTIONS_PAGE_REMINDERS")
expect("Pause zurück", breakToggle.cell.y, breakY)
expectTrue("Intervall wieder da", interval.left:IsVisible())

-- Modus übersteht /reload (Profil-Einstellung)
addon.Set("optionsAdvanced", false)
LevelTimerOptions:Hide()
wow.logout()
wow.login()
SlashCmdList.LEVELTIMER("config")
expect("nach Reload einfach", options.modeCheckbox:GetChecked(), false)
addon.Set("optionsAdvanced", true)

LevelTimerOptions:Hide()
expect("keine Fehler", #wow.errors, 0)

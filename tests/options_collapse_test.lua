-- Roadmap 406: einklappbare Abschnitte (Komfort > Ausblenden in Gruppen, Komfort > Quests): Klick auf die Überschrift
-- blendet die Bausteine darunter aus, die folgenden rücken nach oben; die Suche klappt wieder auf.
local L = addon.L
local options = addon.OptionsWindow

wow.login()
SlashCmdList.LEVELTIMER("config")
options.ShowPage("COMFORT_PAGE_QUESTS")

local function entryOf(labelKey)
  for _, entry in ipairs(options.Search(L[labelKey])) do
    if entry.tipKey == labelKey .. "_TIP" then return entry end
  end
end

local section = options.SectionOf("COMFORT_PAGE_AUTOMATION")
expectTrue("Abschnitt Automatik gefunden", section ~= nil)
local accept = entryOf("AUTO_ACCEPT_QUESTS")
local progress = entryOf("QUEST_PROGRESS_TOGGLE")
local yBefore = progress.cell.y
expectTrue("Schalter sichtbar", accept.left:IsVisible())

-- Einklappen per Klick auf die Überschrift
local header = section.widgets[1]
header._scripts.OnMouseUp(header, "LeftButton")
expect("eingeklappt", options.IsCollapsed(section), true)
expect("Schalter darunter weg", accept.left:IsShown(), false)
expectTrue("folgender Abschnitt rückt hoch", progress.cell.y > yBefore)
expectTrue("Überschrift zeigt +", header.label._text:find("^%+") ~= nil)

-- Suche nach einem eingeklappten Schalter klappt auf
options.Reveal(accept)
expect("aufgeklappt", options.IsCollapsed(section), false)
expect("Schalter wieder da", accept.left:IsShown(), true)
expect("zurück an der alten Stelle", progress.cell.y, yBefore)

-- Ausblenden: Blizzard-Liste in Gruppen, jede einklappbar
options.ShowPage("COMFORT_PAGE_HIDE")
for _, key in ipairs({ "SECTION_BLIZZ_UNIT_FRAMES", "SECTION_BLIZZ_MINIMAP_BUFFS", "SECTION_BLIZZ_BARS" }) do
  local group = options.SectionOf(key)
  expectTrue("Gruppe " .. key, group ~= nil and group.collapsible)
end
local units = options.SectionOf("SECTION_BLIZZ_UNIT_FRAMES")
options.SetCollapsed(units, true)
local bars = options.SectionOf("SECTION_BLIZZ_BARS")
expectTrue("Leisten-Gruppe rückt hoch", bars.shift > 0)
options.SetCollapsed(units, false)
expect("wieder unten", bars.shift, 0)

LevelTimerOptions:Hide()
expect("keine Fehler", #wow.errors, 0)

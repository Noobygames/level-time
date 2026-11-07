-- Suche in den Einstellungen: findet Beschriftungen und Tooltip-Texte auf allen Reitern und Unterseiten, ein Treffer
-- zeigt Reiter und Unterseite, scrollt hin und hebt den Baustein kurz hervor; Sprache wechselt live.
local L = addon.L
local options = addon.OptionsWindow
local box = LevelTimerOptionsSearch

wow.login()
SlashCmdList.LEVELTIMER("config")
expect("keine Liste beim Öffnen", options.SearchResultRows()[1], nil)

-- Zu kurze Eingabe sucht nicht
options.SetSearchText("a")
expect("ein Zeichen: keine Liste", #options.SearchResultRows(), 0)

-- Beschriftung: "Reparieren" steht unter Komfort > Automatik
options.SetSearchText(L.AUTO_REPAIR)
local rows = options.SearchResultRows()
expectTrue("Treffer da", #rows >= 1)
local first = rows[1]
expect("Treffer zeigt die Beschriftung", first.text, L.AUTO_REPAIR)
expect("Treffer zeigt den Ort", first.where, L.OPTIONS_TAB_COMFORT .. " > " .. L.COMFORT_PAGE_AUTOMATION)

-- Klick: Reiter und Unterseite gezeigt, Feld geleert, Baustein hervorgehoben
first.click()
local tab, sub = options.CurrentPage()
expect("Reiter Komfort", tab, "OPTIONS_TAB_COMFORT")
expect("Unterseite Automatik", sub, "COMFORT_PAGE_AUTOMATION")
expect("Feld geleert", box:GetText(), "")
expect("Liste zu", #options.SearchResultRows(), 0)
local highlight = options.Highlighted()
expectTrue("hervorgehoben", highlight ~= nil)
local repair = first.entry
expect("Hervorhebung am Schalter", highlight._points[1][2], repair.left)
expect("Hervorhebung bis zur Beschriftung", highlight._points[2][2], repair.left.label)
wow.runTimers()
expect("Hervorhebung verschwindet", options.Highlighted(), nil)

-- Tooltip-Text: ein Wort nur aus dem Tooltip findet den Schalter (Titel-Treffer zuerst)
local tipOnly = "Tooltip"  -- steht in vielen Tooltip-Texten, z.B. Quest-Effizienz
local matches = options.Search(tipOnly)
expectTrue("Tooltip-Treffer", #matches > 0)
local titleMatches, sawTip = 0, false
for _, entry in ipairs(matches) do
  local inTitle = entry.title() and entry.title():lower():find(tipOnly:lower(), 1, true)
  if inTitle then
    expect("Titel-Treffer vor Tooltip-Treffern", sawTip, false)
    titleMatches = titleMatches + 1
  else
    sawTip = true
  end
end
expectTrue("auch reine Tooltip-Treffer", sawTip)

-- Viele Treffer: höchstens 10 Zeilen plus "... und n weitere"; nichts gefunden: eine Zeile
options.SetSearchText("en")
rows = options.SearchResultRows()
expect("10 Treffer plus Rest", #rows, 11)
expect("Rest-Zeile", rows[11].text, string.format(L.OPTIONS_SEARCH_MORE, #options.Search("en") - 10))
expect("Rest-Zeile ohne Sprung", rows[11].entry, nil)
options.SetSearchText("zzqqxx")
rows = options.SearchResultRows()
expect("nichts gefunden: eine Zeile", #rows, 1)
expect("nichts gefunden", rows[1].text, L.OPTIONS_SEARCH_NONE)

-- Enter springt zum ersten Treffer, auch auf eine tiefe Zeile (gescrollt)
options.SetSearchText(L.WARN_BREATH_BELOW)
box._scripts.OnEnterPressed(box)
tab, sub = options.CurrentPage()
expect("Enter: Reiter", tab, "OPTIONS_TAB_NOTIFICATIONS")
expect("Enter: Unterseite", sub, "OPTIONS_PAGE_WARNINGS")
local breath
for _, entry in ipairs(options.Search(L.WARN_BREATH_BELOW)) do
  if entry.tipKey == "WARN_BREATH_BELOW_TIP" then breath = entry end
end
expectTrue("gescrollt", breath.tab.scroll:GetVerticalScroll() > 62)

-- Esc leert das Feld; Treffer für Seiten selbst zeigen die Seite
options.SetSearchText("Speedrun")
box._scripts.OnEscapePressed(box)
expect("Esc leert", box:GetText(), "")
expect("Esc schließt die Liste", #options.SearchResultRows(), 0)
local pageHit
for _, entry in ipairs(options.Search(L.OPTIONS_PAGE_SSF)) do
  if entry.isPage then pageHit = entry end
end
options.Reveal(pageHit)
tab, sub = options.CurrentPage()
expect("Seiten-Treffer", sub, "OPTIONS_PAGE_SSF")

-- Sprache wechseln: die Suche nimmt die neuen Texte
addon.Set("language", "enUS")
expectTrue("englisch gefunden", #options.Search("Auto repair") > 0 or #options.Search(L.AUTO_REPAIR) > 0)
expect("deutsch nicht mehr", #options.Search("Automatisch reparieren"), 0)
addon.Set("language", "deDE")

-- Schließen leert die Suche
options.SetSearchText("Minimap")
LevelTimerOptions:Hide()
expect("Schließen leert", box:GetText(), "")
expect("keine Fehler", #wow.errors, 0)

-- Optionsfenster (Roadmap 395): ein Apply bei offenem Fenster aktualisiert nur die sichtbare Seite; verborgene Seiten
-- holen es beim Umschalten nach, ein Sprachwechsel aktualisiert alles
local OptionsBuilder = addon.OptionsBuilder

wow.login({ level = 10 })

local builder = OptionsBuilder.New({ name = "LevelTimerTestOptions", alpha = 0.9, title = function() return "Test" end })
local runs = { first = 0, second = 0, footer = 0 }
builder.AddPage("OPTIONS_TAB_GENERAL")
builder.OnRefresh(function() runs.first = runs.first + 1 end)
builder.FinishPage()
builder.AddPage("OPTIONS_TAB_ALERTS")
builder.OnRefresh(function() runs.second = runs.second + 1 end)
builder.FinishPage()
builder.Finish()

builder.panel:Show()
builder.Refresh(addon.db)
expect("vollständig: erste Seite", runs.first, 1)
expect("vollständig: zweite Seite", runs.second, 1)

for _ = 1, 5 do builder.RefreshIfShown(addon.db) end
expect("offen: sichtbare Seite aktualisiert", runs.first, 6)
expect("offen: verborgene Seite wartet", runs.second, 1)

builder.ShowPage("OPTIONS_TAB_ALERTS")
expect("umgeschaltet: einmal nachgeholt", runs.second, 2)
builder.ShowPage("OPTIONS_TAB_GENERAL")
expect("zurück: nichts nachzuholen", runs.first, 6)

addon.db.language = addon.db.language == "deDE" and "enUS" or "deDE"
builder.RefreshIfShown(addon.db)
expect("Sprachwechsel: alle Seiten", runs.second, 3)

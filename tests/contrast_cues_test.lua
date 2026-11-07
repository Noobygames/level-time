-- UX 216: aktiver Reiter nicht nur über die Farbe (Unterstrich), blaue Hervorhebung in Säulendiagrammen mit Legende
wow.login()
local tab = addon.Widgets.CreateTab(UIParent, "GameFontNormal", function() end)
tab:SetLabel("Reiter")
tab:SetActive(true)
expect("aktiv: unterstrichen", tab.underline:IsShown(), true)
tab:SetActive(false)
expect("inaktiv: ohne Strich", tab.underline:IsShown(), false)

local chart = addon.Charts.CreateColumnChart(UIParent, 300, 100)
chart:SetItems({ { label = "1", value = 3, text = "3" }, { label = "2", value = 5, text = "5" } }, tostring)
expect("ohne Hervorhebung keine Legende", chart.legendText:IsShown(), false)
chart:SetItems({ { label = "1", value = 3, text = "3" }, { label = "2", value = 5, text = "5", highlight = true } }, tostring)
expect("Legende da", chart.legendText:IsShown(), true)
expect("Legendentext", chart.legendText:GetText(), addon.L.CHART_HIGHLIGHT_LEGEND)

expect("keine Fehler", #wow.errors, 0)

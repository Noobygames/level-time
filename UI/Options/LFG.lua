-- Optionen, Reiter Gruppensuche (nur WoW Forever): Zusatzinfos im Tooltip von Blizzards Gruppensuche, der
-- Sprachfilter und das eigene Fenster. Die Logik steht in Assist/LFGTooltip.lua, Assist/LFGLanguages.lua und
-- Assist/LFGSearch.lua (Fenster: UI/LFGWindow.lua).
local _, ns = ...
if not ns.Client.IsForever() then return end
local O = ns.OptionsCore
local addPage, finishPage, addSection, addToggles, toggle = O.addPage, O.finishPage, O.addSection, O.addToggles, O.toggle

addPage("OPTIONS_TAB_LFG")
addSection("SECTION_LFG_TOOLTIP")
addToggles({ toggle("LFG_TOOLTIP_TOGGLE", "lfgTooltip") })
addSection("SECTION_LFG_LANGUAGES")
addToggles({ toggle("LFG_ALL_LANGUAGES_TOGGLE", "lfgAllLanguages", ns.LFGLanguages.IsAvailable) })
addSection("SECTION_LFG_WINDOW")
addToggles({ toggle("LFG_WINDOW_TOGGLE", "lfgWindow", ns.LFGSearch.IsAvailable) })
finishPage()

-- Optionen, Reiter Gruppensuche (nur WoW Forever): Zusatzinfos im Tooltip von Blizzards Gruppensuche, der
-- Sprachfilter und das eigene Fenster. Die Logik steht in Assist/LFGTooltip.lua, Assist/LFGLanguages.lua und
-- Assist/LFGSearch.lua (Fenster: UI/LFGWindow.lua).
local _, ns = ...
if not ns.Client.IsForever() then return end
local O = ns.OptionsCore
local addPage, finishPage, addSection, addToggles, toggle = O.addPage, O.finishPage, O.addSection, O.addToggles, O.toggle
local addButton = O.addButton
local L = ns.L

addPage("OPTIONS_TAB_LFG")
addSection("SECTION_LFG_TOOLTIP")
addToggles({ toggle("LFG_TOOLTIP_TOGGLE", "lfgTooltip") })
addSection("SECTION_LFG_LANGUAGES")
local languageToggles = {}
for _, code in ipairs(ns.LFGLanguages.Available()) do
  local key = "LFG_LANGUAGE_" .. code:upper()
  table.insert(languageToggles, {
    label = key, tip = "LFG_LANGUAGE_PICK_TIP",
    -- Blizzards eigene Sprachnamen, sonst unsere
    text = function() return _G["LFG_LIST_LANGUAGE_" .. code:upper()] or (L[key] ~= key and L[key]) or code end,
    enabled = function() return not ns.LFGLanguages.Defaults()[code] end,
    get = function() return ns.LFGLanguages.Selected()[code] == true end,
    set = function(checked) ns.LFGLanguages.Toggle(code, checked) end,
  })
end
addToggles(languageToggles)
addButton("LFG_LANGUAGES_RESTORE", function() ns.LFGLanguages.Restore() end)
addSection("SECTION_LFG_WINDOW")
addToggles({ toggle("LFG_WINDOW_TOGGLE", "lfgWindow", ns.LFGSearch.IsAvailable) })
finishPage()

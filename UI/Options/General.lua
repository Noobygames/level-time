-- Optionen, Reiter Allgemein: Sprache, Minimap, Changelog, Assistent; die Profile folgen in Profiles.lua (schließt den Reiter).
local _, ns = ...
local O = ns.OptionsCore
local addPage, addToggles, addButton, addChooser, addHint = O.addPage, O.addToggles, O.addButton, O.addChooser, O.addHint
local addSubPage, toggle, localized = O.addSubPage, O.toggle, O.localized

-- Sprachnamen stehen immer in der eigenen Sprache
local function addLanguageChooser()
  local choices = { { value = ns.AUTO_LANGUAGE, name = localized("LANGUAGE_AUTO") } }
  for _, language in ipairs(ns.languages) do
    choices[#choices + 1] = { value = language.code, name = function() return language.name end }
  end
  addChooser({ label = "LANGUAGE", setting = "language", choices = choices })
end

addPage("SECTION_GENERAL")
addSubPage("SECTION_LANGUAGE")
addLanguageChooser()
-- Knopf an der Minimap gehört zu den Level-Time-Fenstern, nicht zur Sprache (UX S20)
addSubPage("OPTIONS_PAGE_MINIMAP")
addToggles({
  { label = "SHOW_MINIMAP", get = function(db) return not db.minimap.hide end,
    set = function(checked) ns.SetMinimapHidden(not checked) end, reset = O.minimapReset },
})
addSubPage("OPTIONS_PAGE_CHANGELOG")
-- Changelog (UI/Changelog.lua): nach Updates automatisch, jederzeit die letzten 14 Tage
addToggles({ toggle("CHANGELOG_AUTO_SHOW", "changelogAutoShow") })
addButton("CHANGELOG_SHOW", function() ns.Changelog.ShowRecent() end)
addSubPage("OPTIONS_PAGE_SETUP")
addButton("SETUP_OPEN", function() ns.SetupWizard.Show() end)
addHint("OPTIONS_HINT")

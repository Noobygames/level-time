-- Einstellungen: Symbole an Reiter, Seitenleisten-Einträgen und Abschnittsüberschriften.
local L = addon.L
local icons = addon.OptionsIcons

wow.login()
SlashCmdList.LEVELTIMER("config")

-- Quelle = Pfad oder Zauber-ID (dann dessen Symbol)
local function hasTexture(source)
  local path = type(source) == "number" and addon.Widgets.SpellTexture(source) or source
  return wow.findFrame(function(frame) return rawget(frame, "_texture") == path end) ~= nil
end

-- Jede Quelle ist ein Pfad oder eine Zauber-ID mit Symbol
for key, source in pairs(icons) do
  local ok = type(source) == "string" or (type(source) == "number" and addon.Widgets.SpellTexture(source) ~= nil)
  expectTrue("gültige Quelle " .. key, ok)
end

expectTrue("Reiter mit Symbol", hasTexture(icons.OPTIONS_TAB_HINTS))
expectTrue("Seitenleiste mit Symbol", hasTexture(icons.OPTIONS_PAGE_STAT_XP))
expectTrue("Abschnitt mit Symbol", hasTexture(icons.SECTION_STAT_PRESETS))
expectTrue("Tabelle belegt", icons.OPTIONS_TAB_MAIN ~= nil and L.OPTIONS_TAB_MAIN ~= nil)

-- Ohne Eintrag kein Symbol; mit Symbol ist der Reiter 16 + 4 px breiter
local function newTab(source)
  local tab = addon.Widgets.CreateTab(UIParent, "GameFontNormal", function() end)
  tab:SetIcon(source)
  tab:SetLabel("x")
  return tab
end
local plain, withIcon = newTab(icons.NO_SUCH_KEY), newTab(icons.OPTIONS_TAB_MAIN)
expect("kein Symbol ohne Eintrag", plain.iconTexture, false)
expectTrue("Symbol angelegt", withIcon.iconTexture ~= false)
expect("Breite mit Symbol", withIcon:GetWidth(), plain:GetWidth() + 20)

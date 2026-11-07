-- Sprachen: Liste, Standardsprache aus dem Client und ns.L (Text in der eingestellten Sprache). Die Texte selbst
-- stehen je Sprache in Locales/deDE.lua, enUS.lua, frFR.lua, esES.lua (geladen nach dieser Datei).
local _, ns = ...

ns.languages = {
  { code = "deDE", name = "Deutsch" },
  { code = "enUS", name = "English" },
  { code = "frFR", name = "Français" },
  { code = "esES", name = "Español" },
}

ns.locales = {}  -- je Sprache eine Datei (Locales/deDE.lua, ...), geladen nach dieser

-- Client-Sprache, für die es Texte gibt (esMX nutzt die spanischen); sonst Englisch
local CLIENT_LANGUAGES = { deDE = "deDE", frFR = "frFR", esES = "esES", esMX = "esES" }

function ns.DefaultLanguage()
  return CLIENT_LANGUAGES[GetLocale()] or "enUS"
end

-- L.KEY liefert den Text in der eingestellten Sprache, Fallback Englisch
ns.L = setmetatable({}, {
  __index = function(_, key)
    local lang = (ns.db and ns.db.language) or ns.DefaultLanguage()
    local strings = ns.locales[lang] or ns.locales.enUS
    return strings[key] or ns.locales.enUS[key] or key
  end,
})

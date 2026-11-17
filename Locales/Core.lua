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

-- Einstellungswert "folgt dem Client" (Standard); nur eine bewusste Wahl speichert einen Sprachcode
ns.AUTO_LANGUAGE = "auto"

function ns.DefaultLanguage()
  return CLIENT_LANGUAGES[GetLocale()] or "enUS"
end

-- Eingestellte Sprache des Addons (Einstellung language), sonst die des Clients
function ns.Language()
  local language = ns.db and ns.db.language
  if language and language ~= ns.AUTO_LANGUAGE then return language end
  return ns.DefaultLanguage()
end

-- L.KEY liefert den Text in der eingestellten Sprache, Fallback Englisch
ns.L = setmetatable({}, {
  __index = function(_, key)
    local strings = ns.locales[ns.Language()] or ns.locales.enUS
    return strings[key] or ns.locales.enUS[key] or key
  end,
})

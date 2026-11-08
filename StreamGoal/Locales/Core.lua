-- Texte von Level Time Goals: je Sprache eine Datei (Locales/deDE.lua, enUS.lua, frFR.lua, esES.lua, geladen nach
-- dieser). Sie werden in die Sprachtabellen von Level Time eingehängt (Schlüssel mit Präfix SG_), damit die gemeinsamen
-- Bausteine (Tabelle, Karten, Export) sie in der dort gewählten Sprache finden; ns.L ist das L von Level Time.
local _, ns = ...
local LT = LevelTimerAPI

ns.locales = {}  -- [Sprache] = Texte dieser Sprache (tests/streamgoal_locales_test.lua vergleicht sie mit enUS)

-- Texte einer Sprache merken und in Level Time einhängen
function ns.AddLocale(code, texts)
  ns.locales[code] = texts
  local target = LT.locales[code]
  for key, text in pairs(texts) do target[key] = text end
end

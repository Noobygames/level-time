-- Sprachen: jede Sprache hat jeden Text mit denselben Platzhaltern wie Englisch.
local locales = addon.locales
local english = locales.enUS

-- Platzhalter %s und %d in Reihenfolge, z.B. "sdd"
local function placeholders(text)
  local result = {}
  for kind in text:gmatch("%%([sd])") do
    table.insert(result, kind)
  end
  return table.concat(result)
end

for _, language in ipairs(addon.languages) do
  local strings = locales[language.code]
  expectTrue("Texte für " .. language.code, strings ~= nil)
  if strings then
    for key, text in pairs(english) do
      local translated = strings[key]
      if translated == nil then
        expectTrue(language.code .. " fehlt " .. key, false)
      else
        expect(language.code .. " Platzhalter " .. key, placeholders(translated), placeholders(text))
      end
    end
    for key, text in pairs(strings) do
      expectTrue(language.code .. " hat überzähligen Text " .. key, english[key] ~= nil)
      -- Schutz vor Werkzeug-Fehlern: Git Bash macht aus "/played" sonst "C:/Program Files/Git/played"
      expect(language.code .. " Dateipfad in " .. key, text:find("^%a:/"), nil)
    end
  end
end

-- Standardsprache folgt dem Client
local originalGetLocale = GetLocale
for clientLocale, expected in pairs({ deDE = "deDE", frFR = "frFR", esES = "esES", esMX = "esES", ruRU = "enUS" }) do
  GetLocale = function() return clientLocale end
  expect("Standardsprache für " .. clientLocale, addon.DefaultLanguage(), expected)
end
GetLocale = originalGetLocale

-- Umschalten in den Einstellungen
wow.login()
SlashCmdList.LEVELTIMER("config")
expectTrue("Reiter Français", wow.click("Français"))
expect("französische Texte", addon.L.ROW_DEATHS, "Morts")
expectTrue("Reiter Español", wow.click("Español"))
expect("spanische Texte", addon.L.ROW_DEATHS, "Muertes")
SlashCmdList.LEVELTIMER("history")
expectTrue("Historie auf Spanisch", wow.click("Gráficos"))

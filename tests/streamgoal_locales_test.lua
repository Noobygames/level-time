-- Level Time Goals: jede Sprache hat jeden Text mit denselben Platzhaltern wie Englisch, und alle landen in den
-- Sprachtabellen von Level Time (die gemeinsamen Bausteine lesen sie dort).
local texts = streamGoal.locales
local english = texts.enUS

local function placeholders(text)
  local result = {}
  for kind in text:gmatch("%%([sd])") do table.insert(result, kind) end
  return table.concat(result)
end

for _, language in ipairs(addon.languages) do
  local strings = texts[language.code]
  expectTrue("Texte für " .. language.code, strings ~= nil)
  if strings then
    for key, text in pairs(english) do
      if strings[key] == nil then
        expectTrue(language.code .. " fehlt " .. key, false)
      else
        expect(language.code .. " Platzhalter " .. key, placeholders(strings[key]), placeholders(text))
        expect(language.code .. " in Level Time eingehängt " .. key, addon.locales[language.code][key], strings[key])
      end
    end
    for key in pairs(strings) do
      expectTrue(language.code .. " hat überzähligen Text " .. key, english[key] ~= nil)
    end
  end
end

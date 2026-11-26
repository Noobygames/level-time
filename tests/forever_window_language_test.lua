-- Fenster, die beim Laden gebaut werden, folgen der Addon-Sprache (Client deDE, Addon enUS) und dem Sprachwechsel:
-- feste Texte dürfen nicht beim Laden mit der Client-Sprache gesetzt werden.
local function hasText(text)
  return wow.findFrame(function(frame) return rawget(frame, "_text") == text end) ~= nil
end

-- Kein Text beim Laden (vor PLAYER_LOGIN) gelesen: der käme in der Client-Sprache (wow_stub.lua merkt die Zugriffe)
expect("Texte beim Laden", table.concat(wow.earlyTexts, "; "), "")

wow.login({ level = 30, xp = 0, xpMax = 10000 })
addon.Set("language", "enUS")
addon.Hints.Add({ text = "test" })
for _, pair in ipairs({
  { "Hinweise", "Hints" },                                                  -- Titel Hinweisfenster
  { "Nicht mehr automatisch anzeigen", "Don't show automatically" },       -- Haken Dungeon Guide
}) do
  expect("kein deutscher Text: " .. pair[1], hasText(pair[1]), false)
  expectTrue("englischer Text: " .. pair[2], hasText(pair[2]))
end

-- Wechsel zurück auf Deutsch
addon.Set("language", "deDE")
expectTrue("Wechsel: deutscher Titel", hasText("Hinweise"))

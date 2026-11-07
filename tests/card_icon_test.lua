-- Karten (Lib/Card.lua, Roadmap 401): dasselbe Symbol wird nicht bei jedem Set neu aufgelöst und gesetzt
local Card = addon.Card

wow.login({ level = 10 })
local card = Card.Create("LevelTimerTestCard")
local lookups = { count = 0 }
local getSpellTexture = C_Spell.GetSpellTexture
C_Spell.GetSpellTexture = function(...)
  lookups.count = lookups.count + 1
  return getSpellTexture(...)
end

local color = { 1, 1, 1 }
card.Set({ color = color, icon = 19705, title = "Eins" })
expect("erstes Set löst auf", lookups.count, 1)
for index = 1, 10 do card.Set({ color = color, icon = 19705, title = "Titel " .. index }) end
expect("gleiches Symbol: nicht neu aufgelöst", lookups.count, 1)
expect("Titel trotzdem neu", card.frame.title:GetText(), "Titel 10")
card.Set({ color = color, icon = 1229741, title = "Anders" })
expect("anderes Symbol: aufgelöst", lookups.count, 2)
card.Set({ color = color, texture = "Interface\\Icons\\INV_Misc_Note_01", title = "Pfad" })
expect("Pfad gesetzt", card.frame.icon:GetTexture(), "Interface\\Icons\\INV_Misc_Note_01")
card.Set({ color = color, icon = 1229741, title = "Zurück" })
expect("wieder Spell nach Pfad: aufgelöst", lookups.count, 3)
C_Spell.GetSpellTexture = getSpellTexture

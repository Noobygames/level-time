-- LT-330: Über der Höchststufe aller Ziel-Instanzen bietet niemand mehr die Dungeonquest an (Höhlen des Wehklagens
-- 15-25, Quest 1486 "Deviate Hides" ab 13, ohne Vorquest und Fraktion)
local DungeonQuests = addon.DungeonQuests
local DEVIATE_HIDES = 1486

wow.login({ level = 20 })
expect("im Levelbereich annehmbar", DungeonQuests.CanTake(DEVIATE_HIDES), true)
expectTrue("Angebot im Levelbereich", DungeonQuests.Offer(DEVIATE_HIDES) ~= nil)
wow.levelUp(25)
expect("an der Höchststufe noch annehmbar", DungeonQuests.CanTake(DEVIATE_HIDES), true)
wow.levelUp(26)
expect("darüber nicht mehr angeboten", DungeonQuests.CanTake(DEVIATE_HIDES), false)
expect("kein Angebot mehr", DungeonQuests.Offer(DEVIATE_HIDES), nil)
wow.levelUp(41)
local listed = false
for _, quest in ipairs(DungeonQuests.InstanceQuests(43)) do
  if quest.questID == DEVIATE_HIDES then listed = quest.available end
end
expect("in der Instanzliste nicht annehmbar", listed, false)
expect("keine Lua-Fehler", #wow.errors, 0)

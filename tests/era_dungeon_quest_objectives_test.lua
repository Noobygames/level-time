-- Questziele der Dungeonquests (Classic Era, DungeonDB): Tötungsziel (203), Beute mit NPC- und Objektquellen (204),
-- Objektziel-Quelle (17) und Quest ohne Zieldaten.
local DQ = addon.DungeonQuests

wow.login({ level = 14 })

local kill = DQ.Objectives(203)
expect("Tötungsziel", kill.npcs[1], 937)
expectTrue("Tötungsziel ohne items", kill.items == nil)

local loot = DQ.Objectives(204)
expect("Beute-NPC", loot.items[2633].npcs[2], 941)
expect("Beute-Objekt", loot.items[2634].objects[1], 263)

expect("Objekt-Quelle", DQ.Objectives(17).items[8047].objects[1], 126049)

local targets = DQ.TargetNpcs(204)
expectTrue("Zielmenge enthält Beute-NPCs", targets[940] and targets[941] and targets[942])
expectTrue("Objekt-Quellen sind keine NPCs", targets[263] == nil)
expectTrue("TargetNpcs gecacht", DQ.TargetNpcs(204) == targets)
expectTrue("Objektquelle allein ohne NPC", DQ.TargetNpcs(17) == nil)

expectTrue("unbekannte Quest", DQ.Objectives(999999999) == nil and DQ.TargetNpcs(999999999) == nil)
expectTrue("keine Zahl", DQ.Objectives("x") == nil)

-- LT-412: Fizzle Brassbolts (NPC 4454) bietet Stufe 45 den grauen Kettenschritt 1 (1104, Uldaman) an: Ausrufezeichen
-- am Zielfenster; im Hinweis steht Schritt 1, nach der Annahme der nächste offene Schritt.
local DQ = addon.DungeonQuests
local created = {}
local realCreate = CreateFrame
CreateFrame = function(kind, name, parent)
  local frame = realCreate(kind, name, parent)
  if parent then created[parent] = frame end
  return frame
end
TargetFrame = CreateFrame("Frame")

wow.state.class = "WARRIOR"
wow.state.faction = "Horde"
wow.state.units.target = { name = "Fizzle Brassbolts", guid = "Creature-0-4379-1-31-4454-0001" }
wow.login({ level = 45 })
wow.fire("PLAYER_TARGET_CHANGED")

local offers = DQ.UnitOffers("target")
expect("Schritt 1 im Angebot", offers[1] and offers[1].questID, 1104)
expect("Schritt 1 von 7", offers[1].step, 1)
local mark = created[TargetFrame]
expectTrue("Zielfenster markiert", mark ~= nil and mark:IsShown())
expectTrue("Ausrufezeichen", mark.bang:IsShown())
expectTrue("kein Dungeon-Symbol", not mark.icon:IsShown())

local first
for _, quest in ipairs(DQ.InstanceQuests(70)) do
  if quest.step and not first then first = quest end
end
expect("Hinweisliste beginnt mit Schritt 1", first.step, 1)

wow.state.questLog = { { questID = 1104, title = "Salt Flat Venom", objectives = {} } }
wow.fire("QUEST_LOG_UPDATE")
local next1
for _, quest in ipairs(DQ.InstanceQuests(70)) do
  if quest.step and not next1 then next1 = quest end
end
-- 1105 ist die zweite Quest auf Stufe 1, erst beide zusammen öffnen Stufe 2 (1106)
expect("nach Annahme die andere Quest der Stufe 1", next1.questID, 1105)
expect("keine Lua-Fehler", #wow.errors, 0)

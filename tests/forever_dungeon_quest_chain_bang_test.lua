-- LT-412: Häuptling Hawkwind (NPC 2981) bietet Stufe 45 den grauen Kettenschritt 1 (752, Maraudon) an: Ausrufezeichen
-- am Zielfenster; im Hinweis steht Schritt 1, nach der Annahme Schritt 2.
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
wow.state.units.target = { name = "Häuptling Hawkwind", guid = "Creature-0-4379-1-31-2981-0001" }
wow.login({ level = 45 })
wow.fire("PLAYER_TARGET_CHANGED")

local offers = DQ.UnitOffers("target")
expect("Schritt 1 im Angebot", offers[1] and offers[1].questID, 752)
expect("Schritt 1 von 7", offers[1].step, 1)
local mark = created[TargetFrame]
expectTrue("Zielfenster markiert", mark ~= nil and mark:IsShown())
expectTrue("Ausrufezeichen", mark.bang:IsShown())
expectTrue("kein Dungeon-Symbol", not mark.icon:IsShown())

local first
for _, quest in ipairs(DQ.InstanceQuests(349)) do
  if quest.step and not first then first = quest end
end
expect("Hinweisliste beginnt mit Schritt 1", first.step, 1)

wow.state.questLog = { { questID = 752, title = "A Humble Task", objectives = {} } }
wow.fire("QUEST_LOG_UPDATE")
local next1
for _, quest in ipairs(DQ.InstanceQuests(349)) do
  if quest.step and not next1 then next1 = quest end
end
expect("nach Annahme Schritt 2", next1.questID, 753)
expect("keine Lua-Fehler", #wow.errors, 0)

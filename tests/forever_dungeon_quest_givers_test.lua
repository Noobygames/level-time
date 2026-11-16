-- LT-304: Andrew Brownell (Unterstadt, NPC 2308) bietet der Horde-Schamanin Stufe 40 "Das Ende bringen" (3341) an;
-- die Plakette steht schon vor dem Laden (/reload in der Stadt, kein NAME_PLATE_UNIT_ADDED) und wird trotzdem markiert.
local DQ = addon.DungeonQuests

local plates = { nameplate1 = CreateFrame("Frame") }
C_NamePlate = { GetNamePlateForUnit = function(unit) return plates[unit] end }
local created = {}
local realCreate = CreateFrame
CreateFrame = function(kind, name, parent)
  local frame = realCreate(kind, name, parent)
  if parent then created[parent] = frame end
  return frame
end

wow.state.class = "SHAMAN"
wow.state.faction = "Horde"
wow.state.units.nameplate1 = { name = "Andrew Brownell", guid = "Creature-0-4379-0-31-2308-0001" }
wow.login({ level = 40 })
wow.fire("PLAYER_ENTERING_WORLD")
wow.fire("QUEST_LOG_UPDATE")

expectTrue("3341 annehmbar", DQ.CanTake(3341))
expect("Geber bietet 3341", DQ.GiverOffers("npc", 2308)[1].questID, 3341)
wow.fire("QUEST_LOG_UPDATE")
wow.update(2)
local mark = created[plates.nameplate1]
expectTrue("Plakette ohne ADDED-Ereignis markiert", mark ~= nil and mark:IsShown())

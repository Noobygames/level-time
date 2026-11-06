-- Rolle des Spielers in der Gruppe (Ansagen für Heiler: Mana, Kontrollverlust).
--   GroupRole.IsHealerInGroupInstance()  Rolle Heiler (UnitGroupRolesAssigned), in einem Dungeon oder Schlachtzug
--                                        und in einer Gruppe, die man anschreiben kann (GroupChat.PartyChannel)
local _, ns = ...

local GroupRole = {}
ns.GroupRole = GroupRole

local HEALER = "HEALER"
local GROUP_INSTANCES = { party = true, raid = true }

function GroupRole.IsHealer()
  if not UnitGroupRolesAssigned then return false end
  local role = UnitGroupRolesAssigned("player")
  return not ns.IsSecret(role) and role == HEALER
end

function GroupRole.IsHealerInGroupInstance()
  if not GroupRole.IsHealer() then return false end
  local inInstance, instanceType = IsInInstance()
  return inInstance and GROUP_INSTANCES[instanceType] == true and ns.GroupChat.PartyChannel() ~= nil
end

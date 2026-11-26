-- LT-283: Quests der neuen Forever-Dungeons in der DungeonDB: Instanz-Zuordnung, Geber, Vorquest-Ketten
local DB = addon.DungeonDB

local function inInstance(mapID, questID)
  for _, id in ipairs(DB.quests[mapID] or {}) do
    if id == questID then return true end
  end
  local chain = DB.questChains[questID]
  return chain ~= nil and chain[1] == mapID
end

-- Karten-ID, Quest, Geber-NPC (nil = Geber in der Instanz)
local cases = {
  { 2970, 95775, 2519 }, -- Die versunkene Stadt
  { 3039, 94982, 257558 }, -- Festung Krol'dok
  { 3065, 96395, 265002 }, -- Halle der Thanen
  { 2994, 95262, 260271 }, -- Gefängnis von Alcaz (Allianz)
  { 2994, 95309, 260383 }, -- Gefängnis von Alcaz (Horde)
  { 2994, 95454, nil },
  { 2999, 92401, 250686 }, -- Ruinen von Lordaeron
  { 2959, 96986, 2278 }, -- Dalaran
}
for _, case in ipairs(cases) do
  local mapID, questID, giver = case[1], case[2], case[3]
  expectTrue("Quest " .. questID .. " in Instanz " .. mapID, inInstance(mapID, questID))
  expectTrue("Quest " .. questID .. " hat Questdaten", DB.questInfo[questID] ~= nil)
  expect("Geber von " .. questID, DB.questInfo[questID][6], giver)
end

-- Alcaz-Kette Allianz: Shaw > Sully > Sully > Das geheime Gefängnis, Horde: Eitrigg > Nazeer > Ulka > Ulka
expect("Allianz-Kette Anfang", DB.questChains[95194][2], 95262)
expect("Allianz-Kette Gesamt", DB.questChains[95194][4], 4)
-- Import-Fehler: Ritus der Sicht (771, Mulgore) hing wegen eines Questziels mit Razorlash an Maraudon
expect("Ritus der Sicht keine Maraudon-Quest", DB.questChains[767], nil)
expect("Ritus der Kraft keine Vorquest", DB.questChains[757], nil)
expect("Horde-Kette Anfang", DB.questChains[95283][2], 96332)
expect("Horde-Kette hinten", DB.questChains[95285][3], 3)
expect("Vorquest Allianz", DB.questInfo[96381].preAny[1], 95198)
expectTrue("Sully gibt 95262", DB.givers.npc[260271][3] == 95262)

-- LT-328: Negolash anlocken (619) ist in Forever eine Düsterbruch-Quest, aber nicht schon ab 35 annehmbar
expect("619 Mindeststufe", DB.questInfo[619][2], 51)

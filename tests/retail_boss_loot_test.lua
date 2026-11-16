-- LT-298: Retail-Boss-Beute aus dem Encounter Journal (Stub der EJ-Funktionen)
local BossLoot = addon.BossLoot
local calls = { selectInstance = {}, selectEncounter = {} }
local current = { instance = 99, encounter = 7 }
local loot = {
  [7] = {},
  [500] = { { itemID = 1, itemQuality = 4 }, { itemID = 2, itemQuality = 2 }, { itemID = 3, itemQuality = "ffa335ee" },
    { itemID = 4, itemQuality = 3 } },
}
local reads = { count = 0 }
ITEM_QUALITY_COLORS = { [4] = { hex = "|cffa335ee" } }

C_EncounterJournal = {
  GetInstanceForGameMap = function(mapID) return mapID == 43 and 63 or nil end,
  GetLootInfoByIndex = function(index) return loot[current.encounter][index] end,
  GetSlotFilter = function() return 0 end,
  ResetSlotFilter = function() end,
  SetSlotFilter = function() end,
}
function EJ_GetCurrentInstance() return current.instance end
function EJ_SelectInstance(id) calls.selectInstance[#calls.selectInstance + 1] = id; current.instance = id end
function EJ_SelectEncounter(id) calls.selectEncounter[#calls.selectEncounter + 1] = id; current.encounter = id end
function EJ_GetEncounterInfoByIndex(index)
  local boss = ({ { 400, 1000 }, { 500, 2000 } })[index]  -- { journalID, dungeonEncounterID }
  if boss then return "Boss", "", boss[1], 0, "", 63, boss[2], 43 end
end
function EJ_GetNumLoot() reads.count = reads.count + 1; return #(loot[current.encounter] or {}) end
EncounterJournal = { encounterID = 7, IsShown = function() return false end }

wow.login({ level = 20, xp = 0, xpMax = 100000 })

expectTrue("Journal gilt als Beutequelle", BossLoot.IsAvailable())
local drops = BossLoot.ForEncounter(43, 2000)
expect("nur rar und besser", #drops, 3)
expect("episch zuerst", drops[1][1], 1)
expect("Farbcode als Qualität", drops[2][2], 4)
expect("Rar zuletzt", drops[3][1], 4)
expect("vorherige Instanz wiederhergestellt", current.instance, 99)
expect("vorherige Begegnung wiederhergestellt", current.encounter, 7)
BossLoot.ForEncounter(43, 2000)
expect("zwischengespeichert", reads.count, 1)
expect("ForBoss ohne NPC-Daten nutzt das Journal", #BossLoot.ForBoss(nil, 43, 2000), 3)
expect("unbekannte Karte ohne Beute", #BossLoot.ForEncounter(1, 3000), 0)
expect("unbekannte Begegnung ohne Beute", #BossLoot.ForEncounter(43, 9999), 0)

-- geöffnetes Journal: keine Auswahländerung
EncounterJournal.IsShown = function() return true end
local before = #calls.selectInstance
expect("offenes Journal: keine Beute gelesen", #BossLoot.ForEncounter(43, 1000), 0)
expect("offenes Journal: Auswahl unberührt", #calls.selectInstance, before)

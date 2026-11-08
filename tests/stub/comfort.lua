-- Teil der nachgebauten WoW-API (tests/wow_stub.lua):
-- Komfort: Beschwörung, Beute, Flugkarte, Würfeln um Beute.
-- Gemeinsame Helfer kommen über stub (Spielzustand, Frames).
local stub = ...
local state = stub.state

-- Beschwörung: state.summon = { summoner, area }; Aufrufe landen in wow.comfortActions
wow.comfortActions = {}
local function comfortAction(...) table.insert(wow.comfortActions, { ... }) end
C_SummonInfo = {
  GetSummonConfirmSummoner = function() return state.summon and state.summon.summoner end,
  GetSummonConfirmAreaName = function() return state.summon and state.summon.area end,
  ConfirmSummon = function() comfortAction("confirmSummon") end,
}
function AcceptResurrect() comfortAction("acceptResurrect") end
function RepopMe() comfortAction("repop") end
C_DeathInfo = { GetSelfResurrectOptions = function() return state.selfResurrect or {} end }
-- Beute: state.lootSlots = Anzahl; LootSlot merkt den Platz
-- Flugkarte: state.taxiNodes = { { name, type, x, y, id, hops } } (type "CURRENT", "REACHABLE", ...; x/y wie
-- TaxiNodePosition; id = nodeID aus C_TaxiMap.GetAllTaxiNodes, ohne id liefert der Client den Knoten dort nicht;
-- hops = { { vonSlot, nachSlot }, ... } Teilstrecken, Standard eine direkte vom CURRENT-Knoten); state.taxiMapID
function NumTaxiNodes() return #(state.taxiNodes or {}) end
function TaxiNodeName(index) return state.taxiNodes[index].name end
function TaxiNodeGetType(index) return state.taxiNodes[index].type end
function TaxiNodePosition(index) local node = state.taxiNodes[index]; return node.x or 0, node.y or 0 end
function TakeTaxiNode() end
function GetTaxiMapID() return state.taxiMapID or 0 end
local function taxiHops(index)
  local node = state.taxiNodes[index]
  if node.hops then return node.hops end
  for slot, other in ipairs(state.taxiNodes) do
    if other.type == "CURRENT" then return { { slot, index } } end
  end
  return {}
end
function GetNumRoutes(index) return #taxiHops(index) end
function TaxiGetNodeSlot(index, hop, source)
  local part = taxiHops(index)[hop]
  return source and part[1] or part[2]
end
C_TaxiMap = {
  GetAllTaxiNodes = function()
    local nodes = {}
    for slot, node in ipairs(state.taxiNodes or {}) do
      if node.id then table.insert(nodes, { nodeID = node.id, slotIndex = slot, name = node.name }) end
    end
    return nodes
  end,
}
-- Blizzards Tooltip der Flugpunkte (TaxiFrame), damit Hooks darauf greifen
function TaxiNodeOnButtonEnter(button)
  GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
  GameTooltip:AddLine(TaxiNodeName(button:GetID()))
end
function GetNumLootItems() return state.lootSlots or 0 end
function LootSlot(slot) comfortAction("loot", slot) end
function ConfirmLootRoll(rollID, rollType) comfortAction("confirmRoll", rollID, rollType) end
-- Würfeln um Beute: state.lootRolls[rollID] = { link, name, texture, quality }, state.activeLootRolls = { rollID, ... }
function GetLootRollItemLink(rollID) return ((state.lootRolls or {})[rollID] or {}).link end
function GetLootRollItemInfo(rollID)
  local roll = (state.lootRolls or {})[rollID]
  if not roll then return nil end
  return roll.texture or 134400, roll.name, 1, roll.quality or 2, false, true, true, false
end
function GetActiveLootRollIDs() return state.activeLootRolls or {} end
function GetLootRollTimeLeft() return 60000 end
-- Würfel-Historie wie im Client: Classic Era (era_*) das alte C_LootHistory (state.lootHistory = { { rollID, link,
-- isDone, winnerIdx, players = { { name, class, rollType, roll, isWinner } } } }), sonst das neue je Beute
-- (state.lootDrops["encounterID:lootListID"] = EncounterLootDropInfo, state.encounterDrops[encounterID] = Liste)
if state.interface < 16000 then  -- unter 16000 (Classic Era) altes C_LootHistory, sonst (Forever 16xxx, Retail) neues
  C_LootHistory = {
    GetNumItems = function() return #(state.lootHistory or {}) end,
    GetItem = function(index)
      local item = state.lootHistory[index]
      return item.rollID, item.link, #item.players, item.isDone == true, item.winnerIdx
    end,
    GetPlayerInfo = function(index, playerIndex)
      local player = state.lootHistory[index].players[playerIndex]
      return player.name, player.class, player.rollType, player.roll, player.isWinner == true
    end,
  }
else
  C_LootHistory = {
    GetSortedInfoForDrop = function(encounterID, lootListID)
      return (state.lootDrops or {})[encounterID .. ":" .. lootListID]
    end,
    GetSortedDropsForEncounter = function(encounterID) return (state.encounterDrops or {})[encounterID] end,
  }
end
-- Blizzards Würfelfenster (GroupLootFrame1..4, versteckt; Tests setzen rollID und zeigen sie)
for index = 1, 4 do
  local frame = CreateFrame("Frame", "GroupLootFrame" .. index, UIParent)
  frame._shown = false
end
function ConfirmLootSlot(slot) comfortAction("confirmBind", slot) end
function RequestTimePlayed() end

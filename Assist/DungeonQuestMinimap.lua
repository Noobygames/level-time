-- Dungeonquest-Geber auf der Minimap (LT-37; Einstellung dungeonQuestMinimap unter dungeonQuestGivers, an; Randsymbole
-- dungeonQuestMinimapEdge, an): Geber mit Ort aus der DungeonDB, die dem Charakter jetzt eine Dungeonquest oder einen
-- Kettenschritt anbieten, erscheinen nach Entfernung zum Spieler auf der Minimap, auch jenseits einer Zonengrenze.
-- Platzierung, Rand und Takt: Lib/MinimapPins.lua.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    dungeonQuestMinimap = true,
    dungeonQuestMinimapEdge = true,
  },
})
local DungeonQuests = ns.DungeonQuests
local Givers = ns.DungeonQuestGivers

local DungeonQuestMinimap = {}
ns.DungeonQuestMinimap = DungeonQuestMinimap

local PIN_SIZE = 14

function DungeonQuestMinimap.IsAvailable()
  return Givers.IsAvailable()
end

local function newPin(parent, size)
  local pin = Givers.NewMark(parent, size)
  pin:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    Givers.AddOfferLines(GameTooltip, self.offers)
    GameTooltip:Show()
  end)
  pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return pin
end

local layer = ns.MinimapPins.Create({
  size = PIN_SIZE,
  enabled = function(db)
    return db.dungeonQuestGivers and db.dungeonQuestMinimap and DungeonQuestMinimap.IsAvailable()
  end,
  edge = function(db) return db.dungeonQuestMinimapEdge end,
  key = DungeonQuests.Revision,
  candidates = function(instanceID)
    return ns.MinimapPins.Collect(instanceID, DungeonQuests.GiverMapIDs(), DungeonQuests.OffersOnMap)
  end,
  newPin = newPin,
  show = function(pin, candidate)
    pin.offers = candidate.offers
    Givers.ShowMark(pin, candidate.offers)
  end,
})
DungeonQuestMinimap.Update = layer.Update

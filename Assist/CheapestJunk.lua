-- Taschen voll: billigsten grauen Gegenstand per Klick löschen (Einstellung deleteCheapestJunk, aus).
-- Sind die normalen Taschen voll, erscheint ein Knopf mit Name und Verkaufswert des billigsten grauen Gegenstands
-- (Stückzahl mal Preis). Der Klick löscht ihn (Bags.Pickup + DeleteCursorItem; beides geht nur aus einem Klick).
-- Der Knopf ist wie die anderen Anzeigen verschiebbar (Frames.Register).
-- Nur Qualität grau, mit bekanntem Verkaufswert, nicht gesperrt und nie ein Quest-Gegenstand.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    deleteCheapestJunk = false,
  },
})
local L = ns.L

local CheapestJunk = {}
ns.CheapestJunk = CheapestJunk

local POOR_QUALITY = 0
local BUTTON_MIN_WIDTH, BUTTON_HEIGHT = 200, 24
local DEFAULT_POSITION = { "BOTTOM", "BOTTOM", 0, 240 }
local CHECK_SECONDS = 2

local button
local shown  -- Platz, den der Knopf gerade anbietet

-- Grau, mit Verkaufswert, nicht gesperrt, kein Quest-Gegenstand
local function isDeletable(bag, slot, info)
  local itemID, quality = info.itemID, info.quality
  if ns.IsSecret(itemID) or ns.IsSecret(quality) or quality ~= POOR_QUALITY
      or info.hasNoValue or info.isLocked then return false end
  local questInfo = C_Container.GetContainerItemQuestInfo and C_Container.GetContainerItemQuestInfo(bag, slot)
  return not (questInfo and questInfo.isQuestItem)
end

-- Billigster Platz { bag, slot, itemID, count, value } oder nil
function CheapestJunk.Find()
  local cheapest
  ns.Bags.ForEachItem(function(bag, slot, info)
    if not isDeletable(bag, slot, info) then return end
    local price = ns.Items.GetSellPrice(info.itemID)
    if not price then return end
    local count = info.stackCount or 1
    if not cheapest or price * count < cheapest.value then
      cheapest = { bag = bag, slot = slot, itemID = info.itemID, count = count, value = price * count }
    end
  end)
  return cheapest
end

local function describe(entry)
  local name = ns.Items.GetName(entry.itemID) or tostring(entry.itemID)
  if entry.count > 1 then name = string.format("%s x%d", name, entry.count) end
  return string.format(L.DELETE_CHEAPEST_JUNK_BUTTON, name, ns.Format.Money(entry.value))
end

-- Platz ist noch genau der angebotene Gegenstand (gleiche ID und Stückzahl, weiter löschbar)
local function stillOffered(entry)
  local info = C_Container.GetContainerItemInfo(entry.bag, entry.slot)
  return info ~= nil and not ns.IsSecret(info.itemID) and info.itemID == entry.itemID
    and (info.stackCount or 1) == entry.count and isDeletable(entry.bag, entry.slot, info)
end

-- Der Klick löscht nur den angebotenen Platz, und nur wenn er sich seit der Anzeige nicht geändert hat
local function onClick()
  local entry = shown
  if not entry or ns.InCombat() then return end
  if stillOffered(entry) then
    if CursorHasItem() then ClearCursor() end
    ns.Bags.Pickup(entry.bag, entry.slot)
    if CursorHasItem() then
      DeleteCursorItem()
      ns.Debug("bags", "deleted cheapest junk %s from %s/%s", entry.itemID, entry.bag, entry.slot)
    end
  end
  CheapestJunk.Update()
end

-- Beispielinhalt im Edit-Modus und in der Vorschau
local function setPreview(enabled)
  if enabled then
    ns.Widgets.SetButtonText(button, string.format(L.DELETE_CHEAPEST_JUNK_BUTTON, "?", ns.Format.Money(0)),
      BUTTON_MIN_WIDTH)
    button:Show()
  else
    CheapestJunk.Update()
  end
end

function CheapestJunk.Update()
  if ns.EditMode and ns.EditMode.IsActive() then return end
  shown = ns.db and ns.db.deleteCheapestJunk and not ns.InCombat()
    and ns.Bags.GetFreeSlots() <= 0 and CheapestJunk.Find() or nil
  if not shown then
    button:Hide()
    return
  end
  ns.Widgets.SetButtonText(button, describe(shown), BUTTON_MIN_WIDTH)
  button:Show()
end

button = ns.Widgets.CreateButton(UIParent, BUTTON_MIN_WIDTH, BUTTON_HEIGHT, onClick)
button:Hide()
ns.Widgets.AttachTooltip(button, function() return L.DELETE_CHEAPEST_JUNK end,
  function() return L.DELETE_CHEAPEST_JUNK_BUTTON_TIP end)
ns.Frames.Register({
  id = "cheapestJunk", frame = button, label = "EDIT_FRAME_CHEAPEST_JUNK", default = DEFAULT_POSITION,
  settingsPage = "COMFORT_PAGE_AUTOMATION", preview = setPreview, dragWhenUnlocked = true,
})

ns.RegisterEvent("BAG_UPDATE_DELAYED", CheapestJunk.Update)
ns.RegisterEvent("PLAYER_REGEN_ENABLED", CheapestJunk.Update)
ns.RegisterEvent("PLAYER_REGEN_DISABLED", CheapestJunk.Update)
ns.Every(CHECK_SECONDS, CheapestJunk.Update, function(db) return db.deleteCheapestJunk end)
ns.RegisterApply(CheapestJunk.Update)

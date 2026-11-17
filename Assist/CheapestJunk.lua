-- Taschen voll: billigsten grauen Gegenstand per Klick löschen (Einstellung deleteCheapestJunk, aus).
-- Sind die normalen Taschen voll, erscheint ein Knopf mit Name und Verkaufswert des billigsten grauen Gegenstands
-- (Stückzahl mal Preis). Der Klick löscht ihn (Bags.Pickup + DeleteCursorItem; beides geht nur aus einem Klick).
-- Knopf, Titel und Symbol des Gegenstands stehen in einem kleinen Fenster, das wie die anderen Anzeigen verschiebbar
-- ist (Frames.Register).
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
local PAD = 8
local ICON_SIZE = 32
local TITLE_HEIGHT = 18
local PREVIEW_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local window, icon, title
local button
local shown  -- Platz, den der Knopf gerade anbietet
local shownText  -- Text auf dem Knopf (neu gesetzt nur bei Änderung, SetButtonText misst die Breite)
-- Neu prüfen beim Takt: nur nach Sperr-Änderungen oder solange Preis oder Name eines grauen Gegenstands noch fehlt;
-- Taschen, Kampf und Einstellungen prüfen ohnehin sofort über ihre Ereignisse
local recheck = true

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
    if not price then
      recheck = true  -- Gegenstandsdaten noch nicht geladen
      return
    end
    local count = info.stackCount or 1
    if not cheapest or price * count < cheapest.value then
      cheapest = { bag = bag, slot = slot, itemID = info.itemID, count = count, value = price * count }
    end
  end)
  return cheapest
end

local function describe(entry)
  local name = ns.Items.GetName(entry.itemID)
  if not name then
    recheck = true
    name = tostring(entry.itemID)
  end
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
-- Fensterbreite folgt dem Knopf (Text in der Spielersprache)
local function fitWindow()
  title:SetText(L.DELETE_CHEAPEST_JUNK_TITLE)
  window:SetWidth(PAD + ICON_SIZE + PAD + math.max(button:GetWidth(), title:GetStringWidth() or 0) + PAD)
end

local function setPreview(enabled)
  if enabled then
    shownText = nil
    ns.Widgets.SetButtonText(button, string.format(L.DELETE_CHEAPEST_JUNK_BUTTON, "?", ns.Format.Money(0)),
      BUTTON_MIN_WIDTH)
    icon:SetTexture(PREVIEW_ICON)
    fitWindow()
    button:Show()
    window:Show()
  else
    CheapestJunk.Update()
  end
end

function CheapestJunk.Update()
  if ns.EditMode and ns.EditMode.IsActive() then return end
  recheck = false
  shown = ns.db and ns.db.deleteCheapestJunk and not ns.InCombat()
    and ns.Bags.GetFreeSlots() <= 0 and CheapestJunk.Find() or nil
  if not shown then
    window:Hide()
    return
  end
  local text = describe(shown)
  if text ~= shownText then
    shownText = text
    ns.Widgets.SetButtonText(button, text, BUTTON_MIN_WIDTH)
    icon:SetTexture(ns.Items.GetIcon(shown.itemID) or PREVIEW_ICON)
    fitWindow()
  end
  button:Show()
  window:Show()
end

-- Fenster: Titel oben, darunter Symbol des Gegenstands (Tooltip des Gegenstands) und der Knopf
window = ns.Widgets.CreatePanel(nil, 0.9)
window:SetHeight(PAD + TITLE_HEIGHT + ICON_SIZE + PAD)
window:Hide()
title = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOPLEFT", PAD, -PAD)
local iconFrame = CreateFrame("Frame", nil, window)
iconFrame:SetSize(ICON_SIZE, ICON_SIZE)
iconFrame:SetPoint("TOPLEFT", PAD, -(PAD + TITLE_HEIGHT))
icon = iconFrame:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints()
iconFrame:EnableMouse(true)
iconFrame:SetScript("OnEnter", function(self)
  if not shown then return end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetBagItem(shown.bag, shown.slot)
  GameTooltip:Show()
end)
iconFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
button = ns.Widgets.CreateButton(window, BUTTON_MIN_WIDTH, BUTTON_HEIGHT, onClick)
button:SetPoint("LEFT", iconFrame, "RIGHT", PAD, 0)
ns.Widgets.AttachTooltip(button, function() return L.DELETE_CHEAPEST_JUNK end,
  function() return L.DELETE_CHEAPEST_JUNK_BUTTON_TIP end)
ns.Frames.Register({
  id = "cheapestJunk", frame = window, label = "EDIT_FRAME_CHEAPEST_JUNK", default = DEFAULT_POSITION,
  settingsPage = "COMFORT_PAGE_AUTOMATION", preview = setPreview, dragWhenUnlocked = true,
})

ns.RegisterEvent("BAG_UPDATE_DELAYED", CheapestJunk.Update)
ns.RegisterEvent("PLAYER_REGEN_ENABLED", CheapestJunk.Update)
ns.RegisterEvent("PLAYER_REGEN_DISABLED", CheapestJunk.Update)
ns.RegisterEvent("ITEM_LOCK_CHANGED", function() recheck = true end)
ns.Every(CHECK_SECONDS, function()
  if recheck then CheapestJunk.Update() end
end, function(db) return db.deleteCheapestJunk end)
ns.RegisterApply(function()
  shownText = nil  -- Sprache kann gewechselt haben
  CheapestJunk.Update()
end)

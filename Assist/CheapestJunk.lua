-- Taschen voll: billige Gegenstände per Klick löschen (Einstellung deleteCheapestJunk, aus).
-- Sind die normalen Taschen voll, erscheint ein kleines Fenster mit bis zu MAX_OFFERS Gegenständen (Symbol mit
-- Tooltip, Knopf mit Name und Verkaufswert = Stückzahl mal Preis). Der Klick löscht genau diesen Platz
-- (Bags.Pickup + DeleteCursorItem; beides geht nur aus einem Klick). Reihenfolge: graue zuerst, dann weiße; je
-- Qualität der billigste vorn.
-- Grau: mit bekanntem Verkaufswert, nicht gesperrt, nie ein Quest-Gegenstand. Weiß zusätzlich nur Waffen, Rüstung und
-- Verschiedenes (keine Reagenzien, Verbrauchsgüter, Handwerkswaren, Munition, Taschen, Schlüssel), nie ein
-- Klassen-Reagenz (Reagents.CLASSES) und nur, wenn der Stapel höchstens WHITE_VALUE_PER_LEVEL × Stufe wert ist.
-- Das X schließt das Fenster, bis die Taschen wieder Platz hatten. Verschiebbar wie die anderen Anzeigen
-- (Frames.Register).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    deleteCheapestJunk = false,
  },
})
local L = ns.L

local CheapestJunk = {}
ns.CheapestJunk = CheapestJunk

local POOR_QUALITY, COMMON_QUALITY = 0, 1
CheapestJunk.MAX_OFFERS = 3
local WHITE_VALUE_PER_LEVEL = 10  -- Kupfer je Spielerstufe: Stufe 40 = 4 Silber
-- Gegenstandsklassen, aus denen weiße Gegenstände angeboten werden (Enum.ItemClass: Waffe, Rüstung, Verschiedenes)
local WHITE_CLASSES = { [2] = true, [4] = true, [15] = true }
local MISC_REAGENT_SUBCLASS = 1  -- Verschiedenes > Reagenz
local BUTTON_MIN_WIDTH, BUTTON_HEIGHT = 200, 24
local DEFAULT_POSITION = { "BOTTOM", "BOTTOM", 0, 240 }
local CHECK_SECONDS = 2
local PAD = 8
local ICON_SIZE = 28
local ROW_GAP = 4
local TITLE_HEIGHT = 18
local CLOSE_SPACE = 24  -- Platz für das X rechts neben dem Titel
local PREVIEW_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local window, title
local rows = {}
local shown = {}  -- angebotene Plätze, je Zeile einer
local shownKey     -- Texte der Zeilen (neu gesetzt nur bei Änderung, SetButtonText misst die Breite)
local dismissed = false  -- per X geschlossen: bleibt zu, bis die Taschen wieder Platz haben
-- Neu prüfen beim Takt: nur nach Sperr-Änderungen oder solange Preis oder Name eines Gegenstands noch fehlt;
-- Taschen, Kampf und Einstellungen prüfen ohnehin sofort über ihre Ereignisse
local recheck = true

-- Klassen-Reagenzien aller Klassen (Item-IDs), einmal gesammelt
local classReagents
local function isClassReagent(itemID)
  if not classReagents then
    classReagents = {}
    for _, groups in pairs(ns.Reagents and ns.Reagents.CLASSES or {}) do
      for _, group in ipairs(groups) do
        for _, entry in ipairs(group) do classReagents[entry.item] = true end
      end
    end
  end
  return classReagents[itemID] == true
end

-- Weißer Gegenstand, der als Müll gelten darf: Waffe, Rüstung oder Verschiedenes, kein Reagenz
local function isJunkClass(itemID)
  if isClassReagent(itemID) then return false end
  local getInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  if not getInstant then return false end
  local classID, subClassID = select(6, getInstant(itemID))
  if not WHITE_CLASSES[classID] then return false end
  return not (classID == 15 and subClassID == MISC_REAGENT_SUBCLASS)
end

-- Grau oder weiß, mit Verkaufswert, nicht gesperrt, kein Quest-Gegenstand
local function isCandidate(bag, slot, info)
  local itemID, quality = info.itemID, info.quality
  if ns.IsSecret(itemID) or ns.IsSecret(quality) or info.hasNoValue or info.isLocked then return false end
  if quality ~= POOR_QUALITY and not (quality == COMMON_QUALITY and isJunkClass(itemID)) then return false end
  local questInfo = C_Container.GetContainerItemQuestInfo and C_Container.GetContainerItemQuestInfo(bag, slot)
  return not (questInfo and questInfo.isQuestItem)
end

local function whiteLimit()
  return (UnitLevel("player") or 1) * WHITE_VALUE_PER_LEVEL
end

-- Bis zu limit Plätze { bag, slot, itemID, count, value, quality }: graue vor weißen, je Qualität billigste zuerst
function CheapestJunk.FindAll(limit)
  local found = {}
  local maxWhite = whiteLimit()
  ns.Bags.ForEachItem(function(bag, slot, info)
    if not isCandidate(bag, slot, info) then return end
    local price = ns.Items.GetSellPrice(info.itemID)
    if not price then
      recheck = true  -- Gegenstandsdaten noch nicht geladen
      return
    end
    local count = info.stackCount or 1
    local value = price * count
    if info.quality == COMMON_QUALITY and value > maxWhite then return end
    found[#found + 1] = { bag = bag, slot = slot, itemID = info.itemID, count = count, value = value,
      quality = info.quality }
  end)
  table.sort(found, function(a, b)
    if a.quality ~= b.quality then return a.quality < b.quality end
    return a.value < b.value
  end)
  for index = #found, (limit or CheapestJunk.MAX_OFFERS) + 1, -1 do found[index] = nil end
  return found
end

-- Erster Kandidat oder nil
function CheapestJunk.Find()
  return CheapestJunk.FindAll(1)[1]
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
    and (info.stackCount or 1) == entry.count and isCandidate(entry.bag, entry.slot, info)
end

-- Der Klick löscht nur den angebotenen Platz, und nur wenn er sich seit der Anzeige nicht geändert hat
local function deleteOffer(index)
  local entry = shown[index]
  if not entry or ns.InCombat() then return end
  if stillOffered(entry) then
    if CursorHasItem() then ClearCursor() end
    ns.Bags.Pickup(entry.bag, entry.slot)
    if CursorHasItem() then
      DeleteCursorItem()
      ns.Debug("bags", "deleted cheap item %s from %s/%s", entry.itemID, entry.bag, entry.slot)
    end
  end
  CheapestJunk.Update()
end

-- Zeilen füllen; Breite folgt dem breitesten Knopf (Text in der Spielersprache), Höhe der Zahl der Zeilen
local function layout(entries, texts)
  title:SetText(L.DELETE_CHEAPEST_JUNK_TITLE)
  local width = (title:GetStringWidth() or 0) + CLOSE_SPACE
  for index, row in ipairs(rows) do
    local entry = entries[index]
    row:SetShown(entry ~= nil)
    if entry then
      ns.Widgets.SetButtonText(row.button, texts[index], BUTTON_MIN_WIDTH)
      row.icon:SetTexture(entry.itemID and ns.Items.GetIcon(entry.itemID) or PREVIEW_ICON)
      width = math.max(width, ICON_SIZE + PAD + row.button:GetWidth())
    end
  end
  window:SetWidth(PAD + width + PAD)
  window:SetHeight(PAD + TITLE_HEIGHT + #entries * (ICON_SIZE + ROW_GAP) - ROW_GAP + PAD)
end

-- Beispielinhalt im Edit-Modus und in der Vorschau
local function setPreview(enabled)
  if enabled then
    shownKey = nil
    layout({ {} }, { string.format(L.DELETE_CHEAPEST_JUNK_BUTTON, "?", ns.Format.Money(0)) })
    window:Show()
  else
    CheapestJunk.Update()
  end
end

function CheapestJunk.Update()
  if ns.EditMode and ns.EditMode.IsActive() then return end
  recheck = false
  local full = ns.db and ns.db.deleteCheapestJunk and ns.Bags.GetFreeSlots() <= 0
  if not full then dismissed = false end
  shown = (full and not dismissed and not ns.InCombat()) and CheapestJunk.FindAll() or {}
  if #shown == 0 then
    window:Hide()
    return
  end
  local texts = {}
  for index, entry in ipairs(shown) do texts[index] = describe(entry) end
  local key = table.concat(texts, "\n")
  if key ~= shownKey then
    shownKey = key
    layout(shown, texts)
  end
  window:Show()
end

function CheapestJunk.IsShown()
  return window:IsShown()
end

-- Test-Zugriff: Zeilen (Knopf, Symbol)
function CheapestJunk.Rows()
  return rows
end

-- Fenster: Titel und X oben, darunter je Angebot Symbol (Tooltip des Gegenstands) und Löschen-Knopf
window = ns.Widgets.CreatePanel(nil, 0.9)
window:Hide()
title = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOPLEFT", PAD, -PAD)
local closeButton = ns.Widgets.CreateCloseButton(window)
closeButton:SetScript("OnClick", function()
  dismissed = true
  window:Hide()
end)
CheapestJunk.closeButton = closeButton

for index = 1, CheapestJunk.MAX_OFFERS do
  local row = CreateFrame("Frame", nil, window)
  row:SetHeight(ICON_SIZE)
  row:SetPoint("TOPLEFT", PAD, -(PAD + TITLE_HEIGHT + (index - 1) * (ICON_SIZE + ROW_GAP)))
  row:SetPoint("RIGHT", -PAD, 0)
  local iconFrame = CreateFrame("Frame", nil, row)
  iconFrame:SetSize(ICON_SIZE, ICON_SIZE)
  iconFrame:SetPoint("LEFT")
  row.icon = iconFrame:CreateTexture(nil, "ARTWORK")
  row.icon:SetAllPoints()
  iconFrame:EnableMouse(true)
  iconFrame:SetScript("OnEnter", function(self)
    local entry = shown[index]
    if not entry then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetBagItem(entry.bag, entry.slot)
    GameTooltip:Show()
  end)
  iconFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
  row.button = ns.Widgets.CreateButton(row, BUTTON_MIN_WIDTH, BUTTON_HEIGHT, function() deleteOffer(index) end)
  row.button:SetPoint("LEFT", iconFrame, "RIGHT", PAD, 0)
  ns.Widgets.AttachTooltip(row.button, function() return L.DELETE_CHEAPEST_JUNK end,
    function() return L.DELETE_CHEAPEST_JUNK_BUTTON_TIP end)
  rows[index] = row
end

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
  shownKey = nil  -- Sprache kann gewechselt haben
  CheapestJunk.Update()
end)

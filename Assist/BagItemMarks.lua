-- Quest-Gegenstände in den Taschen markieren (Einstellung bagQuestItemMarks im Reiter "Komfort" > Quests, an):
-- Blizzards Ausrufezeichen (TEXTURE_ITEM_QUEST_BANG) oben auf dem Taschenplatz für
--   * Gegenstände eines offenen Sammelziels ("Wolfsfleisch: 3/5"; QuestItemTooltip.IsOpenQuestItem, erfüllte Ziele
--     und abgegebene Quests zählen nicht mehr) und
--   * Gegenstände, für die der Client eine Quest meldet (C_Container.GetContainerItemQuestInfo: questID oder
--     isQuestItem; ItemQuestInfo in classic_era und forever).
-- Forever (ContainerFrameItemButtonMixin) zeigt für den zweiten Fall schon selbst IconQuestTexture: dann keine
-- Doppelmarkierung. Classic-ContainerFrame (Era) blendet sie in ContainerFrame_UpdateQuestItem immer aus.
-- Taschenplätze: ContainerFrame1..NUM_CONTAINER_FRAMES (+ ContainerFrameCombinedBags in Forever), Knöpfe über
-- EnumerateValidItems oder <Frame>Item<i>; Aktualisierung nur bei sichtbaren Taschen (BAG_UPDATE_DELAYED,
-- QUEST_LOG_UPDATE, OnShow der Taschenfenster). Fremde Taschen-Addons ersetzen die Frames: dann nichts zu tun.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    bagQuestItemMarks = true,
  },
})

local BagItemMarks = {}
ns.BagItemMarks = BagItemMarks

-- Gelbes Ausrufezeichen wie über Questgebern (auch in Assist/QuestMarks.lua), klein in der Ecke gut lesbar
local BANG_TEXTURE = "Interface\\GossipFrame\\AvailableQuestIcon"
local MARK_SIZE = 16
local MARK_INSET = 1
local DEFAULT_FRAME_COUNT = 13
local COMBINED_FRAME = "ContainerFrameCombinedBags"

local hooked = {}  -- [Taschenfenster] = true
local marks = setmetatable({}, { __mode = "k" })  -- [Taschenknopf] = Textur (je Knopf einmal)

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function isQuestRelevant(bag, slot)
  local info = C_Container.GetContainerItemInfo(bag, slot)
  if not info then return false end
  local questInfo = C_Container.GetContainerItemQuestInfo and C_Container.GetContainerItemQuestInfo(bag, slot)
  if type(questInfo) == "table" and (readable(questInfo.questID) or readable(questInfo.isQuestItem) == true) then
    return true
  end
  local itemID = readable(info.itemID)
  if type(itemID) ~= "number" then return false end
  local name = readable(info.itemName) or ns.Items.GetName(itemID)
  return ns.QuestItemTooltip.IsOpenQuestItem(itemID, name)
end

local function markOf(button)
  if not marks[button] then
    local mark = button:CreateTexture(nil, "OVERLAY")
    mark:SetTexture(BANG_TEXTURE)
    -- Klein oben links, damit Symbol und Stapelzahl sichtbar bleiben
    mark:SetSize(MARK_SIZE, MARK_SIZE)
    mark:SetPoint("TOPLEFT", button, "TOPLEFT", MARK_INSET, -MARK_INSET)
    marks[button] = mark
  end
  return marks[button]
end

local function updateButton(button, bag)
  local show = false
  if ns.db.bagQuestItemMarks and bag and button.GetID then
    local slot = button:GetID()
    -- Blizzards eigenes Ausrufezeichen/Rahmen (Forever) nicht doppeln
    local own = button.IconQuestTexture
    show = not (own and own.IsShown and own:IsShown()) and isQuestRelevant(bag, slot)
  end
  if show or marks[button] then
    local mark = markOf(button)
    if show then mark:Show() else mark:Hide() end
  end
end

local function buttonsOf(frame)
  if frame.EnumerateValidItems then
    local list = {}
    for _, button in frame:EnumerateValidItems() do list[#list + 1] = button end
    return list
  end
  local list, name = {}, frame:GetName()
  for i = 1, (frame.size or 0) do list[#list + 1] = _G[name .. "Item" .. i] end
  return list
end

local function updateFrame(frame)
  for _, button in ipairs(buttonsOf(frame)) do
    local bag = button.GetBagID and button:GetBagID() or frame:GetID()
    updateButton(button, bag)
  end
end

local function forEachFrame(fn)
  local count = NUM_CONTAINER_FRAMES or DEFAULT_FRAME_COUNT
  for i = 1, count do
    local frame = _G["ContainerFrame" .. i]
    if frame then fn(frame) end
  end
  if _G[COMBINED_FRAME] then fn(_G[COMBINED_FRAME]) end
end

local function refresh()
  if not ns.db then return end
  forEachFrame(function(frame)
    if not hooked[frame] and frame.HookScript then
      hooked[frame] = true
      frame:HookScript("OnShow", function(self) ns.SafeCall(updateFrame, self) end)
    end
    if frame:IsShown() then updateFrame(frame) end
  end)
end

ns.RegisterEvent("BAG_UPDATE_DELAYED", refresh)
ns.RegisterEvent("QUEST_LOG_UPDATE", refresh)
ns.RegisterApply(refresh)

-- Taschen-Markierung in Classic Era: Blizzards ContainerFrame (Vanilla) blendet das Quest-Zeichen immer aus,
-- Knöpfe heißen <Frame>Item<i> (kein EnumerateValidItems, Bag-ID = frame:GetID()). Das Addon markiert selbst.
local meat = { text = "Wolfsfleisch: 3/5", finished = false, type = "item" }
wow.state.questLog = {
  { title = "Wald", isHeader = true },
  { questID = 50, title = "Fleisch", objectives = { meat } },
}
wow.state.bagSlots = 3
wow.state.bags = { [1] = {
  { itemID = 1, itemName = "Wolfsfleisch", stackCount = 5 },
  { itemID = 2, itemName = "Leinenstoff", stackCount = 1 },
  { itemID = 3, itemName = "Siegel", stackCount = 1, questInfo = { isQuestItem = true, isActive = true, questID = 50 } },
} }

local textures = {}
local bag = CreateFrame("Frame", "ContainerFrame2")
bag:SetID(1)
bag.size = 3
bag.EnumerateValidItems = false  -- gibt es im Classic-ContainerFrame nicht (Stub-Rahmen liefern sonst No-Ops)
for slot = 1, 3 do
  local button = CreateFrame("Button", "ContainerFrame2Item" .. slot)
  button:SetID(slot)
  button.CreateTexture = function()
    textures[slot] = CreateFrame("Frame")
    return textures[slot]
  end
  button.IconQuestTexture = CreateFrame("Frame")
  button.IconQuestTexture:Hide()  -- Vanilla blendet das Blizzard-Zeichen immer aus
  _G["ContainerFrame2Item" .. slot] = button
end
ContainerFrame2 = bag

wow.login({ level = 10 })
local function marked(slot) return textures[slot] ~= nil and textures[slot]._shown == true end

bag:Show()
wow.fire("BAG_UPDATE_DELAYED")
expectTrue("Sammelgegenstand markiert", marked(1))
expect("normaler Gegenstand nicht", marked(2), false)
expectTrue("Gegenstand einer laufenden Quest markiert", marked(3))

-- Quest abgegeben: Ziel verschwindet aus dem Log, Gegenstand ohne Questinfo verliert die Markierung
table.remove(wow.state.questLog, 2)
wow.fire("QUEST_LOG_UPDATE")
expect("Quest weg: Markierung weg", marked(1), false)

-- Tasche geschlossen: keine Arbeit, keine Fehler
bag:Hide()
wow.fire("BAG_UPDATE_DELAYED")
expect("Fehler?", #wow.errors, 0)

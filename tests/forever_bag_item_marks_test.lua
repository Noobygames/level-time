-- Taschen-Markierung für Quest-Gegenstände (Forever, ContainerFrame mit EnumerateValidItems): offenes Sammelziel
-- und Questinfo des Clients bekommen ein Ausrufezeichen, Blizzards eigenes Zeichen wird nicht gedoppelt,
-- erfülltes Ziel / abgegebene Quest / Einstellung aus entfernen die Markierung.
local meat = { text = "Wolfsfleisch: 3/5", finished = false, type = "item" }
wow.state.questLog = {
  { title = "Wald", isHeader = true },
  { questID = 50, title = "Fleisch", objectives = { meat } },
}
local function bagItem(id, name, extra)
  local entry = { itemID = id, itemName = name, stackCount = 1 }
  for key, value in pairs(extra or {}) do entry[key] = value end
  return entry
end
wow.state.bagSlots = 4
wow.state.bags = { [0] = {
  bagItem(1, "Wolfsfleisch"),
  bagItem(2, "Leinenstoff"),
  bagItem(3, "Alte Karte", { questInfo = { isQuestItem = false, questID = 77, isActive = false } }),
  bagItem(4, "Siegel", { questInfo = { isQuestItem = true, isActive = false } }),
} }

local buttons, textures = {}, {}
for slot = 1, 4 do
  buttons[slot] = CreateFrame("Button", "TestBagButton" .. slot)
  buttons[slot]:SetID(slot)
  buttons[slot].CreateTexture = function()
    textures[slot] = CreateFrame("Frame")
    return textures[slot]
  end
  buttons[slot].GetBagID = function() return 0 end
  buttons[slot].IconQuestTexture = CreateFrame("Frame")
  buttons[slot].IconQuestTexture:Hide()
end
buttons[4].IconQuestTexture:Show()  -- Blizzard zeichnet für dieses Siegel schon selbst
local bag = CreateFrame("Frame", "ContainerFrame1")
bag:SetID(0)
bag.EnumerateValidItems = function()
  local i = 0
  return function() i = i + 1; return buttons[i] and i, buttons[i] end
end
ContainerFrame1 = bag

wow.login({ level = 10 })
local function marked(slot)
  local mark = textures[slot]
  return mark ~= nil and mark._shown == true
end

wow.fire("BAG_UPDATE_DELAYED")
expectTrue("Sammelgegenstand markiert", marked(1))
expect("normaler Gegenstand nicht", marked(2), false)
expectTrue("Quest-Starter markiert", marked(3))
expect("Blizzard zeichnet schon: keine zweite Markierung", marked(4), false)

meat.finished = true
wow.fire("QUEST_LOG_UPDATE")
expect("Ziel erfüllt: Markierung weg", marked(1), false)
meat.finished = false
wow.fire("QUEST_LOG_UPDATE")
expectTrue("Ziel wieder offen", marked(1))
local quest = table.remove(wow.state.questLog, 2)
wow.fire("QUEST_LOG_UPDATE")
expect("Quest weg: Markierung weg", marked(1), false)

wow.state.questLog[2] = quest
wow.fire("QUEST_LOG_UPDATE")
expectTrue("Quest wieder da", marked(1))
addon.Set("bagQuestItemMarks", false)
expect("Einstellung aus: Starter ohne Markierung", marked(3), false)
expect("Einstellung aus: Sammelgegenstand ohne Markierung", marked(1), false)
expect("Fehler?", #wow.errors, 0)

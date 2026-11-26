-- Freie Taschenplätze auf den Taschenknöpfen: Blizzards Zahl am Rucksack durchsichtig, unsere Zahl ohne
-- Reagenzientasche darüber, eigene Zahl auf der Reagenzientasche; folgt der CVar displayFreeBagSlots.
local BagFreeSlots = addon.BagFreeSlots

local REAGENT_BAG = 5
Enum.BagIndex = { ReagentBag = REAGENT_BAG }
MainMenuBarBackpackButton = CreateFrame("ItemButton")
MainMenuBarBackpackButton.FreeSlots = MainMenuBarBackpackButton:CreateFontString()
CharacterReagentBag0Slot = CreateFrame("ItemButton")
-- Unsere Zahlen mitschneiden: alle Font-Strings, die das Addon auf den beiden Knöpfen anlegt
local created = {}
for _, button in ipairs({ MainMenuBarBackpackButton, CharacterReagentBag0Slot }) do
  local create = button.CreateFontString
  button.CreateFontString = function(...)
    local fontString = create(...)
    table.insert(created, fontString)
    return fontString
  end
end
SetCVar("displayFreeBagSlots", "1")

wow.state.bags[REAGENT_BAG] = {}
wow.state.freeSlots = { [0] = { 3, 0 }, [1] = { 20, 4 }, [REAGENT_BAG] = { 12, 0 } }

wow.login()
BagFreeSlots.Update()

local blizzard = MainMenuBarBackpackButton.FreeSlots

expect("Blizzards Zahl durchsichtig", blizzard:GetAlpha(), 0)
-- Sichtbare Zahlen unserer Font-Strings, sortiert
local function shownCounts()
  local texts = {}
  for _, fontString in ipairs(created) do
    if fontString:IsShown() then table.insert(texts, fontString:GetText()) end
  end
  table.sort(texts)
  return table.concat(texts, " ")
end
expect("Rucksack ohne Reagenzientasche, Reagenzientasche eigene", shownCounts(), "(12) (3)")

-- CVar aus: unsere Zahlen weg
SetCVar("displayFreeBagSlots", "0")
wow.fire("CVAR_UPDATE", "displayFreeBagSlots", "0")
expect("CVar aus: keine Zahl", shownCounts(), "")

-- Einstellung aus: Blizzards Zahl wieder sichtbar
addon.Set("bagFreeSlots", false)
expect("aus: Blizzards Zahl zurück", blizzard:GetAlpha(), 1)
expect("Fehler?", #wow.errors, 0)

-- Freie Taschenplätze auf den Taschenknöpfen (Einstellung bagFreeSlots, Reiter "Oberfläche", an): Blizzards Zahl am
-- Rucksack zählt die Reagenzientasche mit; wir blenden sie aus und legen die freien Plätze der normalen Taschen
-- (Bags.GetFreeSlots) darüber, die Reagenzientasche bekommt ihre eigene Zahl (Bags.GetReagentFreeSlots).
-- Blizzards Zahl: MainMenuBarBackpackButton.FreeSlots (Mainline-Vorlage, auch Forever) bzw.
-- MainMenuBarBackpackButtonCount (Classic Era). Sie wird nur durchsichtig (Alpha 0), Blizzard schaltet sie weiter über
-- die CVar displayFreeBagSlots; unsere Zahlen folgen derselben CVar. Reagenzientasche: CharacterReagentBag0Slot.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    bagFreeSlots = true,
  },
})

local BagFreeSlots = {}
ns.BagFreeSlots = BagFreeSlots

local FREE_SLOTS_FORMAT = "(%d)"   -- wie Blizzards Zähler
local FREE_SLOTS_CVAR = "displayFreeBagSlots"
local LABEL_FONT = "NumberFontNormal"
local REAGENT_LABEL_OFFSET_Y = 2  -- Abstand der Zahl vom unteren Rand der Reagenzientasche
local TRANSPARENT, OPAQUE = 0, 1

local labels = {}  -- [Knopf] = unsere Zahl

local function blizzardCount()
  local backpack = _G.MainMenuBarBackpackButton
  return backpack and (backpack.FreeSlots or _G.MainMenuBarBackpackButtonCount)
end

-- Zahl auf einem Knopf, über anchor (Blizzards Zahl) gelegt oder unten mittig
local function labelOn(button, anchor)
  local label = labels[button]
  if not label then
    label = button:CreateFontString(nil, "OVERLAY", LABEL_FONT)
    if anchor then
      label:SetPoint("CENTER", anchor, "CENTER")
    else
      label:SetPoint("BOTTOM", button, "BOTTOM", 0, REAGENT_LABEL_OFFSET_Y)
    end
    labels[button] = label
  end
  return label
end

local function showCount(label, free, shown)
  if free then ns.Widgets.SetTextIfChanged(label, string.format(FREE_SLOTS_FORMAT, free)) end
  label:SetShown(shown and free ~= nil)
end

function BagFreeSlots.Update()
  local enabled = ns.db and ns.db.bagFreeSlots == true
  local blizzard = blizzardCount()
  if blizzard then blizzard:SetAlpha(enabled and TRANSPARENT or OPAQUE) end
  if not enabled then
    for _, label in pairs(labels) do label:Hide() end
    return
  end
  local shown = ns.CVars.Get(FREE_SLOTS_CVAR) == "1"
  local free, reagentFree = ns.Bags.GetFreeSlots(), ns.Bags.GetReagentFreeSlots()
  if blizzard then showCount(labelOn(_G.MainMenuBarBackpackButton, blizzard), free, shown) end
  local reagentButton = _G.CharacterReagentBag0Slot
  if reagentButton then showCount(labelOn(reagentButton), reagentFree, shown) end
  ns.Debug("bags", "free slots %s, reagent %s, shown %s", free, reagentFree, shown)
end

local events = ns.NewEventGroup()
for _, event in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_ENTERING_WORLD", "CVAR_UPDATE" }) do
  events.Add(event, nil, BagFreeSlots.Update)
end

ns.RegisterApply(function(db)
  events.SetActive(db.bagFreeSlots == true)
  BagFreeSlots.Update()
end)

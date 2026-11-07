-- Welt-Tooltips am Mauszeiger (tooltipAnchor): nur Standardanker mit UIParent, Knöpfe behalten ihren Platz
local owners = {}
function GameTooltip:SetOwner(owner, anchor) table.insert(owners, { owner = owner, anchor = anchor }) end
function GameTooltip_SetDefaultAnchor(tooltip, parent) tooltip:SetOwner(parent, "ANCHOR_NONE") end

wow.login()
local button = CreateFrame("Button")

local function lastAnchor(parent)
  owners = {}
  GameTooltip_SetDefaultAnchor(GameTooltip, parent)
  return owners[#owners].anchor
end

expect("Standard: Blizzards Anker", lastAnchor(UIParent), "ANCHOR_NONE")
addon.Set("tooltipAnchor", "cursor")
expect("Welt: am Zeiger", lastAnchor(UIParent), "ANCHOR_CURSOR")
expect("Knopf: Blizzards Anker", lastAnchor(button), "ANCHOR_NONE")
addon.Set("tooltipAnchor", "cursorRight")
expect("rechts vom Zeiger", lastAnchor(UIParent), "ANCHOR_CURSOR_RIGHT")
addon.Set("tooltipAnchor", "default")
expect("zurück auf Standard", lastAnchor(UIParent), "ANCHOR_NONE")

-- Auswahl in den Optionen (Komfort > Fenster)
addon.OptionsWindow.ShowPage("COMFORT_PAGE_FRAMES")
expectTrue("Auswahl in der Suche", #addon.OptionsWindow.Search(addon.L.TOOLTIP_ANCHOR) > 0)

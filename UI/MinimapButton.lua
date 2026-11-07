-- Minimap-Button von Level Time (Lib/MinimapButton.lua): Winkel in db.minimap.angle, ausblenden mit db.minimap.hide.
-- Links Einstellungen, Shift+links Historie, rechts Fenster an/aus, Shift+rechts Edit-Modus.
local _, ns = ...
local L = ns.L

local minimapButton = ns.MinimapButton.New({
  name = ns.GlobalName("MinimapButton"),
  icon = ns.Widgets.ICON,
  getAngle = function() return ns.db.minimap.angle end,
  setAngle = function(angle) ns.db.minimap.angle = angle end,
  onClick = function(mouseButton)
    if mouseButton == "RightButton" and IsShiftKeyDown() then
      ns.EditMode.Toggle()
    elseif mouseButton == "RightButton" then
      ns.Set("showTimer", not ns.db.showTimer)
    elseif IsShiftKeyDown() then
      ns.ToggleHistory()
    else
      ns.ToggleOptions()
    end
  end,
  tooltip = function(tooltip)
    tooltip:AddLine(ns.DISPLAY_NAME)
    tooltip:AddLine(L.TOOLTIP_LEFT, 1, 1, 1)
    tooltip:AddLine(L.TOOLTIP_SHIFT_LEFT, 1, 1, 1)
    tooltip:AddLine(L.TOOLTIP_RIGHT, 1, 1, 1)
    tooltip:AddLine(L.TOOLTIP_SHIFT_RIGHT, 1, 1, 1)
    tooltip:AddLine(L.TOOLTIP_DRAG, 1, 1, 1)
  end,
})

function ns.SetMinimapHidden(hidden)
  ns.db.minimap.hide = hidden
  ns.ApplySettings()
  if hidden then ns.Print(L.MINIMAP_HIDDEN) end
end

ns.RegisterApply(function(db)
  minimapButton.SetShown(not db.minimap.hide)
end)

-- Retail: Eintrag im Addon-Compartment (siehe AddonCompartmentFunc in der .toc)
function LevelTimer_OnAddonCompartmentClick()
  ns.ToggleOptions()
end

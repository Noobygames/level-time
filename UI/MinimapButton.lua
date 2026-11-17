-- Minimap-Button von Level Time (Lib/MinimapButton.lua): Winkel in db.minimap.angle, ausblenden mit db.minimap.hide.
-- Dazu die gemeinsame Klickbelegung (ns.LauncherClicks) für Minimap-Button, Datentext (UI/Broker.lua) und
-- Addon-Compartment, damit alle Einstiegspunkte gleich reagieren und dieselben Tooltip-Zeilen zeigen.
local _, ns = ...
local L = ns.L

local LauncherClicks = {}
ns.LauncherClicks = LauncherClicks

-- Links Einstellungen, rechts Fenster ist bewusst umgekehrt zur LibDBIcon-Gewohnheit (links Fenster, rechts Optionen):
-- so kennen es die Spieler seit Beginn, deshalb nicht tauschen (LT-65).
local CLICKS = {
  { button = "LeftButton", shift = false, tip = "TOOLTIP_LEFT", run = function() ns.ToggleOptions() end },
  { button = "LeftButton", shift = true, tip = "TOOLTIP_SHIFT_LEFT", run = function() ns.ToggleHistory() end },
  { button = "RightButton", shift = false, tip = "TOOLTIP_RIGHT",
    run = function() ns.Set("showTimer", not ns.db.showTimer) end },
  { button = "RightButton", shift = true, tip = "TOOLTIP_SHIFT_RIGHT", run = function() ns.EditMode.Toggle() end },
  { button = "LeftButton", ctrl = true, tip = "TOOLTIP_CTRL_LEFT", available = function() return ns.DungeonGuide.IsAvailable() end,
    run = function() ns.DungeonGuide.Open() end },
}

-- Jede andere Taste (Mitte, unbekannt) gilt als Linksklick
function LauncherClicks.Handle(mouseButton)
  local button = mouseButton == "RightButton" and "RightButton" or "LeftButton"
  local shift = IsShiftKeyDown() and true or false
  local ctrl = IsControlKeyDown() and true or false
  for _, click in ipairs(CLICKS) do
    if click.button == button and (click.shift or false) == shift and (click.ctrl or false) == ctrl
        and (not click.available or click.available()) then
      click.run()
      return
    end
  end
end

function LauncherClicks.AddTooltipLines(tooltip, r, g, b)
  for _, click in ipairs(CLICKS) do
    if not click.available or click.available() then tooltip:AddLine(L[click.tip], r, g, b) end
  end
end

local minimapButton = ns.MinimapButton.New({
  name = ns.GlobalName("MinimapButton"),
  icon = ns.Widgets.ICON,
  getAngle = function() return ns.db.minimap.angle end,
  setAngle = function(angle) ns.db.minimap.angle = angle end,
  onClick = LauncherClicks.Handle,
  tooltip = function(tooltip)
    tooltip:AddLine(ns.DISPLAY_NAME)
    LauncherClicks.AddTooltipLines(tooltip, 1, 1, 1)
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

-- Retail: Eintrag im Addon-Compartment (siehe AddonCompartmentFunc in der .toc);
-- WoW übergibt (addonName, mouseButton, menuButtonFrame)
function LevelTimer_OnAddonCompartmentClick(_, mouseButton)
  LauncherClicks.Handle(mouseButton)
end

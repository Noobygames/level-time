-- Einstiege in das eigene Gruppensuche-Fenster (UI/LFGWindow.lua, nur WoW Forever). Blizzards Gruppensuche bleibt
-- unberührt und öffnet wie gewohnt; unser Fenster öffnet über ein eigenes Minikarten-Icon (Einstellung
-- lfgMinimapButton), /lt lfg (Core/Commands.lua) und einen Knopf "Level Time" oben an Blizzards LFGParentFrame.
-- Blizzard_GroupFinder_VanillaStyle lädt bei Bedarf: der Knopf entsteht, sobald LFGParentFrame existiert.
local _, ns = ...
if not ns.Client.IsForever() then return end

local L = ns.L
local LFGSearch = ns.LFGSearch
local LFGWindow = ns.LFGWindow

local ICON = "Interface\\ICONS\\INV_SideTab_GroupBrowsing_c60"  -- Blizzards Reiter "Gruppen durchsuchen"
local BLIZZARD_BUTTON_WIDTH = 90
local BLIZZARD_BUTTON_HEIGHT = 20
local CLOSE_BUTTON_GAP = 2

local minimapButton = ns.MinimapButton.New({
  name = ns.GlobalName("LFGMinimapButton"),
  icon = ICON,
  getAngle = function() return ns.db.lfgMinimapAngle end,
  setAngle = function(angle) ns.db.lfgMinimapAngle = angle end,
  onClick = function() LFGWindow.Toggle() end,
  tooltip = function(tooltip)
    tooltip:AddLine(L.LFG_MINIMAP_TITLE)
    tooltip:AddLine(L.LFG_MINIMAP_CLICK, 1, 1, 1)
    tooltip:AddLine(L.TOOLTIP_DRAG, 1, 1, 1)
  end,
})
LFGWindow.minimapButton = minimapButton.frame

ns.RegisterApply(function(db)
  minimapButton.SetShown(db.lfgMinimapButton and LFGSearch.IsAvailable())
end)

-- Knopf links neben Blizzards Schließen-Knopf: schließt Blizzards Fenster und öffnet unseres (eigener Klick, kein
-- geschützter Aufruf)
local blizzardButton
local function addBlizzardButton()
  if blizzardButton or not LFGParentFrame then return end
  blizzardButton = CreateFrame("Button", nil, LFGParentFrame, "UIPanelButtonTemplate")
  blizzardButton:SetSize(BLIZZARD_BUTTON_WIDTH, BLIZZARD_BUTTON_HEIGHT)
  local close = LFGParentFrame.CloseButton or _G.LFGParentFrameCloseButton
  if close then
    blizzardButton:SetPoint("RIGHT", close, "LEFT", -CLOSE_BUTTON_GAP, 0)
  else
    blizzardButton:SetPoint("TOPRIGHT", -30, -2)
  end
  blizzardButton:SetText(ns.DISPLAY_NAME)
  blizzardButton:SetScript("OnClick", function()
    HideUIPanel(LFGParentFrame)
    LFGWindow.Show()
  end)
  ns.Widgets.AttachTooltip(blizzardButton, function() return L.LFG_MINIMAP_TITLE end,
    function() return L.LFG_BLIZZARD_BUTTON_TIP end)
  LFGWindow.blizzardButton = blizzardButton
end

addBlizzardButton()
ns.RegisterEvent("ADDON_LOADED", addBlizzardButton)

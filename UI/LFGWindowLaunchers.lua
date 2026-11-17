-- Einstiege in das eigene Gruppensuche-Fenster (UI/LFGWindow.lua, nur WoW Forever). Blizzards Gruppensuche bleibt
-- unberührt und öffnet wie gewohnt; unser Fenster öffnet über ein eigenes Minikarten-Icon (Einstellung
-- lfgMinimapButton), /lt lfg (Core/Commands.lua) und einen Seitenreiter rechts an Blizzards LFGParentFrame (LT-351).
-- Der Seitenreiter ist nur ein Starter: Blizzards Reiter und Teilfenster werden nie ein- oder ausgeblendet oder markiert
-- (Blizzard_GroupFinder_VanillaStyle ist "## Secure: 1", seine C_LFGList-Getter würden sonst Taint tragen). Er hängt unter
-- Blizzards Reiter "Wer" oder, falls installiert, unter dem Reiter von LFG Forever (LFGForeverBlizzardTab). Unser Fenster
-- bekommt dieselbe Seitenleiste: Blizzards drei Reiter (öffnen Blizzards Fenster, nur außerhalb des Kampfs), LFG Forever
-- (falls da) und unser eigener (markiert). Blizzard_GroupFinder_VanillaStyle lädt bei Bedarf: der Reiter entsteht, sobald
-- LFGParentFrame existiert.
local _, ns = ...
if not ns.Client.IsForever() then return end

local L = ns.L
local LFGSearch = ns.LFGSearch
local LFGWindow = ns.LFGWindow

local ICON = "Interface\\ICONS\\INV_SideTab_GroupBrowsing_c60"  -- Blizzards Reiter "Gruppen durchsuchen"
local OWN_ICON = "Interface\\AddOns\\LevelTimer\\Media\\Icon"
-- Unser Fenster: Blizzards Gruppensuche-Auge (kennen Spieler), mit kleinem Level-Time-Abzeichen unten rechts, damit
-- man es vom Original unterscheidet
local LFG_ICON = "Interface\\ICONS\\INV_SideTab_GroupFinder_c60"
local BADGE_SIZE = 14
local BADGE_INSET = 2
local MINIMAP_BADGE_INSET = 6  -- innerhalb des runden Minikarten-Rahmens

-- Level-Time-Abzeichen über dem Symbol eines Knopfs oder Reiters
local function addBadge(frame, inset)
  local badge = frame:CreateTexture(nil, "OVERLAY", nil, 7)
  badge:SetTexture(OWN_ICON)
  badge:SetSize(BADGE_SIZE, BADGE_SIZE)
  badge:SetPoint("BOTTOMRIGHT", -(inset or BADGE_INSET), inset or BADGE_INSET)
  return badge
end
local SIDE_TEMPLATE = "LargeSideTabButtonTemplate"  -- Blizzards Seitenreiter (SharedUIPanelTemplates, Mainline)
local SIDE_FALLBACK_SIZE = 40    -- eigene Ersatzfläche, falls die Vorlage fehlt
local SIDE_FALLBACK_ICON = 30
local SIDE_TOP = -60             -- erster Reiter wie Blizzards ListingTab
local SIDE_GAP = -2              -- Abstand zwischen zwei Reitern wie bei Blizzard
local LFG_FOREVER_TAB = "LFGForeverBlizzardTab"
-- Blizzards Reiter in LFGParentFrame (LFGVanilla_ShowFrame(tab)): Index, Symbol, Blizzards Text, unser Ersatztext
local BLIZZARD_TABS = {
  { tab = 1, icon = "Interface\\ICONS\\INV_SideTab_GroupFinder_c60", global = "LFG_LIST_TAB_1", key = "LFG_TAB_LISTING" },
  { tab = 2, icon = ICON, global = "LFG_LIST_TAB_2", key = "LFG_TAB_SEARCH" },
  { tab = 3, icon = "Interface\\ICONS\\INV_SideTab_WhoList_c60", global = "LFG_LIST_TAB_3", key = "LFG_TAB_WHO" },
}

local minimapButton = ns.MinimapButton.New({
  name = ns.GlobalName("LFGMinimapButton"),
  icon = LFG_ICON,
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
LFGWindow.minimapBadge = addBadge(minimapButton.frame, MINIMAP_BADGE_INSET)

ns.RegisterApply(function(db)
  minimapButton.SetShown(db.lfgMinimapButton and LFGSearch.IsAvailable())
  BINDING_NAME_LEVELTIMER_LFG_WINDOW = L.LFG_BINDING
end)

-- Tastenbelegung (Bindings.xml): Fenster umschalten
function LevelTimer_LFGWindow()
  if ns.character then LFGWindow.Toggle() end
end

---------------------------------------------------------------------------
-- Seitenreiter
---------------------------------------------------------------------------
local function hasSideTemplate()
  return C_XMLUtil ~= nil and C_XMLUtil.GetTemplateInfo ~= nil and C_XMLUtil.GetTemplateInfo(SIDE_TEMPLATE) ~= nil
end

-- Ein Seitenreiter mit Symbol und Tooltip; onClick() nach Linksklick. Blizzards Vorlage, sonst eine schlichte Fläche.
local function newSideTab(parent, name, texture, onClick, title, tip)
  local template = hasSideTemplate() and SIDE_TEMPLATE or nil
  local tab = CreateFrame("Frame", name, parent, template)
  if not template then
    tab:SetSize(SIDE_FALLBACK_SIZE, SIDE_FALLBACK_SIZE)
    tab.Icon = tab:CreateTexture(nil, "ARTWORK")
    tab.Icon:SetPoint("CENTER")
  end
  tab.Icon:SetTexture(texture)
  -- wie Blizzards LFGVanillaRightTabTemplate: Symbol füllt den Reiter (Vorlagen-Standard 50, die Maske schneidet zu)
  if tab.SetFillToInterior then tab:SetFillToInterior(true) else tab.Icon:SetSize(SIDE_FALLBACK_ICON, SIDE_FALLBACK_ICON) end
  tab:EnableMouse(true)
  -- nach Blizzards eigenem OnMouseUp (Klang, Symbol zurück); kein SetCustomOnMouseUpHandler, der fehlt ohne Vorlage
  tab:HookScript("OnMouseUp", function(_, button, upInside)
    if button == "LeftButton" and upInside ~= false then onClick() end
  end)
  ns.Widgets.AttachTooltip(tab, title, tip)
  return tab
end

local function setChecked(tab, checked)
  if tab.SetChecked then tab:SetChecked(checked) end
end

-- Öffnet unser Fenster; Blizzards schließt nur außerhalb des Kampfs (HideUIPanel auf einem sicheren Fenster)
local function openOwn()
  if LFGParentFrame and LFGParentFrame:IsShown() and not InCombatLockdown() then HideUIPanel(LFGParentFrame) end
  LFGWindow.Show()
end

-- Reiter an Blizzards Fenster: unter LFG Forever, sonst unter "Wer", sonst oben rechts am Rahmen
local blizzardTab
local function anchorBlizzardTab()
  local above = _G[LFG_FOREVER_TAB] or LFGParentFrame.WhoListingTab
  blizzardTab:ClearAllPoints()
  if above then
    blizzardTab:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, SIDE_GAP)
  else
    blizzardTab:SetPoint("TOPLEFT", LFGParentFrame, "TOPRIGHT", 0, SIDE_TOP)
  end
end

local function addBlizzardTab()
  if blizzardTab or not LFGParentFrame then return end
  blizzardTab = newSideTab(LFGParentFrame, ns.GlobalName("LFGSideTab"), LFG_ICON, openOwn,
    function() return L.LFG_MINIMAP_TITLE end, function() return L.LFG_BLIZZARD_BUTTON_TIP end)
  addBadge(blizzardTab)
  anchorBlizzardTab()
  LFGParentFrame:HookScript("OnShow", anchorBlizzardTab)  -- LFG Forever legt seinen Reiter evtl. erst später an
  LFGWindow.blizzardTab = blizzardTab
  ns.Debug("lfg", "side tab added below %s", _G[LFG_FOREVER_TAB] and LFG_FOREVER_TAB or "WhoListingTab")
end

-- Blizzards Fenster mit Reiter tab öffnen (nur außerhalb des Kampfs, ShowUIPanel auf einem sicheren Fenster)
local function openBlizzard(tab)
  if InCombatLockdown() or not LFGVanilla_ShowFrame then
    ns.Print(L.LFG_SIDE_TAB_COMBAT)
    return
  end
  LFGWindow.Hide()
  LFGVanilla_ShowFrame(tab)
end

-- LFG Forever über seinen eigenen Reiter öffnen (dessen Klick-Logik, nicht unsere)
local function openLfgForever()
  local tab = _G[LFG_FOREVER_TAB]
  local onMouseUp = tab and tab:GetScript("OnMouseUp")
  if not onMouseUp then return end
  LFGWindow.Hide()
  onMouseUp(tab, "LeftButton", true)
end

-- Seitenleiste unseres Fensters: rechts am Fenster, bei offenem Detail rechts am Detail
local ownTabs = {}
for _, entry in ipairs(BLIZZARD_TABS) do
  table.insert(ownTabs, newSideTab(LFGWindow.panel, nil, entry.icon, function() openBlizzard(entry.tab) end,
    function() return LFGWindow.Text(entry.global, entry.key) end, function() return L.LFG_SIDE_TAB_BLIZZARD_TIP end))
end
local lfgForeverTab = newSideTab(LFGWindow.panel, nil, ICON, openLfgForever,
  function() return L.LFG_SIDE_TAB_LFGF end, function() return L.LFG_SIDE_TAB_LFGF_TIP end)
table.insert(ownTabs, lfgForeverTab)
local ownTab = newSideTab(LFGWindow.panel, nil, LFG_ICON, function() end,
  function() return L.LFG_MINIMAP_TITLE end, function() return L.LFG_SIDE_TAB_OWN_TIP end)
addBadge(ownTab)
table.insert(ownTabs, ownTab)
setChecked(ownTab, true)
LFGWindow.sideTabs, LFGWindow.lfgForeverSideTab = ownTabs, lfgForeverTab

LFGWindow.OnRefresh(function()
  local detail = LFGWindow.Parts().detail
  local right = (detail and detail:IsShown()) and detail or LFGWindow.panel
  local foreverTab = _G[LFG_FOREVER_TAB]
  if foreverTab and type(foreverTab.Icon) == "table" and foreverTab.Icon.GetTexture then
    lfgForeverTab.Icon:SetTexture(foreverTab.Icon:GetTexture())
  end
  lfgForeverTab:SetShown(foreverTab ~= nil)
  local previous
  for _, tab in ipairs(ownTabs) do
    if tab:IsShown() then
      tab:ClearAllPoints()
      if previous then
        tab:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, SIDE_GAP)
      else
        tab:SetPoint("TOPLEFT", right, "TOPRIGHT", 0, SIDE_TOP)
      end
      previous = tab
    end
  end
end)

addBlizzardTab()
ns.RegisterEvent("ADDON_LOADED", addBlizzardTab)

-- Minimap-Button-Sammler (Reiter Komfort, Minimap; Einstellung minimapButtonBar, Standard aus):
-- Fremde Addon-Minimap-Buttons werden an einer einklappbaren Leiste gesammelt, um die Minimap aufzuräumen.
-- Vollständig umkehrbar: beim Deaktivieren kehren alle gesammelten Buttons an ihre Originalpositionen zurück.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    minimapButtonBar = false,
  },
})

local MinimapBar = {}
ns.MinimapBar = MinimapBar

local BUTTON_SIZE = 32
local GAP = 4
local PADDING = 6
local MAX_PER_ROW = 6
local PANEL_ALPHA = 0.9

local IGNORED_NAMES = {
  ["LevelTimerMinimapButton"] = true,
  ["StreamGoalMinimapButton"] = true,
  ["LevelTimerMinimapBarToggle"] = true,
  ["LevelTimerMinimapBar"] = true,
  ["MinimapZoomIn"] = true,
  ["MinimapZoomOut"] = true,
  ["GameTimeFrame"] = true,
  ["MiniMapTracking"] = true,
  ["MiniMapTrackingButton"] = true,
  ["MiniMapMailFrame"] = true,
  ["MiniMapBattlefieldFrame"] = true,
  ["MiniMapWorldMapButton"] = true,
  ["MiniMapLFGFrame"] = true,
  ["MiniMapInstanceDifficulty"] = true,
  ["GuildInstanceDifficulty"] = true,
  ["MiniMapChallengeMode"] = true,
  ["QueueStatusMinimapButton"] = true,
  ["GarrisonLandingPageMinimapButton"] = true,
  ["ExpansionLandingPageMinimapButton"] = true,
  ["TimeManagerClockButton"] = true,
  ["AddonCompartmentFrame"] = true,
  ["MinimapZoneTextButton"] = true,
  ["MinimapBackdrop"] = true,
  ["MinimapCompassTexture"] = true,
}

local IGNORED_PREFIXES = {
  "HandyNotesPin",
  "QuestieFrame",
  "GatherMatePin",
}

local barFrame, toggleButton
local isExpanded = false
local originalStates = {}
local collectedButtons = {}
local pendingCollect = false
local pendingRestore = false

local function inCombat()
  return InCombatLockdown and InCombatLockdown()
end

local MIN_BUTTON_SIZE, MAX_BUTTON_SIZE = 16, 48   -- typische Minimap-Knöpfe; ohne Größe (0) zählt der Knopf mit

local function validDim(v)
  if not v or v <= 0 then return true end
  return v >= MIN_BUTTON_SIZE and v <= MAX_BUTTON_SIZE
end

-- Pfeil am Umschalter: zeigt, in welche Richtung die Leiste auf- bzw. zuklappt
local ARROW_OPEN, ARROW_CLOSED = ">", "<"

local function updateToggleText()
  if not toggleButton or not toggleButton._text then return end
  toggleButton._text:SetText(isExpanded and ARROW_OPEN or ARROW_CLOSED)
end

-- Gesammelte Knöpfe müssen klickbar und voll sichtbar sein. Der Knopf selbst und alle Unterframes
-- (Trefferfläche, Overlays) liegen über der Leiste; sonst fängt sie (EnableMouse) oder ihr Hintergrund den Klick ab.
-- Fade-Effekte (LibDBIcon showOnMouseover) hängen am Minimap-OnEnter/-OnLeave und liefen für umgehängte Knöpfe ins Leere:
-- sie bleiben dann auf niedriger Deckkraft ("ausgegraut").
local MAX_CHILD_DEPTH = 3
local hookedButtons = {}
local hookedLibs = false
local settingAlpha = false

local function holdAlpha(child)
  if not child.SetAlpha then return end
  settingAlpha = true
  if type(child.fadeOut) == "table" and type(child.fadeOut.Stop) == "function" then pcall(child.fadeOut.Stop, child.fadeOut) end
  child:SetAlpha(1)
  settingAlpha = false
end

local function raiseChildren(frame, strata, level, depth, saved)
  if depth > MAX_CHILD_DEPTH or type(frame.GetChildren) ~= "function" then return end
  local ok, children = pcall(function() return { frame:GetChildren() } end)
  if not ok then return end
  for _, sub in ipairs(children) do
    if type(sub) == "table" and sub ~= barFrame and sub.SetFrameLevel
      and not (sub.IsForbidden and sub:IsForbidden()) then
      if saved and not saved[sub] then
        saved[sub] = { strata = sub.GetFrameStrata and sub:GetFrameStrata(), level = sub:GetFrameLevel() }
      end
      if sub.SetFrameStrata then sub:SetFrameStrata(strata) end
      sub:SetFrameLevel(level)
      raiseChildren(sub, strata, level + 1, depth + 1, saved)
    end
  end
end

-- Fade-Animation und spätere SetAlpha-Aufrufe des Addons wieder auf volle Deckkraft zwingen (nur solange gesammelt)
local function hookButton(child)
  if hookedButtons[child] then return end
  hookedButtons[child] = true
  if type(hooksecurefunc) == "function" and type(child.SetAlpha) == "function" then
    hooksecurefunc(child, "SetAlpha", function(self, alpha)
      if settingAlpha or not originalStates[self] or ns.IsSecret(alpha) then return end
      if type(alpha) == "number" and alpha < 1 then holdAlpha(self) end
    end)
  end
  local fade = child.fadeOut
  if type(fade) == "table" and type(fade.HookScript) == "function" then
    pcall(fade.HookScript, fade, "OnPlay", function()
      if originalStates[child] then holdAlpha(child) end
    end)
  end
end

local function prepareButton(child)
  local strata = barFrame:GetFrameStrata() or "MEDIUM"
  local level = (barFrame:GetFrameLevel() or 1) + 2
  if child.SetFrameStrata then child:SetFrameStrata(strata) end
  if child.SetFrameLevel then child:SetFrameLevel(level) end
  local saved = originalStates[child]
  if saved then saved.children = saved.children or {} end
  raiseChildren(child, strata, level + 1, 1, saved and saved.children)
  holdAlpha(child)
  hookButton(child)
end

-- Nur sichtbare Knöpfe anordnen: vom Addon versteckte (z.B. LibDBIcon "hide") bleiben versteckt und ohne Lücke
local function layoutButtons()
  if not barFrame then return end
  local shown = {}
  for _, child in ipairs(collectedButtons) do
    if child:IsShown() then table.insert(shown, child) end
  end
  local count = #shown
  if count == 0 then
    barFrame:SetSize(BUTTON_SIZE + PADDING * 2, BUTTON_SIZE + PADDING * 2)
    return
  end
  local cols = math.min(count, MAX_PER_ROW)
  local rows = math.ceil(count / MAX_PER_ROW)
  local barWidth = PADDING * 2 + cols * BUTTON_SIZE + (cols - 1) * GAP
  local barHeight = PADDING * 2 + rows * BUTTON_SIZE + (rows - 1) * GAP
  barFrame:SetSize(barWidth, barHeight)

  for i, child in ipairs(shown) do
    child:SetParent(barFrame)
    child:ClearAllPoints()
    local col = (i - 1) % MAX_PER_ROW
    local row = math.floor((i - 1) / MAX_PER_ROW)
    local x = PADDING + col * (BUTTON_SIZE + GAP)
    local y = -(PADDING + row * (BUTTON_SIZE + GAP))
    child:SetPoint("TOPLEFT", barFrame, "TOPLEFT", x, y)
    prepareButton(child)
    if child.SetScale then
      child:SetScale(1)
    end
  end
end

local function createFrames()
  if barFrame then return end
  if not Minimap then return end

  -- BackdropTemplate: Theme.RegisterPanel setzt je nach Preset einen Backdrop
  toggleButton = CreateFrame("Button", ns.GlobalName("MinimapBarToggle"), UIParent, "BackdropTemplate")
  toggleButton:SetSize(20, 20)
  toggleButton:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -4, 0)
  toggleButton:SetFrameStrata("MEDIUM")
  toggleButton:SetFrameLevel(10)

  local text = toggleButton:CreateFontString(nil, "OVERLAY")
  text:SetPoint("CENTER", 0, 0)
  text:SetFontObject(ns.Theme.Font("label"))
  text:SetText(ARROW_CLOSED)
  toggleButton._text = text

  toggleButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  toggleButton:SetScript("OnClick", function()
    MinimapBar.Toggle()
  end)

  toggleButton:SetScript("OnEnter", function(self)
    if GameTooltip then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(ns.DISPLAY_NAME)
      GameTooltip:AddLine(ns.L.MINIMAP_BUTTON_BAR, 1, 1, 1)
      GameTooltip:Show()
    end
  end)
  toggleButton:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
  end)

  toggleButton:Hide()

  barFrame = CreateFrame("Frame", ns.GlobalName("MinimapBar"), UIParent, "BackdropTemplate")
  barFrame:SetPoint("TOPRIGHT", toggleButton, "TOPLEFT", -4, 0)
  barFrame:SetFrameStrata("MEDIUM")
  barFrame:SetFrameLevel(9)
  barFrame:SetSize(BUTTON_SIZE + PADDING * 2, BUTTON_SIZE + PADDING * 2)
  barFrame:EnableMouse(true)
  barFrame:SetScript("OnMouseUp", function(_, button)
    if button == "RightButton" then
      MinimapBar.SetExpanded(false)
    end
  end)
  -- Beim Aufklappen Lage und Deckkraft erneuern (Addons verschieben/verblassen ihre Knöpfe zwischendurch)
  barFrame:SetScript("OnShow", function()
    if not inCombat() then layoutButtons() end
  end)
  barFrame:Hide()

  ns.Theme.RegisterPanel(barFrame, PANEL_ALPHA)
  ns.Theme.RegisterPanel(toggleButton, PANEL_ALPHA)
end

function MinimapBar.IsAvailable()
  return Minimap ~= nil
end

-- Knopf erkennen: benannt, nicht ignoriert, Button (oder klickbar oder LibDBIcon) in typischer Knopfgröße
local function isClickable(child)
  local ok, isButton = pcall(child.IsObjectType, child, "Button")
  if ok and isButton then return true end
  local okClick, click = pcall(child.GetScript, child, "OnClick")
  local okUp, up = pcall(child.GetScript, child, "OnMouseUp")
  return (okClick and click ~= nil) or (okUp and up ~= nil)
end

function MinimapBar.IsMinimapButton(child)
  if type(child) ~= "table" or type(child.GetName) ~= "function" then return false end
  if type(child.IsForbidden) == "function" and child:IsForbidden() then return false end
  if child == barFrame or child == toggleButton or originalStates[child] ~= nil then return false end
  if barFrame and child:GetParent() == barFrame then return false end

  local name = child:GetName()
  if ns.IsSecret(name) or type(name) ~= "string" or name == "" or IGNORED_NAMES[name] then return false end
  if name == ns.GlobalName("MinimapButton") or name == ns.GlobalName("MinimapBarToggle")
    or name == ns.GlobalName("MinimapBar") then
    return false
  end
  for _, prefix in ipairs(IGNORED_PREFIXES) do
    if name:sub(1, #prefix) == prefix then return false end
  end

  -- LibDBIcon-Knöpfe sind immer Minimap-Knöpfe, egal welche Größe das Addon gewählt hat
  if name:find("^LibDBIcon10_") then return true end
  if not isClickable(child) then return false end
  return validDim(child:GetWidth()) and validDim(child:GetHeight())
end

function MinimapBar.Scan()
  local candidates = {}
  local seen = {}
  local function scanParent(parent)
    if not parent or type(parent.GetChildren) ~= "function" then return end
    local ok, children = pcall(function() return { parent:GetChildren() } end)
    if not ok or type(children) ~= "table" then return end
    for _, child in ipairs(children) do
      if type(child) == "table" and not seen[child] then
        seen[child] = true
        if MinimapBar.IsMinimapButton(child) then
          table.insert(candidates, child)
        end
      end
    end
  end

  scanParent(Minimap)
  if MinimapBackdrop then
    scanParent(MinimapBackdrop)
  end
  return candidates
end

-- LibDBIcon setzt Knöpfe bei Refresh/Show/SetButtonToPosition zurück an die Minimap: Leistenlage danach erneuern
local function hookLibDBIcon()
  if hookedLibs or type(hooksecurefunc) ~= "function" or not LibStub then return end
  local lib = LibStub("LibDBIcon-1.0", true)
  if not lib then return end
  hookedLibs = true
  for _, name in ipairs({ "Refresh", "Show", "SetButtonToPosition" }) do
    if type(lib[name]) == "function" then
      hooksecurefunc(lib, name, function()
        if ns.db and ns.db.minimapButtonBar and #collectedButtons > 0 and not inCombat() then
          layoutButtons()
        end
      end)
    end
  end
end

local function doCollect()
  if not MinimapBar.IsAvailable() then return end
  createFrames()
  hookLibDBIcon()
  local candidates = MinimapBar.Scan()
  for _, child in ipairs(candidates) do
    -- Versteckte Knöpfe (vom Addon oder Spieler ausgeblendet) nicht einsammeln
    if not originalStates[child] and child:IsShown() then
      local points = {}
      local numPoints = type(child.GetNumPoints) == "function" and child:GetNumPoints() or 0
      if numPoints > 0 then
        for i = 1, numPoints do
          local pt, relTo, relPt, x, y = child:GetPoint(i)
          table.insert(points, { pt, relTo, relPt, x, y })
        end
      elseif type(child.GetPoint) == "function" then
        local pt, relTo, relPt, x, y = child:GetPoint(1)
        if pt then
          table.insert(points, { pt, relTo, relPt, x, y })
        end
      end

      originalStates[child] = {
        parent = child.GetParent and child:GetParent() or Minimap,
        points = points,
        scale = child.GetScale and child:GetScale() or 1,
        strata = child.GetFrameStrata and child:GetFrameStrata() or "MEDIUM",
        level = child.GetFrameLevel and child:GetFrameLevel() or 1,
        shown = child.IsShown and child:IsShown() or false,
        alpha = child.GetAlpha and child:GetAlpha() or 1,
      }
      table.insert(collectedButtons, child)
    end
  end

  if ns.db and ns.db.minimapButtonBar then
    toggleButton:Show()
    layoutButtons()
    if isExpanded then
      barFrame:Show()
    else
      barFrame:Hide()
    end
    updateToggleText()
  end
end

function MinimapBar.Collect()
  if inCombat() then
    pendingCollect = true
    return
  end
  doCollect()
end

local function doRestoreAll()
  for _, child in ipairs(collectedButtons) do
    local saved = originalStates[child]
    if saved then
      if child.SetParent then child:SetParent(saved.parent) end
      child:ClearAllPoints()
      if #saved.points > 0 then
        for _, pt in ipairs(saved.points) do
          child:SetPoint(pt[1], pt[2], pt[3], pt[4], pt[5])
        end
      end
      if child.SetScale then child:SetScale(saved.scale) end
      if child.SetFrameStrata then child:SetFrameStrata(saved.strata) end
      if child.SetFrameLevel then child:SetFrameLevel(saved.level) end
      if child.SetShown then
        child:SetShown(saved.shown)
      elseif saved.shown then
        child:Show()
      else
        child:Hide()
      end
      if child.SetAlpha and saved.alpha then
        settingAlpha = true
        child:SetAlpha(saved.alpha)
        settingAlpha = false
      end
      for sub, state in pairs(saved.children or {}) do
        if state.strata and sub.SetFrameStrata then sub:SetFrameStrata(state.strata) end
        if sub.SetFrameLevel then sub:SetFrameLevel(state.level) end
      end
      originalStates[child] = nil
    end
  end
  collectedButtons = {}
  if barFrame then barFrame:Hide() end
  if toggleButton then toggleButton:Hide() end
end

function MinimapBar.RestoreAll()
  if inCombat() then
    pendingRestore = true
    return
  end
  doRestoreAll()
end

function MinimapBar.IsExpanded()
  return isExpanded
end

function MinimapBar.SetExpanded(expanded)
  isExpanded = expanded and true or false
  createFrames()
  if isExpanded and ns.db and ns.db.minimapButtonBar then
    if not inCombat() then layoutButtons() end
    barFrame:Show()
  else
    if barFrame then barFrame:Hide() end
  end
  updateToggleText()
end

function MinimapBar.Toggle()
  MinimapBar.SetExpanded(not isExpanded)
end

function MinimapBar.Collected()
  local list = {}
  for _, b in ipairs(collectedButtons) do
    table.insert(list, b)
  end
  return list
end

function MinimapBar.BarFrame()
  createFrames()
  return barFrame
end

function MinimapBar.ToggleButton()
  createFrames()
  return toggleButton
end

ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if pendingRestore then
    pendingRestore = false
    MinimapBar.RestoreAll()
  elseif pendingCollect or (ns.db and ns.db.minimapButtonBar) then
    pendingCollect = false
    MinimapBar.Collect()
  end
end)

ns.RegisterEvent("ADDON_LOADED", function()
  if ns.db and ns.db.minimapButtonBar then
    MinimapBar.Collect()
  end
end)

ns.OnLogin(function()
  if ns.db and ns.db.minimapButtonBar then
    if C_Timer and C_Timer.After then
      C_Timer.After(1, function()
        if ns.db and ns.db.minimapButtonBar then
          MinimapBar.Collect()
        end
      end)
    end
  end
end)

ns.RegisterApply(function(db)
  if db.minimapButtonBar then
    MinimapBar.Collect()
  else
    MinimapBar.RestoreAll()
  end
end)

-- Numerische Bedrohungsanzeige & Namensplaketten-Färbung (Reiter Komfort, System; threatShowNumeric, Standard aus; Roadmap 443).
-- 1. Setzt die CVar threatShowNumeric auf 1, umkehrbar über Lib/CVars.lua.
-- 2. Zeigt am Zielrahmen (TargetFrame) ein eigenes Prozent-Abzeichen (LevelTimerTargetThreat), falls Blizzards
--    eigene Anzeige (TargetFrameNumericalThreat / TargetFrame.threatNumericIndicator) im Solo-Spiel oder Client
--    ausgeblendet bleibt:
--      Status 0 (niedrig): Grau
--      Status 1 (hoch): Gelb
--      Status 2 (kurz vor Aggro / Verlust als Tank): Orange + Leuchtrahmen
--      Status 3 (hat Aggro / Tankt): Rot
-- 3. Färbt im Kampf die Gesundheitsbalken naher feindlicher Namensplaketten nach Bedrohungsstufe.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    threatShowNumeric = false,
  },
})

local ThreatDisplay = {}
ns.ThreatDisplay = ThreatDisplay

local CVAR = "threatShowNumeric"

ThreatDisplay.COLORS = {
  [0] = { 0.69, 0.69, 0.69 }, -- Grau: niedrige Bedrohung
  [1] = { 1.00, 1.00, 0.47 }, -- Gelb: hohe Bedrohung
  [2] = { 1.00, 0.60, 0.00 }, -- Orange: kurz vor Aggro / Verlust
  [3] = { 1.00, 0.15, 0.15 }, -- Rot: hat Aggro
}

local badgeFrame
local badgeBg
local badgeBorder
local badgeGlow
local badgeText
local activePlates = {} -- unit -> plate
local coloredBars = {}  -- healthBar -> { r, g, b }

local function isReadableNumber(val)
  return type(val) == "number" and not ns.IsSecret(val)
end

local function isReadableBool(val)
  return type(val) == "boolean" and not ns.IsSecret(val)
end

local function blizzardIndicatorShown()
  local modern = _G.TargetFrame and _G.TargetFrame.threatNumericIndicator
  if modern and modern.IsShown and modern:IsShown() then return true end
  local classic = _G.TargetFrameNumericalThreat
  if classic and classic.IsShown and classic:IsShown() then return true end
  return false
end

local function ensureBadge()
  if badgeFrame then return badgeFrame end
  local parent = _G.TargetFrame or UIParent
  badgeFrame = CreateFrame("Frame", "LevelTimerTargetThreat", parent)
  badgeFrame:SetSize(48, 20)
  badgeFrame:SetPoint("BOTTOM", parent, "TOP", -30, -22)
  if badgeFrame.SetFrameStrata then
    badgeFrame:SetFrameStrata("HIGH")
  end

  badgeGlow = badgeFrame:CreateTexture(nil, "BACKGROUND")
  badgeGlow:SetPoint("TOPLEFT", badgeFrame, "TOPLEFT", -3, 3)
  badgeGlow:SetPoint("BOTTOMRIGHT", badgeFrame, "BOTTOMRIGHT", 3, -3)
  badgeGlow:SetColorTexture(1.0, 0.6, 0.0, 0.85)
  badgeGlow:Hide()

  badgeBorder = badgeFrame:CreateTexture(nil, "BORDER")
  badgeBorder:SetAllPoints()
  badgeBorder:SetColorTexture(0.15, 0.15, 0.15, 0.95)

  badgeBg = badgeFrame:CreateTexture(nil, "ARTWORK")
  badgeBg:SetPoint("TOPLEFT", badgeFrame, "TOPLEFT", 1, -1)
  badgeBg:SetPoint("BOTTOMRIGHT", badgeFrame, "BOTTOMRIGHT", -1, 1)
  badgeBg:SetColorTexture(0.69, 0.69, 0.69, 0.90)

  badgeText = badgeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  badgeText:SetPoint("CENTER", badgeFrame, "CENTER", 0, 0)
  badgeText:SetTextColor(1, 1, 1, 1)
  badgeText:SetText("")

  badgeFrame:Hide()
  ThreatDisplay.badge = badgeFrame
  return badgeFrame
end

function ThreatDisplay.ColorForStatus(status)
  if not isReadableNumber(status) then return nil end
  return ThreatDisplay.COLORS[status]
end

function ThreatDisplay.TargetThreat()
  if not UnitExists or not UnitExists("target") then return nil end
  if UnitCanAttack and not UnitCanAttack("player", "target") then return nil end
  local dead = UnitIsDeadOrGhost and UnitIsDeadOrGhost("target")
  if isReadableBool(dead) and dead then return nil end
  if not UnitDetailedThreatSituation then return nil end

  local ok, isTanking, status, scaledPercent, rawPercent, threatValue =
    pcall(UnitDetailedThreatSituation, "player", "target")
  if not ok then return nil end
  if not isReadableNumber(status) then return nil end

  local pct = isReadableNumber(scaledPercent) and scaledPercent
    or (isReadableNumber(rawPercent) and rawPercent)
    or (status == 3 and 100 or nil)
  if not pct then return nil end
  if status == 0 and pct <= 0 and not (isReadableBool(isTanking) and isTanking) then
    return nil
  end
  return status, math.floor(pct + 0.5), isReadableBool(isTanking) and isTanking or false,
    isReadableNumber(threatValue) and threatValue or nil
end

function ThreatDisplay.UpdateTarget()
  if not ns.db or ns.db.threatShowNumeric ~= true then
    if badgeFrame then badgeFrame:Hide() end
    return
  end
  local frame = ensureBadge()
  local parent = _G.TargetFrame or UIParent
  if frame:GetParent() ~= parent then
    frame:SetParent(parent)
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOM", parent, "TOP", -30, -22)
  end

  if blizzardIndicatorShown() then
    frame:Hide()
    return
  end

  local status, pct = ThreatDisplay.TargetThreat()
  if not status or not pct then
    frame:Hide()
    return
  end

  local color = ThreatDisplay.ColorForStatus(status) or ThreatDisplay.COLORS[0]
  badgeBg:SetColorTexture(color[1], color[2], color[3], 0.90)
  if status == 2 then
    badgeGlow:Show()
  else
    badgeGlow:Hide()
  end
  badgeText:SetText(pct .. "%")
  frame:Show()
end

local function findHealthBar(plate)
  if not plate or type(plate) ~= "table" then return nil end
  local uf = rawget(plate, "UnitFrame") or plate.UnitFrame
  if uf and uf.healthBar then return uf.healthBar end
  if plate.healthBar then return plate.healthBar end
  return nil
end

local function restoreBarColor(bar)
  local orig = coloredBars[bar]
  if not orig then return end
  coloredBars[bar] = nil
  if bar.SetStatusBarColor then
    pcall(bar.SetStatusBarColor, bar, orig[1], orig[2], orig[3])
  end
end

local function restoreAllPlates()
  for bar in pairs(coloredBars) do
    restoreBarColor(bar)
  end
end

function ThreatDisplay.UpdateNameplate(unit)
  if type(unit) ~= "string" or ns.IsSecret(unit) then return end
  local plate = activePlates[unit]
  if not plate and C_NamePlate and C_NamePlate.GetNamePlateForUnit then
    local ok, p = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if ok and not ns.IsSecret(p) then plate = p end
  end
  local bar = findHealthBar(plate)
  if not bar then return end

  if not ns.db or ns.db.threatShowNumeric ~= true then
    restoreBarColor(bar)
    return
  end

  local inCombat = UnitAffectingCombat and UnitAffectingCombat(unit)
  local canAttack = not UnitCanAttack or UnitCanAttack("player", unit)
  local status = UnitThreatSituation and UnitThreatSituation("player", unit)
  if not isReadableNumber(status) and UnitDetailedThreatSituation then
    local ok, _, detStatus = pcall(UnitDetailedThreatSituation, "player", unit)
    if ok and isReadableNumber(detStatus) then status = detStatus end
  end

  local color = (isReadableBool(inCombat) and inCombat and canAttack) and ThreatDisplay.ColorForStatus(status) or nil
  if not color then
    restoreBarColor(bar)
    return
  end

  if not coloredBars[bar] then
    local r, g, b = 1, 0, 0
    if bar.GetStatusBarColor then
      local ok, cr, cg, cb = pcall(bar.GetStatusBarColor, bar)
      if ok and isReadableNumber(cr) and isReadableNumber(cg) and isReadableNumber(cb) then
        r, g, b = cr, cg, cb
      end
    end
    coloredBars[bar] = { r, g, b }
  end
  if bar.SetStatusBarColor then
    pcall(bar.SetStatusBarColor, bar, color[1], color[2], color[3])
  end
end

function ThreatDisplay.UpdateAllNameplates()
  if not ns.db or ns.db.threatShowNumeric ~= true then
    restoreAllPlates()
    return
  end
  for unit in pairs(activePlates) do
    ThreatDisplay.UpdateNameplate(unit)
  end
end

function ThreatDisplay.BadgeFrame()
  return ensureBadge()
end

function ThreatDisplay.BadgeText()
  return badgeText and badgeText:GetText() or ""
end

function ThreatDisplay.IsGlowShown()
  return badgeGlow ~= nil and badgeGlow:IsShown()
end

local events = ns.NewEventGroup()

events.Add("PLAYER_TARGET_CHANGED", nil, function()
  ThreatDisplay.UpdateTarget()
end)

events.Add("UNIT_THREAT_LIST_UPDATE", nil, function(unit)
  ThreatDisplay.UpdateTarget()
  if unit and activePlates[unit] then
    ThreatDisplay.UpdateNameplate(unit)
  else
    ThreatDisplay.UpdateAllNameplates()
  end
end)

events.Add("UNIT_THREAT_SITUATION_UPDATE", nil, function()
  ThreatDisplay.UpdateTarget()
  ThreatDisplay.UpdateAllNameplates()
end)

events.Add("PLAYER_REGEN_DISABLED", nil, function()
  ThreatDisplay.UpdateTarget()
  ThreatDisplay.UpdateAllNameplates()
end)

events.Add("PLAYER_REGEN_ENABLED", nil, function()
  ThreatDisplay.UpdateTarget()
  restoreAllPlates()
end)

events.Add("NAME_PLATE_UNIT_ADDED", nil, function(unit)
  if type(unit) ~= "string" or ns.IsSecret(unit) then return end
  if C_NamePlate and C_NamePlate.GetNamePlateForUnit then
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if ok and not ns.IsSecret(plate) and plate then
      activePlates[unit] = plate
    end
  end
  ThreatDisplay.UpdateNameplate(unit)
end)

events.Add("NAME_PLATE_UNIT_REMOVED", nil, function(unit)
  if type(unit) ~= "string" or ns.IsSecret(unit) then return end
  local plate = activePlates[unit]
  activePlates[unit] = nil
  local bar = findHealthBar(plate)
  if bar then restoreBarColor(bar) end
end)

local function apply(db)
  db = db or ns.db
  if not db then return end
  local enabled = db.threatShowNumeric == true
  if enabled then
    ns.CVars.Override(CVAR, "1")
  else
    ns.CVars.Restore(CVAR)
  end
  events.SetActive(enabled)
  ThreatDisplay.UpdateTarget()
  ThreatDisplay.UpdateAllNameplates()
  ns.Debug("threat", "apply threatShowNumeric=%s", enabled)
end

ThreatDisplay.Apply = apply
ns.RegisterApply(apply)

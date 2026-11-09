-- Reichweiten-Anzeige am Zielrahmen (Roadmap 447): Kompakte Entfernungsanzeige in Metern
-- (0-10 m, 10-11 m, 11-28 m, 28+ m) am Zielrahmen. Gedrosselt über ns.Every(0.25) nur bei vorhandenem Ziel.
-- Nutzt CheckInteractDistance mit Schutz vor geheimen Werten (ns.IsSecret).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    showTargetRange = false,
  },
})

local TargetRange = {}
ns.TargetRange = TargetRange

local function checkDistance(unit, index)
  if not CheckInteractDistance then return false end
  local ok, val = pcall(CheckInteractDistance, unit, index)
  if not ok or ns.IsSecret(val) then return false end
  return val == true
end

function TargetRange.Estimate(unit)
  unit = unit or "target"
  if not UnitExists(unit) then return nil end
  local dead = UnitIsDeadOrGhost(unit)
  if not ns.IsSecret(dead) and dead == true then return nil end

  if checkDistance(unit, 3) then
    return "0-10 m"
  elseif checkDistance(unit, 2) then
    return "10-11 m"
  elseif checkDistance(unit, 1) then
    return "11-28 m"
  else
    return "28+ m"
  end
end

local frame = CreateFrame("Frame", ns.GlobalName("TargetRange"), UIParent)
frame:SetSize(70, 20)
frame:SetClampedToScreen(true)
frame:Hide()

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
text:SetPoint("CENTER", frame, "CENTER", 0, 0)
text:SetText("")

TargetRange.frame = frame
TargetRange.text = text

function TargetRange.Frame()
  return frame
end

function TargetRange.Text()
  return text:GetText()
end

function TargetRange.Update()
  if not ns.db or not ns.db.showTargetRange then
    frame:Hide()
    return
  end
  local range = TargetRange.Estimate("target")
  if not range then
    frame:Hide()
  else
    text:SetText(range)
    frame:Show()
  end
end

local function preview(editing)
  if editing then
    text:SetText("10-11 m")
    frame:Show()
  else
    TargetRange.Update()
  end
end

ns.Frames.Register({
  id = "targetRange",
  frame = frame,
  label = "COMFORT_TARGET_RANGE",
  labelKey = "COMFORT_TARGET_RANGE",
  default = { "CENTER", "CENTER", 0, -120 },
  defaultScale = 1,
  settingsPage = "comfort",
  clickable = true,
  dragWhenUnlocked = true,
  actionsTip = true,
  preview = preview,
  hide = function() ns.Set("showTargetRange", false) end,
})

ns.RegisterEvent("PLAYER_TARGET_CHANGED", function()
  if ns.db and ns.db.showTargetRange then
    TargetRange.Update()
  end
end)

ns.Every(0.25, function()
  TargetRange.Update()
end, function(db) return db.showTargetRange end)

ns.RegisterApply(function(db)
  if not db.showTargetRange then
    frame:Hide()
  else
    TargetRange.Update()
  end
end)

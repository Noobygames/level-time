-- Druiden-Manaleiste (Reiter Komfort, Fenster; druidManaBar, Standard aus): in Bär- und Katzengestalt eine schmale
-- Manaleiste unter Blizzards Energie-/Wutleiste am Spielerrahmen. Nur Classic Era/Anniversary: Retail und Forever
-- haben dafür Blizzards eigene Leiste (Blizzard_UnitFrame/Mainline/AlternatePowerBar.lua,
-- PlayerFrame_GetAlternatePowerBar). Werte aus UnitPower/UnitPowerMax("player", Mana), Gestalt aus UnitPowerType;
-- geheime Werte blenden die Leiste aus. Eigener Rahmen am Spielerrahmen (erstellt außerhalb des Kampfs, weil der
-- Spielerrahmen geschützt ist); Ereignisse nur, solange die Einstellung an ist.
local _, ns = ...

local DruidManaBar = {}
ns.DruidManaBar = DruidManaBar

local MANA = Enum and Enum.PowerType and Enum.PowerType.Mana or 0
local HEIGHT = 10
local GAP = 1
local MANA_COLOR = { 0, 0, 1 }
local BACKGROUND = { 0, 0, 0, 0.5 }

local bar

function DruidManaBar.IsAvailable()
  local _, class = UnitClass("player")
  return class == "DRUID" and PlayerFrameManaBar ~= nil and PlayerFrame_GetAlternatePowerBar == nil
    and not ns.Client.IsRetail() and not ns.Client.IsForever()
end

function DruidManaBar.Bar()
  return bar
end

local function readable(...)
  for index = 1, select("#", ...) do
    if ns.IsSecret((select(index, ...))) then return false end
  end
  return true
end

local function create()
  bar = CreateFrame("StatusBar", "LevelTimerDruidManaBar", PlayerFrame)
  bar:SetHeight(HEIGHT)
  bar:SetPoint("TOPLEFT", PlayerFrameManaBar, "BOTTOMLEFT", 0, -GAP)
  bar:SetPoint("TOPRIGHT", PlayerFrameManaBar, "BOTTOMRIGHT", 0, -GAP)
  bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetStatusBarColor(unpack(MANA_COLOR))
  local background = bar:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints()
  background:SetColorTexture(unpack(BACKGROUND))
  bar.text = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
  bar.text:SetPoint("CENTER")
  bar:Hide()
end

-- Nur in Gestalten ohne Mana (UnitPowerType ~= Mana) und mit lesbaren Werten
function DruidManaBar.Update()
  if not bar then return end
  local powerType = UnitPowerType("player")
  local mana, maxMana = UnitPower("player", MANA), UnitPowerMax("player", MANA)
  if not (ns.db.druidManaBar and readable(powerType, mana, maxMana)) or powerType == MANA
    or type(maxMana) ~= "number" or maxMana <= 0 then
    bar:Hide()
    return
  end
  bar:SetMinMaxValues(0, maxMana)
  bar:SetValue(mana)
  ns.Widgets.SetTextIfChanged(bar.text, string.format("%d / %d", mana, maxMana))
  bar:Show()
end

local events = ns.NewEventGroup()
for _, event in ipairs({ "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER" }) do
  events.Add(event, "player", DruidManaBar.Update)
end
events.Add("UPDATE_SHAPESHIFT_FORM", nil, DruidManaBar.Update)

-- Erstellen am geschützten Spielerrahmen erst nach dem Kampf
local pending = false
events.Add("PLAYER_REGEN_ENABLED", nil, function()
  if pending then
    pending = false
    create()
    DruidManaBar.Update()
  end
end)

ns.RegisterApply(function(db)
  local active = db.druidManaBar == true and DruidManaBar.IsAvailable()
  events.SetActive(active)
  if active and not bar then
    if InCombatLockdown() then pending = true else create() end
  end
  DruidManaBar.Update()
end)

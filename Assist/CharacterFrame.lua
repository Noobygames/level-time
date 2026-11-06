-- Zusätze im Charakterfenster (Reiter Komfort, Fenster; je Einstellung, Standard aus):
--   characterDurability  Gesamthaltbarkeit der Ausrüstung in Prozent links neben der Waffenhand, gefärbt von rot bis
--                        grün (GearWarnings.GetOverallDurability); aktualisiert bei UPDATE_INVENTORY_DURABILITY und
--                        beim Öffnen des Fensters.
--   characterVolume      Regler für die Gesamtlautstärke (CVar Sound_MasterVolume, 0..1) rechts neben den Waffen.
-- Anker: PaperDollFrame und die Waffenplätze CharacterMainHandSlot / CharacterSecondaryHandSlot / CharacterRangedSlot
-- (Fernkampf fehlt in Retail) gibt es in allen Clients; das Charakterfenster lädt mit dem Spiel (kein Load-on-Demand).
-- Beides sind eigene Frames, Blizzards Fenster wird nur per HookScript("OnShow") ergänzt.
local _, ns = ...
local L = ns.L

local CharacterFrameExtras = {}
ns.CharacterFrameExtras = CharacterFrameExtras

local SLOT_GAP = 8
local LABEL_GAP = 2
local VOLUME_WIDTH = 80
local VOLUME_CVAR = "Sound_MasterVolume"
-- Dokumentierte C_CVar-Funktionen bevorzugt, die Globalen nur als Rückfall
local getCVar = C_CVar and C_CVar.GetCVar or GetCVar
local setCVar = C_CVar and C_CVar.SetCVar or SetCVar
local VOLUME_STEP = 5   -- Prozent
local PERCENT = 100
-- Farbe der Haltbarkeit: unter LOW rot, unter MEDIUM gelb, sonst grün
local DURABILITY_LOW, DURABILITY_MEDIUM = 0.2, 0.6
local COLOR_LOW, COLOR_MEDIUM, COLOR_HIGH = { 1, 0.2, 0.1 }, { 1, 0.85, 0 }, { 0.2, 1, 0.2 }

local durabilityLabel, durabilityValue, volumeSlider

function CharacterFrameExtras.IsAvailable()
  return PaperDollFrame ~= nil and CharacterMainHandSlot ~= nil
end

-- Eigene Anzeigen (für Tests): Haltbarkeitswert und Lautstärkeregler, nil bis zum ersten Einschalten
function CharacterFrameExtras.Widgets()
  return durabilityValue, volumeSlider
end

function CharacterFrameExtras.DurabilityColor(fraction)
  if fraction < DURABILITY_LOW then return COLOR_LOW end
  if fraction < DURABILITY_MEDIUM then return COLOR_MEDIUM end
  return COLOR_HIGH
end

---------------------------------------------------------------------------
-- Haltbarkeit
---------------------------------------------------------------------------
local function updateDurability()
  if not durabilityValue then return end
  local fraction = ns.GearWarnings.GetOverallDurability()
  local shown = ns.db.characterDurability and fraction ~= nil
  durabilityLabel:SetShown(shown)
  durabilityValue:SetShown(shown)
  if not shown then return end
  durabilityLabel:SetText(L.NOTICE_DURABILITY)
  durabilityValue:SetText(ns.Format.Percent(fraction, 1))
  durabilityValue:SetTextColor(unpack(CharacterFrameExtras.DurabilityColor(fraction)))
end

local function createDurability()
  durabilityValue = PaperDollFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  durabilityValue:SetPoint("BOTTOMRIGHT", CharacterMainHandSlot, "BOTTOMLEFT", -SLOT_GAP, 0)
  durabilityLabel = PaperDollFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  durabilityLabel:SetPoint("BOTTOMRIGHT", durabilityValue, "TOPRIGHT", 0, LABEL_GAP)
end

---------------------------------------------------------------------------
-- Lautstärke
---------------------------------------------------------------------------
local function volumePercent()
  return math.floor((tonumber(getCVar(VOLUME_CVAR)) or 0) * PERCENT + 0.5)
end

local function formatVolume(percent)
  return string.format(L.VOLUME_PERCENT, percent)
end

local function refreshVolume()
  if not volumeSlider then return end
  volumeSlider:SetShown(ns.db.characterVolume == true)
  volumeSlider.label:SetText(L.MASTER_VOLUME)
  local percent = volumePercent()
  volumeSlider:SetValueSilently(percent, formatVolume(percent))
end

local function createVolume()
  volumeSlider = ns.Widgets.CreateSlider(PaperDollFrame, 0, PERCENT, VOLUME_STEP, function(percent)
    setCVar(VOLUME_CVAR, percent / PERCENT)
    volumeSlider.valueText:SetText(formatVolume(percent))
  end)
  volumeSlider:SetWidth(VOLUME_WIDTH)
  local lastWeapon = CharacterRangedSlot or CharacterSecondaryHandSlot or CharacterMainHandSlot
  volumeSlider:SetPoint("BOTTOMLEFT", lastWeapon, "BOTTOMRIGHT", SLOT_GAP, 0)
  ns.Widgets.AttachTooltip(volumeSlider.slider, function() return L.MASTER_VOLUME end,
    function() return L.CHARACTER_VOLUME_TIP end)
end

---------------------------------------------------------------------------
-- Anwenden
---------------------------------------------------------------------------
local created = false

local function refresh()
  updateDurability()
  refreshVolume()
end

local function create()
  if created or not CharacterFrameExtras.IsAvailable() then return end
  created = true
  createDurability()
  createVolume()
  PaperDollFrame:HookScript("OnShow", refresh)
end

ns.RegisterEvent("UPDATE_INVENTORY_DURABILITY", updateDurability)
ns.RegisterApply(function(db)
  if db.characterDurability or db.characterVolume then create() end
  refresh()
end)

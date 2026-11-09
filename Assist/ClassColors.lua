-- Klassenfarben in Einheitenrahmen (Reiter Komfort, Fenster; Einstellung classColorFrames, Standard aus): der
-- Namenshintergrund von Ziel- und Fokusrahmen zeigt bei Spielern die Klassenfarbe statt der Reaktionsfarbe.
-- Blizzard färbt ihn in TargetFrameMixin:CheckFaction (Retail/Forever TargetFrameContent.TargetFrameContentMain.
-- ReputationColor, Classic nameBackground) mit UnitSelectionColor; wir färben per hooksecurefunc danach um (kein
-- Ersetzen, nur die Farbe einer Textur, auch im Kampf erlaubt). Geheime Klassen (Forever/Retail in Instanzen)
-- bleiben bei Blizzards Farbe. Ausgeschaltet bekommen die Rahmen sofort wieder UnitSelectionColor.
-- classColorPlayerFrame (Standard aus): Namenshintergrund am Spielerrahmen in der eigenen Klassenfarbe. Classic-Rahmen
-- (PlayerFrameTexture, Classic Era/Anniversary) haben dort keinen; eigene Textur wie der Namenshintergrund des Ziels
-- (TargetFrame.xml: UI-TargetingFrame-LevelBackground, 119x19, TOPRIGHT -90/-26), gespiegelt an der gleichen Stelle des
-- gleich großen Spielerrahmens. Retail/Forever (Atlas-Rahmen) fehlen: Lage ohne Blizzard-Vorbild ungeprüft.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    classColorPlayerFrame = false,
    classColorFrames = false,
  },
})

local ClassColors = {}
ns.ClassColors = ClassColors

ClassColors.FRAME_NAMES = { "TargetFrame", "FocusFrame" }
local hooked = false

local function asTable(value)
  if type(value) == "table" then return value end
end

-- Namenshintergrund eines Ziel- oder Fokusrahmens je Client
function ClassColors.NameBackground(frame)
  if not frame then return nil end
  local content = asTable(frame.TargetFrameContent)
  local main = content and asTable(content.TargetFrameContentMain)
  return (main and asTable(main.ReputationColor)) or asTable(frame.nameBackground)
end

function ClassColors.Frames()
  local list = {}
  for _, name in ipairs(ClassColors.FRAME_NAMES) do
    local frame = _G[name]
    if frame and ClassColors.NameBackground(frame) and frame.CheckFaction then table.insert(list, frame) end
  end
  return list
end

function ClassColors.IsAvailable()
  return #ClassColors.Frames() > 0
end

-- Klassenfarbe eines Spielers, nil bei NPCs und geheimen Werten
function ClassColors.ForUnit(unit)
  local isPlayer = UnitIsPlayer(unit)
  if ns.IsSecret(isPlayer) or not isPlayer then return nil end
  local _, class = UnitClass(unit)
  if ns.IsSecret(class) or not class then return nil end
  return RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
end

local function paint(frame)
  if not ns.db.classColorFrames or not frame.unit then return end
  local color = ClassColors.ForUnit(frame.unit)
  if color then ClassColors.NameBackground(frame):SetVertexColor(color.r, color.g, color.b) end
end

-- Zurück zu Blizzards Farbe (Spieler sind immer "player controlled", also UnitSelectionColor wie in CheckFaction)
local function restore(frame)
  if frame.unit and UnitExists(frame.unit) and ClassColors.ForUnit(frame.unit) then
    ClassColors.NameBackground(frame):SetVertexColor(UnitSelectionColor(frame.unit))
  end
end

---------------------------------------------------------------------------
-- Spielerrahmen (Classic-Rahmen)
---------------------------------------------------------------------------
ClassColors.PLAYER_NAME_TEXTURE = "Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground"
ClassColors.PLAYER_NAME_SIZE = { 119, 19 }
ClassColors.PLAYER_NAME_OFFSET = { 90, -26 }
local NAME_SUBLEVEL = 1  -- über PlayerFrameBackground (gleiche Schicht)

local playerBackground

function ClassColors.CanColorPlayerFrame()
  return PlayerFrame ~= nil and PlayerFrameTexture ~= nil and PlayerName ~= nil
end

function ClassColors.PlayerBackground()
  return playerBackground
end

local function applyPlayerFrame(enabled)
  if not ClassColors.CanColorPlayerFrame() then return end
  if enabled and not playerBackground then
    playerBackground = PlayerFrame:CreateTexture(nil, "BACKGROUND", nil, NAME_SUBLEVEL)
    playerBackground:SetTexture(ClassColors.PLAYER_NAME_TEXTURE)
    playerBackground:SetTexCoord(1, 0, 0, 1)  -- gespiegelt wie der ganze Spielerrahmen
    playerBackground:SetSize(unpack(ClassColors.PLAYER_NAME_SIZE))
    playerBackground:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", unpack(ClassColors.PLAYER_NAME_OFFSET))
  end
  if not playerBackground then return end
  local color = enabled and ClassColors.ForUnit("player")
  if color then playerBackground:SetVertexColor(color.r, color.g, color.b) end
  playerBackground:SetShown(color ~= nil and color ~= false)
end

ns.RegisterApply(function(db)
  applyPlayerFrame(db.classColorPlayerFrame)
  local frames = ClassColors.Frames()
  if db.classColorFrames and not hooked then
    hooked = true
    for _, frame in ipairs(frames) do hooksecurefunc(frame, "CheckFaction", paint) end
  end
  for _, frame in ipairs(frames) do
    if db.classColorFrames then paint(frame) elseif hooked then restore(frame) end
  end
end)

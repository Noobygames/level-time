-- Anprobe verbessern (Reiter Komfort, Fenster; dressUpButtons, Standard aus): zwei Knöpfe im Anprobe-Fenster links
-- neben Blizzards "Zurücksetzen" (DressUpFrameResetButton, alle Clients): "Ausziehen" (alles ab) und "Wappenrock"
-- (nur den Wappenrock ab, INVSLOT_TABARD). Das Modell je Client:
--   Classic Era/Anniversary  DressUpModelFrame (DressUpModel, FrameAPIDressUpModelDocumentation: Undress/UndressSlot)
--   Retail/Forever           DressUpFrame.ModelScene:GetPlayerActor() (FrameAPIModelSceneFrameActorDocumentation:
--                            Undress/UndressSlot), wie Blizzards DressUpFrames.lua
-- Blizzards "Zurücksetzen" zieht wieder alles an. Eigene Knöpfe, keine Blizzard-Skripte ersetzt.
local _, ns = ...
local L = ns.L

local DressUp = {}
ns.DressUp = DressUp

local TABARD_SLOT = INVSLOT_TABARD or 19
local BUTTON_MIN_WIDTH = 80
local BUTTON_HEIGHT = 22
local BUTTON_GAP = 2

local buttons

function DressUp.IsAvailable()
  return DressUpFrame ~= nil and DressUpFrameResetButton ~= nil
end

-- Modell oder Darsteller mit Undress/UndressSlot, nil wenn keiner da ist
function DressUp.Model()
  local scene = DressUpFrame and DressUpFrame.ModelScene
  if type(scene) == "table" and scene.GetPlayerActor then
    local actor = scene:GetPlayerActor()
    if type(actor) == "table" and actor.Undress then return actor end
  end
  if DressUpModelFrame and DressUpModelFrame.Undress then return DressUpModelFrame end
  return nil
end

function DressUp.UndressAll()
  local model = DressUp.Model()
  if model then model:Undress() end
end

function DressUp.UndressTabard()
  local model = DressUp.Model()
  if model then model:UndressSlot(TABARD_SLOT) end
end

function DressUp.Buttons()
  return buttons
end

local function addButton(anchor, labelKey, onClick)
  local button = ns.Widgets.CreateButton(DressUpFrame, BUTTON_MIN_WIDTH, BUTTON_HEIGHT, onClick)
  button:SetPoint("RIGHT", anchor, "LEFT", -BUTTON_GAP, 0)
  ns.Widgets.SetButtonText(button, L[labelKey], BUTTON_MIN_WIDTH)
  ns.Widgets.AttachTooltip(button, function() return L[labelKey] end, function() return L[labelKey .. "_TIP"] end)
  return button
end

local function create()
  buttons = {}
  buttons.undress = addButton(DressUpFrameResetButton, "DRESS_UP_UNDRESS", DressUp.UndressAll)
  buttons.tabard = addButton(buttons.undress, "DRESS_UP_TABARD", DressUp.UndressTabard)
end

ns.RegisterApply(function(db)
  if not DressUp.IsAvailable() then return end
  if db.dressUpButtons and not buttons then create() end
  if not buttons then return end
  for _, button in pairs(buttons) do button:SetShown(db.dressUpButtons == true) end
  -- Beschriftungen folgen der Sprache
  ns.Widgets.SetButtonText(buttons.undress, L.DRESS_UP_UNDRESS, BUTTON_MIN_WIDTH)
  ns.Widgets.SetButtonText(buttons.tabard, L.DRESS_UP_TABARD, BUTTON_MIN_WIDTH)
end)

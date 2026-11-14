-- Kreatur-Porträt ohne mitgelieferte Bilder: der Client zeichnet die Kreatur live in einem Modellrahmen
-- (PlayerModel:SetCreature(creatureID), Porträt-Zoom wie Blizzards QuestNPCModel). SetCreature, SetPortraitZoom und
-- SetCamDistanceScale gehören zu CharacterModelBase (Blizzards generierte Doku, auch im Zweig classic_era) und sind
-- laut warcraft.wiki.gg in Retail, Classic Era und WoW Forever vorhanden; fehlt trotzdem eine Methode oder die
-- NPC-ID, zeigt der Rahmen ein Totenkopf-Symbol.
-- Das Modell entsteht erst beim ersten Bedarf; dieselbe NPC-ID setzt nichts neu (die Fenster rechnen jede Sekunde neu,
-- SetCreature lädt das Modell neu). Als Kind des Aufrufers verschwindet es mit dessen Fenster.
--   local portrait = CreatureModel.Create(parent, size)
--   CreatureModel.Set(portrait, npcID)   -- nil = Symbol
--   portrait.npcID = gezeigte NPC-ID (false = Symbol), portrait.model = Modellrahmen (false = noch keiner)
local _, ns = ...

local CreatureModel = {}
ns.CreatureModel = CreatureModel

local FALLBACK_ICON = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
CreatureModel.FALLBACK_ICON = FALLBACK_ICON
local BACKGROUND_COLOR = { 0.05, 0.05, 0.05, 1 }  -- deckend: im Live-Tracker liegt das Porträt über dem Kartensymbol
local PORTRAIT_ZOOM = 1        -- 1 = Kopf und Schultern, 0 = ganze Figur
local CAM_DISTANCE_SCALE = 1

-- Methode aufrufen, falls der Client sie kennt
local function call(object, method, ...)
  local fn = object[method]
  if fn then fn(object, ...) end
end

-- Kamera aufs Gesicht; auch nach dem Laden des Modells, weil das Laden die Kamera zurücksetzen kann
local function frameCamera(model)
  call(model, "SetPortraitZoom", PORTRAIT_ZOOM)
  call(model, "SetCamDistanceScale", CAM_DISTANCE_SCALE)
end

-- Modellrahmen des Porträts (beim ersten Bedarf angelegt) oder nil, wenn der Client SetCreature nicht kennt
local unsupported = false
local function modelOf(portrait)
  if not portrait.model and not unsupported then
    local model = CreateFrame("PlayerModel", nil, portrait)
    if model.SetCreature then
      model:SetAllPoints()
      if model.HasScript and model:HasScript("OnModelLoaded") then model:SetScript("OnModelLoaded", frameCamera) end
      portrait.model = model
    else
      ns.Debug("portrait", "no PlayerModel:SetCreature, icon fallback")
      model:Hide()
      unsupported = true
    end
  end
  return portrait.model or nil
end

function CreatureModel.Create(parent, size)
  local portrait = CreateFrame("Frame", nil, parent)
  portrait:SetSize(size, size)
  local background = portrait:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints()
  background:SetColorTexture(unpack(BACKGROUND_COLOR))
  portrait.icon = portrait:CreateTexture(nil, "ARTWORK")
  portrait.icon:SetAllPoints()
  portrait.icon:SetTexture(FALLBACK_ICON)
  portrait.npcID, portrait.model = false, false  -- immer gesetzt: im Test-Stub liefern unbekannte Felder eine Funktion
  return portrait
end

function CreatureModel.Set(portrait, npcID)
  npcID = npcID or false
  if npcID == portrait.npcID then return end
  local model = npcID and modelOf(portrait)
  portrait.npcID = model and npcID or false
  portrait.icon:SetShown(not model)
  if portrait.model then portrait.model:SetShown(model and true or false) end
  if model then
    model:SetCreature(npcID)
    frameCamera(model)
  end
end

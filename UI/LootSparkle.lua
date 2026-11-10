-- Das Glitzern selbst: ein kleiner Schwarm Funken (Media\Glint, aus tools/artwork) an einer Namensplakette.
-- Nur AnimationGroups (Blizzard_APIDocumentationGenerated SimpleAnimGroup/Alpha/Scale/Rotation, in Forever, Retail
-- und Classic Era gleich), kein OnUpdate: ohne angehängtes Glitzern läuft nichts. Jeder Funke hat eine eigene
-- Schleife mit anderer Dauer und Pause und springt bei jedem Durchlauf (OnLoop) an eine neue Stelle.
-- Zustände (LootTarget): READY hell und golden, FAR gedämpft, LOCKED grau; der Wechsel zu READY lässt alle
-- Funken auf einmal neu aufleuchten.
--   LootSparkle.Attach(plate, state, kind)  an die Plakette hängen und einblenden
--   LootSparkle.SetState(state, kind)       Aussehen wechseln
--   LootSparkle.Release()                   abnehmen und anhalten
--   LootSparkle.AttachedTo()                aktuelle Plakette oder nil
--   LootSparkle.Preview(kind)               Vorschau für 4 Sekunden
local addonName, ns = ...

local LootSparkle = {}
ns.LootSparkle = LootSparkle

LootSparkle.TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\Media\\Glint"
LootSparkle.MIN_SCALE, LootSparkle.MAX_SCALE = 0.5, 2

LootSparkle.CATEGORY_COLORS = {
  ore   = { 1.00, 0.60, 0.18 },
  herb  = { 0.40, 1.00, 0.42 },
  quest = { 1.00, 0.84, 0.15 },
  chest = { 0.45, 0.78, 1.00 },
  bobber = { 1.00, 0.45, 0.40 },
  corpse = { 1.00, 0.86, 0.45 },
}

local GLINT_COUNT = 6
local GLINT_SIZE = 30      -- Pixel bei Größe 1
local SPREAD_X, SPREAD_Y = 40, 28  -- Halbachsen der Fläche, in der Funken erscheinen
local OFFSET_Y = -40       -- von der Plakette nach unten zum Objekt
local FADE_IN_SECONDS = 0.35
local MIN_SHINE, MAX_SHINE = 0.7, 1.3  -- Dauer eines Aufleuchtens (Sekunden)
local MAX_PAUSE = 0.6      -- dunkle Pause vor einem Aufleuchten
local MIN_GROWTH, MAX_GROWTH = 0.35, 1  -- Größe am Anfang und auf dem Höhepunkt
local TURN_DEGREES = 60

local SHADE_BASE_WIDTH, SHADE_BASE_HEIGHT = 96, 54
local PREVIEW_DURATION = 4
local PREVIEW_CYCLE = { "ore", "herb", "quest", "chest", "bobber", "corpse" }

-- Farbe und Deckkraft je Zustand
local LOOKS = {
  ready = { color = { 1, 0.86, 0.45 }, alpha = 1 },
  far = { color = { 1, 0.86, 0.45 }, alpha = 0.5 },
  locked = { color = { 0.6, 0.6, 0.6 }, alpha = 0.45 },
}

local frame       -- Träger der Funken, wird an die Plakette gehängt
local shade       -- Dunkler Bodenschatten für Kontrast
local silhouetteMask  -- Maske für Spieler-Silhouette
local silhouetteActive = false
local fadeIn      -- Einblenden des ganzen Schwarms
local glints = {} -- { texture, animation }
local plate, state, kind
local previewToken = 0
local previewIndex = 0

local function between(low, high)
  return low + (high - low) * math.random()
end

-- Neue Stelle und Größe in einer flachen Ellipse
local function place(glint)
  local angle, reach = math.random() * 2 * math.pi, math.sqrt(math.random())
  local texture = glint.texture
  texture:ClearAllPoints()
  texture:SetPoint("CENTER", frame, "CENTER", math.cos(angle) * reach * SPREAD_X, math.sin(angle) * reach * SPREAD_Y)
  local size = GLINT_SIZE * between(0.6, 1.2)
  texture:SetSize(size, size)
end

-- Aufleuchten: einblenden und wachsen, dann ausblenden und schrumpfen, dabei leicht drehen
local function createAnimation(texture)
  local shine = between(MIN_SHINE, MAX_SHINE)
  local group = texture:CreateAnimationGroup()
  group:SetLooping("REPEAT")
  local turn = (math.random() < 0.5 and TURN_DEGREES or -TURN_DEGREES) / 2
  local steps = {
    { "Alpha", 1, function(a) a:SetFromAlpha(0); a:SetToAlpha(1) end },
    { "Alpha", 2, function(a) a:SetFromAlpha(1); a:SetToAlpha(0) end },
    { "Scale", 1, function(a) a:SetScaleFrom(MIN_GROWTH, MIN_GROWTH); a:SetScaleTo(MAX_GROWTH, MAX_GROWTH) end },
    { "Scale", 2, function(a) a:SetScaleFrom(MAX_GROWTH, MAX_GROWTH); a:SetScaleTo(MIN_GROWTH, MIN_GROWTH) end },
    { "Rotation", 1, function(a) a:SetDegrees(turn) end },
    { "Rotation", 2, function(a) a:SetDegrees(turn) end },
  }
  -- Pause nur vor der ersten Hälfte; die Textur selbst ist unsichtbar (Alpha 0), also bleibt es dann dunkel
  local pause = between(0, MAX_PAUSE)
  for _, step in ipairs(steps) do
    local animation = group:CreateAnimation(step[1])
    animation:SetOrder(step[2])
    animation:SetDuration(shine / 2)
    if step[2] == 1 then animation:SetStartDelay(pause) end
    step[3](animation)
  end
  return group
end

local function updateShadeSize()
  if not shade then return end
  local scale = LootSparkle.CurrentScale()
  shade:SetSize(SHADE_BASE_WIDTH * scale, SHADE_BASE_HEIGHT * scale)
end

local function applySilhouette()
  if not frame then return end
  local enabled = ns.db and ns.db.lootSparkleSilhouette == true
  if enabled and type(frame.CreateMaskTexture) == "function" then
    if not silhouetteMask then
      local mask = frame:CreateMaskTexture()
      if mask then
        mask:SetSize(128, 128)
        mask:ClearAllPoints()
        mask:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        if mask.SetTexture then
          mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        end
        silhouetteMask = mask
      end
    end
    if silhouetteMask then
      for _, glint in ipairs(glints) do
        if glint.texture and glint.texture.AddMaskTexture then
          glint.texture:AddMaskTexture(silhouetteMask)
        end
      end
      if shade and shade.AddMaskTexture then
        shade:AddMaskTexture(silhouetteMask)
      end
    end
    silhouetteActive = true
  else
    if silhouetteMask then
      for _, glint in ipairs(glints) do
        if glint.texture and glint.texture.RemoveMaskTexture then
          glint.texture:RemoveMaskTexture(silhouetteMask)
        end
      end
      if shade and shade.RemoveMaskTexture then
        shade:RemoveMaskTexture(silhouetteMask)
      end
    end
    silhouetteActive = false
  end
end

local function create()
  frame = CreateFrame("Frame")
  frame:SetSize(1, 1)
  frame:Hide()

  shade = frame:CreateTexture(nil, "BACKGROUND")
  shade:SetTexture(LootSparkle.TEXTURE)
  shade:SetBlendMode("BLEND")
  shade:SetVertexColor(0, 0, 0)
  shade:SetAlpha(0.30)
  shade:ClearAllPoints()
  shade:SetPoint("CENTER", frame, "CENTER", 0, 0)
  updateShadeSize()

  fadeIn = frame:CreateAnimationGroup()
  local alpha = fadeIn:CreateAnimation("Alpha")
  alpha:SetFromAlpha(0)
  alpha:SetToAlpha(1)
  alpha:SetDuration(FADE_IN_SECONDS)
  for i = 1, GLINT_COUNT do
    local texture = frame:CreateTexture(nil, "OVERLAY")
    texture:SetTexture(LootSparkle.TEXTURE)
    texture:SetBlendMode("ADD")
    texture:SetAlpha(0)
    local glint = { texture = texture, animation = createAnimation(texture) }
    glint.animation:SetScript("OnLoop", function() place(glint) end)
    glints[i] = glint
  end
end

local function restartGlints()
  for _, glint in ipairs(glints) do
    glint.animation:Stop()
    place(glint)
    glint.animation:Play()
  end
end

function LootSparkle.ColorFor(colorState, colorKind)
  if colorState == "locked" or (ns.LootTarget and colorState == ns.LootTarget.LOCKED) then
    return LOOKS.locked.color
  end
  if ns.db and ns.db.lootSparkleCategoryColors == false then
    return LOOKS.ready.color
  end
  return (colorKind and LootSparkle.CATEGORY_COLORS[colorKind]) or LOOKS.ready.color
end

local function applyLook()
  local look = LOOKS[state] or LOOKS.ready
  frame:SetAlpha(look.alpha)
  local color = LootSparkle.ColorFor(state, kind)
  for _, glint in ipairs(glints) do
    glint.texture:SetVertexColor(color[1], color[2], color[3])
  end
end

function LootSparkle.CurrentScale()
  local scale = ns.db and ns.db.lootSparkleScale or 1
  return math.max(LootSparkle.MIN_SCALE, math.min(LootSparkle.MAX_SCALE, scale))
end

function LootSparkle.AttachedTo()
  return plate
end

function LootSparkle.State()
  return state
end

function LootSparkle.CurrentKind()
  return kind
end

function LootSparkle.HasShade()
  if not frame then create() end
  return shade ~= nil
end

function LootSparkle.Shade()
  if not frame then create() end
  return shade
end

function LootSparkle.Glints()
  if not frame then create() end
  return glints
end

function LootSparkle.IsSilhouetteActive()
  return silhouetteActive == true
end

function LootSparkle.SilhouetteMask()
  return silhouetteMask
end

function LootSparkle.IsPreviewing()
  return previewToken > 0
end

function LootSparkle.Attach(target, newState, newKind)
  if not frame then create() end
  if previewToken > 0 and target ~= UIParent then
    previewToken = 0
  end
  plate, state, kind = target, newState, newKind
  frame:SetParent(target)
  -- unter dem Inhalt der Plakette, damit der Name lesbar bleibt
  local level = target.GetFrameLevel and target:GetFrameLevel()
  if type(level) == "number" and not ns.IsSecret(level) then
    frame:SetFrameLevel(target == UIParent and math.max(level, 10) or math.max(level - 1, 0))
  end
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", target, "CENTER", 0, OFFSET_Y)
  -- gedimmte Plaketten (nicht anvisiert) sollen das Glitzern nicht mit abdunkeln
  frame:SetIgnoreParentAlpha(true)
  local scale = LootSparkle.CurrentScale()
  frame:SetScale(scale)
  updateShadeSize()
  applySilhouette()
  applyLook()
  frame:Show()
  fadeIn:Play()
  restartGlints()
  ns.Debug("sparkle", "attached, state %s kind %s", newState, newKind)
end

function LootSparkle.SetState(newState, newKind)
  if not plate then return end
  local changed = false
  if newState and newState ~= state then
    state = newState
    changed = true
  end
  if newKind and newKind ~= kind then
    kind = newKind
    changed = true
  end
  if not changed then return end
  applyLook()
  if state == (ns.LootTarget and ns.LootTarget.READY or "ready") then restartGlints() end
  ns.Debug("sparkle", "state %s kind %s", state, kind)
end

function LootSparkle.Release()
  if not plate then return end
  plate, state, kind = nil, nil, nil
  previewToken = 0
  for _, glint in ipairs(glints) do glint.animation:Stop() end
  fadeIn:Stop()
  frame:Hide()
  frame:ClearAllPoints()
  frame:SetParent(nil)
end

function LootSparkle.Preview(previewKind)
  if not previewKind then
    previewIndex = (previewIndex % #PREVIEW_CYCLE) + 1
    previewKind = PREVIEW_CYCLE[previewIndex]
  end
  previewToken = previewToken + 1
  local currentToken = previewToken
  local readyState = ns.LootTarget and ns.LootTarget.READY or "ready"
  LootSparkle.Attach(UIParent, readyState, previewKind)
  C_Timer.After(PREVIEW_DURATION, function()
    if previewToken == currentToken then
      LootSparkle.Release()
    end
  end)
end

ns.RegisterApply(function()
  if frame then
    local scale = LootSparkle.CurrentScale()
    frame:SetScale(scale)
    updateShadeSize()
    applySilhouette()
    if plate then applyLook() end
  end
end)

-- Das Glitzern selbst: Multi-Layer-2D-Effekt-Engine (Roadmap 456) an einer Namensplakette.
-- Kombiniert Bodenschatten (shade, BLEND), mehrschichtige Lichttexturen (SparkleHalo, SparkleRing,
-- SparkleArcs, SparkleBeam, SparkleSigil, SparkleFlare) im Blend-Modus ADD und Funken (Glint, SparkleFlare).
-- Nur AnimationGroups (Blizzard SimpleAnimGroup Alpha/Scale/Rotation), kein OnUpdate: ohne
-- angehängtes Glitzern läuft nichts.
-- 6 visuelle Stile (LootSparkle.STYLES):
--   "aura":    Halo + gegenläufig rotierende Sichelbögen + Funken
--   "beam":    Vertikale Lichtsäule + scharfer Bodenring + dezente Funken
--   "sigil":   Gegenläufig rotierendes Doppel-Siegel + Halo
--   "ripple":  Pulsierende konzentrische Bodenwellen + Halo
--   "sparkle": Aufsteigender Funkenschwarm + sanfter Halo
--   "subtle":  Dezenter, ruhiger Boden-Schein für minimale Ablenkung
-- Zustände (LootTarget): READY hell und kategoriefarben mit Aufblitz-Impuls (flash),
-- FAR gedämpft (alpha = 0.5), LOCKED grau (alpha = 0.45) mit eingefrorenen Zusatz-Layern.
--   LootSparkle.Attach(plate, state, kind)  an die Plakette hängen und einblenden
--   LootSparkle.SetState(state, kind)       Aussehen wechseln
--   LootSparkle.Release()                   abnehmen und anhalten
--   LootSparkle.AttachedTo()                aktuelle Plakette oder nil
--   LootSparkle.Preview(kind)               Vorschau für 4 Sekunden
local addonName, ns = ...

local LootSparkle = {}
ns.LootSparkle = LootSparkle

LootSparkle.STYLES = { "aura", "beam", "sigil", "ripple", "sparkle", "subtle" }

LootSparkle.TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\Media\\Glint"
LootSparkle.TEXTURE_HALO = "Interface\\AddOns\\" .. addonName .. "\\Media\\SparkleHalo"
LootSparkle.TEXTURE_RING = "Interface\\AddOns\\" .. addonName .. "\\Media\\SparkleRing"
LootSparkle.TEXTURE_ARCS = "Interface\\AddOns\\" .. addonName .. "\\Media\\SparkleArcs"
LootSparkle.TEXTURE_FLARE = "Interface\\AddOns\\" .. addonName .. "\\Media\\SparkleFlare"
LootSparkle.TEXTURE_BEAM = "Interface\\AddOns\\" .. addonName .. "\\Media\\SparkleBeam"
LootSparkle.TEXTURE_SIGIL = "Interface\\AddOns\\" .. addonName .. "\\Media\\SparkleSigil"
LootSparkle.MIN_SCALE, LootSparkle.MAX_SCALE = 0.5, 2

LootSparkle.CATEGORY_COLORS = {
  ore   = { 1.00, 0.60, 0.18 },
  herb  = { 0.40, 1.00, 0.42 },
  quest = { 1.00, 0.84, 0.15 },
  chest = { 0.45, 0.78, 1.00 },
  bobber = { 1.00, 0.45, 0.40 },
  corpse = { 1.00, 0.86, 0.45 },
}

local STYLE_LAYERS = {
  aura = { "arcs", "halo" },
  beam = { "beam", "ring1" },
  sigil = { "arcs", "halo", "sigil" },
  ripple = { "halo", "ring1", "ring2" },
  sparkle = { "halo" },
  subtle = { "halo", "ring1" },
}

local LAYER_ORDER = { "halo", "ring1", "ring2", "arcs", "beam", "sigil", "flash" }

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
local layers = {} -- { halo, ring1, ring2, ring, arcs, beam, sigil, flash }
local layerAnims = {}
local lastFlashAt = 0
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

local function createHaloAnim(tex)
  local group = tex:CreateAnimationGroup()
  group:SetLooping("REPEAT")
  local a1 = group:CreateAnimation("Alpha")
  a1:SetOrder(1)
  a1:SetDuration(1.6)
  a1:SetFromAlpha(0.65)
  a1:SetToAlpha(0.95)
  local a2 = group:CreateAnimation("Alpha")
  a2:SetOrder(2)
  a2:SetDuration(1.6)
  a2:SetFromAlpha(0.95)
  a2:SetToAlpha(0.65)
  local s1 = group:CreateAnimation("Scale")
  s1:SetOrder(1)
  s1:SetDuration(1.6)
  s1:SetScaleFrom(0.92, 0.92)
  s1:SetScaleTo(1.08, 1.08)
  local s2 = group:CreateAnimation("Scale")
  s2:SetOrder(2)
  s2:SetDuration(1.6)
  s2:SetScaleFrom(1.08, 1.08)
  s2:SetScaleTo(0.92, 0.92)
  return group
end

local function createArcsAnim(tex)
  local group = tex:CreateAnimationGroup()
  group:SetLooping("REPEAT")
  local r = group:CreateAnimation("Rotation")
  r:SetDuration(5.0)
  r:SetDegrees(360)
  return group
end

local function createSigilAnim(tex)
  local group = tex:CreateAnimationGroup()
  group:SetLooping("REPEAT")
  local r = group:CreateAnimation("Rotation")
  r:SetDuration(12.0)
  r:SetDegrees(-360)
  return group
end

local function createBeamAnim(tex)
  local group = tex:CreateAnimationGroup()
  group:SetLooping("REPEAT")
  local a1 = group:CreateAnimation("Alpha")
  a1:SetOrder(1)
  a1:SetDuration(1.2)
  a1:SetFromAlpha(0.55)
  a1:SetToAlpha(0.95)
  local a2 = group:CreateAnimation("Alpha")
  a2:SetOrder(2)
  a2:SetDuration(1.2)
  a2:SetFromAlpha(0.95)
  a2:SetToAlpha(0.55)
  local s1 = group:CreateAnimation("Scale")
  s1:SetOrder(1)
  s1:SetDuration(1.2)
  s1:SetScaleFrom(0.95, 0.9)
  s1:SetScaleTo(1.05, 1.1)
  local s2 = group:CreateAnimation("Scale")
  s2:SetOrder(2)
  s2:SetDuration(1.2)
  s2:SetScaleFrom(1.05, 1.1)
  s2:SetScaleTo(0.95, 0.9)
  return group
end

local function createRingAnim(tex, delay)
  local group = tex:CreateAnimationGroup()
  group:SetLooping("REPEAT")
  local s = group:CreateAnimation("Scale")
  s:SetDuration(1.8)
  s:SetScaleFrom(0.4, 0.4)
  s:SetScaleTo(1.3, 1.3)
  if delay and delay > 0 then s:SetStartDelay(delay) end
  local a1 = group:CreateAnimation("Alpha")
  a1:SetOrder(1)
  a1:SetDuration(0.4)
  a1:SetFromAlpha(0.2)
  a1:SetToAlpha(0.9)
  if delay and delay > 0 then a1:SetStartDelay(delay) end
  local a2 = group:CreateAnimation("Alpha")
  a2:SetOrder(2)
  a2:SetDuration(1.4)
  a2:SetFromAlpha(0.9)
  a2:SetToAlpha(0.0)
  return group
end

local function createFlashAnim(tex)
  local group = tex:CreateAnimationGroup()
  local s = group:CreateAnimation("Scale")
  s:SetDuration(0.26)
  s:SetScaleFrom(0.4, 0.4)
  s:SetScaleTo(1.3, 1.3)
  local a1 = group:CreateAnimation("Alpha")
  a1:SetOrder(1)
  a1:SetDuration(0.08)
  a1:SetFromAlpha(0.0)
  a1:SetToAlpha(1.0)
  local a2 = group:CreateAnimation("Alpha")
  a2:SetOrder(2)
  a2:SetDuration(0.18)
  a2:SetFromAlpha(1.0)
  a2:SetToAlpha(0.0)
  group:SetScript("OnFinished", function()
    tex:Hide()
  end)
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
      for _, name in ipairs(LAYER_ORDER) do
        local layer = layers[name]
        if layer and layer.AddMaskTexture then
          layer:AddMaskTexture(silhouetteMask)
        end
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
      for _, name in ipairs(LAYER_ORDER) do
        local layer = layers[name]
        if layer and layer.RemoveMaskTexture then
          layer:RemoveMaskTexture(silhouetteMask)
        end
      end
    end
    silhouetteActive = false
  end
end

function LootSparkle.CurrentStyle()
  local style = ns.db and ns.db.lootSparkleStyle
  if style and STYLE_LAYERS[style] then
    return style
  end
  return "aura"
end

function LootSparkle.ActiveLayerNames()
  local style = LootSparkle.CurrentStyle()
  local names = STYLE_LAYERS[style] or STYLE_LAYERS.aura
  local result = {}
  for i, name in ipairs(names) do
    result[i] = name
    result[name] = true
  end
  if result.ring1 then
    result.ring = true
  end
  return result
end

function LootSparkle.LastFlashAt()
  return lastFlashAt or 0
end

local function applyStyle()
  if not frame then return end
  local activeNames = LootSparkle.ActiveLayerNames()
  local color = LootSparkle.ColorFor(state, kind)
  for _, name in ipairs(LAYER_ORDER) do
    if name ~= "flash" then
      local layer = layers[name]
      local anim = layerAnims[name]
      if activeNames[name] then
        layer:Show()
        layer:SetVertexColor(color[1], color[2], color[3])
        if plate and state ~= "locked" and anim and not anim:IsPlaying() then
          anim:Play()
        end
      else
        if anim and anim:IsPlaying() then
          anim:Stop()
        end
        layer:Hide()
      end
    end
  end
end

local function triggerFlash()
  lastFlashAt = (type(GetTime) == "function" and GetTime()) or 1000
  if layers.flash and layerAnims.flash then
    local color = LootSparkle.ColorFor(state, kind)
    layers.flash:SetVertexColor(color[1], color[2], color[3])
    layers.flash:Show()
    layerAnims.flash:Stop()
    layerAnims.flash:Play()
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

  layers.halo = frame:CreateTexture(nil, "ARTWORK", nil, 1)
  layers.halo:SetTexture(LootSparkle.TEXTURE_HALO)
  layers.halo:SetBlendMode("ADD")
  layers.halo:SetSize(96, 96)
  layers.halo:SetPoint("CENTER", frame, "CENTER", 0, 0)
  layerAnims.halo = createHaloAnim(layers.halo)

  layers.ring1 = frame:CreateTexture(nil, "ARTWORK", nil, 2)
  layers.ring1:SetTexture(LootSparkle.TEXTURE_RING)
  layers.ring1:SetBlendMode("ADD")
  layers.ring1:SetSize(80, 80)
  layers.ring1:SetPoint("CENTER", frame, "CENTER", 0, 0)
  layerAnims.ring1 = createRingAnim(layers.ring1, 0)

  layers.ring2 = frame:CreateTexture(nil, "ARTWORK", nil, 2)
  layers.ring2:SetTexture(LootSparkle.TEXTURE_RING)
  layers.ring2:SetBlendMode("ADD")
  layers.ring2:SetSize(80, 80)
  layers.ring2:SetPoint("CENTER", frame, "CENTER", 0, 0)
  layerAnims.ring2 = createRingAnim(layers.ring2, 0.9)

  layers.ring = layers.ring1

  layers.arcs = frame:CreateTexture(nil, "ARTWORK", nil, 3)
  layers.arcs:SetTexture(LootSparkle.TEXTURE_ARCS)
  layers.arcs:SetBlendMode("ADD")
  layers.arcs:SetSize(84, 84)
  layers.arcs:SetPoint("CENTER", frame, "CENTER", 0, 0)
  layerAnims.arcs = createArcsAnim(layers.arcs)

  layers.beam = frame:CreateTexture(nil, "ARTWORK", nil, 4)
  layers.beam:SetTexture(LootSparkle.TEXTURE_BEAM)
  layers.beam:SetBlendMode("ADD")
  layers.beam:SetSize(48, 120)
  layers.beam:SetPoint("BOTTOM", frame, "CENTER", 0, -8)
  layerAnims.beam = createBeamAnim(layers.beam)

  layers.sigil = frame:CreateTexture(nil, "ARTWORK", nil, 3)
  layers.sigil:SetTexture(LootSparkle.TEXTURE_SIGIL)
  layers.sigil:SetBlendMode("ADD")
  layers.sigil:SetSize(88, 88)
  layers.sigil:SetPoint("CENTER", frame, "CENTER", 0, 0)
  layerAnims.sigil = createSigilAnim(layers.sigil)

  layers.flash = frame:CreateTexture(nil, "OVERLAY", nil, 5)
  layers.flash:SetTexture(LootSparkle.TEXTURE_FLARE)
  layers.flash:SetBlendMode("ADD")
  layers.flash:SetSize(72, 72)
  layers.flash:SetPoint("CENTER", frame, "CENTER", 0, 0)
  layers.flash:Hide()
  layerAnims.flash = createFlashAnim(layers.flash)

  for i = 1, GLINT_COUNT do
    local texture = frame:CreateTexture(nil, "OVERLAY")
    texture:SetTexture(i % 2 == 0 and LootSparkle.TEXTURE_FLARE or LootSparkle.TEXTURE)
    texture:SetBlendMode("ADD")
    texture:SetAlpha(0)
    local glint = { texture = texture, animation = createAnimation(texture) }
    glint.animation:SetScript("OnLoop", function() place(glint) end)
    glints[i] = glint
  end

  applyStyle()
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
  local activeNames = LootSparkle.ActiveLayerNames()
  for _, name in ipairs(LAYER_ORDER) do
    if name ~= "flash" and activeNames[name] then
      local layer = layers[name]
      layer:SetVertexColor(color[1], color[2], color[3])
      local anim = layerAnims[name]
      if anim then
        if state == "locked" then
          if name == "arcs" or name == "sigil" or name == "ring2" then
            anim:Stop()
          end
        elseif plate and not anim:IsPlaying() then
          anim:Play()
        end
      end
    end
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

function LootSparkle.Layers()
  if not frame then create() end
  return layers
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
  applyStyle()
  applyLook()
  frame:Show()
  fadeIn:Play()
  restartGlints()
  local readyState = ns.LootTarget and ns.LootTarget.READY or "ready"
  if state == readyState then
    triggerFlash()
  end
  ns.Debug("sparkle", "attached, state %s kind %s", newState, newKind)
end

function LootSparkle.SetState(newState, newKind)
  if not plate then return end
  local changed = false
  local oldState = state
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
  local readyState = ns.LootTarget and ns.LootTarget.READY or "ready"
  if state == readyState and oldState ~= state then
    restartGlints()
    triggerFlash()
  end
  ns.Debug("sparkle", "state %s kind %s", state, kind)
end

function LootSparkle.Release()
  if not plate then return end
  plate, state, kind = nil, nil, nil
  previewToken = 0
  for _, glint in ipairs(glints) do glint.animation:Stop() end
  for _, anim in pairs(layerAnims) do anim:Stop() end
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
    applyStyle()
    if plate then applyLook() end
  end
end)

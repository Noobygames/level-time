-- Das Glitzern selbst: Multi-Layer-2D-Effekt-Engine (Roadmap 456) an einer Namensplakette.
-- Stile und Schichten sind Daten in LootSparkleStyles.lua, die Animationen in LootSparkleAnimations.lua; hier
-- entstehen die Texturen, der Funkenschwarm, der Bodenschatten und die Zustandswechsel.
-- Stile (LootSparkle.STYLES, Reihenfolge wie im Auswahlfeld):
--   "finder":  Zielsucher, vier Eckklammern wie ein Kamera-Fokus (Standard)
--   "arrow":   Pfeil nach unten über dem Ziel, wippt
--   "glitter": schlichtes Glitzern, nur Funkelsterne
--   "symbol":  Kategorie-Symbol über dem Ziel, wippt
--   "clock", "progress", "pillar": Uhrwerk, Fortschrittsring, Lichtsäule (Bodenstile)
--   Klassisch (Glow): "aura", "beam", "sigil", "ripple", "sparkle", "subtle"
-- Nur AnimationGroups (Blizzard SimpleAnimGroup), kein OnUpdate: ohne angehängtes Glitzern läuft nichts.
-- Zustände (LootTarget): READY hell und kategoriefarben mit Aufblitz-Impuls (flash) und Schicht-Impuls
-- (readyAnimation), FAR gedämpft (alpha = 0.5), LOCKED grau (alpha = 0.45) mit eingefrorenen Zusatz-Layern.
--   LootSparkle.Attach(plate, state, kind)  an die Plakette hängen und einblenden
--   LootSparkle.SetState(state, kind)       Aussehen wechseln
--   LootSparkle.Release()                   abnehmen und anhalten
--   LootSparkle.AttachedTo()                aktuelle Plakette oder nil
--   LootSparkle.Preview(kind)               Vorschau für 4 Sekunden
local _, ns = ...

local LootSparkle = {}
ns.LootSparkle = LootSparkle

local Styles, Animations = ns.LootSparkleStyles, ns.LootSparkleAnimations

LootSparkle.STYLES = Styles.ORDER
LootSparkle.TEXTURE = Styles.TEXTURE.glint
LootSparkle.TEXTURE_FLARE = Styles.TEXTURE.flare
LootSparkle.MIN_SCALE, LootSparkle.MAX_SCALE = 0.5, 2


LootSparkle.CATEGORY_COLORS = {
  ore   = { 1.00, 0.60, 0.18 },
  herb  = { 0.40, 1.00, 0.42 },
  quest = { 1.00, 0.84, 0.15 },
  chest = { 0.45, 0.78, 1.00 },
  bobber = { 1.00, 0.45, 0.40 },
  corpse = { 1.00, 0.86, 0.45 },
}

-- Schichtnamen in Zeichenreihenfolge, die Blitz-Sonderschicht zuletzt
local LAYER_ORDER = {}
for _, def in ipairs(Styles.LAYERS) do table.insert(LAYER_ORDER, def.name) end


local GLINT_COUNT = 6
-- Zusatztexturen am Stern (nur in Stilen mit glintRim): dunkler weicher Umriss für Schnee und Sand, kleiner weißer Kern
local GLINT_EXTRAS = {
  { texture = Styles.TEXTURE.flare, blend = "BLEND", color = { 0, 0, 0 }, factor = 1.15, alpha = 0.35, sublevel = 0 },
  { texture = Styles.TEXTURE.glint, blend = "ADD", color = { 1, 1, 1 }, factor = 0.5, alpha = 0.9, sublevel = 2 },
}
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
local glints = {} -- { texture, animation, extras = { { texture, animation, factor } } }
local layers = {}     -- Textur je Schichtname (LootSparkleStyles.LAYERS) plus ring = ring1
local layerDefs = {}  -- Schichtdefinition je Name
local layerAnims = {} -- Dauer-Animation je Schicht
local readyAnims = {} -- Einmal-Animation beim Wechsel auf "ready" je Schicht
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
  -- Umriss und heller Kern hängen mittig am Stern und wachsen mit ihm
  for _, extra in ipairs(glint.extras) do
    extra.texture:ClearAllPoints()
    extra.texture:SetPoint("CENTER", texture, "CENTER", 0, 0)
    extra.texture:SetSize(size * extra.factor, size * extra.factor)
  end
end

-- Aufleuchten: einblenden und wachsen, dann ausblenden und schrumpfen, dabei leicht drehen
local function createAnimation(texture, timing)
  local shine, turn, pause = timing.shine, timing.turn, timing.pause
  local group = texture:CreateAnimationGroup()
  group:SetLooping("REPEAT")
  local steps = {
    { "Alpha", 1, function(a) a:SetFromAlpha(0); a:SetToAlpha(1) end },
    { "Alpha", 2, function(a) a:SetFromAlpha(1); a:SetToAlpha(0) end },
    { "Scale", 1, function(a) a:SetScaleFrom(MIN_GROWTH, MIN_GROWTH); a:SetScaleTo(MAX_GROWTH, MAX_GROWTH) end },
    { "Scale", 2, function(a) a:SetScaleFrom(MAX_GROWTH, MAX_GROWTH); a:SetScaleTo(MIN_GROWTH, MIN_GROWTH) end },
    { "Rotation", 1, function(a) a:SetDegrees(turn) end },
    { "Rotation", 2, function(a) a:SetDegrees(turn) end },
  }
  -- Pause nur vor der ersten Hälfte; die Textur selbst ist unsichtbar (Alpha 0), also bleibt es dann dunkel
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
  if style and Styles.Get(style) then
    return style
  end
  return Styles.DEFAULT
end

-- Aktive Schichten des Stils als Liste und Menge (Name = true); ring = true, sobald ring1 aktiv ist
function LootSparkle.ActiveLayerNames()
  local result = {}
  for i, name in ipairs(Styles.Get(LootSparkle.CurrentStyle()).layers) do
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

-- Ist die Schicht im aktuellen Zustand zu sehen? (def.states = nur in diesen Zuständen)
local function visibleInState(def)
  return not def.states or def.states[state or "ready"] == true
end

-- Läuft die Dauer-Animation? Eingefroren im Zustand "locked", wenn die Schicht es verlangt.
local function shouldAnimate(def)
  if state == "locked" and def.freezeLocked then return false end
  return plate ~= nil and (not def.animStates or def.animStates[state or "ready"] == true)
end

local function glintsEnabled()
  return Styles.Get(LootSparkle.CurrentStyle()).glints == true
end

-- Funkenschwarm passend zum Stil ein- oder ausschalten (läuft nur mit Plakette)
local function glintRimEnabled()
  return Styles.Get(LootSparkle.CurrentStyle()).glintRim == true
end

-- Zusatztexturen der Sterne laufen mit, solange der Stil sie verlangt
local function syncGlintExtras(glint, enabled)
  for _, extra in ipairs(glint.extras) do
    if enabled and glintRimEnabled() then
      extra.texture:Show()
      if not extra.animation:IsPlaying() then extra.animation:Play() end
    else
      extra.animation:Stop()
      extra.texture:Hide()
    end
  end
end

local function syncGlints()
  local enabled = plate ~= nil and glintsEnabled()
  for _, glint in ipairs(glints) do
    if enabled then
      if not glint.animation:IsPlaying() then
        place(glint)
        glint.texture:Show()
        glint.animation:Play()
      end
    else
      glint.animation:Stop()
      glint.texture:Hide()
    end
    syncGlintExtras(glint, enabled)
  end
end

-- Farbe zu Weiß aufhellen (amount 0 bis 1, nil = unverändert): heißer Kern statt flacher Farbe
function LootSparkle.Whiten(color, amount)
  if not amount or amount <= 0 then return color end
  return {
    color[1] + (1 - color[1]) * amount, color[2] + (1 - color[2]) * amount, color[3] + (1 - color[3]) * amount,
  }
end

-- Schichten des Stils zeigen, einfärben, in der Größe des Zustands setzen; Animationen starten oder anhalten.
-- Das Symbol wählt seinen Ausschnitt im Atlas nach der Kategorie.
local function applyLayers()
  local activeNames = LootSparkle.ActiveLayerNames()
  local color = LootSparkle.ColorFor(state, kind)
  for _, name in ipairs(LAYER_ORDER) do
    local def = layerDefs[name]
    if not def.flash then
      local layer, anim = layers[name], layerAnims[name]
      if activeNames[name] and visibleInState(def) then
        layer:Show()
        local tint = def.color or LootSparkle.Whiten(color, def.whiten)
        layer:SetVertexColor(tint[1], tint[2], tint[3])
        local size = def.sizes and def.sizes[state or "ready"] or def.size
        layer:SetSize(size[1], size[2])
        if def.atlas then layer:SetTexCoord(Styles.SymbolCoords(kind)) end
        local stateAlpha = def.stateAlpha and def.stateAlpha[state or "ready"]
        if stateAlpha then layer:SetAlpha(stateAlpha) end
        if anim then
          if shouldAnimate(def) then
            if not anim:IsPlaying() then anim:Play() end
          else
            anim:Stop()
          end
        end
      else
        if anim and anim:IsPlaying() then anim:Stop() end
        layer:Hide()
      end
    end
  end
end

local function applyStyle()
  if not frame then return end
  shade:SetShown(Styles.Get(LootSparkle.CurrentStyle()).shade == true)
  applyLayers()
  syncGlints()
end

-- Schicht-Impulse beim Wechsel auf "ready" (Zielsucher schnappt zu, Pfeil hüpft)
local function playReadyAnimations()
  local activeNames = LootSparkle.ActiveLayerNames()
  for name, anim in pairs(readyAnims) do
    if activeNames[name] and visibleInState(layerDefs[name]) then
      anim:Stop()
      anim:Play()
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

  for _, def in ipairs(Styles.LAYERS) do
    local texture = frame:CreateTexture(nil, def.layer or "ARTWORK", nil, def.sublevel)
    texture:SetTexture(def.texture)
    texture:SetBlendMode(def.blend or "ADD")
    texture:SetSize(def.size[1], def.size[2])
    local point = def.point or { "CENTER", 0, 0, "CENTER" }
    texture:SetPoint(point[1], frame, point[4], point[2], point[3])
    if def.alpha then texture:SetAlpha(def.alpha) end
    if def.cell then texture:SetTexCoord(Styles.CellCoords(def.cell)) end
    if def.flash then texture:Hide() end
    layers[def.name], layerDefs[def.name] = texture, def
    layerAnims[def.name] = def.animation and Animations[def.animation](texture, def) or nil
    readyAnims[def.name] = def.readyAnimation and Animations[def.readyAnimation](texture, def) or nil
  end
  layers.ring = layers.ring1

  for i = 1, GLINT_COUNT do
    local texture = frame:CreateTexture(nil, "OVERLAY")
    texture:SetTexture(i % 2 == 0 and LootSparkle.TEXTURE_FLARE or LootSparkle.TEXTURE)
    texture:SetBlendMode("ADD")
    texture:SetAlpha(0)
    -- ein Aufleuchten für den Stern und seine Zusatztexturen: gleiche Zeiten, damit sie im Gleichtakt laufen
    local timing = {
      shine = between(MIN_SHINE, MAX_SHINE), pause = between(0, MAX_PAUSE),
      turn = (math.random() < 0.5 and TURN_DEGREES or -TURN_DEGREES) / 2,
    }
    local glint = { texture = texture, animation = createAnimation(texture, timing), extras = {} }
    for _, extra in ipairs(GLINT_EXTRAS) do
      local part = frame:CreateTexture(nil, "OVERLAY", nil, extra.sublevel)
      part:SetTexture(extra.texture)
      part:SetBlendMode(extra.blend)
      part:SetVertexColor(extra.color[1], extra.color[2], extra.color[3], extra.alpha)
      part:SetAlpha(0)
      table.insert(glint.extras, {
        texture = part, factor = extra.factor, animation = createAnimation(part, timing), maxAlpha = extra.alpha,
      })
    end
    glint.animation:SetScript("OnLoop", function() place(glint) end)
    glints[i] = glint
  end

  applyStyle()
end

local function restartGlints()
  if not glintsEnabled() then return end
  for _, glint in ipairs(glints) do
    glint.animation:Stop()
    place(glint)
    glint.animation:Play()
    for _, extra in ipairs(glint.extras) do
      extra.animation:Stop()
      if glintRimEnabled() then extra.animation:Play() end
    end
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
  applyLayers()
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
    playReadyAnimations()
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
    playReadyAnimations()
    triggerFlash()
  end
  ns.Debug("sparkle", "state %s kind %s", state, kind)
end

function LootSparkle.Release()
  if not plate then return end
  plate, state, kind = nil, nil, nil
  previewToken = 0
  for _, glint in ipairs(glints) do
    glint.animation:Stop()
    for _, extra in ipairs(glint.extras) do extra.animation:Stop() end
  end
  for _, anim in pairs(layerAnims) do anim:Stop() end
  for _, anim in pairs(readyAnims) do anim:Stop() end
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

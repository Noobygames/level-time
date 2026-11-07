-- Das Glitzern selbst: ein kleiner Schwarm Funken (Media\Glint, aus tools/artwork) an einer Namensplakette.
-- Nur AnimationGroups (Blizzard_APIDocumentationGenerated SimpleAnimGroup/Alpha/Scale/Rotation, in Forever, Retail
-- und Classic Era gleich), kein OnUpdate: ohne angehängtes Glitzern läuft nichts. Jeder Funke hat eine eigene
-- Schleife mit anderer Dauer und Pause und springt bei jedem Durchlauf (OnLoop) an eine neue Stelle.
-- Zustände (LootTarget): READY hell und golden, FAR gedämpft, LOCKED grau; der Wechsel zu READY lässt alle
-- Funken auf einmal neu aufleuchten.
--   LootSparkle.Attach(plate, state)  an die Plakette hängen und einblenden
--   LootSparkle.SetState(state)       Aussehen wechseln
--   LootSparkle.Release()             abnehmen und anhalten
--   LootSparkle.AttachedTo()          aktuelle Plakette oder nil
local addonName, ns = ...

local LootSparkle = {}
ns.LootSparkle = LootSparkle

LootSparkle.TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\Media\\Glint"
LootSparkle.MIN_SCALE, LootSparkle.MAX_SCALE = 0.5, 2

local GLINT_COUNT = 6
local GLINT_SIZE = 30      -- Pixel bei Größe 1
local SPREAD_X, SPREAD_Y = 40, 28  -- Halbachsen der Fläche, in der Funken erscheinen
local OFFSET_Y = -40       -- von der Plakette nach unten zum Objekt
local FADE_IN_SECONDS = 0.35
local MIN_SHINE, MAX_SHINE = 0.7, 1.3  -- Dauer eines Aufleuchtens (Sekunden)
local MAX_PAUSE = 0.6      -- dunkle Pause vor einem Aufleuchten
local MIN_GROWTH, MAX_GROWTH = 0.35, 1  -- Größe am Anfang und auf dem Höhepunkt
local TURN_DEGREES = 60

-- Farbe und Deckkraft je Zustand
local LOOKS = {
  ready = { color = { 1, 0.86, 0.45 }, alpha = 1 },
  far = { color = { 1, 0.86, 0.45 }, alpha = 0.5 },
  locked = { color = { 0.6, 0.6, 0.6 }, alpha = 0.45 },
}

local frame       -- Träger der Funken, wird an die Plakette gehängt
local fadeIn      -- Einblenden des ganzen Schwarms
local glints = {} -- { texture, animation }
local plate, state

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

local function create()
  frame = CreateFrame("Frame")
  frame:SetSize(1, 1)
  frame:Hide()
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

local function applyLook()
  local look = LOOKS[state] or LOOKS.ready
  frame:SetAlpha(look.alpha)
  for _, glint in ipairs(glints) do
    glint.texture:SetVertexColor(look.color[1], look.color[2], look.color[3])
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

function LootSparkle.Attach(target, newState)
  if not frame then create() end
  plate, state = target, newState
  frame:SetParent(target)
  -- unter dem Inhalt der Plakette, damit der Name lesbar bleibt
  local level = target.GetFrameLevel and target:GetFrameLevel()
  if type(level) == "number" and not ns.IsSecret(level) then frame:SetFrameLevel(math.max(level - 1, 0)) end
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", target, "CENTER", 0, OFFSET_Y)
  -- gedimmte Plaketten (nicht anvisiert) sollen das Glitzern nicht mit abdunkeln
  frame:SetIgnoreParentAlpha(true)
  frame:SetScale(LootSparkle.CurrentScale())
  applyLook()
  frame:Show()
  fadeIn:Play()
  restartGlints()
  ns.Debug("sparkle", "attached, state %s", newState)
end

function LootSparkle.SetState(newState)
  if not plate or newState == state then return end
  state = newState
  applyLook()
  if newState == ns.LootTarget.READY then restartGlints() end  -- in Reichweite: alle Funken auf einmal
  ns.Debug("sparkle", "state %s", newState)
end

function LootSparkle.Release()
  if not plate then return end
  plate, state = nil, nil
  for _, glint in ipairs(glints) do glint.animation:Stop() end
  fadeIn:Stop()
  frame:Hide()
  frame:ClearAllPoints()
  frame:SetParent(nil)
end

ns.RegisterApply(function()
  if frame then frame:SetScale(LootSparkle.CurrentScale()) end
end)

-- Animationen der Glitzer-Schichten (Roadmap 456, 466, 475): je Name eine Funktion(Textur, Schichtdefinition) -> AnimationGroup.
-- Nur Blizzard-AnimationGroups (Alpha, Scale, Rotation, Translation), kein OnUpdate. Die Namen stehen in
-- LootSparkleStyles.LAYERS (animation = Schleife, readyAnimation = einmalig beim Wechsel auf "ready").
local _, ns = ...

local Animations = {}
ns.LootSparkleAnimations = Animations

-- Eine Animation der Gruppe anlegen: kind, Reihenfolge, Dauer, Einstellungen in fn(animation)
local function add(group, kind, order, duration, fn)
  local animation = group:CreateAnimation(kind)
  animation:SetOrder(order)
  animation:SetDuration(duration)
  fn(animation)
  return animation
end

local function loopingGroup(texture)
  local group = texture:CreateAnimationGroup()
  group:SetLooping("REPEAT")
  return group
end

-- Hin und zurück: Wert 1 -> 2 -> 1 in zwei Hälften gleicher Dauer
local function pingPong(group, kind, half, setup)
  add(group, kind, 1, half, function(a) setup(a, true) end)
  add(group, kind, 2, half, function(a) setup(a, false) end)
end

function Animations.halo(texture)
  local group = loopingGroup(texture)
  pingPong(group, "Alpha", 1.6, function(a, forth) a:SetFromAlpha(forth and 0.65 or 0.95); a:SetToAlpha(forth and 0.95 or 0.65) end)
  pingPong(group, "Scale", 1.6, function(a, forth)
    a:SetScaleFrom(forth and 0.92 or 1.08, forth and 0.92 or 1.08)
    a:SetScaleTo(forth and 1.08 or 0.92, forth and 1.08 or 0.92)
  end)
  return group
end

function Animations.arcs(texture)
  local group = loopingGroup(texture)
  add(group, "Rotation", 1, 5.0, function(a) a:SetDegrees(360) end)
  return group
end

function Animations.sigil(texture)
  local group = loopingGroup(texture)
  add(group, "Rotation", 1, 12.0, function(a) a:SetDegrees(-360) end)
  return group
end

function Animations.beam(texture)
  local group = loopingGroup(texture)
  pingPong(group, "Alpha", 1.2, function(a, forth) a:SetFromAlpha(forth and 0.55 or 0.95); a:SetToAlpha(forth and 0.95 or 0.55) end)
  pingPong(group, "Scale", 1.2, function(a, forth)
    a:SetScaleFrom(forth and 0.95 or 1.05, forth and 0.9 or 1.1)
    a:SetScaleTo(forth and 1.05 or 0.95, forth and 1.1 or 0.9)
  end)
  return group
end

-- Wachsender, ausblendender Ring; delay verschiebt den Start (zweite Welle)
local function ring(texture, delay)
  local group = loopingGroup(texture)
  local scale = add(group, "Scale", 1, 1.8, function(a) a:SetScaleFrom(0.4, 0.4); a:SetScaleTo(1.3, 1.3) end)
  local fadeIn = add(group, "Alpha", 1, 0.4, function(a) a:SetFromAlpha(0.2); a:SetToAlpha(0.9) end)
  add(group, "Alpha", 2, 1.4, function(a) a:SetFromAlpha(0.9); a:SetToAlpha(0.0) end)
  if delay > 0 then
    scale:SetStartDelay(delay)
    fadeIn:SetStartDelay(delay)
  end
  return group
end

function Animations.ring(texture) return ring(texture, 0) end
function Animations.ringLate(texture) return ring(texture, 0.9) end

-- Aufblitz-Impuls beim Wechsel auf "ready"; blendet die Textur danach aus
function Animations.flash(texture)
  local group = texture:CreateAnimationGroup()
  add(group, "Scale", 1, 0.26, function(a) a:SetScaleFrom(0.4, 0.4); a:SetScaleTo(1.3, 1.3) end)
  add(group, "Alpha", 1, 0.08, function(a) a:SetFromAlpha(0.0); a:SetToAlpha(1.0) end)
  add(group, "Alpha", 2, 0.18, function(a) a:SetFromAlpha(1.0); a:SetToAlpha(0.0) end)
  group:SetScript("OnFinished", function() texture:Hide() end)
  return group
end

-- Sanftes Auf und Ab (Pfeil, Symbol): Translation hoch, dann zurück, weich an den Wendepunkten
local function bob(texture, height, half)
  local group = loopingGroup(texture)
  pingPong(group, "Translation", half, function(a, forth)
    a:SetOffset(0, forth and height or -height)
    a:SetSmoothing("IN_OUT")
  end)
  return group
end

function Animations.bob(texture) return bob(texture, 5, 0.7) end
function Animations.bobSmall(texture) return bob(texture, 3, 0.9) end

-- Kurzer Hüpfer bei "ready": schnell hoch, fallend zurück
function Animations.hop(texture)
  local group = texture:CreateAnimationGroup()
  add(group, "Translation", 1, 0.12, function(a) a:SetOffset(0, 12); a:SetSmoothing("OUT") end)
  add(group, "Translation", 2, 0.18, function(a) a:SetOffset(0, -12); a:SetSmoothing("IN") end)
  return group
end

-- Zielsucher schnappt zu: von der weiten Klammergröße (Verhältnis aus def.sizes) kurz über das Ziel hinaus
-- (Überschwingen auf 90 %) und zurück auf 100 %
function Animations.snap(texture, def)
  local group = texture:CreateAnimationGroup()
  local ratio = def.sizes.far[1] / def.sizes.ready[1]
  add(group, "Scale", 1, 0.12, function(a)
    a:SetScaleFrom(ratio, ratio)
    a:SetScaleTo(0.9, 0.9)
    a:SetSmoothing("IN")
  end)
  add(group, "Scale", 2, 0.07, function(a)
    a:SetScaleFrom(1, 1)
    a:SetScaleTo(1 / 0.9, 1 / 0.9)
    a:SetSmoothing("OUT")
  end)
  return group
end

-- Weicher Leuchtrand atmet; Dauer bewusst anders als Wippen und Schatten, damit die Schichten nie im Gleichtakt laufen
function Animations.glowPulse(texture)
  local group = loopingGroup(texture)
  pingPong(group, "Alpha", 0.9, function(a, forth)
    a:SetFromAlpha(forth and 0.35 or 0.7)
    a:SetToAlpha(forth and 0.7 or 0.35)
    a:SetSmoothing("IN_OUT")
  end)
  return group
end

-- Boden unter wippender Form (Schatten, Bodenlicht): kleiner und blasser, wenn die Form oben ist, gleiche Dauer
-- wie bob/bobSmall; hoch/niedrig = Deckkraft unten bzw. oben
local function groundBob(texture, half, low, high)
  local group = loopingGroup(texture)
  pingPong(group, "Alpha", half, function(a, forth)
    a:SetFromAlpha(forth and high or low)
    a:SetToAlpha(forth and low or high)
    a:SetSmoothing("IN_OUT")
  end)
  pingPong(group, "Scale", half, function(a, forth)
    a:SetScaleFrom(forth and 1 or 0.8, forth and 1 or 0.8)
    a:SetScaleTo(forth and 0.8 or 1, forth and 0.8 or 1)
    a:SetSmoothing("IN_OUT")
  end)
  return group
end

function Animations.shadowArrow(texture) return groundBob(texture, 0.7, 0.3, 0.55) end
function Animations.shadowSymbol(texture) return groundBob(texture, 0.9, 0.3, 0.55) end
function Animations.groundArrow(texture) return groundBob(texture, 0.7, 0.18, 0.4) end
function Animations.groundSymbol(texture) return groundBob(texture, 0.9, 0.18, 0.4) end

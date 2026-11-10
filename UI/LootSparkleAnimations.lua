-- Animationen der Glitzer-Schichten (Roadmap 456, 466, 467, 468, 475, 476): je Name eine Funktion(Textur, Schichtdefinition) -> AnimationGroup.
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

-- Bodenstile (Roadmap 467, 468, 476) ---------------------------------------------------------------------------------

-- Folge von Deckkraft-Schritten { von, bis, Dauer, Glättung } in aufeinanderfolgenden Ordnungen; der Rest bis zur
-- Schleifenlänge period wird mit einer Pause (Deckkraft 0 bis 0) aufgefüllt, damit alle Schichten gleich lang laufen
-- und versetzte Starts nie auseinanderdriften.
local function alphaSequence(texture, steps, period)
  local group = loopingGroup(texture)
  local order, total = 0, 0
  for _, step in ipairs(steps) do
    order = order + 1
    total = total + step[3]
    add(group, "Alpha", order, step[3], function(a)
      a:SetFromAlpha(step[1])
      a:SetToAlpha(step[2])
      if step[4] then a:SetSmoothing(step[4]) end
    end)
  end
  if period - total > 0.001 then
    add(group, "Alpha", order + 1, period - total, function(a) a:SetFromAlpha(0); a:SetToAlpha(0) end)
  end
  return group
end

-- Uhrwerk: Der Zeiger kriecht in 16 Stellungen; jede Stellung blendet ein, während die vorige ausblendet
-- (def.index 0 bis 15, eine Stellung dauert HAND_STEP Sekunden). Stellung 0 (12 Uhr) beginnt die Schleife mit dem
-- Ausblenden und endet mit dem Einblenden.
local HAND_COUNT, HAND_STEP = 16, 1.5
function Animations.clockHand(texture, def)
  local k, step = def.index, HAND_STEP
  local steps
  if k == 0 then
    steps = { { 1, 0, step }, { 0, 0, (HAND_COUNT - 2) * step }, { 0, 1, step } }
  else
    steps = {}
    if k > 1 then table.insert(steps, { 0, 0, (k - 1) * step }) end
    table.insert(steps, { 0, 1, step })
    table.insert(steps, { 1, 0, step })
  end
  return alphaSequence(texture, steps, HAND_COUNT * step)
end

-- Zeiger springt auf 12: kleiner Rückschwung mit Überschwingen
function Animations.clockSpring(texture)
  local group = texture:CreateAnimationGroup()
  add(group, "Scale", 1, 0.08, function(a) a:SetScaleFrom(1, 1); a:SetScaleTo(0.82, 0.82); a:SetSmoothing("IN") end)
  add(group, "Scale", 2, 0.1, function(a) a:SetScaleFrom(0.82, 0.82); a:SetScaleTo(1.1, 1.1); a:SetSmoothing("OUT") end)
  add(group, "Scale", 3, 0.14, function(a) a:SetScaleFrom(1.1, 1.1); a:SetScaleTo(1, 1); a:SetSmoothing("IN_OUT") end)
  return group
end

-- Der Ring tickt einmal pro Sekunde: kurz größer, dann zurück
function Animations.clockTick(texture)
  local group = loopingGroup(texture)
  add(group, "Scale", 1, 0.05, function(a) a:SetScaleFrom(1, 1); a:SetScaleTo(1.05, 1.05); a:SetSmoothing("OUT") end)
  add(group, "Scale", 2, 0.2, function(a) a:SetScaleFrom(1.05, 1.05); a:SetScaleTo(1, 1); a:SetSmoothing("IN_OUT") end)
  add(group, "Scale", 3, 0.75, function(a) a:SetScaleFrom(1, 1); a:SetScaleTo(1, 1) end)
  return group
end

-- Leuchtrand im Takt des Tickens (Uhrwerk, Fortschrittsring): dieselbe Dauer wie clockTick
function Animations.clockGlow(texture)
  local group = loopingGroup(texture)
  add(group, "Alpha", 1, 0.05, function(a) a:SetFromAlpha(0.35); a:SetToAlpha(0.8) end)
  add(group, "Alpha", 2, 0.95, function(a) a:SetFromAlpha(0.8); a:SetToAlpha(0.35); a:SetSmoothing("OUT") end)
  return group
end

-- Fortschrittsring, "weit": die ersten FAR_SEGMENTS Segmente füllen sich nacheinander, halten und blenden gemeinsam
-- aus. Die übrigen Segmente bleiben dunkel und füllen sich erst bei "bereit" (es wird kein Abstand gemessen).
local FAR_SEGMENTS, FILL_STEP, FILL_FADE_IN, FILL_HOLD_UNTIL, FILL_FADE_OUT, FILL_PERIOD = 10, 0.16, 0.3, 2.6, 0.6, 4.4
function Animations.segmentFill(texture, def)
  local i = def.index
  if i >= FAR_SEGMENTS then return nil end
  local start = i * FILL_STEP
  local steps = {}
  if start > 0 then table.insert(steps, { 0, 0, start }) end
  table.insert(steps, { 0, 0.9, FILL_FADE_IN, "OUT" })
  table.insert(steps, { 0.9, 0.9, FILL_HOLD_UNTIL - start - FILL_FADE_IN })
  table.insert(steps, { 0.9, 0, FILL_FADE_OUT })
  return alphaSequence(texture, steps, FILL_PERIOD)
end

-- Fortschrittsring voll: eine Welle läuft um den Ring, jedes Segment poppt kurz auf (Level-up-Puls)
function Animations.segmentPop(texture, def)
  local group = texture:CreateAnimationGroup()
  local grow = add(group, "Scale", 1, 0.09, function(a) a:SetScaleFrom(1, 1); a:SetScaleTo(1.14, 1.14); a:SetSmoothing("OUT") end)
  if def.index > 0 then grow:SetStartDelay(def.index * 0.02) end
  add(group, "Scale", 2, 0.2, function(a) a:SetScaleFrom(1.14, 1.14); a:SetScaleTo(1, 1); a:SetSmoothing("IN_OUT") end)
  return group
end

-- Lichtsäule ---------------------------------------------------------------------------------------------------------

-- Atmen zwischen zwei Deckkräften (Säule, Bodenlicht, Zusatzschicht bei "bereit"); half = Dauer einer Richtung
local function breathe(texture, half, low, high)
  local group = loopingGroup(texture)
  pingPong(group, "Alpha", half, function(a, forth)
    a:SetFromAlpha(forth and low or high)
    a:SetToAlpha(forth and high or low)
    a:SetSmoothing("IN_OUT")
  end)
  return group
end

function Animations.pillarPulse(texture) return breathe(texture, 1.3, 0.5, 0.8) end
function Animations.pillarGround(texture) return breathe(texture, 1.3, 0.45, 0.75) end
-- bereit: schnell und hell, die Säule pulsiert
function Animations.pillarSurge(texture) return breathe(texture, 0.45, 0.25, 0.85) end

-- Säule schießt bei "bereit" auf: schmal und blass, kurz breiter als normal, dann zurück
function Animations.surge(texture)
  local group = texture:CreateAnimationGroup()
  add(group, "Scale", 1, 0.1, function(a) a:SetScaleFrom(0.6, 1); a:SetScaleTo(1.35, 1); a:SetSmoothing("OUT") end)
  add(group, "Alpha", 1, 0.1, function(a) a:SetFromAlpha(0.3); a:SetToAlpha(1) end)
  add(group, "Scale", 2, 0.22, function(a) a:SetScaleFrom(1.35, 1); a:SetScaleTo(1, 1); a:SetSmoothing("IN_OUT") end)
  return group
end

-- Flacher Ring steigt an der Säule auf: wabert leicht seitlich, wird schmaler und blendet oben aus. Drei Ringe laufen
-- um def.delay versetzt, die Schleifenlänge RING_PERIOD ist für alle gleich.
local RING_STEP, RING_PERIOD, RING_RISE = 0.6, 4.2, 25
local RING_SCALE = { 1, 0.93, 0.85, 0.78, 0.7 }
local RING_WOBBLE = { 3, -6, 6, -3 }
local RING_ALPHA = { { 0, 0.9 }, { 0.9, 0.8 }, { 0.8, 0.5 }, { 0.5, 0 } }
function Animations.lightRing(texture, def)
  local group = loopingGroup(texture)
  local order = 0
  if def.delay > 0 then
    order = 1
    add(group, "Alpha", order, def.delay, function(a) a:SetFromAlpha(0); a:SetToAlpha(0) end)
  end
  for i = 1, #RING_WOBBLE do
    order = order + 1
    add(group, "Translation", order, RING_STEP, function(a) a:SetOffset(RING_WOBBLE[i], RING_RISE); a:SetSmoothing("NONE") end)
    add(group, "Scale", order, RING_STEP, function(a)
      a:SetScaleFrom(RING_SCALE[i], RING_SCALE[i])
      a:SetScaleTo(RING_SCALE[i + 1], RING_SCALE[i + 1])
    end)
    add(group, "Alpha", order, RING_STEP, function(a) a:SetFromAlpha(RING_ALPHA[i][1]); a:SetToAlpha(RING_ALPHA[i][2]) end)
  end
  local rest = RING_PERIOD - def.delay - RING_STEP * #RING_WOBBLE
  if rest > 0.001 then
    add(group, "Alpha", order + 1, rest, function(a) a:SetFromAlpha(0); a:SetToAlpha(0) end)
  end
  return group
end

-- Lichtpunkt steigt auf: kurz einblenden, langsam nach oben treiben (def.rise Pixel, def.drift seitlich), ausblenden
local MOTE_PERIOD = 3.2
function Animations.mote(texture, def)
  local group = loopingGroup(texture)
  local order = 0
  if def.delay > 0 then
    order = 1
    add(group, "Alpha", order, def.delay, function(a) a:SetFromAlpha(0); a:SetToAlpha(0) end)
  end
  add(group, "Alpha", order + 1, 0.6, function(a) a:SetFromAlpha(0); a:SetToAlpha(0.95) end)
  add(group, "Translation", order + 1, 0.6, function(a) a:SetOffset(def.drift * 0.3, def.rise * 0.3); a:SetSmoothing("NONE") end)
  add(group, "Scale", order + 1, 0.6, function(a) a:SetScaleFrom(0.6, 0.6); a:SetScaleTo(1, 1) end)
  add(group, "Alpha", order + 2, 1.6, function(a) a:SetFromAlpha(0.95); a:SetToAlpha(0) end)
  add(group, "Translation", order + 2, 1.6, function(a) a:SetOffset(def.drift * 0.7, def.rise * 0.7); a:SetSmoothing("NONE") end)
  add(group, "Scale", order + 2, 1.6, function(a) a:SetScaleFrom(1, 1); a:SetScaleTo(0.4, 0.4) end)
  local rest = MOTE_PERIOD - def.delay - 2.2
  if rest > 0.001 then add(group, "Alpha", order + 3, rest, function(a) a:SetFromAlpha(0); a:SetToAlpha(0) end) end
  return group
end

-- Hilfsfunktionen für LootSparkleSceneAnimations.lua (Szenen-Stile, Roadmap 469, 470, 472, 473)
Animations.helpers = { add = add, loopingGroup = loopingGroup, alphaSequence = alphaSequence, breathe = breathe }

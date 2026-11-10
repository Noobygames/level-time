-- Animationen der Szenen-Stile des Beute-Glitzerns (Roadmap 469, 470, 472, 473): Glühwürmchen, Schatzkarte,
-- Pixel-Pop, Sternbild. Wie LootSparkleAnimations.lua: je Name eine Funktion(Textur, Schichtdefinition) ->
-- AnimationGroup, nur Blizzard-AnimationGroups, kein OnUpdate. Die Hilfsfunktionen kommen von dort.
local _, ns = ...

local Animations = ns.LootSparkleAnimations
local H = Animations.helpers
local add, loopingGroup, alphaSequence, breathe = H.add, H.loopingGroup, H.alphaSequence, H.breathe

local function fade(group, order, duration, fn) return add(group, "Alpha", order, duration, fn) end

-- Glühwürmchen -------------------------------------------------------------------------------------------------------

-- Irrflug: def.steps = Liste { dx, dy, Dauer, Deckkraft, Größe }; jedes Stück bewegt sich weich, blendet zur nächsten
-- Deckkraft und Größe (Aufglimmen und Verlöschen). Der letzte Abschnitt (def.closing Sekunden) führt zum Ausgangspunkt
-- zurück und erlischt, die Schleife beginnt also unsichtbar am Anker. Jedes Tier hat andere Dauern: nie im Gleichtakt.
-- def.peak = größte Deckkraft der Schicht (Schatten blasser als der Kern).
function Animations.fireflyWander(texture, def)
  local group = loopingGroup(texture)
  local peak, order = def.peak or 1, 0
  local sumX, sumY, alpha, scale = 0, 0, 0, 0.7
  local function stage(dx, dy, duration, toAlpha, toScale)
    order = order + 1
    add(group, "Translation", order, duration, function(a) a:SetOffset(dx, dy); a:SetSmoothing("IN_OUT") end)
    local fromAlpha, fromScale = alpha, scale
    fade(group, order, duration, function(a)
      a:SetFromAlpha(fromAlpha * peak)
      a:SetToAlpha(toAlpha * peak)
      a:SetSmoothing("IN_OUT")
    end)
    add(group, "Scale", order, duration, function(a) a:SetScaleFrom(fromScale, fromScale); a:SetScaleTo(toScale, toScale) end)
    sumX, sumY, alpha, scale = sumX + dx, sumY + dy, toAlpha, toScale
  end
  for _, step in ipairs(def.steps) do stage(step[1], step[2], step[3], step[4], step[5]) end
  stage(-sumX, -sumY, def.closing, 0, 0.7)
  return group
end

-- Gesammelt (bereit): kleiner Kreisflug um den Anker, ohne Deckkraft-Änderung (die setzt fireflyGather)
function Animations.fireflyOrbit(texture, def)
  local group = loopingGroup(texture)
  local radiusX, radiusY, step = 3 + def.index, 2 + def.index % 2, 0.85 + 0.12 * def.index
  local legs = { { 1, 1 }, { -1, 1 }, { -1, -1 }, { 1, -1 } }
  for order, leg in ipairs(legs) do
    add(group, "Translation", order, step, function(a)
      a:SetOffset(leg[1] * radiusX, leg[2] * radiusY)
      a:SetSmoothing("IN_OUT")
    end)
    local big = order % 2 == 1
    add(group, "Scale", order, step, function(a)
      a:SetScaleFrom(big and 1 or 1.12, big and 1 or 1.12)
      a:SetScaleTo(big and 1.12 or 1, big and 1.12 or 1)
      a:SetSmoothing("IN_OUT")
    end)
  end
  return group
end

-- Bereit: das Tier springt unsichtbar zu seinem alten Ort (def.fromX, def.fromY relativ zum Anker) und fliegt zur
-- Mitte, wird dabei heller und größer und setzt sich mit leichtem Überschwingen
local GATHER_SECONDS = 0.6
function Animations.fireflyGather(texture, def)
  local group = texture:CreateAnimationGroup()
  add(group, "Translation", 1, 0.01, function(a) a:SetOffset(def.fromX, def.fromY) end)
  fade(group, 1, 0.01, function(a) a:SetFromAlpha(0); a:SetToAlpha(0) end)
  add(group, "Translation", 2, GATHER_SECONDS, function(a) a:SetOffset(-def.fromX, -def.fromY); a:SetSmoothing("IN_OUT") end)
  fade(group, 2, GATHER_SECONDS, function(a) a:SetFromAlpha(0); a:SetToAlpha(1); a:SetSmoothing("OUT") end)
  add(group, "Scale", 2, GATHER_SECONDS, function(a) a:SetScaleFrom(0.6, 0.6); a:SetScaleTo(1.35, 1.35); a:SetSmoothing("OUT") end)
  add(group, "Scale", 3, 0.25, function(a) a:SetScaleFrom(1.35, 1.35); a:SetScaleTo(1, 1); a:SetSmoothing("IN_OUT") end)
  return group
end

-- Weiches Atmen eines Zusatzleuchtens (Glühwürmchen-Hof, Pixelstern-Hof, Sternbild-Hof)
function Animations.softPulse(texture, def) return breathe(texture, 1.1, 0.2 * (def.peak or 1), 0.45 * (def.peak or 1)) end

-- Schatzkarte -------------------------------------------------------------------------------------------------------

-- "weit": X-Striche (Zellen 0 bis 3) werden nacheinander gemalt, danach die Pfadstriche (Zellen 4 bis 7); alles
-- hält und blendet gemeinsam aus. Schleifenlänge MAP_PERIOD für alle gleich.
local MAP_PERIOD, MAP_STROKE_STEP, MAP_DASH_START, MAP_DASH_STEP = 5.4, 0.45, 1.9, 0.3
local MAP_FADE_IN, MAP_HOLD_UNTIL, MAP_FADE_OUT, MAP_PEAK = 0.2, 4.4, 0.6, 0.9
local MAP_X_CELLS = 4
function Animations.mapStroke(texture, def)
  local start = def.index < MAP_X_CELLS and def.index * MAP_STROKE_STEP
    or MAP_DASH_START + (def.index - MAP_X_CELLS) * MAP_DASH_STEP
  local steps = {}
  if start > 0 then table.insert(steps, { 0, 0, start }) end
  table.insert(steps, { 0, MAP_PEAK, MAP_FADE_IN, "OUT" })
  table.insert(steps, { MAP_PEAK, MAP_PEAK, MAP_HOLD_UNTIL - start - MAP_FADE_IN })
  table.insert(steps, { MAP_PEAK, 0, MAP_FADE_OUT })
  return alphaSequence(texture, steps, MAP_PERIOD)
end

-- "bereit": der Tintenkreis schließt sich Stück für Stück (def.index 0 bis 7), jedes Stück setzt kurz auf
local INK_STEP, INK_FADE = 0.06, 0.07
function Animations.mapInk(texture, def)
  local group = texture:CreateAnimationGroup()
  local order = 1
  if def.index > 0 then
    fade(group, order, def.index * INK_STEP, function(a) a:SetFromAlpha(0); a:SetToAlpha(0) end)
    order = order + 1
  end
  fade(group, order, INK_FADE, function(a) a:SetFromAlpha(0); a:SetToAlpha(1) end)
  add(group, "Scale", order, 0.14, function(a) a:SetScaleFrom(1.1, 1.1); a:SetScaleTo(1, 1); a:SetSmoothing("OUT") end)
  return group
end

-- Pixel-Pop ---------------------------------------------------------------------------------------------------------

-- Ein Schritt der Pixel-Bewegung: Sprung (kurz, hart) und Halt, wie Einzelbilder eines 8-Bit-Spiels
local FRAME_JUMP, FRAME_HOLD = 0.02, 0.12
local function pixelFrames(group, order, frames, offset)
  for i, fraction in ipairs(frames) do
    order = order + 1
    add(group, "Translation", order, FRAME_JUMP, function(a) a:SetOffset(offset(fraction)); a:SetSmoothing("NONE") end)
    fade(group, order, FRAME_JUMP, function(a) a:SetFromAlpha(i == 1 and 0 or 1); a:SetToAlpha(1) end)
    order = order + 1
    fade(group, order, FRAME_HOLD, function(a) a:SetFromAlpha(1); a:SetToAlpha(1) end)
  end
  return order
end

-- Pixel springt auf und fällt (def.rise Pixel Höhe, def.drift seitlich, def.delay Startversatz), blinkt zum Schluss aus
local POP_FRAMES = { 0.5, 0.3, 0.2, -0.3, -0.5, -0.7 }
local POP_BLINK, POP_PERIOD = 0.05, 2.6
function Animations.pixelPop(texture, def)
  local group = loopingGroup(texture)
  local order, total = 0, 0
  if def.delay > 0 then
    order, total = 1, def.delay
    fade(group, order, def.delay, function(a) a:SetFromAlpha(0); a:SetToAlpha(0) end)
  end
  order = pixelFrames(group, order, POP_FRAMES, function(fraction) return def.drift / #POP_FRAMES, def.rise * fraction end)
  total = total + #POP_FRAMES * (FRAME_JUMP + FRAME_HOLD)
  order = order + 1
  fade(group, order, POP_BLINK, function(a) a:SetFromAlpha(0.5); a:SetToAlpha(0) end)
  total = total + POP_BLINK
  if POP_PERIOD - total > 0.001 then
    fade(group, order + 1, POP_PERIOD - total, function(a) a:SetFromAlpha(0); a:SetToAlpha(0) end)
  end
  return group
end

-- Bereit: Pixel fliegen vom Zentrum nach außen (def.dirX, def.dirY = Ziel), in vier Bildern, und blinken aus
local BURST_FRAMES = { 0.45, 0.3, 0.15, 0.1 }
function Animations.pixelBurst(texture, def)
  local group = texture:CreateAnimationGroup()
  local order = pixelFrames(group, 0, BURST_FRAMES, function(fraction) return def.dirX * fraction, def.dirY * fraction end)
  fade(group, order + 1, POP_BLINK, function(a) a:SetFromAlpha(0.6); a:SetToAlpha(0) end)
  return group
end

-- Marschierende Quadrate am Boden: zwei Hälften blinken im Wechsel (index 0 oder 1), harte Kanten, kein Überblenden
local BLINK_HALF = 0.4
function Animations.pixelBlink(texture, def)
  local on, off = def.index == 0, def.index ~= 0
  local steps = {
    { on and 0.9 or 0, on and 0.9 or 0, BLINK_HALF },
    { off and 0.9 or 0, off and 0.9 or 0, BLINK_HALF },
  }
  return alphaSequence(texture, steps, 2 * BLINK_HALF)
end

-- Pixelstern: springt bei "bereit" in vier harten Stufen auf (klein, groß, kleiner, fertig)
local STAR_POP = { { 0.35, 0.06 }, { 1.3, 0.08 }, { 0.9, 0.06 }, { 1, 0.06 } }
function Animations.pixelStarPop(texture)
  local group = texture:CreateAnimationGroup()
  for order, step in ipairs(STAR_POP) do
    add(group, "Scale", order, step[2], function(a) a:SetScaleFrom(step[1], step[1]); a:SetScaleTo(step[1], step[1]) end)
  end
  return group
end

-- Pixelstern funkelt: kurz größer (harter Sprung), dann wieder normal
function Animations.pixelTwinkle(texture)
  local group = loopingGroup(texture)
  local stages = { { 1, 0.7 }, { 1.14, 0.12 }, { 1, 0.35 } }
  for order, stage in ipairs(stages) do
    add(group, "Scale", order, stage[2], function(a) a:SetScaleFrom(stage[1], stage[1]); a:SetScaleTo(stage[1], stage[1]) end)
  end
  return group
end

-- Sternbild ---------------------------------------------------------------------------------------------------------

-- "weit": Stern oder Linie erscheint zur Zeit def.delay (Sterne mit kleinem Aufploppen, def.pop), hält und blendet mit
-- den anderen aus. def.peak = größte Deckkraft (Schatten blasser). Schleifenlänge SKY_PERIOD für alle gleich.
local SKY_PERIOD, SKY_HOLD_UNTIL, SKY_FADE_IN, SKY_SETTLE, SKY_FADE_OUT = 6.4, 4.8, 0.3, 0.15, 0.8
function Animations.skyReveal(texture, def)
  local group = loopingGroup(texture)
  local peak, pop, order = def.peak or 1, def.pop == true, 0
  local function stage(duration, fromAlpha, toAlpha, fromScale, toScale, smoothing)
    order = order + 1
    fade(group, order, duration, function(a)
      a:SetFromAlpha(fromAlpha)
      a:SetToAlpha(toAlpha)
      if smoothing then a:SetSmoothing(smoothing) end
    end)
    if pop then
      add(group, "Scale", order, duration, function(a)
        a:SetScaleFrom(fromScale, fromScale)
        a:SetScaleTo(toScale, toScale)
        if smoothing then a:SetSmoothing(smoothing) end
      end)
    end
  end
  if def.delay > 0 then stage(def.delay, 0, 0, 1, 1) end
  stage(SKY_FADE_IN, 0, peak, 0.4, 1.25, "OUT")
  if pop then stage(SKY_SETTLE, peak, peak, 1.25, 1) end
  stage(SKY_HOLD_UNTIL - def.delay - SKY_FADE_IN - (pop and SKY_SETTLE or 0), peak, peak, 1, 1)
  stage(SKY_FADE_OUT, peak, 0, 1, 1)
  stage(SKY_PERIOD - SKY_HOLD_UNTIL - SKY_FADE_OUT, 0, 0, 1, 1)
  return group
end

-- Bereit: Stern ploppt kurz auf (schnell groß, dann zurück mit Überschwingen)
function Animations.skyPop(texture)
  local group = texture:CreateAnimationGroup()
  add(group, "Scale", 1, 0.1, function(a) a:SetScaleFrom(1, 1); a:SetScaleTo(1.6, 1.6); a:SetSmoothing("OUT") end)
  add(group, "Scale", 2, 0.12, function(a) a:SetScaleFrom(1.6, 1.6); a:SetScaleTo(0.9, 0.9); a:SetSmoothing("IN_OUT") end)
  add(group, "Scale", 3, 0.1, function(a) a:SetScaleFrom(0.9, 0.9); a:SetScaleTo(1, 1); a:SetSmoothing("IN_OUT") end)
  return group
end

-- Sterne im fertigen Bild funkeln leise, jeder in eigener Dauer (def.half)
function Animations.skyTwinkle(texture, def) return breathe(texture, def.half, 0.1, 0.3) end

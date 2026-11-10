-- Stil- und Schichtdefinitionen des Beute-Glitzerns (Roadmap 456, 466, 467, 468, 471, 474, 475, 476). Reine Daten: LootSparkle.lua
-- baut daraus die Texturen, LootSparkleAnimations.lua liefert die Animationen. Ein neuer Stil = ein Eintrag in
-- STYLES (und ORDER); braucht er eine neue Schicht, ein Eintrag in LAYERS (Texturen aus tools/artwork).
local addonName, ns = ...

local Styles = {}
ns.LootSparkleStyles = Styles

local function media(name)
  return "Interface\\AddOns\\" .. addonName .. "\\Media\\" .. name
end

Styles.TEXTURE = {
  glint = media("Glint"), halo = media("SparkleHalo"), ring = media("SparkleRing"), arcs = media("SparkleArcs"),
  flare = media("SparkleFlare"), beam = media("SparkleBeam"), sigil = media("SparkleSigil"),
  bracket = media("SparkleBracket"), bracketDashed = media("SparkleBracketDashed"), arrow = media("SparkleArrow"),
  symbols = media("SparkleSymbols"), symbolsOutline = media("SparkleSymbolsOutline"),
  bracketOutline = media("SparkleBracketOutline"), bracketCore = media("SparkleBracketCore"),
  arrowOutline = media("SparkleArrowOutline"), trail = media("SparkleTrail"), badge = media("SparkleBadge"), bracketGlow = media("SparkleBracketGlow"), arrowGlow = media("SparkleArrowGlow"),
  clockFace = media("SparkleClockFace"), clockOutline = media("SparkleClockOutline"), clockGlow = media("SparkleClockGlow"),
  clockHands = media("SparkleClockHands"), segments = media("SparkleSegments"), progressTrack = media("SparkleProgressTrack"),
  progressGlow = media("SparkleProgressGlow"), column = media("SparkleColumn"), columnCore = media("SparkleColumnCore"),
  columnShade = media("SparkleColumnShade"), lightRing = media("SparkleLightRing"),
}

-- Gruppen im Auswahlfeld: eigene Formen zuerst, die Glow-Stile aus Roadmap 456 als "Klassisch"
Styles.GROUP_SHAPES, Styles.GROUP_CLASSIC = "shapes", "classic"

Styles.DEFAULT = "finder"

-- layers = aktive Schichten (Namen aus LAYERS), glints = Funkenschwarm, shade = dunkler Bodenschatten (Klassisch)
Styles.STYLES = {
  finder = {
    group = Styles.GROUP_SHAPES, glints = false, shade = false,
    layers = { "shadow", "groundRing", "bracketOutline", "bracketGlow", "bracketBloom", "bracket", "bracketCore", "bracketLocked" },
  },
  arrow = {
    group = Styles.GROUP_SHAPES, glints = false, shade = false,
    layers = { "shadowArrow", "groundArrow", "trail", "arrowOutline", "arrowGlow", "arrow" },
  },
  glitter = { group = Styles.GROUP_SHAPES, layers = { "shadow", "groundRing" }, glints = true, glintRim = true, shade = false },
  symbol = {
    group = Styles.GROUP_SHAPES, glints = false, shade = false,
    layers = { "shadowSymbol", "groundSymbol", "badge", "symbolBloom", "symbolOutline", "symbol" },
  },
  clock = {
    group = Styles.GROUP_SHAPES, glints = false, shade = false,
    layers = { "shadowWide", "clockOutline", "clockGlow", "clockFace", "clockHand1", "clockHand2", "clockHand3", "clockHand4",
      "clockHand5", "clockHand6", "clockHand7", "clockHand8", "clockHand9", "clockHand10", "clockHand11", "clockHand12",
      "clockHand13", "clockHand14", "clockHand15", "clockHand16" },
  },
  progress = {
    group = Styles.GROUP_SHAPES, glints = false, shade = false,
    layers = { "shadowWide", "progressTrack", "progressGlow", "progressSeg1", "progressSeg2", "progressSeg3", "progressSeg4",
      "progressSeg5", "progressSeg6", "progressSeg7", "progressSeg8", "progressSeg9", "progressSeg10", "progressSeg11",
      "progressSeg12", "progressSeg13", "progressSeg14", "progressSeg15", "progressSeg16" },
  },
  pillar = {
    group = Styles.GROUP_SHAPES, glints = false, shade = false,
    layers = { "shadow", "pillarShade", "groundRing", "pillarGround", "pillar", "pillarCore", "pillarSurge", "pillarBloom",
      "pillarRing1", "pillarRing2", "pillarRing3", "pillarMote1", "pillarMote2", "pillarMote3", "pillarMote4", "pillarMote5" },
  },
  aura = { group = Styles.GROUP_CLASSIC, layers = { "arcs", "halo" }, glints = true, shade = true },
  beam = { group = Styles.GROUP_CLASSIC, layers = { "beam", "ring1" }, glints = true, shade = true },
  sigil = { group = Styles.GROUP_CLASSIC, layers = { "arcs", "halo", "sigil" }, glints = true, shade = true },
  ripple = { group = Styles.GROUP_CLASSIC, layers = { "halo", "ring1", "ring2" }, glints = true, shade = true },
  sparkle = { group = Styles.GROUP_CLASSIC, layers = { "halo" }, glints = true, shade = true },
  subtle = { group = Styles.GROUP_CLASSIC, layers = { "halo", "ring1" }, glints = true, shade = true },
}

Styles.ORDER = { "finder", "arrow", "glitter", "symbol", "clock", "progress", "pillar", "aura", "beam", "sigil", "ripple", "sparkle", "subtle" }

-- Schichten in Zeichenreihenfolge. name, texture, size {Breite, Höhe}, point {Anker, x, y, Bezugsanker} (Standard
-- CENTER, 0, 0, CENTER), sublevel, blend (Standard ADD), animation (Name aus LootSparkleAnimations, läuft in Schleife),
-- freezeLocked (Animation steht im Zustand "locked"), states (nur in diesen Zuständen sichtbar, sonst immer),
-- sizes (Größe je Zustand statt size), readyAnimation (einmalig beim Wechsel auf "ready"), flash (Sonderschicht
-- für den Aufblitz-Impuls, gehört zu keinem Stil), color (feste Farbe statt Kategoriefarbe, z. B. Schatten schwarz),
-- whiten (Anteil 0 bis 1, zu dem die Kategoriefarbe zu Weiß aufgehellt wird: heller Kern), alpha (Grunddeckkraft),
-- atlas (Symbol-Atlas: Ausschnitt nach Kategorie), cell (Zelle i ab 0 in einem 4 x 4 Atlas, fester Ausschnitt),
-- stateAlpha (Grunddeckkraft je Zustand), animStates (die Dauer-Animation läuft nur in diesen Zuständen),
-- index/delay/drift/rise (Parameter für die Animationsfabrik, z. B. Zeigerstellung, Startversatz).
-- Aufbau eines Stils für die Welt (Tiefe und Kontrast auch auf Schnee, Sand und in der Nacht), von unten nach oben:
-- flacher Kontaktschatten und Bodenring am Fuß des Ziels (in der Höhe auf etwa 0.35 gestaucht, wie eine Ellipse auf
-- dem Boden), dunkler weicher Umriss (BLEND), Leuchtrand (ADD), Körper mit Licht und Schatten in der Textur (BLEND,
-- eingefärbt), heller Kern (ADD). Aufrechte Elemente (Pfeil, Symbol, Funken) stehen über dem Boden.
local DARK = { 0, 0, 0 }
local FOOT = { "CENTER", 0, -24, "CENTER" }
local GROUND = { "CENTER", 0, -20, "CENTER" }
local ARROW_POINT = { "BOTTOM", 0, 22, "CENTER" }
local TRAIL_POINT = { "BOTTOM", 0, 62, "CENTER" }
local SYMBOL_POINT = { "CENTER", 0, 47, "CENTER" }
local BRACKET_SIZES = { far = { 84, 84 }, ready = { 56, 56 } }
-- Leuchtrand-Texturen tragen die Form nur auf diesem Anteil (tools/artwork glowShapeScale), damit der Auslauf vor dem
-- Texturrand bei 0 ist; die Schicht ist deshalb entsprechend größer als der Körper
Styles.GLOW_SCALE = 0.5
local function glowSized(size) return { size[1] / Styles.GLOW_SCALE, size[2] / Styles.GLOW_SCALE } end
local GLOW_SIZES = { far = glowSized(BRACKET_SIZES.far), ready = glowSized(BRACKET_SIZES.ready) }
local ARROW_SIZE, SYMBOL_SIZE = { 44, 44 }, { 50, 50 }
local ARROW_GLOW_SIZE = glowSized(ARROW_SIZE)
-- Bodenstile (Roadmap 467, 468, 476): Kreise liegen als Ellipse (Höhe 0.4 der Breite) am Fuß des Ziels
local GROUND_ELLIPSE = { 100, 40 }
local HAND_COUNT, SEGMENT_COUNT = 16, 16
local COLUMN_POINT = { "BOTTOM", 0, -26, "CENTER" }
local MOTES = { { x = -10, delay = 0, rise = 96, drift = 6 }, { x = 9, delay = 0.6, rise = 108, drift = -7 },
  { x = -3, delay = 1.2, rise = 90, drift = 4 }, { x = 13, delay = 1.8, rise = 100, drift = -5 }, { x = -14, delay = 2.4, rise = 104, drift = 8 } }
local GROUND_LAYERS = {}
-- Zeiger: 16 Stellungen im Atlas; Stellung 1 (12 Uhr) bleibt bei "bereit" und "gesperrt" stehen, die übrigen
-- blenden nur im Zustand "weit" nacheinander über (der Zeiger kriecht)
for i = 1, HAND_COUNT do
  local first = i == 1
  table.insert(GROUND_LAYERS, { name = "clockHand" .. i, texture = Styles.TEXTURE.clockHands, blend = "BLEND", size = GROUND_ELLIPSE,
    point = FOOT, sublevel = 4, whiten = 0.4, alpha = 0, cell = i - 1, index = i - 1,
    states = first and { far = true, ready = true, locked = true } or { far = true },
    stateAlpha = first and { far = 0, ready = 1, locked = 1 } or nil,
    animation = "clockHand", animStates = { far = true }, freezeLocked = true, readyAnimation = first and "clockSpring" or nil })
end
-- Fortschrittsring: 16 Segmente; "weit" füllt die ersten zehn wiederholt, "bereit" ist der Ring voll und pulst
for i = 1, SEGMENT_COUNT do
  table.insert(GROUND_LAYERS, { name = "progressSeg" .. i, texture = Styles.TEXTURE.segments, blend = "BLEND", size = GROUND_ELLIPSE,
    point = FOOT, sublevel = 3, whiten = 0.15, alpha = 0, cell = i - 1, index = i - 1,
    stateAlpha = { far = 0, ready = 1, locked = 0.35 }, animation = "segmentFill", animStates = { far = true },
    readyAnimation = "segmentPop" })
end
for i, delay in ipairs({ 0, 0.9, 1.8 }) do
  table.insert(GROUND_LAYERS, { name = "pillarRing" .. i, texture = Styles.TEXTURE.lightRing, size = { 58, 23 }, point = FOOT,
    sublevel = 3, whiten = 0.3, alpha = 0, index = i, delay = delay, animation = "lightRing", freezeLocked = true })
end
for i, mote in ipairs(MOTES) do
  local size = 8 + (i % 3) * 2
  table.insert(GROUND_LAYERS, { name = "pillarMote" .. i, texture = Styles.TEXTURE.flare, size = { size, size },
    point = { "CENTER", mote.x, -22, "CENTER" }, sublevel = 4, whiten = 0.5, alpha = 0, delay = mote.delay, rise = mote.rise,
    drift = mote.drift, animation = "mote", freezeLocked = true })
end

Styles.LAYERS = {
  { name = "shadow", texture = Styles.TEXTURE.halo, blend = "BLEND", size = { 72, 26 }, point = FOOT, sublevel = 0,
    color = DARK, alpha = 0.55 },
  { name = "shadowArrow", texture = Styles.TEXTURE.halo, blend = "BLEND", size = { 72, 26 }, point = FOOT, sublevel = 0,
    color = DARK, alpha = 0.55, animation = "shadowArrow", freezeLocked = true },
  { name = "shadowSymbol", texture = Styles.TEXTURE.halo, blend = "BLEND", size = { 72, 26 }, point = FOOT, sublevel = 0,
    color = DARK, alpha = 0.55, animation = "shadowSymbol", freezeLocked = true },
  { name = "groundRing", texture = Styles.TEXTURE.ring, size = { 76, 28 }, point = FOOT, sublevel = 1, whiten = 0.3, alpha = 0.45 },
  -- weiches Bodenlicht unter Pfeil und Symbol: wird kleiner und blasser, wenn die Form oben ist
  { name = "groundArrow", texture = Styles.TEXTURE.halo, size = { 60, 22 }, point = GROUND, sublevel = 1, whiten = 0.2, alpha = 0.4,
    animation = "groundArrow", freezeLocked = true },
  { name = "groundSymbol", texture = Styles.TEXTURE.halo, size = { 60, 22 }, point = GROUND, sublevel = 1, whiten = 0.2, alpha = 0.4,
    animation = "groundSymbol", freezeLocked = true },
  { name = "halo", texture = Styles.TEXTURE.halo, size = { 96, 96 }, sublevel = 1, animation = "halo" },
  { name = "ring1", texture = Styles.TEXTURE.ring, size = { 80, 32 }, sublevel = 2, animation = "ring" },
  { name = "ring2", texture = Styles.TEXTURE.ring, size = { 80, 32 }, sublevel = 2, animation = "ringLate", freezeLocked = true },
  { name = "arcs", texture = Styles.TEXTURE.arcs, size = { 84, 84 }, sublevel = 3, animation = "arcs", freezeLocked = true },
  { name = "beam", texture = Styles.TEXTURE.beam, size = { 48, 120 }, point = { "BOTTOM", 0, -8, "CENTER" }, sublevel = 4,
    animation = "beam" },
  { name = "sigil", texture = Styles.TEXTURE.sigil, size = { 88, 88 }, sublevel = 3, animation = "sigil", freezeLocked = true },
  -- Zielsucher: weit = offen (große Klammern), bereit = zugeschnappt (mit Überschwingen) und leuchtend,
  -- gesperrt = grau gestrichelt
  { name = "bracketOutline", texture = Styles.TEXTURE.bracketOutline, blend = "BLEND", sublevel = 2, states = { far = true, ready = true },
    sizes = BRACKET_SIZES, size = BRACKET_SIZES.ready, color = DARK, alpha = 0.9, readyAnimation = "snap" },
  { name = "bracketGlow", texture = Styles.TEXTURE.bracketGlow, sublevel = 2, states = { far = true, ready = true },
    sizes = GLOW_SIZES, size = GLOW_SIZES.ready, alpha = 0.35, animation = "glowPulse", readyAnimation = "snap" },
  { name = "bracketBloom", texture = Styles.TEXTURE.halo, sublevel = 2, states = { ready = true }, size = { 110, 110 },
    alpha = 0.18, animation = "glowPulse" },
  { name = "bracket", texture = Styles.TEXTURE.bracket, blend = "BLEND", sublevel = 3, states = { far = true, ready = true },
    sizes = BRACKET_SIZES, size = BRACKET_SIZES.ready, whiten = 0.2, readyAnimation = "snap" },
  { name = "bracketCore", texture = Styles.TEXTURE.bracketCore, sublevel = 4, states = { far = true, ready = true },
    sizes = BRACKET_SIZES, size = BRACKET_SIZES.ready, whiten = 0.75, alpha = 0.6, readyAnimation = "snap" },
  { name = "bracketLocked", texture = Styles.TEXTURE.bracketDashed, blend = "BLEND", sublevel = 3, states = { locked = true },
    size = { 56, 56 } },
  -- Pfeil: Kristall mit Lichtspur nach oben, wippt; Umriss und Leuchten wippen mit
  { name = "trail", texture = Styles.TEXTURE.trail, size = { 20, 56 }, point = TRAIL_POINT, sublevel = 1, whiten = 0.3, alpha = 0.85,
    animation = "bob", freezeLocked = true, readyAnimation = "hop" },
  { name = "arrowOutline", texture = Styles.TEXTURE.arrowOutline, blend = "BLEND", size = ARROW_SIZE, point = ARROW_POINT, sublevel = 2,
    color = DARK, alpha = 0.9, animation = "bob", freezeLocked = true, readyAnimation = "hop" },
  { name = "arrowGlow", texture = Styles.TEXTURE.arrowGlow, size = ARROW_GLOW_SIZE, point = { "CENTER", 0, 44, "CENTER" }, sublevel = 2, alpha = 0.8,
    animation = "bob", freezeLocked = true, readyAnimation = "hop" },
  { name = "arrow", texture = Styles.TEXTURE.arrow, blend = "BLEND", size = ARROW_SIZE, point = ARROW_POINT, sublevel = 3,
    whiten = 0.15, animation = "bob", freezeLocked = true, readyAnimation = "hop" },
  -- Symbol: gefülltes Kategorie-Symbol auf dunkler Scheibe über dem Ziel
  { name = "badge", texture = Styles.TEXTURE.badge, blend = "BLEND", size = { 60, 60 }, point = SYMBOL_POINT, sublevel = 1,
    color = DARK, alpha = 0.5, animation = "bobSmall", freezeLocked = true, readyAnimation = "hop" },
  { name = "symbolBloom", texture = Styles.TEXTURE.halo, size = { 66, 66 }, point = SYMBOL_POINT, sublevel = 2, alpha = 0.45,
    animation = "bobSmall", freezeLocked = true, readyAnimation = "hop" },
  { name = "symbolOutline", texture = Styles.TEXTURE.symbolsOutline, blend = "BLEND", size = { 54, 54 }, point = SYMBOL_POINT,
    sublevel = 3, color = DARK, alpha = 0.9, atlas = true, animation = "bobSmall", freezeLocked = true, readyAnimation = "hop" },
  { name = "symbol", texture = Styles.TEXTURE.symbols, blend = "BLEND", size = SYMBOL_SIZE, point = SYMBOL_POINT, sublevel = 4,
    whiten = 0.3, atlas = true, animation = "bobSmall", freezeLocked = true, readyAnimation = "hop" },
  { name = "shadowWide", texture = Styles.TEXTURE.halo, blend = "BLEND", size = { 112, 44 }, point = FOOT, sublevel = 0,
    color = DARK, alpha = 0.5 },
  -- Uhrwerk: Zifferblatt am Boden, bereit = tickt (Zeiger und Segmente entstehen in GROUND_LAYERS)
  { name = "clockOutline", texture = Styles.TEXTURE.clockOutline, blend = "BLEND", size = GROUND_ELLIPSE, point = FOOT, sublevel = 2,
    color = DARK, alpha = 0.9, animation = "clockTick", animStates = { ready = true } },
  { name = "clockGlow", texture = Styles.TEXTURE.clockGlow, size = glowSized(GROUND_ELLIPSE), point = FOOT, sublevel = 2, alpha = 0.35,
    animation = "clockGlow", freezeLocked = true },
  { name = "clockFace", texture = Styles.TEXTURE.clockFace, blend = "BLEND", size = GROUND_ELLIPSE, point = FOOT, sublevel = 3,
    whiten = 0.2, animation = "clockTick", animStates = { ready = true } },
  -- Fortschrittsring: leere Leiste als dunkle Spur, Segmente füllen sich
  { name = "progressTrack", texture = Styles.TEXTURE.progressTrack, blend = "BLEND", size = GROUND_ELLIPSE, point = FOOT, sublevel = 2,
    color = DARK, alpha = 0.85 },
  { name = "progressGlow", texture = Styles.TEXTURE.progressGlow, size = glowSized(GROUND_ELLIPSE), point = FOOT, sublevel = 2,
    states = { ready = true }, alpha = 0.5, animation = "clockGlow" },
  -- Lichtsäule: warme Säule vom Himmel auf das Ziel mit Bodenkreis, Lichtringen und aufsteigenden Lichtpunkten
  { name = "pillarShade", texture = Styles.TEXTURE.columnShade, blend = "BLEND", size = { 66, 132 }, point = COLUMN_POINT, sublevel = 1,
    color = DARK, alpha = 0.4 },
  { name = "pillarGround", texture = Styles.TEXTURE.halo, size = { 70, 26 }, point = FOOT, sublevel = 2, whiten = 0.2, alpha = 0.6,
    animation = "pillarGround", freezeLocked = true },
  { name = "pillar", texture = Styles.TEXTURE.column, size = { 64, 128 }, point = COLUMN_POINT, sublevel = 2, alpha = 0.55,
    animation = "pillarPulse", freezeLocked = true, readyAnimation = "surge" },
  { name = "pillarCore", texture = Styles.TEXTURE.columnCore, size = { 40, 124 }, point = COLUMN_POINT, sublevel = 3, whiten = 0.6,
    alpha = 0.8, animation = "pillarPulse", freezeLocked = true, readyAnimation = "surge" },
  { name = "pillarSurge", texture = Styles.TEXTURE.column, size = { 96, 150 }, point = COLUMN_POINT, sublevel = 2, states = { ready = true },
    alpha = 0.5, animation = "pillarSurge", readyAnimation = "surge" },
  { name = "pillarBloom", texture = Styles.TEXTURE.halo, size = { 100, 38 }, point = FOOT, sublevel = 3, whiten = 0.5, states = { ready = true },
    alpha = 0.7, animation = "pillarSurge" },
  { name = "flash", texture = Styles.TEXTURE.flare, layer = "OVERLAY", size = { 72, 72 }, sublevel = 5, animation = "flash", flash = true },
}

-- erzeugte Schichten (Zeiger, Segmente, Ringe, Lichtpunkte) vor dem Aufblitz-Impuls einreihen
for _, def in ipairs(GROUND_LAYERS) do table.insert(Styles.LAYERS, #Styles.LAYERS, def) end

-- Schichtdefinition nach Name
Styles.LAYERS_BY_NAME = {}
for _, def in ipairs(Styles.LAYERS) do Styles.LAYERS_BY_NAME[def.name] = def end

-- Texturkoordinaten (links, rechts, oben, unten) der Zelle i (ab 0) in einem Atlas mit 4 x 4 Zellen
function Styles.CellCoords(i)
  local column, row = i % 4, math.floor(i / 4)
  return column / 4, (column + 1) / 4, row / 4, (row + 1) / 4
end

-- Zelle im Symbol-Atlas (4 x 2, zeilenweise von links oben) je Kategorie
Styles.SYMBOL_CELLS = { ore = 1, herb = 2, quest = 3, chest = 4, bobber = 5, corpse = 6 }
local SYMBOL_COLUMNS, SYMBOL_ROWS = 4, 2

-- Texturkoordinaten (links, rechts, oben, unten) des Symbols einer Kategorie; unbekannte Kategorie = Quest-Schriftrolle
function Styles.SymbolCoords(kind)
  local cell = (Styles.SYMBOL_CELLS[kind] or Styles.SYMBOL_CELLS.quest) - 1
  local column, row = cell % SYMBOL_COLUMNS, math.floor(cell / SYMBOL_COLUMNS)
  return column / SYMBOL_COLUMNS, (column + 1) / SYMBOL_COLUMNS, row / SYMBOL_ROWS, (row + 1) / SYMBOL_ROWS
end

function Styles.Get(style)
  return Styles.STYLES[style]
end

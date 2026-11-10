-- Stil- und Schichtdefinitionen des Beute-Glitzerns (Roadmap 456, 466, 471, 474, 475). Reine Daten: LootSparkle.lua
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
  symbols = media("SparkleSymbols"), bracketGlow = media("SparkleBracketGlow"), arrowGlow = media("SparkleArrowGlow"),
}

-- Gruppen im Auswahlfeld: eigene Formen zuerst, die Glow-Stile aus Roadmap 456 als "Klassisch"
Styles.GROUP_SHAPES, Styles.GROUP_CLASSIC = "shapes", "classic"

Styles.DEFAULT = "finder"

-- layers = aktive Schichten (Namen aus LAYERS), glints = Funkenschwarm, shade = dunkler Bodenschatten (Klassisch)
Styles.STYLES = {
  finder = {
    group = Styles.GROUP_SHAPES, glints = false, shade = false,
    layers = { "shadow", "bracketShade", "bracketGlow", "bracket", "bracketLocked" },
  },
  arrow = {
    group = Styles.GROUP_SHAPES, glints = false, shade = false,
    layers = { "shadowArrow", "arrowShade", "arrowGlow", "arrow" },
  },
  glitter = { group = Styles.GROUP_SHAPES, layers = { "shadow" }, glints = true, shade = false },
  symbol = {
    group = Styles.GROUP_SHAPES, glints = false, shade = false,
    layers = { "shadowSymbol", "symbolShade", "symbolBloom", "symbol" },
  },
  aura = { group = Styles.GROUP_CLASSIC, layers = { "arcs", "halo" }, glints = true, shade = true },
  beam = { group = Styles.GROUP_CLASSIC, layers = { "beam", "ring1" }, glints = true, shade = true },
  sigil = { group = Styles.GROUP_CLASSIC, layers = { "arcs", "halo", "sigil" }, glints = true, shade = true },
  ripple = { group = Styles.GROUP_CLASSIC, layers = { "halo", "ring1", "ring2" }, glints = true, shade = true },
  sparkle = { group = Styles.GROUP_CLASSIC, layers = { "halo" }, glints = true, shade = true },
  subtle = { group = Styles.GROUP_CLASSIC, layers = { "halo", "ring1" }, glints = true, shade = true },
}

Styles.ORDER = { "finder", "arrow", "glitter", "symbol", "aura", "beam", "sigil", "ripple", "sparkle", "subtle" }

-- Schichten in Zeichenreihenfolge. name, texture, size {Breite, Höhe}, point {Anker, x, y, Bezugsanker} (Standard
-- CENTER, 0, 0, CENTER), sublevel, blend (Standard ADD), animation (Name aus LootSparkleAnimations, läuft in Schleife),
-- freezeLocked (Animation steht im Zustand "locked"), states (nur in diesen Zuständen sichtbar, sonst immer),
-- sizes (Größe je Zustand statt size), readyAnimation (einmalig beim Wechsel auf "ready"), flash (Sonderschicht
-- für den Aufblitz-Impuls, gehört zu keinem Stil), color (feste Farbe statt Kategoriefarbe, z. B. Schatten schwarz),
-- whiten (Anteil 0 bis 1, zu dem die Kategoriefarbe zu Weiß aufgehellt wird: heißer Kern), alpha (Grunddeckkraft).
-- Aufbau eines Stils für die Welt (Tiefe und Kontrast auch auf Schnee und Sand): flacher dunkler Kontaktschatten am
-- Boden (BLEND, Höhe etwa 0.4 der Breite wie eine Ellipse auf dem Boden), darüber ein dunkler weicher Rand um die Form
-- (BLEND), ein weicher Leuchtrand (ADD) und der scharfe, zum Weiß aufgehellte Körper. Aufrechte Elemente (Pfeil,
-- Symbol, Funken) stehen über dem Schatten; was auf dem Boden liegt (Ringe, Schatten) ist in der Höhe gestaucht.
local DARK = { 0, 0, 0 }
local ABOVE = { "BOTTOM", 0, 26, "CENTER" }
local SYMBOL_CENTER = { "CENTER", 0, 43, "CENTER" }
local SHADOW_POINT = { "CENTER", 0, -10, "CENTER" }
local BRACKET_SIZES = { far = { 84, 84 }, ready = { 56, 56 } }
Styles.LAYERS = {
  { name = "shadow", texture = Styles.TEXTURE.halo, blend = "BLEND", size = { 64, 24 }, point = SHADOW_POINT, sublevel = 0,
    color = DARK, alpha = 0.4 },
  { name = "shadowArrow", texture = Styles.TEXTURE.halo, blend = "BLEND", size = { 64, 24 }, point = SHADOW_POINT, sublevel = 0,
    color = DARK, alpha = 0.4, animation = "shadowArrow", freezeLocked = true },
  { name = "shadowSymbol", texture = Styles.TEXTURE.halo, blend = "BLEND", size = { 56, 20 }, point = SHADOW_POINT, sublevel = 0,
    color = DARK, alpha = 0.4, animation = "shadowSymbol", freezeLocked = true },
  { name = "halo", texture = Styles.TEXTURE.halo, size = { 96, 96 }, sublevel = 1, animation = "halo" },
  { name = "ring1", texture = Styles.TEXTURE.ring, size = { 80, 32 }, sublevel = 2, animation = "ring" },
  { name = "ring2", texture = Styles.TEXTURE.ring, size = { 80, 32 }, sublevel = 2, animation = "ringLate", freezeLocked = true },
  { name = "arcs", texture = Styles.TEXTURE.arcs, size = { 84, 84 }, sublevel = 3, animation = "arcs", freezeLocked = true },
  { name = "beam", texture = Styles.TEXTURE.beam, size = { 48, 120 }, point = { "BOTTOM", 0, -8, "CENTER" }, sublevel = 4,
    animation = "beam" },
  { name = "sigil", texture = Styles.TEXTURE.sigil, size = { 88, 88 }, sublevel = 3, animation = "sigil", freezeLocked = true },
  -- Zielsucher: weit = offen (große Klammern), bereit = zugeschnappt (mit Überschwingen), gesperrt = grau gestrichelt
  { name = "bracketShade", texture = Styles.TEXTURE.bracketGlow, blend = "BLEND", sublevel = 1, states = { far = true, ready = true },
    sizes = BRACKET_SIZES, size = BRACKET_SIZES.ready, color = DARK, alpha = 0.4, readyAnimation = "snap" },
  { name = "bracketGlow", texture = Styles.TEXTURE.bracketGlow, sublevel = 2, states = { far = true, ready = true },
    sizes = BRACKET_SIZES, size = BRACKET_SIZES.ready, alpha = 0.6, animation = "glowPulse", readyAnimation = "snap" },
  { name = "bracket", texture = Styles.TEXTURE.bracket, blend = "BLEND", sublevel = 3, states = { far = true, ready = true },
    sizes = BRACKET_SIZES, size = BRACKET_SIZES.ready, whiten = 0.25, readyAnimation = "snap" },
  { name = "bracketLocked", texture = Styles.TEXTURE.bracketDashed, blend = "BLEND", sublevel = 3, states = { locked = true },
    size = { 56, 56 } },
  -- Pfeil: schwebt über dem Ziel, Rand und Leuchten wippen mit
  { name = "arrowShade", texture = Styles.TEXTURE.arrowGlow, blend = "BLEND", size = { 28, 28 }, point = ABOVE, sublevel = 1,
    color = DARK, alpha = 0.4, animation = "bob", freezeLocked = true, readyAnimation = "hop" },
  { name = "arrowGlow", texture = Styles.TEXTURE.arrowGlow, size = { 28, 28 }, point = ABOVE, sublevel = 2, alpha = 0.6,
    animation = "bob", freezeLocked = true, readyAnimation = "hop" },
  { name = "arrow", texture = Styles.TEXTURE.arrow, blend = "BLEND", size = { 28, 28 }, point = ABOVE, sublevel = 3,
    whiten = 0.2, animation = "bob", freezeLocked = true, readyAnimation = "hop" },
  -- Symbol: Kategorie-Symbol über dem Ziel
  { name = "symbolShade", texture = Styles.TEXTURE.halo, blend = "BLEND", size = { 46, 46 }, point = SYMBOL_CENTER, sublevel = 1,
    color = DARK, alpha = 0.35, animation = "bobSmall", freezeLocked = true, readyAnimation = "hop" },
  { name = "symbolBloom", texture = Styles.TEXTURE.halo, size = { 50, 50 }, point = SYMBOL_CENTER, sublevel = 2, alpha = 0.45,
    animation = "bobSmall", freezeLocked = true, readyAnimation = "hop" },
  { name = "symbol", texture = Styles.TEXTURE.symbols, blend = "BLEND", size = { 34, 34 }, point = ABOVE, sublevel = 3,
    whiten = 0.2, animation = "bobSmall", freezeLocked = true, readyAnimation = "hop" },
  { name = "flash", texture = Styles.TEXTURE.flare, layer = "OVERLAY", size = { 72, 72 }, sublevel = 5, animation = "flash", flash = true },
}

-- Schichtdefinition nach Name
Styles.LAYERS_BY_NAME = {}
for _, def in ipairs(Styles.LAYERS) do Styles.LAYERS_BY_NAME[def.name] = def end

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

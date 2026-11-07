-- Aussehen aller eigenen Anzeigen an einer Stelle: semantische Farben (Theme.COLORS), Abstände (Theme.SPACE),
-- eigene Schriften je Rolle (Theme.Font) und Rahmenstile (Theme.ApplyPanel, Theme.ApplyCard).
-- Einstellungen: theme (Preset aus Theme.PRESETS), themeAccent (Akzentfarbe, "" = die des Presets), themeFont
-- (Schriftart, "" = Schrift des Clients; Liste aus Blizzard-Schriften und, falls ein anderes Addon LibSharedMedia
-- geladen hat, dessen Schriften), themeFontSize (Versatz in Punkten), themeOutline (none/outline/thick).
-- Farben sind Tabellen, die beim Anwenden an Ort und Stelle überschrieben werden: wer sich eine Farbe merkt
-- (local COLOR = Theme.COLORS.good), sieht nach einem Preset-Wechsel beim nächsten Zeichnen die neue.
-- Lädt vor allen UI-Modulen; sein Apply läuft daher vor ihren (Schriften und Farben stehen, wenn sie messen).
local addonName, ns = ...

local Theme = {}
ns.Theme = Theme

Theme.SPACE = { xs = 2, s = 4, m = 8, l = 12, xl = 16, xxl = 20 }

-- Farben des Standard-Looks ("classic"); die Werte entsprechen den früher je Datei eingetragenen
local CLASSIC_COLORS = {
  background = { 0.04, 0.05, 0.1 },  -- Fenster (Panels)
  surface = { 0.03, 0.04, 0.08 },    -- Karten, Level-Up-Fenster
  border = { 0.72, 0.53, 0.17 },
  accent = { 0.96, 0.79, 0.36 },     -- Zeit, XP-Balken, aktiver Reiter, Tooltip-Titel
  gold = { 1, 0.82, 0 },             -- Level-Up, laufender Countdown
  text = { 1, 1, 1 },
  muted = { 0.72, 0.72, 0.72 },      -- Hinweise: lesbar, aber leiser als normaler Text
  inactive = { 0.55, 0.55, 0.55 },   -- nicht gewählter Reiter
  good = { 64 / 255, 1, 64 / 255 },  -- schneller, im Rahmen, Level-Up erreichbar (Texte)
  bad = { 1, 64 / 255, 64 / 255 },   -- langsamer, Tode, über dem Limit
  neutral = { 1, 208 / 255, 64 / 255 },  -- gleichauf (Toleranzband), knapp am Limit
  best = { 192 / 255, 112 / 255, 1 },    -- Gold-Split (neue Bestzeit, lila wie bei Sprint)
  goodOnChroma = { 77 / 255, 210 / 255, 1 },  -- "schneller" auf grünem Chroma-Grund (OBS stanzt Grün aus)
  goodLosing = { 0.6, 0.9, 0.6 },    -- vorn, das laufende Level verliert aber Zeit (LiveSplit "ahead, losing")
  badGaining = { 1, 0.62, 0.55 },    -- hinten, das laufende Level holt aber auf (LiveSplit "behind, gaining")
  success = { 0.35, 1, 0.45 },       -- fertig/erreicht (Karten)
  info = { 0.55, 0.8, 1 },           -- Hinweise, Flüge
  warning = { 1, 0.6, 0.2 },
  chromaGreen = { 0, 1, 0 },
  -- Buttons (Widgets.CreateButton): Grund je Zustand, Rand, Text deaktiviert
  buttonFace = { 0.11, 0.12, 0.2 },
  buttonFaceHover = { 0.18, 0.19, 0.3 },
  buttonFacePressed = { 0.06, 0.07, 0.12 },
  buttonFaceDisabled = { 0.08, 0.08, 0.1 },
  buttonBorder = { 0.5, 0.38, 0.14 },
  buttonBorderDisabled = { 0.3, 0.3, 0.3 },
  buttonTextDisabled = { 0.5, 0.5, 0.5 },
  chromaMagenta = { 1, 0, 1 },
}

-- Rahmenstile: tooltip = Blizzards Tooltip-Grund mit goldenem Rand, flat = einfarbig mit 1-px-Rand (nur
-- SetColorTexture), none = nur Grund
Theme.BORDER_TOOLTIP, Theme.BORDER_FLAT, Theme.BORDER_NONE = "tooltip", "flat", "none"

-- Presets: abweichende Farben, Rahmen der Fenster (panelBorder) und Karten (cardBorder), Deckkraft-Faktor der
-- Fenster (panelAlpha, mal der eingestellten Deckkraft) und Deckkraft der Karten (cardAlpha)
Theme.DEFAULT = "classic"
Theme.ORDER = { "classic", "flat", "minimal", "colorblind" }
Theme.PRESETS = {
  classic = { panelBorder = "tooltip", cardBorder = "none", panelAlpha = 1, cardAlpha = 0.82, colors = {} },
  flat = {
    panelBorder = "flat", cardBorder = "flat", panelAlpha = 1, cardAlpha = 0.9,
    colors = { background = { 0.06, 0.06, 0.08 }, surface = { 0.06, 0.06, 0.08 }, border = { 0.22, 0.22, 0.27 } },
  },
  minimal = { panelBorder = "none", cardBorder = "none", panelAlpha = 0.5, cardAlpha = 0.45, colors = {} },
  -- Farbsehschwäche: Blau statt Grün, Orange statt Rot
  colorblind = {
    panelBorder = "tooltip", cardBorder = "none", panelAlpha = 1, cardAlpha = 0.82,
    colors = {
      good = { 0.3, 0.65, 1 }, success = { 0.3, 0.65, 1 }, goodOnChroma = { 0.3, 0.65, 1 },
      bad = { 1, 0.55, 0.1 }, neutral = { 0.95, 0.95, 0.95 },
      goodLosing = { 0.62, 0.8, 1 }, badGaining = { 1, 0.8, 0.5 },  -- hell statt Rot-Grün-Abstufung
    },
  },
}

-- Akzentfarben (themeAccent); "class" = Klassenfarbe des Charakters
Theme.ACCENT_ORDER = { "", "blue", "green", "purple", "class" }
Theme.ACCENTS = {
  blue = { 0.35, 0.65, 1 },
  green = { 0.4, 0.9, 0.4 },
  purple = { 0.7, 0.45, 1 },
}

-- Kontur (themeOutline) -> Flags von FontInstance:SetFont ("" = ohne; Flags sind seit 10.0 Pflicht, daher nie nil)
Theme.OUTLINE_ORDER = { "none", "outline", "thick" }
local OUTLINE_FLAGS = { none = "", outline = "OUTLINE", thick = "THICKOUTLINE" }

Theme.MIN_FONT_OFFSET, Theme.MAX_FONT_OFFSET = -4, 8
local MIN_FONT_SIZE = 6

-- Schriften, die es in allen Clients gibt (Namen wie bei LibSharedMedia, damit beide Listen zusammenpassen).
-- Lokalisierte Clients (z.B. ruRU) haben eigene Standardschriften: "" bleibt bei der Schrift des Clients.
local BUILTIN_FONTS = {
  { name = "Friz Quadrata TT", path = "Fonts\\FRIZQT__.TTF" },
  { name = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
  { name = "Skurri", path = "Fonts\\skurri.ttf" },
  { name = "Morpheus", path = "Fonts\\MORPHEUS.ttf" },
}

-- Ein Font-Objekt je Rolle; Grundlage (Größe, Farbe, Schatten) ist das Blizzard-Objekt dahinter
local FONT_ROLES = {
  title = "GameFontNormal",          -- Kartentitel, Überschriften (gold)
  body = "GameFontHighlight",        -- Fließtext (weiß)
  label = "GameFontNormalSmall",     -- Zeilenbeschriftungen (gold)
  small = "GameFontHighlightSmall",  -- Zeilenwerte (weiß)
  number = "GameFontNormalLarge",    -- Zeit im Hauptfenster
  huge = "GameFontNormalHuge",       -- große Zahl auf Karten, Einblendungen
}

Theme.COLORS = {}
for name, color in pairs(CLASSIC_COLORS) do
  Theme.COLORS[name] = { color[1], color[2], color[3] }
end

-- "|cffrrggbb" je Farbe, beim Anwenden neu berechnet (Texte werden mehrmals pro Sekunde gebaut)
local hexCodes = {}

local function toHex(color)
  local function byte(value) return math.floor(value * 255 + 0.5) end
  return string.format("|cff%02x%02x%02x", byte(color[1]), byte(color[2]), byte(color[3]))
end

function Theme.Hex(name)
  return hexCodes[name]
end

-- Farbe als r, g, b (für SetTextColor/SetColorTexture)
function Theme.RGB(name)
  local color = Theme.COLORS[name]
  return color[1], color[2], color[3]
end

local active = Theme.PRESETS.classic

function Theme.Preset()
  return active
end

---------------------------------------------------------------------------
-- Farben
---------------------------------------------------------------------------
-- Klassenfarbe als { r, g, b } zum Klassen-Kürzel (RAID_CLASS_COLORS), sonst fallback (auch nil)
function Theme.ClassColor(class, fallback)
  local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if color then return { color.r, color.g, color.b } end
  return fallback
end

local function accentFor(key)
  if key == "class" then return Theme.ClassColor(UnitClass and select(2, UnitClass("player"))) end
  return Theme.ACCENTS[key]
end

local function applyColors(preset, accentKey)
  for name, base in pairs(CLASSIC_COLORS) do
    local color = preset.colors[name] or base
    local target = Theme.COLORS[name]
    target[1], target[2], target[3] = color[1], color[2], color[3]
  end
  local accent = accentFor(accentKey)
  if accent then
    local target = Theme.COLORS.accent
    target[1], target[2], target[3] = accent[1], accent[2], accent[3]
  end
  for name, color in pairs(Theme.COLORS) do hexCodes[name] = toHex(color) end
end

---------------------------------------------------------------------------
-- Schriften
---------------------------------------------------------------------------
local fonts = {}     -- Name des Font-Objekts -> { font, role, outlined }
local readableSize = 0      -- Untergrenze der Schrift (themeMinFontSize, 0 = aus), s. Lesbarkeit unten
local smallestFontSize = 0  -- kleinste Rolle nach dem Anwenden
local defaults = {}  -- Rolle -> { face, size, flags } des Blizzard-Objekts
local OUTLINED_SUFFIX = "Outline"

local function fontName(role, outlined)
  return "LevelTimerFont_" .. role .. (outlined and OUTLINED_SUFFIX or "")
end

-- Je Rolle zwei Objekte: wie eingestellt und immer mit Kontur (Layout "text" für Streams, Textfelder auf Balken)
for role, baseName in pairs(FONT_ROLES) do
  local base = _G[baseName]
  if base then defaults[role] = { base:GetFont() } end
  for _, outlined in ipairs({ false, true }) do
    local name = fontName(role, outlined)
    local font = CreateFont(name)
    if base then
      -- Kopie statt Vererbung: eigene Änderungen (SetFont) wirken nicht auf Blizzards Objekt zurück
      if font.CopyFontObject then font:CopyFontObject(base) else font:SetFontObject(base) end
    end
    fonts[name] = { font = font, role = role, outlined = outlined }
  end
end

-- Name des Font-Objekts einer Rolle, für CreateFontString(nil, layer, Theme.Font("label")); outlined = immer mit
-- Kontur (mindestens "outline", "thick" bleibt)
function Theme.Font(role, outlined)
  return fontName(role, outlined)
end

local function sharedMedia()
  return LibStub and LibStub("LibSharedMedia-3.0", true)
end

-- Auswahl für themeFont: { { key, name } }, zuerst "" (Schrift des Clients), dann Blizzard-Schriften, dann
-- weitere aus LibSharedMedia (nur wenn ein anderes Addon die Bibliothek geladen hat)
function Theme.FontChoices()
  local choices = { { key = "" } }
  local seen = {}
  for _, font in ipairs(BUILTIN_FONTS) do
    table.insert(choices, { key = font.name, name = font.name })
    seen[font.name] = true
  end
  local media = sharedMedia()
  if media and media.List then
    for _, name in ipairs(media:List("font") or {}) do
      if not seen[name] then
        table.insert(choices, { key = name, name = name })
        seen[name] = true
      end
    end
  end
  return choices
end

-- Pfad einer gewählten Schrift; nil = Schrift des Clients (auch wenn ein gemerktes Medium gerade fehlt)
function Theme.FontPath(key)
  if not key or key == "" then return nil end
  for _, font in ipairs(BUILTIN_FONTS) do
    if font.name == key then return font.path end
  end
  local media = sharedMedia()
  return media and media.Fetch and media:Fetch("font", key, true) or nil
end

local function applyFonts(db)
  local face = Theme.FontPath(db.themeFont)
  local outline = OUTLINE_FLAGS[db.themeOutline]
  local offset = db.themeFontSize or 0
  local floor = math.max(MIN_FONT_SIZE, readableSize)
  smallestFontSize = 0
  for _, entry in pairs(fonts) do
    local default = defaults[entry.role]
    if default and default[1] then
      local flags = (outline and outline ~= "") and outline or (entry.outlined and OUTLINE_FLAGS.outline)
        or (default[3] or "")
      local size = math.max(floor, default[2] + offset)
      entry.font:SetFont(face or default[1], size, flags)
      smallestFontSize = smallestFontSize == 0 and size or math.min(smallestFontSize, size)
    end
  end
end

---------------------------------------------------------------------------
-- Balkentexturen (themeBarTexture, Roadmap 361): "" = einfarbig wie bisher, eigene TGA aus tools/artwork (weiß in
-- Graustufen, eingefärbt per SetVertexColor), Blizzards Statusleiste und, falls ein anderes Addon LibSharedMedia
-- geladen hat, dessen "statusbar"-Medien
---------------------------------------------------------------------------
local MEDIA = "Interface\\AddOns\\" .. addonName .. "\\Media\\"
local FLAT_TEXTURE = "Interface\\Buttons\\WHITE8x8"  -- wie Theme.WHITE_TEXTURE (steht weiter unten)
local BUILTIN_BARS = {
  { key = "smooth", path = MEDIA .. "BarSmooth" },
  { key = "gloss", path = MEDIA .. "BarGloss" },
  { key = "blizzard", path = "Interface\\TargetingFrame\\UI-StatusBar" },
}
Theme.BUILTIN_BARS = BUILTIN_BARS

-- Auswahl: { { key, name } }; name nil = Text aus den Locales (BAR_TEXTURE_<KEY>), Medien mit ihrem Namen
function Theme.BarTextureChoices()
  local choices = { { key = "" } }
  local seen = {}
  for _, bar in ipairs(BUILTIN_BARS) do
    table.insert(choices, { key = bar.key })
    seen[bar.key] = true
  end
  local media = sharedMedia()
  if media and media.List then
    for _, name in ipairs(media:List("statusbar") or {}) do
      if not seen[name] then
        table.insert(choices, { key = name, name = name })
        seen[name] = true
      end
    end
  end
  return choices
end

-- Pfad der gewählten Balkentextur; einfarbig, wenn nichts gewählt ist oder ein gemerktes Medium fehlt
function Theme.BarTexturePath(key)
  if not key or key == "" then return FLAT_TEXTURE end
  for _, bar in ipairs(BUILTIN_BARS) do
    if bar.key == key then return bar.path end
  end
  local media = sharedMedia()
  return media and media.Fetch and media:Fetch("statusbar", key, true) or FLAT_TEXTURE
end

local barTexture = FLAT_TEXTURE

-- Füllung eines Balkens in der gewählten Textur und Farbe (statt SetColorTexture)
function Theme.SetBarTexture(texture, r, g, b, a)
  texture:SetTexture(barTexture)
  texture:SetVertexColor(r, g, b, a or 1)
end

---------------------------------------------------------------------------
-- Lesbarkeit (themeMinFontSize, Roadmap 361): keine Rolle kleiner als die Untergrenze, und keine Anzeige so klein
-- skaliert, dass ihre kleinste Schrift effektiv (Punktgröße x Größe der Anzeige) darunter fällt. 0 = aus.
---------------------------------------------------------------------------
Theme.MIN_READABLE_SIZES = { 0, 8, 9, 10, 11, 12 }

-- Kleinste Größe einer Anzeige, bei der die Untergrenze noch hält (1 = nicht verkleinern); nil = keine Grenze
function Theme.MinReadableScale()
  if readableSize <= 0 or smallestFontSize <= 0 then return nil end
  return math.min(1, readableSize / smallestFontSize)
end

-- Höhe einer Rolle in Punkten (für Zeilenhöhen, die der Schrift folgen sollen)
function Theme.FontHeight(role)
  local _, size = fonts[fontName(role)].font:GetFont()
  return size or 0
end

---------------------------------------------------------------------------
-- Rahmen: Fenster (Panels mit BackdropTemplate) und Karten (einfache Frames)
---------------------------------------------------------------------------
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8x8"
Theme.WHITE_TEXTURE = WHITE_TEXTURE  -- einfarbige Fläche; Widgets.WHITE_TEXTURE zeigt hierher
local BORDER_SIZE = 1
local TOOLTIP_BACKDROP = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 14,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
Theme.TOOLTIP_BACKDROP = TOOLTIP_BACKDROP

-- Eigener Grund und vier 1-px-Linien (flat/none, Karten), einmal je Frame angelegt
local function flatParts(frame)
  local existing = rawget(frame, "themeParts")  -- rawget: Frames liefern für unbekannte Schlüssel sonst Methoden
  if existing then return existing end
  local parts = { lines = {} }
  parts.background = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
  parts.background:SetAllPoints(frame)
  for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
    local line = frame:CreateTexture(nil, "BORDER")
    if side == "TOP" or side == "BOTTOM" then
      line:SetPoint(side .. "LEFT")
      line:SetPoint(side .. "RIGHT")
      line:SetHeight(BORDER_SIZE)
    else
      line:SetPoint("TOP" .. side)
      line:SetPoint("BOTTOM" .. side)
      line:SetWidth(BORDER_SIZE)
    end
    parts.lines[side] = line
  end
  frame.themeParts = parts
  return parts
end

local function setFlat(frame, color, alpha, showBorder)
  local parts = flatParts(frame)
  parts.background:SetColorTexture(color[1], color[2], color[3], alpha)
  parts.background:Show()
  local border = Theme.COLORS.border
  for _, line in pairs(parts.lines) do
    line:SetColorTexture(border[1], border[2], border[3], 1)
    line:SetShown(showBorder)
  end
end

local function hideFlat(frame)
  local parts = rawget(frame, "themeParts")
  if not parts then return end
  parts.background:Hide()
  for _, line in pairs(parts.lines) do line:Hide() end
end

-- Fenster im Stil des Presets. alpha = Deckkraft des Grunds; bei 0 verschwindet auch der Rand (sonst bliebe ein
-- schwebender Goldrahmen stehen). chroma = { r, g, b } für einen deckenden Grund ohne Rand (OBS-Freistellung).
function Theme.ApplyPanel(frame, alpha, chroma)
  local style = active.panelBorder
  local color = chroma or Theme.COLORS.background
  local backgroundAlpha = chroma and 1 or alpha * active.panelAlpha
  local showBorder = not chroma and backgroundAlpha > 0
  if style == Theme.BORDER_TOOLTIP then
    hideFlat(frame)
    if rawget(frame, "themeStyle") ~= style then frame:SetBackdrop(TOOLTIP_BACKDROP) end
    frame:SetBackdropColor(color[1], color[2], color[3], backgroundAlpha)
    local border = Theme.COLORS.border
    frame:SetBackdropBorderColor(border[1], border[2], border[3], showBorder and 1 or 0)
  else
    if rawget(frame, "themeStyle") ~= style and frame.ClearBackdrop then frame:ClearBackdrop() end
    setFlat(frame, color, backgroundAlpha, showBorder and style == Theme.BORDER_FLAT)
  end
  frame.themeStyle = style
end

-- Karte: Grund in surface mit der Deckkraft des Presets, Rand nur im Stil flat
function Theme.ApplyCard(frame)
  setFlat(frame, Theme.COLORS.surface, active.cardAlpha, active.cardBorder == Theme.BORDER_FLAT)
end

---------------------------------------------------------------------------
-- Anwenden: Farben, Schriften, dann alle angemeldeten Fenster und Karten (Fenster behalten ihre Deckkraft)
---------------------------------------------------------------------------
local panels = setmetatable({}, { __mode = "k" })  -- Fenster -> Deckkraft
local cards = setmetatable({}, { __mode = "k" })

-- Fenster mit fester Deckkraft (Einstellungen, Historie, ...), folgt dem Preset
function Theme.RegisterPanel(frame, alpha)
  panels[frame] = alpha
  Theme.ApplyPanel(frame, alpha)
end

function Theme.RegisterCard(frame)
  cards[frame] = true
  Theme.ApplyCard(frame)
end

-- Hintergrund eines Anzeigefensters aus den Einstellungen (Hauptfenster, Split-Liste, Zusammenfassung):
-- windowBackground = "default" (bgAlpha) oder eine Chroma-Farbe; alpha optional statt bgAlpha (Layout "text": 0)
Theme.BACKGROUND_DEFAULT = "default"
Theme.CHROMA = { green = Theme.COLORS.chromaGreen, magenta = Theme.COLORS.chromaMagenta }

function Theme.ApplyBackground(frame, db, alpha)
  panels[frame] = nil  -- Deckkraft kommt aus den Einstellungen, nicht aus der Anmeldung
  Theme.ApplyPanel(frame, alpha or db.bgAlpha, Theme.CHROMA[db.windowBackground])
end

function Theme.Apply(db)
  active = Theme.PRESETS[db.theme] or Theme.PRESETS[Theme.DEFAULT]
  applyColors(active, db.themeAccent)
  readableSize = db.themeMinFontSize or 0
  applyFonts(db)
  barTexture = Theme.BarTexturePath(db.themeBarTexture)
  for frame, alpha in pairs(panels) do Theme.ApplyPanel(frame, alpha) end
  for frame in pairs(cards) do Theme.ApplyCard(frame) end
end

applyColors(active, "")  -- Farben stehen schon vor dem ersten Apply (Module merken sie beim Laden)
ns.RegisterApply(Theme.Apply)

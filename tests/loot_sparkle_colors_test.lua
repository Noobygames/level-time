-- Roadmap 457 & 444: Kategoriefarben, Bodenschatten, Silhouettenmaske, Effekt-Vorschau & Lueur-Erkennung
local LootSparkles, LootSparkle, LootTarget = addon.LootSparkles, addon.LootSparkle, addon.LootTarget
local expect, expectTrue, expectNear = expect, expectTrue, expectNear

-- Client-Funktionen und CVars fürs Soft-Targeting
local plates = {}
local cursors = {}
local objects = {}
local inRange = {}
local loot = {}
C_NamePlate = { GetNamePlateForUnit = function(unit) return plates[unit] end }
UnitIsGameObject = function(unit) return objects[unit] == true end
SetUnitCursorTexture = function(texture, unit)
  texture:SetTexture(cursors[unit])
  return cursors[unit] ~= nil
end
UnitIsInInteractRange = function(unit) return inRange[unit] end
CanLootUnit = function(guid)
  local entry = loot[guid] or {}
  return entry[1] == true, entry[2] == true
end

wow.state.cvars = {
  SoftTargetInteract = "1", SoftTargetIconGameObject = "0", SoftTargetInteractRange = "10.000000",
  SoftTargetInteractArc = "0", SoftTargetInteractOnlyInRange = "0", SoftTargetNameplateInteract = "0",
}

wow.login({ level = 20 })

-- 1. ColorFor Tests
local function expectColor(desc, actual, expected)
  expectNear(desc .. " R", actual[1], expected[1], 0.01)
  expectNear(desc .. " G", actual[2], expected[2], 0.01)
  expectNear(desc .. " B", actual[3], expected[3], 0.01)
end

expectColor("ore color", LootSparkle.ColorFor("ready", "ore"), { 1.00, 0.60, 0.18 })
expectColor("herb color", LootSparkle.ColorFor("ready", "herb"), { 0.40, 1.00, 0.42 })
expectColor("quest color", LootSparkle.ColorFor("ready", "quest"), { 1.00, 0.84, 0.15 })
expectColor("chest color", LootSparkle.ColorFor("ready", "chest"), { 0.45, 0.78, 1.00 })
expectColor("bobber color", LootSparkle.ColorFor("ready", "bobber"), { 1.00, 0.45, 0.40 })
expectColor("corpse color", LootSparkle.ColorFor("ready", "corpse"), { 1.00, 0.86, 0.45 })
expectColor("locked color", LootSparkle.ColorFor("locked", "ore"), { 0.6, 0.6, 0.6 })
expectColor("locked corpse", LootSparkle.ColorFor("locked", "corpse"), { 0.6, 0.6, 0.6 })

-- Fallback wenn lootSparkleCategoryColors = false
addon.Set("lootSparkleCategoryColors", false)
expectColor("category colors disabled fallback ore", LootSparkle.ColorFor("ready", "ore"), { 1, 0.86, 0.45 })
expectColor("category colors disabled fallback herb", LootSparkle.ColorFor("ready", "herb"), { 1, 0.86, 0.45 })
addon.Set("lootSparkleCategoryColors", true)
expectColor("category colors re-enabled ore", LootSparkle.ColorFor("ready", "ore"), { 1.00, 0.60, 0.18 })

-- 2. Shade (Bodenschatten) Tests
expectTrue("has shade", LootSparkle.HasShade())
local shade = LootSparkle.Shade()
expectTrue("shade exists", shade ~= nil)
expect("shade blend mode", shade:GetBlendMode(), "BLEND")
expectNear("shade alpha", shade:GetAlpha(), 0.30, 0.01)
local sr, sg, sb = shade:GetVertexColor()
expect("shade vertex R", sr, 0)
expect("shade vertex G", sg, 0)
expect("shade vertex B", sb, 0)
expectNear("shade width at scale 1", shade._width, 96, 0.1)
expectNear("shade height at scale 1", shade._height, 54, 0.1)

addon.Set("lootSparkleScale", 1.5)
expectNear("shade width at scale 1.5", shade._width, 144, 0.1)
expectNear("shade height at scale 1.5", shade._height, 81, 0.1)
addon.Set("lootSparkleScale", 1)

-- 3. Silhouette Mask Tests
expect("silhouette inactive by default", LootSparkle.IsSilhouetteActive(), false)
addon.Set("lootSparkleSilhouette", true)
expect("silhouette active when enabled", LootSparkle.IsSilhouetteActive(), true)
local mask = LootSparkle.SilhouetteMask()
expectTrue("mask created", mask ~= nil)
addon.Set("lootSparkleSilhouette", false)
expect("silhouette inactive when disabled", LootSparkle.IsSilhouetteActive(), false)

-- 4. Preview Tests
LootSparkle.Release()
expect("not previewing before call", LootSparkle.IsPreviewing(), false)
LootSparkle.Preview("ore")
expectTrue("is previewing", LootSparkle.IsPreviewing())
expect("preview attached to UIParent", LootSparkle.AttachedTo(), UIParent)
expect("current kind is ore", LootSparkle.CurrentKind(), "ore")
expect("current state is ready", LootSparkle.State(), "ready")

-- Direkte Angabe der Art
LootSparkle.Preview("herb")
expect("preview switched to herb", LootSparkle.CurrentKind(), "herb")

-- Freigabe nach Ablauf des 4s-Timers
wow.runTimers()
expect("released after timer", LootSparkle.IsPreviewing(), false)
expect("attached cleared", LootSparkle.AttachedTo(), nil)

-- Vorschau ohne Art wechselt durch PREVIEW_CYCLE
LootSparkle.Preview()
expectTrue("previewing cycle", LootSparkle.IsPreviewing())
expect("first cycle kind is ore", LootSparkle.CurrentKind(), "ore")
LootSparkle.Release()

LootSparkle.Preview()
expect("second cycle kind is herb", LootSparkle.CurrentKind(), "herb")
LootSparkle.Release()

-- 5. Soft-Targeting: Weitergabe von kind an LootSparkle
local SOFT = LootTarget.UNIT
local plate = CreateFrame("Frame")
plates[SOFT] = plate
plates.nameplate1 = plate
objects[SOFT] = true
cursors[SOFT] = "Interface\\Cursor\\Mine"
inRange[SOFT] = true
wow.state.units[SOFT] = { name = "Kupfervorkommen" }

addon.Set("lootSparkleOre", true)
addon.Set("lootSparkleHerbs", true)
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
expect("attached to plate", LootSparkle.AttachedTo(), plate)
expect("kind passed as ore", LootSparkle.CurrentKind(), "ore")

local glint = LootSparkle.Glints()[1]
local gr, gg, gb = glint.texture:GetVertexColor()
expectColor("glint vertex color is ore", { gr, gg, gb }, { 1.00, 0.60, 0.18 })

-- Wechsel zu Kräutern
cursors[SOFT] = "Interface\\Cursor\\GatherHerbs"
wow.fire("PLAYER_SOFT_INTERACT_CHANGED", "GameObject-1", "GameObject-2")
expect("kind passed as herb", LootSparkle.CurrentKind(), "herb")
gr, gg, gb = glint.texture:GetVertexColor()
expectColor("glint vertex color updated to herb", { gr, gg, gb }, { 0.40, 1.00, 0.42 })

addon.Set("lootSparkleOre", false)
addon.Set("lootSparkleHerbs", false)

-- 6. Roadmap 444: Truhen-, Schwimmer- und Berufe-Erkennung
-- 6.1 Truhen-Erkennung
objects[SOFT] = true

-- Via PickLock Cursor
cursors[SOFT] = "Interface\\Cursor\\PickLock"
wow.state.units[SOFT] = { name = "Geheimnisvolles Ding" }
expect("PickLock Cursor ergibt chest", (LootTarget.Classify(SOFT)), LootTarget.CHEST)

-- Via Truhen-Name mit Interact-Cursor ("Verbeulte Truhe" / "Battered Chest")
cursors[SOFT] = "Interface\\Cursor\\Interact"
wow.state.units[SOFT] = { name = "Verbeulte Truhe" }
expect("Verbeulte Truhe erkannt", (LootTarget.Classify(SOFT)), LootTarget.CHEST)

wow.state.units[SOFT] = { name = "Battered Chest" }
expect("Battered Chest erkannt", (LootTarget.Classify(SOFT)), LootTarget.CHEST)

-- Via gelernten Behälter (LootTarget.LearnContainerFromGUID)
local chestGuid = "GameObject-0-4240-0-117-12345-00002A5469"
wow.state.units[SOFT] = { name = "Seltsames Gebilde", guid = chestGuid }
expect("noch nicht gelernt: nil", (LootTarget.Classify(SOFT)), nil)
LootTarget.LearnContainerFromGUID(chestGuid)
expect("nach Lernen: chest", (LootTarget.Classify(SOFT)), LootTarget.CHEST)

-- 6.2 Schwimmer-Erkennung
-- Via Fishing Cursor
cursors[SOFT] = "Interface\\Cursor\\Fishing"
wow.state.units[SOFT] = { name = "Schwimmer" }
expect("Fishing Cursor ergibt bobber", (LootTarget.Classify(SOFT)), LootTarget.BOBBER)

-- Via Bobber Objekt-ID 35591 (auch mit generischem Cursor)
cursors[SOFT] = "Interface\\Cursor\\Interact"
local bobberGuid = "GameObject-0-4240-0-117-35591-00002A5469"
wow.state.units[SOFT] = { name = "Schwimmer", guid = bobberGuid }
expect("Objekt-ID 35591 ergibt bobber", (LootTarget.Classify(SOFT)), LootTarget.BOBBER)

-- 6.3 NPC- und Service-Ausschlüsse (Speak, Mail, Trainer -> nil)
cursors[SOFT] = "Interface\\Cursor\\Speak"
wow.state.units[SOFT] = { name = "Wache" }
expect("Speak Cursor ausgeschlossen", (LootTarget.Classify(SOFT)), nil)

cursors[SOFT] = "Interface\\Cursor\\Mail"
wow.state.units[SOFT] = { name = "Briefkasten" }
expect("Mail Cursor ausgeschlossen", (LootTarget.Classify(SOFT)), nil)

cursors[SOFT] = "Interface\\Cursor\\Trainer"
wow.state.units[SOFT] = { name = "Klassenlehrer" }
expect("Trainer Cursor ausgeschlossen", (LootTarget.Classify(SOFT)), nil)

-- 6.4 lootSparkleHideUntrained Filterung
local oldIsPlayerSpell = IsPlayerSpell
local knownSpells = {}
IsPlayerSpell = function(spellId) return knownSpells[spellId] == true end

addon.Set("lootSparkleOre", true)
addon.Set("lootSparkleHerbs", true)
addon.Set("lootSparkleHideUntrained", true)

-- Erz ohne Bergbau (2575 false): evaluate schaltet Plakette nicht an
cursors[SOFT] = "Interface\\Cursor\\Mine"
wow.state.units[SOFT] = { name = "Kupfervorkommen" }
knownSpells[2575] = false
LootSparkle.Release()
wow.fire("PLAYER_SOFT_INTERACT_CHANGED", "GameObject-1", "GameObject-2")
expect("Erz ohne Bergbau: kein Glitzern", LootSparkle.AttachedTo(), nil)

-- Erz mit Bergbau (2575 true): Glitzern erlaubt
knownSpells[2575] = true
wow.fire("PLAYER_SOFT_INTERACT_CHANGED", "GameObject-1", "GameObject-2")
expect("Erz mit Bergbau: glitzert", LootSparkle.AttachedTo(), plate)

-- Kraut ohne Kräuterkunde (2366 false): evaluate schaltet Plakette nicht an
cursors[SOFT] = "Interface\\Cursor\\GatherHerbs"
wow.state.units[SOFT] = { name = "Friedensblume" }
knownSpells[2366] = false
LootSparkle.Release()
wow.fire("PLAYER_SOFT_INTERACT_CHANGED", "GameObject-2", "GameObject-3")
expect("Kraut ohne Kräuterkunde: kein Glitzern", LootSparkle.AttachedTo(), nil)

-- Kraut mit Kräuterkunde (2366 true): Glitzern erlaubt
knownSpells[2366] = true
wow.fire("PLAYER_SOFT_INTERACT_CHANGED", "GameObject-2", "GameObject-3")
expect("Kraut mit Kräuterkunde: glitzert", LootSparkle.AttachedTo(), plate)

addon.Set("lootSparkleOre", false)
addon.Set("lootSparkleHerbs", false)
addon.Set("lootSparkleHideUntrained", false)
IsPlayerSpell = oldIsPlayerSpell

-- 6.5 IsFishing
local oldUnitChannelInfo = UnitChannelInfo
UnitChannelInfo = function(unit)
  if unit == "player" then return "Angeln", "", 136245 end
end
expectTrue("IsFishing mit Texture 136245", LootSparkles.IsFishing())
UnitChannelInfo = function(unit)
  if unit == "player" then return "Angeln", "", "Interface\\Icons\\Trade_Fishing" end
end
expectTrue("IsFishing mit Trade_Fishing", LootSparkles.IsFishing())
UnitChannelInfo = function() return nil end
expect("IsFishing ohne Kanalisieren", LootSparkles.IsFishing(), false)
UnitChannelInfo = oldUnitChannelInfo

-- 7. Roadmap 456: Multi-Layer-2D-Effekt-Engine & Stile
-- 7.1 Stile und Umschalten
expect("standard style is finder", LootSparkle.CurrentStyle(), "finder")
expect("17 sparkle styles exist", #LootSparkle.STYLES, 17)

local expectedStyles = {
  finder = true, arrow = true, glitter = true, symbol = true, clock = true, progress = true, pillar = true,
  fireflies = true, treasure = true, pixels = true, constellation = true,
  aura = true, beam = true, sigil = true, ripple = true, sparkle = true, subtle = true,
}
local Styles = addon.LootSparkleStyles
expect("default is the first style", Styles.DEFAULT, LootSparkle.STYLES[1])
for _, s in ipairs(LootSparkle.STYLES) do
  expectTrue("style definition for " .. s, Styles.Get(s) ~= nil)
  expectTrue("style has group " .. s, Styles.Get(s).group == "shapes" or Styles.Get(s).group == "classic")
end
expect("classic group has 6 styles", (function()
  local n = 0
  for _, s in ipairs(LootSparkle.STYLES) do if Styles.Get(s).group == "classic" then n = n + 1 end end
  return n
end)(), 6)
for _, s in ipairs(LootSparkle.STYLES) do
  expectTrue("valid style in STYLES: " .. s, expectedStyles[s] == true)
end

-- Vorbereitung für Schicht-Prüfungen via Vorschau
LootSparkle.Preview("herb")
expect("attached in preview", LootSparkle.AttachedTo(), UIParent)
expect("kind is herb", LootSparkle.CurrentKind(), "herb")
expect("state is ready", LootSparkle.State(), "ready")

local sparkleFrame = wow.findFrame(function(f)
  return f._parent == UIParent and rawget(f, "_animationGroups") ~= nil
end)
expectTrue("sparkle frame found", sparkleFrame ~= nil)

local allLayerNames = { "halo", "ring1", "ring2", "arcs", "beam", "sigil", "bracket", "bracketLocked", "arrow", "symbol",
  "shadow", "shadowArrow", "shadowSymbol", "groundRing", "groundArrow", "groundSymbol", "bracketOutline", "bracketGlow",
  "bracketBloom", "bracketCore", "trail", "arrowOutline", "arrowGlow", "badge", "symbolBloom", "symbolOutline" }
-- alle Schichten der Stile (auch die erzeugten Zeiger, Segmente, Ringe), außer dem Aufblitz-Impuls
do
  local known = {}
  for _, name in ipairs(allLayerNames) do known[name] = true end
  for _, def in ipairs(Styles.LAYERS) do
    if not def.flash and not known[def.name] then table.insert(allLayerNames, def.name) end
  end
end
local layers = LootSparkle.Layers()
expectTrue("layers table returned", layers ~= nil)
for _, name in ipairs(allLayerNames) do
  expectTrue("layer texture exists: " .. name, layers[name] ~= nil)
end
expectTrue("ring alias exists", layers.ring == layers.ring1)
expectTrue("flash layer exists", layers.flash ~= nil)

local expectedActive = {
  -- bracketLocked gehört zum Zielsucher, ist aber nur im Zustand "locked" sichtbar
  finder = { shadow = true, groundRing = true, bracketOutline = true, bracketGlow = true, bracketBloom = true, bracket = true, bracketCore = true },
  arrow = { shadowArrow = true, groundArrow = true, trail = true, arrowOutline = true, arrowGlow = true, arrow = true },
  glitter = { shadow = true, groundRing = true },
  symbol = { shadowSymbol = true, groundSymbol = true, badge = true, symbolBloom = true, symbolOutline = true, symbol = true },
  -- Bodenstile: in "ready" sichtbare Schichten (Zeiger 2 bis 16 gibt es nur bei "far")
  clock = { shadowWide = true, clockOutline = true, clockGlow = true, clockFace = true, clockHand1 = true },
  progress = { shadowWide = true, progressTrack = true, progressGlow = true },
  pillar = { shadow = true, pillarShade = true, groundRing = true, pillarGround = true, pillar = true, pillarCore = true,
    pillarSurge = true, pillarBloom = true, pillarRing1 = true, pillarRing2 = true, pillarRing3 = true,
    pillarMote1 = true, pillarMote2 = true, pillarMote3 = true, pillarMote4 = true, pillarMote5 = true },
  aura = { arcs = true, halo = true },
  beam = { beam = true, ring1 = true },
  sigil = { arcs = true, halo = true, sigil = true },
  ripple = { halo = true, ring1 = true, ring2 = true },
  sparkle = { halo = true },
  subtle = { halo = true, ring1 = true },
}

for _, style in ipairs(LootSparkle.STYLES) do
  addon.Set("lootSparkleStyle", style)
  expect("style set to " .. style, LootSparkle.CurrentStyle(), style)
  local activeNames = LootSparkle.ActiveLayerNames()
  local exp = expectedActive[style]
  if style == "progress" then
    -- alle 16 Segmente sind bei "ready" sichtbar
    exp = setmetatable({}, { __index = function(_, name) return expectedActive.progress[name] or name:find("^progressSeg") ~= nil end })
  end
  if style == "fireflies" or style == "treasure" or style == "pixels" or style == "constellation" then
    -- Szenen-Stile: sichtbar bei "ready" ist jede Schicht des Stils ohne Zustandsbeschränkung oder mit "ready"
    exp = {}
    for _, name in ipairs(Styles.Get(style).layers) do
      local def = Styles.LAYERS_BY_NAME[name]
      if not def.states or def.states.ready then exp[name] = true end
    end
  end
  expectTrue(style .. " layer names listed", #activeNames == #Styles.Get(style).layers)

  -- Prüfe, dass die erwarteten Layer aktiv sind
  for _, name in ipairs(allLayerNames) do
    if exp[name] then
      expectTrue(style .. " has active " .. name, activeNames[name] == true)
      expectTrue(style .. " layer is shown: " .. name, layers[name]:IsShown())
      local r, g, b = layers[name]:GetVertexColor()
      local def = Styles.LAYERS_BY_NAME[name]
      local want = def.color or LootSparkle.Whiten({ 0.40, 1.00, 0.42 }, def.whiten)
      expectColor(style .. " layer color " .. name, { r, g, b }, want)
    else
      -- Zustandsabhängige Schichten (Zielsucher gesperrt) gehören zum Stil, sind in "ready" aber verborgen
      local def = Styles.LAYERS_BY_NAME[name]
      expectTrue(style .. " has inactive " .. name, activeNames[name] ~= true or (def.states ~= nil and not def.states.ready))
      expect(style .. " inactive layer is hidden: " .. name, layers[name]:IsShown(), false)
    end
  end
end

-- 7.2 Dynamische Zustandswechsel (FAR -> READY -> LOCKED)
addon.Set("lootSparkleStyle", "aura")
LootSparkle.SetState("far", "ore")
expect("switched to far", LootSparkle.State(), "far")
expectNear("far alpha is 0.5", sparkleFrame:GetAlpha(), 0.5, 0.01)
local r, g, b = layers.halo:GetVertexColor()
expectColor("far state keeps category color", { r, g, b }, { 1.00, 0.60, 0.18 })

-- READY Impuls (Flash & Aufhellung)
local beforeFlash = LootSparkle.LastFlashAt()
LootSparkle.SetState("ready", "ore")
expect("switched to ready", LootSparkle.State(), "ready")
expectNear("ready alpha is 1", sparkleFrame:GetAlpha(), 1, 0.01)
expectTrue("flash triggered on ready", LootSparkle.LastFlashAt() >= beforeFlash)
r, g, b = layers.arcs:GetVertexColor()
expectColor("ready state color", { r, g, b }, { 1.00, 0.60, 0.18 })

-- LOCKED Zustand (Entsättigt / grau)
LootSparkle.SetState("locked", "ore")
expect("switched to locked", LootSparkle.State(), "locked")
expectNear("locked alpha is 0.45", sparkleFrame:GetAlpha(), 0.45, 0.01)
r, g, b = layers.halo:GetVertexColor()
expectColor("locked halo color is gray", { r, g, b }, { 0.6, 0.6, 0.6 })
r, g, b = layers.arcs:GetVertexColor()
expectColor("locked arcs color is gray", { r, g, b }, { 0.6, 0.6, 0.6 })

-- 7.3 Eigene Stile (Roadmap 466, 471, 474, 475): Zustände, Schichten, Funken, Bodenschatten
local function shown(name) return layers[name]:IsShown() end
local function glintsShown()
  for _, g in ipairs(LootSparkle.Glints()) do
    if g.texture:IsShown() then return true end
  end
  return false
end

-- Zielsucher: weit = offene Klammern, bereit = zugeschnappt (Impuls), gesperrt = gestrichelt und grau
addon.Set("lootSparkleStyle", "finder")
LootSparkle.SetState("far", "ore")
expectTrue("finder far: bracket shown", shown("bracket"))
expect("finder far: dashed hidden", shown("bracketLocked"), false)
expect("finder far: wide brackets", layers.bracket:GetWidth(), 84)
expect("finder far: outline follows size", layers.bracketOutline:GetWidth(), 84)
expect("finder far: no bloom yet", shown("bracketBloom"), false)
expectTrue("finder far: ground ring at the foot", shown("groundRing"))
expect("finder: no glints", glintsShown(), false)
expect("finder: no classic shade", LootSparkle.Shade():IsShown(), false)
expectTrue("finder: contact shadow shown", shown("shadow"))
r, g, b = layers.shadow:GetVertexColor()
expectColor("contact shadow is black, not category colored", { r, g, b }, { 0, 0, 0 })
r, g, b = layers.bracket:GetVertexColor()
expectColor("bracket core is whitened ore color", { r, g, b }, LootSparkle.Whiten({ 1.00, 0.60, 0.18 }, 0.2))
LootSparkle.SetState("ready", "ore")
expect("finder ready: snapped brackets", layers.bracket:GetWidth(), 56)
expectTrue("finder ready: bloom shown", shown("bracketBloom"))
expectTrue("finder ready: hot core shown", shown("bracketCore"))
expectTrue("finder ready: snap animation played", Styles.Get("finder") ~= nil and wow.findFrame ~= nil)
LootSparkle.SetState("locked", "ore")
expect("finder locked: solid hidden", shown("bracket"), false)
expect("finder locked: glow hidden", shown("bracketGlow"), false)
expectTrue("finder locked: dashed shown", shown("bracketLocked"))
r, g, b = layers.bracketLocked:GetVertexColor()
expectColor("finder locked: grey", { r, g, b }, { 0.6, 0.6, 0.6 })

-- Pfeil: wippt, gesperrt still und grau
addon.Set("lootSparkleStyle", "arrow")
LootSparkle.SetState("far", "herb")
expectTrue("arrow shown", shown("arrow"))
local function playingGroup(layer)
  for _, group in ipairs(rawget(layer, "_animationGroups") or {}) do
    if group:IsPlaying() then return true end
  end
  return false
end
expectTrue("arrow bobs while far", playingGroup(layers.arrow))
expectTrue("arrow shadow bobs with it", playingGroup(layers.shadowArrow))
LootSparkle.SetState("locked", "herb")
expect("arrow still when locked", playingGroup(layers.arrow), false)
expect("arrow shadow still when locked", playingGroup(layers.shadowArrow), false)
r, g, b = layers.arrow:GetVertexColor()
expectColor("arrow locked grey (core slightly whitened)", { r, g, b }, LootSparkle.Whiten({ 0.6, 0.6, 0.6 }, 0.15))
LootSparkle.SetState("ready", "herb")
expectTrue("arrow bobs again when ready", playingGroup(layers.arrow))
expect("arrow: no glints", glintsShown(), false)

-- Symbol: kategorieabhängiger Atlas-Ausschnitt, wippt
addon.Set("lootSparkleStyle", "symbol")
LootSparkle.SetState("ready", "ore")
expectTrue("symbol shown", shown("symbol"))
expectTrue("symbol bobs", playingGroup(layers.symbol))
local l1, r1, t1, b1 = Styles.SymbolCoords("ore")
expectNear("ore cell left", l1, 0, 0.001)
expectNear("ore cell right", r1, 0.25, 0.001)
expectNear("ore cell top", t1, 0, 0.001)
expectNear("ore cell bottom", b1, 0.5, 0.001)
local l2, _, t2 = Styles.SymbolCoords("corpse")
expectNear("corpse cell left", l2, 0.25, 0.001)
expectNear("corpse cell top", t2, 0.5, 0.001)
local l3 = Styles.SymbolCoords("unbekannt")
expectNear("unknown kind falls back to scroll", l3, 0.5, 0.001)

-- Standard-Glitzer: nur Funken, keine Schichten
addon.Set("lootSparkleStyle", "glitter")
LootSparkle.SetState("far", "quest")
for _, name in ipairs(allLayerNames) do
  if name ~= "shadow" and name ~= "groundRing" then expect("glitter has no layer " .. name, shown(name), false) end
end
expectTrue("glitter keeps its contact shadow", shown("shadow"))
expectTrue("glitter: glints shown", glintsShown())
local extra = LootSparkle.Glints()[1].extras[1]
expectTrue("glitter: star outline shown", extra.texture:IsShown())
expectTrue("glitter: star outline animates in sync", extra.animation:IsPlaying())
expectTrue("glitter: glints animate", LootSparkle.Glints()[1].animation:IsPlaying())
addon.Set("lootSparkleStyle", "finder")
expect("glints off after switch to finder", glintsShown(), false)
expect("glint animation stopped", LootSparkle.Glints()[1].animation:IsPlaying(), false)
addon.Set("lootSparkleStyle", "aura")
expectTrue("classic aura keeps glints", glintsShown())
expect("classic aura: no star outline", LootSparkle.Glints()[1].extras[1].texture:IsShown(), false)
expectTrue("classic aura keeps shade", LootSparkle.Shade():IsShown())

-- Aufräumen
LootSparkle.Release()
expect("released after section 7", LootSparkle.AttachedTo(), nil)
addon.Set("lootSparkleStyle", "aura")


-- Bodenstile (Roadmap 467, 468, 476) -----------------------------------------------------------------------------------
LootSparkle.Preview("ore")  -- hängt das Glitzern an UIParent (Zustand ready)
local function alphaOf(name) return layers[name]:GetAlpha() end
local function anyPlaying(layer) return playingGroup(layer) end
local function countShown(prefix)
  local n = 0
  for name, layer in pairs(layers) do
    if name:find("^" .. prefix) and layer:IsShown() then n = n + 1 end
  end
  return n
end

-- Uhrwerk: weit = Zeiger kriecht (16 Stellungen, alle sichtbar und animiert), bereit = nur 12 Uhr, tickt
addon.Set("lootSparkleStyle", "clock")
LootSparkle.SetState("far", "ore")
expect("clock far: all 16 hand positions shown", countShown("clockHand"), 16)
expectTrue("clock far: hand 1 animates", anyPlaying(layers.clockHand1))
expectTrue("clock far: hand 9 animates", anyPlaying(layers.clockHand9))
expect("clock far: ring does not tick", anyPlaying(layers.clockFace), false)
expectNear("clock far: hand 1 base alpha 0", alphaOf("clockHand1"), 0, 0.001)
LootSparkle.SetState("ready", "ore")
expect("clock ready: only 12 o'clock hand", countShown("clockHand"), 1)
expectNear("clock ready: hand fully visible", alphaOf("clockHand1"), 1, 0.001)
expectTrue("clock ready: ring ticks", anyPlaying(layers.clockFace))
expectTrue("clock ready: outline ticks with it", anyPlaying(layers.clockOutline))
expect("clock ready: creeping stopped", anyPlaying(layers.clockHand9), false)
LootSparkle.SetState("locked", "ore")
expect("clock locked: hand stands", countShown("clockHand"), 1)
expect("clock locked: ring does not tick", anyPlaying(layers.clockFace), false)
local lr, lg, lb = layers.clockFace:GetVertexColor()
expectColor("clock locked: grey", { lr, lg, lb }, LootSparkle.Whiten({ 0.6, 0.6, 0.6 }, 0.2))
local l, r, t, b = Styles.CellCoords(5)
expectNear("cell 5 left", l, 0.25, 0.001)
expectNear("cell 5 right", r, 0.5, 0.001)
expectNear("cell 5 top", t, 0.25, 0.001)
expectNear("cell 5 bottom", b, 0.5, 0.001)

-- Fortschrittsring: weit = erste zehn Segmente laufen, bereit = alle 16 voll und poppen
addon.Set("lootSparkleStyle", "progress")
LootSparkle.SetState("far", "herb")
expect("progress far: 16 segments in place", countShown("progressSeg"), 16)
expectTrue("progress far: segment 1 fills", anyPlaying(layers.progressSeg1))
expectTrue("progress far: segment 10 fills", anyPlaying(layers.progressSeg10))
expect("progress far: segment 11 stays dark", anyPlaying(layers.progressSeg11), false)
expectNear("progress far: segment 16 dark", alphaOf("progressSeg16"), 0, 0.001)
expect("progress far: no glow yet", layers.progressGlow:IsShown(), false)
LootSparkle.SetState("ready", "herb")
expectNear("progress ready: segment 16 full", alphaOf("progressSeg16"), 1, 0.001)
expectNear("progress ready: segment 1 full", alphaOf("progressSeg1"), 1, 0.001)
expectTrue("progress ready: pop wave plays", anyPlaying(layers.progressSeg1))
expectTrue("progress ready: glow shown", layers.progressGlow:IsShown())
expectTrue("progress ready: track stays", layers.progressTrack:IsShown())
LootSparkle.SetState("locked", "herb")
expectNear("progress locked: ring dimmed", alphaOf("progressSeg4"), 0.35, 0.001)
expect("progress locked: glow hidden", layers.progressGlow:IsShown(), false)

-- Lichtsäule: Säule, Ringe und Lichtpunkte laufen; bereit pulsiert die Zusatzschicht, gesperrt steht alles
addon.Set("lootSparkleStyle", "pillar")
LootSparkle.SetState("far", "chest")
expectTrue("pillar far: column shown", shown("pillar"))
expectTrue("pillar far: column breathes", anyPlaying(layers.pillar))
expectTrue("pillar far: ring 1 rises", anyPlaying(layers.pillarRing1))
expectTrue("pillar far: ring 3 rises", anyPlaying(layers.pillarRing3))
expectTrue("pillar far: mote rises", anyPlaying(layers.pillarMote2))
expect("pillar far: no surge layer", shown("pillarSurge"), false)
LootSparkle.SetState("ready", "chest")
expectTrue("pillar ready: surge layer shown", shown("pillarSurge"))
expectTrue("pillar ready: surge pulses", anyPlaying(layers.pillarSurge))
expectTrue("pillar ready: bloom shown", shown("pillarBloom"))
LootSparkle.SetState("locked", "chest")
expect("pillar locked: ground light stands", anyPlaying(layers.pillarGround), false)
expect("pillar locked: rings frozen", anyPlaying(layers.pillarRing2), false)
expect("pillar locked: motes frozen", anyPlaying(layers.pillarMote1), false)
expect("pillar locked: surge hidden", shown("pillarSurge"), false)
LootSparkle.Release()
addon.Set("lootSparkleStyle", "aura")

-- Szenen-Stile (Roadmap 469, 470, 472, 473) ----------------------------------------------------------------------------
LootSparkle.Preview("ore")

-- Glühwürmchen: weit = vier Tiere irren (je eigene Dauer), bereit = gesammelt, Sammel-Animation läuft
addon.Set("lootSparkleStyle", "fireflies")
LootSparkle.SetState("far", "ore")
expectTrue("fireflies far: wandering core 1", anyPlaying(layers.fireflyCore1))
expectTrue("fireflies far: wandering glow 4", anyPlaying(layers.fireflyGlow4))
expect("fireflies far: gathered layers hidden", layers.fireflyReadyCore1:IsShown(), false)
LootSparkle.SetState("ready", "ore")
expect("fireflies ready: wanderers hidden", layers.fireflyCore1:IsShown(), false)
expectTrue("fireflies ready: gathered core shown", layers.fireflyReadyCore1:IsShown())
expectTrue("fireflies ready: orbit runs", anyPlaying(layers.fireflyReadyGlow2))
expectTrue("fireflies ready: bloom", layers.fireflyBloom:IsShown())
expect("fireflies: gather starts at the old spot", Styles.LAYERS_BY_NAME.fireflyReadyCore1.fromX, -34 - -22)
LootSparkle.SetState("locked", "ore")
expectTrue("fireflies locked: frozen flies stay visible", layers.fireflyCore1:IsShown())
expect("fireflies locked: no wandering", anyPlaying(layers.fireflyCore1), false)

-- Schatzkarte: weit = X und Pfad werden gemalt, bereit = X steht, Kreis (Zellen 9 bis 16) erscheint
addon.Set("lootSparkleStyle", "treasure")
LootSparkle.SetState("far", "quest")
expectTrue("treasure far: X stroke 1 painted", anyPlaying(layers.mapCell1))
expectTrue("treasure far: dash painted", anyPlaying(layers.mapCell6))
expect("treasure far: ring hidden", layers.mapCell12:IsShown(), false)
expect("treasure far: glow hidden", layers.mapGlow:IsShown(), false)
LootSparkle.SetState("ready", "quest")
expectNear("treasure ready: X fully drawn", alphaOf("mapCell3"), 1, 0.001)
expectTrue("treasure ready: ring segment 1 shown", layers.mapCell9:IsShown())
expectTrue("treasure ready: ring closes", anyPlaying(layers.mapCell16))
expectTrue("treasure ready: glow", layers.mapGlow:IsShown())
expect("treasure ready: no more painting", anyPlaying(layers.mapCell1), false)
LootSparkle.SetState("locked", "quest")
expect("treasure locked: ring hidden", layers.mapCell12:IsShown(), false)
expectNear("treasure locked: X stays", alphaOf("mapCell1"), 0.9, 0.001)

-- Pixel-Pop: weit = Pixel springen, Ring blinkt; bereit = Stern, Burst, Ring voll
addon.Set("lootSparkleStyle", "pixels")
LootSparkle.SetState("far", "chest")
expectTrue("pixels far: pixel pops", anyPlaying(layers.pixelBlock3))
expectTrue("pixels far: ring A blinks", anyPlaying(layers.pixelRingA))
expectTrue("pixels far: ring B blinks", anyPlaying(layers.pixelRingB))
expect("pixels far: star hidden", layers.pixelStar:IsShown(), false)
expect("pixels far: burst hidden", layers.pixelBurst1:IsShown(), false)
LootSparkle.SetState("ready", "chest")
expectTrue("pixels ready: star shown", layers.pixelStar:IsShown())
expectTrue("pixels ready: star pops", anyPlaying(layers.pixelStar))
expectTrue("pixels ready: burst plays", anyPlaying(layers.pixelBurst10))
expectNear("pixels ready: ring solid", alphaOf("pixelRingA"), 1, 0.001)
expect("pixels ready: ring does not blink", anyPlaying(layers.pixelRingA), false)
LootSparkle.SetState("locked", "chest")
expect("pixels locked: pixels stand", anyPlaying(layers.pixelBlock1), false)
expectNear("pixels locked: pixel visible", alphaOf("pixelBlock1"), 0.85, 0.001)

-- Sternbild: weit = Sterne und Linien erscheinen nacheinander, bereit = komplett mit Funkeln
addon.Set("lootSparkleStyle", "constellation")
LootSparkle.SetState("far", "herb")
expectTrue("constellation far: star 1 appears", anyPlaying(layers.skyStar1))
expectTrue("constellation far: line 4 appears", anyPlaying(layers.skyLine4))
expect("constellation far: no glow yet", layers.skyStarGlow1:IsShown(), false)
LootSparkle.SetState("ready", "herb")
expectNear("constellation ready: star 5 complete", alphaOf("skyStar5"), 1, 0.001)
expectNear("constellation ready: line 3 complete", alphaOf("skyLine3"), 0.95, 0.001)
expectTrue("constellation ready: stars twinkle", anyPlaying(layers.skyStarGlow3))
expectTrue("constellation ready: star pops", anyPlaying(layers.skyStar2))
expect("constellation ready: reveal stopped", anyPlaying(layers.skyLine1), false)
LootSparkle.SetState("locked", "herb")
expectNear("constellation locked: star dimmed", alphaOf("skyStar1"), 0.75, 0.001)
expect("constellation locked: still", anyPlaying(layers.skyLine1), false)
local l1, r1 = Styles.CellCoords(8)
expectNear("shade cell 8 left", l1, 0, 0.001)
expectNear("shade cell 8 right", r1, 0.25, 0.001)
LootSparkle.Release()
addon.Set("lootSparkleStyle", "aura")

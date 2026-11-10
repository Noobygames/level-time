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
expect("10 sparkle styles exist", #LootSparkle.STYLES, 10)

local expectedStyles = {
  finder = true, arrow = true, glitter = true, symbol = true,
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
  "shadow", "shadowArrow", "shadowSymbol", "bracketShade", "bracketGlow", "arrowShade", "arrowGlow", "symbolShade", "symbolBloom" }
local layers = LootSparkle.Layers()
expectTrue("layers table returned", layers ~= nil)
for _, name in ipairs(allLayerNames) do
  expectTrue("layer texture exists: " .. name, layers[name] ~= nil)
end
expectTrue("ring alias exists", layers.ring == layers.ring1)
expectTrue("flash layer exists", layers.flash ~= nil)

local expectedActive = {
  -- bracketLocked gehört zum Zielsucher, ist aber nur im Zustand "locked" sichtbar
  finder = { shadow = true, bracketShade = true, bracketGlow = true, bracket = true },
  arrow = { shadowArrow = true, arrowShade = true, arrowGlow = true, arrow = true },
  glitter = { shadow = true },
  symbol = { shadowSymbol = true, symbolShade = true, symbolBloom = true, symbol = true },
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
      expectTrue(style .. " has inactive " .. name, activeNames[name] ~= true or (style == "finder" and name == "bracketLocked"))
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
expect("finder: no glints", glintsShown(), false)
expect("finder: no classic shade", LootSparkle.Shade():IsShown(), false)
expectTrue("finder: contact shadow shown", shown("shadow"))
r, g, b = layers.shadow:GetVertexColor()
expectColor("contact shadow is black, not category colored", { r, g, b }, { 0, 0, 0 })
r, g, b = layers.bracket:GetVertexColor()
expectColor("bracket core is whitened ore color", { r, g, b }, LootSparkle.Whiten({ 1.00, 0.60, 0.18 }, 0.25))
LootSparkle.SetState("ready", "ore")
expect("finder ready: snapped brackets", layers.bracket:GetWidth(), 56)
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
expectColor("arrow locked grey (core slightly whitened)", { r, g, b }, LootSparkle.Whiten({ 0.6, 0.6, 0.6 }, 0.2))
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
  if name ~= "shadow" then expect("glitter has no layer " .. name, shown(name), false) end
end
expectTrue("glitter keeps its contact shadow", shown("shadow"))
expectTrue("glitter: glints shown", glintsShown())
expectTrue("glitter: glints animate", LootSparkle.Glints()[1].animation:IsPlaying())
addon.Set("lootSparkleStyle", "finder")
expect("glints off after switch to finder", glintsShown(), false)
expect("glint animation stopped", LootSparkle.Glints()[1].animation:IsPlaying(), false)
addon.Set("lootSparkleStyle", "aura")
expectTrue("classic aura keeps glints", glintsShown())
expectTrue("classic aura keeps shade", LootSparkle.Shade():IsShown())

-- Aufräumen
LootSparkle.Release()
expect("released after section 7", LootSparkle.AttachedTo(), nil)
addon.Set("lootSparkleStyle", "aura")

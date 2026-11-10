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
expect("standard style is aura", LootSparkle.CurrentStyle(), "aura")
expect("6 sparkle styles exist", #LootSparkle.STYLES, 6)

local expectedStyles = { aura = true, beam = true, sigil = true, ripple = true, sparkle = true, subtle = true }
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

local allLayerNames = { "halo", "ring1", "ring2", "arcs", "beam", "sigil" }
local layers = LootSparkle.Layers()
expectTrue("layers table returned", layers ~= nil)
for _, name in ipairs(allLayerNames) do
  expectTrue("layer texture exists: " .. name, layers[name] ~= nil)
end
expectTrue("ring alias exists", layers.ring == layers.ring1)
expectTrue("flash layer exists", layers.flash ~= nil)

local expectedActive = {
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

  -- Prüfe, dass die erwarteten Layer aktiv sind
  for _, name in ipairs(allLayerNames) do
    if exp[name] then
      expectTrue(style .. " has active " .. name, activeNames[name] == true)
      expectTrue(style .. " layer is shown: " .. name, layers[name]:IsShown())
      local r, g, b = layers[name]:GetVertexColor()
      expectColor(style .. " layer color " .. name, { r, g, b }, { 0.40, 1.00, 0.42 })
    else
      expectTrue(style .. " has inactive " .. name, activeNames[name] ~= true)
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

-- Aufräumen
LootSparkle.Release()
expect("released after section 7", LootSparkle.AttachedTo(), nil)
addon.Set("lootSparkleStyle", "aura")

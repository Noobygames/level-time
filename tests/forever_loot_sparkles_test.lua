-- Beute-Glitzer (WoW Forever): Quest-Gegenstände per CVar, Glitzern beim Annähern an Erz, Kräuter, Quest-Objekte
-- und Leichen mit Beute über das Soft-Targeting. Aus = keine CVar angefasst, ausgeschaltet kommen die Werte des
-- Spielers zurück, in der Kampfsperre wird nichts geändert.
wow.loadExtractor()  -- Debug-Log und Profiler liegen im lokalen Data Extractor
local LootSparkles, LootSparkle, LootTarget = addon.LootSparkles, addon.LootSparkle, addon.LootTarget
local L = addon.L

expect("ohne CVar: kein Quest-Gegenstand-Glitzern", LootSparkles.HasQuestItemSparkle(), false)

-- Client-Funktionen fürs Soft-Targeting (stehen nicht im Stub)
local plates = {}     -- Einheit -> Namensplakette
local cursors = {}    -- Einheit -> Zeiger-Datei (SetUnitCursorTexture)
local objects = {}    -- Einheit -> Welt-Objekt?
local inRange = {}    -- Einheit -> UnitIsInInteractRange
local loot = {}       -- GUID -> { hasLoot, canLoot }
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
  outlineModeShowLootEffectWhenDisabled = "0", graphicsQuality = "5",
  SoftTargetInteract = "1", SoftTargetIconGameObject = "0", SoftTargetInteractRange = "10.000000",
  SoftTargetInteractArc = "0", SoftTargetInteractOnlyInRange = "0", SoftTargetNameplateInteract = "0",
}
local cvars = wow.state.cvars
local original = {}
for name, value in pairs(cvars) do original[name] = value end

wow.login({ level = 20 })
expectTrue("verfügbar: Quest-Gegenstände", LootSparkles.HasQuestItemSparkle())
expectTrue("verfügbar: Soft-Targeting", LootSparkles.CanSoftTarget())
for name, value in pairs(original) do expect("aus: " .. name .. " unberührt", cvars[name], value) end
expect("aus: nichts gemerkt", LevelTimerDB.cvarOriginals, nil)

---------------------------------------------------------------------------
-- Quest-Gegenstände
---------------------------------------------------------------------------
addon.Set("lootSparkleQuestItems", true)
expect("an: Glitzern der Quest-Gegenstände", cvars.outlineModeShowLootEffectWhenDisabled, "1")

-- Grafik-Voreinstellung setzt die CVar zurück: kurz danach wieder an
cvars.outlineModeShowLootEffectWhenDisabled = "0"
wow.fire("CVAR_UPDATE", "graphicsQuality")
wow.runTimers()
expect("nach Voreinstellung wieder an", cvars.outlineModeShowLootEffectWhenDisabled, "1")

-- im Kampf nur vormerken, nach dem Kampf nachholen
cvars.outlineModeShowLootEffectWhenDisabled = "0"
wow.state.combatLockdown = true
wow.fire("CVAR_UPDATE", "GRAPHICSQUALITY")
wow.runTimers()
expect("Kampfsperre: nicht geändert", cvars.outlineModeShowLootEffectWhenDisabled, "0")
wow.state.combatLockdown = false
wow.fire("PLAYER_REGEN_ENABLED")
expect("nach dem Kampf nachgeholt", cvars.outlineModeShowLootEffectWhenDisabled, "1")

-- fremde CVar: nichts geplant
wow.timers = {}
wow.fire("CVAR_UPDATE", "cameraDistanceMaxZoomFactor")
expect("andere CVar: kein Nachsetzen geplant", #wow.timers, 0)

wow.printed = {}
addon.Set("lootSparkleQuestItems", false)
expect("aus: Wert des Spielers zurück", cvars.outlineModeShowLootEffectWhenDisabled, "0")
expectTrue("aus: Hinweis auf Neustart", (wow.printed[#wow.printed] or ""):find(L.LOOT_SPARKLE_RESTART, 1, true))
wow.printed = {}
addon.ApplySettings()
expect("erneut angewendet: kein zweiter Hinweis", #wow.printed, 0)

---------------------------------------------------------------------------
-- Erz in der Nähe
---------------------------------------------------------------------------
local SOFT = LootTarget.UNIT
local plate = CreateFrame("Frame")
objects[SOFT] = true
cursors[SOFT] = "Interface\\Cursor\\Mine"
inRange[SOFT] = false
wow.state.units[SOFT] = { name = "Kupfervorkommen" }

addon.Set("lootSparkleOre", true)
expect("Soft-Targeting immer an", cvars.SoftTargetInteract, "3")
expect("Symbole auf Objekten an", cvars.SoftTargetIconGameObject, "1")
expect("Reichweite", cvars.SoftTargetInteractRange, "60")
expect("rundum", cvars.SoftTargetInteractArc, "2")
expect("Erz: Plakette eingeschaltet", cvars.SoftTargetNameplateInteract, "1")
expect("Plakette noch nicht da: kein Glitzern", LootSparkle.AttachedTo(), nil)

-- die Plakette kommt
plates[SOFT] = plate
plates.nameplate1 = plate
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
expect("Glitzern an der Plakette", LootSparkle.AttachedTo(), plate)
expect("außer Reichweite: gedämpft", LootSparkle.State(), LootTarget.FAR)

local sparkleFrame = wow.findFrame(function(frame)
  return frame._parent == plate and rawget(frame, "_animationGroups") ~= nil
end)
expectTrue("Glitzer-Frame an der Plakette", sparkleFrame ~= nil)
expect("Glitzer sichtbar", sparkleFrame:IsShown(), true)
expect("blendet ein", sparkleFrame._animationGroups[1]:IsPlaying(), true)
-- Funken gehören nur zu manchen Stilen (Standard Zielsucher hat keine)
addon.Set("lootSparkleStyle", "glitter")
local glintGroups = 0
wow.findFrame(function(frame)
  for _, group in ipairs(rawget(frame, "_animationGroups") or {}) do
    if group:GetScript("OnLoop") and group:IsPlaying() then glintGroups = glintGroups + 1 end
  end
  return false
end)
expectTrue("Funken laufen als Animationen", glintGroups >= 1)

-- in Reichweite: erst nach Bestätigung hell (kein Flackern am Rand)
inRange[SOFT] = true
wow.update(0.25)
expect("ein Blick: noch gedämpft", LootSparkle.State(), LootTarget.FAR)
wow.update(0.25)
expect("bestätigt: hell", LootSparkle.State(), LootTarget.READY)

-- ausgegraut (Fertigkeit zu niedrig): grau, vorsichtiger bestätigt
cursors[SOFT] = "Interface\\Cursor\\UnableMine"
wow.update(0.25)
wow.update(0.25)
expect("gesperrt: noch nicht bestätigt", LootSparkle.State(), LootTarget.READY)
wow.update(0.25)
expect("gesperrt: grau", LootSparkle.State(), LootTarget.LOCKED)

-- Atlas statt Datei (neuere Zeiger)
cursors[SOFT] = nil
SetUnitCursorTexture = function(texture)
  texture:SetTexture(nil)
  texture._atlas = "Cursor_Mine_64"
  return true
end
expect("Atlas: Erz erkannt", (LootTarget.Classify(SOFT)), LootTarget.ORE)
SetUnitCursorTexture = function(texture, unit)
  texture:SetTexture(cursors[unit])
  texture._atlas = nil
  return cursors[unit] ~= nil
end

-- Kraut, aber Kräuter aus: kein Glitzern, Plakette wieder wie beim Spieler
cursors[SOFT] = "Interface\\Cursor\\GatherHerbs"
wow.fire("PLAYER_SOFT_INTERACT_CHANGED", "GameObject-1", "GameObject-2")
expect("Kraut ohne Schalter: kein Glitzern", LootSparkle.AttachedTo(), nil)
expect("Plakette auf Wert des Spielers", cvars.SoftTargetNameplateInteract, "0")
expect("Glitzer versteckt", sparkleFrame:IsShown(), false)

addon.Set("lootSparkleHerbs", true)
expect("Kräuter an: Plakette an", cvars.SoftTargetNameplateInteract, "1")
expect("Kraut glitzert", LootSparkle.AttachedTo(), plate)

-- NPC als Ziel: nichts
objects[SOFT] = false
cursors[SOFT] = "Interface\\Cursor\\Speak"
wow.fire("PLAYER_SOFT_INTERACT_CHANGED", "GameObject-2", "Creature-3")
expect("NPC: kein Glitzern", LootSparkle.AttachedTo(), nil)
expect("NPC: keine Plakette", cvars.SoftTargetNameplateInteract, "0")

---------------------------------------------------------------------------
-- Quest-Objekt und Leiche
---------------------------------------------------------------------------
wow.state.questLog = { { questID = 77, title = "Vorräte sichern", objectives = { { text = "Vorräte: 0/3", finished = false } } } }
wow.fire("QUEST_LOG_UPDATE")
objects[SOFT] = true
cursors[SOFT] = "Interface\\Cursor\\PickUp"
wow.state.units[SOFT] = { name = "Bündel mit Vorräte" }
expect("Quest-Objekt erkannt", (LootTarget.Classify(SOFT)), LootTarget.QUEST)
wow.fire("PLAYER_SOFT_INTERACT_CHANGED", "Creature-3", "GameObject-4")
expect("Quest-Objekte aus: kein Glitzern", LootSparkle.AttachedTo(), nil)
addon.Set("lootSparkleQuestObjects", true)
expect("Quest-Objekt glitzert", LootSparkle.AttachedTo(), plate)
-- Ziel erfüllt: kein Quest-Objekt mehr
wow.state.questLog[1].objectives[1].finished = true
wow.fire("QUEST_LOG_UPDATE")
expect("Ziel erfüllt: nicht mehr Quest", (LootTarget.Classify(SOFT)), nil)
wow.state.questLog = {}
wow.fire("QUEST_LOG_UPDATE")

objects[SOFT] = false
cursors[SOFT] = "Interface\\Cursor\\LootAll"
wow.state.units[SOFT] = { name = "Kobold", dead = true, guid = "Creature-9" }
loot["Creature-9"] = { true, true }
addon.Set("lootSparkleCorpses", true)
wow.fire("PLAYER_SOFT_INTERACT_CHANGED", "GameObject-4", "Creature-9")
expect("Leiche mit Beute glitzert", LootSparkle.AttachedTo(), plate)
loot["Creature-9"] = { false, false }
wow.fire("LOOT_CLOSED")
expect("geplündert: kein Glitzern", LootSparkle.AttachedTo(), nil)

-- leergeplündert, aber häutbar (Roadmap 479): glitzert nur mit erlerntem Kürschnern
UNIT_SKINNABLE_LEATHER, UNIT_SKINNABLE_ROCK = "Häutbar", "Benötigt Bergbau"
local tooltipLines = { { leftText = "Kobold" }, { leftText = "Häutbar" } }
C_TooltipInfo = { GetUnit = function() return { lines = tooltipLines } end }
expect("häutbar ohne Kürschnern: nichts", (LootTarget.Classify(SOFT)), nil)
wow.state.knownSpells = { [8613] = true }
expect("häutbar mit Kürschnern: Leiche", (LootTarget.Classify(SOFT)), LootTarget.CORPSE)
tooltipLines[2] = { leftText = "Benötigt Bergbau" }
expect("abbaubare Leiche ohne Bergbau: nichts", (LootTarget.Classify(SOFT)), nil)
wow.state.knownSpells = { [2575] = true }
expect("abbaubare Leiche mit Bergbau: Leiche", (LootTarget.Classify(SOFT)), LootTarget.CORPSE)
tooltipLines[2] = { leftText = wow.SECRET }
expect("geheime Zeile: nichts", (LootTarget.Classify(SOFT)), nil)
wow.state.knownSpells, C_TooltipInfo = nil, nil

-- fremde Beute (z.B. Gruppe, nicht berechtigt): nichts
loot["Creature-9"] = { true, false }
expect("nicht berechtigt: keine Leiche", (LootTarget.Classify(SOFT)), nil)

-- geheime Werte: nie glitzern, kein Fehler
UnitIsGameObject = function() return wow.SECRET end
expect("geheim: nichts", (LootTarget.Classify(SOFT)), nil)
UnitIsGameObject = function(unit) return objects[unit] == true end

---------------------------------------------------------------------------
-- Kurz kein Interaktionsziel (Roadmap 397): die Plakette bleibt offen, kommt ein Ziel zurück, keine CVar-Änderung
---------------------------------------------------------------------------
objects[SOFT] = true
cursors[SOFT] = "Interface\\Cursor\\Mine"
wow.fire("PLAYER_SOFT_INTERACT_CHANGED", "Creature-9", "GameObject-5")
expect("Erz: Plakette an", cvars.SoftTargetNameplateInteract, "1")
local soft = wow.state.units[SOFT]
wow.state.units[SOFT] = nil
cursors[SOFT] = nil
wow.fire("PLAYER_SOFT_INTERACT_CHANGED", "GameObject-5", nil)
expect("kein Ziel: Plakette bleibt kurz offen", cvars.SoftTargetNameplateInteract, "1")
wow.state.units[SOFT] = soft
cursors[SOFT] = "Interface\\Cursor\\Mine"
wow.fire("PLAYER_SOFT_INTERACT_CHANGED", nil, "GameObject-5")
wow.runTimers()
expect("Ziel zurück: Plakette blieb offen (kein Zurücksetzen)", cvars.SoftTargetNameplateInteract, "1")
wow.state.units[SOFT] = nil
cursors[SOFT] = nil
wow.fire("PLAYER_SOFT_INTERACT_CHANGED", "GameObject-5", nil)
wow.runTimers()
expect("dauerhaft kein Ziel: Plakette zu", cvars.SoftTargetNameplateInteract, "0")
wow.state.units[SOFT] = soft

---------------------------------------------------------------------------
-- Kampf
---------------------------------------------------------------------------
objects[SOFT] = true
cursors[SOFT] = "Interface\\Cursor\\Mine"
wow.fire("PLAYER_SOFT_INTERACT_CHANGED", "Creature-9", "GameObject-5")
expect("vor dem Kampf: Plakette an", cvars.SoftTargetNameplateInteract, "1")
wow.fire("PLAYER_REGEN_DISABLED")
expect("Kampfbeginn: Plakette zu", cvars.SoftTargetNameplateInteract, "0")
wow.state.combatLockdown = true
wow.fire("PLAYER_SOFT_INTERACT_CHANGED", "GameObject-5", "GameObject-6")
expect("Kampfsperre: Plakette bleibt zu", cvars.SoftTargetNameplateInteract, "0")
addon.Set("lootSparkleOre", false)
addon.Set("lootSparkleHerbs", false)
addon.Set("lootSparkleQuestObjects", false)
addon.Set("lootSparkleCorpses", false)
expect("Kampfsperre: nichts zurückgesetzt", cvars.SoftTargetInteract, "3")
wow.state.combatLockdown = false
wow.fire("PLAYER_REGEN_ENABLED")
for name, value in pairs(original) do expect("alles aus: " .. name .. " zurück", cvars[name], value) end
expect("alles aus: nichts mehr gemerkt", LevelTimerDB.cvarOriginals, nil)
expect("alles aus: kein Glitzern", LootSparkle.AttachedTo(), nil)

---------------------------------------------------------------------------
-- Einmal-CVars gehören danach dem Spieler
---------------------------------------------------------------------------
addon.Set("lootSparkleOre", true)
expect("wieder an: Soft-Targeting", cvars.SoftTargetInteract, "3")
cvars.SoftTargetInteract = "0"  -- Spieler schaltet die Interaktionstaste selbst aus
addon.ApplySettings()
wow.fire("PLAYER_ENTERING_WORLD")
expect("bleibt aus, wie der Spieler es wollte", cvars.SoftTargetInteract, "0")
expect("eigene CVar neu gesetzt", cvars.SoftTargetInteractRange, "60")
addon.Set("lootSparkleOre", false)
expect("aus: Original des Spielers", cvars.SoftTargetInteract, "1")

-- Größe der Funken
addon.Set("lootSparkleScale", 1.5)
expectNear("Größe", LootSparkle.CurrentScale(), 1.5)
addon.Set("lootSparkleScale", 9)
expectNear("Größe begrenzt", LootSparkle.CurrentScale(), LootSparkle.MAX_SCALE)

-- /lt debug check: Eintrag für das Ziel, ohne Fehler
SlashCmdList.LEVELTIMER("debug check")
local found = false
for _, line in ipairs(LevelTimerDebugLog and LevelTimerDebugLog.lines or {}) do
  if type(line) == "string" and line:find("lootSparkles.target", 1, true) then found = true end
end
expectTrue("Prüfeintrag geschrieben", found)

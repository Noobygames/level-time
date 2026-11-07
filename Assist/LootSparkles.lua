-- Beute-Glitzer (Komfort > Oberfläche > Beute-Glitzer), alles einzeln schaltbar und aus, bis eingeschaltet.
-- Alle CVars laufen über CVars.lua: beim ersten Setzen wird der Wert des Spielers gemerkt, beim Ausschalten
-- zurückgesetzt; aus = nichts angefasst. Geprüft gegen Ketho/BlizzardInterfaceResources (Resources/CVars.lua je
-- Client) und wow-ui-source (Blizzard_SettingsDefinitions_Frame Controls/Accessibility, Blizzard_NamePlates):
--
-- 1. Quest-Gegenstände (lootSparkleQuestItems, nur WoW Forever): CVar outlineModeShowLootEffectWhenDisabled = 1
--    ("When Outline Mode is disabled, replace passive outlines with loot sparkles", Account, gibt es nur in
--    Forever). Grafik-Voreinstellungen setzen sie zurück, daher nach CVAR_UPDATE der Grafikstufe (Name im ersten
--    Argument, wie Blizzards NamePlateDriverMixin es liest) mit kurzer Verzögerung erneut. Abschalten wirkt erst
--    nach einem Neustart des Spiels (/reload reicht nicht): Chatzeile.
--
-- 2. Annäherung an Erz, Kräuter, Quest-Objekte und Leichen mit Beute (lootSparkleOre/Herbs/QuestObjects/Corpses):
--    Das Soft-Targeting wählt immer ein Interaktionsziel ("softinteract", PLAYER_SOFT_INTERACT_CHANGED) und kann
--    ihm eine Namensplakette geben (SoftTargetNameplateInteract). Was es ist, sagt LootTarget.lua; das Glitzern
--    (LootSparkle.lua) hängt an dieser Plakette. Die Plakette wird nur für Ziele eingeschaltet, die glitzern
--    sollen, sonst gilt wieder der Wert des Spielers (NPCs, Briefkästen bekommen also keine).
--    Gesetzt, solange einer dieser Schalter an ist (alle Clients, Account; Forever-only übergeht CVars.lua):
--      SoftTargetInteract 3 (immer, Enum.SoftTargetEnableFlags.Any) und SoftTargetIconGameObject 1 (ohne bekommen
--        Welt-Objekte keine Plakette) nur beim ersten Einschalten; schaltet der Spieler sie danach selbst aus,
--        bleibt es aus (dann glitzert nichts)
--      SoftTargetInteractRange 60 (das Spiel begrenzt selbst), SoftTargetInteractArc 2 (rundum),
--      SoftTargetInteractOnlyInRange 0 (auch Ziele außer Reichweite, nur Forever)
--    SoftTargetInteract und SoftTargetInteractRange sind geschützt (secure): CVar-Änderungen nur außerhalb der
--    Kampfsperre, sonst nach dem Kampf. Zu Kampfbeginn geht die Plakette zu (sonst behielte jede Leiche eine).
--
-- Andere Addons, die dieselben CVars steuern (ForeverLootSparkles, Lueur): dann tut dieses Modul nichts und sagt es
-- einmal je Login im Chat, statt sich mit ihnen abzuwechseln.
local _, ns = ...

local LootSparkles = {}
ns.LootSparkles = LootSparkles

local L = ns.L
local LootTarget, LootSparkle = ns.LootTarget, ns.LootSparkle

local QUEST_ITEM_CVAR = "outlineModeShowLootEffectWhenDisabled"
local ON = 1
-- Grafikänderungen, nach denen die Quest-Gegenstand-CVar erneut gesetzt wird (klein geschrieben)
local GRAPHICS_CVARS = {
  graphicsquality = true, raidgraphicsquality = true,
  graphicsoutlinemode = true, raidgraphicsoutlinemode = true,
  [QUEST_ITEM_CVAR:lower()] = true,
}
local GRAPHICS_DELAY = 1  -- Sekunden: die Voreinstellung schreibt mehrere CVars nacheinander
local LOGIN_RECHECK = 5   -- Sekunden: mit dem Account synchronisierte Einstellungen kommen evtl. später

local SOFT_TARGET_ALWAYS = "3"  -- Enum.SoftTargetEnableFlags.Any
-- nur beim ersten Einschalten gesetzt, danach gehören sie dem Spieler
local ONCE_CVARS = { SoftTargetInteract = SOFT_TARGET_ALWAYS, SoftTargetIconGameObject = ON }
-- gesetzt, solange ein Schalter an ist
local OWN_CVARS = { SoftTargetInteractRange = 60, SoftTargetInteractArc = 2, SoftTargetInteractOnlyInRange = 0 }
local PLATE_CVAR = "SoftTargetNameplateInteract"

-- Art des Ziels -> Einstellung
local KIND_SETTINGS = {
  [LootTarget.ORE] = "lootSparkleOre",
  [LootTarget.HERB] = "lootSparkleHerbs",
  [LootTarget.QUEST] = "lootSparkleQuestObjects",
  [LootTarget.CORPSE] = "lootSparkleCorpses",
}
local CONFLICTING_ADDONS = { "ForeverLootSparkles", "Lueur" }

local TICK_SECONDS = 0.2  -- Reichweite und Beute nachprüfen, nur solange ein Glitzern hängt oder erwartet wird
local PLATE_CLOSE_DELAY = 2  -- Sekunden ohne Interaktionsziel, bis die Plakette wieder auf den Wert des Spielers geht
local STATE_TICKS = 2     -- so oft muss ein neuer Zustand gesehen werden (kein Flackern am Reichweitenrand)
local LOCKED_TICKS = 3    -- "gesperrt" vorsichtiger bestätigen

local conflict           -- Name eines Addons, das dieselben CVars steuert, sonst nil
local writing = false    -- eigene CVar-Änderung läuft (CVAR_UPDATE ignorieren)
local pendingCVars = false  -- in der Kampfsperre nicht möglich gewesen
local recheckQueued = false
local plateOpen          -- Plakette für das Ziel eingeschaltet? nil = unbekannt, neu setzen
local waiting = false    -- Glitzern gewünscht, Plakette noch nicht da
local retarget = false   -- Ziel gewechselt: eine wiederverwendete Plakette zeigt das nicht von selbst
local plates = {}        -- sichtbare Plaketten: [Einheit] = Plakette (beim Entfernen evtl. nicht mehr abfragbar)
local candidate, candidateTicks  -- neuer Zustand, der noch bestätigt wird

local function read(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, value = pcall(fn, ...)
  if not ok or ns.IsSecret(value) then return nil end
  return value
end

local function isAddOnLoaded(name)
  local check = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
  return read(check, name) == true
end

-- Eigene CVar-Änderungen lösen CVAR_UPDATE synchron aus; das eigene Echo wird übergangen
local function withWrites(fn, ...)
  writing = true
  local ok, err = pcall(fn, ...)
  writing = false
  if not ok then error(err, 0) end
end

function LootSparkles.HasQuestItemSparkle()
  return ns.CVars.Exists(QUEST_ITEM_CVAR)
end

function LootSparkles.CanSoftTarget()
  return LootTarget.IsAvailable() and ns.CVars.Exists("SoftTargetInteract")
end

function LootSparkles.Conflict()
  return conflict
end

local function anyKindOn(db)
  for _, setting in pairs(KIND_SETTINGS) do
    if db[setting] == true then return true end
  end
  return false
end

local function softTargetWanted()
  local db = ns.db
  return db ~= nil and conflict == nil and LootSparkles.CanSoftTarget() and anyKindOn(db)
end

---------------------------------------------------------------------------
-- 1. Quest-Gegenstände
---------------------------------------------------------------------------
local function applyQuestItems()
  if conflict or not ns.db or not LootSparkles.HasQuestItemSparkle() then return end
  if InCombatLockdown() then
    pendingCVars = true
    return
  end
  if ns.db.lootSparkleQuestItems == true then
    withWrites(ns.CVars.Override, QUEST_ITEM_CVAR, ON)
    return
  end
  local wasOn = ns.CVars.Get(QUEST_ITEM_CVAR) == tostring(ON)
  local restored = false
  withWrites(function() restored = ns.CVars.Restore(QUEST_ITEM_CVAR) end)
  -- der Client zeichnet das Glitzern bis zum Neustart weiter
  if restored and wasOn and ns.CVars.Get(QUEST_ITEM_CVAR) ~= tostring(ON) then ns.Print(L.LOOT_SPARKLE_RESTART) end
end

local function recheckQuestItems(delay)
  if recheckQueued then return end
  recheckQueued = true
  C_Timer.After(delay, function()
    recheckQueued = false
    applyQuestItems()
  end)
end

---------------------------------------------------------------------------
-- 2. Glitzern beim Annähern
---------------------------------------------------------------------------

-- Plakette des Interaktionsziels an (open) oder auf den Wert des Spielers zurück
local closeToken = 0  -- zählt hoch bei jeder Entscheidung; ein verzögertes Schließen gilt nur ohne neuere

local function setPlate(open)
  closeToken = closeToken + 1
  if open == plateOpen or InCombatLockdown() then return end
  plateOpen = open
  if open then
    withWrites(ns.CVars.Override, PLATE_CVAR, ON)
  else
    withWrites(ns.CVars.Restore, PLATE_CVAR)
  end
end

-- Ohne Interaktionsziel ist keine Plakette zu sehen: Schließen darf warten (Roadmap 397). Wer zwischen zwei
-- Leichen oder Erzen kurz kein Ziel hat, schaltet die CVar sonst bei jedem Schritt zweimal um (CVAR_UPDATE).
local function closePlateSoon()
  if plateOpen ~= true then return setPlate(false) end
  closeToken = closeToken + 1
  local token = closeToken
  C_Timer.After(PLATE_CLOSE_DELAY, function()
    if token == closeToken then setPlate(false) end
  end)
end

local function hasInteractTarget()
  local exists = UnitExists(LootTarget.UNIT)
  return ns.IsSecret(exists) or exists == true
end

local function usablePlate(plate)
  if not plate or ns.IsSecret(plate) or (plate.IsForbidden and plate:IsForbidden()) then return nil end
  return plate
end

-- Plakette des Ziels; für Welt-Objekte liefert GetNamePlateForUnit("softinteract") sie evtl. nicht, dann die
-- sichtbare Plakette, die das Ziel ist oder ein Welt-Objekt (Objekte bekommen nur über diese CVar eine)
local function findPlate()
  local plate = usablePlate(read(C_NamePlate.GetNamePlateForUnit, LootTarget.UNIT))
  if plate then return plate end
  for unit, candidatePlate in pairs(plates) do
    if read(UnitIsUnit, unit, LootTarget.UNIT) == true or read(UnitIsGameObject, unit) == true then
      return usablePlate(candidatePlate)
    end
  end
  return nil
end

local function release()
  LootSparkle.Release()
  waiting, candidate = false, nil
end

-- Ein neuer Zustand gilt erst, wenn er mehrmals hintereinander gesehen wurde
local function proposeState(state)
  if state == LootSparkle.State() then
    candidate = nil
    return
  end
  if candidate ~= state then
    candidate, candidateTicks = state, 1
    return
  end
  candidateTicks = candidateTicks + 1
  if candidateTicks >= (state == LootTarget.LOCKED and LOCKED_TICKS or STATE_TICKS) then
    candidate = nil
    LootSparkle.SetState(state)
  end
end

local function evaluate()
  if not softTargetWanted() then
    release()
    return
  end
  local kind, blocked = LootTarget.Classify(LootTarget.UNIT)
  local wanted = kind ~= nil and ns.db[KIND_SETTINGS[kind]] == true
  if wanted or hasInteractTarget() then setPlate(wanted) else closePlateSoon() end
  if not wanted then
    release()
    return
  end
  local plate = findPlate()
  if not plate then
    -- gerade eingeschaltet: NAME_PLATE_UNIT_ADDED folgt
    LootSparkle.Release()
    waiting = true
    return
  end
  waiting = false
  local state = LootTarget.State(LootTarget.UNIT, blocked)
  if LootSparkle.AttachedTo() ~= plate or retarget then
    retarget, candidate = false, nil
    LootSparkle.Attach(plate, state)
    ns.Debug("sparkle", "%s target", kind)
  else
    proposeState(state)
  end
end

local function applySoftTarget()
  if conflict or not ns.db or not LootSparkles.CanSoftTarget() then return end
  if InCombatLockdown() then
    pendingCVars = true
    if not softTargetWanted() then release() end
    return
  end
  local CVars = ns.CVars
  plateOpen = nil
  if softTargetWanted() then
    withWrites(function()
      for name, value in pairs(ONCE_CVARS) do
        if not CVars.IsOverridden(name) then CVars.Override(name, value) end
      end
      for name, value in pairs(OWN_CVARS) do CVars.Override(name, value) end
    end)
    evaluate()
    return
  end
  release()
  withWrites(function()
    for name in pairs(ONCE_CVARS) do CVars.Restore(name) end
    for name in pairs(OWN_CVARS) do CVars.Restore(name) end
    CVars.Restore(PLATE_CVAR)
  end)
end

local function applyAll()
  applyQuestItems()
  applySoftTarget()
end

---------------------------------------------------------------------------
-- Ereignisse
---------------------------------------------------------------------------
ns.OnLogin(function()
  conflict = nil
  for _, name in ipairs(CONFLICTING_ADDONS) do
    if isAddOnLoaded(name) then conflict = name end
  end
  local db = ns.db
  if conflict and (db.lootSparkleQuestItems == true or anyKindOn(db)) then
    ns.Print(string.format(L.LOOT_SPARKLE_CONFLICT, conflict))
  end
  recheckQuestItems(LOGIN_RECHECK)
end)

ns.RegisterApply(applyAll)

-- nach jedem Ladebildschirm: mit dem Account synchronisierte CVars können die eigenen überschrieben haben
ns.RegisterEvent("PLAYER_ENTERING_WORLD", function()
  if ns.db then applyAll() end
end)

ns.RegisterEvent("CVAR_UPDATE", function(name)
  if writing or not ns.db or ns.db.lootSparkleQuestItems ~= true then return end
  if type(name) == "string" and not ns.IsSecret(name) and GRAPHICS_CVARS[name:lower()] then
    recheckQuestItems(GRAPHICS_DELAY)
  end
end)

-- Laut warcraft.wiki.gg (InCombatLockdown) greift die Sperre erst nach PLAYER_REGEN_DISABLED: Plakette noch zu
ns.RegisterEvent("PLAYER_REGEN_DISABLED", function()
  if softTargetWanted() then setPlate(false) end
end)

ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if pendingCVars then
    pendingCVars = false
    applyAll()
  elseif softTargetWanted() then
    plateOpen = nil
    evaluate()
  end
end)

ns.RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED", function(oldTarget, newTarget)
  if not softTargetWanted() then return end
  if not ns.IsSecret(oldTarget) and not ns.IsSecret(newTarget) and oldTarget and newTarget and oldTarget ~= newTarget then
    retarget = LootSparkle.AttachedTo() ~= nil
  end
  evaluate()
end)

ns.RegisterEvent("NAME_PLATE_UNIT_ADDED", function(unit)
  if not softTargetWanted() or type(unit) ~= "string" then return end
  plates[unit] = read(C_NamePlate.GetNamePlateForUnit, unit)
  evaluate()
end)

ns.RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(unit)
  local plate = plates[unit]
  plates[unit] = nil
  if plate and plate == LootSparkle.AttachedTo() then
    release()
    waiting = softTargetWanted()
  end
end)

-- Leiche geplündert: hat sie noch Beute?
ns.RegisterEvent("LOOT_CLOSED", function()
  if LootSparkle.AttachedTo() or waiting then evaluate() end
end)

ns.Every(TICK_SECONDS, function()
  if LootSparkle.AttachedTo() or waiting then evaluate() end
end)

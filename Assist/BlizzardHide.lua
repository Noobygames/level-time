-- Blizzard-Oberfläche ausblenden (Roadmap 371): Liste der Blizzard-HUD-Elemente, die sich einzeln ausblenden lassen
-- (Komfort > Oberfläche > "Blizzard-Oberfläche" und im Edit-Modus direkt am Element, UI/BlizzardOverlays.lua).
-- Einstellung hiddenBlizzardFrames = { [id] = true } (optional, nil = nichts ausgeblendet; unbekannte Ids zählen nicht).
--
-- Jeder Eintrag: id, label (Locale-Schlüssel; mit number ein Format wie "Aktionsleiste %d"), frames() -> Liste
-- (erster gezeigter Frame bekommt die Fläche im Edit-Modus), optional buttons() (weitere Knöpfe ohne Maus), protected
-- (enthält geschützte Knöpfe), events (statt Alpha: diese Ereignisse am ersten Frame abmelden), client() (kann es den
-- Frame in diesem Client geben; ohne = alle), setting (vorhandene Einstellung eines anderen Moduls, z.B.
-- hideStanceBar: dann schaltet BlizzardHide nur diese Einstellung, das Ausblenden macht das andere Modul).
-- Frames werden erst bei Bedarf über globale Namen und Unterschlüssel gesucht (fehlende fallen weg, je Client anders;
-- geprüft gegen Gethe/wow-ui-source live, classic_era, classic_anniversary, forever).
--
-- Ausblenden: Alpha 0 (Lib/Overrides.lua, stellt den gemerkten Wert her) und Maus aus am Frame, an den Knöpfen und an
-- den Unterframes bis CHILD_DEPTH Ebenen tief, damit unsichtbare Knöpfe nicht klickbar bleiben. Kein Hide, kein
-- SetParent, kein UnregisterUnitWatch und kein Blizzard-Layout-Aufruf: die meisten dieser Frames sind Systeme von
-- Blizzards Edit Mode (auch in Classic) oder werden von Blizzard umgehängt (Zauberleiste an den Spielerrahmen).
-- Setzt Blizzard selbst Alpha (Deckkraft aus dem Edit Mode, Reichweite der Gruppenrahmen, Ausblenden der
-- Zauberleiste), setzt ein hooksecurefunc auf SetAlpha sofort wieder 0 und merkt sich Blizzards Wert für später.
-- Im Kampf wird nichts geändert (EnableMouse an geschützten Frames ist dann gesperrt): nach PLAYER_REGEN_ENABLED.
-- Grenze: Knöpfe, die Blizzard nach dem Ausblenden neu anlegt (Pools), bleiben klickbar bis zum nächsten Anwenden.
local _, ns = ...
local Client = ns.Client

local BlizzardHide = {}
ns.BlizzardHide = BlizzardHide

local HIDDEN = 0
local CHILD_DEPTH = 2
local ACTION_BUTTONS = 12
local PET_BUTTONS = 10
local PARTY_MEMBERS = 4
local BOSS_FRAMES = 8
local SETTING = "hiddenBlizzardFrames"

---------------------------------------------------------------------------
-- Frames suchen
---------------------------------------------------------------------------
local function asTable(value)
  if type(value) == "table" then return value end
end

-- Unterframe per Schlüssel (nur Tabellen; Stub-Frames liefern für unbekannte Schlüssel Funktionen)
local function child(frame, key)
  return frame and asTable(frame[key]) or nil
end

-- Erster vorhandener globaler Frame der Namen
local function first(...)
  local names = { ... }
  return function()
    for _, name in ipairs(names) do
      local frame = asTable(_G[name])
      if frame then return { frame } end
    end
    return {}
  end
end

-- Alle vorhandenen Frames mit Nummer: pattern wie "Boss%dTargetFrame"
local function numbered(pattern, count)
  return function()
    local list = {}
    for index = 1, count do
      local frame = asTable(_G[string.format(pattern, index)])
      if frame then table.insert(list, frame) end
    end
    return list
  end
end

-- Alle vorhandenen globalen Frames einer Namensliste
local function named(names)
  return function()
    local list = {}
    for _, name in ipairs(names) do
      local frame = asTable(_G[name])
      if frame then table.insert(list, frame) end
    end
    return list
  end
end

-- Erste Liste, die nicht leer ist
local function either(primary, fallback)
  return function()
    local list = primary()
    if #list > 0 then return list end
    return fallback()
  end
end

-- Gruppenmitglieder: Retail/Forever/Classic PartyFrame.MemberFrame1..4 (Pool), ältere Clients PartyMemberFrame1..4
local function partyMembers()
  local list = {}
  for index = 1, PARTY_MEMBERS do
    local member = child(asTable(_G.PartyFrame), "MemberFrame" .. index) or asTable(_G["PartyMemberFrame" .. index])
    if member then table.insert(list, member) end
  end
  return list
end

-- Gebietsname an der Minimap: MinimapCluster.ZoneTextButton (alle Clients), Classic auch MinimapZoneTextButton
local function zoneText()
  local button = child(asTable(_G.MinimapCluster), "ZoneTextButton") or asTable(_G.MinimapZoneTextButton)
  return { button }
end

-- Chatfenster samt Reiter und Knopfleiste
local function chatWindows()
  local list = {}
  for _, chatFrame in ipairs(ns.ChatWindows.All()) do
    table.insert(list, chatFrame)
    local name = type(chatFrame.GetName) == "function" and chatFrame:GetName()
    local tab = type(name) == "string" and asTable(_G[name .. "Tab"])
    if tab then table.insert(list, tab) end
    local buttonFrame = child(chatFrame, "buttonFrame")
    if buttonFrame then table.insert(list, buttonFrame) end
  end
  return list
end

-- Grafik der Hauptleiste: Endkappen (Greifen) und Rahmen an MainActionBar, Classic zusätzlich die alte MainMenuBar,
-- die dort nur noch als Grafik dient (MainActionBarOverrides.lua)
local function barArt()
  local list = {}
  local bar = asTable(_G.MainActionBar)
  for _, key in ipairs({ "EndCaps", "BorderArt" }) do
    local art = child(bar, key)
    if art then table.insert(list, art) end
  end
  if bar and asTable(_G.MainMenuBar) then table.insert(list, _G.MainMenuBar) end
  return list
end

local MICRO_BUTTONS = {
  "CharacterMicroButton", "ProfessionMicroButton", "PlayerSpellsMicroButton", "SpellbookMicroButton",
  "TalentMicroButton", "AchievementMicroButton", "QuestLogMicroButton", "HousingMicroButton", "GuildMicroButton",
  "SocialsMicroButton", "LFDMicroButton", "LFGMicroButton", "PVPMicroButton", "CollectionsMicroButton",
  "EJMicroButton", "StoreMicroButton", "MainMenuMicroButton", "HelpMicroButton", "WorldMapMicroButton",
}
local BAG_BUTTONS = {
  "MainMenuBarBackpackButton", "CharacterBag0Slot", "CharacterBag1Slot", "CharacterBag2Slot", "CharacterBag3Slot",
  "CharacterReagentBag0Slot", "KeyRingButton", "BagBarExpandToggle",
}

-- Was ein Client haben kann (für die Schalter in den Optionen; die werden beim Laden gebaut)
local function notEra() return not Client.IsClassicEra() end
local function modern() return Client.IsRetail() or Client.IsForever() end

local function statusBars(kind)
  return function() return ns.HideFrames.StatusBars(kind) end
end

-- Reihenfolge = Reihenfolge in den Optionen und im Debug-Log
BlizzardHide.ENTRIES = {
  { id = "player", label = "BLIZZ_FRAME_PLAYER", frames = first("PlayerFrame"), protected = true },
  { id = "target", label = "BLIZZ_FRAME_TARGET", frames = first("TargetFrame"), protected = true },
  { id = "focus", label = "BLIZZ_FRAME_FOCUS", frames = first("FocusFrame"), protected = true, client = notEra },
  { id = "party", label = "BLIZZ_FRAME_PARTY", frames = first("PartyFrame"), buttons = partyMembers, protected = true },
  { id = "pet", label = "BLIZZ_FRAME_PET", frames = first("PetFrame"), protected = true },
  { id = "boss", label = "BLIZZ_FRAME_BOSS", protected = true,
    frames = either(first("BossTargetFrameContainer"), numbered("Boss%dTargetFrame", BOSS_FRAMES)),
    buttons = numbered("Boss%dTargetFrame", BOSS_FRAMES) },
  -- Classic: Blizzard_ArenaUI lädt erst bei Bedarf (ADDON_LOADED wendet neu an)
  { id = "arena", label = "BLIZZ_FRAME_ARENA", frames = first("ArenaEnemyFramesContainer", "ArenaEnemyFrames"),
    protected = true, client = notEra },
  { id = "castBar", label = "BLIZZ_FRAME_CAST_BAR", frames = first("PlayerCastingBarFrame", "CastingBarFrame") },
  { id = "minimap", label = "BLIZZ_FRAME_MINIMAP", frames = first("MinimapCluster") },
  { id = "zoneText", label = "BLIZZ_FRAME_ZONE_TEXT", frames = zoneText },
  { id = "clock", label = "BLIZZ_FRAME_CLOCK", frames = first("TimeManagerClockButton") },
  { id = "calendar", label = "BLIZZ_FRAME_CALENDAR", frames = first("GameTimeFrame"), setting = "minimapHideCalendar",
    tip = "MINIMAP_HIDE_CALENDAR_TIP", available = function() return ns.MinimapTweaks.HasCalendarButton() end },
  { id = "buffs", label = "BLIZZ_FRAME_BUFFS", frames = first("BuffFrame") },
  { id = "debuffs", label = "BLIZZ_FRAME_DEBUFFS", frames = first("DebuffFrame") },
  -- Quest-Items im Tracker sind geschützte Knöpfe
  { id = "tracker", label = "BLIZZ_FRAME_TRACKER", protected = true,
    frames = first("ObjectiveTrackerFrame", "QuestWatchFrame", "WatchFrame") },
  { id = "chat", label = "BLIZZ_FRAME_CHAT", frames = chatWindows },
  { id = "chatButtons", label = "BLIZZ_FRAME_CHAT_BUTTONS", setting = "hideChatButtons", tip = "HIDE_CHAT_BUTTONS_TIP",
    frames = function() return named(ns.ChatWindows.BUTTONS)() end },
  { id = "mainBar", label = "BLIZZ_FRAME_MAIN_BAR", frames = first("MainActionBar"),
    buttons = numbered("ActionButton%d", ACTION_BUTTONS), protected = true },
  { id = "bar2", label = "BLIZZ_FRAME_BAR", number = 2, frames = first("MultiBarBottomLeft"),
    buttons = numbered("MultiBarBottomLeftButton%d", ACTION_BUTTONS), protected = true },
  { id = "bar3", label = "BLIZZ_FRAME_BAR", number = 3, frames = first("MultiBarBottomRight"),
    buttons = numbered("MultiBarBottomRightButton%d", ACTION_BUTTONS), protected = true },
  { id = "bar4", label = "BLIZZ_FRAME_BAR", number = 4, frames = first("MultiBarRight"),
    buttons = numbered("MultiBarRightButton%d", ACTION_BUTTONS), protected = true },
  { id = "bar5", label = "BLIZZ_FRAME_BAR", number = 5, frames = first("MultiBarLeft"),
    buttons = numbered("MultiBarLeftButton%d", ACTION_BUTTONS), protected = true },
  { id = "bar6", label = "BLIZZ_FRAME_BAR", number = 6, frames = first("MultiBar5"),
    buttons = numbered("MultiBar5Button%d", ACTION_BUTTONS), protected = true },
  { id = "bar7", label = "BLIZZ_FRAME_BAR", number = 7, frames = first("MultiBar6"),
    buttons = numbered("MultiBar6Button%d", ACTION_BUTTONS), protected = true },
  { id = "bar8", label = "BLIZZ_FRAME_BAR", number = 8, frames = first("MultiBar7"),
    buttons = numbered("MultiBar7Button%d", ACTION_BUTTONS), protected = true },
  { id = "barArt", label = "BLIZZ_FRAME_BAR_ART", frames = barArt },
  { id = "stance", label = "BLIZZ_FRAME_STANCE", frames = first("StanceBar"), setting = "hideStanceBar",
    tip = "HIDE_STANCE_BAR_TIP", available = function() return ns.HideFrames.HasStanceBar() end, advanced = true },
  { id = "petBar", label = "BLIZZ_FRAME_PET_BAR", frames = first("PetActionBar", "PetActionBarFrame"),
    buttons = numbered("PetActionButton%d", PET_BUTTONS), protected = true },
  { id = "microMenu", label = "BLIZZ_FRAME_MICRO_MENU", frames = first("MicroMenuContainer", "MicroMenu"),
    buttons = named(MICRO_BUTTONS), protected = true },
  { id = "bags", label = "BLIZZ_FRAME_BAGS", frames = first("BagsBar"), buttons = named(BAG_BUTTONS), protected = true },
  { id = "xpBar", label = "BLIZZ_FRAME_XP_BAR", frames = statusBars("experience"), setting = "hideBlizzardXpBar",
    tip = "HIDE_BLIZZARD_XP_BAR_TIP", available = function() return ns.HideFrames.HasXpBar() end },
  { id = "repBar", label = "BLIZZ_FRAME_REP_BAR", frames = statusBars("reputation"), setting = "hideBlizzardRepBar",
    tip = "HIDE_BLIZZARD_REP_BAR_TIP", available = function() return ns.HideFrames.HasRepBar() end, advanced = true },
  { id = "durability", label = "BLIZZ_FRAME_DURABILITY", frames = first("DurabilityFrame") },
  { id = "vehicleSeat", label = "BLIZZ_FRAME_VEHICLE_SEAT", frames = first("VehicleSeatIndicator"), client = modern },
  -- Sprechender Kopf: Blizzard blendet ihn mit Animationen ein; Ereignis abmelden statt Alpha (wie das Boss-Banner)
  { id = "talkingHead", label = "BLIZZ_FRAME_TALKING_HEAD", frames = first("TalkingHeadFrame"),
    events = { "TALKINGHEAD_REQUESTED" }, client = modern },
  { id = "lossOfControl", label = "BLIZZ_FRAME_LOSS_OF_CONTROL", frames = first("LossOfControlFrame") },
  -- Extra-Aktionsknopf und Zonenfähigkeit teilen sich Blizzards Behälter (ExtraAbilityContainer)
  { id = "extraAbilities", label = "BLIZZ_FRAME_EXTRA_ABILITIES",
    frames = first("ExtraAbilityContainer", "ExtraActionBarFrame"), buttons = first("ExtraActionButton1"),
    protected = true },
}

local byId = {}
for _, entry in ipairs(BlizzardHide.ENTRIES) do byId[entry.id] = entry end

function BlizzardHide.Get(id)
  return byId[id]
end

-- Eigene Id (nicht über die Einstellung eines anderen Moduls); nur diese stehen in hiddenBlizzardFrames
function BlizzardHide.IsOwnId(id)
  return byId[id] ~= nil and byId[id].setting == nil
end

-- Beschriftung in der aktuellen Sprache
function BlizzardHide.Label(entry)
  local text = ns.L[entry.label]
  return entry.number and string.format(text, entry.number) or text
end

-- Kann es das Element in diesem Client geben (Schalter in den Optionen)
function BlizzardHide.IsSupported(entry)
  return entry.client == nil or entry.client()
end

-- Vorhandene Frames jetzt
function BlizzardHide.Frames(entry)
  if not BlizzardHide.IsSupported(entry) then return {} end
  return entry.frames()
end

function BlizzardHide.IsAvailable(entry)
  return #BlizzardHide.Frames(entry) > 0
end

---------------------------------------------------------------------------
-- Einstellung
---------------------------------------------------------------------------
local EMPTY = {}

local function hiddenSet(db)
  local value = db and db[SETTING]
  return type(value) == "table" and value or EMPTY
end

function BlizzardHide.IsHidden(id, db)
  db = db or ns.db
  local entry = byId[id]
  if not entry or not db then return false end
  if entry.setting then return db[entry.setting] == true end
  return hiddenSet(db)[id] == true
end

-- Ausblenden an/aus; Einträge mit eigener Einstellung schalten diese
function BlizzardHide.SetHidden(id, hidden)
  local entry = byId[id]
  if not entry then return end
  hidden = hidden and true or false
  ns.Debug("overrides", "blizzard frame %s hidden %s", id, hidden)
  if entry.setting then
    ns.Set(entry.setting, hidden)
    return
  end
  local copy = {}
  for key, value in pairs(hiddenSet(ns.db)) do copy[key] = value end
  copy[id] = hidden or nil
  ns.Set(SETTING, next(copy) and copy or nil)
end

function BlizzardHide.Toggle(id)
  BlizzardHide.SetHidden(id, not BlizzardHide.IsHidden(id))
end

-- Schalter für die Optionen (OptionsBuilder.AddToggles): jeder Eintrag, den es im Client geben kann, auch die mit
-- eigener Einstellung (der Schalter setzt dann diese, setting = Zurücksetzen je Unterseite; tip = Erklärung dieser
-- Einstellung, available = Bedingung des anderen Moduls, advanced = nur mit allen Optionen)
function BlizzardHide.Toggles()
  local toggles = {}
  for _, entry in ipairs(BlizzardHide.ENTRIES) do
    table.insert(toggles, {
      label = entry.label,
      text = function() return BlizzardHide.Label(entry) end,
      tip = entry.tip or "BLIZZARD_FRAME_TIP",
      setting = entry.setting,
      advanced = entry.advanced,
      get = function(db) return BlizzardHide.IsHidden(entry.id, db) end,
      set = function(checked) BlizzardHide.SetHidden(entry.id, checked) end,
      available = function() return BlizzardHide.IsSupported(entry) and (entry.available == nil or entry.available()) end,
    })
  end
  return toggles
end

---------------------------------------------------------------------------
-- Ausblenden und herstellen (mit Zählern: ein Frame kann in zwei Einträgen stecken, z.B. Gebietsname in der Minimap)
---------------------------------------------------------------------------
local setAlpha = ns.Overrides.Alpha()
local setMouse = ns.Overrides.New(
  function(frame) return frame:IsMouseEnabled() end,
  function(frame, enabled) frame:EnableMouse(enabled) end)

local alphaRefs, mouseRefs = {}, {}  -- Objekt -> Anzahl Einträge, die es gerade ausblenden
local blizzardAlpha = {}             -- Objekt -> Alpha, das Blizzard während des Ausblendens setzen wollte
local alphaHooked = {}
local applied = {}                   -- Id -> { alpha = {...}, mouse = {...}, events = Frame } solange ausgeblendet
local pending = false

-- Setzt Blizzard Alpha, bleibt es 0 (der eigene Aufruf mit 0 endet hier sofort)
local function guardAlpha(object)
  if alphaHooked[object] or type(object.SetAlpha) ~= "function" then return end
  alphaHooked[object] = true
  hooksecurefunc(object, "SetAlpha", function(self, alpha)
    if not alphaRefs[self] or alpha == HIDDEN then return end
    blizzardAlpha[self] = alpha
    self:SetAlpha(HIDDEN)
  end)
end

local function hideAlpha(object)
  alphaRefs[object] = (alphaRefs[object] or 0) + 1
  if alphaRefs[object] > 1 then return end
  guardAlpha(object)
  setAlpha(object, true, HIDDEN)
end

local function restoreAlpha(object)
  alphaRefs[object] = (alphaRefs[object] or 1) - 1
  if alphaRefs[object] > 0 then return end
  alphaRefs[object] = nil
  setAlpha(object, false)
  local wanted = blizzardAlpha[object]
  blizzardAlpha[object] = nil
  if wanted then object:SetAlpha(wanted) end
end

local function hideMouse(object)
  mouseRefs[object] = (mouseRefs[object] or 0) + 1
  if mouseRefs[object] == 1 then setMouse(object, true, false) end
end

local function restoreMouse(object)
  mouseRefs[object] = (mouseRefs[object] or 1) - 1
  if mouseRefs[object] > 0 then return end
  mouseRefs[object] = nil
  setMouse(object, false)
end

local function isTexture(object)
  return type(object.GetObjectType) == "function" and object:GetObjectType() == "Texture"
end

-- Frame und Unterframes bis depth Ebenen tief, je einmal (Texturen haben keine Maus)
local function collectMouse(list, seen, object, depth)
  if seen[object] or isTexture(object) or type(object.EnableMouse) ~= "function" then return end
  seen[object] = true
  table.insert(list, object)
  if depth <= 0 or type(object.GetChildren) ~= "function" then return end
  for _, sub in ipairs({ object:GetChildren() }) do
    if type(sub) == "table" then collectMouse(list, seen, sub, depth - 1) end
  end
end

local function hideEntry(entry)
  local frames = BlizzardHide.Frames(entry)
  local state = { alpha = {}, mouse = {} }
  if entry.events then
    state.events = frames[1]
    ns.HideFrames.SetEventsMuted(state.events, entry.events, true)
  else
    local seen = {}
    for _, frame in ipairs(frames) do
      hideAlpha(frame)
      table.insert(state.alpha, frame)
      collectMouse(state.mouse, seen, frame, CHILD_DEPTH)
    end
    for _, button in ipairs(entry.buttons and entry.buttons() or {}) do collectMouse(state.mouse, seen, button, 0) end
    for _, object in ipairs(state.mouse) do hideMouse(object) end
  end
  applied[entry.id] = state
  ns.Debug("overrides", "blizzard frame %s hidden: %s frames, %s mouse targets", entry.id, #state.alpha, #state.mouse)
end

local function restoreEntry(entry)
  local state = applied[entry.id]
  applied[entry.id] = nil
  if state.events then ns.HideFrames.SetEventsMuted(state.events, entry.events, false) end
  for _, frame in ipairs(state.alpha) do restoreAlpha(frame) end
  for _, object in ipairs(state.mouse) do restoreMouse(object) end
  ns.Debug("overrides", "blizzard frame %s restored", entry.id)
end

function BlizzardHide.IsApplied(id)
  return applied[id] ~= nil
end

function BlizzardHide.IsPending()
  return pending
end

-- refresh = true: ausgeblendete Einträge neu suchen (Blizzard-Addon nachgeladen, Kampf vorbei)
function BlizzardHide.Apply(db, refresh)
  if not db then return end
  local wanted = hiddenSet(db)
  for _, entry in ipairs(BlizzardHide.ENTRIES) do
    if not entry.setting then
      local hide = wanted[entry.id] == true
      local isHidden = applied[entry.id] ~= nil
      if hide ~= isHidden or (hide and refresh) then
        if InCombatLockdown() then
          if not pending then ns.Debug("overrides", "blizzard frames: waiting for combat end") end
          pending = true
          return
        end
        if isHidden then restoreEntry(entry) end
        if hide then hideEntry(entry) end
      end
    end
  end
end

ns.RegisterApply(function(db) BlizzardHide.Apply(db) end)

ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if not pending then return end
  pending = false
  BlizzardHide.Apply(ns.db, true)
end)

-- Blizzard-Addons laden Frames nach (Arena, Uhr, Tracker): ausgeblendete neu suchen
ns.RegisterEvent("ADDON_LOADED", function(name)
  if not ns.db or next(hiddenSet(ns.db)) == nil then return end
  if type(name) == "string" and name:find("^Blizzard_") then BlizzardHide.Apply(ns.db, true) end
end)

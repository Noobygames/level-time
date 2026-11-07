-- Blizzard-Einblendungen und Kleinkram am Bildschirm ausblenden (Reiter Komfort, Oberfläche; je Einstellung, Standard
-- aus). Alles umkehrbar ohne /reload; fehlende Frames (je Client verschieden) werden übergangen, ihre Schalter fehlen.
--   hideBossBanner       Banner nach einem Bosskill mit der Beute (BossBanner, Retail und Forever): Ereignisse
--                        BOSS_KILL und ENCOUNTER_LOOT_RECEIVED abgemeldet (BossBannerToast.lua, BossBanner_OnLoad).
--   hideEventToasts      Ereignis-Einblendungen in der Bildschirmmitte (EventToastManagerFrame, Retail und Forever;
--                        dort auch das Level-Up-Banner): Ereignis DISPLAY_EVENT_TOASTS abgemeldet.
--   hideAlerts           Erfolge, Beute-Toasts und andere Meldungen unten (AlertFrame): Ereignisse aus ALERT_EVENTS
--                        abgemeldet (AlertFrameMixin:OnLoad in Mainline und Classic AlertFrames.lua).
--   hideStanceBar        Haltungsleiste (StanceBar) an einen versteckten Rahmen gehängt. Sie enthält geschützte
--                        Knöpfe: nur außerhalb des Kampfs, im Kampf geändert wird nach PLAYER_REGEN_ENABLED nachgeholt.
--   hideRestAnimation    "Zzz" am Spielerporträt beim Ausruhen: Retail/Forever PlayerRestLoop (Alpha 0), Classic
--                        PlayerRestIcon und PlayerRestGlow (Alpha 0; Blizzard zeigt und versteckt sie nur).
--   hidePortraitNumbers  Schadens- und Heilzahlen auf Spieler- und Begleiterporträt (CombatFeedback): die Texte werden
--                        nach Blizzards Show sofort versteckt (hooksecurefunc). Retail/Forever HitIndicator.HitText,
--                        Classic PlayerHitIndicator, überall PetHitIndicator.
--   hideBlizzardXpBar    Blizzards Erfahrungsleiste (Level Time zeigt eine eigene), hideBlizzardRepBar die Rufleiste.
--                        Alle Clients (live, classic_era, classic_anniversary, forever) haben den StatusTrackingBarManager
--                        mit zwei Behältern (Main/SecondaryStatusTrackingBarContainer, Systeme von Blizzards Edit Mode);
--                        jeder Behälter hat je Art eine eigene Leiste in container.bars[StatusTrackingBarInfo.BarsEnum.*].
--                        Ausgeblendet wird nur per Alpha 0 und Maus aus an der Leiste (samt ExhaustionTick) und am Rahmen
--                        des Behälters (BarFrameTexture, Classic MainMenuBarTextures/StandaloneTextures), solange der
--                        Behälter eine ausgeblendete Art zeigt. Kein Hide/SetParent/Layout-Aufruf: der Behälter bleibt
--                        für Edit Mode und ManageFramePositions unverändert (die Lücke über der Aktionsleiste bleibt).
--                        Blizzard setzt Alpha nur am Behälter (Ein-/Ausblend-Animation), nie an Leiste oder Rahmen;
--                        wechselt die gezeigte Art (ApplyPendingBarToShow, hooksecurefunc), wird neu angewendet.
--                        Nur außerhalb des Kampfs, im Kampf geändert wird nach PLAYER_REGEN_ENABLED nachgeholt.
--                        Ältere Clients ohne Manager: MainMenuExpBar (mit ExhaustionTick) und ReputationWatchBar.
-- Abgemeldete Ereignisse werden nur wieder angemeldet, wenn sie vorher angemeldet waren (IsEventRegistered).
local _, ns = ...

local HideFrames = {}
ns.HideFrames = HideFrames

local BOSS_BANNER_EVENTS = { "BOSS_KILL", "ENCOUNTER_LOOT_RECEIVED" }
local EVENT_TOAST_EVENTS = { "DISPLAY_EVENT_TOASTS" }
-- Vereinigung der Ereignisse aus AlertFrameMixin:OnLoad aller Clients (nicht angemeldete fallen weg)
HideFrames.ALERT_EVENTS = {
  "ACHIEVEMENT_EARNED", "CRITERIA_EARNED", "LFG_COMPLETION_REWARD", "SCENARIO_COMPLETED", "LOOT_ITEM_ROLL_WON",
  "SHOW_LOOT_TOAST", "SHOW_LOOT_TOAST_UPGRADE", "SHOW_PVP_FACTION_LOOT_TOAST", "SHOW_RATED_PVP_REWARD_TOAST",
  "PET_BATTLE_CLOSE", "ENTITLEMENT_DELIVERED", "RAF_ENTITLEMENT_DELIVERED", "STORE_PRODUCT_DELIVERED",
  "GARRISON_BUILDING_ACTIVATABLE", "GARRISON_TALENT_COMPLETE", "GARRISON_MISSION_FINISHED", "GARRISON_FOLLOWER_ADDED",
  "GARRISON_RANDOM_MISSION_ADDED", "NEW_RECIPE_LEARNED", "SHOW_LOOT_TOAST_LEGENDARY_LOOTED",
  "AZERITE_EMPOWERED_ITEM_LOOTED", "QUEST_TURNED_IN", "QUEST_LOOT_RECEIVED", "NEW_PET_ADDED", "NEW_MOUNT_ADDED",
  "NEW_TOY_ADDED", "NEW_WARBAND_SCENE_ADDED", "NEW_RUNEFORGE_POWER_ADDED", "TRANSMOG_COSMETIC_COLLECTION_SOURCE_ADDED",
  "TRANSMOG_COLLECTION_SOURCE_ADDED", "SKILL_LINE_SPECS_UNLOCKED", "PERKS_PROGRAM_CURRENCY_AWARDED",
  "PERKS_ACTIVITY_COMPLETED", "REQUESTED_GUILD_RENAME_RESULT", "INITIATIVE_TASK_COMPLETED",
  "CHALLENGE_MODE_COMPLETED_REWARDS",
}
local HIDDEN = 0

local setAlpha = ns.Overrides.Alpha()
local setParent = ns.Overrides.Parent()
local setMouse = ns.Overrides.New(
  function(frame) return frame:IsMouseEnabled() end,
  function(frame, enabled) frame:EnableMouse(enabled) end)

-- Ereignisse eines Frames umkehrbar abmelden: nur die, die angemeldet waren, kommen später zurück
local muted = {}  -- Frame -> Liste abgemeldeter Ereignisse

local function setEventsMuted(frame, events, mute)
  if not frame or not frame.IsEventRegistered then return end
  if mute and not muted[frame] then
    muted[frame] = {}
    for _, event in ipairs(events) do
      if frame:IsEventRegistered(event) then
        frame:UnregisterEvent(event)
        table.insert(muted[frame], event)
      end
    end
  elseif not mute and muted[frame] then
    for _, event in ipairs(muted[frame]) do frame:RegisterEvent(event) end
    muted[frame] = nil
  end
end
HideFrames.SetEventsMuted = setEventsMuted  -- auch für BlizzardHide.lua (Sprechender Kopf)

---------------------------------------------------------------------------
-- Frames je Client
---------------------------------------------------------------------------
-- Unterframe per Schlüssel, nur wenn es ein Frame (Tabelle) ist
local function child(frame, key)
  local value = frame and frame[key]
  if type(value) == "table" then return value end
end

local function playerFrameContent()
  return child(PlayerFrame, "PlayerFrameContent")
end

-- Ruhe-Anzeige am Porträt: Retail/Forever eine Animation, Classic Symbol und Leuchten
function HideFrames.RestFrames()
  local content = playerFrameContent()
  local restLoop = child(child(content, "PlayerFrameContentContextual"), "PlayerRestLoop")
  if restLoop then return { restLoop } end
  local list = {}
  if PlayerRestIcon then table.insert(list, PlayerRestIcon) end
  if PlayerRestGlow then table.insert(list, PlayerRestGlow) end
  return list
end

-- Texte der Porträtzahlen (CombatFeedback_Initialize in PlayerFrame/PetFrame)
function HideFrames.HitTexts()
  local list = {}
  local content = playerFrameContent()
  local hitText = child(child(child(content, "PlayerFrameContentMain"), "HitIndicator"), "HitText")
  if hitText then
    table.insert(list, hitText)
  elseif PlayerHitIndicator then
    table.insert(list, PlayerHitIndicator)
  end
  if PetHitIndicator then table.insert(list, PetHitIndicator) end
  return list
end

function HideFrames.StanceBar()
  return StanceBar
end

-- Statusleisten: Arten wie StatusTrackingBarInfo.BarsEnum (Werte als Rückfall, falls die Tabelle fehlt)
local BAR_KINDS = { experience = 4, reputation = 1 }
local BAR_ENUM_KEYS = { experience = "Experience", reputation = "Reputation" }
local CONTAINER_NAMES = { "MainStatusTrackingBarContainer", "SecondaryStatusTrackingBarContainer" }
local LEGACY_BARS = { experience = "MainMenuExpBar", reputation = "ReputationWatchBar" }
local ART_LISTS = { "MainMenuBarTextures", "StandaloneTextures" }

function HideFrames.BarIndex(kind)
  local enum = type(StatusTrackingBarInfo) == "table" and StatusTrackingBarInfo.BarsEnum
  local index = type(enum) == "table" and enum[BAR_ENUM_KEYS[kind]]
  return type(index) == "number" and index or BAR_KINDS[kind]
end

-- Behälter des StatusTrackingBarManager (barContainers, sonst die globalen Namen)
function HideFrames.StatusBarContainers()
  local list = {}
  local containers = child(StatusTrackingBarManager, "barContainers")
  if containers then
    for _, container in ipairs(containers) do
      if type(container) == "table" then table.insert(list, container) end
    end
  else
    for _, name in ipairs(CONTAINER_NAMES) do
      if type(_G[name]) == "table" then table.insert(list, _G[name]) end
    end
  end
  return list
end

-- Leisten einer Art (eine je Behälter; ältere Clients der eine globale Frame)
function HideFrames.StatusBars(kind)
  local list = {}
  local index = HideFrames.BarIndex(kind)
  for _, container in ipairs(HideFrames.StatusBarContainers()) do
    local bar = child(child(container, "bars"), index)
    if bar then table.insert(list, bar) end
  end
  local legacy = _G[LEGACY_BARS[kind]]
  if #list == 0 and type(legacy) == "table" then table.insert(list, legacy) end
  return list
end

-- Gezeigte Art eines Behälters (StatusTrackingBarContainerMixin.shownBarIndex, -1 = keine)
function HideFrames.ShownBarIndex(container)
  local index = container.shownBarIndex
  return type(index) == "number" and index or nil
end

-- Rahmen-Texturen eines Behälters (Retail/Forever BarFrameTexture, Classic die beiden Textur-Listen)
function HideFrames.ContainerArt(container)
  local list = {}
  local frameTexture = child(container, "BarFrameTexture")
  if frameTexture then table.insert(list, frameTexture) end
  for _, key in ipairs(ART_LISTS) do
    for _, texture in ipairs(child(container, key) or {}) do
      if type(texture) == "table" then table.insert(list, texture) end
    end
  end
  return list
end

function HideFrames.HasBossBanner() return BossBanner ~= nil end
function HideFrames.HasEventToasts() return EventToastManagerFrame ~= nil end
function HideFrames.HasAlerts() return AlertFrame ~= nil end
function HideFrames.HasStanceBar() return HideFrames.StanceBar() ~= nil end
function HideFrames.HasRestAnimation() return #HideFrames.RestFrames() > 0 end
function HideFrames.HasPortraitNumbers() return #HideFrames.HitTexts() > 0 end
function HideFrames.HasXpBar() return #HideFrames.StatusBars("experience") > 0 end
function HideFrames.HasRepBar() return #HideFrames.StatusBars("reputation") > 0 end

---------------------------------------------------------------------------
-- Haltungsleiste (geschützte Knöpfe: nicht im Kampf)
---------------------------------------------------------------------------
local function inCombat()
  return InCombatLockdown and InCombatLockdown()
end

local stancePending = false

local function applyStanceBar()
  local bar = HideFrames.StanceBar()
  if not bar then return end
  if inCombat() then
    stancePending = true
    ns.Debug("comfort", "stance bar: waiting for combat end")
    return
  end
  stancePending = false
  setParent(bar, ns.db.hideStanceBar, ns.Overrides.HiddenParent())
end

ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if stancePending then applyStanceBar() end
end)

---------------------------------------------------------------------------
-- Erfahrungs- und Rufleiste (Alpha und Maus, nur außerhalb des Kampfs)
---------------------------------------------------------------------------
local statusPending = false
local statusHooked = {}  -- Behälter -> true, sobald ApplyPendingBarToShow nachgehakt ist
local lastStatusState

local function setBarHidden(bar, hidden)
  setAlpha(bar, hidden, HIDDEN)
  setMouse(bar, hidden, false)
  local tick = child(bar, "ExhaustionTick") or (bar == _G.MainMenuExpBar and child(_G, "ExhaustionTick")) or nil
  if tick then setMouse(tick, hidden, false) end
end

local function anyStatusBarHidden(db)
  return db.hideBlizzardXpBar == true or db.hideBlizzardRepBar == true
end

-- Nach einem Wechsel der gezeigten Art (z.B. Max-Level: Ruf statt Erfahrung) den Rahmen neu setzen
local function hookContainer(container)
  if statusHooked[container] or type(container.ApplyPendingBarToShow) ~= "function" then return end
  statusHooked[container] = true
  hooksecurefunc(container, "ApplyPendingBarToShow", function()
    if anyStatusBarHidden(ns.db) or statusPending then HideFrames.ApplyStatusBars() end
  end)
end

function HideFrames.ApplyStatusBars()
  local db = ns.db
  if not db then return end
  if inCombat() then
    statusPending = true
    ns.Debug("overrides", "status bars: waiting for combat end")
    return
  end
  statusPending = false
  local hidden = {}
  for kind in pairs(BAR_KINDS) do
    local hide = (kind == "experience" and db.hideBlizzardXpBar or kind == "reputation" and db.hideBlizzardRepBar)
      == true
    hidden[HideFrames.BarIndex(kind)] = hide
    for _, bar in ipairs(HideFrames.StatusBars(kind)) do setBarHidden(bar, hide) end
  end
  local containers = HideFrames.StatusBarContainers()
  for _, container in ipairs(containers) do
    -- Rahmen nur weg, solange der Behälter eine ausgeblendete Art zeigt
    local artHidden = hidden[HideFrames.ShownBarIndex(container)] == true
    for _, texture in ipairs(HideFrames.ContainerArt(container)) do setAlpha(texture, artHidden, HIDDEN) end
    if anyStatusBarHidden(db) then hookContainer(container) end
  end
  -- Nur bei Änderung loggen (Apply läuft bei jeder Einstellung)
  local state = string.format("%s/%s/%d", tostring(db.hideBlizzardXpBar), tostring(db.hideBlizzardRepBar), #containers)
  if state ~= lastStatusState then
    lastStatusState = state
    ns.Debug("overrides", "status bars: xp hidden %s, rep hidden %s, containers %s", db.hideBlizzardXpBar,
      db.hideBlizzardRepBar, #containers)
  end
end

ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if statusPending then HideFrames.ApplyStatusBars() end
end)

-- WoW Forever: die Leisten stehen im eigenen Blizzard-Addon Blizzard_StatusTrackingBar
ns.RegisterEvent("ADDON_LOADED", function(name)
  if name == "Blizzard_StatusTrackingBar" and ns.db then HideFrames.ApplyStatusBars() end
end)

---------------------------------------------------------------------------
-- Porträtzahlen: nach jedem Show sofort verstecken, solange eingeschaltet
---------------------------------------------------------------------------
local hitHooked = false

local function hookHitTexts()
  if hitHooked then return end
  hitHooked = true
  for _, text in ipairs(HideFrames.HitTexts()) do
    hooksecurefunc(text, "Show", function(self)
      if ns.db.hidePortraitNumbers then self:Hide() end
    end)
  end
end

---------------------------------------------------------------------------
-- Anwenden
---------------------------------------------------------------------------
function HideFrames.Apply(db)
  setEventsMuted(BossBanner, BOSS_BANNER_EVENTS, db.hideBossBanner)
  setEventsMuted(EventToastManagerFrame, EVENT_TOAST_EVENTS, db.hideEventToasts)
  setEventsMuted(AlertFrame, HideFrames.ALERT_EVENTS, db.hideAlerts)
  for _, frame in ipairs(HideFrames.RestFrames()) do setAlpha(frame, db.hideRestAnimation, HIDDEN) end
  if db.hidePortraitNumbers then
    hookHitTexts()
    for _, text in ipairs(HideFrames.HitTexts()) do text:Hide() end
  end
  applyStanceBar()
  HideFrames.ApplyStatusBars()
end

ns.RegisterApply(HideFrames.Apply)

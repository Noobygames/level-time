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

function HideFrames.HasBossBanner() return BossBanner ~= nil end
function HideFrames.HasEventToasts() return EventToastManagerFrame ~= nil end
function HideFrames.HasAlerts() return AlertFrame ~= nil end
function HideFrames.HasStanceBar() return HideFrames.StanceBar() ~= nil end
function HideFrames.HasRestAnimation() return #HideFrames.RestFrames() > 0 end
function HideFrames.HasPortraitNumbers() return #HideFrames.HitTexts() > 0 end

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
end

ns.RegisterApply(HideFrames.Apply)

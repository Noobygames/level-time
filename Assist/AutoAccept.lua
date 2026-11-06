-- Anfragen an den Spieler selbst annehmen (Reiter Komfort, Automatik; je Einstellung, Standard aus):
--   autoAcceptSummon     Beschwörung: CONFIRM_SUMMON, nach SUMMON_DELAY Sekunden angenommen, wenn Beschwörer und Ort
--                        gleich geblieben sind; nicht im Kampf. Eine Chatzeile kündigt es an, Umschalt hält es an.
--   autoAcceptResurrect  Wiederbelebung: RESURRECT_REQUEST(Name), nicht, wenn der Helfer gerade kämpft
--                        (Kampf-Wiederbelebung) oder selbst tot ist.
--   autoReleasePvP       Tod in einem Schlachtfeld: Geist nach RELEASE_DELAY freilassen (RepopMe), außer es gibt
--                        eine Selbst-Wiederbelebung (Seelenstein, Ankh).
-- Abläufe wie Blizzards StaticPopup-Dialoge CONFIRM_SUMMON, RESURRECT* und DEATH (Annehmen-Taste ruft dieselben
-- Funktionen). C_SummonInfo und C_DeathInfo gibt es nicht in jedem Client: dann fehlt die Funktion still.
local _, ns = ...
local L = ns.L
local Comfort = ns.Comfort

local AutoAccept = {}
ns.AutoAccept = AutoAccept

AutoAccept.SUMMON_DELAY = 10
AutoAccept.RELEASE_DELAY = 1
local RESURRECT_POPUPS = { "RESURRECT", "RESURRECT_NO_SICKNESS", "RESURRECT_NO_TIMER" }
local PVP = "pvp"

local function summonInfo()
  if not C_SummonInfo then return nil end
  return C_SummonInfo.GetSummonConfirmSummoner(), C_SummonInfo.GetSummonConfirmAreaName()
end

local function onSummon()
  if not ns.db.autoAcceptSummon or not C_SummonInfo or ns.InCombat() then return end
  local summoner, area = summonInfo()
  if ns.IsSecret(summoner) or ns.IsSecret(area) then return end
  ns.Print(string.format(L.SUMMON_ACCEPT_IN, summoner or L.UNKNOWN_NAME, area or "?", AutoAccept.SUMMON_DELAY))
  C_Timer.After(AutoAccept.SUMMON_DELAY, function()
    local nowSummoner, nowArea = summonInfo()
    if nowSummoner ~= summoner or nowArea ~= area or not summoner then return end
    if not Comfort.IsActive("autoAcceptSummon") then
      ns.Print(L.SUMMON_NOT_ACCEPTED)
      return
    end
    ns.Debug("comfort", "summon from %s accepted", summoner)
    C_SummonInfo.ConfirmSummon()
    StaticPopup_Hide("CONFIRM_SUMMON")
  end)
end

local function onResurrectRequest(name)
  if not Comfort.IsActive("autoAcceptResurrect") or ns.IsSecret(name) then return end
  if name and (UnitAffectingCombat(name) or UnitIsDead(name)) then
    ns.Debug("comfort", "resurrect from %s not accepted (combat or dead)", name)
    return
  end
  ns.Debug("comfort", "resurrect from %s accepted", name)
  AcceptResurrect()
  for _, popup in ipairs(RESURRECT_POPUPS) do StaticPopup_Hide(popup) end
end

local function hasSelfResurrect()
  if not C_DeathInfo or not C_DeathInfo.GetSelfResurrectOptions then return false end
  local options = C_DeathInfo.GetSelfResurrectOptions()
  return type(options) == "table" and #options > 0
end

local function inBattleground()
  local inInstance, instanceType = IsInInstance()
  return inInstance and instanceType == PVP
end

local function onDead()
  if not ns.db.autoReleasePvP or not inBattleground() or hasSelfResurrect() then return end
  C_Timer.After(AutoAccept.RELEASE_DELAY, function()
    local stillDead = UnitIsDeadOrGhost("player") and not (UnitIsGhost and UnitIsGhost("player"))
    if not stillDead or not Comfort.IsActive("autoReleasePvP") then return end
    ns.Debug("comfort", "released in battleground")
    RepopMe()
  end)
end

ns.RegisterEvent("CONFIRM_SUMMON", onSummon)
ns.RegisterEvent("RESURRECT_REQUEST", onResurrectRequest)
ns.RegisterEvent("PLAYER_DEAD", onDead)

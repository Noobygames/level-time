-- Zielart Erkundung (Roadmap 307): "N Gebiete entdecken" oder "Zone X erreichen".
-- Entdecken: Meldung ERR_ZONE_EXPLORED ("Entdeckt: %s") bzw. ERR_ZONE_EXPLORED_XP (mit XP) als Systemchat
-- (CHAT_MSG_SYSTEM) oder gelbe Bildschirmmeldung (UI_INFO_MESSAGE). Welche der beiden der
-- jeweilige Client schickt, ist im Spiel zu prüfen; dieselbe Entdeckung aus beiden Quellen zählt einmal (DUPLICATE_SECONDS).
-- Zone: GetRealZoneText oder GetSubZoneText enthält den Namen (Teilstring), bei ZONE_CHANGED*; schon dort = kein Ziel.
-- Anteil einer Zone (C_MapExplorationInfo) ist noch offen.
-- params: { mode = "count"|"zone", zone = Name }
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Kinds = ns.Kinds
local L = ns.L

local Explore = {}
ns.ExploreGoals = Explore

local MODES = { "count", "zone" }
local MODE_LABELS = { count = "SG_FORM_EXPLORE_COUNT", zone = "SG_FORM_EXPLORE_ZONE" }
local ICON = "Interface\\Icons\\INV_Misc_Map_01"
local DUPLICATE_SECONDS = 5
local REACHED = 1

-- GetRealZoneText (Name der Zone, nicht die Instanz-Anzeige) gibt es in allen Clients; GetZoneText als Rückfall
local function inZone(wanted)
  local zoneText = GetRealZoneText or GetZoneText
  local zone = zoneText and zoneText()
  local subZone = GetSubZoneText and GetSubZoneText()
  return Kinds.Matches(zone, wanted) or Kinds.Matches(subZone, wanted)
end

Goals.RegisterKind("explore", {
  label = "SG_KIND_EXPLORE",
  group = "progress",
  usage = "SG_USAGE_EXPLORE",
  color = LT.Theme.COLORS.info,
  icon = ICON,
  -- Modus zuerst; darunter nur das Feld des gewählten Modus (Anzahl bzw. Zone)
  editable = { "amount" },  -- nur die Zielzahl; Modus und Filter gelten ab dem Anlegen
  form = { fields = {
    { type = "choice", param = "mode", label = "SG_FORM_EXPLORE_MODE", values = MODES, labels = MODE_LABELS },
    { type = "amount", label = "SG_FORM_AMOUNT", showIf = { mode = "count" } },
    { type = "text", param = "zone", label = "SG_FORM_ZONE", showIf = { mode = "zone" } },
  } },
  -- "add explore 10" = 10 Gebiete; "add explore Tanaris" = Zone erreichen
  parse = function(args, rest)
    local amount = tonumber(args[1])
    if amount and #args == 1 then return { mode = "count" }, amount end
    return { mode = "zone", zone = rest }, nil
  end,
  prepare = function(params, target)
    params.mode = params.mode or (params.zone and "zone" or "count")
    if params.mode ~= "zone" then
      params.zone = nil
      return target
    end
    params.zone = strtrim(params.zone or "")
    return REACHED
  end,
  validate = function(params, target)
    if params.mode == "count" then return Kinds.ValidAmount(target) end
    if params.mode ~= "zone" then return string.format(L.SG_ERR_UNKNOWN_KIND, tostring(params.mode)) end
    local zone, err = Kinds.CleanText(params.zone, L.SG_ERR_ZONE)
    if not zone then return err end
    params.zone = zone
  end,
  current = function(goal)
    if goal.params.mode == "zone" and inZone(goal.params.zone) then return REACHED end
    return 0
  end,
  title = function(goal)
    if goal.params.mode == "zone" then return string.format(L.SG_GOAL_ZONE, goal.params.zone) end
    return Kinds.Counted("SG_GOAL_EXPLORE", goal.target)
  end,
  hasCount = function(goal) return goal.params.mode == "count" end,
})

---------------------------------------------------------------------------
-- Erfassung: Entdeckungen
---------------------------------------------------------------------------
local formats  -- beim ersten Bedarf: speziellere Form (mit XP) zuerst
local lastArea, lastAreaAt

function Explore.ParseDiscovery(message)
  if type(message) ~= "string" or LT.IsSecret(message) then return nil end
  formats = formats or LT.ChatPatterns.CompileGlobals({ "ERR_ZONE_EXPLORED_XP", "ERR_ZONE_EXPLORED" })
  local args = LT.ChatPatterns.MatchAny(message, formats)
  return args and args[1] or nil
end

local function onDiscovery(message)
  if not ns.db or not Goals.HasActive("explore") then return end
  local area = Explore.ParseDiscovery(message)
  if not area then return end
  local now = GetTime()
  if area == lastArea and now - lastAreaAt <= DUPLICATE_SECONDS then return end
  lastArea, lastAreaAt = area, now
  ns.Debug("tracking", "discovered %s", area)
  Goals.Add("explore", function(goal) return goal.params.mode == "count" end, 1)
end

LT.RegisterEvent("CHAT_MSG_SYSTEM", onDiscovery)
-- UI_INFO_MESSAGE(messageType, message); ältere Clients nur (message)
LT.RegisterEvent("UI_INFO_MESSAGE", function(messageType, message)
  onDiscovery(message or messageType)
end)

---------------------------------------------------------------------------
-- Erfassung: Zone erreichen
---------------------------------------------------------------------------
local function checkZone()
  if not ns.db or not Goals.HasActive("explore") then return end
  Goals.SetEach("explore", function(goal)
    if goal.params.mode == "zone" and inZone(goal.params.zone) then return REACHED end
  end)
end

LT.RegisterEvent("ZONE_CHANGED_NEW_AREA", checkZone)
LT.RegisterEvent("ZONE_CHANGED", checkZone)
LT.RegisterEvent("ZONE_CHANGED_INDOORS", checkZone)

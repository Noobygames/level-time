-- Zielart Ruf (Roadmap 303): bei einer Fraktion N Ruf gewinnen (Rufmeldungen im Chat, Reputation.Parse von Level
-- Time) oder eine Stufe erreichen (Freundlich ... Ehrfürchtig). Stufe und Wert aus der Rufliste des Clients:
-- Classic/TBC GetNumFactions + GetFactionInfo (name, _, standingID, barMin, barMax, barValue), Retail/Forever
-- C_Reputation.GetNumFactions + GetFactionDataByIndex ({ name, reaction, currentStanding }). Stand der Stufen-Ziele
-- = Rufwert (Schwellen wie im Client: Freundlich 3000, Wohlwollend 9000, Respektvoll 21000, Ehrfürchtig 42000), neu
-- bei UPDATE_FACTION, nur solange ein Ruf-Ziel läuft. Eingeklappte Gruppen der Rufliste sieht die Liste nicht
-- (Fraktion dann erst nach dem Aufklappen); Retail-Renown (große Fraktionen) ist nicht abgedeckt.
-- params: { mode = "gain"|"standing", faction = Name (Teilstring), standing = Stufe 5-8 }
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Kinds = ns.Kinds
local L = ns.L

local Reputation = {}
ns.ReputationGoals = Reputation

local ICON = "Interface\\Icons\\INV_Scroll_03"
local MODES = { "gain", "standing" }
local MODE_LABELS = { gain = "SG_FORM_REP_GAIN", standing = "SG_FORM_REP_STANDING" }
local FRIENDLY, EXALTED = 5, 8
local STANDINGS = { 5, 6, 7, 8 }
local STANDING_KEYS = { [5] = "friendly", [6] = "honored", [7] = "revered", [8] = "exalted" }
-- Rufwert am Beginn jeder Stufe (standingID 1-8)
local THRESHOLDS = { [1] = -42000, [2] = -6000, [3] = -3000, [4] = 0, [5] = 3000, [6] = 9000, [7] = 21000, [8] = 42000 }

-- Name einer Stufe in der Sprache des Clients (FACTION_STANDING_LABEL1..8, alle Clients)
function Reputation.StandingLabel(standing)
  return _G["FACTION_STANDING_LABEL" .. standing] or tostring(standing)
end

-- { name, standing, value } einer Fraktion aus der Rufliste; nil, wenn sie dort nicht steht
local function fromClassic(wanted)
  if not GetNumFactions or not GetFactionInfo then return nil end
  for index = 1, GetNumFactions() do
    local name, _, standing, _, _, value, _, _, isHeader = GetFactionInfo(index)
    if name and not isHeader and Kinds.Matches(name, wanted) then return { name = name, standing = standing, value = value } end
  end
end

local function fromRetail(wanted)
  local reputation = C_Reputation
  if not reputation or not reputation.GetNumFactions or not reputation.GetFactionDataByIndex then return nil end
  for index = 1, reputation.GetNumFactions() do
    local data = reputation.GetFactionDataByIndex(index)
    if data and not data.isHeader and Kinds.Matches(data.name, wanted) then
      return { name = data.name, standing = data.reaction, value = data.currentStanding }
    end
  end
end

function Reputation.Find(wanted)
  local faction = fromRetail(wanted) or fromClassic(wanted)
  if not faction or type(faction.value) ~= "number" or LT.IsSecret(faction.value) then return nil end
  return faction
end

-- "freundlich", "honored" oder 5-8 -> Stufe
local function parseStanding(word)
  local number = tonumber(word)
  if number then return number end
  word = (word or ""):lower()
  for standing, key in pairs(STANDING_KEYS) do
    if key == word or Reputation.StandingLabel(standing):lower() == word then return standing end
  end
end

Goals.RegisterKind("reputation", {
  label = "SG_KIND_REPUTATION",
  usage = "SG_USAGE_REPUTATION",
  color = LT.Theme.COLORS.good,
  icon = ICON,
  form = { amount = "SG_FORM_REP_AMOUNT", fields = {
    { type = "choice", param = "mode", label = "SG_FORM_REP_MODE", values = MODES, labels = MODE_LABELS },
    { type = "text", param = "faction", label = "SG_FORM_REP_FACTION" },
    { type = "choice", param = "standing", label = "SG_FORM_REP_STANDING_LEVEL", values = STANDINGS,
      labels = { [5] = "SG_STANDING_5", [6] = "SG_STANDING_6", [7] = "SG_STANDING_7", [8] = "SG_STANDING_8" } },
  } },
  -- "add rep 1000 <Fraktion>" (gewinnen) oder "add rep honored <Fraktion>" (Stufe)
  parse = function(args, rest)
    local first = args[1]
    local remainder = rest:match("^%S+%s*(.*)$") or ""
    local standing = not tonumber(first) and parseStanding(first) or nil
    if standing then return { mode = "standing", standing = standing, faction = remainder }, nil end
    return { mode = "gain", faction = remainder }, tonumber(first)
  end,
  prepare = function(params, target)
    params.mode = params.mode or "gain"
    params.faction = strtrim(params.faction or "")
    local faction = params.faction ~= "" and Reputation.Find(params.faction) or nil
    if faction then params.faction = faction.name end
    if params.mode ~= "standing" then
      params.standing = nil
      return target
    end
    params.standing = tonumber(params.standing)
    return params.standing and THRESHOLDS[params.standing] or nil
  end,
  validate = function(params, target)
    if params.faction == "" then return L.SG_ERR_FACTION end
    if params.mode == "gain" then return Kinds.ValidAmount(target) end
    if params.mode ~= "standing" or not params.standing or params.standing < FRIENDLY or params.standing > EXALTED then
      return L.SG_ERR_STANDING
    end
    if not Reputation.Find(params.faction) then return L.SG_ERR_FACTION_UNKNOWN end
  end,
  startAtCurrent = true,  -- Balken ab dem Rufwert beim Anlegen (Werte können negativ sein)
  current = function(goal)
    if goal.params.mode ~= "standing" then return 0 end
    return Reputation.Find(goal.params.faction).value
  end,
  countText = function(goal)
    if goal.params.mode ~= "standing" then return string.format("%d / %d", goal.progress, goal.target) end
    local faction = Reputation.Find(goal.params.faction)
    local now = faction and faction.standing or goal.params.standing
    return Reputation.StandingLabel(now) .. " > " .. Reputation.StandingLabel(goal.params.standing)
  end,
  title = function(goal)
    if goal.params.mode == "standing" then
      return string.format(L.SG_GOAL_REP_STANDING, goal.params.faction, Reputation.StandingLabel(goal.params.standing))
    end
    return string.format(L.SG_GOAL_REP_GAIN, goal.target, goal.params.faction)
  end,
})

---------------------------------------------------------------------------
-- Erfassung
---------------------------------------------------------------------------
LT.RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE", function(message)
  if not ns.db or not Goals.HasActive("reputation") then return end
  local faction, amount = LT.Reputation.Parse(message)
  if not faction then return end
  Goals.Add("reputation", function(goal)
    return goal.params.mode == "gain" and Kinds.Matches(faction, goal.params.faction)
  end, amount)
end)

LT.RegisterEvent("UPDATE_FACTION", function()
  if not ns.db or not Goals.HasActive("reputation") then return end
  Goals.SetEach("reputation", function(goal)
    if goal.params.mode ~= "standing" then return nil end
    local faction = Reputation.Find(goal.params.faction)
    return faction and faction.value or nil
  end)
end)

-- Zielart Erfolg (Roadmap 309): einen Erfolg erreichen. Nur in Clients mit Erfolgen (GetAchievementInfo; nicht in
-- Classic Era und TBC), sonst ist die Art nicht verfügbar (kein Reiter, kein Befehl). Fertig bei ACHIEVEMENT_EARNED(achievementID); Fortschritt aus den
-- Kriterien (GetAchievementNumCriteria, GetAchievementCriteriaInfo: criteriaString, criteriaType, completed, quantity,
-- reqQuantity): ein Kriterium mit Menge zählt die Menge (z.B. 37 / 50), sonst erledigte Kriterien. Neu bei
-- CRITERIA_UPDATE (kommt oft; nur solange ein Erfolgsziel läuft, je Ziel ein paar Aufrufe).
-- params: { achievementId, name }
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Kinds = ns.Kinds
local L = ns.L

local ICON = "Interface\\Icons\\Spell_Holy_HolyBolt"

-- ID aus einem Erfolgs-Link ("|Hachievement:123:...") oder einer Zahl
local function parseAchievement(text)
  text = text or ""
  return tonumber((text:match("achievement:(%d+)"))) or tonumber((text:match("^%s*(%d+)%s*$")))
end

local function info(achievementId)
  if not GetAchievementInfo then return nil end
  local id, name, _, completed, _, _, _, _, _, icon = GetAchievementInfo(achievementId)
  if not id then return nil end
  return { name = name, completed = completed == true, icon = icon }
end

-- Stand und Ziel aus den Kriterien: { progress, target }; ohne Kriterien 0 von 1
local function criteria(achievementId)
  local count = GetAchievementNumCriteria and GetAchievementNumCriteria(achievementId) or 0
  if count == 1 then
    local _, _, completed, quantity, required = GetAchievementCriteriaInfo(achievementId, 1)
    if type(required) == "number" and required > 1 and type(quantity) == "number" then
      return math.min(quantity, required), required
    end
    return completed and 1 or 0, 1
  end
  if count == 0 then return 0, 1 end
  local done = 0
  for index = 1, count do
    local _, _, completed = GetAchievementCriteriaInfo(achievementId, index)
    if completed then done = done + 1 end
  end
  return done, count
end

Goals.RegisterKind("achievement", {
  available = function() return GetAchievementInfo ~= nil end,
  label = "SG_KIND_ACHIEVEMENT",
  usage = "SG_USAGE_ACHIEVEMENT",
  color = LT.Theme.COLORS.gold,
  icon = ICON,
  texture = function(goal)
    local data = info(goal.params.achievementId)
    return data and data.icon or nil
  end,
  tooltip = function(goal, tooltip)
    local link = GetAchievementLink and GetAchievementLink(goal.params.achievementId)
    if link then tooltip:SetHyperlink(link:match("|H(achievement:[^|]+)|h") or link) end
  end,
  form = { fields = { { type = "text", param = "input", label = "SG_FORM_ACHIEVEMENT", links = true } } },
  parse = function(_, rest) return { input = rest }, nil end,
  prepare = function(params)
    if params.input then
      params.achievementId = parseAchievement(params.input)
      params.input = nil
    end
    local data = params.achievementId and info(params.achievementId)
    if not data then return nil end
    params.name = data.name
    local _, target = criteria(params.achievementId)
    if data.completed then return 0 end  -- schon erreicht (current liefert dann den Stand >= Ziel)
    return target
  end,
  validate = function(params)
    if not params.name then return L.SG_ERR_ACHIEVEMENT end
  end,
  current = function(goal)
    local data = info(goal.params.achievementId)
    if data and data.completed then return goal.target end
    return (criteria(goal.params.achievementId))
  end,
  title = function(goal) return string.format(L.SG_GOAL_ACHIEVEMENT, goal.params.name) end,
  hasCount = function(goal) return goal.target > 1 end,
})

---------------------------------------------------------------------------
-- Erfassung
---------------------------------------------------------------------------
LT.RegisterEvent("ACHIEVEMENT_EARNED", function(achievementId)
  if not ns.db or not Goals.HasActive("achievement") then return end
  Goals.SetEach("achievement", function(goal)
    if goal.params.achievementId == achievementId then return goal.target end
  end)
end)

LT.RegisterEvent("CRITERIA_UPDATE", function()
  if not ns.db or not Goals.HasActive("achievement") then return end
  Goals.SetEach("achievement", function(goal) return (criteria(goal.params.achievementId)) end)
end)

Kinds.ParseAchievement = parseAchievement

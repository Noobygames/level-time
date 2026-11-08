-- Zielart Beruf/Fertigkeit (Roadmap 297): Fertigkeit N in einem Beruf (oder einer Waffenfertigkeit in Classic)
-- erreichen. Stand: Systemmeldung CHAT_MSG_SKILL im Format SKILL_RANK_UP ("Eure Fertigkeit in %s hat sich auf %d
-- erhöht.", alle Clients); beim Anlegen der aktuelle Wert, soweit der Client ihn nennt: Classic GetSkillLineInfo,
-- Retail/Forever GetProfessions + GetProfessionInfo (fehlt beides, startet das Ziel bei 0 und folgt der Meldung).
-- params: { skill = Name oder Teil davon (wie im Spiel, Sprache des Clients) }
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Kinds = ns.Kinds
local L = ns.L

local Skill = {}
ns.SkillGoals = Skill

local ICON = "Interface\\Icons\\Trade_Engineering"
local PROFESSION_SLOTS = 5  -- GetProfessions: zwei Hauptberufe, Archäologie, Angeln, Kochen

-- Classic: Liste aller Fertigkeiten (Überschriften überspringen)
local function fromSkillLines(wanted)
  if not GetNumSkillLines or not GetSkillLineInfo then return nil end
  for index = 1, GetNumSkillLines() do
    local name, isHeader, _, rank = GetSkillLineInfo(index)
    if not isHeader and Kinds.Matches(name, wanted) and type(rank) == "number" then return rank, name end
  end
end

-- Retail/Forever: Berufe nach Index
local function fromProfessions(wanted)
  if not GetProfessions or not GetProfessionInfo then return nil end
  local indices = { GetProfessions() }
  for slot = 1, PROFESSION_SLOTS do
    local index = indices[slot]
    if index then
      local name, _, rank = GetProfessionInfo(index)
      if Kinds.Matches(name, wanted) and type(rank) == "number" then return rank, name end
    end
  end
end

-- Aktueller Wert und voller Name der Fertigkeit, nil wenn der Client sie nicht nennt
function Skill.Current(wanted)
  local rank, name = fromSkillLines(wanted)
  if rank then return rank, name end
  return fromProfessions(wanted)
end

Goals.RegisterKind("skill", {
  label = "SG_KIND_SKILL",
  group = "progress",
  usage = "SG_USAGE_SKILL",
  color = LT.Theme.COLORS.goodLosing,
  icon = ICON,
  editable = { "amount" },  -- nur die Zielzahl; Modus und Filter gelten ab dem Anlegen
  form = { amount = "SG_FORM_SKILL_RANK", fields = { { type = "text", param = "skill", label = "SG_FORM_SKILL" } } },
  -- "add skill 150 Kräuterkunde"
  parse = function(args, rest)
    local rank = tonumber(args[1])
    local name = rank and rest:match("^%S+%s*(.*)$") or rest
    return { skill = name }, rank
  end,
  prepare = function(params, target)
    params.skill = strtrim(params.skill or "")
    local _, fullName = Skill.Current(params.skill ~= "" and params.skill or nil)
    if fullName and params.skill ~= "" then params.skill = fullName end
    return target
  end,
  validate = function(params, target)
    if params.skill == "" then return L.SG_ERR_SKILL end
    return Kinds.ValidAmount(target)
  end,
  current = function(goal) return (Skill.Current(goal.params.skill)) or 0 end,
  title = function(goal) return string.format(L.SG_GOAL_SKILL, goal.params.skill, goal.target) end,
})

---------------------------------------------------------------------------
-- Erfassung: "Fertigkeit ... erhöht" im Chat; Muster beim ersten Bedarf (das Format steht ab dem Laden des Clients)
---------------------------------------------------------------------------
local rankFormat

local function parseRankUp(message)
  if type(message) ~= "string" or LT.IsSecret(message) or type(SKILL_RANK_UP) ~= "string" then return nil end
  rankFormat = rankFormat or LT.ChatPatterns.Compile(SKILL_RANK_UP)
  local args = LT.ChatPatterns.Match(message, rankFormat)
  local rank = args and tonumber(args[2])
  if not rank then return nil end
  return args[1], rank
end
Skill.ParseRankUp = parseRankUp

LT.RegisterEvent("CHAT_MSG_SKILL", function(message)
  if not ns.db or not Goals.HasActive("skill") then return end
  local name, rank = parseRankUp(message)
  if not name then return end
  ns.Debug("tracking", "skill %s -> %s", name, rank)
  Goals.SetEach("skill", function(goal)
    if Kinds.Matches(name, goal.params.skill) then return rank end
  end)
end)

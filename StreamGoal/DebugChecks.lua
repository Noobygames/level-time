-- Debug-Checks von Level Time Goals für offene Fragen im Spiel (/lt debug check, Ergebnis im Debug-Log von Level Time).
-- Namen <Roadmap>.goals.<was>; ManualToCheck nennt sie bei den Punkten 173-183.
local _, ns = ...
local LT = ns.LT
local DebugLog = LT.DebugLog

if not DebugLog or not DebugLog.AddCheck then return end

local function spellName(spellID)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellID) end
  if GetSpellInfo then return (GetSpellInfo(spellID)) end
end

local function safe(value)
  if LT.IsSecret(value) then return "<secret>" end
  return value
end

-- 300: kennt der Client die Spell-IDs der Heiltränke (Regel "nopotion")?
DebugLog.AddCheck("300.goals.potionSpells", function()
  local result = {}
  for spellID in pairs(ns.RuleGoals.POTION_SPELLS) do result[tostring(spellID)] = safe(spellName(spellID)) or false end
  return result
end)

-- 297: Format der Fertigkeitsmeldung und welche Quelle den Startwert liefert
DebugLog.AddCheck("297.goals.skills", function()
  local professions = {}
  if GetProfessions then
    for _, index in ipairs({ GetProfessions() }) do
      local name, _, rank = GetProfessionInfo(index)
      table.insert(professions, string.format("%s=%s", tostring(safe(name)), tostring(safe(rank))))
    end
  end
  return {
    format = SKILL_RANK_UP or false,
    skillLines = GetNumSkillLines ~= nil and GetNumSkillLines() or false,
    professions = professions,
  }
end)

-- 307/309: Meldungsformate für Entdecken und Ehre, Erfolgs-API
DebugLog.AddCheck("307.goals.formats", function()
  return {
    explored = ERR_ZONE_EXPLORED or false,
    exploredXp = ERR_ZONE_EXPLORED_XP or false,
    honorGain = COMBATLOG_HONORGAIN or false,
    honorNoRank = COMBATLOG_HONORGAIN_NO_RANK or false,
    honorAward = COMBATLOG_HONORAWARD or false,
    achievements = GetAchievementInfo ~= nil,
  }
end)

-- 303: welche Rufliste der Client hat und was die erste Fraktion liefert
DebugLog.AddCheck("303.goals.reputation", function()
  local retail = C_Reputation and C_Reputation.GetFactionDataByIndex ~= nil
  local first
  for index = 1, 5 do
    local data
    if retail then
      data = C_Reputation.GetFactionDataByIndex(index)
      data = data and not data.isHeader and { name = data.name, reaction = data.reaction, value = data.currentStanding }
    elseif GetFactionInfo then
      local name, _, standing, _, _, value, _, _, isHeader = GetFactionInfo(index)
      data = name and not isHeader and { name = name, reaction = standing, value = value }
    end
    if data then
      first = { name = safe(data.name), reaction = safe(data.reaction), value = safe(data.value) }
      break
    end
  end
  return { retail = retail and true or false, classic = GetFactionInfo ~= nil, first = first or false }
end)

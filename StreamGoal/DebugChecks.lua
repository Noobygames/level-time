-- Debug-Checks von Level Time Goals für offene Fragen im Spiel (/lt debug check, Ergebnis im Debug-Log, das im lokalen
-- LevelTimer_DataExtractor liegt; ohne ihn gibt es LT.DebugLog nicht und die Datei tut nichts).
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

-- 432: kann der Client die Stücke des Glücksrads drehen, und gibt es den Tick-Ton?
DebugLog.AddCheck("432.goals.wheel", function()
  local slice = ns.WheelDisplay.SliceTexture(1)
  return {
    setRotation = type(slice.SetRotation) == "function",
    getRotation = type(slice.GetRotation) == "function" and slice:GetRotation() or false,
    tickSound = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or false,
    playSound = PlaySound ~= nil,
  }
end)

-- 439: Weglaufen: kennt der Client die Zauber, die den Kampf ohne Weglaufen beenden, und was liefern die Einheiten?
DebugLog.AddCheck("439.goals.escape", function()
  local spells = {}
  for spellID in pairs(ns.EscapeGoals.COMBAT_DROP_SPELLS) do
    spells[tostring(spellID)] = safe(spellName(spellID)) or false
  end
  local result = ns.EscapeGoals.Snapshot()
  result.dropSpells = spells
  return result
end)

-- 439: Momente: welche Erkennungen der Client kann und welche APIs es dafür gibt
DebugLog.AddCheck("439.goals.moments", function()
  local rewards = ns.db and ns.db.questRewards and ns.db.questRewards[LT.characterKey]
  local rewardCount = 0
  for _ in pairs(rewards or {}) do rewardCount = rewardCount + 1 end
  return {
    modes = table.concat(ns.Moments.MODES, ","),
    swimming = IsSwimming ~= nil and safe(IsSwimming()) or false,
    falling = IsFalling ~= nil and safe(IsFalling()) or false,
    glidingInfo = C_PlayerInfo ~= nil and C_PlayerInfo.GetGlidingInfo ~= nil,
    performEmote = C_ChatInfo ~= nil and C_ChatInfo.PerformEmote ~= nil,
    doEmote = DoEmote ~= nil,
    spellHelpful = C_Spell ~= nil and C_Spell.IsSpellHelpful ~= nil,
    buybackItemId = C_MerchantFrame ~= nil and C_MerchantFrame.GetBuybackItemID ~= nil,
    buybackLink = GetBuybackItemLink ~= nil,
    buyback = BuybackItem ~= nil,
    questRewards = rewardCount,
  }
end)

local Goals = ns.Goals

local function frameStrata(frame)
  if not frame then return false end
  return { strata = frame:GetFrameStrata(), level = frame:GetFrameLevel(), shown = frame:IsShown() and true or false }
end

-- LT-114, LT-121, LT-97, LT-191: laufende Ziele mit Art, Stand, Frist (Restzeit, Modus, Spielzeit-Basis), Belohnung
-- und Erfolgs-Kriterien; vor und nach Login/Ausloggen laufen lassen und die Zeilen vergleichen
DebugLog.AddCheck("LT114.goals.active", function()
  local list = {}
  for _, goal in ipairs(Goals.Active()) do
    local deadline = goal.deadline
    table.insert(list, {
      id = goal.id, kind = goal.kind, progress = safe(goal.progress), target = goal.target,
      deadlineMode = deadline and deadline.mode or false,
      deadlineRemaining = deadline and ns.Deadlines.Remaining(goal) or false,
      deadlineText = deadline and ns.Deadlines.Text(goal) or false,
      reward = ns.Rewards.Line(goal) or false,
      achievementId = goal.params and goal.params.achievementId or nil,
    })
  end
  local played = LT.PlayedTime and LT.PlayedTime.GetTotalSeconds and LT.PlayedTime.GetTotalSeconds()
  return { goals = list, playedSeconds = played or false, now = time(), points = ns.Rewards.TotalPoints(LT.characterKey) }
end)

-- LT-97: API-Rückgaben des Erfolgssystems für den ersten laufenden Erfolgs-Zielwert (sonst Erfolg 6)
DebugLog.AddCheck("LT97.goals.achievement", function()
  local id = 6
  for _, goal in ipairs(Goals.Active()) do
    if goal.kind == "achievement" and goal.params then id = goal.params.achievementId or id end
  end
  local criteria = {}
  local count = GetAchievementNumCriteria and GetAchievementNumCriteria(id) or 0
  for index = 1, math.min(count, 5) do
    local name, _, completed, quantity, required = GetAchievementCriteriaInfo(id, index)
    table.insert(criteria, string.format("%s completed=%s %s/%s", tostring(safe(name)), tostring(safe(completed)),
      tostring(safe(quantity)), tostring(safe(required))))
  end
  return { id = id, info = GetAchievementInfo ~= nil and safe((GetAchievementInfo(id))) or false, criteria = criteria }
end)

-- LT-117: Pakete und Teilen: Liste, Titel, Roundtrip Encode/Decode, Import-Art
DebugLog.AddCheck("LT117.goals.packs", function()
  local packs = {}
  for _, entry in ipairs(ns.Packs.List()) do
    table.insert(packs, string.format("%s builtin=%s titles=%s", entry.key, tostring(entry.builtin),
      table.concat(ns.Packs.Titles(entry.key), "|")))
  end
  local key = ns.Packs.List()[1]
  local exported = key and ns.Packs.Export(key.key)
  local entries = exported and ns.Packs.Decode(exported)
  local roundtrip = entries and ns.Packs.Decode(ns.Packs.Encode("Test", entries))
  return { packs = packs, exportLength = exported and #exported or false, decoded = entries and #entries or false,
    roundtrip = roundtrip and #roundtrip or false }
end)

-- LT-158 (Minimap-Button): Einstellung, Winkel, Tooltip-Zeilen und Rahmen
DebugLog.AddCheck("LT158.goals.minimapButton", function()
  local lines = {}
  local tooltip = { AddLine = function(_, text) table.insert(lines, tostring(text)) end }
  ns.MinimapButton.FillTooltip(tooltip)
  return { shown = ns.db.settings.minimapButton, angle = ns.db.settings.minimapAngle,
    running = #ns.MinimapButton.ListedGoals(), tooltip = lines }
end)

-- LT-166: Glücksrad: Neuwürfe, Anzeigedauer, Ebenen von Rad und Ergebnis-Karte gegen das Fenster
DebugLog.AddCheck("LT166.goals.wheelState", function()
  return { rerollsLeft = ns.Wheel.RerollsLeft(), spinning = ns.Wheel.IsSpinning() and true or false,
    resultSeconds = ns.db.settings.wheelResultSeconds, spinStrata = ns.WheelDisplay.SPIN_STRATA,
    wheel = frameStrata(_G.StreamGoalWheel), card = frameStrata(ns.Wheel.card and ns.Wheel.card.frame),
    window = frameStrata(_G.StreamGoalWindow) }
end)

-- LT-169, LT-167: Einstieg: Zahl der Ziele und Datenbank-Schlüssel (kein Willkommen-Flag im Code vorhanden)
DebugLog.AddCheck("LT169.goals.firstRun", function()
  local keys = {}
  for key in pairs(StreamGoalDB or {}) do table.insert(keys, key) end
  table.sort(keys)
  return { dbKeys = table.concat(keys, ","), active = #Goals.Active(), history = #Goals.History() }
end)

-- LT-148: Zusammenfassungskarte im Stream: Modus, Zeilen (zweimal im Abstand aufrufen: Werte zählen live?),
-- Rahmen und Stream-Modus
DebugLog.AddCheck("LT148.recap.state", function()
  local rows = {}
  local recap = ns.RecapWindow
  if recap and recap.GetMode then
    for _, row in ipairs(recap.BuildRows(recap.GetMode()) or {}) do
      table.insert(rows, type(row) == "table" and table.concat({ tostring(row[1]), tostring(row[2]) }, "=") or tostring(row))
    end
  end
  return { mode = recap and recap.GetMode and recap.GetMode() or false, rows = rows,
    streamMode = ns.StreamMode and ns.StreamMode.IsEnabled() or false }
end)

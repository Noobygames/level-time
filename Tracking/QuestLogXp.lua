-- XP der Quests im Questlog (Roadmap 270): Summe getrennt nach abgabebereit und offen, und ob die Abgabe der
-- fertigen Quests für das Level-Up reicht. Fenster-Zeile (StatLines.lua) und XP-Balken (TimerWindow.lua) lesen hier.
-- Questlog und Belohnungen liest Lib/QuestLog.lua. Neu gezählt wird nur nach einer Änderung (QUEST_LOG_UPDATE,
-- Abgabe, Level-Up), und zwar erst beim nächsten Lesen.
local _, ns = ...
local QuestLog = ns.QuestLog

local QuestLogXp = {}
ns.QuestLogXp = QuestLogXp

local dirty = true
local readyXp, openXp = 0, 0

local function recount()
  readyXp, openXp = 0, 0
  for _, entry in ipairs(QuestLog.Entries()) do
    local xp = QuestLog.RewardXp(entry.questID)
    if xp and xp > 0 then
      if entry.ready then readyXp = readyXp + xp else openXp = openXp + xp end
    end
  end
  dirty = false
  ns.Debug("quests", "quest log XP: ready %s, open %s", readyXp, openXp)
end

-- XP der abgabebereiten und der offenen Quests
function QuestLogXp.Get()
  if dirty then recount() end
  return readyXp, openXp
end

-- Fehlende XP bis zum Level-Up minus XP der fertigen Quests: <= 0 heißt, die Abgabe reicht
function QuestLogXp.MissingAfterTurnIn()
  local ready = QuestLogXp.Get()
  return UnitXPMax("player") - UnitXP("player") - ready
end

local function markDirty() dirty = true end

ns.RegisterEvent("QUEST_LOG_UPDATE", markDirty)
ns.RegisterEvent("QUEST_TURNED_IN", markDirty)
ns.OnLogin(markDirty)
ns.OnLevelStarted(markDirty)  -- Belohnungen hängen in Retail vom Level ab

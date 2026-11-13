-- XP und Geld beim Überfahren einer Quest im Questlog (Roadmap 486, Einstellung questLogRewards, Standard aus).
-- Nur Hooks nach Blizzards eigenem Handler, nie Skripte ersetzen (Taint). Rahmen je Client (Gethe/wow-ui-source):
--   Era/TBC         QuestLogTitleButtonTemplate ruft im XML-Skript QuestLogTitleButton_OnEnter(self) über den globalen
--                   Namen auf (Vanilla/QuestLogFrame.xml) -> hooksecurefunc reicht. Blizzard zeigt dort nur in einer
--                   Gruppe einen Tooltip (QuestLog_UpdatePartyInfoTooltip), sonst baut der Hook ihn selbst; OnLeave
--                   versteckt GameTooltip. Log-Index = GetID() + FauxScrollFrame_GetOffset(QuestLogListScrollFrame).
--   Retail/Forever  QuestLogTitleTemplate bindet <OnEnter function="QuestMapLogTitleButton_OnEnter"/> beim Erzeugen
--                   (Mainline/QuestMapFrame.xml), ein späterer Hook auf die globale Funktion erreicht vorhandene Knöpfe
--                   nicht. Deshalb nach jedem QuestLogQuests_Update jeden neuen Knopf aus
--                   QuestScrollFrame.titleFramePool einmal per HookScript("OnEnter") erweitern; Blizzards Tooltip steht
--                   dann schon (button.questLogIndex).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    questLogRewards = false,
  },
})

local QuestLogRewards = {}
ns.QuestLogRewards = QuestLogRewards

local hookedButtons = setmetatable({}, { __mode = "k" })
local hooked = {}

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

-- Belohnungszeile für Log-Index index an den Tooltip von button; eigener Tooltip, wenn Blizzard keinen zeigt
function QuestLogRewards.Show(button, index)
  if not (ns.db and ns.db.questLogRewards) or type(index) ~= "number" then return end
  local entry = ns.QuestLog.Entry(index)
  local text = entry and ns.QuestTooltip.RewardText(entry.questID)
  if not text then return end
  if GameTooltip:GetOwner() ~= button then
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(entry.title or ns.L.UNKNOWN_NAME)
  end
  GameTooltip:AddLine(text, 1, 1, 1)
  GameTooltip:Show()
end

local function onClassicEnter(button)
  local offset = QuestLogListScrollFrame and FauxScrollFrame_GetOffset
    and FauxScrollFrame_GetOffset(QuestLogListScrollFrame) or 0
  QuestLogRewards.Show(button, button:GetID() + offset)
end

local function onMainlineUpdate()
  local pool = QuestScrollFrame and QuestScrollFrame.titleFramePool
  if type(pool) ~= "table" or not pool.EnumerateActive then return end
  for button in pool:EnumerateActive() do
    if not hookedButtons[button] and button.HookScript then
      hookedButtons[button] = true
      button:HookScript("OnEnter", function(self)
        ns.SafeCall(QuestLogRewards.Show, self, readable(self.questLogIndex))
      end)
    end
  end
end

local function hookFunction(name, hook)
  if hooked[name] or type(_G[name]) ~= "function" then return end
  hooked[name] = true
  hooksecurefunc(name, function(...) ns.SafeCall(hook, ...) end)
  ns.Debug("quests", "quest log rewards hooked %s", name)
end

local function hookAll()
  hookFunction("QuestLogTitleButton_OnEnter", onClassicEnter)
  hookFunction("QuestLogQuests_Update", onMainlineUpdate)
end

ns.OnLogin(hookAll)
ns.RegisterEvent("ADDON_LOADED", hookAll)

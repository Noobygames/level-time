-- Questnamen in Blizzards Listen ergänzen: Gespräch, Gruß, Questlog und (Classic) Quest-Tracker. Module melden einen
-- Ergänzer an (QuestListHooks.Register({ enabled = function(db), decorate = function(text, quest) })); decorate liefert
-- den neuen Text oder nil (nichts zu tun, schon ergänzt). quest = { questID, level, group } (Gruß: ohne questID).
-- Ergänzer laufen in Anmeldereihenfolge (.toc), jeder muss erkennen, ob er den Text schon ergänzt hat.
-- Nur hooksecurefunc/HookScript nach Blizzards eigenem Aufbau, nie Skripte ersetzen (Taint). Blizzard setzt die Texte
-- bei jedem Aufbau neu, deshalb reicht es, nach jedem Aufbau den Text zu ergänzen; aus = beim nächsten Aufbau weg.
-- Rahmen je Client (Gethe/wow-ui-source, Zweige classic_era, classic_anniversary, forever, live):
--   Gespräch  alle: GossipAvailableQuestButtonMixin/GossipActiveQuestButtonMixin:Setup(questInfo), questInfo.questLevel
--             (GossipQuestUIInfo); Knöpfe entstehen erst beim ersten Gespräch aus dem Template, daher Hook vor dem
--             ersten Gespräch (Login) auf die Mixin-Tabelle.
--   Gruß      alle: QuestFrameGreetingPanel OnShow (XML bindet QuestFrameGreetingPanel_OnShow direkt) und die globale
--             Funktion (Mainline ruft sie bei QUEST_LOG_UPDATE direkt auf). Classic: QuestTitleButton1..MAX_NUM_QUESTS,
--             Mainline: QuestFrameGreetingPanel.titleButtonPool; Knöpfe tragen isActive (1/0) und die ID.
--             Level über GetActiveLevel/GetAvailableLevel: nicht in Blizzards generierter Doku und im UI-Code nicht
--             benutzt, deshalb nur, wenn es die Funktionen gibt (im Spiel prüfen).
--   Questlog  Era/TBC: QuestLog_Update, Knöpfe QuestLogTitle1..QUESTS_DISPLAYED (+ FauxScrollFrame-Versatz),
--             GetQuestLogTitle(i): Level 2., suggestedGroup 3. (Blizzards Vanilla-Code nennt es questTag);
--             Retail/Forever: QuestLogQuests_Update, Knöpfe in QuestScrollFrame.titleFramePool (button.questLogIndex,
--             button.Text), C_QuestLog.GetInfo(i).level/suggestedGroup.
--   Tracker   Era/TBC: QuestWatch_Update, Titelzeilen QuestWatchLineN wie dort gezählt (globale GetNumQuestWatches/
--             GetQuestIndexForWatch wie in Blizzards Vanilla-QuestLogFrame.lua; in Forever nicht geladen).
--             Forever: Blizzard_ObjectiveTracker, Rahmen QuestObjectiveTracker und CampaignQuestObjectiveTracker;
--             UpdateSingle(quest) setzt je Quest block:SetHeader(Titel) (Block per GetExistingBlock(questID), Schrift
--             block.HeaderText). Der Titel trägt dort schon "[Level+] " und den Quest-Typ (Camelot/
--             QuestUtilsOverrides.lua), deshalb ohne Level. LayoutContents ruft self.UpdateSingle über das Rahmenfeld,
--             daher Hook je Rahmen statt auf QuestObjectiveTrackerMixin. Retail: nicht gebaut.
local _, ns = ...

local QuestListHooks = {}
ns.QuestListHooks = QuestListHooks

local decorators = {}
local hooked = {}  -- [Name] = true, sobald eingehängt

function QuestListHooks.Register(decorator)
  table.insert(decorators, decorator)
end

local function anyEnabled()
  if not ns.db then return false end
  for _, decorator in ipairs(decorators) do
    if decorator.enabled(ns.db) then return true end
  end
  return false
end

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

-- Text eines Knopfs oder einer Schrift durch alle eingeschalteten Ergänzer; true, wenn geändert
local function decorateWidget(widget, quest)
  if not widget or not widget.GetText then return false end
  local text = readable(widget:GetText())
  if type(text) ~= "string" then return false end
  local changed = false
  for _, decorator in ipairs(decorators) do
    if decorator.enabled(ns.db) then
      local result = decorator.decorate(text, quest)
      if result then text, changed = result, true end
    end
  end
  if changed then widget:SetText(text) end
  return changed
end

-- Eintrag im Questlog (Lib/QuestLog.lua) als quest-Tabelle
local function logQuest(index)
  local entry = ns.QuestLog.Entry(index)
  if not entry then return nil end
  return { questID = entry.questID, level = entry.level, group = entry.group }
end

-- Gruppe einer Quest-ID, wenn sie im Log steht (Gespräche liefern nur das Level)
local function groupOf(questID)
  local entry = ns.QuestLog.Find(questID)
  return entry ~= nil and entry.group
end

-- Gespräch: Knopf nach Blizzards Setup; Knöpfe mit Resize passen ihre Höhe an
local function onGossipSetup(button, questInfo)
  if not anyEnabled() or type(questInfo) ~= "table" then return end
  local quest = { questID = readable(questInfo.questID), level = questInfo.questLevel, group = groupOf(questInfo.questID) }
  if decorateWidget(button, quest) and button.Resize then button:Resize() end
end

-- Gruß-Knöpfe: Classic feste Namen, Mainline ein Pool
local function greetingButtons()
  local buttons = {}
  local pool = QuestFrameGreetingPanel and QuestFrameGreetingPanel.titleButtonPool
  if type(pool) == "table" and pool.EnumerateActive then
    for button in pool:EnumerateActive() do table.insert(buttons, button) end
  else
    for i = 1, (MAX_NUM_QUESTS or 0) do
      local button = _G["QuestTitleButton" .. i]
      if button and button:IsShown() then table.insert(buttons, button) end
    end
  end
  return buttons
end

local function greetingLevel(button)
  local id = button.GetID and button:GetID()
  if type(id) ~= "number" or id <= 0 then return nil end
  if button.isActive == 1 then
    return GetActiveLevel and GetActiveLevel(id)
  end
  return GetAvailableLevel and GetAvailableLevel(id)
end

local function onGreetingShown()
  if not anyEnabled() then return end
  for _, button in ipairs(greetingButtons()) do
    -- Höhe wie Blizzard (Text + 2), falls die längere Zeile umbricht
    local textHeight = decorateWidget(button, { level = greetingLevel(button), group = false }) and button.GetTextHeight
      and button:GetTextHeight()
    if type(textHeight) == "number" and not ns.IsSecret(textHeight) then
      button:SetHeight(math.max(textHeight + 2, button:GetHeight() or 0))
    end
  end
end

-- Classic-Questlog: sichtbare Zeilen wie in QuestLog_Update
local function onClassicQuestLog()
  if not anyEnabled() or not QuestLogListScrollFrame then return end
  local offset = FauxScrollFrame_GetOffset and FauxScrollFrame_GetOffset(QuestLogListScrollFrame) or 0
  local numEntries = ns.QuestLog.Count()
  for i = 1, (QUESTS_DISPLAYED or 0) do
    local index = i + offset
    local button = _G["QuestLogTitle" .. i]
    local quest = button and index <= numEntries and logQuest(index)
    if quest then decorateWidget(button, quest) end
  end
end

-- Retail/Forever-Questlog: Knöpfe des Pools tragen ihren Log-Index
local function onMainlineQuestLog()
  if not anyEnabled() then return end
  local pool = QuestScrollFrame and QuestScrollFrame.titleFramePool
  if type(pool) ~= "table" or not pool.EnumerateActive then return end
  for button in pool:EnumerateActive() do
    local index = readable(button.questLogIndex)
    local quest = type(index) == "number" and logQuest(index)
    if quest then decorateWidget(button.Text, quest) end
  end
end

-- Classic-Tracker: Titelzeile je beobachteter Quest mit Zielen, gezählt wie in QuestWatch_Update
local function onQuestWatch()
  if not anyEnabled() or not GetNumQuestWatches or not GetQuestIndexForWatch then return end
  local line = 1
  local widest = 0
  for i = 1, (GetNumQuestWatches()) or 0 do
    local index = GetQuestIndexForWatch(i)
    local objectives = index and GetNumQuestLeaderBoards(index) or 0
    if objectives > 0 then
      local title = _G["QuestWatchLine" .. line]
      local quest = logQuest(index)
      if quest and decorateWidget(title, quest) and title.GetWidth then
        widest = math.max(widest, title:GetWidth() or 0)
      end
      line = line + objectives + 1
    end
  end
  -- Blizzard hat die Breite vor dem Ergänzen berechnet
  if QuestWatchFrame and widest > 0 and widest + 10 > (QuestWatchFrame:GetWidth() or 0) then
    QuestWatchFrame:SetWidth(widest + 10)
  end
end

-- Forever-Tracker: Kopfzeile der Quest nach Blizzards UpdateSingle. Level fehlt absichtlich (Blizzard zeigt es schon).
-- shortcut: Höhe hat Blizzard vor dem Ergänzen berechnet; bricht die längere Zeile um, überlappt sie (im Spiel prüfen)
local function onTrackerQuest(module, quest)
  if not anyEnabled() or type(quest) ~= "table" or not quest.GetID then return end
  local questID = readable(quest:GetID())
  local block = type(questID) == "number" and module.GetExistingBlock and module:GetExistingBlock(questID)
  if block then decorateWidget(block.HeaderText, { questID = questID, group = false }) end
end

local function hookTracker(name)
  local module = _G[name]
  if hooked[name] or type(module) ~= "table" or type(module.UpdateSingle) ~= "function" then return end
  hooked[name] = true
  hooksecurefunc(module, "UpdateSingle", function(...) ns.SafeCall(onTrackerQuest, ...) end)
  ns.Debug("questlist", "hooked %s.UpdateSingle", name)
end

local function hookFunction(name, hook)
  if hooked[name] or type(_G[name]) ~= "function" then return end
  hooked[name] = true
  hooksecurefunc(name, function(...) ns.SafeCall(hook, ...) end)
  ns.Debug("questlist", "hooked %s", name)
end

local function hookMixin(name, hook)
  local mixin = _G[name]
  if hooked[name] or type(mixin) ~= "table" or type(mixin.Setup) ~= "function" then return end
  hooked[name] = true
  hooksecurefunc(mixin, "Setup", function(...) ns.SafeCall(hook, ...) end)
  ns.Debug("questlist", "hooked %s.Setup", name)
end

local function hookAll()
  hookMixin("GossipAvailableQuestButtonMixin", onGossipSetup)
  hookMixin("GossipActiveQuestButtonMixin", onGossipSetup)
  hookFunction("QuestFrameGreetingPanel_OnShow", onGreetingShown)
  if not hooked.greetingScript and QuestFrameGreetingPanel and QuestFrameGreetingPanel.HookScript then
    hooked.greetingScript = true
    QuestFrameGreetingPanel:HookScript("OnShow", function() ns.SafeCall(onGreetingShown) end)
  end
  hookFunction("QuestLog_Update", onClassicQuestLog)
  hookFunction("QuestWatch_Update", onQuestWatch)
  hookFunction("QuestLogQuests_Update", onMainlineQuestLog)
  if ns.Client.IsForever() then
    hookTracker("QuestObjectiveTracker")
    hookTracker("CampaignQuestObjectiveTracker")
  end
end

-- Erst nach dem Login (alle Blizzard-Rahmen geladen); spätere Blizzard-Addons über ADDON_LOADED
ns.OnLogin(hookAll)
ns.RegisterEvent("ADDON_LOADED", hookAll)

-- Kein Neuaufbau beim Umschalten: Blizzard-Funktionen aus Addon-Code aufzurufen könnte Taint verbreiten; die Listen
-- zeigen die Änderung beim nächsten eigenen Aufbau (Öffnen, Blättern, Questupdate).

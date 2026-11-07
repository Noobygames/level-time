-- Quest-Level vor Questnamen (Roadmap 259, Einstellung questLevels, Standard aus): "[12] Titel", "[12+] Titel" für
-- Gruppenquests (suggestedGroup > 0) in Questlog, Gesprächs- und Grußlisten und (Classic) im Quest-Tracker.
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
--   Tracker   Era/TBC: QuestWatch_Update, Titelzeilen QuestWatchLineN wie dort gezählt. Retail/Forever (ObjectiveTracker)
--             nicht gebaut.
local _, ns = ...

local QuestLevels = {}
ns.QuestLevels = QuestLevels

local PREFIX_PATTERN = "^%[%d+%+?%] "  -- schon ergänzt (Blizzard hat den Text nicht neu gesetzt)
local hooked = {}  -- [Name] = true, sobald eingehängt

local function isEnabled()
  return ns.db and ns.db.questLevels
end

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

-- "[12] " bzw. "[12+] "; nil ohne lesbares Level
function QuestLevels.Tag(level, group)
  level = readable(level)
  if type(level) ~= "number" or level <= 0 then return nil end
  return string.format("[%d%s] ", level, group and "+" or "")
end

-- Fügt das Level nach führenden Leerzeichen ein (Blizzards Questlog rückt mit "  " ein), nur einmal
function QuestLevels.Prefix(text, level, group)
  local tag = QuestLevels.Tag(level, group)
  text = readable(text)
  if not tag or type(text) ~= "string" then return nil end
  local indent, rest = text:match("^(%s*)(.*)$")
  if rest:find(PREFIX_PATTERN) then return nil end
  return indent .. tag .. rest
end

-- Level und Gruppe eines Eintrags im Questlog (Lib/QuestLog.lua)
local function logEntry(index)
  local entry = ns.QuestLog.Entry(index)
  if not entry then return nil end
  return entry.level, entry.group
end

-- Gruppe einer Quest-ID, wenn sie im Log steht (Gespräche liefern nur das Level)
local function groupOf(questID)
  local entry = ns.QuestLog.Find(questID)
  return entry ~= nil and entry.group
end

-- Text eines Knopfs oder einer Schrift ergänzen; Knöpfe mit Resize (Gespräch) passen ihre Höhe an
local function prefixWidget(widget, level, group)
  if not widget or not widget.GetText then return false end
  local text = QuestLevels.Prefix(widget:GetText(), level, group)
  if not text then return false end
  widget:SetText(text)
  return true
end

-- Gespräch: Knopf nach Blizzards Setup
local function onGossipSetup(button, questInfo)
  if not isEnabled() or type(questInfo) ~= "table" then return end
  if prefixWidget(button, questInfo.questLevel, groupOf(questInfo.questID)) and button.Resize then
    button:Resize()
  end
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
  if not isEnabled() then return end
  for _, button in ipairs(greetingButtons()) do
    -- Höhe wie Blizzard (Text + 2), falls die längere Zeile umbricht
    local textHeight = prefixWidget(button, greetingLevel(button), false) and button.GetTextHeight
      and button:GetTextHeight()
    if type(textHeight) == "number" and not ns.IsSecret(textHeight) then
      button:SetHeight(math.max(textHeight + 2, button:GetHeight() or 0))
    end
  end
end

-- Classic-Questlog: sichtbare Zeilen wie in QuestLog_Update
local function onClassicQuestLog()
  if not isEnabled() or not QuestLogListScrollFrame then return end
  local offset = FauxScrollFrame_GetOffset and FauxScrollFrame_GetOffset(QuestLogListScrollFrame) or 0
  local numEntries = ns.QuestLog.Count()
  for i = 1, (QUESTS_DISPLAYED or 0) do
    local index = i + offset
    local button = _G["QuestLogTitle" .. i]
    if button and index <= numEntries then
      local level, group = logEntry(index)
      if level then prefixWidget(button, level, group) end
    end
  end
end

-- Retail/Forever-Questlog: Knöpfe des Pools tragen ihren Log-Index
local function onMainlineQuestLog()
  if not isEnabled() then return end
  local pool = QuestScrollFrame and QuestScrollFrame.titleFramePool
  if type(pool) ~= "table" or not pool.EnumerateActive then return end
  for button in pool:EnumerateActive() do
    local index = readable(button.questLogIndex)
    if type(index) == "number" then
      local level, group = logEntry(index)
      if level then prefixWidget(button.Text, level, group) end
    end
  end
end

-- Classic-Tracker: Titelzeile je beobachteter Quest mit Zielen, gezählt wie in QuestWatch_Update
local function onQuestWatch()
  if not isEnabled() or not GetNumQuestWatches or not GetQuestIndexForWatch then return end
  local line = 1
  local widest = 0
  for i = 1, (GetNumQuestWatches()) or 0 do
    local index = GetQuestIndexForWatch(i)
    local objectives = index and GetNumQuestLeaderBoards(index) or 0
    if objectives > 0 then
      local title = _G["QuestWatchLine" .. line]
      local level, group = logEntry(index)
      if level and prefixWidget(title, level, group) and title.GetWidth then
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

local function hookFunction(name, hook)
  if hooked[name] or type(_G[name]) ~= "function" then return end
  hooked[name] = true
  hooksecurefunc(name, function(...) ns.SafeCall(hook, ...) end)
  ns.Debug("questlevels", "hooked %s", name)
end

local function hookMixin(name, hook)
  local mixin = _G[name]
  if hooked[name] or type(mixin) ~= "table" or type(mixin.Setup) ~= "function" then return end
  hooked[name] = true
  hooksecurefunc(mixin, "Setup", function(...) ns.SafeCall(hook, ...) end)
  ns.Debug("questlevels", "hooked %s.Setup", name)
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
end

-- Erst nach dem Login (alle Blizzard-Rahmen geladen); spätere Blizzard-Addons über ADDON_LOADED
ns.OnLogin(hookAll)
ns.RegisterEvent("ADDON_LOADED", hookAll)

-- Kein Neuaufbau beim Umschalten: Blizzard-Funktionen aus Addon-Code aufzurufen könnte Taint verbreiten; die Listen
-- zeigen die Änderung beim nächsten eigenen Aufbau (Öffnen, Blättern, Questupdate).

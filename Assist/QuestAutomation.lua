-- Quests ohne Klicks: annehmen (autoAcceptQuests), geteilte Quests und Eskorten bestätigen
-- (autoAcceptShared), abgeben (autoTurnIn) und bei mehreren Belohnungen die wertvollste wählen
-- (autoChooseReward); Gespräche mit nur einer Option überspringen (skipGossip).
-- Abläufe wie in Blizzards QuestFrame/GossipFrame aller Clients:
--   QUEST_DETAIL          Quest-Text offen: AcceptQuest, bei Quests, die der Client schon selbst
--                         angenommen hat (QuestGetAutoAccept), AcknowledgeAutoAcceptQuest.
--                         PvP-Quests (QuestFlagsPVP) fragen im Spiel nach, die bleiben manuell.
--                         Von einem Spieler geteilt (die Einheit "questnpc" ist ein Spieler): nur mit
--                         autoAcceptShared und nur, wenn declineSharedQuests (Social.lua) sie nicht ablehnt. Grau: C_QuestLog.IsQuestTrivial(GetQuestID()), das gibt es
--                         nur in Retail und WoW Forever; Classic Era/TBC filtern graue Quests nur in
--                         den Quest-Listen (Gespräch, QUEST_GREETING).
--   QUEST_ACCEPT_CONFIRM  Quest eines anderen Spielers (Eskorte): ConfirmAcceptQuest, Dialog schließen; nicht, wenn
--                         declineSharedQuests sie ablehnt.
--   QUEST_PROGRESS        Abgabe, Gegenstände prüfen: CompleteQuest, wenn IsQuestCompletable.
--   QUEST_COMPLETE        Belohnung: GetQuestReward(Wahl); Wahl = 1 bei einer Belohnung zur Auswahl,
--                         sonst 0 (wie QuestInfoFrame.itemChoice). Quests, die Geld kosten
--                         (GetQuestMoneyToGet), fragen im Spiel nach und bleiben manuell.
--   GOSSIP_SHOW           Gesprächsfenster mit Quest-Listen: zuerst fertige Quests
--                         (C_GossipInfo.SelectActiveQuest), dann neue (SelectAvailableQuest), je questID.
--   QUEST_GREETING        alte Quest-Liste ohne Gespräch: dasselbe mit SelectActiveQuest/
--                         SelectAvailableQuest(index), fertig laut GetActiveTitle.
-- Graue (triviale) und ignorierte Quests werden nicht angenommen: beim Leveln Zeitverschwendung.
-- Wiederholbare Quests wählt die Automatik nie selbst aus den Listen aus. Öffnet man sie von Hand, bleibt die
-- Abgabe in Retail/Forever manuell (C_QuestLog.IsRepeatableQuest(GetQuestID())); Classic Era/TBC kennen das im
-- Dialog nicht, dort gibt autoTurnIn sie ab, außer die Sperrliste (QuestBlocklist.lua) nennt NPC oder Quest.
-- Sperrliste: NPCs und Quests, deren Abgabe Gegenstände verbraucht (Stoffspenden), plus eigene Einträge
-- (Einstellung questExclude); dort tut die Automatik nichts, auch kein Gespräch überspringen.
-- Gespräch überspringen wie Blizzards GossipFrame bei selectOptionWhenOnlyOption: keine Quests,
-- genau eine verfügbare Option (GossipOptionStatus Available), kein ForceGossip; gewählt mit
-- C_GossipInfo.SelectOptionByIndex(orderIndex). Optionen mit Bestätigung fragt das Spiel weiter nach. Optionen mit
-- Flags oder Belohnungen (GossipOptionUIInfo.flags/rewards; normale Optionen haben laut Debug-Log flags 0 und keine
-- rewards) bleiben manuell.
local _, ns = ...
local Comfort = ns.Comfort
local Blocklist = ns.QuestBlocklist

local QuestAutomation = {}
ns.QuestAutomation = QuestAutomation

local QUEST_ACCEPT_POPUP = "QUEST_ACCEPT"  -- Blizzards Dialog zu QUEST_ACCEPT_CONFIRM
local NO_CHOICE = 0           -- GetQuestReward ohne Belohnung zur Auswahl
local OPTION_AVAILABLE = 0    -- Enum.GossipOptionStatus.Available

-- Wiederholbare Quests (Abgaben wie Runenstoff, Dunkelmond, Argentumdämmerung) bleiben manuell:
-- nach jeder Abgabe öffnet sich das Gespräch wieder, die Automatik würde alle Gegenstände abgeben.
local function isWorthTaking(quest)
  return not quest.isTrivial and not quest.isIgnored and not quest.repeatable
    and not Blocklist.IsBlockedQuest(quest.questID, quest.title)
end

-- Quest im offenen Dialog (Text, Abgabe, Belohnung): gesperrt oder in Retail/Forever als wiederholbar bekannt
local function isBlockedDialog()
  local questID = GetQuestID and GetQuestID()
  if Blocklist.Blocks(questID, GetTitleText()) then return true end
  if not (C_QuestLog.IsRepeatableQuest and type(questID) == "number" and questID ~= 0) then return false end
  local repeatable = C_QuestLog.IsRepeatableQuest(questID)
  local blocked = not ns.IsSecret(repeatable) and repeatable == true
  if blocked then ns.Debug("quests", "quest %s is repeatable, left to the player", questID) end
  return blocked
end

-- Erste lohnende Quest aus einer Liste von C_GossipInfo (GossipQuestUIInfo)
local function firstWorthTaking(quests)
  for _, quest in ipairs(quests) do
    if isWorthTaking(quest) then return quest end
  end
end

local function isShared()
  return UnitExists("questnpc") and UnitIsPlayer("questnpc")
end

-- Geteilte Quest, die Social.lua ablehnt (declineSharedQuests gewinnt gegen autoAcceptShared)
local function isDeclinedShare()
  return ns.Social.DeclinesSharedQuest(UnitName("questnpc"), UnitGUID("questnpc"))
end

-- Graue Quest im offenen Quest-Text; false, wo der Client das nicht verrät
local function isTrivialDetail()
  if not (C_QuestLog.IsQuestTrivial and GetQuestID) then return false end
  local questID = GetQuestID()
  return questID ~= nil and questID ~= 0 and C_QuestLog.IsQuestTrivial(questID)
end

ns.RegisterEvent("QUEST_DETAIL", function()
  local shared = isShared()
  if not Comfort.IsActive(shared and "autoAcceptShared" or "autoAcceptQuests") then return end
  if shared and isDeclinedShare() then return end
  if QuestFlagsPVP and QuestFlagsPVP() then return end
  if isBlockedDialog() then return end
  if isTrivialDetail() then
    ns.Debug("quests", "skipping trivial quest")
    return
  end
  if QuestGetAutoAccept and QuestGetAutoAccept() then
    ns.Debug("quests", "acknowledging auto-accepted quest")
    AcknowledgeAutoAcceptQuest()
  else
    ns.Debug("quests", "accepting quest")
    AcceptQuest()
  end
end)

ns.RegisterEvent("QUEST_ACCEPT_CONFIRM", function(name)
  if not Comfort.IsActive("autoAcceptShared") or ns.Social.DeclinesSharedQuest(name) then return end
  ns.Debug("quests", "confirming shared quest")
  ConfirmAcceptQuest()
  StaticPopup_Hide(QUEST_ACCEPT_POPUP)
end)

local function firstComplete(quests)
  for _, quest in ipairs(quests) do
    if quest.isComplete and not quest.repeatable and not Blocklist.IsBlockedQuest(quest.questID, quest.title) then
      return quest
    end
  end
end

ns.RegisterEvent("QUEST_PROGRESS", function()
  if not Comfort.IsActive("autoTurnIn") or not IsQuestCompletable() or isBlockedDialog() then return end
  ns.Debug("quests", "completing quest")
  CompleteQuest()
end)

-- Verkaufswert einer Belohnung zur Auswahl; nil, solange der Client das Item nicht kennt
local function choiceValue(index)
  local link = GetQuestItemLink("choice", index)
  return link and ns.Items.GetSellPrice(link)
end

-- Belohnung mit dem höchsten Verkaufswert; nil, wenn ein Wert noch unbekannt ist
local function mostValuableChoice(count)
  local best, bestValue
  for index = 1, count do
    local value = choiceValue(index)
    if not value then return nil end
    if not bestValue or value > bestValue then best, bestValue = index, value end
  end
  return best
end

-- Welche Belohnung genommen wird; nil = Spieler wählt selbst
function QuestAutomation.RewardChoice()
  local count = GetNumQuestChoices()
  if count == 0 then return NO_CHOICE end
  if count == 1 then return 1 end
  if ns.db.autoChooseReward then return mostValuableChoice(count) end
  return nil
end

ns.RegisterEvent("QUEST_COMPLETE", function()
  if not Comfort.IsActive("autoTurnIn") or GetQuestMoneyToGet() > 0 or isBlockedDialog() then return end
  local choice = QuestAutomation.RewardChoice()
  ns.Debug("quests", "reward choice %s", choice)
  if choice then GetQuestReward(choice) end
end)

local REPEAT_GUARD_SECONDS = 2  -- dieselbe Option nicht öfter in so kurzer Zeit wählen (Schleifen)
local lastSkipped  -- { id, at } der zuletzt automatisch gewählten Option

-- Die einzige Gesprächsoption, wenn es sonst nichts zu tun gibt (z.B. Flugmeister, Händler).
-- Als Geist nie: der Geistheiler hat genau eine Option ("Wiederbeleben"), die Wiederbelebungsschwäche kostet.
local function onlyOption()
  if UnitIsDeadOrGhost("player") then
    ns.Debug("quests", "gossip: ghost, no option skipped")
    return nil
  end
  if C_GossipInfo.GetNumAvailableQuests() > 0 or C_GossipInfo.GetNumActiveQuests() > 0 then return nil end
  if C_GossipInfo.ForceGossip() then return nil end
  local options = C_GossipInfo.GetOptions()
  if #options ~= 1 or options[1].status ~= OPTION_AVAILABLE then return nil end
  if (options[1].flags or 0) ~= 0 or (options[1].rewards and #options[1].rewards > 0) then return nil end
  -- Solche Optionen wählt Blizzards GossipFrame schon selbst (HandleShow), sonst doppelt gewählt
  if options[1].selectOptionWhenOnlyOption then return nil end
  local id = options[1].gossipOptionID or options[1].orderIndex
  if lastSkipped and lastSkipped.id == id and GetTime() - lastSkipped.at < REPEAT_GUARD_SECONDS then return nil end
  lastSkipped = { id = id, at = GetTime() }
  return options[1]
end

-- Gesprächsfenster: erst fertige Quests abgeben, dann die nächste lohnende öffnen
-- (QUEST_PROGRESS/QUEST_DETAIL übernehmen den Rest), sonst die einzige Option wählen
function QuestAutomation.HandleGossip()
  if Blocklist.IsBlockedNpc() then
    ns.Debug("quests", "gossip: blocked npc")
    return false
  end
  if Comfort.IsActive("autoTurnIn") then
    local quest = firstComplete(C_GossipInfo.GetActiveQuests())
    if quest then
      ns.Debug("quests", "gossip: turning in quest %s", quest.questID)
      C_GossipInfo.SelectActiveQuest(quest.questID)
      return true
    end
  end
  if Comfort.IsActive("autoAcceptQuests") then
    local quest = firstWorthTaking(C_GossipInfo.GetAvailableQuests())
    if quest then
      ns.Debug("quests", "gossip: opening quest %s", quest.questID)
      C_GossipInfo.SelectAvailableQuest(quest.questID)
      return true
    end
  end
  if Comfort.IsActive("skipGossip") then
    local option = onlyOption()
    if option then
      ns.Debug("quests", "gossip: skipping to option %s", option.orderIndex)
      C_GossipInfo.SelectOptionByIndex(option.orderIndex)
      return true
    end
  end
  return false
end

function QuestAutomation.HandleGreeting()
  if Blocklist.IsBlockedNpc() then
    ns.Debug("quests", "greeting: blocked npc")
    return false
  end
  if Comfort.IsActive("autoTurnIn") then
    for index = 1, GetNumActiveQuests() do
      local title, isComplete = GetActiveTitle(index)
      if isComplete and not Blocklist.IsBlockedQuest(nil, title) then
        ns.Debug("quests", "greeting: turning in quest %s", index)
        SelectActiveQuest(index)
        return true
      end
    end
  end
  if Comfort.IsActive("autoAcceptQuests") then
    for index = 1, GetNumAvailableQuests() do
      -- 3. Rückgabe in allen Clients: isRepeatable (2. ist in Classic isDaily, sonst frequency)
      local isTrivial, _, isRepeatable = GetAvailableQuestInfo(index)
      if not isTrivial and not isRepeatable and not Blocklist.IsBlockedQuest(nil, GetAvailableTitle(index)) then
        ns.Debug("quests", "greeting: opening quest %s", index)
        SelectAvailableQuest(index)
        return true
      end
    end
  end
  return false
end

ns.RegisterEvent("GOSSIP_SHOW", function()
  QuestAutomation.HandleGossip()
end)

ns.RegisterEvent("QUEST_GREETING", function()
  QuestAutomation.HandleGreeting()
end)

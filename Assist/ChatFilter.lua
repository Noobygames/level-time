-- Spam-Filter für den Chat (Reiter Komfort, Chat; je Einstellung, Standard aus), bewusst zurückhaltend:
--   filterDrunkSpam   Systemmeldungen, dass andere Spieler betrunken werden oder nüchtern sind
--                     (DRUNK_MESSAGE_OTHER1..4, DRUNK_MESSAGE_ITEM_OTHER1..4 über ChatPatterns). Eigene bleiben.
--   filterSpellLinks  Zauber-Links anderer Spieler in Sagen/Schreien/Emote/Gruppe/Schlachtzug/Instanz, solange man
--                     selbst kämpft (Ansagen wie "Unterbrochen: [Zauber]"); außerhalb des Kampfs bleibt alles.
-- Über Blizzards Nachrichtenfilter ChatFrameUtil.AddMessageEventFilter (alle Clients; Fallback der ältere Alias
-- ChatFrame_AddMessageEventFilter): true = Zeile verwerfen. Blizzard ruft den Filter nur mit lesbaren Werten
-- (canaccessvalue); geheime Texte prüfen wir trotzdem selbst. Ein Filter je Event, er liest die Einstellung erst
-- beim Aufruf, daher kein An- und Abmelden.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    filterDrunkSpam = false,
    filterSpellLinks = false,
  },
})
local ChatPatterns = ns.ChatPatterns

local ChatFilter = {}
ns.ChatFilter = ChatFilter

local DRUNK_VARIANTS = 4
local SPELL_LINK = "|Hspell:"
local SYSTEM_EVENT = "CHAT_MSG_SYSTEM"
ChatFilter.SPELL_LINK_EVENTS = {
  "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
  "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
}

local drunkPatterns  -- erst beim ersten Gebrauch kompiliert

local function drunkFormats()
  local names = {}
  for index = 1, DRUNK_VARIANTS do
    table.insert(names, "DRUNK_MESSAGE_ITEM_OTHER" .. index)
    table.insert(names, "DRUNK_MESSAGE_OTHER" .. index)
  end
  return ChatPatterns.CompileGlobals(names)
end

function ChatFilter.IsDrunkSpam(message)
  drunkPatterns = drunkPatterns or drunkFormats()
  return ChatPatterns.MatchAny(message, drunkPatterns) ~= nil
end

-- Name ohne Realm (Absender kommen als "Name-Realm")
local function baseName(name)
  return (name:match("^([^-]+)")) or name
end

function ChatFilter.IsSpellLinkSpam(message, sender)
  if not message:find(SPELL_LINK, 1, true) or not UnitAffectingCombat("player") then return false end
  return type(sender) ~= "string" or baseName(sender) ~= UnitName("player")
end

local function readable(message, sender)
  return type(message) == "string" and not ns.IsSecret(message) and not ns.IsSecret(sender)
end

local function systemFilter(_, _, message)
  if not (ns.db and ns.db.filterDrunkSpam and readable(message)) then return false end
  local spam = ChatFilter.IsDrunkSpam(message)
  if spam then ns.Debug("chat", "filtered drunk message: %s", message) end  -- je Chatfenster einmal
  return spam
end

local function spellLinkFilter(_, _, message, sender)
  if not (ns.db and ns.db.filterSpellLinks and readable(message, sender)) then return false end
  local spam = ChatFilter.IsSpellLinkSpam(message, sender)
  if spam then ns.Debug("chat", "filtered spell link from %s", sender) end  -- je Chatfenster einmal
  return spam
end

local function addFilter(event, filter)
  if ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter then
    ChatFrameUtil.AddMessageEventFilter(event, filter)
  elseif ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter(event, filter)
  end
end

addFilter(SYSTEM_EVENT, systemFilter)
for _, event in ipairs(ChatFilter.SPELL_LINK_EVENTS) do addFilter(event, spellLinkFilter) end

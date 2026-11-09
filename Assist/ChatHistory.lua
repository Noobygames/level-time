-- Letzten Chat nach /reload wiederherstellen (Reiter Komfort, Chat; Einstellung restoreChat, Standard aus).
-- Beim Logout (kommt auch bei /reload) merkt sich das Modul je Chatfenster die letzten MAX_LINES Zeilen mit Farbe
-- in character.chatHistory = { savedAt, frames = { [Fensternummer] = { { text, r, g, b }, ... } } }; beim nächsten
-- Login schreibt es sie wieder ins Fenster (AddMessage), aber nur nach einer kurzen Pause wie bei /reload oder
-- Disconnect (Session.IsShortGap, gleiche Grenze wie die Session-Fortsetzung). Danach ist der Speicher leer.
-- Zeilen über Blizzards ScrollingMessageFrame (GetNumMessages, GetMessageInfo(i): Text, r, g, b; 1 = älteste).
-- Nicht gespeichert: das Kampflog (ChatFrame2, eigene Zeilen), geheime Zeilen (Retail/Forever) und Zeilen mit
-- geschützten Battle.net-Namen (|K...|k gilt nur in der laufenden Sitzung).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    restoreChat = false,
  },
})

local ChatHistory = {}
ns.ChatHistory = ChatHistory

ChatHistory.MAX_LINES = 50
local COMBAT_LOG_INDEX = 2
local PROTECTED_NAME = "|K"

local function isStorable(text)
  return type(text) == "string" and not ns.IsSecret(text) and text ~= "" and not text:find(PROTECTED_NAME, 1, true)
end

-- Die letzten MAX_LINES lesbaren Zeilen eines Fensters, älteste zuerst
function ChatHistory.Collect(chatFrame)
  local lines = {}
  if not (chatFrame and chatFrame.GetNumMessages) then return lines end
  local count = chatFrame:GetNumMessages() or 0
  for index = math.max(1, count - ChatHistory.MAX_LINES + 1), count do
    local text, r, g, b = chatFrame:GetMessageInfo(index)
    if isStorable(text) then table.insert(lines, { text, r, g, b }) end
  end
  return lines
end

local function save()
  if not ns.db.restoreChat then
    ns.character.chatHistory = nil
    return
  end
  local frames = {}
  for index, chatFrame in ipairs(ns.ChatFrames()) do
    if index ~= COMBAT_LOG_INDEX then frames[index] = ChatHistory.Collect(chatFrame) end
  end
  ns.character.chatHistory = { savedAt = time(), frames = frames }
end

local function restore()
  local saved = ns.character.chatHistory
  ns.character.chatHistory = nil
  if not (ns.db.restoreChat and type(saved) == "table" and ns.Session.IsShortGap(saved.savedAt)) then return end
  local restored = 0
  for index, lines in pairs(type(saved.frames) == "table" and saved.frames or {}) do
    local chatFrame = _G["ChatFrame" .. tostring(index)]
    if chatFrame and type(lines) == "table" then
      for _, line in ipairs(lines) do
        if type(line) == "table" and type(line[1]) == "string" then
          chatFrame:AddMessage(line[1], line[2], line[3], line[4])
          restored = restored + 1
        end
      end
    end
  end
  ns.Debug("chat", "restored %s chat lines", restored)
end

ns.OnLogin(restore)
ns.OnLogout(save)

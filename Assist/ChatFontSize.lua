-- Chat-Schriftgröße frei wählen (Reiter Komfort, Chat; chatFontOverride, Standard aus): alle festen Chatfenster
-- bekommen chatFontSize (CHAT_FONT_SIZE_MIN..MAX), auch Größen, die Blizzards Menü nicht anbietet (CHAT_FONT_HEIGHTS
-- 12-27 in Retail/Forever, 12-18 in Classic). Statt Blizzards Menü-Tabelle zu ändern (geteilte Blizzard-Tabelle,
-- das Classic-Menü läuft über UIDropDownMenu) setzt das Modul die Größe wie das Menü selbst mit
-- FCF_SetChatWindowFontSize(nil, chatFrame, size) (FloatingChatFrame.lua in allen Clients; speichert sie per
-- SetChatWindowSize). Die vorherigen Größen werden je Charakter gemerkt (character.chatFontOriginals, Fenster-ID ->
-- Größe aus GetChatWindowInfo; der Client speichert sie je Charakter) und beim Ausschalten zurückgesetzt.
-- Chatfenster sind nicht geschützt, im Kampf geht es daher auch.
local _, ns = ...

local ChatFontSize = {}
ns.ChatFontSize = ChatFontSize

ChatFontSize.MIN = 8
ChatFontSize.MAX = 32

function ChatFontSize.IsAvailable()
  return FCF_SetChatWindowFontSize ~= nil and GetChatWindowInfo ~= nil
end

local function sizeOf(chatFrame)
  local _, size = GetChatWindowInfo(chatFrame:GetID())
  return tonumber(size)
end

local function setSize(chatFrame, size)
  if sizeOf(chatFrame) ~= size then FCF_SetChatWindowFontSize(nil, chatFrame, size) end
end

local function override(character, size)
  character.chatFontOriginals = character.chatFontOriginals or {}
  local originals = character.chatFontOriginals
  for _, chatFrame in ipairs(ns.ChatFrames()) do
    local id = chatFrame:GetID()
    local current = sizeOf(chatFrame)
    if current then
      if originals[id] == nil then originals[id] = current end
      setSize(chatFrame, size)
    end
  end
end

local function restore(character)
  local originals = character.chatFontOriginals
  if not originals then return end
  for _, chatFrame in ipairs(ns.ChatFrames()) do
    local original = originals[chatFrame:GetID()]
    if original then setSize(chatFrame, original) end
  end
  character.chatFontOriginals = nil
  ns.Debug("comfort", "chat font sizes restored")
end

function ChatFontSize.Clamp(size)
  size = math.floor((tonumber(size) or ChatFontSize.MIN) + 0.5)
  return math.max(ChatFontSize.MIN, math.min(ChatFontSize.MAX, size))
end

ns.RegisterApply(function(db)
  local character = ns.character
  if not character or not ChatFontSize.IsAvailable() then return end
  if db.chatFontOverride then override(character, ChatFontSize.Clamp(db.chatFontSize)) else restore(character) end
end)

-- Teil der nachgebauten WoW-API (tests/wow_stub.lua):
-- Timer, Chatfenster, Nachrichtenfilter, Sprache.
-- Gemeinsame Helfer kommen über stub (Spielzustand, Frames).
local stub = ...
local state = stub.state
local newFrame = stub.newFrame

-- Timer laufen nicht von selbst; Tests starten sie mit wow.runTimers()
wow.timers = {}
C_Timer = { After = function(_, callback) table.insert(wow.timers, callback) end }
-- Chatfenster wie im Client: schreiben /played in ihrem TIME_PLAYED_MSG-Handler (wow.playedLines)
-- Wie im Client ohne loadDeprecationFallbacks: nur die Konstante, nicht der Alias NUM_CHAT_WINDOWS
Constants = { ChatFrameConstants = { MaxChatWindows = 2 } }
wow.playedLines = 0
-- Zeilen wie Blizzards ScrollingMessageFrame: GetMessageInfo(1) ist die älteste (chatFrame._messages)
for index = 1, Constants.ChatFrameConstants.MaxChatWindows do
  local chatFrame = newFrame()
  chatFrame._events.TIME_PLAYED_MSG = true
  chatFrame._scripts.OnEvent = function() wow.playedLines = wow.playedLines + 1 end
  chatFrame._messages = {}
  chatFrame.GetNumMessages = function(self) return #self._messages end
  chatFrame.GetMessageInfo = function(self, messageIndex) return self._messages[messageIndex], 1, 1, 1 end
  chatFrame.AddMessage = function(self, text) table.insert(self._messages, text) end
  chatFrame.GetName = function() return "ChatFrame" .. index end
  chatFrame.GetID = function() return index end
  -- Klemm-Abstände wie FloatingChatFrame.lua (Classic)
  chatFrame._clamp = { -35, 35, 26, -50 }
  chatFrame.GetClampRectInsets = function(self) return unpack(self._clamp) end
  chatFrame.SetClampRectInsets = function(self, left, right, top, bottom) self._clamp = { left, right, top, bottom } end
  -- Eingabezeile, Knopfleiste und Reiter wie in FloatingChatFrame.xml
  chatFrame.editBox = newFrame()
  chatFrame.editBox:SetPoint("TOPLEFT", chatFrame, "BOTTOMLEFT", -5, -2)
  chatFrame.buttonFrame = newFrame()
  chatFrame.buttonFrame._parent = chatFrame
  _G["ChatFrame" .. index] = chatFrame
  _G["ChatFrame" .. index .. "Tab"] = newFrame()
end
CHAT_FRAMES = { "ChatFrame1", "ChatFrame2" }
-- Schriftgröße je Chatfenster (GetChatWindowInfo, zweiter Wert), gesetzt wie Blizzards Menü
wow.chatWindowSizes = {}
function GetChatWindowInfo(id) return "Chat " .. id, wow.chatWindowSizes[id] or 14 end
function FCF_SetChatWindowFontSize(_, chatFrame, size) wow.chatWindowSizes[chatFrame:GetID()] = size end
-- Nachrichtenfilter wie Blizzards ChatFrameUtil; wow.chatFiltered(event, ...) = true, wenn ein Filter verwirft
wow.chatFilters = {}
ChatFrameUtil = {
  AddMessageEventFilter = function(event, filter)
    wow.chatFilters[event] = wow.chatFilters[event] or {}
    table.insert(wow.chatFilters[event], filter)
  end,
}
function wow.chatFiltered(event, ...)
  for _, filter in ipairs(wow.chatFilters[event] or {}) do
    if filter(ChatFrame1, event, ...) then return true end
  end
  return false
end
DEFAULT_CHAT_FRAME, SELECTED_CHAT_FRAME = ChatFrame1, ChatFrame1
date = os.date

function print(...)
  local parts = {}
  for i = 1, select("#", ...) do
    parts[i] = tostring((select(i, ...)))
  end
  table.insert(wow.printed, table.concat(parts, " "))
end

function GetLocale() return "deDE" end

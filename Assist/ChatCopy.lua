-- Chat kopieren: zeigt die Zeilen eines Chatfensters als Text im Kopierfenster (Export.Show), damit man
-- sie mit Strg+C herausholen kann (z.B. /dump-Ausgaben). Addons können sonst nichts aus dem Chat kopieren.
--   /lt copy                  aktuelles Chatfenster, ohne Einstellung
--   Einstellung chatCopyButton (Reiter "Komfort", aus): kleiner Button oben rechts an jedem Chatfenster
-- Zeilen über Blizzards ScrollingMessageFrame (alle Clients, Blizzard_SharedXML): GetNumMessages und
-- GetMessageInfo(i) mit i = 1 für die älteste Zeile. Geheime Zeilen (Retail/Forever, z.B. während der
-- Chat-Sperre) lassen sich nicht lesen und werden nur gezählt.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    chatCopyButton = false,
  },
})
local L = ns.L

local ChatCopy = {}
ns.ChatCopy = ChatCopy

local BUTTON_SIZE = 18
local BUTTON_LABEL = "C"

-- Chat-Formatierung entfernen: Farben und Links (Format.PlainText), Texturen, Atlas-Symbole und
-- geschützte Battle.net-Namen (|K...|k, für Addons nicht lesbar)
local function plainLine(text)
  text = ns.Format.PlainText(text)
  return (text:gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|K.-|k", "?"))
end

-- Zeilen eines Chatfensters, älteste zuerst; Anzahl der geheimen Zeilen dazu
function ChatCopy.Lines(chatFrame)
  local lines, hidden = {}, 0
  if not chatFrame or not chatFrame.GetNumMessages then return lines, hidden end
  for index = 1, chatFrame:GetNumMessages() do
    local text = chatFrame:GetMessageInfo(index)
    if ns.IsSecret(text) then
      hidden = hidden + 1
    elseif text then
      table.insert(lines, plainLine(text))
    end
  end
  return lines, hidden
end

function ChatCopy.Show(chatFrame)
  local lines, hidden = ChatCopy.Lines(chatFrame)
  if hidden > 0 then table.insert(lines, string.format(L.CHAT_COPY_HIDDEN, hidden)) end
  ns.Export.Show(L.CHAT_COPY_TITLE, table.concat(lines, "\n"))
end

-- Gerade gewähltes Chatfenster (Reiter), sonst das Standardfenster
function ChatCopy.ShowCurrent()
  ChatCopy.Show(SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME)
end

---------------------------------------------------------------------------
-- Buttons an den Chatfenstern, erst angelegt, wenn die Einstellung an ist
---------------------------------------------------------------------------
local buttons = {}

local function createButton(chatFrame)
  local button = ns.Widgets.CreateButton(chatFrame, BUTTON_SIZE, BUTTON_SIZE, function() ChatCopy.Show(chatFrame) end)
  button:SetText(BUTTON_LABEL)
  button:SetPoint("TOPRIGHT", chatFrame, "TOPRIGHT", 0, 0)
  ns.Widgets.AttachTooltip(button, function() return L.CHAT_COPY_TITLE end, function() return L.CHAT_COPY_BUTTON_TIP end)
  return button
end

ns.RegisterApply(function(db)
  for _, chatFrame in ipairs(ns.ChatFrames()) do
    if db.chatCopyButton and not buttons[chatFrame] then
      buttons[chatFrame] = createButton(chatFrame)
    end
    if buttons[chatFrame] then buttons[chatFrame]:SetShown(db.chatCopyButton) end
  end
end)

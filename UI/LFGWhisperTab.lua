-- Reiter Flüstern des Gruppensuche-Fensters (UI/LFGWindow.lua, LT-389): Verlauf der Flüster an Gruppenleiter und
-- ihrer Antworten (Assist/LFGWhispers.lua), neueste zuerst, nur diese Sitzung. Klick auf eine Zeile öffnet den Chat
-- an den Spieler (ChatFrameUtil.SendTell, nur aus dem Klick; gesendet wird nichts ohne Enter des Spielers).
local _, ns = ...
if not ns.Client.IsForever() then return end

local L = ns.L
local Theme = ns.Theme
local LFGWhispers = ns.LFGWhispers
local LFGWindow = ns.LFGWindow
local parts = LFGWindow.Parts()
local container = LFGWindow.whisperContainer

local PAD = LFGWindow.PAD
local TOP = 40            -- unter dem Porträtring
local ROW_HEIGHT = 30
local ROW_GAP = 2

local emptyText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
emptyText:SetPoint("TOP", 0, -(TOP + 40))
emptyText:SetWidth(LFGWindow.WIDTH - 2 * PAD)
emptyText:SetTextColor(Theme.RGB("muted"))
parts.whisperEmpty = emptyText

local function openChat(name)
  local tell = ChatFrameUtil and ChatFrameUtil.SendTell or ChatFrame_SendTell
  if tell then tell(name) end
end

local rows = {}
parts.whisperRows = rows
local function createRow(index)
  local row = CreateFrame("Button", nil, container)
  row:SetSize(LFGWindow.WIDTH - 2 * PAD, ROW_HEIGHT)
  row:SetPoint("TOPLEFT", PAD, -(TOP + (index - 1) * (ROW_HEIGHT + ROW_GAP)))
  row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
  row.highlight:SetAllPoints()
  row.highlight:SetColorTexture(1, 1, 1, 0.08)
  row.head = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.head:SetPoint("TOPLEFT", 4, -3)
  row.head:SetJustifyH("LEFT")
  row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.text:SetPoint("TOPLEFT", row.head, "BOTTOMLEFT", 0, -1)
  row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
  row.text:SetJustifyH("LEFT")
  row.text:SetWordWrap(false)
  row:SetScript("OnClick", function(self) if self.entry then openChat(self.entry.name) end end)
  ns.Widgets.AttachTooltip(row, function() return row.entry and row.entry.name or "" end,
    function() return L.LFG_WHISPERS_ROW_TIP end)
  rows[index] = row
  return row
end

local function refresh()
  local entries = LFGWhispers.GetEntries()
  emptyText:SetText(#entries == 0 and L.LFG_WHISPERS_EMPTY or "")
  for index = 1, LFGWhispers.MAX_ENTRIES do
    local row = rows[index] or createRow(index)
    local entry = entries[index]
    row.entry = entry
    row:SetShown(entry ~= nil)
    if entry then
      row.head:SetText(string.format(entry.outgoing and L.LFG_WHISPER_TO or L.LFG_WHISPER_FROM, entry.name)
        .. "  " .. date("%H:%M", entry.time))
      row.text:SetText(entry.text)
    end
  end
end

LFGWindow.RegisterTab(LFGWindow.TAB_WHISPERS, refresh)
LFGWhispers.OnChange(function()
  if LFGWindow.IsShown() and LFGWindow.State().tab == LFGWindow.TAB_WHISPERS then refresh() end
end)

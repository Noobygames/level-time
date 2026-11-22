-- Reiter Mitspieler des Gruppensuche-Fensters (UI/LFGWindow.lua, LT-392): letzte Mitspieler aus der Gruppenliste
-- (Assist/LFGPlayers.lua), neueste zuerst. Klick auf eine Zeile wechselt die Bewertung (keine, +, -); Abbrecher tragen
-- ein "!". Die Bewertung erscheint als Kurzzeichen vor dem Leiternamen in der Suche.
local _, ns = ...
if not ns.Client.IsForever() then return end

local L = ns.L
local Theme = ns.Theme
local LFGPlayers = ns.LFGPlayers
local LFGWindow = ns.LFGWindow
local parts = LFGWindow.Parts()
local container = LFGWindow.playersContainer

local PAD = LFGWindow.PAD
local TOP = 40            -- unter dem Porträtring
local ROW_HEIGHT = 22
local ROW_GAP = 2
local MAX_ROWS = 20

local emptyText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
emptyText:SetPoint("TOP", 0, -(TOP + 40))
emptyText:SetWidth(LFGWindow.WIDTH - 2 * PAD)
emptyText:SetTextColor(Theme.RGB("muted"))
parts.playersEmpty = emptyText

local rows = {}
parts.playersRows = rows
local function createRow(index)
  local row = CreateFrame("Button", nil, container)
  row:SetSize(LFGWindow.WIDTH - 2 * PAD, ROW_HEIGHT)
  row:SetPoint("TOPLEFT", PAD, -(TOP + (index - 1) * (ROW_HEIGHT + ROW_GAP)))
  row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
  row.highlight:SetAllPoints()
  row.highlight:SetColorTexture(1, 1, 1, 0.08)
  row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.text:SetPoint("LEFT", 4, 0)
  row.text:SetJustifyH("LEFT")
  row:SetScript("OnClick", function(self) if self.entry then LFGPlayers.CycleRating(self.entry.name) end end)
  ns.Widgets.AttachTooltip(row, function() return row.entry and row.entry.name or "" end,
    function() return L.LFG_PLAYERS_ROW_TIP end)
  rows[index] = row
  return row
end

local function refresh()
  local list = LFGPlayers.GetList()
  emptyText:SetText(#list == 0 and L.LFG_PLAYERS_EMPTY or "")
  for index = 1, MAX_ROWS do
    local row = rows[index] or createRow(index)
    local entry = list[index]
    row.entry = entry
    row:SetShown(entry ~= nil)
    if entry then
      local text = LFGPlayers.Marker(entry.name) .. entry.name .. "  " .. date("%d.%m. %H:%M", entry.time)
      if entry.leaves then text = text .. "  " .. string.format(L.LFG_PLAYERS_LEFT, entry.leaves) end
      row.text:SetText(text)
    end
  end
end

LFGWindow.RegisterTab(LFGWindow.TAB_PLAYERS, refresh)
LFGPlayers.OnChange(function()
  if LFGWindow.IsShown() and LFGWindow.State().tab == LFGWindow.TAB_PLAYERS then refresh() end
end)

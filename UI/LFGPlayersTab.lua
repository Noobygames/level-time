-- Reiter Mitspieler des Gruppensuche-Fensters (UI/LFGWindow.lua, LT-392): letzte Mitspieler aus der Gruppenliste
-- (Assist/LFGPlayers.lua), neueste zuerst, mit Bildlauf. Zeile: Klassensymbol, Name in Klassenfarbe, Rollensymbol;
-- darunter letzter gemeinsamer Dungeon, Zeitpunkt und "!" für Abbrecher; rechts die Knöpfe + und - (Bewertung, noch
-- einmal = zurücknehmen). Tooltip der Zeile: Stufe, Klasse, Rolle, Dungeon, zuletzt gesehen. Die Bewertung erscheint
-- als Kurzzeichen vor dem Leiternamen in der Suche.
local _, ns = ...
if not ns.Client.IsForever() then return end

local L = ns.L
local Theme = ns.Theme
local Widgets = ns.Widgets
local LFGPlayers = ns.LFGPlayers
local LFGWindow = ns.LFGWindow
local LFGTooltip = ns.LFGTooltip
local parts = LFGWindow.Parts()
local container = LFGWindow.playersContainer

local PAD = LFGWindow.PAD
local GAP = LFGWindow.GAP
local SMALL_GAP = 4
local TOP = 40               -- unter dem Porträtring
local SCROLLBAR_SPACE = 24   -- Platz rechts für die Bildlaufleiste
local ROW_HEIGHT = 32
local ROW_GAP = 4
local CLASS_ICON_SIZE = 20
local ROLE_ICON_SIZE = 16
local RATE_BUTTON_WIDTH, RATE_BUTTON_HEIGHT = 28, 22
local ROW_WIDTH = LFGWindow.WIDTH - 2 * PAD - SCROLLBAR_SPACE
local DATE_FORMAT = "%d.%m. %H:%M"
local SEPARATOR = "  ·  "
local RATE_SYMBOLS = { [LFGPlayers.UP] = "+", [LFGPlayers.DOWN] = "-" }  -- ASCII: jede Schrift kann es
local RATE_COLORS = { [LFGPlayers.UP] = "good", [LFGPlayers.DOWN] = "bad" }
local LEAVER_COLOR = "|cffff9a3c"

local emptyText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
emptyText:SetPoint("TOP", 0, -(TOP + 40))
emptyText:SetWidth(LFGWindow.WIDTH - 2 * PAD)
emptyText:SetTextColor(Theme.RGB("muted"))
parts.playersEmpty = emptyText

local area = Widgets.CreateScrollArea(container, { step = ROW_HEIGHT + ROW_GAP, keepInRange = true })
area:SetPoint("TOPLEFT", PAD, -TOP)
area:SetPoint("BOTTOMRIGHT", -(PAD + SCROLLBAR_SPACE), PAD)
local content = CreateFrame("Frame", nil, area)
content:SetSize(ROW_WIDTH, ROW_HEIGHT)
area:SetScrollChild(content)

local function tooltipLines(entry)
  local lines = {}
  if entry.class then
    local className = ns.Format.ClassName(entry.class)
    table.insert(lines, entry.level and string.format(L.LFG_PLAYERS_TIP_CLASS, entry.level, className) or className)
  end
  local roleKey = entry.role and LFGTooltip.ROLE_TEXTS[entry.role]
  if roleKey then table.insert(lines, string.format(L.LFG_PLAYERS_TIP_ROLE, L[roleKey])) end
  if entry.dungeon then table.insert(lines, string.format(L.LFG_PLAYERS_TIP_DUNGEON, entry.dungeon)) end
  table.insert(lines, string.format(L.LFG_PLAYERS_TIP_SEEN, date(DATE_FORMAT, entry.time)))
  if entry.leaves then table.insert(lines, LEAVER_COLOR .. string.format(L.LFG_PLAYERS_TIP_LEFT, entry.leaves) .. "|r") end
  table.insert(lines, L.LFG_PLAYERS_TIP_MARKER)
  return table.concat(lines, "\n")
end

-- Knopf + oder -: aktiv in Status-Farbe und hervorgehoben, sonst gedämpft
local function newRateButton(row, rating, key)
  local button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  button:SetSize(RATE_BUTTON_WIDTH, RATE_BUTTON_HEIGHT)
  button:SetText(RATE_SYMBOLS[rating])
  button.rating = rating
  button:SetScript("OnClick", function() if row.entry then LFGPlayers.ToggleRating(row.entry.name, rating) end end)
  Widgets.AttachTooltip(button, function() return L[key] end, function() return L[key .. "_TIP"] end)
  return button
end

local function paintRateButton(button, current)
  local active = current == button.rating
  local text = button:GetFontString()
  if text then text:SetTextColor(Theme.RGB(active and RATE_COLORS[button.rating] or "muted")) end
  if active then button:LockHighlight() else button:UnlockHighlight() end
end

local rows = {}
parts.playersRows = rows
local function createRow(index)
  local row = CreateFrame("Button", nil, content)
  row:SetSize(ROW_WIDTH, ROW_HEIGHT)
  row:SetPoint("TOPLEFT", 0, -(index - 1) * (ROW_HEIGHT + ROW_GAP))
  row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
  row.highlight:SetAllPoints()
  row.highlight:SetColorTexture(1, 1, 1, 0.08)
  row.classIcon = row:CreateTexture(nil, "ARTWORK")
  row.classIcon:SetSize(CLASS_ICON_SIZE, CLASS_ICON_SIZE)
  row.classIcon:SetPoint("LEFT", SMALL_GAP, 0)
  row.downButton = newRateButton(row, LFGPlayers.DOWN, "LFG_PLAYERS_RATE_DOWN")
  row.downButton:SetPoint("RIGHT", -SMALL_GAP, 0)
  row.upButton = newRateButton(row, LFGPlayers.UP, "LFG_PLAYERS_RATE_UP")
  row.upButton:SetPoint("RIGHT", row.downButton, "LEFT", -SMALL_GAP, 0)
  row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.name:SetPoint("TOPLEFT", row.classIcon, "TOPRIGHT", GAP, 2)
  row.name:SetJustifyH("LEFT")
  row.roleIcon = row:CreateTexture(nil, "ARTWORK")
  row.roleIcon:SetPoint("LEFT", row.name, "RIGHT", SMALL_GAP, 0)
  row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.detail:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -2)
  row.detail:SetPoint("RIGHT", row.upButton, "LEFT", -GAP, 0)
  row.detail:SetJustifyH("LEFT")
  row.detail:SetWordWrap(false)
  row.detail:SetTextColor(Theme.RGB("muted"))
  Widgets.AttachTooltip(row, function() return row.entry and row.entry.name or "" end,
    function() return row.entry and tooltipLines(row.entry) end)
  rows[index] = row
  return row
end

local function detailText(entry)
  local text = date(DATE_FORMAT, entry.time)
  if entry.dungeon then text = entry.dungeon .. SEPARATOR .. text end
  if entry.leaves then text = text .. SEPARATOR .. LEAVER_COLOR .. "! " .. string.format(L.LFG_PLAYERS_LEFT, entry.leaves) .. "|r" end
  return text
end

local function fillRow(row, entry)
  Widgets.SetClassIcon(row.classIcon, entry.class, CLASS_ICON_SIZE)
  row.name:SetText(entry.name)
  row.name:SetTextColor(unpack(Theme.ClassColor(entry.class, { Theme.RGB("gold") })))
  Widgets.SetIcon(row.roleIcon, entry.role and LFGWindow.ROLE_ATLAS[entry.role], ROLE_ICON_SIZE)
  row.detail:SetText(detailText(entry))
  paintRateButton(row.upButton, entry.rating)
  paintRateButton(row.downButton, entry.rating)
end

local function refresh()
  local list = LFGPlayers.GetList()
  emptyText:SetText(#list == 0 and L.LFG_PLAYERS_EMPTY or "")
  for index = 1, math.max(#list, #rows) do
    local entry = list[index]
    local row = rows[index] or (entry and createRow(index))
    if row then
      row.entry = entry
      row:SetShown(entry ~= nil)
      if entry then fillRow(row, entry) end
    end
  end
  content:SetHeight(math.max(ROW_HEIGHT, #list * (ROW_HEIGHT + ROW_GAP)))
end

LFGWindow.RegisterTab(LFGWindow.TAB_PLAYERS, refresh)
LFGPlayers.OnChange(function()
  if LFGWindow.IsShown() and LFGWindow.State().tab == LFGWindow.TAB_PLAYERS then refresh() end
end)

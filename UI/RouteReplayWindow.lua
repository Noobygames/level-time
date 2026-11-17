-- Fenster der Routen-Checkliste (Daten: Speedrun/RouteReplay.lua): Kopf mit Quelle und Fortschritt, darunter bis
-- MAX_ROWS Schritte ab dem letzten erledigten; die nächsten drei offenen in Gold. Einstellung routeReplay (/lt route),
-- Position über Lib/Frames.lua, Aktualisierung über ns.Every.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme

local RouteReplayWindow = { MAX_ROWS = 10 }
ns.RouteReplayWindow = RouteReplayWindow

local PADDING = 12
local HEADER_HEIGHT = 40
local ROW_HEIGHT = 32
local WIDTH = 340
local UPDATE_INTERVAL = 2
-- Markierung wie im Gruppensuche-Fenster; offene Schritte haben keine Textur (Platz bleibt frei)
local MARK_TEXTURES = { done = "Interface\\RaidFrame\\ReadyCheck-Ready", next = "Interface\\RaidFrame\\ReadyCheck-Waiting" }
local MARK_SIZE = 14
local MARK_GAP = 6
local COLORS = { done = "muted", next = "gold", open = "text" }

local panel = Widgets.CreatePanel(ns.GlobalName("RouteReplay"), 0.95)
panel:SetSize(WIDTH, HEADER_HEIGHT)
panel:Hide()
local header = Widgets.CreateWindowHeader(panel, "", { onClose = function() ns.Set("routeReplay", false) end })
local title = header.title
header:SetIcon("Interface\\Icons\\INV_Misc_ScrollUnrolled01")  -- Checkliste
local progress = header:CreateFontString(nil, "OVERLAY", Theme.Font("label"))
progress:SetPoint("RIGHT", header.actions, "RIGHT")

local rows = {}
local previewing = false

local function getRow(index)
  if rows[index] then return rows[index] end
  local row = Widgets.CreateListRow(panel, ROW_HEIGHT)
  row:SetPoint("TOPLEFT", PADDING, -HEADER_HEIGHT - (index - 1) * ROW_HEIGHT)
  row:SetPoint("RIGHT", -PADDING, 0)
  row:EnableMouse(false)  -- reine Anzeige: kein Hover
  row.mark = row:CreateTexture(nil, "OVERLAY")
  row.mark:SetSize(MARK_SIZE, MARK_SIZE)
  row.mark:SetPoint("LEFT", 8, 0)
  row.text:SetPoint("LEFT", 8 + MARK_SIZE + MARK_GAP, 0)  -- ersetzt den Anker aus CreateListRow
  rows[index] = row
  return row
end

local function showEntries(entries)
  for index = 1, math.max(#entries, #rows) do
    local row, entry = getRow(index), entries[index]
    if entry then
      Widgets.SetTextIfChanged(row.text, string.format("%s  (%s)", entry.name,
        string.format(L.ROUTE_LEVEL, entry.level or 0)))
      row.text:SetTextColor(Theme.RGB(COLORS[entry.status]))
      row.mark:SetTexture(MARK_TEXTURES[entry.status])
    end
    row:SetShown(entry ~= nil)
    row.mark:SetShown(entry ~= nil and MARK_TEXTURES[entry.status] ~= nil)
  end
  panel:SetHeight(HEADER_HEIGHT + math.max(#entries, 1) * ROW_HEIGHT)
end

-- Ab dem letzten erledigten Schritt vor dem ersten offenen (etwas Kontext), höchstens MAX_ROWS
local function visibleSteps(steps)
  local first = 1
  for index, step in ipairs(steps) do
    if step.status ~= "done" then first = math.max(1, index - 1) break end
    first = index
  end
  local list = {}
  for index = first, math.min(#steps, first + RouteReplayWindow.MAX_ROWS - 1) do list[#list + 1] = steps[index] end
  return list
end

function RouteReplayWindow.Update()
  if not (ns.db.routeReplay or previewing) then panel:Hide() return end
  local route = ns.RouteReplay.Get()
  if route then
    title:SetText(string.format(L.ROUTE_TITLE, route.run.name or "?", route.run.reachedLevel or 0))
    progress:SetText(route.done .. " / " .. #route.steps)
    showEntries(visibleSteps(route.steps))
  else
    title:SetText(L.ROUTE_TITLE_EMPTY)
    progress:SetText("")
    showEntries({})
  end
  -- Fortschritt als Aktion im Kopf: der Titel (Name, lange Sprachen) schiebt das Fenster breiter statt zu überlappen
  header.actions:SetWidth(math.max(1, math.ceil(progress:GetStringWidth())))
  panel:SetWidth(math.max(WIDTH, header:MinWidth()))
  panel:Show()
end

ns.Frames.Register({
  id = "routeReplay", frame = panel, label = "EDIT_FRAME_ROUTE", default = { "TOPLEFT", "TOPLEFT", 20, -420 },
  settingsPage = "OPTIONS_PAGE_ROUTE_REPLAY", dragWhenUnlocked = true,
  preview = function(on)
    previewing = on
    RouteReplayWindow.Update()
  end,
  hide = function() ns.Set("routeReplay", false) end,
})

ns.Every(UPDATE_INTERVAL, RouteReplayWindow.Update, function(db) return db.routeReplay end)
ns.RegisterApply(function() RouteReplayWindow.Update() end)

-- Kleines Hinweisfenster der Dungeonquests (Inhalt aus Assist/DungeonQuestHints.lua): Titel, je Quest eine Zeile
-- (Titel, darunter Geber und Ort), Schließen-Knopf; schließt nach DISPLAY_SECONDS von selbst, unter der Maus bleibt es
-- stehen. Position über Lib/Frames.lua (Edit-Modus mit Beispielinhalt, ziehbar solange nicht gesperrt).
-- DungeonQuestHint.Show(title, rows), rows = { { text, detail, muted, place = { uiMapID, x, y } }, ... }.
-- Klick auf eine Zeile mit Ort: eigener Kartenpunkt (eine Ebene über Lib/MapPins.lua, ersetzt den vorigen), wo es sie
-- gibt zusätzlich Blizzards Wegpunkt (C_Map.CanSetUserWaypointOnMap/SetUserWaypoint mit UiMapPoint; laut Blizzard-Doku
-- nur Retail, in Classic Era fehlen sie) und die Weltkarte auf der Zone öffnen (OpenWorldMap(mapID), auch in Classic
-- Era: Blizzard_WorldMap/Vanilla).
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme

local DungeonQuestHint = {
  DISPLAY_SECONDS = 20,
  MAX_ROWS = 8,
}
ns.DungeonQuestHint = DungeonQuestHint

local DEFAULT_POSITION = { "TOP", "TOP", 0, -220 }
local PADDING = 12
local MIN_WIDTH = 240
local TITLE_HEIGHT = 40  -- Fensterkopf (Widgets.CreateWindowHeader)
local CLOSE_SPACE = 56   -- Platz rechts neben dem Titel für den Schließen-Knopf
local ROW_TEXT_INSET = 8 -- Texteinzug in der Listenzeile
local ROW_HEIGHT = 32    -- Zeile mit Text und Detailzeile
local LINE_GAP = 2
local FADE_OUT = 0.7
local BACKGROUND_ALPHA = 0.92
local REFRESH_SECONDS = 1  -- Takt, in dem Detailzeilen (Gebernamen) neu abgefragt werden

local panel = Widgets.CreatePanel(ns.GlobalName("DungeonQuestHint"), BACKGROUND_ALPHA)
panel:Hide()
local header = Widgets.CreateWindowHeader(panel, "", { onClose = function() DungeonQuestHint.Hide() end })
local title = header.title

local WAYPOINT_SIZE = 18
local WAYPOINT_ATLAS = "Waypoint-MapPin-Untracked"
local WAYPOINT_TEXTURE = "Interface\\Icons\\INV_Misc_Map_01"  -- Rückfall, wo der Atlas fehlt (Classic Era)

local rows = {}
local rowEntries = {}  -- [Zeile] = angezeigter Eintrag
local shownAt
local editing = false
local waypoint      -- { uiMapID, x, y, text } des zuletzt angeklickten Eintrags
local waypointRevision = 0

local waypointLayer = ns.MapPins.Create({
  name = ns.GlobalName("DungeonQuestWaypoint"),
  label = "DungeonQuestWaypoint",
  points = function(mapID)
    if not waypoint or waypoint.uiMapID ~= mapID then return {} end
    return { { x = waypoint.x, y = waypoint.y, size = WAYPOINT_SIZE, atlas = WAYPOINT_ATLAS, texture = WAYPOINT_TEXTURE } }
  end,
  revision = function() return waypointRevision end,
  onEnter = function(pin)
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    GameTooltip:SetText(waypoint and waypoint.text or "")
    GameTooltip:Show()
  end,
})

local function setBlizzardWaypoint(place)
  if not (C_Map and C_Map.SetUserWaypoint and C_Map.CanSetUserWaypointOnMap and UiMapPoint) then return end
  if not C_Map.CanSetUserWaypointOnMap(place.uiMapID) then return end
  C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(place.uiMapID, place.x, place.y))
end

-- Kartenpunkt zum Eintrag setzen und die Karte auf seiner Zone öffnen
function DungeonQuestHint.SetWaypoint(entry)
  local place = entry.place
  waypoint = { uiMapID = place.uiMapID, x = place.x, y = place.y, text = entry.text }
  waypointRevision = waypointRevision + 1
  waypointLayer.SetEnabled(true)
  setBlizzardWaypoint(place)
  if OpenWorldMap then OpenWorldMap(place.uiMapID) end
  ns.Debug("dungeonquests", "waypoint %s %s %s", place.uiMapID, place.x, place.y)
end

function DungeonQuestHint.Waypoint()
  return waypoint
end

local function setColor(fontString, colorName)
  fontString:SetTextColor(ns.Theme.RGB(colorName))
end

local function getRow(index)
  if rows[index] then return rows[index] end
  local row = Widgets.CreateListRow(panel, ROW_HEIGHT)
  row:SetPoint("TOPLEFT", PADDING, -TITLE_HEIGHT - (index - 1) * ROW_HEIGHT)
  row:SetPoint("RIGHT", -PADDING, 0)
  row.text:ClearAllPoints()  -- zwei Zeilen: Text oben, Detail darunter
  row.text:SetPoint("TOPLEFT", ROW_TEXT_INSET, -LINE_GAP)
  row.detail = row:CreateFontString(nil, "OVERLAY", Theme.Font("note"))
  row.detail:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, -LINE_GAP)
  row.detail:SetJustifyH("LEFT")
  setColor(row.detail, "note")
  row:SetScript("OnClick", function(self)
    local entry = rowEntries[self]
    if entry and entry.place then DungeonQuestHint.SetWaypoint(entry) end
  end)
  Widgets.AttachTooltip(row, function() return ns.DISPLAY_NAME end,
    function() return rowEntries[row] and rowEntries[row].place and L.DUNGEON_QUEST_HINT_CLICK or nil end)
  rows[index] = row
  return row
end

local function hide()
  editing = false
  panel:Hide()
end
DungeonQuestHint.Hide = hide

local function layout(titleText, entries)
  title:SetText(titleText)
  local width = title:GetStringWidth() + CLOSE_SPACE - 2 * PADDING
  local count = math.min(#entries, DungeonQuestHint.MAX_ROWS)
  for index = 1, count do
    local entry, row = entries[index], getRow(index)
    rowEntries[row] = entry
    row.text:SetText(entry.text)
    setColor(row.text, entry.muted and "inactive" or "text")
    row.detail:SetText(entry.detail or "")
    width = math.max(width, row.text:GetStringWidth() + 2 * ROW_TEXT_INSET, row.detail:GetStringWidth() + 2 * ROW_TEXT_INSET)
    row:Show()
  end
  for index = count + 1, #rows do rows[index]:Hide() end
  local more = #entries - count
  if more > 0 then  -- letzte Zeile: Hinweis auf die übrigen
    local row = getRow(count + 1)
    rowEntries[row] = nil
    row.text:SetText(string.format(L.DUNGEON_QUESTS_MORE, more))
    setColor(row.text, "muted")
    row.detail:SetText("")
    row:Show()
    count = count + 1
  end
  panel:SetSize(math.max(MIN_WIDTH, width + 2 * PADDING), PADDING + TITLE_HEIGHT + count * ROW_HEIGHT)
end

function DungeonQuestHint.Show(titleText, entries)
  if #entries == 0 then return end
  layout(titleText, entries)
  shownAt = GetTime()
  panel:SetAlpha(1)
  panel:Show()
  ns.Debug("dungeonquests", "hint shown: %s (%s rows)", titleText, #entries)
end

function DungeonQuestHint.IsShown()
  return panel:IsShown()
end

-- Zeilen des Fensters und ihre Einträge (für Tests)
function DungeonQuestHint.Rows()
  return rows, rowEntries
end

-- Detailzeilen neu abfragen (entry.refresh): ein beim Öffnen noch unbekannter NPC-Name erscheint, sobald er auflösbar ist
local function refreshDetails()
  for row, entry in pairs(rowEntries) do
    if entry.refresh and row:IsShown() then Widgets.SetTextIfChanged(row.detail, entry.refresh() or "") end
  end
end

local sinceRefresh = 0
ns.SetUpdateScript(panel, "DungeonQuestHint", function(self, elapsed)
  if editing or not shownAt then return end
  sinceRefresh = sinceRefresh + (elapsed or 0)
  if sinceRefresh >= REFRESH_SECONDS then
    sinceRefresh = 0
    refreshDetails()
  end
  local age = GetTime() - shownAt
  local hold = DungeonQuestHint.DISPLAY_SECONDS
  if self:IsMouseOver() and age > hold then  -- unter der Maus bleibt es stehen
    shownAt = GetTime() - hold
    age = hold
  end
  if age >= hold + FADE_OUT then
    hide()
  elseif age > hold then
    self:SetAlpha(1 - (age - hold) / FADE_OUT)
  end
end)

-- Edit-Modus: Beispielinhalt bleibt stehen, bis der Modus endet
local function setEditing(enabled)
  if enabled then
    layout(L.EDIT_FRAME_DUNGEON_QUEST_HINT, {
      { text = L.DUNGEON_QUEST_HINT_SAMPLE, detail = L.DUNGEON_QUEST_GIVER_NPC },
    })
    editing = true
    panel:SetAlpha(1)
    panel:Show()
  elseif editing then
    hide()
  end
end

ns.Frames.Register({
  id = "dungeonQuestHint", frame = panel, label = "EDIT_FRAME_DUNGEON_QUEST_HINT", default = DEFAULT_POSITION,
  settingsPage = "COMFORT_PAGE_DUNGEONS", preview = setEditing, dragWhenUnlocked = true,
  available = function() return ns.DungeonQuests.IsAvailable() end,
})

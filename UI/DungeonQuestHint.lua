-- Kleines Hinweisfenster der Dungeonquests (Inhalt aus Assist/DungeonQuestHints.lua): Titel, je Quest eine Zeile
-- (Titel, darunter Geber und Ort), Schließen-Knopf; bleibt stehen, bis es geschlossen wird. Nur mit der Einstellung
-- dungeonQuestHintAutoClose schließt es nach DISPLAY_SECONDS von selbst (unter der Maus bleibt es dann stehen).
-- Position über Lib/Frames.lua (Edit-Modus mit Beispielinhalt, ziehbar solange nicht gesperrt).
-- DungeonQuestHint.Show(title, rows, mapID), rows = { { text, detail, muted, place = { uiMapID, x, y } }, ... }; mit
-- mapID (Hinweis zu einer Instanz) steht über den Knöpfen der Haken "Für diesen Dungeon nicht mehr anzeigen" (LT-394,
-- je Charakter, DungeonQuestHints.SetHidden).
-- Alle Quests stehen in einer Liste mit Mausrad-Bildlauf (Fensterhöhe höchstens MAX_ROWS Zeilen). Klick auf eine Zeile
-- mit Ort: eigener Kartenpunkt (eine Ebene über Lib/MapPins.lua) ein/aus, mehrere gleichzeitig, Zeile markiert; die
-- Knöpfe unter der Liste setzen alle / entfernen alle. Wo es ihn gibt, folgt Blizzards Wegpunkt dem zuletzt gesetzten Punkt
-- (C_Map.CanSetUserWaypointOnMap/SetUserWaypoint mit UiMapPoint; laut Blizzard-Doku nur Retail, in Classic Era fehlen
-- sie); beim Setzen öffnet die Weltkarte auf der Zone (OpenWorldMap(mapID), auch in Classic Era: Blizzard_WorldMap/Vanilla).
-- Blizzards Wegpunkt kann nur einen Punkt; die eigenen Punkte erscheinen alle, auch auf Kontinent- und Nachbarkarten
-- (MapPins mapIDs). "Alle markieren" öffnet die Karte einmal: liegen die Punkte in mehreren Zonen, auf der
-- übergeordneten Karte der ersten (C_Map.GetMapInfo parentMapID, alle Clients).
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme

local DungeonQuestHint = {
  DISPLAY_SECONDS = 20,
  MAX_ROWS = 8,  -- sichtbare Zeilen, darüber hinaus blättert die Liste
}
ns.DungeonQuestHint = DungeonQuestHint

local PADDING = 12
local MIN_WIDTH = 240
local TITLE_HEIGHT = 40  -- Fensterkopf (Widgets.CreateWindowHeader)
local ROW_TEXT_INSET = 8 -- Texteinzug in der Listenzeile
local ROW_HEIGHT = 32    -- Zeile mit Text und Detailzeile
local LINE_GAP = 2
local FADE_OUT = 0.7
local BACKGROUND_ALPHA = 0.92
local REFRESH_SECONDS = 1  -- Takt, in dem Detailzeilen (Gebernamen) neu abgefragt werden
local ACTION_HEIGHT = 22   -- Knöpfe "Alle markieren" / "Alle löschen" unter der Liste
local ACTION_PADDING = 16
local ACTION_GAP = 6

local panel = Widgets.CreatePanel(ns.GlobalName("DungeonQuestHint"), BACKGROUND_ALPHA)
panel:Hide()
local header = Widgets.CreateWindowHeader(panel, "", { onClose = function() DungeonQuestHint.Hide() end })
local title = header.title
header:SetIcon("Interface\\Icons\\INV_Misc_Key_05")  -- Dungeon

local WAYPOINT_SIZE = 18
local WAYPOINT_ATLAS = "Waypoint-MapPin-Untracked"
local WAYPOINT_TEXTURE = "Interface\\Icons\\INV_Misc_Map_01"  -- Rückfall, wo der Atlas fehlt (Classic Era)
local PIN_MARK_SIZE = 16
local PIN_SPACE = PIN_MARK_SIZE + 8  -- Platz rechts in der Zeile für das Kartenpunkt-Zeichen
local PIN_LOOK = { atlas = WAYPOINT_ATLAS, texture = WAYPOINT_TEXTURE }

local rows = {}
local rowEntries = {}  -- [Zeile] = angezeigter Eintrag
local shownEntries = {}  -- Einträge des gezeigten Hinweises
local shownAt
local lastShown  -- { title, entries, mapID } des zuletzt gezeigten Hinweises (erneut öffnen mit ShowLast)
local editing = false
local pins = {}  -- gesetzte Kartenpunkte in Setzreihenfolge: { key, uiMapID, x, y, text }
local pinRevision = 0

local function pinKey(entry)
  local place = entry.place
  return place.uiMapID .. ":" .. place.x .. ":" .. place.y .. ":" .. entry.text
end

local function findPin(key)
  for index, pin in ipairs(pins) do
    if pin.key == key then return pin, index end
  end
end

local waypointLayer = ns.MapPins.Create({
  name = ns.GlobalName("DungeonQuestWaypoint"),
  label = "DungeonQuestWaypoint",
  points = function(mapID)
    local list = {}
    for _, pin in ipairs(pins) do
      if pin.uiMapID == mapID then
        table.insert(list, { x = pin.x, y = pin.y, size = WAYPOINT_SIZE, atlas = WAYPOINT_ATLAS,
          texture = WAYPOINT_TEXTURE, text = pin.text })
      end
    end
    return list
  end,
  revision = function() return pinRevision end,
  -- Zonen aller Punkte: so erscheinen sie auch auf der Kontinentkarte und am Rand von Nachbarzonen
  mapIDs = function()
    local list, seen = {}, {}
    for _, pin in ipairs(pins) do
      if not seen[pin.uiMapID] then
        seen[pin.uiMapID] = true
        table.insert(list, pin.uiMapID)
      end
    end
    return list
  end,
  onEnter = function(pin, point)
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    GameTooltip:SetText(point and point.text or "")
    GameTooltip:Show()
  end,
})

local function setBlizzardWaypoint(place)
  if not (C_Map and C_Map.SetUserWaypoint and C_Map.CanSetUserWaypointOnMap and UiMapPoint) then return end
  if not C_Map.CanSetUserWaypointOnMap(place.uiMapID) then return end
  C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(place.uiMapID, place.x, place.y))
end

-- Zeilen der gesetzten Kartenpunkte markieren (Zeichen rechts + Auswahlgrund)
local function updatePinMarks()
  for row, entry in pairs(rowEntries) do
    local pinned = entry.place ~= nil and findPin(pinKey(entry)) ~= nil
    row.pinMark:SetShown(pinned)
    row:SetSelected(pinned)
  end
end

local function pinsChanged()
  pinRevision = pinRevision + 1
  waypointLayer.SetEnabled(#pins > 0)
  updatePinMarks()
end

local function openMap(uiMapID)
  if OpenWorldMap then OpenWorldMap(uiMapID) end
end

-- Kartenpunkt zum Eintrag setzen (Blizzards Wegpunkt folgt ihm) und die Karte auf seiner Zone öffnen (keepMap: nicht)
function DungeonQuestHint.SetWaypoint(entry, keepMap)
  local place = entry.place
  local key = pinKey(entry)
  if not findPin(key) then
    table.insert(pins, { key = key, uiMapID = place.uiMapID, x = place.x, y = place.y, text = entry.text })
  end
  pinsChanged()
  setBlizzardWaypoint(place)
  if not keepMap then openMap(place.uiMapID) end
  ns.Debug("dungeonquests", "waypoint %s %s %s", place.uiMapID, place.x, place.y)
end

-- Kartenpunkt entfernen; Blizzards Wegpunkt springt auf den letzten verbliebenen, ohne Punkte wird er gelöscht
local function removePin(key)
  local _, index = findPin(key)
  if not index then return end
  table.remove(pins, index)
  pinsChanged()
  local last = pins[#pins]
  if last then
    setBlizzardWaypoint(last)
  elseif C_Map and C_Map.ClearUserWaypoint then
    C_Map.ClearUserWaypoint()
  end
end

function DungeonQuestHint.TogglePin(entry)
  local key = pinKey(entry)
  if findPin(key) then removePin(key) else DungeonQuestHint.SetWaypoint(entry) end
end

-- Alle Einträge mit Ort im Fenster markieren / alle Kartenpunkte entfernen
function DungeonQuestHint.MarkAll()
  local first, zones, seen = nil, 0, {}
  for _, entry in ipairs(shownEntries) do
    if entry.place then
      if not findPin(pinKey(entry)) then DungeonQuestHint.SetWaypoint(entry, true) end
      first = first or entry.place.uiMapID
      if not seen[entry.place.uiMapID] then seen[entry.place.uiMapID], zones = true, zones + 1 end
    end
  end
  if not first then return end
  local info = zones > 1 and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(first)
  openMap(info and info.parentMapID and info.parentMapID > 0 and info.parentMapID or first)
  ns.Debug("dungeonquests", "mark all: %s pins in %s zones", #pins, zones)
end

function DungeonQuestHint.ClearAll()
  while #pins > 0 do removePin(pins[#pins].key) end
end

-- Zuletzt gesetzter Kartenpunkt (oder nil) und Anzahl aller gesetzten
function DungeonQuestHint.Waypoint()
  return pins[#pins]
end

function DungeonQuestHint.PinCount()
  return #pins
end

local function setColor(fontString, colorName)
  fontString:SetTextColor(ns.Theme.RGB(colorName))
end

-- Knöpfe unten rechts unter der Liste; anchor = der Knopf rechts davon. Text und Breite setzt layout (Sprachwechsel).
local function createAction(labelKey, onClick, anchor)
  local button = Widgets.CreateButton(panel, 60, ACTION_HEIGHT, onClick)
  button.labelKey = labelKey
  if anchor then button:SetPoint("RIGHT", anchor, "LEFT", -ACTION_GAP, 0) else button:SetPoint("BOTTOMRIGHT", -PADDING, PADDING) end
  Widgets.AttachTooltip(button, function() return L[labelKey] end, function() return L[labelKey .. "_TIP"] end)
  return button
end
local clearButton = createAction("DUNGEON_QUEST_HINT_CLEAR_ALL", function() DungeonQuestHint.ClearAll() end)
local markButton = createAction("DUNGEON_QUEST_HINT_MARK_ALL", function() DungeonQuestHint.MarkAll() end, clearButton)
local FOOTER_HEIGHT = ACTION_HEIGHT + PADDING  -- Knopfzeile mit Abstand zur Liste
local HIDE_ROW_HEIGHT = 28  -- Zeile mit dem Haken "nicht mehr anzeigen" über den Knöpfen

local hideMapID  -- Instanz des gezeigten Hinweises, nil ohne Haken
local hideCheck = Widgets.CreateCheckbox(panel, function(checked)
  if hideMapID then ns.DungeonQuestHints.SetHidden(hideMapID, checked) end
end)
hideCheck:SetPoint("BOTTOMLEFT", PADDING - 4, PADDING + ACTION_HEIGHT + 2)
Widgets.AttachTooltip(hideCheck, function() return L.DUNGEON_QUEST_HINT_HIDE_DUNGEON end,
  function() return L.DUNGEON_QUEST_HINT_HIDE_DUNGEON_TIP end)

local area = Widgets.CreateScrollArea(panel, { step = ROW_HEIGHT, keepInRange = true })
area:SetPoint("TOPLEFT", PADDING, -TITLE_HEIGHT)
local content = CreateFrame("Frame", nil, area)
content:SetSize(MIN_WIDTH, ROW_HEIGHT)
area:SetScrollChild(content)

local function getRow(index)
  if rows[index] then return rows[index] end
  local row = Widgets.CreateListRow(content, ROW_HEIGHT)
  row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
  row.text:ClearAllPoints()  -- zwei Zeilen: Text oben, Detail darunter
  row.text:SetPoint("TOPLEFT", ROW_TEXT_INSET, -LINE_GAP)
  row.detail = row:CreateFontString(nil, "OVERLAY", Theme.Font("note"))
  row.detail:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, -LINE_GAP)
  row.detail:SetJustifyH("LEFT")
  setColor(row.detail, "note")
  row.pinMark = row:CreateTexture(nil, "OVERLAY")
  row.pinMark:SetSize(PIN_MARK_SIZE, PIN_MARK_SIZE)
  row.pinMark:SetPoint("RIGHT", -ROW_TEXT_INSET, 0)
  ns.MapPins.Paint(row.pinMark, PIN_LOOK)
  row.pinMark:Hide()
  row:SetScript("OnClick", function(self)
    local entry = rowEntries[self]
    if entry and entry.place then DungeonQuestHint.TogglePin(entry) end
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

local function layout(titleText, entries, mapID)
  if type(titleText) == "function" then titleText = titleText() end  -- erst hier übersetzt (Sprachwechsel)
  title:SetText(titleText)
  hideMapID = mapID
  hideCheck:SetShown(mapID ~= nil)
  hideCheck.label:SetText(L.DUNGEON_QUEST_HINT_HIDE_DUNGEON)
  hideCheck:SetChecked(mapID ~= nil and ns.DungeonQuestHints.IsHidden(mapID))
  local footer = FOOTER_HEIGHT + (mapID and HIDE_ROW_HEIGHT or 0)
  area:SetPoint("BOTTOMRIGHT", -PADDING, PADDING + footer)
  for _, button in ipairs({ markButton, clearButton }) do
    button:SetText(L[button.labelKey])
    button:SetWidth(button:GetTextWidth() + ACTION_PADDING)
  end
  local actionsWidth = markButton:GetWidth() + ACTION_GAP + clearButton:GetWidth()
  -- breit genug für Titel (mit Symbol und Schließen-Knopf), Knopfzeile und Zeilen
  local checkWidth = mapID and hideCheck:GetWidth() + Widgets.CHECKBOX_LABEL_GAP + hideCheck.label:GetStringWidth() or 0
  local width = math.max(MIN_WIDTH - 2 * PADDING, actionsWidth, checkWidth,
    header:MinWidth() - 2 * PADDING)
  for index, entry in ipairs(entries) do
    local row = getRow(index)
    rowEntries[row] = entry
    row.text:SetText(entry.textOf and entry.textOf() or entry.text)
    setColor(row.text, entry.muted and "inactive" or "text")
    row.detail:SetText(entry.refresh and entry.refresh() or entry.detail or "")
    width = math.max(width, row.text:GetStringWidth() + 2 * ROW_TEXT_INSET + PIN_SPACE,
      row.detail:GetStringWidth() + 2 * ROW_TEXT_INSET + PIN_SPACE)
    row:Show()
  end
  for index = #entries + 1, #rows do
    rowEntries[rows[index]] = nil
    rows[index]:Hide()
  end
  shownEntries = entries
  for _, row in ipairs(rows) do row:SetWidth(width) end
  content:SetSize(width, #entries * ROW_HEIGHT)
  area:SetVerticalScroll(0)
  updatePinMarks()
  panel:SetSize(width + 2 * PADDING,
    PADDING + TITLE_HEIGHT + math.min(#entries, DungeonQuestHint.MAX_ROWS) * ROW_HEIGHT + footer)
end

function DungeonQuestHint.Show(titleText, entries, mapID)
  if #entries == 0 then return end
  layout(titleText, entries, mapID)
  lastShown = { title = titleText, entries = entries, mapID = mapID }
  shownAt = GetTime()
  panel:SetAlpha(1)
  panel:Show()
  ns.Debug("dungeonquests", "hint shown: %s rows", #entries)
end

-- Zuletzt gezeigten Hinweis erneut öffnen; false, wenn es noch keinen gab
function DungeonQuestHint.ShowLast()
  if not lastShown then return false end
  DungeonQuestHint.Show(lastShown.title, lastShown.entries, lastShown.mapID)
  return true
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
  if editing or not shownAt or not panel:IsShown() then return end
  sinceRefresh = sinceRefresh + (elapsed or 0)
  if sinceRefresh >= REFRESH_SECONDS then
    sinceRefresh = 0
    refreshDetails()
  end
  if not (ns.db and ns.db.dungeonQuestHintAutoClose) then return end
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

-- Sprachwechsel bei offenem Fenster: Titel und Zeilen neu übersetzen
ns.RegisterApply(function()
  if panel:IsShown() and not editing and lastShown then layout(lastShown.title, lastShown.entries, lastShown.mapID) end
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
  id = "dungeonQuestHint", frame = panel, label = "EDIT_FRAME_DUNGEON_QUEST_HINT",
  settingsPage = "OPTIONS_PAGE_DUNGEON_QUESTS", preview = setEditing, dragWhenUnlocked = true,
  available = function() return ns.DungeonQuests.IsAvailable() end,
})

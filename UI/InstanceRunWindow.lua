-- Fenster "Dungeon- und Raid-Runs" (Roadmap 493; /lt runs, Knopf und Zeilenklick in Verlauf > Instanzen): links die
-- Läufe eines Charakters (neueste zuerst, Filter Alle/Dungeons/Raids, Markierung Bestzeit/offen/Raid), rechts der
-- gewählte Lauf: Kopf (Name, Datum, Level, Status), Vergleich mit Bestzeit oder letztem Lauf derselben Instanz,
-- acht Kacheln (Zeit, Tode, Kills, XP, Bosse, Geld, Quests, Gruppe), Bosstabelle (Split, Vergleich, Abstand, XP) und
-- Beute samt Würfen; Boss-Porträts (Lib/CreatureModel.lua) je Zeile und groß für den Endboss im Kopf. Daten aus History.GetInstanceLog und InstanceRuns.lua; blau/orange = Theme good/bad.
-- Läuft der gewählte Lauf noch, rechnet das Fenster einmal je Sekunde neu.
-- shortcut: die Liste zeigt die neuesten MAX_LIST_ROWS Läufe des Filters; bei Bedarf Lazy Load wie in TableView.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme
local Format = ns.Format
local InstanceBosses = ns.InstanceBosses
local InstanceRuns = ns.InstanceRuns
local CreatureModel = ns.CreatureModel

local InstanceRunWindow = {}
ns.InstanceRunWindow = InstanceRunWindow

local WIDTH, HEIGHT = 800, 540
local MARGIN = 14
local TITLE_HEIGHT = 26
local LIST_WIDTH = 230
local FILTER_HEIGHT = 22
local ROW_HEIGHT = 34
local MAX_LIST_ROWS = 100
local DETAIL_LEFT = MARGIN + LIST_WIDTH + MARGIN
local DETAIL_WIDTH = WIDTH - DETAIL_LEFT - MARGIN
local TILE_COLUMNS = 4
local TILE_HEIGHT = 50
local TILE_GAP = 6
local TABLE_ROW_HEIGHT = 18
local BOSS_ROW_HEIGHT = 24
local ROW_PORTRAIT_SIZE = 22
local HEADER_PORTRAIT_SIZE = 36
local TABLE_NUMBER_WIDTH = 70
local SECTION_GAP = 12
local SCROLL_STEP = 40
local UPDATE_INTERVAL = 1
local SECONDS_PER_HOUR = 3600
local LIST_ROW_ALPHA = 0.25

local ALL = "all"
local FILTERS = {
  { id = ALL, label = "DUNGEON_RUNS_FILTER_ALL" },
  { id = InstanceRuns.DUNGEON, label = "DUNGEON_RUNS_FILTER_DUNGEONS" },
  { id = InstanceRuns.RAID, label = "DUNGEON_RUNS_FILTER_RAIDS" },
}
local COMPARES = {
  { id = InstanceRuns.BEST, label = "DUNGEON_RUNS_COMPARE_BEST", column = "DUNGEON_RUNS_COLUMN_BEST" },
  { id = InstanceRuns.LAST, label = "DUNGEON_RUNS_COMPARE_LAST", column = "DUNGEON_RUNS_COLUMN_LAST" },
}

local state = { characterKey = nil, filter = ALL, compare = InstanceRuns.BEST, selected = nil }

local function colored(colorName, text)
  return Theme.Hex(colorName) .. text .. "|r"
end

---------------------------------------------------------------------------
-- Rahmen
---------------------------------------------------------------------------
local panelName = ns.GlobalName("DungeonRuns")
local panel = Widgets.CreatePanel(panelName, 0.95)
panel:SetSize(WIDTH, HEIGHT)
panel:SetPoint("CENTER", 0, 40)
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
Widgets.CreateCloseButton(panel)
table.insert(UISpecialFrames, panelName)  -- mit ESC schließen

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", MARGIN, -MARGIN)

local refresh

-- Reiterzeile (Filter oder Vergleich): options = { { id, label } }, onPick(id)
local function createToggles(options, onPick)
  local tabs = {}
  for index, option in ipairs(options) do
    tabs[index] = Widgets.CreateTab(panel, "GameFontNormalSmall", function() onPick(option.id) end)
    tabs[index].id, tabs[index].labelKey = option.id, option.label
  end
  return tabs
end

local function layoutToggles(tabs, active, anchorPoint, x, y)
  for index, tab in ipairs(tabs) do
    tab:SetLabel(L[tab.labelKey])
    tab:SetActive(tab.id == active)
    tab:ClearAllPoints()
    if index == 1 then
      tab:SetPoint(anchorPoint, panel, anchorPoint, x, y)
    else
      tab:SetPoint("LEFT", tabs[index - 1], "RIGHT", 4, 0)
    end
  end
end

local filterTabs = createToggles(FILTERS, function(id)
  state.filter, state.selected = id, nil
  refresh()
end)
local compareTabs = createToggles(COMPARES, function(id)
  state.compare = id
  refresh()
end)
local compareLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

---------------------------------------------------------------------------
-- Liste der Läufe
---------------------------------------------------------------------------
local listArea = Widgets.CreateScrollArea(panel, { step = SCROLL_STEP, keepInRange = true })
listArea:SetPoint("TOPLEFT", MARGIN, -MARGIN - TITLE_HEIGHT - FILTER_HEIGHT)
listArea:SetPoint("BOTTOMLEFT", MARGIN, MARGIN)
listArea:SetWidth(LIST_WIDTH)
local listContent = CreateFrame("Frame", nil, listArea)
listContent:SetSize(LIST_WIDTH, 1)
listArea:SetScrollChild(listContent)
local listRows = {}

local function createListRow(index)
  local row = CreateFrame("Button", nil, listContent)
  row:SetSize(LIST_WIDTH, ROW_HEIGHT)
  row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
  row.background = row:CreateTexture(nil, "BACKGROUND")
  row.background:SetAllPoints()
  row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.name:SetPoint("TOPLEFT", 4, -3)
  row.badge = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.badge:SetPoint("TOPRIGHT", -4, -4)
  row.name:SetPoint("RIGHT", row.badge, "LEFT", -4, 0)
  row.name:SetJustifyH("LEFT")
  row.name:SetWordWrap(false)
  row.date = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.date:SetPoint("BOTTOMLEFT", 4, 3)
  row.time = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.time:SetPoint("BOTTOMRIGHT", -4, 3)
  row:SetScript("OnClick", function(self)
    state.selected = self.recordTime
    refresh()
  end)
  return row
end

-- Markierung eines Laufs in der Liste
local function badgeOf(records, index)
  local record = records[index]
  if InstanceRuns.IsBest(records, index) then return colored("good", L.DUNGEON_RUNS_BADGE_BEST) end
  if InstanceBosses.List(record.mapID, record.difficultyID) and not InstanceRuns.IsCompleted(record) then
    return colored("bad", L.DUNGEON_RUNS_BADGE_OPEN)
  end
  if record.instanceType == InstanceRuns.RAID then return colored("info", L.DUNGEON_RUNS_BADGE_RAID) end
  return ""
end

local function matchesFilter(record)
  return state.filter == ALL or record.instanceType == state.filter
end

-- Indizes der sichtbaren Läufe (neueste zuerst, höchstens MAX_LIST_ROWS)
local function visibleIndices(records)
  local indices = {}
  for index, record in ipairs(records) do
    if matchesFilter(record) then indices[#indices + 1] = index end
    if #indices >= MAX_LIST_ROWS then break end
  end
  return indices
end

local function renderList(records, indices, selectedIndex)
  for position, index in ipairs(indices) do
    local record = records[index]
    local row = listRows[position] or createListRow(position)
    listRows[position] = row
    row.recordTime = record.time
    row.name:SetText(record.name or "?")
    row.badge:SetText(badgeOf(records, index))
    row.date:SetText(date(L.DATE_FORMAT, record.time))
    row.time:SetText(Format.Duration(InstanceRuns.Seconds(record)))
    local r, g, b = Theme.RGB(index == selectedIndex and "accent" or "background")
    row.background:SetColorTexture(r, g, b, index == selectedIndex and LIST_ROW_ALPHA or 0)
    row:Show()
  end
  for position = #indices + 1, #listRows do listRows[position]:Hide() end
  listContent:SetHeight(math.max(1, #indices * ROW_HEIGHT))
end

---------------------------------------------------------------------------
-- Details des gewählten Laufs (eigener Bildlauf: Raids haben viele Bosse)
---------------------------------------------------------------------------
local detailArea = Widgets.CreateScrollArea(panel, { step = SCROLL_STEP, keepInRange = true })
detailArea:SetPoint("TOPLEFT", DETAIL_LEFT, -MARGIN - TITLE_HEIGHT - FILTER_HEIGHT)
detailArea:SetPoint("BOTTOMRIGHT", -MARGIN, MARGIN)
local detail = CreateFrame("Frame", nil, detailArea)
detail:SetSize(DETAIL_WIDTH, 1)
detailArea:SetScrollChild(detail)

local runName = detail:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
runName:SetPoint("TOPLEFT")
runName:SetJustifyH("LEFT")
local runInfo = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
runInfo:SetPoint("TOPLEFT", runName, "BOTTOMLEFT", 0, -2)
-- Platz rechts für das Endboss-Porträt
runName:SetWidth(DETAIL_WIDTH - HEADER_PORTRAIT_SIZE - SECTION_GAP)
runInfo:SetWidth(DETAIL_WIDTH - HEADER_PORTRAIT_SIZE - SECTION_GAP)
runInfo:SetJustifyH("LEFT")
-- Endboss groß rechts im Kopf (Kopf und Kacheln lassen rechts oben Platz)
local endBossPortrait = CreatureModel.Create(detail, HEADER_PORTRAIT_SIZE)
endBossPortrait:SetPoint("TOPRIGHT")
local emptyText = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
emptyText:SetPoint("TOPLEFT")

local TILE_WIDTH = (DETAIL_WIDTH - (TILE_COLUMNS - 1) * TILE_GAP) / TILE_COLUMNS
local tiles = {}
for index = 1, 2 * TILE_COLUMNS do
  local tile = CreateFrame("Frame", nil, detail)
  tile:SetSize(TILE_WIDTH, TILE_HEIGHT)
  local column, line = (index - 1) % TILE_COLUMNS, math.floor((index - 1) / TILE_COLUMNS)
  tile:SetPoint("TOPLEFT", runInfo, "BOTTOMLEFT", column * (TILE_WIDTH + TILE_GAP),
    -SECTION_GAP - line * (TILE_HEIGHT + TILE_GAP))
  local background = tile:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints()
  background:SetColorTexture(1, 1, 1, 0.06)
  tile.label = tile:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  tile.label:SetPoint("TOPLEFT", 6, -4)
  tile.value = tile:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  tile.value:SetPoint("LEFT", 6, 0)
  tile.note = tile:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  tile.note:SetPoint("BOTTOMLEFT", 6, 4)
  for _, text in ipairs({ tile.label, tile.value, tile.note }) do
    text:SetPoint("RIGHT", -6, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
  end
  tiles[index] = tile
end
local TILES_BOTTOM = SECTION_GAP + 2 * TILE_HEIGHT + TILE_GAP + SECTION_GAP

-- Bosstabelle: (Porträt,) Name links, vier Zahlenspalten rechts; portraitSize nil = Kopfzeile ohne Porträt
local NUMBER_COLUMNS = 4
local function createTableRow(fontObject, portraitSize)
  local row = CreateFrame("Frame", nil, detail)
  row:SetSize(DETAIL_WIDTH, portraitSize and BOSS_ROW_HEIGHT or TABLE_ROW_HEIGHT)
  row.cells = {}
  for column = NUMBER_COLUMNS, 1, -1 do
    local cell = row:CreateFontString(nil, "OVERLAY", fontObject)
    cell:SetWidth(TABLE_NUMBER_WIDTH)
    cell:SetJustifyH("RIGHT")
    cell:SetPoint("RIGHT", row, "RIGHT", -(NUMBER_COLUMNS - column) * TABLE_NUMBER_WIDTH, 0)
    row.cells[column + 1] = cell
  end
  local nameLeft = 4
  if portraitSize then
    row.portrait = CreatureModel.Create(row, portraitSize)
    row.portrait:SetPoint("LEFT", nameLeft, 0)
    nameLeft = nameLeft + portraitSize + 6
  end
  local name = row:CreateFontString(nil, "OVERLAY", fontObject)
  name:SetPoint("LEFT", nameLeft, 0)
  name:SetPoint("RIGHT", row.cells[2], "LEFT", -4, 0)
  name:SetJustifyH("LEFT")
  name:SetWordWrap(false)
  row.cells[1] = name
  return row
end

local tableHeader = createTableRow("GameFontDisableSmall")
tableHeader:SetPoint("TOPLEFT", runInfo, "BOTTOMLEFT", 0, -TILES_BOTTOM)
local bossRows = {}

local lootTitle = detail:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local lootText = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
lootText:SetPoint("TOPLEFT", lootTitle, "BOTTOMLEFT", 0, -4)
lootText:SetWidth(DETAIL_WIDTH)
lootText:SetJustifyH("LEFT")
lootText:SetSpacing(2)

local function deltaText(value, reference)
  if not (value and reference) then return "" end
  return Format.SplitDelta(value - reference)
end

local function setTile(index, label, value, note)
  local tile = tiles[index]
  tile.label:SetText(L[label])
  tile.value:SetText(value)
  tile.note:SetText(note or "")
end

local function fillTiles(record, reference, compare)
  local counters = record.counters
  local rate = (record.seconds or 0) > 0 and (record.xp or 0) * SECONDS_PER_HOUR / record.seconds or 0
  local timeNote = reference and string.format(L[compare.id == InstanceRuns.BEST and "DUNGEON_RUN_VS_BEST"
    or "DUNGEON_RUN_VS_LAST"], deltaText(InstanceRuns.Seconds(record), InstanceRuns.Seconds(reference))) or ""
  setTile(1, "DUNGEON_RUNS_TILE_TIME", Format.Duration(InstanceRuns.Seconds(record)), timeNote)
  setTile(2, "DUNGEON_RUNS_TILE_DEATHS", tostring(counters.deaths or 0))
  setTile(3, "DUNGEON_RUNS_TILE_KILLS", tostring(counters.kills or 0))
  setTile(4, "DUNGEON_RUNS_TILE_XP", Format.Number(record.xp or 0),
    string.format(L.DUNGEON_RUNS_XP_PER_HOUR, Format.Number(rate)))
  local rares = InstanceBosses.RaresKilled(record)
  setTile(5, "DUNGEON_RUNS_TILE_BOSSES", InstanceBosses.ProgressText(record) or "-",
    rares > 0 and colored("accent", string.format(L.DUNGEON_RUNS_RARES, rares)) or nil)
  setTile(6, "DUNGEON_RUNS_TILE_MONEY", counters.money and Format.Money(counters.money) or "-")
  setTile(7, "DUNGEON_RUNS_TILE_QUESTS", counters.quests and tostring(counters.quests) or "-")
  setTile(8, "DUNGEON_RUNS_TILE_GROUP", record.groupSize and tostring(record.groupSize) or "-")
end

-- Bosse in Dungeon-Reihenfolge, danach besiegte Bosse außerhalb der Bossliste in Kill-Reihenfolge
local function bossOrder(record)
  local order, listed = {}, {}
  for _, id in ipairs(InstanceBosses.List(record.mapID, record.difficultyID) or {}) do
    order[#order + 1], listed[id] = id, true
  end
  for id in string.gmatch(record.bosses or "", "%d+") do
    id = tonumber(id)
    if not listed[id] then order[#order + 1], listed[id] = id, true end
  end
  return order
end

-- { [NPC-ID] = Sekunden } der Rare eines Laufs (Vergleichsspalte)
local function rareSplits(record)
  local splits = {}
  for _, rare in ipairs(record and InstanceBosses.Rares(record) or {}) do splits[rare.npcID] = rare.seconds end
  return splits
end

-- Zeile der Bosstabelle (wiederverwendet) an Position index
local function bossRow(index)
  local row = bossRows[index] or createTableRow("GameFontHighlightSmall", ROW_PORTRAIT_SIZE)
  bossRows[index] = row
  row:SetPoint("TOPLEFT", tableHeader, "BOTTOMLEFT", 0, -(index - 1) * BOSS_ROW_HEIGHT)
  row:Show()
  return row
end

-- Bosstabelle füllen; Rückgabe: Höhe
local function fillBosses(record, reference, compare, xpById)
  local cells = tableHeader.cells
  cells[1]:SetText(L.DUNGEON_RUNS_COLUMN_BOSS)
  cells[2]:SetText(L.DUNGEON_RUNS_COLUMN_SPLIT)
  cells[3]:SetText(L[compare.column])
  cells[4]:SetText(L.DUNGEON_RUNS_COLUMN_DIFF)
  cells[5]:SetText(L.DUNGEON_RUNS_COLUMN_XP)
  local killed, splits = InstanceBosses.Killed(record), InstanceRuns.Splits(record)
  local referenceSplits = reference and InstanceRuns.Splits(reference) or {}
  local order = bossOrder(record)
  for index, id in ipairs(order) do
    local row = bossRow(index)
    CreatureModel.Set(row.portrait, InstanceBosses.NpcID(id))
    local name = InstanceBosses.Name(id) or tostring(id)
    if InstanceBosses.IsRare(id) then name = name .. colored("accent", " " .. L.DUNGEON_RUNS_RARE_TAG) end
    local split, referenceSplit = splits[id], referenceSplits[id]
    row.cells[1]:SetText(killed[id] and name or colored("muted", name))
    row.cells[2]:SetText(killed[id] and (split and Format.Duration(split) or "?")
      or colored("muted", L.DUNGEON_RUNS_NOT_KILLED))
    row.cells[3]:SetText(referenceSplit and colored("muted", Format.Duration(referenceSplit)) or "-")
    row.cells[4]:SetText(deltaText(split, referenceSplit))
    row.cells[5]:SetText(xpById[id] and Format.Number(xpById[id]) or "")
  end
  -- Rare ohne Encounter (nur besiegte, nie Fortschritt) unter den Bossen
  local rows, referenceRares = #order, rareSplits(reference)
  for _, rare in ipairs(InstanceBosses.Rares(record)) do
    rows = rows + 1
    local row, referenceSplit = bossRow(rows), referenceRares[rare.npcID]
    CreatureModel.Set(row.portrait, rare.npcID)
    row.cells[1]:SetText((rare.name or tostring(rare.npcID)) .. colored("accent", " " .. L.DUNGEON_RUNS_RARE_TAG))
    row.cells[2]:SetText(Format.Duration(rare.seconds))
    row.cells[3]:SetText(referenceSplit and colored("muted", Format.Duration(referenceSplit)) or "-")
    row.cells[4]:SetText(deltaText(rare.seconds, referenceSplit))
    row.cells[5]:SetText("")
  end
  for index = rows + 1, #bossRows do bossRows[index]:Hide() end
  return TABLE_ROW_HEIGHT + rows * BOSS_ROW_HEIGHT
end

-- Ergebnis eines Wurfs aus Sicht des Charakters (ownName = Kurzname)
local function rollResult(roll, ownName)
  local Report = ns.LootRollReport
  local number = roll.ownRoll and string.format(" (%s)", roll.ownRoll) or ""
  if roll.winner and roll.winner == ownName then
    local kind = roll.ownChoice or roll.winnerChoice
    return colored("good", string.format(L.DUNGEON_RUNS_ROLL_WON, kind and Report.KindLabel(kind) or "") .. number)
  elseif roll.ownChoice and roll.ownChoice ~= ns.LootRolls.PASS then
    return colored("bad", string.format(L.DUNGEON_RUNS_ROLL_LOST, Report.KindLabel(roll.ownChoice)) .. number)
  elseif roll.winner then
    return colored("muted", string.format(L.DUNGEON_RUNS_ROLL_WINNER, roll.winner))
  end
  return ""
end

local function lootLines(items, ownName)
  local lines = {}
  for _, item in ipairs(items) do
    local text = item.link
    if item.roll then
      text = text .. " " .. rollResult(item.roll, ownName)
    elseif (item.quantity or 1) > 1 then
      text = text .. " x" .. item.quantity
    end
    lines[#lines + 1] = text
  end
  return #lines > 0 and table.concat(lines, "\n") or colored("muted", L.DUNGEON_RUNS_NO_LOOT)
end

local function statusText(record)
  if record.isCurrent then return colored("accent", L.DUNGEON_RUNS_STATUS_RUNNING) end
  if InstanceRuns.IsCompleted(record) then return colored("good", L.DUNGEON_RUNS_STATUS_DONE) end
  local progress = InstanceBosses.ProgressText(record)
  if not progress then return "" end
  return colored("bad", string.format(L.DUNGEON_RUNS_STATUS_OPEN, progress))
end

local function renderDetail(records, index)
  local record = records and records[index]
  local hasRecord = record ~= nil
  emptyText:SetShown(not hasRecord)
  emptyText:SetText(L.DUNGEON_RUNS_EMPTY)
  for _, part in ipairs({ runName, runInfo, tableHeader, lootTitle, lootText, compareLabel, endBossPortrait }) do part:SetShown(hasRecord) end
  for _, tile in ipairs(tiles) do tile:SetShown(hasRecord) end
  for _, tab in ipairs(compareTabs) do tab:SetShown(hasRecord) end
  if not hasRecord then
    for _, row in ipairs(bossRows) do row:Hide() end
    detail:SetHeight(1)
    return
  end
  local compare = state.compare == InstanceRuns.LAST and COMPARES[2] or COMPARES[1]
  local reference = InstanceRuns.Reference(records, index, compare.id)
  runName:SetText(record.name or "?")
  CreatureModel.Set(endBossPortrait,
    InstanceBosses.NpcID(InstanceBosses.EndBoss(InstanceBosses.List(record.mapID, record.difficultyID))))
  runInfo:SetText(string.format(L.DUNGEON_RUNS_INFO, date(L.DATE_FORMAT, record.time), record.level or "?",
    statusText(record)))
  fillTiles(record, reference, compare)
  local windowEnd = InstanceRuns.WindowEnd(records, index)
  local tableHeight = fillBosses(record, reference, compare,
    InstanceRuns.BossXp(state.characterKey, record, windowEnd))
  lootTitle:SetPoint("TOPLEFT", tableHeader, "TOPLEFT", 0, -tableHeight - SECTION_GAP)
  lootTitle:SetText(L.DUNGEON_RUNS_LOOT)
  local ownName = state.characterKey:match("^([^-]+)")
  lootText:SetText(lootLines(InstanceRuns.Loot(state.characterKey, record, windowEnd), ownName))
  local height = (runName:GetStringHeight() or 0) + TILES_BOTTOM + tableHeight + SECTION_GAP
    + (lootTitle:GetStringHeight() or 0) + 4 + (lootText:GetStringHeight() or 0)
  detail:SetHeight(math.max(1, height))
end

---------------------------------------------------------------------------
-- Gesamtstand
---------------------------------------------------------------------------
local selectedIsCurrent = false

refresh = function()
  if not state.characterKey then return end
  title:SetText(L.DUNGEON_RUNS_TITLE)
  layoutToggles(filterTabs, state.filter, "TOPLEFT", MARGIN, -MARGIN - TITLE_HEIGHT)
  layoutToggles(compareTabs, state.compare, "TOPRIGHT", -MARGIN - 160, -MARGIN - TITLE_HEIGHT)
  compareLabel:SetText(L.DUNGEON_RUNS_COMPARE)
  compareLabel:ClearAllPoints()
  compareLabel:SetPoint("RIGHT", compareTabs[1], "LEFT", -6, 0)
  -- Zweiter Reiter rechts am Rand: die Zeile hängt am ersten, deshalb Platz für den zweiten lassen
  compareTabs[1]:ClearAllPoints()
  compareTabs[1]:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -MARGIN - compareTabs[2]:GetWidth() - 4,
    -MARGIN - TITLE_HEIGHT)
  local records = ns.History.GetInstanceLog(state.characterKey)
  local indices = visibleIndices(records)
  local selectedIndex
  for _, index in ipairs(indices) do
    if records[index].time == state.selected then selectedIndex = index end
  end
  selectedIndex = selectedIndex or indices[1]
  state.selected = selectedIndex and records[selectedIndex].time or nil
  selectedIsCurrent = selectedIndex ~= nil and records[selectedIndex].isCurrent == true
  renderList(records, indices, selectedIndex)
  renderDetail(records, selectedIndex)
end

-- Fenster für einen Charakter öffnen (Standard: eingeloggter), recordTime = vorgewählter Lauf (time des Eintrags)
function InstanceRunWindow.Show(characterKey, recordTime)
  if not ns.db then return end
  state.characterKey = characterKey or ns.characterKey
  state.selected = recordTime
  if recordTime then state.filter = ALL end
  refresh()
  listArea:ScrollTo(0)
  detailArea:ScrollTo(0)
  panel:Show()
end

function InstanceRunWindow.Toggle()
  if panel:IsShown() then panel:Hide() else InstanceRunWindow.Show() end
end

function InstanceRunWindow.IsShown()
  return panel:IsShown()
end

-- Test-Zugriff: gewählter Lauf, Kacheln, Bosszeilen und Beutetext
function InstanceRunWindow.Parts()
  return { selected = state.selected, tiles = tiles, bossRows = bossRows, loot = lootText, listRows = listRows,
    info = runInfo, endBossPortrait = endBossPortrait }
end

function InstanceRunWindow.SetCompare(id)
  state.compare = id
  refresh()
end

function InstanceRunWindow.SetFilter(id)
  state.filter, state.selected = id, nil
  refresh()
end

local sinceUpdate = 0
ns.SetUpdateScript(panel, "InstanceRunWindow", function(_, elapsed)
  sinceUpdate = sinceUpdate + elapsed
  if sinceUpdate < UPDATE_INTERVAL or not selectedIsCurrent then return end
  sinceUpdate = 0
  refresh()
end)

ns.RegisterApply(function()
  if panel:IsShown() then refresh() end
end)

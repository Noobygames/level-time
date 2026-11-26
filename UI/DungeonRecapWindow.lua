-- Dungeon-Recap (LT-334): Fenster nach dem Endboss mit vier Reitern: Übersicht (Kacheln und Auszeichnungen),
-- Beute (Würfe und Beute des Laufs), Gruppe (Zahlen aus dem Schadensmesser je Spieler, Porträts live per
-- SetPortraitTexture, sonst Klassensymbol) und Gegner (gefährlichste Gegner, Boss-Zeiten). Im Kopf das Porträt des
-- zuletzt besiegten Bosses (Lib/CreatureModel.lua) und die Laufzeit: grün mit ▲-Pfeil = schneller, rot mit ▼-Pfeil =
-- langsamer als der beste eigene Lauf derselben Instanz (Farbe nie allein). Zahlen und Auszeichnungen liefern
-- Tracking/RunMeter.lua und History/InstanceRecap.lua; fehlen die Messerzahlen (Client ohne Schadensmesser), zeigt das
-- Fenster nur, was das Journal weiß. Öffnet nach dem Endboss von selbst (Einstellung dungeonRecapAutoOpen), sonst über
-- /lt recap run, den Knopf "Recap" im Run-Fenster oder Linksklick auf den Live-Tracker; im laufenden Lauf mit dem
-- Zwischenstand (LT-405). Beute und Würfe kommen erst nach dem Kill: das Fenster rechnet
-- deshalb alle UPDATE_INTERVAL Sekunden neu, solange es offen ist.
-- shortcut: die Gruppen-Tabelle zeigt höchstens MAX_PLAYERS Spieler (Raids: die mit dem meisten Schaden).
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme
local Format = ns.Format
local InstanceBosses = ns.InstanceBosses
local InstanceRuns = ns.InstanceRuns
local InstanceRecap = ns.InstanceRecap
local CreatureModel = ns.CreatureModel

ns.RegisterDefaults({ settings = { dungeonRecapAutoOpen = true } })

local DungeonRecapWindow = {}
ns.DungeonRecapWindow = DungeonRecapWindow

local WIDTH, HEIGHT = 640, 520
local PADDING_X, PADDING_Y = 16, 12
local HEADER_HEIGHT = 40
local GAP, SMALL_GAP = 8, 4
local PORTRAIT_SIZE = 32
local SUMMARY_HEIGHT = 28
local TAB_HEIGHT = 24
local FOOTER_HEIGHT = 28
local ROW_HEIGHT = 32
local TILE_HEIGHT = 56
local TILE_COLUMNS = 3
local AWARD_COLUMNS = 2
local AWARD_HEIGHT = 36
local ICON_SIZE = 24
local MAX_PLAYERS = 8
local MAX_BOSS_ROWS = 12
local MAX_MOBS = 5
local NUMBER_WIDTH = 80
local SHORT_NUMBER_WIDTH = 56
local SCROLL_STEP = 40
local UPDATE_INTERVAL = 2
local SECONDS_PER_HOUR = 3600
local ROW_ALPHA = 0.25
local ARROW_SIZE = 14
local ARROW_UP = "|TInterface\\Buttons\\Arrow-Up-Up:" .. ARROW_SIZE .. "|t"      -- besser als zuvor
local ARROW_DOWN = "|TInterface\\Buttons\\Arrow-Down-Up:" .. ARROW_SIZE .. "|t"  -- schlechter als zuvor
local MVP_ICON = "|TInterface\\GroupFrame\\UI-Group-LeaderIcon:14|t"
local BUTTON_PADDING = 24

local TAB_OVERVIEW, TAB_LOOT, TAB_GROUP, TAB_ENEMIES = "overview", "loot", "group", "enemies"
local TABS = {
  { id = TAB_OVERVIEW, label = "DUNGEON_RECAP_TAB_OVERVIEW" },
  { id = TAB_LOOT, label = "DUNGEON_RECAP_TAB_LOOT" },
  { id = TAB_GROUP, label = "DUNGEON_RECAP_TAB_GROUP" },
  { id = TAB_ENEMIES, label = "DUNGEON_RECAP_TAB_ENEMIES" },
}

-- Auszeichnungen: Symbol, Beschriftung, Wertformat (Format = "time" | "number" | "count") und Tooltip-Text
local AWARDS = {
  [InstanceRecap.FASTEST_BOSS] = { icon = "Interface\\Icons\\INV_Misc_PocketWatch_01", key = "FASTEST", kind = "time" },
  [InstanceRecap.MOST_DEATHS] = { icon = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull", key = "DEATHS", kind = "count" },
  [InstanceRecap.DANGEROUS_MOB] = { icon = "Interface\\Icons\\Spell_Shadow_DeathCoil", key = "MOB", kind = "number" },
  [InstanceRecap.DAMAGE] = { icon = "Interface\\Icons\\INV_Sword_04", key = "DAMAGE", kind = "number" },
  [InstanceRecap.BOSS_DAMAGE] = { icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01", key = "BOSS_DAMAGE", kind = "number" },
  [InstanceRecap.HEALING] = { icon = "Interface\\Icons\\Spell_Holy_FlashHeal", key = "HEALING", kind = "number" },
  [InstanceRecap.INTERRUPTS] = { icon = "Interface\\Icons\\Ability_Kick", key = "INTERRUPTS", kind = "count" },
  [InstanceRecap.TANK] = { icon = "Interface\\Icons\\INV_Shield_06", key = "TANK", kind = "number" },
  [InstanceRecap.LOOT_LUCK] = { icon = "Interface\\Buttons\\UI-GroupLoot-Dice-Up", key = "LOOT_LUCK", kind = "count" },
}

local state = { characterKey = nil, time = nil, tab = TAB_OVERVIEW }

local function colored(colorName, text)
  return Theme.Hex(colorName) .. text .. "|r"
end

local function classColored(class, text)
  local color = Theme.ClassColor(class)
  if not color then return text end
  return string.format("|cff%02x%02x%02x%s|r", math.floor(color[1] * 255 + 0.5), math.floor(color[2] * 255 + 0.5),
    math.floor(color[3] * 255 + 0.5), text)
end

-- Pfeil und Text in der Farbe der Abweichung: weniger = besser (▲ grün), mehr = schlechter (▼ rot), 0 neutral
local function deviation(delta, text)
  if delta < 0 then return ARROW_UP .. " " .. colored("good", text) end
  if delta > 0 then return ARROW_DOWN .. " " .. colored("bad", text) end
  return colored("muted", text)
end

---------------------------------------------------------------------------
-- Rahmen und Kopf
---------------------------------------------------------------------------
local panelName = ns.GlobalName("DungeonRecap")
local panel = Widgets.CreatePanel(panelName, 0.95)
panel:SetSize(WIDTH, HEIGHT)
panel:SetPoint("CENTER", 0, 40)
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
table.insert(UISpecialFrames, panelName)  -- mit ESC schließen

local header = Widgets.CreateWindowHeader(panel, "")
local bossPortrait = CreatureModel.Create(header, PORTRAIT_SIZE)
bossPortrait:SetPoint("LEFT", PADDING_X - SMALL_GAP, 0)
header.title:ClearAllPoints()
header.title:SetPoint("LEFT", bossPortrait, "RIGHT", GAP, 0)
header.title:SetPoint("RIGHT", header.close, "LEFT", -GAP, 0)
header.title:SetJustifyH("LEFT")
header.title:SetWordWrap(false)

local infoText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
infoText:SetPoint("TOPLEFT", PADDING_X, -HEADER_HEIGHT - GAP)
local durationText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
durationText:SetPoint("TOPRIGHT", -PADDING_X, -HEADER_HEIGHT - SMALL_GAP)
local deltaText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
deltaText:SetPoint("RIGHT", durationText, "LEFT", -GAP, 0)
infoText:SetPoint("RIGHT", deltaText, "LEFT", -GAP, 0)
infoText:SetJustifyH("LEFT")
infoText:SetWordWrap(false)

local refresh
local tabButtons = {}
for index, tab in ipairs(TABS) do
  local button = Widgets.CreateTab(panel, "GameFontNormal", function()
    state.tab = tab.id
    refresh()
  end)
  button.id, button.labelKey = tab.id, tab.label
  tabButtons[index] = button
end

local TABS_TOP = HEADER_HEIGHT + GAP + SUMMARY_HEIGHT

local body = Widgets.CreateScrollArea(panel, { step = SCROLL_STEP, keepInRange = true })
body:SetPoint("TOPLEFT", PADDING_X, -TABS_TOP - TAB_HEIGHT - GAP)
body:SetPoint("BOTTOMRIGHT", -PADDING_X, PADDING_Y + FOOTER_HEIGHT + GAP)
local BODY_WIDTH = WIDTH - 2 * PADDING_X
local content = CreateFrame("Frame", nil, body)
content:SetSize(BODY_WIDTH, 1)
body:SetScrollChild(content)

local function createPage()
  local page = CreateFrame("Frame", nil, content)
  page:SetPoint("TOPLEFT")
  page:SetSize(BODY_WIDTH, 1)
  return page
end
local pages = { [TAB_OVERVIEW] = createPage(), [TAB_LOOT] = createPage(), [TAB_GROUP] = createPage(),
  [TAB_ENEMIES] = createPage() }

-- Fuß: Run-Fenster und Schließen (Primärbutton rechts unten)
local closeButton = Widgets.CreateButton(panel, 80, FOOTER_HEIGHT, function() panel:Hide() end)
closeButton:SetPoint("BOTTOMRIGHT", -PADDING_X, PADDING_Y)
closeButton:SetPrimary(true)
local runsButton = Widgets.CreateButton(panel, 80, FOOTER_HEIGHT, function()
  ns.InstanceRunWindow.Show(state.characterKey, state.time)
end)
runsButton:SetPoint("RIGHT", closeButton, "LEFT", -GAP, 0)

local function fitButton(button, text)
  button:SetText(text)
  button:SetWidth(button:GetTextWidth() + BUTTON_PADDING)
end

---------------------------------------------------------------------------
-- Zeilen und Texte
---------------------------------------------------------------------------
local function createText(parent, fontObject, justify)
  local text = parent:CreateFontString(nil, "OVERLAY", fontObject)
  text:SetJustifyH(justify or "LEFT")
  text:SetWordWrap(false)
  return text
end

local function createStripe(row, index)
  local stripe = row:CreateTexture(nil, "BACKGROUND")
  stripe:SetAllPoints()
  stripe:SetColorTexture(0, 0, 0, index % 2 == 0 and 0 or ROW_ALPHA)
end

local function createSectionTitle(page)
  local title = createText(page, "GameFontNormal")
  return title
end

-- Kachel (Beschriftung, Wert, Zusatz)
local function createTile(page, index)
  local tile = CreateFrame("Frame", nil, page, "BackdropTemplate")
  local width = (BODY_WIDTH - (TILE_COLUMNS - 1) * GAP) / TILE_COLUMNS
  tile:SetSize(width, TILE_HEIGHT)
  local column, line = (index - 1) % TILE_COLUMNS, math.floor((index - 1) / TILE_COLUMNS)
  tile:SetPoint("TOPLEFT", column * (width + GAP), -line * (TILE_HEIGHT + GAP))
  Theme.RegisterCard(tile)
  tile.label = createText(tile, "GameFontHighlightSmall")
  tile.label:SetPoint("TOPLEFT", GAP + SMALL_GAP, -SMALL_GAP)
  tile.value = createText(tile, "GameFontNormalLarge")
  tile.value:SetPoint("LEFT", GAP + SMALL_GAP, 0)
  tile.note = createText(tile, "GameFontHighlightSmall")
  tile.note:SetPoint("BOTTOMLEFT", GAP + SMALL_GAP, SMALL_GAP)
  tile.note:SetPoint("RIGHT", -GAP, 0)
  return tile
end

local TILE_COUNT = 6
local tiles = {}
for index = 1, TILE_COUNT do tiles[index] = createTile(pages[TAB_OVERVIEW], index) end
local TILES_HEIGHT = 2 * TILE_HEIGHT + GAP

local awardsTitle = createSectionTitle(pages[TAB_OVERVIEW])
awardsTitle:SetPoint("TOPLEFT", 0, -TILES_HEIGHT - GAP)
local AWARDS_TOP = TILES_HEIGHT + GAP + 16 + SMALL_GAP

local function createAwardRow(index)
  local page = pages[TAB_OVERVIEW]
  local row = CreateFrame("Frame", nil, page, "BackdropTemplate")
  local width = (BODY_WIDTH - (AWARD_COLUMNS - 1) * GAP) / AWARD_COLUMNS
  row:SetSize(width, AWARD_HEIGHT)
  local column, line = (index - 1) % AWARD_COLUMNS, math.floor((index - 1) / AWARD_COLUMNS)
  row:SetPoint("TOPLEFT", column * (width + GAP), -AWARDS_TOP - line * (AWARD_HEIGHT + SMALL_GAP))
  Theme.RegisterCard(row)
  row:EnableMouse(true)
  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(ICON_SIZE, ICON_SIZE)
  row.icon:SetPoint("LEFT", GAP, 0)
  row.label = createText(row, "GameFontHighlightSmall")
  row.label:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", GAP, 2)
  row.label:SetPoint("RIGHT", -GAP, 0)
  row.text = createText(row, "GameFontNormal")
  row.text:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", GAP, -2)
  row.text:SetPoint("RIGHT", -GAP, 0)
  Widgets.AttachTooltip(row, function() return row.tipTitle end, function() return row.tipText end)
  return row
end
local awardRows = {}

local noDataText = createText(pages[TAB_OVERVIEW], "GameFontDisableSmall")
noDataText:SetWordWrap(true)

-- Reiter Beute
local lootText = pages[TAB_LOOT]:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
lootText:SetPoint("TOPLEFT")
lootText:SetWidth(BODY_WIDTH)
lootText:SetJustifyH("LEFT")
lootText:SetSpacing(GAP)

-- Reiter Gruppe: Kopfzeile und Spielerzeilen
local function createColumns(row, headerStyle)
  local font = headerStyle and "GameFontNormalSmall" or "GameFontHighlight"
  row.cells = {}
  -- rechts nach links: Tode, Unterbr., Heilung, Schaden
  local widths = { SHORT_NUMBER_WIDTH, SHORT_NUMBER_WIDTH, NUMBER_WIDTH, NUMBER_WIDTH }
  local previous
  for index, width in ipairs(widths) do
    local cell = createText(row, font, "RIGHT")
    cell:SetWidth(width)
    if previous then cell:SetPoint("RIGHT", previous, "LEFT", -GAP, 0) else cell:SetPoint("RIGHT", -GAP, 0) end
    row.cells[#widths + 1 - index] = cell
    previous = cell
  end
  row.name = createText(row, font)
  row.name:SetPoint("LEFT", headerStyle and GAP or (GAP + ICON_SIZE + GAP), 0)
  row.name:SetPoint("RIGHT", row.cells[1], "LEFT", -GAP, 0)
end

local groupHeader = CreateFrame("Frame", nil, pages[TAB_GROUP])
groupHeader:SetSize(BODY_WIDTH, TAB_HEIGHT)
groupHeader:SetPoint("TOPLEFT")
createColumns(groupHeader, true)
local playerRows = {}
local groupNote = createText(pages[TAB_GROUP], "GameFontDisableSmall")
groupNote:SetWordWrap(true)
groupNote:SetWidth(BODY_WIDTH)

local function createPlayerRow(index)
  local row = CreateFrame("Frame", nil, pages[TAB_GROUP])
  row:SetSize(BODY_WIDTH, ROW_HEIGHT)
  row:SetPoint("TOPLEFT", 0, -TAB_HEIGHT - (index - 1) * ROW_HEIGHT)
  createStripe(row, index)
  createColumns(row, false)
  row.portrait = row:CreateTexture(nil, "ARTWORK")
  row.portrait:SetSize(ICON_SIZE, ICON_SIZE)
  row.portrait:SetPoint("LEFT", GAP, 0)
  return row
end

-- Reiter Gegner
local mobsTitle = createSectionTitle(pages[TAB_ENEMIES])
mobsTitle:SetPoint("TOPLEFT")
local mobRows, bossRows = {}, {}
local bossesTitle = createSectionTitle(pages[TAB_ENEMIES])

local function createListRow(rows, index, top)
  local row = CreateFrame("Frame", nil, pages[TAB_ENEMIES])
  row:SetSize(BODY_WIDTH, ROW_HEIGHT)
  row:SetPoint("TOPLEFT", 0, -top - (index - 1) * ROW_HEIGHT)
  createStripe(row, index)
  row.name = createText(row, "GameFontHighlight")
  row.name:SetPoint("LEFT", GAP, 0)
  row.name:SetPoint("RIGHT", -(2 * NUMBER_WIDTH + 2 * GAP), 0)
  row.first = createText(row, "GameFontHighlight", "RIGHT")
  row.first:SetWidth(NUMBER_WIDTH)
  row.first:SetPoint("RIGHT", -(NUMBER_WIDTH + 2 * GAP), 0)
  row.second = createText(row, "GameFontHighlight", "RIGHT")
  row.second:SetWidth(NUMBER_WIDTH)
  row.second:SetPoint("RIGHT", -GAP, 0)
  rows[index] = row
  return row
end

---------------------------------------------------------------------------
-- Daten
---------------------------------------------------------------------------
local function lastBossName(record)
  local lastID
  for id in string.gmatch(record.bosses or "", "%d+") do lastID = tonumber(id) end
  return lastID and InstanceBosses.Name(lastID), lastID
end

local function findRecord(records, time)
  for index, record in ipairs(records) do
    if record.time == time then return record, index end
  end
end

local function latestCompleted(records)
  for index, record in ipairs(records) do
    if InstanceRuns.IsCompleted(record) then return record, index end
  end
end

local function fillHeader(record, records, index)
  local bossName, bossID = lastBossName(record)
  CreatureModel.Set(bossPortrait, bossID and InstanceBosses.NpcID(bossID))
  header:SetTitle(bossName and string.format(L.DUNGEON_RECAP_HEADER, record.name or "?", bossName)
    or (record.name or "?"))
  local status = record.isCurrent and (InstanceRuns.IsCompleted(record) and colored("good", L.DUNGEON_RUNS_STATUS_DONE)
    or colored("accent", L.DUNGEON_RUNS_STATUS_RUNNING)) or colored("good", L.DUNGEON_RUNS_STATUS_DONE)
  infoText:SetText(string.format(L.DUNGEON_RUNS_INFO, date(L.DATE_FORMAT, record.time), record.level or "?", status))
  durationText:SetText(Format.Duration(InstanceRuns.Seconds(record)))
  local delta = InstanceRecap.TimeDelta(records, index)
  if delta then
    deltaText:SetText(deviation(delta, string.format(L.DUNGEON_RUN_VS_BEST, Format.SignedDuration(delta))))
  else
    deltaText:SetText(colored("muted", L.DUNGEON_RECAP_FIRST_RUN))
  end
end

local function setTile(index, label, value, note)
  local tile = tiles[index]
  tile.label:SetText(L[label])
  tile.value:SetText(value)
  tile.note:SetText(note or "")
end

local function fillTiles(record, records, index)
  local counters = record.counters or {}
  local rate = (record.seconds or 0) > 0 and (record.xp or 0) * SECONDS_PER_HOUR / record.seconds or 0
  local rares = InstanceBosses.RaresKilled(record)
  setTile(1, "DUNGEON_RUNS_TILE_BOSSES", InstanceBosses.ProgressText(record) or "-",
    rares > 0 and colored("accent", string.format(L.DUNGEON_RUNS_RARES, rares)) or nil)
  local reference = InstanceRuns.Reference(records, index, InstanceRuns.BEST)
  local deathsNote
  if reference and reference.counters and reference.counters.deaths then
    local difference = (counters.deaths or 0) - reference.counters.deaths
    deathsNote = deviation(difference, string.format(L.DUNGEON_RUN_VS_BEST, string.format("%+d", difference)))
  end
  setTile(2, "DUNGEON_RUNS_TILE_DEATHS", tostring(counters.deaths or 0), deathsNote)
  setTile(3, "DUNGEON_RUNS_TILE_KILLS", tostring(counters.kills or 0))
  setTile(4, "DUNGEON_RUNS_TILE_XP", Format.Number(record.xp or 0), string.format(L.DUNGEON_RUNS_XP_PER_HOUR, Format.Number(rate)))
  setTile(5, "DUNGEON_RUNS_TILE_MONEY", counters.money and Format.Money(counters.money) or "-")
  setTile(6, "DUNGEON_RUNS_TILE_GROUP", record.groupSize and tostring(record.groupSize) or "-")
end

local function awardValue(award, value)
  if award.kind == "time" then return Format.Duration(value) end
  if award.kind == "number" then return Format.Number(value) end
  return tostring(value)
end

local function fillAwards(record, loot)
  local awards = InstanceRecap.Awards(record, loot)
  for index, entry in ipairs(awards) do
    local row = awardRows[index] or createAwardRow(index)
    awardRows[index] = row
    local def = AWARDS[entry.id]
    row.icon:SetTexture(def.icon)
    row.label:SetText(L["DUNGEON_RECAP_AWARD_" .. def.key])
    row.text:SetText(string.format(L["DUNGEON_RECAP_VALUE_" .. def.key], classColored(entry.class, entry.who),
      awardValue(def, entry.value)))
    row.tipTitle, row.tipText = L["DUNGEON_RECAP_AWARD_" .. def.key], L["DUNGEON_RECAP_AWARD_" .. def.key .. "_TIP"]
    row:Show()
  end
  for index = #awards + 1, #awardRows do awardRows[index]:Hide() end
  local lines = math.ceil(#awards / AWARD_COLUMNS)
  awardsTitle:SetText(L.DUNGEON_RECAP_AWARDS)
  awardsTitle:SetShown(#awards > 0)
  noDataText:ClearAllPoints()
  noDataText:SetPoint("TOPLEFT", 0, -AWARDS_TOP - lines * (AWARD_HEIGHT + SMALL_GAP))
  noDataText:SetWidth(BODY_WIDTH)
  noDataText:SetText(ns.RunMeter.IsAvailable() and "" or L.DUNGEON_RECAP_NO_METER)
  noDataText:SetShown(not ns.RunMeter.IsAvailable())
  return AWARDS_TOP + lines * (AWARD_HEIGHT + SMALL_GAP) + (noDataText:GetStringHeight() or 0)
end

-- Gruppen-Einheit mit diesem Kurznamen (für das Porträt) oder nil
local function unitOfName(name)
  local short = name:match("^[^-]+") or name
  local units = { "player" }
  for number = 1, math.max(GetNumGroupMembers and GetNumGroupMembers() or 0, 5) do
    units[#units + 1] = (IsInRaid and IsInRaid()) and ("raid" .. number) or ("party" .. number)
  end
  for _, unit in ipairs(units) do
    if UnitExists(unit) then
      local unitName = UnitName(unit)
      if not ns.IsSecret(unitName) and unitName == short then return unit end
    end
  end
end

local function setPortrait(row, player)
  local unit = unitOfName(player.name)
  row.portrait:SetTexCoord(0, 1, 0, 1)
  if unit and SetPortraitTexture then
    SetPortraitTexture(row.portrait, unit)
    row.portrait:Show()
    return
  end
  Widgets.SetClassIcon(row.portrait, player.class)
end

local function fillGroup(record)
  local players = InstanceRecap.Players(record)
  local mvp = InstanceRecap.Mvp(players)
  groupHeader.name:SetText(L.DUNGEON_RECAP_COLUMN_PLAYER)
  groupHeader.cells[1]:SetText(L.DUNGEON_RECAP_COLUMN_DAMAGE)
  groupHeader.cells[2]:SetText(L.DUNGEON_RECAP_COLUMN_HEALING)
  groupHeader.cells[3]:SetText(L.DUNGEON_RECAP_COLUMN_INTERRUPTS)
  groupHeader.cells[4]:SetText(L.DUNGEON_RECAP_COLUMN_DEATHS)
  local shown = math.min(#players, MAX_PLAYERS)
  for index = 1, shown do
    local player = players[index]
    local row = playerRows[index] or createPlayerRow(index)
    playerRows[index] = row
    row.name:SetText(classColored(player.class, player.name) .. (player.name == mvp and (" " .. MVP_ICON) or ""))
    row.cells[1]:SetText(Format.Number(player.damage))
    row.cells[2]:SetText(Format.Number(player.healing))
    row.cells[3]:SetText(tostring(player.interrupts))
    row.cells[4]:SetText(player.deaths > 0 and colored("bad", tostring(player.deaths)) or "0")
    setPortrait(row, player)
    row:Show()
  end
  for index = shown + 1, #playerRows do playerRows[index]:Hide() end
  groupNote:ClearAllPoints()
  groupNote:SetPoint("TOPLEFT", 0, -TAB_HEIGHT - shown * ROW_HEIGHT - GAP)
  groupNote:SetText(shown > 0 and L.DUNGEON_RECAP_GROUP_NOTE or L.DUNGEON_RECAP_NO_METER)
  return TAB_HEIGHT + shown * ROW_HEIGHT + GAP + (groupNote:GetStringHeight() or 0)
end

local function fillEnemies(record, records, index)
  local mobs = InstanceRecap.Mobs(record)
  mobsTitle:SetText(L.DUNGEON_RECAP_MOBS)
  local mobCount = math.min(#mobs, MAX_MOBS)
  local top = TAB_HEIGHT
  for position = 1, mobCount do
    local row = mobRows[position] or createListRow(mobRows, position, top)
    row.name:SetText(mobs[position].name)
    row.first:SetText("")
    row.second:SetText(string.format(L.DUNGEON_RECAP_VALUE_MOB_DAMAGE, Format.Number(mobs[position].damage)))
    row:Show()
  end
  for position = mobCount + 1, #mobRows do mobRows[position]:Hide() end
  local bossesTop = top + math.max(mobCount, 1) * ROW_HEIGHT + GAP
  if mobCount == 0 then mobsTitle:SetText(L.DUNGEON_RECAP_MOBS .. " " .. colored("muted", L.DUNGEON_RECAP_NO_DATA)) end
  bossesTitle:ClearAllPoints()
  bossesTitle:SetPoint("TOPLEFT", 0, -bossesTop)
  bossesTitle:SetText(L.DUNGEON_RECAP_BOSSES)
  -- Bosse in Kill-Reihenfolge mit Zeit und Abstand zum besten anderen Lauf
  local splits = InstanceRuns.Splits(record)
  local reference = InstanceRuns.Reference(records, index, InstanceRuns.BEST)
  local referenceSplits = reference and InstanceRuns.Splits(reference) or {}
  local order = {}
  for id in string.gmatch(record.bosses or "", "%d+") do order[#order + 1] = tonumber(id) end
  local bossCount = math.min(#order, MAX_BOSS_ROWS)
  local rowsTop = bossesTop + TAB_HEIGHT
  for position = 1, bossCount do
    local id = order[position]
    local row = bossRows[position] or createListRow(bossRows, position, rowsTop)
    local rareTag = InstanceBosses.IsRare(id) and (" " .. colored("accent", L.DUNGEON_RECAP_RARE)) or ""
    row.name:SetText((InstanceBosses.Name(id) or "?") .. rareTag)
    row.first:SetText(splits[id] and Format.Duration(splits[id]) or "")
    local difference = splits[id] and referenceSplits[id] and (splits[id] - referenceSplits[id])
    row.second:SetText(difference and deviation(difference, Format.SignedDuration(difference)) or "")
    row:Show()
  end
  for position = bossCount + 1, #bossRows do bossRows[position]:Hide() end
  return rowsTop + bossCount * ROW_HEIGHT
end

---------------------------------------------------------------------------
-- Gesamtstand
---------------------------------------------------------------------------
local function showPage(id, height)
  for pageID, page in pairs(pages) do page:SetShown(pageID == id) end
  content:SetHeight(math.max(1, height))
end

refresh = function()
  if not state.characterKey then return end
  local records = ns.History.GetInstanceLog(state.characterKey)
  local record, index = findRecord(records, state.time)
  if not record then record, index = latestCompleted(records) end
  if not record then return end
  state.time = record.time
  fillHeader(record, records, index)
  fitButton(runsButton, L.DUNGEON_RECAP_RUNS)
  fitButton(closeButton, L.DUNGEON_RECAP_CLOSE)
  local previous
  for _, button in ipairs(tabButtons) do
    button:SetLabel(L[button.labelKey])
    button:SetActive(button.id == state.tab)
    button:ClearAllPoints()
    if previous then button:SetPoint("LEFT", previous, "RIGHT", GAP, 0)
    else button:SetPoint("TOPLEFT", panel, "TOPLEFT", PADDING_X, -TABS_TOP) end
    previous = button
  end
  local windowEnd = InstanceRuns.WindowEnd(records, index)
  local loot = InstanceRuns.Loot(state.characterKey, record, windowEnd)
  local height
  if state.tab == TAB_OVERVIEW then
    fillTiles(record, records, index)
    height = fillAwards(record, loot)
  elseif state.tab == TAB_LOOT then
    lootText:SetText(ns.InstanceRunWindow.LootLines(loot, state.characterKey:match("^([^-]+)")))
    height = lootText:GetStringHeight() or 0
  elseif state.tab == TAB_GROUP then
    height = fillGroup(record)
  else
    height = fillEnemies(record, records, index)
  end
  showPage(state.tab, height)
end

-- Fenster öffnen: characterKey (Standard: eingeloggter Charakter), recordTime = Lauf (time des Eintrags; Standard: der
-- offene Lauf, sonst der jüngste abgeschlossene). false, wenn es keinen solchen Lauf gibt.
function DungeonRecapWindow.Show(characterKey, recordTime)
  if not ns.db then return false end
  state.characterKey = characterKey or ns.characterKey
  local records = ns.History.GetInstanceLog(state.characterKey)
  local record
  if recordTime then
    record = findRecord(records, recordTime)
  elseif records[1] and records[1].isCurrent then
    record = records[1]
  else
    record = latestCompleted(records)
  end
  ns.Debug("recap", "dungeon recap show: requested %s, current %s, found %s", recordTime,
    records[1] and records[1].isCurrent and true or false, record and record.time)
  if not record then return false end
  state.time, state.tab = record.time, TAB_OVERVIEW
  refresh()
  body:ScrollTo(0)
  panel:Show()
  return true
end

function DungeonRecapWindow.IsShown()
  return panel:IsShown()
end

-- Test-Zugriff
function DungeonRecapWindow.Parts()
  return { tiles = tiles, awardRows = awardRows, playerRows = playerRows, mobRows = mobRows, bossRows = bossRows,
    header = header, delta = deltaText, duration = durationText, loot = lootText, portrait = bossPortrait,
    pages = pages, tabs = tabButtons, state = state }
end

function DungeonRecapWindow.SetTab(id)
  state.tab = id
  refresh()
end

local sinceUpdate = 0
ns.SetUpdateScript(panel, "DungeonRecapWindow", function(_, elapsed)
  sinceUpdate = sinceUpdate + elapsed
  if sinceUpdate < UPDATE_INTERVAL then return end
  sinceUpdate = 0
  refresh()
end)

ns.RegisterApply(function()
  if panel:IsShown() then refresh() end
end)

-- Nach dem Endboss und dem Einsammeln der Messerzahlen (RunMeter.lua) von selbst öffnen
ns.RunMeter.OnReady(function(run)
  if ns.db.dungeonRecapAutoOpen then DungeonRecapWindow.Show(ns.characterKey, run.startedAt) end
end)

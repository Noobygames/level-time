-- Zähler am Würfel-Fenster (Roadmap 364, Einstellungen lootRollCounts und lootRollNames, Standard aus): unter jedem
-- Blizzard-Würfelfenster eine Zeile mit Blizzards Knopf-Symbolen und der Zahl der Spieler je Wahl (Bedarf, Gier,
-- Entzaubern und Transmog nur, wenn jemand sie gewählt hat, Passen) und einer Sanduhr für die, die noch fehlen.
-- Tooltip je Zähler (lootRollNames): die Namen in Klassenfarbe, mit Wurf, sobald bekannt.
-- Blizzards Fenster: GroupLootFrame1..4 (Classic Blizzard_UIPanels_Game/Classic/LootFrame.xml, Retail/Forever
-- Mainline/GroupLootFrame.xml), frame.rollID setzt GroupLootFrame_OpenNewFrame bzw. GroupLootContainer_OpenNewFrame.
-- Nur eigene Kind-Frames und HookScript (OnShow/OnHide); Blizzards Skripte bleiben unberührt (kein Taint). Die Zeile
-- sitzt unter dem Fenster: der Stapel lässt je Fenster 100 Punkte (reservedSize), die Fenster sind 84 (Classic) bzw.
-- 67 (Retail) hoch.
-- Ersatz: Würfe, für die kein Blizzard-Fenster sichtbar ist (anderes Addon ersetzt sie, mehr als vier Würfe in
-- Retail), stehen auf einer eigenen Karte (LevelTimerLootRolls; Position und Größe über Lib/Frames.lua, Id
-- "lootRolls", im Edit-Modus mit Beispielwürfen).
-- Stehen bleiben (Nutzer-Wunsch): Hat man selbst gewählt, schließt Blizzard das Würfelfenster, der Wurf läuft aber
-- weiter. Solche Würfe bleiben mit Zählern auf der Karte, bis der Gewinner feststeht (oder höchstens
-- PENDING_GRACE Sekunden nach Ablauf der Würfelzeit, falls nie eine Gewinnerzeile kommt); danach zeigt die Karte
-- WINNER_SECONDS lang das Ergebnis (LootRollReport.SummaryText).
-- Aktualisiert bei Änderungen an einem Wurf (LootRolls.OnChange/OnComplete), beim Ein-/Ausblenden der Fenster und
-- einmal je Sekunde, solange die Karte offene oder abgeschlossene Würfe zeigt (Ablauf).
local _, ns = ...
local L = ns.L
local LootRolls = ns.LootRolls
local Widgets = ns.Widgets
local Theme = ns.Theme

local LootRollDisplay = {}
ns.LootRollDisplay = LootRollDisplay

local ICON_SIZE = 14
local ICON_TEXT_GAP = 2
local CELL_GAP = 8
local ROW_OFFSET = -2           -- Abstand der Zeile unter dem Blizzard-Fenster
local MAX_BLIZZARD_FRAMES = 10  -- GroupLootFrame1..n (heute 4 in allen Clients)
local DEFAULT_POS = { "BOTTOM", "BOTTOM", 0, 260 }
local DISPLAY_KINDS = { LootRolls.NEED, LootRolls.GREED, LootRolls.DISENCHANT, LootRolls.TRANSMOG, LootRolls.PASS,
  LootRolls.WAITING }
local ALWAYS_SHOWN = { need = true, greed = true, pass = true }
local WINNER_SECONDS = 10   -- so lange steht das Ergebnis auf der Karte
local PENDING_GRACE = 30    -- offener Wurf ohne Gewinnerzeile: so lange nach Ablauf der Würfelzeit noch zeigen

local rows = {}       -- [Blizzard-Fenster] = Zählerzeile
local hooked = {}     -- Fenster mit OnShow/OnHide-Hook
local card
local previewing = false  -- Edit-Modus: Karte mit Beispielwürfen
local results = {}       -- abgeschlossene Würfe der letzten WINNER_SECONDS: { roll, at } (LootRolls vergisst sie)
local cardTimed = false   -- Karte zeigt Würfe mit Ablauf: Sekundentakt aktiv

local function setIcon(texture, kind)
  local atlas = LootRolls.ATLASES[kind]
  if atlas and texture.SetAtlas then
    texture:SetAtlas(atlas)
  else
    texture:SetTexture(LootRolls.ICONS[kind] or LootRolls.ICONS.need)
  end
end

-- Symbol als Text (|T...|t bzw. |A...|a) für die Karte
function LootRollDisplay.IconText(kind, size)
  size = size or ICON_SIZE
  local atlas = LootRolls.ATLASES[kind]
  if atlas then return string.format("|A:%s:%d:%d|a", atlas, size, size) end
  local path = LootRolls.ICONS[kind]
  if not path then return "" end
  return string.format("|T%s:%d:%d|t", path, size, size)
end

local function isShownKind(kind, counts)
  return ALWAYS_SHOWN[kind] or counts[kind] > 0
end

-- "|T..|t 2  |T..|t 1 ..." für einen Wurf
function LootRollDisplay.CountsLine(roll)
  local counts = LootRolls.Counts(roll)
  local parts = {}
  for _, kind in ipairs(DISPLAY_KINDS) do
    if isShownKind(kind, counts) then parts[#parts + 1] = LootRollDisplay.IconText(kind) .. " " .. counts[kind] end
  end
  return table.concat(parts, "  ")
end

---------------------------------------------------------------------------
-- Tooltip: Namen je Wahl
---------------------------------------------------------------------------
local function showTooltip(cell)
  local roll = cell.row.roll
  if not (roll and ns.db.lootRollNames) then return end
  local names = LootRolls.NamesOf(roll, cell.kind)
  GameTooltip:SetOwner(cell, "ANCHOR_TOP")
  GameTooltip:SetText(string.format(L.LOOT_ROLL_TOOLTIP_TITLE, ns.LootRollReport.KindLabel(cell.kind), #names),
    Theme.RGB("accent"))
  if #names == 0 then
    GameTooltip:AddLine(L.LOOT_ROLL_NOBODY, Theme.RGB("muted"))
  end
  for _, name in ipairs(names) do
    local text = ns.LootRollReport.ColoredName(roll, name)
    if roll.rolls[name] then text = string.format(L.LOOT_ROLL_NAME_WITH_ROLL, text, roll.rolls[name]) end
    GameTooltip:AddLine(text, 1, 1, 1)
  end
  GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Zählerzeile unter einem Blizzard-Fenster
---------------------------------------------------------------------------
local function createRow(parent)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(ICON_SIZE, ICON_SIZE)
  row:SetPoint("TOP", parent, "BOTTOM", 0, ROW_OFFSET)
  row.cells = {}
  for _, kind in ipairs(DISPLAY_KINDS) do
    local cell = CreateFrame("Frame", nil, row)
    cell:SetSize(ICON_SIZE, ICON_SIZE)
    cell:EnableMouse(true)
    cell.kind, cell.row = kind, row
    cell.icon = cell:CreateTexture(nil, "ARTWORK")
    cell.icon:SetSize(ICON_SIZE, ICON_SIZE)
    cell.icon:SetPoint("LEFT", cell, "LEFT", 0, 0)
    setIcon(cell.icon, kind)
    cell.text = cell:CreateFontString(nil, "OVERLAY", Theme.Font("small"))
    cell.text:SetPoint("LEFT", cell.icon, "RIGHT", ICON_TEXT_GAP, 0)
    cell:SetScript("OnEnter", showTooltip)
    cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.cells[kind] = cell
  end
  row:Hide()
  return row
end

-- Zellen nebeneinander, ausgeblendete fallen heraus; die Zeile wird so breit wie ihr Inhalt (mittig unter dem Fenster)
local function fillRow(row, roll)
  row.roll = roll
  local counts = LootRolls.Counts(roll)
  local x = 0
  for _, kind in ipairs(DISPLAY_KINDS) do
    local cell = row.cells[kind]
    local shown = isShownKind(kind, counts)
    cell:SetShown(shown)
    if shown then
      Widgets.SetTextIfChanged(cell.text, tostring(counts[kind]))
      local width = ICON_SIZE + ICON_TEXT_GAP + (cell.text:GetStringWidth() or 0)
      cell:SetWidth(width)
      cell:ClearAllPoints()
      cell:SetPoint("LEFT", row, "LEFT", x, 0)
      x = x + width + CELL_GAP
    end
  end
  row:SetWidth(math.max(x - CELL_GAP, ICON_SIZE))
  row:Show()
end

local function blizzardFrames()
  local list = {}
  for index = 1, MAX_BLIZZARD_FRAMES do
    local frame = _G["GroupLootFrame" .. index]
    if type(frame) ~= "table" then break end
    list[#list + 1] = frame
  end
  return list
end

local function visible(frame)
  if frame.IsVisible then return frame:IsVisible() and true or false end
  return frame:IsShown() and true or false
end

---------------------------------------------------------------------------
-- Ersatzkarte für Würfe ohne sichtbares Blizzard-Fenster
---------------------------------------------------------------------------
-- Gegenstand mit Symbol; das Symbol steht im Link-Text, damit auch Drüberfahren am Symbol den Item-Tooltip zeigt
function LootRollDisplay.ItemText(roll)
  local icon = roll.texture and ("|T" .. roll.texture .. ":0|t") or ""
  if roll.link then
    local withIcon, found = roll.link:gsub("(|H[^|]+|h)", "%1" .. icon, 1)
    if found > 0 then return withIcon end
    return icon .. roll.link
  end
  return icon .. (roll.name or "?")
end

local function cardLines(list)
  local lines = {}
  for _, roll in ipairs(list) do
    local item = LootRollDisplay.ItemText(roll)
    if roll.completed then
      lines[#lines + 1] = ns.LootRollReport.SummaryText(roll, item)
    else
      lines[#lines + 1] = item .. "\n" .. LootRollDisplay.CountsLine(roll)
    end
  end
  return table.concat(lines, "\n")
end

-- Offener Wurf (ohne sichtbares Blizzard-Fenster) auf der Karte: bis zum Ergebnis, höchstens PENDING_GRACE nach
-- Ablauf der Würfelzeit
function LootRollDisplay.OnCard(roll, now)
  return not roll.completed and now <= roll.startedAt + roll.seconds + PENDING_GRACE
end

-- Beispielwürfe für den Edit-Modus (eigene Tabellen, nicht in LootRolls)
local SAMPLE_PLAYERS = { "A", "B", "C", "D", "E" }
local function sampleRoll(name, kinds)
  local roll = { name = name, choices = {}, order = {}, rolls = {}, classes = {}, groupSize = #SAMPLE_PLAYERS }
  for index, kind in ipairs(kinds) do
    roll.choices[SAMPLE_PLAYERS[index]] = kind
    roll.order[index] = SAMPLE_PLAYERS[index]
  end
  return roll
end

function LootRollDisplay.SampleRolls()
  return {
    sampleRoll(L.LOOT_ROLL_SAMPLE_ITEM_1, { LootRolls.NEED, LootRolls.GREED, LootRolls.PASS }),
    sampleRoll(L.LOOT_ROLL_SAMPLE_ITEM_2, { LootRolls.GREED, LootRolls.GREED, LootRolls.DISENCHANT, LootRolls.PASS }),
  }
end

local function showCard(list)
  if previewing then list = LootRollDisplay.SampleRolls() end
  if #list > 0 then
    -- Symbol des ersten Gegenstands (das Würfelbild fehlt in manchen Clients), sonst die Würfel
    card.Set({ color = { Theme.RGB("accent") }, icon = LootRolls.ICONS.need, texture = list[1].texture,
      title = L.LOOT_ROLL_CARD_TITLE, body = cardLines(list) })
    card.frame:Show()
  else
    card.frame:Hide()
  end
end

---------------------------------------------------------------------------
-- Gesamtstand: Zeilen an den sichtbaren Fenstern, Rest auf der Karte
---------------------------------------------------------------------------
function LootRollDisplay.Refresh()
  if not ns.db then return end
  local enabled = ns.db.lootRollCounts
  local covered = {}
  for _, frame in ipairs(blizzardFrames()) do
    local rollID = frame.rollID
    local roll = enabled and not ns.IsSecret(rollID) and visible(frame) and LootRolls.Get(rollID)
    if roll and not roll.completed then
      rows[frame] = rows[frame] or createRow(frame)
      fillRow(rows[frame], roll)
      covered[roll] = true
    elseif rows[frame] then
      rows[frame].roll = nil
      rows[frame]:Hide()
    end
  end
  local list = {}
  if enabled then
    local now = GetTime()
    for _, roll in ipairs(LootRolls.All()) do
      if not covered[roll] and LootRollDisplay.OnCard(roll, now) then list[#list + 1] = roll end
    end
    for index = #results, 1, -1 do
      if now - results[index].at >= WINNER_SECONDS then table.remove(results, index) end
    end
    for _, result in ipairs(results) do list[#list + 1] = result.roll end
  end
  showCard(list)
  local timed = #list > 0 and not previewing
  if timed ~= cardTimed then
    cardTimed = timed
    ns.RefreshTasks()
  end
end

-- Blizzards Fenster beobachten, sobald die Zähler an sind (einmal je Fenster)
local function hookFrames()
  for _, frame in ipairs(blizzardFrames()) do
    if not hooked[frame] and frame.HookScript then
      hooked[frame] = true
      frame:HookScript("OnShow", LootRollDisplay.Refresh)
      frame:HookScript("OnHide", LootRollDisplay.Refresh)
    end
  end
end

-- Zählerzeile an einem Blizzard-Fenster (nil, solange keine gebraucht wurde); row.cells[Wahl].text = Zahl
function LootRollDisplay.RowOf(frame)
  return rows[frame]
end

card = ns.Card.Create(ns.GlobalName("LootRolls"))
card.frame:SetFrameStrata("DIALOG")
ns.Widgets.EnableItemLinks(card.frame)  -- Item-Links im Text: Tooltip beim Drüberfahren, Shift-Klick
ns.Frames.Register({
  id = "lootRolls", frame = card.frame, label = "EDIT_FRAME_LOOT_ROLLS", default = DEFAULT_POS,
  settingsPage = "COMFORT_PAGE_LOOT", clickable = true, actionsTip = true,
  preview = function(on)
    previewing = on and true or false
    LootRollDisplay.Refresh()
  end,
  hide = function()
    ns.SetBatch(function(db) db.lootRollCounts = false end)
  end,
})

LootRolls.OnChange(function()
  if ns.db.lootRollCounts then LootRollDisplay.Refresh() end
end)

LootRolls.OnComplete(function(roll)
  if not ns.db.lootRollCounts then return end
  table.insert(results, { roll = roll, at = GetTime() })
  LootRollDisplay.Refresh()
end)

-- Ablauf (Ergebnis ausblenden, vergessene Würfe) nur, solange die Karte solche Würfe zeigt
ns.Every(1, LootRollDisplay.Refresh, function() return cardTimed end)

ns.RegisterApply(function(db)
  if db.lootRollCounts then hookFrames() end
  LootRollDisplay.Refresh()
end)

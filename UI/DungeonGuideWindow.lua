-- Fenster des Dungeon Guides (Inhalt aus Assist/DungeonGuide.lua): Kopf mit Instanzname, Blätterzeile (zurück,
-- "Seitentitel  2/6", vor), darunter die Seite mit Bildlauf: je Gegner ein Block aus Porträt (Lib/CreatureModel.lua,
-- live gezeichnete Kreatur im Rahmen, ohne NPC-ID der Totenkopf), Name, Level/besiegt und den Mechanik-Zeilen mit Zaubersymbol
-- (MechanicTips.Lines, Zaubernamen als Links mit Tooltip). Boss-Seiten haben ein großes Porträt, die Trash-Seite ein
-- kleines je Gegner. Fuß: Haken
-- "Nicht mehr automatisch anzeigen" (Einstellung dungeonGuideAuto) und der Verweis auf /lt guide.
-- Position über Lib/Frames.lua (Edit-Modus mit Beispielseite, ziehbar solange nicht gesperrt).
--   DungeonGuideWindow.Show(instanceName, pages, mapID), pages wie DungeonGuide.Pages; unter dem Kopf wählt eine Auswahlliste
--   (ns.Dropdown, mapID vorausgewählt) jeden Dungeon (DungeonGuide.Dungeons, nach Level sortiert)
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Theme = ns.Theme
local CreatureModel = ns.CreatureModel

local DungeonGuideWindow = {}
ns.DungeonGuideWindow = DungeonGuideWindow

local DEFAULT_POSITION = { "TOPLEFT", "TOPLEFT", 40, -180 }
local WIDTH = 440
local HEIGHT = 520
local BANNER_HEIGHT = 96  -- Dungeonbild (Assist/DungeonArt.lua), ohne Bild 0
local PADDING = 12
local TITLE_HEIGHT = 40   -- Fensterkopf (Widgets.CreateWindowHeader)
local NAV_HEIGHT = 26
local PICK_HEIGHT = 24
local NAV_BUTTON_WIDTH = 28
local FOOTER_HEIGHT = 28
local BOSS_PORTRAIT = 96
local TRASH_PORTRAIT = 48
local PORTRAIT_GAP = 16
local PORTRAIT_BORDER = 4  -- Rahmen ragt so weit über das Porträt hinaus
local BLOCK_GAP = 14
local LINE_GAP = 4
local SCROLL_STEP = 40
local BACKGROUND_ALPHA = 0.94
local ICON = "Interface\\Icons\\INV_Misc_ScrollUnrolled01"
local BODY_WIDTH = WIDTH - 2 * PADDING

local pages, pageIndex, instanceName, shownMapID = {}, 1, "", nil
local editing = false

local panel = Widgets.CreatePanel(ns.GlobalName("DungeonGuide"), BACKGROUND_ALPHA)
panel:SetSize(WIDTH, HEIGHT)
panel:Hide()
table.insert(UISpecialFrames, ns.GlobalName("DungeonGuide"))  -- mit ESC schließen
local header = Widgets.CreateWindowHeader(panel, "", { onClose = function() DungeonGuideWindow.Hide() end })
header:SetIcon(ICON)
-- Feste Fensterbreite (Seiteninhalt): lange Instanznamen (fr/es) enden mit "..." vor dem Schließen-Knopf
header.title:SetPoint("RIGHT", header.actions, "LEFT", -PADDING, 0)
header.title:SetJustifyH("LEFT")
header.title:SetWordWrap(false)

-- Dungeonwahl: Knopf mit dem gezeigten Dungeon, Klick öffnet die Auswahlliste
local pick = Widgets.CreateButton(panel, 1, PICK_HEIGHT, function(self)
  local entries = {}
  for _, dungeon in ipairs(ns.DungeonGuide.Dungeons()) do
    local text = dungeon.maxLevel == math.huge and dungeon.name
      or string.format("%s  %s%s|r", dungeon.name, Theme.Hex("note"),
        string.format(L.INSTANCE_LEVELS, dungeon.minLevel, dungeon.maxLevel))
    entries[#entries + 1] = { key = dungeon.mapID, text = text }
  end
  ns.Dropdown.Open(self, { entries = entries, current = shownMapID,
    onPick = function(mapID) ns.DungeonGuide.ShowMap(mapID) end })
end)
pick:SetPoint("TOPLEFT", PADDING, -TITLE_HEIGHT - LINE_GAP)
pick:SetPoint("TOPRIGHT", -PADDING, -TITLE_HEIGHT - LINE_GAP)
Widgets.AttachTooltip(pick, function() return L.DUNGEON_GUIDE_PICK end, function() return L.DUNGEON_GUIDE_PICK_TIP end)

-- Dungeonbild unter der Auswahl; ohne Bild flach (Höhe fast 0), die Seite rückt nach oben
local banner = CreateFrame("Frame", nil, panel)
banner:SetPoint("TOPLEFT", pick, "BOTTOMLEFT", 0, -LINE_GAP)
banner:SetPoint("TOPRIGHT", pick, "BOTTOMRIGHT", 0, -LINE_GAP)
banner.image = banner:CreateTexture(nil, "ARTWORK")
banner.image:SetAllPoints()
local NO_BANNER = 0.001

local function showBanner(mapID)
  local art = ns.DungeonArt.ForMap(mapID, BODY_WIDTH, BANNER_HEIGHT)
  banner:SetHeight(art and BANNER_HEIGHT or NO_BANNER)
  banner.image:SetShown(art ~= nil)
  if art then
    banner.image:SetTexture(art.texture)
    banner.image:SetTexCoord(art.left, art.right, art.top, art.bottom)
  end
  panel:SetHeight(HEIGHT + (art and BANNER_HEIGHT + LINE_GAP or 0))
end

-- Blätterzeile
local nav = CreateFrame("Frame", nil, panel)
nav:SetPoint("TOPLEFT", banner, "BOTTOMLEFT", 0, -LINE_GAP)
nav:SetPoint("TOPRIGHT", banner, "BOTTOMRIGHT", 0, -LINE_GAP)
nav:SetHeight(NAV_HEIGHT)
local function turn(delta)
  DungeonGuideWindow.ShowPage(pageIndex + delta)
end
local prevButton = Widgets.CreateButton(nav, NAV_BUTTON_WIDTH, NAV_HEIGHT, function() turn(-1) end)
prevButton:SetPoint("LEFT")
prevButton:SetText("<")
local nextButton = Widgets.CreateButton(nav, NAV_BUTTON_WIDTH, NAV_HEIGHT, function() turn(1) end)
nextButton:SetPoint("RIGHT")
nextButton:SetText(">")
local pageTitle = nav:CreateFontString(nil, "OVERLAY", Theme.Font("title"))
pageTitle:SetPoint("LEFT", prevButton, "RIGHT", PADDING, 0)
pageTitle:SetPoint("RIGHT", nextButton, "LEFT", -PADDING, 0)
pageTitle:SetWordWrap(false)  -- lange Seitentitel enden mit "..." statt in die Seite umzubrechen
Widgets.AttachTooltip(prevButton, function() return L.DUNGEON_GUIDE_PREV end)
Widgets.AttachTooltip(nextButton, function() return L.DUNGEON_GUIDE_NEXT end)

-- Fuß: automatisch anzeigen aus/an, Verweis auf den Befehl
local hideCheck = Widgets.CreateCheckbox(panel, function(checked) ns.Set("dungeonGuideAuto", not checked) end)
hideCheck:SetPoint("BOTTOMLEFT", PADDING - 4, PADDING - 6)
Widgets.AttachTooltip(hideCheck, function() return L.DUNGEON_GUIDE_DONT_SHOW end,
  function() return L.DUNGEON_GUIDE_DONT_SHOW_TIP end)
local commandNote = panel:CreateFontString(nil, "OVERLAY", Theme.Font("note"))
commandNote:SetPoint("BOTTOMRIGHT", -PADDING, PADDING)
commandNote:SetTextColor(Theme.RGB("note"))
commandNote:SetText("/lt guide")

-- Seite mit Bildlauf
local area = Widgets.CreateScrollArea(panel, { step = SCROLL_STEP, keepInRange = true })
area:SetPoint("TOPLEFT", nav, "BOTTOMLEFT", 0, -PADDING / 2)
area:SetPoint("BOTTOMRIGHT", -PADDING, FOOTER_HEIGHT + PADDING)
local content = CreateFrame("Frame", nil, area)
content:SetSize(BODY_WIDTH, 1)
area:SetScrollChild(content)

local blocks = {}
local function getBlock(index)
  if blocks[index] then return blocks[index] end
  local block = CreateFrame("Frame", nil, content)
  block:SetWidth(BODY_WIDTH)
  block.portrait = CreatureModel.Create(block, TRASH_PORTRAIT)
  block.portrait:SetPoint("TOPLEFT", PORTRAIT_BORDER, -PORTRAIT_BORDER)
  block.frame = CreateFrame("Frame", nil, block, "BackdropTemplate")
  block.frame:SetPoint("TOPLEFT", block.portrait, -PORTRAIT_BORDER, PORTRAIT_BORDER)
  block.frame:SetPoint("BOTTOMRIGHT", block.portrait, PORTRAIT_BORDER, -PORTRAIT_BORDER)
  block.frame:SetBackdrop({ edgeFile = Theme.TOOLTIP_BACKDROP.edgeFile, edgeSize = Theme.TOOLTIP_BACKDROP.edgeSize })
  block.name = block:CreateFontString(nil, "OVERLAY", Theme.Font("heading"))
  block.name:SetJustifyH("LEFT")
  block.detail = block:CreateFontString(nil, "OVERLAY", Theme.Font("bodyLarge"))
  block.detail:SetJustifyH("LEFT")
  block.detail:SetTextColor(Theme.RGB("note"))
  block.text = block:CreateFontString(nil, "OVERLAY", Theme.Font("bodyLarge"))
  block.text:SetJustifyH("LEFT")
  block.text:SetJustifyV("TOP")
  block.text:SetSpacing(LINE_GAP)
  Widgets.EnableItemLinks(block)  -- Zaubernamen in den Mechanik-Zeilen: Tooltip beim Überfahren, Shift-Klick
  blocks[index] = block
  return block
end

-- Text eines Gegners: Mechanik-Zeilen (alle), ohne Mechaniken "keine Infos"; dazu ob eine Zeile unbestätigt ist
local function unitText(unit)
  if not unit.mechanics then return Theme.Hex("muted") .. L.DUNGEON_GUIDE_NO_INFO .. "|r", false end
  local lines, unverified = ns.MechanicTips.Lines(unit.mechanics, nil, true)
  return table.concat(lines, "\n"), unverified
end

local function unitDetail(unit)
  local parts = {}
  if unit.level then parts[#parts + 1] = string.format(L.DUNGEON_GUIDE_LEVEL, unit.level) end
  if unit.killed then parts[#parts + 1] = L.DUNGEON_GUIDE_KILLED end
  return table.concat(parts, "  ·  ")
end

-- Block füllen und seine Höhe zurückgeben
local function fillBlock(block, unit, portraitSize)
  block.portrait:SetSize(portraitSize, portraitSize)
  block.frame:SetBackdropBorderColor(Theme.RGB("border"))  -- hier statt beim Anlegen: folgt dem Theme
  CreatureModel.Set(block.portrait, unit.npcID)
  local framedSize = portraitSize + 2 * PORTRAIT_BORDER
  local textX = framedSize + PORTRAIT_GAP
  local textWidth = BODY_WIDTH - textX
  block.name:ClearAllPoints()
  block.name:SetPoint("TOPLEFT", textX, 0)
  block.name:SetWidth(textWidth)
  block.name:SetText(unit.name or "")
  local detail = unitDetail(unit)
  block.detail:ClearAllPoints()
  block.detail:SetPoint("TOPLEFT", block.name, "BOTTOMLEFT", 0, -LINE_GAP)
  block.detail:SetText(detail)
  block.detail:SetShown(detail ~= "")
  local text, unverified = unitText(unit)
  block.text:ClearAllPoints()
  block.text:SetPoint("TOPLEFT", detail ~= "" and block.detail or block.name, "BOTTOMLEFT", 0, -LINE_GAP)
  block.text:SetWidth(textWidth)
  block.text:SetText(text)
  local textHeight = block.name:GetStringHeight() + LINE_GAP + block.text:GetStringHeight()
  if detail ~= "" then textHeight = textHeight + block.detail:GetStringHeight() + LINE_GAP end
  local height = math.max(framedSize, textHeight)
  block:SetHeight(height)
  block:Show()
  return height, unverified
end

local unverifiedNote = content:CreateFontString(nil, "OVERLAY", Theme.Font("note"))
unverifiedNote:SetJustifyH("LEFT")
unverifiedNote:SetWidth(BODY_WIDTH)
unverifiedNote:SetTextColor(Theme.RGB("muted"))
-- Feste Texte nach dem Login und bei jedem Sprachwechsel (beim Laden gilt noch die Client-Sprache)
ns.RegisterApply(function()
  hideCheck.label:SetText(L.DUNGEON_GUIDE_DONT_SHOW)
  unverifiedNote:SetText(L.FOREVER_UNVERIFIED)
end)

local function layoutPage(page)
  local units = page.units
  local portraitSize = page.trash and TRASH_PORTRAIT or BOSS_PORTRAIT
  local y, anyUnverified = 0, false
  if #units == 0 then units = { { name = page.title } } end  -- Trash ohne Daten: Hinweis "keine Infos"
  for index, unit in ipairs(units) do
    local block = getBlock(index)
    block:ClearAllPoints()
    block:SetPoint("TOPLEFT", 0, -y)
    local height, unverified = fillBlock(block, unit, portraitSize)
    anyUnverified = anyUnverified or unverified
    y = y + height + BLOCK_GAP
  end
  for index = #units + 1, #blocks do blocks[index]:Hide() end
  unverifiedNote:ClearAllPoints()
  unverifiedNote:SetPoint("TOPLEFT", 0, -y)
  unverifiedNote:SetShown(anyUnverified)
  if anyUnverified then y = y + unverifiedNote:GetStringHeight() end
  content:SetHeight(math.max(1, y))
  area:SetVerticalScroll(0)
end

function DungeonGuideWindow.ShowPage(index)
  if #pages == 0 then return end
  pageIndex = math.max(1, math.min(#pages, index))
  local page = pages[pageIndex]
  pageTitle:SetText(string.format("%s  %s", page.title, Theme.Hex("note") .. pageIndex .. "/" .. #pages .. "|r"))
  prevButton:SetEnabled(pageIndex > 1)
  nextButton:SetEnabled(pageIndex < #pages)
  layoutPage(page)
end

-- Erste Seite mit Infos: Trash, wenn es dazu Daten gibt, sonst der erste noch lebende Boss mit Mechaniken
local function startPage()
  for index, page in ipairs(pages) do
    local unit = page.units[1]
    if unit and unit.mechanics and not unit.killed then return index end
  end
  return 1
end

local function hide()
  editing = false
  panel:Hide()
end
DungeonGuideWindow.Hide = hide

function DungeonGuideWindow.Show(name, newPages, mapID)
  pages, instanceName, shownMapID = newPages, name, mapID
  showBanner(mapID)
  pick:SetText(name ~= "" and name or L.DUNGEON_GUIDE_PICK)
  header:SetTitle(name ~= "" and string.format(L.DUNGEON_GUIDE_TITLE_FOR, name) or L.DUNGEON_GUIDE_TITLE)
  hideCheck:SetChecked(not ns.db.dungeonGuideAuto)
  DungeonGuideWindow.ShowPage(startPage())
  panel:Show()
end

function DungeonGuideWindow.IsShown()
  return panel:IsShown()
end

-- Gezeigte Seite und alle Seiten (für Tests)
function DungeonGuideWindow.Current()
  return pageIndex, pages, instanceName, shownMapID
end

-- Edit-Modus: Beispielseite bleibt stehen, bis der Modus endet
local function setEditing(enabled)
  if enabled then
    DungeonGuideWindow.Show(L.EDIT_FRAME_DUNGEON_GUIDE, {
      { title = L.DUNGEON_GUIDE_TRASH, trash = true, units = { { name = L.DUNGEON_GUIDE_SAMPLE_NPC } } },
    })
    editing = true
  elseif editing then
    hide()
  end
end

ns.Frames.Register({
  id = "dungeonGuide", frame = panel, label = "EDIT_FRAME_DUNGEON_GUIDE", default = DEFAULT_POSITION,
  settingsPage = "OPTIONS_PAGE_DUNGEON_GUIDE", preview = setEditing, dragWhenUnlocked = true,
  available = function() return ns.DungeonGuide.IsAvailable() end,
})

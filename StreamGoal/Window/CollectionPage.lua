-- Reiter "Sammlung" im Fenster /sg: alles, was man aufheben, teilen und wieder einlesen kann, an einer Stelle.
--   Pakete: mehrere Ziele auf einmal anlegen (fertige und eigene, Packs.lua). Je Zeile Übernehmen (Hauptaktion,
--     rechts), Teilen und bei eigenen Löschen (Rückfrage); unten "Laufende Ziele als Paket speichern".
--   Vorlagen: einzelne Ziele für Bingo und Glücksrad (Library.lua), als Tabelle; Linksklick legt eines sofort an,
--     Rechtsklick löscht (Rückfrage); unten freier Text hinzufügen.
-- Oben rechts ein einziges "Importieren" für beide (Sharing.lua erkennt, ob der Text ein Paket oder Vorlagen ist),
-- bei den Vorlagen daneben "Vorlagen teilen" (Pakete teilt jede Zeile für sich).
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Packs = ns.Packs
local Library = ns.Library
local Pool = ns.Pool
local Sharing = ns.Sharing
local Manager = ns.Manager
local L = ns.L
local Widgets = LT.Widgets
local Theme = LT.Theme

local CollectionView = {}
ns.CollectionView = CollectionView

local SECTION_TOP = -28          -- unter der Zeile mit den Unterreitern
local SECTION_TAB_GAP = 14
local BOTTOM_HEIGHT = 70          -- Eingabezeile und Hinweis (bis drei Zeilen) unter Liste bzw. Tabelle
local LABEL_INSET = 4             -- Text einer Zeile mittig zu den Knöpfen
local ROW_BUTTON_MIN_WIDTH = 80
local LABEL_BUTTON_GAP = 12
local NAME_BOX_WIDTH = 160
local HINT_GAP = 8
local SECTIONS = {
  { key = "packs", label = "SG_SECTION_PACKS" },
  { key = "own", label = "SG_SECTION_OWN" },
}

local page = Manager.AddPage({
  key = "collection", label = "SG_TAB_COLLECTION", settingsPage = ns.SETTINGS_PAGES.TRACKER,
  render = function() CollectionView.Render() end,
})

local sectionHeight = Manager.PAGE_HEIGHT + SECTION_TOP
local shownSection = SECTIONS[1].key
local sections = {}  -- [key] = { frame, tab }

for _, section in ipairs(SECTIONS) do
  local frame = CreateFrame("Frame", nil, page)
  frame:SetPoint("TOPLEFT", 0, SECTION_TOP)
  frame:SetSize(Manager.PAGE_WIDTH, sectionHeight)
  local tab = Widgets.CreateTab(page, Theme.Font("title"), function() CollectionView.SelectSection(section.key) end)
  Widgets.AttachTooltip(tab, function() return L[section.label] end, function() return L[section.label .. "_TIP"] end)
  sections[section.key] = { frame = frame, tab = tab, label = section.label }
end

function CollectionView.SelectSection(key)
  if not sections[key] then return end
  shownSection = key
  CollectionView.Render()
end

function CollectionView.Section()
  return shownSection
end

-- Ein Import für Pakete und Vorlagen
local importButton = Manager.CreateButton(page, "SG_IMPORT", function()
  Sharing.ShowImport(function() CollectionView.Render() end)
end)
CollectionView.importButton = importButton
local shareOwnButton = Manager.CreateButton(page, "SG_OWN_SHARE", function() Sharing.ShareOwn() end)
CollectionView.shareOwnButton = shareOwnButton

---------------------------------------------------------------------------
-- Pakete
---------------------------------------------------------------------------
local packsFrame = sections.packs.frame
local visibleRows = math.floor((sectionHeight - BOTTOM_HEIGHT) / Manager.ROW)
local packRows = {}
local packOffset = 0
CollectionView.packRows = packRows

local confirmDeletePack = Widgets.ConfirmPopup("STREAMGOAL_DELETE_PACK", "SG_CONFIRM_DELETE_PACK", function(name)
  if Packs.Delete(name) then ns.Print(string.format(L.SG_CHAT_PACK_DELETED, name)) end
  CollectionView.Render()
end)

function CollectionView.ApplyPack(key)
  local created, err = Packs.Apply(key)
  if created > 0 then ns.Print(string.format(L.SG_CHAT_PACK_APPLIED, created, Packs.Label(key))) end
  if err then ns.Print(err) end
end

local function packRow(index)
  if packRows[index] then return packRows[index] end
  local row = {}
  local y = -Manager.ROW * (index - 1)
  row.label = packsFrame:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
  row.label:SetPoint("TOPLEFT", 0, y - LABEL_INSET)
  row.label:SetJustifyH("LEFT")
  row.label:SetWordWrap(false)
  row.apply = Manager.CreateButton(packsFrame, "SG_PACK_APPLY", function()
    if row.key then CollectionView.ApplyPack(row.key) end
  end, ROW_BUTTON_MIN_WIDTH)
  row.share = Manager.CreateButton(packsFrame, "SG_PACK_SHARE", function()
    if row.key then Sharing.SharePack(row.key) end
  end, ROW_BUTTON_MIN_WIDTH)
  row.delete = Manager.CreateButton(packsFrame, "SG_PACK_DELETE", function()
    if row.key and not row.builtin then confirmDeletePack(row.key, row.key) end
  end, ROW_BUTTON_MIN_WIDTH)
  row.y = y
  packRows[index] = row
  return row
end

local function hidePackRow(row)
  row.key = nil
  row.label:Hide()
  row.apply:Hide()
  row.share:Hide()
  row.delete:Hide()
end

-- Zahl der Ziele eines Pakets für die Beschriftung
local function goalCount(entry)
  if entry.builtin then
    for _, pack in ipairs(Packs.BUILTIN) do
      if pack.key == entry.key then return #pack.goals end
    end
  end
  local own = ns.db.packs[entry.key]
  return own and #own.goals or 0
end

-- Viele eigene Pakete: Mausrad blättert
packsFrame:EnableMouseWheel(true)
packsFrame:SetScript("OnMouseWheel", function(_, delta)
  packOffset = Widgets.ClampOffset(packOffset - delta, #Packs.List(), visibleRows)
  CollectionView.Render()
end)

local nameLabel = Manager.CreateLabel(packsFrame)
nameLabel:SetPoint("BOTTOMLEFT", 0, BOTTOM_HEIGHT - Manager.ROW + LABEL_INSET)
local nameBox = Manager.CreateTextBox(packsFrame, function() CollectionView.SavePack() end)
nameBox:SetWidth(NAME_BOX_WIDTH)
CollectionView.nameBox = nameBox

function CollectionView.SavePack()
  local name = strtrim(nameBox:GetText() or "")
  local err = Packs.Save(name)
  if err then
    ns.Print(err)
    return false
  end
  nameBox:SetText("")
  nameBox:ClearFocus()
  ns.Print(string.format(L.SG_CHAT_PACK_SAVED, name))
  CollectionView.Render()
  return true
end

local saveButton = Manager.CreateButton(packsFrame, "SG_PACK_SAVE", function() CollectionView.SavePack() end)
CollectionView.nameLabel, CollectionView.saveButton = nameLabel, saveButton
local packsHint = Manager.CreateHint(packsFrame)
packsHint:SetPoint("TOPLEFT", packsFrame, "BOTTOMLEFT", 0, BOTTOM_HEIGHT - Manager.ROW - HINT_GAP)

local function renderPacks()
  local list = Packs.List()
  packOffset = Widgets.ClampOffset(packOffset, #list, visibleRows)
  for index = 1, math.max(visibleRows, #packRows) do
    local entry = index <= visibleRows and list[packOffset + index]
    if entry then
      local row = packRow(index)
      row.key, row.builtin = entry.key, entry.builtin
      local label = string.format(L.SG_PACK_ROW, Packs.Label(entry.key), goalCount(entry))
      row.label:SetText(entry.builtin and label or (Theme.Hex("accent") .. label .. "|r"))
      Manager.SetLabels({ row.apply, row.share, row.delete })
      local buttons = Manager.AlignRight({ row.apply, row.share, row.delete }, packsFrame, "TOPRIGHT", row.y)
      row.label:SetWidth(Manager.PAGE_WIDTH - buttons - LABEL_BUTTON_GAP)
      row.label:Show()
      row.apply:Show()
      row.share:Show()
      row.delete:SetShown(not entry.builtin)
    elseif packRows[index] then
      hidePackRow(packRows[index])
    end
  end
  nameLabel:SetText(L.SG_PACK_NAME)
  nameBox:ClearAllPoints()
  nameBox:SetPoint("LEFT", nameLabel, "RIGHT", Manager.LABEL_GAP + Manager.BOX_BORDER, 0)
  Manager.SetLabels({ saveButton })
  saveButton:ClearAllPoints()
  saveButton:SetPoint("LEFT", nameBox, "RIGHT", Manager.BUTTON_GAP, 0)
  local hint = L.SG_PACKS_HINT
  if #list > visibleRows then
    hint = hint .. " " .. string.format(L.SG_PACKS_MORE, visibleRows, #list)
  end
  packsHint:SetText(hint)
end

---------------------------------------------------------------------------
-- Vorlagen
---------------------------------------------------------------------------
local ownFrame = sections.own.frame

local confirmRemoveOwn = Widgets.ConfirmPopup("STREAMGOAL_REMOVE_OWN", "SG_CONFIRM_REMOVE_OWN", function(id)
  if Library.Remove(id) then ns.Print(L.SG_CHAT_OWN_REMOVED) end
  CollectionView.Render()
end)

-- Vorlage jetzt als laufendes Ziel anlegen
function CollectionView.Start(item)
  local goal, err = Pool.Create(item)
  ns.Print(goal and string.format(L.SG_CHAT_ADDED, Goals.Title(goal)) or err)
  return goal
end

-- Linksklick: anlegen, Rechtsklick: löschen (Rückfrage; es fehlt dann auch im Bingo-Entwurf und im Rad)
function CollectionView.OnOwnRowClick(item, mouseButton)
  if mouseButton == "RightButton" then
    confirmRemoveOwn(Pool.Title(item), item.ownId)
  else
    CollectionView.Start(item)
  end
end

local ownView = LT.TableView.Create({
  tab = "SG_TAB_COLLECTION",
  columns = {
    { header = "SG_COL_GOAL", width = 340, align = "LEFT", value = function(item) return Pool.Title(item) end },
    { header = "SG_COL_KIND", width = 130, align = "LEFT",
      value = function(item) return L[Goals.GetKind(item.kind).label] end },
    { header = "SG_COL_SAVED", width = 100, align = "LEFT",
      value = function(item) return item.createdAt and date("%Y-%m-%d", item.createdAt) or "" end,
      sort = function(item) return item.createdAt or 0 end },
  },
  records = function() return Pool.OwnItems() end,
  footer = function(_, records) return { string.format(L.SG_OWN_FOOTER, #records, Library.MAX_ENTRIES) } end,
  rowColor = function() return Theme.COLORS.accent end,
  onRowClick = function(item, mouseButton) CollectionView.OnOwnRowClick(item, mouseButton) end,
  hint = "SG_OWN_TABLE_HINT",
})

local ownTableHeight = sectionHeight - BOTTOM_HEIGHT
local ownHolder = CreateFrame("Frame", nil, ownFrame)
ownHolder:SetPoint("TOPLEFT")
ownHolder:SetSize(Manager.PAGE_WIDTH, ownTableHeight)
local ownTable = ownView.Create(ownHolder, Manager.PAGE_WIDTH, ownTableHeight)
CollectionView.ownTable = ownTable

local textLabel = Manager.CreateLabel(ownFrame)
textLabel:SetPoint("BOTTOMLEFT", 0, BOTTOM_HEIGHT - Manager.ROW + LABEL_INSET)
local textBox = Manager.CreateTextBox(ownFrame, function() CollectionView.AddText() end)
CollectionView.textBox = textBox

function CollectionView.AddText()
  local entry, err = Library.AddText(textBox:GetText())
  if not entry then
    ns.Print(err)
    return nil
  end
  textBox:SetText("")
  textBox:ClearFocus()
  ns.Print(string.format(L.SG_CHAT_OWN_SAVED, entry.params.text))
  CollectionView.Render()
  return entry
end

local addTextButton = Manager.CreateButton(ownFrame, "SG_OWN_ADD_TEXT", function() CollectionView.AddText() end)
local ownHint = Manager.CreateHint(ownFrame)
ownHint:SetPoint("TOPLEFT", ownFrame, "BOTTOMLEFT", 0, BOTTOM_HEIGHT - Manager.ROW - HINT_GAP)

local function renderOwn()
  textLabel:SetText(L.SG_OWN_TEXT)
  Manager.SetLabels({ addTextButton })
  local buttons = Manager.AlignRight({ addTextButton }, ownFrame, "BOTTOMRIGHT", BOTTOM_HEIGHT - Manager.ROW)
  Manager.FitBox(textLabel, textBox, buttons)
  ownHint:SetText(L.SG_OWN_HINT)
  ownTable:Render(nil, false, true)
end

---------------------------------------------------------------------------
-- Anzeige
---------------------------------------------------------------------------
function CollectionView.Render()
  if not ns.db then return end
  local left = 0
  for _, section in ipairs(SECTIONS) do
    local entry = sections[section.key]
    entry.tab:SetLabel(L[entry.label])
    entry.tab:SetActive(section.key == shownSection)
    entry.tab:ClearAllPoints()
    entry.tab:SetPoint("TOPLEFT", left, 0)
    left = left + entry.tab:GetWidth() + SECTION_TAB_GAP
    entry.frame:SetShown(section.key == shownSection)
  end
  Manager.SetLabels({ importButton, shareOwnButton })
  Manager.AlignRight({ importButton, shareOwnButton }, page, "TOPRIGHT", 0)
  shareOwnButton:SetShown(shownSection == "own")
  if shownSection == "packs" then renderPacks() else renderOwn() end
end

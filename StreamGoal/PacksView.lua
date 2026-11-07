-- Reiter "Vorlagen" im Fenster /sg (Roadmap 301): je Paket eine Zeile mit Übernehmen, Teilen (Text zum Kopieren) und
-- bei eigenen Paketen Löschen (Rückfrage); darunter Name + "Laufende Ziele speichern" und "Importieren".
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Packs = ns.Packs
local Manager = ns.Manager
local L = ns.L
local Widgets = LT.Widgets
local Theme = LT.Theme

local PacksView = {}
ns.PacksView = PacksView

local ROW = 26
local BUTTON_HEIGHT = 20
local BUTTON_MIN_WIDTH = 80
local BUTTON_GAP = 6
local NAME_BOX_WIDTH = 160
local BOX_BORDER = 6

local page = Manager.AddPage("packs", "SG_TAB_PACKS", function() PacksView.Render() end)

local header = Widgets.CreateSectionHeader(page)
header:SetPoint("TOPLEFT")
header:SetPoint("TOPRIGHT")

local rows = {}

local confirmDelete = Widgets.ConfirmPopup("STREAMGOAL_DELETE_PACK", "SG_CONFIRM_DELETE_PACK", function(name)
  if Packs.Delete(name) then ns.Print(string.format(L.SG_CHAT_PACK_DELETED, name)) end
  PacksView.Render()
end)

function PacksView.Apply(key)
  local created, err = Packs.Apply(key)
  if created > 0 then ns.Print(string.format(L.SG_CHAT_PACK_APPLIED, created, Packs.Label(key))) end
  if err then ns.Print(err) end
end

local function rowAt(index)
  if rows[index] then return rows[index] end
  local row = {}
  local y = -ROW * index
  row.label = page:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
  row.label:SetPoint("TOPLEFT", 0, y - 4)
  row.label:SetJustifyH("LEFT")
  row.delete = Widgets.CreateButton(page, BUTTON_MIN_WIDTH, BUTTON_HEIGHT, function()
    if row.key and not row.builtin then confirmDelete(row.key, row.key) end
  end)
  row.delete:SetPoint("TOPRIGHT", 0, y)
  row.share = Widgets.CreateButton(page, BUTTON_MIN_WIDTH, BUTTON_HEIGHT, function()
    if row.key then LT.Export.Show(Packs.Label(row.key), Packs.Export(row.key)) end
  end)
  row.share:SetPoint("RIGHT", row.delete, "LEFT", -BUTTON_GAP, 0)
  row.apply = Widgets.CreateButton(page, BUTTON_MIN_WIDTH, BUTTON_HEIGHT, function()
    if row.key then PacksView.Apply(row.key) end
  end)
  row.apply:SetPoint("RIGHT", row.share, "LEFT", -BUTTON_GAP, 0)
  rows[index] = row
  return row
end

-- Speichern und Importieren unter der Liste
local nameLabel = page:CreateFontString(nil, "OVERLAY", Theme.Font("title"))
nameLabel:SetJustifyH("LEFT")
local nameBox = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
nameBox:SetSize(NAME_BOX_WIDTH, BUTTON_HEIGHT)
nameBox:SetAutoFocus(false)
nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
PacksView.nameBox = nameBox

local hint = page:CreateFontString(nil, "OVERLAY", Theme.Font("small"))
hint:SetTextColor(Theme.RGB("muted"))
hint:SetJustifyH("LEFT")
hint:SetWidth(Manager.PAGE_WIDTH)

function PacksView.SaveActive()
  local name = strtrim(nameBox:GetText() or "")
  local err = Packs.Save(name)
  if err then
    ns.Print(err)
    return false
  end
  nameBox:SetText("")
  nameBox:ClearFocus()
  ns.Print(string.format(L.SG_CHAT_PACK_SAVED, name))
  PacksView.Render()
  return true
end

local saveButton = Widgets.CreateButton(page, BUTTON_MIN_WIDTH, BUTTON_HEIGHT, function() PacksView.SaveActive() end)
nameBox:SetScript("OnEnterPressed", function() PacksView.SaveActive() end)
local importButton = Widgets.CreateButton(page, BUTTON_MIN_WIDTH, BUTTON_HEIGHT, function()
  LT.Export.ShowImport(L.SG_PACK_IMPORT_TITLE, function(text)
    local name, err = Packs.Import(text)
    PacksView.Render()
    if not name then return err, false end
    return string.format(L.SG_CHAT_PACK_IMPORTED, name), true
  end)
end)

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

function PacksView.Render()
  if not ns.db then return end
  header:SetText(L.SG_PACKS_TITLE)
  local list = Packs.List()
  for index, entry in ipairs(list) do
    local row = rowAt(index)
    row.key, row.builtin = entry.key, entry.builtin
    local label = string.format(L.SG_PACK_ROW, Packs.Label(entry.key), goalCount(entry))
    row.label:SetText(entry.builtin and label or (Theme.Hex("accent") .. label .. "|r"))
    Widgets.SetButtonText(row.apply, L.SG_PACK_APPLY, BUTTON_MIN_WIDTH)
    Widgets.SetButtonText(row.share, L.SG_PACK_SHARE, BUTTON_MIN_WIDTH)
    Widgets.SetButtonText(row.delete, L.SG_PACK_DELETE, BUTTON_MIN_WIDTH)
    row.label:Show()
    row.apply:Show()
    row.share:Show()
    row.delete:SetShown(not entry.builtin)
  end
  for index = #list + 1, #rows do
    local row = rows[index]
    row.key = nil
    row.label:Hide()
    row.apply:Hide()
    row.share:Hide()
    row.delete:Hide()
  end
  local y = -ROW * (#list + 1) - 10
  nameLabel:SetText(L.SG_PACK_NAME)
  nameLabel:ClearAllPoints()
  nameLabel:SetPoint("TOPLEFT", 0, y - 4)
  nameBox:ClearAllPoints()
  nameBox:SetPoint("LEFT", nameLabel, "RIGHT", LT.OptionsBuilder.CHOOSER_TAB_GAP + BOX_BORDER, 0)
  Widgets.SetButtonText(saveButton, L.SG_PACK_SAVE, BUTTON_MIN_WIDTH)
  saveButton:ClearAllPoints()
  saveButton:SetPoint("LEFT", nameBox, "RIGHT", BUTTON_GAP, 0)
  Widgets.SetButtonText(importButton, L.SG_PACK_IMPORT, BUTTON_MIN_WIDTH)
  importButton:ClearAllPoints()
  importButton:SetPoint("TOPRIGHT", 0, y)
  hint:SetText(L.SG_PACKS_HINT)
  hint:ClearAllPoints()
  hint:SetPoint("TOPLEFT", 0, y - ROW - 6)
end

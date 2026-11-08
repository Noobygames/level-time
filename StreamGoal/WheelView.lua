-- Reiter "Glücksrad" im Fenster /sg (Roadmap 431): der Pool des Rads als Tabelle (TableView von Level Time: Filter,
-- Sortieren) mit allen mitgelieferten und eigenen Zielen; Linksklick schaltet einen Eintrag für das Rad an/aus,
-- Rechtsklick auf ein eigenes Ziel löscht es (Rückfrage; es fehlt dann auch im Bingo). Darunter: freien Text als
-- eigenes Ziel hinzufügen, Drehen, eigene Ziele teilen und importieren (Text-Format der Pakete).
local _, ns = ...
local LT = ns.LT
local Pool = ns.Pool
local Library = ns.Library
local Wheel = ns.Wheel
local Manager = ns.Manager
local L = ns.L
local Widgets = LT.Widgets
local Theme = LT.Theme

local WheelView = {}
ns.WheelView = WheelView

local HEADER_HEIGHT = 24
local BOTTOM_HEIGHT = 64        -- Zeilen unter der Tabelle
local ROW = 26
local BOX_HEIGHT = 20
local BOX_BORDER = 6
local BUTTON_MIN_WIDTH = 90
local BUTTON_GAP = 6
local LABEL_GAP = 8

local page = Manager.AddPage("wheel", "SG_TAB_WHEEL", function() WheelView.Render() end)

local header = Widgets.CreateSectionHeader(page)
header:SetPoint("TOPLEFT")
header:SetPoint("TOPRIGHT")

local confirmRemove = Widgets.ConfirmPopup("STREAMGOAL_REMOVE_OWN", "SG_CONFIRM_REMOVE_OWN", function(id)
  if Library.Remove(id) then ns.Print(L.SG_CHAT_OWN_REMOVED) end
  WheelView.Render()
end)

local function sourceText(item)
  return item.premade and L.SG_POOL_PREMADE or L.SG_POOL_OWN
end

-- Linksklick: an/aus, Rechtsklick auf ein eigenes Ziel: löschen
function WheelView.OnRowClick(item, mouseButton)
  if mouseButton == "RightButton" then
    if not item.premade then confirmRemove(Pool.Title(item), item.ownId) end
    return
  end
  Wheel.SetEnabled(item.key, not Wheel.IsEnabled(item.key))
end

local function share()
  local text = Library.Export()
  if not text then
    ns.Print(L.SG_OWN_EMPTY)
    return
  end
  LT.Export.Show(L.SG_OWN_GOALS, text)
end

local function import()
  LT.Export.ShowImport(L.SG_OWN_IMPORT_TITLE, function(text)
    local added, err = Library.Import(text)
    WheelView.Render()
    if not added then return err, false end
    return string.format(L.SG_CHAT_OWN_IMPORTED, added), true
  end)
end

local poolView = LT.TableView.Create({
  tab = "SG_TAB_WHEEL",
  columns = {
    { header = "SG_COL_POOL_ON", width = 60, align = "LEFT",
      value = function(item) return Wheel.IsEnabled(item.key) and L.SG_POOL_ON or L.SG_POOL_OFF end },
    { header = "SG_COL_GOAL", width = 390, align = "LEFT", value = function(item) return Pool.Title(item) end },
    { header = "SG_COL_SOURCE", width = 120, align = "LEFT", value = sourceText },
  },
  records = function() return Pool.Items() end,
  footer = function(_, records)
    local on = 0
    for _, item in ipairs(records) do
      if Wheel.IsEnabled(item.key) then on = on + 1 end
    end
    return { string.format(L.SG_POOL_FOOTER, on, #records) }
  end,
  rowColor = function(item)
    if not Wheel.IsEnabled(item.key) then return Theme.COLORS.muted end
    return item.premade and Theme.COLORS.text or Theme.COLORS.accent
  end,
  onRowClick = function(item, mouseButton) WheelView.OnRowClick(item, mouseButton) end,
  hint = "SG_WHEEL_POOL_HINT",
  buttons = {
    { label = "SG_OWN_SHARE", onClick = share },
    { label = "SG_OWN_IMPORT", onClick = import },
  },
})

local holder = CreateFrame("Frame", nil, page)
holder:SetPoint("TOPLEFT", 0, -HEADER_HEIGHT)
holder:SetSize(Manager.PAGE_WIDTH, Manager.PAGE_HEIGHT - HEADER_HEIGHT - BOTTOM_HEIGHT)
local poolTable = poolView.Create(holder, Manager.PAGE_WIDTH, Manager.PAGE_HEIGHT - HEADER_HEIGHT - BOTTOM_HEIGHT)
WheelView.table = poolTable

-- Freier Text als eigenes Ziel
local textLabel = page:CreateFontString(nil, "OVERLAY", Theme.Font("title"))
textLabel:SetJustifyH("LEFT")
textLabel:SetPoint("BOTTOMLEFT", 0, ROW + 8)
local textBox = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
textBox:SetHeight(BOX_HEIGHT)
textBox:SetAutoFocus(false)
textBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
WheelView.textBox = textBox

function WheelView.AddText()
  local entry, err = Library.AddText(textBox:GetText())
  if not entry then
    ns.Print(err)
    return nil
  end
  textBox:SetText("")
  textBox:ClearFocus()
  ns.Print(string.format(L.SG_CHAT_OWN_SAVED, entry.params.text))
  WheelView.Render()
  return entry
end
textBox:SetScript("OnEnterPressed", function() WheelView.AddText() end)

local addButton = Widgets.CreateButton(page, BUTTON_MIN_WIDTH, BOX_HEIGHT + 2, function() WheelView.AddText() end)
addButton:SetPoint("BOTTOMRIGHT", 0, ROW + 6)
Widgets.AttachTooltip(addButton, function() return L.SG_OWN_ADD_TEXT end, function() return L.SG_OWN_ADD_TEXT_TIP end)

local spinButton = Widgets.CreateButton(page, BUTTON_MIN_WIDTH, BOX_HEIGHT + 2, function() ns.Commands.Wheel("") end)
spinButton:SetPoint("BOTTOMRIGHT", 0, 0)
Widgets.AttachTooltip(spinButton, function() return L.SG_WHEEL_SPIN end, function() return L.SG_WHEEL_SPIN_TIP end)

function WheelView.Render()
  if not ns.db then return end
  header:SetText(L.SG_WHEEL_POOL_TITLE)
  textLabel:SetText(L.SG_OWN_TEXT)
  Widgets.SetButtonText(addButton, L.SG_OWN_ADD_TEXT, BUTTON_MIN_WIDTH)
  Widgets.SetButtonText(spinButton, L.SG_WHEEL_SPIN, BUTTON_MIN_WIDTH)
  local labelWidth = math.ceil(textLabel:GetStringWidth() or 0)
  textBox:ClearAllPoints()
  textBox:SetPoint("LEFT", textLabel, "RIGHT", LABEL_GAP + BOX_BORDER, 0)
  textBox:SetWidth(Manager.PAGE_WIDTH - labelWidth - LABEL_GAP - BOX_BORDER - addButton:GetWidth() - BUTTON_GAP)
  poolTable:Render(nil, false, true)
end

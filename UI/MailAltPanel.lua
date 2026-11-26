-- Seitenfenster "An Twink senden" rechts am Postfenster (nur im Reiter Post versenden, mit mailAssist): je eigener
-- Twink auf demselben Realm eine Zeile mit Klassensymbol, Name in Klassenfarbe und Stufe (Mail.GetKnownAlts); Klick
-- trägt ihn als Empfänger ein, die Zeile des eingetragenen Empfängers ist markiert. Unten bündig am Postfenster,
-- damit andere Addons oben rechts (z.B. Materiallisten) Platz behalten. Das X blendet es bis zum Schließen der Post aus.
-- Öffnet Blizzard rechts daneben ein Fenster (Charakter, Zauberbuch, ...: GetUIPanel center/right), weicht es aus.
local _, ns = ...
local L = ns.L
local Theme = ns.Theme
local Widgets = ns.Widgets

local MailAltPanel = { MAX_ROWS = 12 }
ns.MailAltPanel = MailAltPanel

local PADDING = 12        -- DESIGN.md: Fenster 12 x 16, Listenzeile 32, Symbol 16, Symbol zu Text 12
local HEADER_HEIGHT = 40  -- Widgets.CreateWindowHeader
local ROW_HEIGHT = 32
local ICON_SIZE = 16
local ICON_INSET = 8
local TEXT_GAP = 12
local LEVEL_GAP = 16      -- zwischen Name und Stufe
local MIN_WIDTH = 220
local BACKGROUND_ALPHA = 0.92
local GAP_TO_MAIL = 4

local panel = Widgets.CreatePanel(ns.GlobalName("MailAlts"), BACKGROUND_ALPHA)
panel:Hide()
local closedForSession = false
local header = Widgets.CreateWindowHeader(panel, "", { onClose = function()
  closedForSession = true
  panel:Hide()
end })

local rows = {}
local measure = panel:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
local moreText = panel:CreateFontString(nil, "OVERLAY", Theme.Font("note"))
moreText:SetTextColor(Theme.RGB("note"))

local function getRow(index)
  if rows[index] then return rows[index] end
  local row = Widgets.CreateListRow(panel, ROW_HEIGHT)
  row:SetPoint("TOPLEFT", PADDING, -HEADER_HEIGHT - (index - 1) * ROW_HEIGHT)
  row:SetPoint("RIGHT", -PADDING, 0)
  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetPoint("LEFT", ICON_INSET, 0)
  row.text:ClearAllPoints()
  row.text:SetPoint("LEFT", row.icon, "RIGHT", TEXT_GAP, 0)
  row.level = row:CreateFontString(nil, "OVERLAY", Theme.Font("note"))
  row.level:SetPoint("RIGHT", -ICON_INSET, 0)
  row.level:SetJustifyH("RIGHT")
  row.text:SetPoint("RIGHT", row.level, "LEFT", -LEVEL_GAP, 0)
  row:SetScript("OnClick", function(self)
    ns.Mail.FillRecipient(self.alt.name)
    MailAltPanel.Update()
  end)
  Widgets.AttachTooltip(row, function() return row.alt and row.alt.name end, function() return L.MAIL_ALTS_ROW_TIP end)
  rows[index] = row
  return row
end

local function currentRecipient()
  return SendMailNameEditBox and SendMailNameEditBox:GetText() or ""
end

-- Sichtbar nur im Reiter "Post versenden" mit Twinks; Inhalt jedes Mal frisch (neue Twinks, Sprache, Empfänger)
function MailAltPanel.Update()
  local sendShown = SendMailFrame and SendMailFrame:IsShown()
  local covered = GetUIPanel and (GetUIPanel("center") or GetUIPanel("right"))
  local alts = sendShown and not covered and ns.db and ns.db.mailAssist and not closedForSession
    and ns.Mail.GetKnownAlts() or {}
  if #alts == 0 then
    panel:Hide()
    return
  end
  header:SetTitle(L.MAIL_ALTS_TITLE)
  local recipient = currentRecipient():lower()
  local width = math.max(MIN_WIDTH, header:MinWidth())
  -- shortcut: mehr als MAX_ROWS Twinks auf einem Realm werden abgeschnitten (letzte Zeile nennt den Rest), Bildlauf erst bei Bedarf
  local count = math.min(#alts, MailAltPanel.MAX_ROWS)
  moreText:SetShown(#alts > count)
  moreText:SetText(string.format(L.MAIL_ALTS_MORE, #alts - count))
  for index = 1, count do
    local alt, row = alts[index], getRow(index)
    row.alt = alt
    Widgets.SetClassIcon(row.icon, alt.class, ICON_SIZE)
    row.text:SetText(alt.name)
    row.text:SetTextColor(unpack(Theme.ClassColor(alt.class, { Theme.RGB("text") })))
    row.level:SetText(alt.level and string.format(L.MAIL_ALTS_LEVEL, alt.level) or "")
    row.level:SetTextColor(Theme.RGB("muted"))
    row:SetSelected(alt.name:lower() == recipient)
    measure:SetText(alt.name)
    local nameWidth = measure:GetStringWidth() or 0
    measure:SetText(row.level:GetText())
    width = math.max(width, 2 * PADDING + 2 * ICON_INSET + ICON_SIZE + TEXT_GAP + nameWidth + LEVEL_GAP
      + (measure:GetStringWidth() or 0))
    row:Show()
  end
  for index = count + 1, #rows do rows[index]:Hide() end
  local moreHeight = moreText:IsShown() and ROW_HEIGHT or 0
  moreText:SetPoint("TOPLEFT", PADDING + ICON_INSET, -HEADER_HEIGHT - count * ROW_HEIGHT - 8)
  panel:SetSize(width, HEADER_HEIGHT + count * ROW_HEIGHT + moreHeight + PADDING)
  panel:ClearAllPoints()
  panel:SetPoint("BOTTOMLEFT", MailFrame or SendMailFrame, "BOTTOMRIGHT", GAP_TO_MAIL, 0)
  panel:Show()
end

function MailAltPanel.IsShown() return panel:IsShown() end
function MailAltPanel.Rows() return rows end

-- Neue Post-Sitzung: X gilt nicht mehr
function MailAltPanel.Reset()
  closedForSession = false
  panel:Hide()
end

local hooked = false
-- Reiterwechsel Posteingang / Post versenden und getippter Empfänger (Markierung) halten das Fenster aktuell
function MailAltPanel.Hook()
  if hooked or not SendMailFrame then return end
  hooked = true
  SendMailFrame:HookScript("OnShow", function() ns.SafeCall(MailAltPanel.Update) end)
  SendMailFrame:HookScript("OnHide", function() panel:Hide() end)
  -- Blizzard schiebt Fenster neben die Post (Charakter, Zauberbuch, ...): ausweichen bzw. zurückkommen
  if hooksecurefunc and UpdateUIPanelPositions then
    hooksecurefunc("UpdateUIPanelPositions", function() ns.SafeCall(MailAltPanel.Update) end)
  end
  if SendMailNameEditBox then
    SendMailNameEditBox:HookScript("OnTextChanged", function()
      if panel:IsShown() then ns.SafeCall(MailAltPanel.Update) end
    end)
  end
end

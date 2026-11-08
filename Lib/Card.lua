-- Karte für Hinweise: dunkler Grund, Farbleiste links, Symbol, Titel, Text und auf Wunsch eine große Zahl
-- mit leerlaufendem Balken. Eine Karte zeigt immer einen Inhalt; Größe aus den Texten der Sprache.
--   local card = Card.Create("MeinFrame")
--   card.Set({ color = { r, g, b }, icon = Pfad oder Spell-ID, title = "...", body = "...", time = true })
--   texture = Pfad oder Datei-ID (z.B. Item-Symbol) statt icon; gewinnt, wenn beide gesetzt sind
--   timeText = erster Text der großen Zeile (optional); die Breite reicht für ihn und für eine zweistellige Zahl
--   card.SetTime("42 s"); card.SetFraction(0.7)
-- card.frame ist der Rahmen (Position, Skalierung, Ein-/Ausblenden macht der Aufrufer); card.frame.title,
-- .body und .time sind die Textfelder, .icon das Symbol.
local _, ns = ...

local Card = {}
ns.Card = Card

local ICON_SIZE = 36
local PADDING = 10
local ACCENT_WIDTH = 4
local ICON_GAP = 10
local MIN_WIDTH = 210
local MAX_TEXT_WIDTH = 280      -- längere Texte brechen um
local LINE_GAP = 2
local BAR_HEIGHT = 5
local BAR_GAP = 6
local BAR_BACK_COLOR = { 1, 1, 1, 0.12 }
local BODY_COLOR = { 1, 1, 1 }
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

-- Pfad bleibt, eine Zahl ist eine Spell-ID (Textur aus dem Client); fehlt sie, das Fragezeichen
local function iconTexture(icon)
  if type(icon) == "number" then
    local texture = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(icon)
    if not texture and GetSpellTexture then texture = GetSpellTexture(icon) end  -- ältere Clients
    return texture or FALLBACK_ICON
  end
  return icon
end

function Card.Create(name)
  local card = {}
  local frame = CreateFrame("Frame", name, UIParent)
  frame:SetSize(MIN_WIDTH, ICON_SIZE + 2 * PADDING)
  frame:Hide()
  card.frame = frame

  ns.Theme.RegisterCard(frame)  -- Grund (und im Stil flat ein Rand) aus dem Theme

  local accent = frame:CreateTexture(nil, "BORDER")
  accent:SetColorTexture(1, 1, 1, 1)
  accent:SetPoint("TOPLEFT")
  accent:SetPoint("BOTTOMLEFT")
  accent:SetWidth(ACCENT_WIDTH)

  local icon = frame:CreateTexture(nil, "ARTWORK")
  icon:SetSize(ICON_SIZE, ICON_SIZE)
  icon:SetPoint("TOPLEFT", ACCENT_WIDTH + PADDING, -PADDING)

  local title = frame:CreateFontString(nil, "OVERLAY", ns.Theme.Font("title"))
  title:SetJustifyH("LEFT")
  local body = frame:CreateFontString(nil, "OVERLAY", ns.Theme.Font("body"))
  body:SetJustifyH("LEFT")
  body:SetTextColor(unpack(BODY_COLOR))
  local timeText = frame:CreateFontString(nil, "OVERLAY", ns.Theme.Font("huge"))
  timeText:SetJustifyH("LEFT")
  timeText:SetTextColor(1, 1, 1)
  frame.title, frame.body, frame.time, frame.icon = title, body, timeText, icon

  local barBack = frame:CreateTexture(nil, "ARTWORK")
  barBack:SetColorTexture(unpack(BAR_BACK_COLOR))
  barBack:SetHeight(BAR_HEIGHT)
  barBack:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", ACCENT_WIDTH + PADDING, PADDING - 2)
  barBack:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING, PADDING - 2)
  local barFill = frame:CreateTexture(nil, "ARTWORK", nil, 1)  -- Farbe und Textur setzt card.Set
  barFill:SetHeight(BAR_HEIGHT)
  barFill:SetPoint("TOPLEFT", barBack)

  -- Text in der gewünschten Breite: erst natürliche Breite, dann bei Bedarf umbrechen. Rückgabe: Breite, Höhe
  local function measure(fontString)
    fontString:SetWidth(0)
    local width = fontString:GetStringWidth() or 0
    if width > MAX_TEXT_WIDTH then
      fontString:SetWidth(MAX_TEXT_WIDTH)
      width = MAX_TEXT_WIDTH
    end
    return width, fontString:GetStringHeight() or 0
  end

  local hasIcon, hasBody, hasTime = false, false, false
  local initialTime  -- timeText aus card.Set
  local shownIcon, shownTexture  -- zuletzt gesetztes Symbol (icon bzw. texture aus card.Set)

  local function layout()
    local textLeft = ACCENT_WIDTH + PADDING + (hasIcon and ICON_SIZE + ICON_GAP or 0)
    title:ClearAllPoints()
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", textLeft, -PADDING - (hasIcon and LINE_GAP or 0))
    local titleWidth, titleHeight = measure(title)

    local widest, height = titleWidth, titleHeight
    local last = title
    if hasBody then
      body:ClearAllPoints()
      body:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -LINE_GAP)
      local width, bodyHeight = measure(body)
      widest, height, last = math.max(widest, width), height + LINE_GAP + bodyHeight, body
    end
    if hasTime then
      timeText:ClearAllPoints()
      timeText:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -LINE_GAP)
      ns.Widgets.SetTextIfChanged(timeText, string.format(ns.L.SECONDS_SHORT, 99))  -- breiteste Zahl
      local width, timeHeight = measure(timeText)
      if initialTime then
        -- Längere Zeilen wie "28 / 30  noch 5m 50s" bekommen ihre Breite, statt über den Rand zu laufen
        ns.Widgets.SetTextIfChanged(timeText, initialTime)
        width = math.max(width, (measure(timeText)))
      end
      widest, height = math.max(widest, width), height + LINE_GAP + timeHeight
    end
    frame:SetWidth(math.max(MIN_WIDTH, textLeft + widest + PADDING))
    frame:SetHeight(2 * PADDING + math.max(hasIcon and ICON_SIZE or 0, height) + (hasTime and BAR_GAP + BAR_HEIGHT or 0))
  end

  -- spec = { color, icon (Pfad oder Spell-ID, optional), texture (Pfad oder Datei-ID, optional), title,
  --          body (optional), time (true = Zahl und Balken), timeText (optional) }
  function card.Set(spec)
    local r, g, b = unpack(spec.color)
    accent:SetColorTexture(r, g, b, 1)
    ns.Theme.SetBarTexture(barFill, r, g, b, 1)
    title:SetTextColor(r, g, b)
    hasIcon = spec.texture ~= nil or spec.icon ~= nil
    icon:SetShown(hasIcon)
    -- Gleiches Symbol wie beim letzten Mal: nicht neu auflösen und setzen (Roadmap 401; Level Time Goals baut seine
    -- Karten bei jedem Apply und Fortschritt neu, Quest-Einblendungen kommen in Serien mit demselben Symbol)
    local sameIcon = hasIcon and spec.texture == shownTexture and spec.icon == shownIcon and icon:GetTexture() ~= nil
    shownTexture, shownIcon = spec.texture, spec.icon
    if hasIcon and not sameIcon then
      local texture = spec.texture or iconTexture(spec.icon)
      icon:SetTexture(texture)
      -- Fehlt die Textur im Client, zeigt er ein grünes Quadrat; das Log zeigt, was aufgelöst wurde (Roadmap 237, 244)
      if ns.IsDebugging() then
        ns.Debug("card", "icon %s -> %s, file %s", spec.texture or spec.icon, texture,
          icon.GetTextureFileID and icon:GetTextureFileID())
      end
    end
    title:SetText(spec.title or "")
    hasBody = spec.body ~= nil and spec.body ~= ""
    body:SetShown(hasBody)
    body:SetText(spec.body or "")
    hasTime = spec.time and true or false
    initialTime = hasTime and spec.timeText or nil
    timeText:SetShown(hasTime)
    barBack:SetShown(hasTime)
    barFill:SetShown(hasTime)
    layout()
  end

  function card.SetTime(text)
    ns.Widgets.SetTextIfChanged(timeText, text)
  end

  function card.SetFraction(fraction)
    local width = frame:GetWidth() - ACCENT_WIDTH - 2 * PADDING
    barFill:SetWidth(math.max(1, width * math.max(0, math.min(1, fraction))))
  end

  return card
end

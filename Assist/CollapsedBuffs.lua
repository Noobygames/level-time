-- Gewählte Buffs bei eingeklappter Buffleiste (Roadmap 500): Klappt der Spieler Blizzards Buffleiste ein (Pfeil am
-- BuffFrame), blendet Blizzard alle Buffs mit mehr als einer Minute Restzeit oder ohne Ablauf aus. Diese Anzeige
-- zeigt dann die gewählten Buffs (z.B. Wasser-/Blitzschlagschild, deren Ladungen man im Auge behalten muss) als Symbol
-- mit Stapelzahl und Restzeit.
-- Eingeklappt: BuffFrame:IsExpanded() aus BuffFrameMixin, gleich in Retail, Classic Era und WoW Forever
-- (Gethe/wow-ui-source, Blizzard_BuffFrame/BuffFrame.lua; false auch bei zusammengefassten Buffs, consolidateBuffs).
-- Blizzards Cooldown-Manager (C_CooldownViewer) kann das nicht ersetzen: er verfolgt nur die von Blizzard je
-- Spezialisierung vorgegebenen Fähigkeiten, keine frei gewählte Buff-Liste.
-- Einstellungen: collapsedBuffs (an/aus), collapsedBuffsList (Spell-IDs oder Namen, durch Komma oder Semikolon
-- getrennt; eine ID zählt über ihren Namen in der Client-Sprache, damit alle Ränge passen).
-- Nie verschoben: die Anzeige hängt direkt hinter den sichtbaren Buffs der eingeklappten Leiste (nur angedockt,
-- Blizzards Leiste selbst bleibt unberührt, sonst Taint am Rechtsklick-Abbrechen). Verschoben: eigene Position.
-- Prüfung 500.collapsedBuffs, Proben in LevelTimer_DataExtractor/Debug/DebugChecks.lua.
local _, ns = ...

-- Blitzschlagschild, Wasserschild (TBC, Forever, Retail), Erdschild; Forever kennt Wasserschild nur als 408510
local SHIELD_IDS = "324, 24398, 408510, 52127, 974"
local OLD_SHIELD_IDS = "324, 24398, 52127, 974"  -- alter Standard ohne Forever-ID: gespeicherte Werte nachziehen

ns.RegisterDefaults({
  settings = {
    collapsedBuffs = true,
    collapsedBuffsList = SHIELD_IDS,
  },
})
local Auras = ns.Auras

ns.OnLogin(function()
  if ns.db.collapsedBuffsList == OLD_SHIELD_IDS then ns.db.collapsedBuffsList = SHIELD_IDS end
end)

local CollapsedBuffs = {}
ns.CollapsedBuffs = CollapsedBuffs

CollapsedBuffs.MAX_ICONS = 8
local CHECK_INTERVAL = 0.25
local ICON_SIZE = 30
local ICON_GAP = 4
local TIME_HEIGHT = 12
local SEPARATORS = "[^,;]+"
local PREVIEW_TEXTURE = "Interface\\Icons\\Spell_Nature_LightningShield"
local PREVIEW_COUNT = 3
local PREVIEW_SECONDS = 540

-- true, solange Blizzards Buffleiste eingeklappt ist; nil, wenn der Client keine einklappbare Leiste hat
function CollapsedBuffs.IsBarCollapsed()
  if type(BuffFrame) ~= "table" or type(BuffFrame.IsExpanded) ~= "function" then return nil end
  local ok, expanded = pcall(BuffFrame.IsExpanded, BuffFrame)
  if not ok or ns.IsSecret(expanded) then return nil end
  return not expanded
end

local function spellName(spellId)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellId) end
  return GetSpellInfo and (GetSpellInfo(spellId)) or nil
end

-- Stapeltext, wenn die Zahl geheim ist: Blizzards Formatierung (leer unter 2), SetText nimmt den geheimen Text an
function CollapsedBuffs.DisplayCount(aura)
  local get = C_UnitAuras and C_UnitAuras.GetAuraApplicationDisplayCount
  if not get or not aura.auraInstanceID then return nil end
  local ok, text = pcall(get, "player", aura.auraInstanceID, 2)
  return ok and (ns.IsSecret(text) or type(text) == "string") and text or nil
end

-- Gewählte Buffs aus der Einstellung: Spell-IDs und Namen (klein); neu gelesen nur, wenn sich der Text ändert
local parsedText, ids, names
local function wanted()
  local text = ns.db.collapsedBuffsList or ""
  if text == parsedText then return ids, names end
  parsedText, ids, names = text, {}, {}
  for entry in text:gmatch(SEPARATORS) do
    entry = strtrim(entry)
    local spellId = tonumber(entry)
    local name = spellId and spellName(spellId) or entry
    if spellId then ids[spellId] = true end
    if name and name ~= "" then names[name:lower()] = true end
  end
  return ids, names
end

function CollapsedBuffs.Matches(aura)
  local wantedIds, wantedNames = wanted()
  if aura.spellId and wantedIds[aura.spellId] then return true end
  return type(aura.name) == "string" and wantedNames[aura.name:lower()] == true
end

---------------------------------------------------------------------------
-- Anzeige
---------------------------------------------------------------------------
local frame = CreateFrame("Frame", ns.GlobalName("CollapsedBuffs"), UIParent)
frame:SetSize(ICON_SIZE, ICON_SIZE + TIME_HEIGHT)
frame:SetClampedToScreen(true)
frame:Hide()

local icons = {}
for index = 1, CollapsedBuffs.MAX_ICONS do
  local icon = CreateFrame("Frame", nil, frame)
  icon:SetSize(ICON_SIZE, ICON_SIZE)
  icon:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(index - 1) * (ICON_SIZE + ICON_GAP), 0)
  icon.texture = icon:CreateTexture(nil, "ARTWORK")
  icon.texture:SetAllPoints()
  icon.count = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
  icon.time = icon:CreateFontString(nil, "OVERLAY", ns.Theme.Font("body"))
  icon.time:SetPoint("TOP", icon, "BOTTOM", 0, -1)
  icon:Hide()
  icons[index] = icon
end

-- Ein Symbol füllen: Stapel ab 2 (wie Blizzard), Restzeit nur bei Buffs mit Ablauf
-- count = Zahl oder fertiger (ggf. geheimer) Anzeigetext von Blizzard
local function fill(icon, texture, count, remaining)
  icon.texture:SetTexture(texture)
  if type(count) == "string" then
    icon.count:SetText(count)  -- geheimer Text: nur durchreichen, nie vergleichen
  else
    ns.Widgets.SetTextIfChanged(icon.count, (count and count > 1) and tostring(count) or "")
  end
  local text, r, g, b = "", 1, 1, 1
  if remaining then text, r, g, b = ns.CooldownNumbers.FormatRemaining(remaining) end
  ns.Widgets.SetTextIfChanged(icon.time, text)
  icon.time:SetTextColor(r, g, b)
  icon:Show()
end

local function showCount(shown)
  for index = shown + 1, CollapsedBuffs.MAX_ICONS do icons[index]:Hide() end
  frame:SetShown(shown > 0)
  if shown > 0 then frame:SetWidth(shown * ICON_SIZE + (shown - 1) * ICON_GAP) end
end

-- Letzter sichtbarer Buff der Blizzard-Leiste und die Wuchsrichtung (Standard nach links)
local function lastBlizzardBuff()
  local container = type(BuffFrame) == "table" and BuffFrame.AuraContainer
  if not container or type(BuffFrame.auraFrames) ~= "table" then return nil end
  local last
  for _, button in ipairs(BuffFrame.auraFrames) do
    if button.isAuraAnchor ~= true and button:IsShown() then last = button end
  end
  return last, container, container.addIconsToRight == true
end

-- shortcut: hängt nur hinter den letzten Buff (keine zweite Zeile), reicht für die eingeklappte Leiste
local function dockToBuffBar()
  if ns.Frames.HasPosition("collapsedBuffs") then return end
  local last, container, toRight = lastBlizzardBuff()
  if not container then return end
  local target = last or container
  local _, relativeTo = frame:GetPoint(1)
  if relativeTo == target then return end
  frame:ClearAllPoints()
  if not last then
    frame:SetPoint(toRight and "TOPLEFT" or "TOPRIGHT", container, toRight and "TOPLEFT" or "TOPRIGHT")
  elseif toRight then
    frame:SetPoint("TOPLEFT", last, "TOPRIGHT", ICON_GAP, 0)
  else
    frame:SetPoint("TOPRIGHT", last, "TOPLEFT", -ICON_GAP, 0)
  end
end

local previewing = false

-- Gezeigte Buffs: nur bei eingeklappter Leiste. Ist die Buff-Liste gesperrt (Retail/Forever im Kampf), fragt die
-- Anzeige die gewählten Spell-IDs einzeln ab: Blizzard gibt manche Auren trotzdem frei (C_Secrets). Geheime bleiben
-- weg (nichts zeigen statt alter Stände); Namen ohne Spell-ID gehen dann nicht.
function CollapsedBuffs.Update()
  if previewing then return end
  local shown = 0
  local function show(aura)
    shown = shown + 1
    local count = aura.applications
    if ns.IsSecret(count) or type(count) ~= "number" then count = CollapsedBuffs.DisplayCount(aura) end
    fill(icons[shown], aura.icon, count, (Auras.RemainingSeconds(aura)))
    return shown >= CollapsedBuffs.MAX_ICONS
  end
  if ns.db and ns.db.collapsedBuffs and CollapsedBuffs.IsBarCollapsed() then
    local readable = Auras.ForEachBuff(function(aura)
      if not CollapsedBuffs.Matches(aura) then return false end
      return show(aura)
    end)
    if not readable then
      local wantedIds = wanted()
      for spellId in pairs(wantedIds) do
        local aura = Auras.PlayerAuraBySpellId(spellId)
        if aura and show(aura) then break end
      end
    end
  end
  if shown > 0 then dockToBuffBar() end
  showCount(shown)
end

function CollapsedBuffs.ShownCount()
  local count = 0
  for _, icon in ipairs(icons) do
    if icon:IsShown() then count = count + 1 end
  end
  return frame:IsShown() and count or 0
end

function CollapsedBuffs.Frame()
  return frame
end

-- Stapel- und Zeittext des n-ten Symbols
function CollapsedBuffs.IconTexts(index)
  return icons[index].count:GetText(), icons[index].time:GetText()
end

ns.Frames.Register({
  id = "collapsedBuffs", frame = frame, label = "COLLAPSED_BUFFS",
  default = { "TOPRIGHT", "TOPRIGHT", -220, -110 },
  settingsPage = "COMFORT_PAGE_FRAMES",
  clickable = true, dragWhenUnlocked = true, actionsTip = true,
  preview = function(on)
    previewing = on
    if on then
      fill(icons[1], PREVIEW_TEXTURE, PREVIEW_COUNT, PREVIEW_SECONDS)
      showCount(1)
    else
      CollapsedBuffs.Update()
    end
  end,
  hide = function() ns.Set("collapsedBuffs", false) end,
})

ns.Every(CHECK_INTERVAL, CollapsedBuffs.Update, function(db) return db.collapsedBuffs end)
ns.RegisterApply(function() CollapsedBuffs.Update() end)

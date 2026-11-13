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
-- Prüfung 500.collapsedBuffs, Proben in LevelTimer_DataExtractor/Debug/DebugChecks.lua.
local _, ns = ...

local SHIELD_IDS = "324, 24398, 52127, 974"  -- Blitzschlagschild, Wasserschild (TBC/Forever, Retail), Erdschild

ns.RegisterDefaults({
  settings = {
    collapsedBuffs = true,
    collapsedBuffsList = SHIELD_IDS,
  },
})
local Auras = ns.Auras

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
  icon.time = icon:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  icon.time:SetPoint("TOP", icon, "BOTTOM", 0, -1)
  icon:Hide()
  icons[index] = icon
end

-- Ein Symbol füllen: Stapel ab 2 (wie Blizzard), Restzeit nur bei Buffs mit Ablauf
local function fill(icon, texture, count, remaining)
  icon.texture:SetTexture(texture)
  ns.Widgets.SetTextIfChanged(icon.count, (count and count > 1) and tostring(count) or "")
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

local previewing = false

-- Gezeigte Buffs: nur bei eingeklappter Leiste und lesbaren Auren (gesperrt = nichts zeigen statt alter Stände)
function CollapsedBuffs.Update()
  if previewing then return end
  local shown = 0
  if ns.db and ns.db.collapsedBuffs and CollapsedBuffs.IsBarCollapsed() then
    Auras.ForEachBuff(function(aura)
      if not CollapsedBuffs.Matches(aura) then return false end
      shown = shown + 1
      local count = aura.applications
      if ns.IsSecret(count) or type(count) ~= "number" then count = nil end
      fill(icons[shown], aura.icon, count, (Auras.RemainingSeconds(aura)))
      return shown >= CollapsedBuffs.MAX_ICONS
    end)
  end
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

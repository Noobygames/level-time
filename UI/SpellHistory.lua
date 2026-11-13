-- Zauberleiste für Zuschauer (Roadmap 316): die letzten N gewirkten Zauber als Symbole
-- (UNIT_SPELLCAST_SUCCEEDED auf player, kein Kampflog), mit Chroma-Hintergrund für OBS.
-- Rang (Roadmap 487): Zahl aus C_Spell.GetSpellSubtext (Era, Retail, Forever laut SpellDocumentation; ältere Clients
-- GetSpellSubtext), in Classic "Rang 3". Retail-Untertexte ("Volksfähigkeit", "Passiv") haben keine Zahl: nichts.
local _, ns = ...
local Theme = ns.Theme

ns.Database.RegisterDefaults({
  settings = {
    showSpellHistory = false,
    spellHistoryCount = 5,
    spellHistoryFadeSeconds = 10,
  },
  ranges = {
    spellHistoryCount = { 3, 10 },
    spellHistoryFadeSeconds = { 0, 30 },
  },
})

local SpellHistory = {
  ICON_SIZE = 32,
  GAP = 4,
  PADDING = 4,
}
ns.SpellHistory = SpellHistory

local frame = CreateFrame("Frame", "LevelTimerSpellHistory", UIParent, "BackdropTemplate")
frame:SetSize(SpellHistory.ICON_SIZE * 5 + SpellHistory.GAP * 4 + SpellHistory.PADDING * 2,
  SpellHistory.ICON_SIZE + SpellHistory.PADDING * 2)
frame:Hide()
SpellHistory.frame = frame

local spells = {}
local iconPool = {}
local lastCastGUID = nil
local previewActive = false

local function getTexture(spellID)
  if not spellID or ns.IsSecret(spellID) then return nil end
  if C_Spell and C_Spell.GetSpellTexture then
    local texture = C_Spell.GetSpellTexture(spellID)
    if texture then return texture end
  end
  if GetSpellTexture then
    return GetSpellTexture(spellID)
  end
  return nil
end

local function getRank(spellID)
  local getSubtext = C_Spell and C_Spell.GetSpellSubtext or GetSpellSubtext
  if type(getSubtext) ~= "function" then return nil end
  local ok, subtext = pcall(getSubtext, spellID)
  if not ok or ns.IsSecret(subtext) or type(subtext) ~= "string" then return nil end
  return subtext:match("%d+")
end

local function getIcon(index)
  if not iconPool[index] then
    local icon = CreateFrame("Frame", nil, frame)
    icon:SetSize(SpellHistory.ICON_SIZE, SpellHistory.ICON_SIZE)
    local tex = icon:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon.texture = tex
    local rank = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    rank:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
    icon.rank = rank
    iconPool[index] = icon
  end
  return iconPool[index]
end

local function updateDisplay()
  local count = ns.db and ns.db.spellHistoryCount or 5
  local displayed = {}

  if previewActive then
    for i = 1, count do
      table.insert(displayed, { texture = 134400 }) -- Interface\\Icons\\INV_Misc_QuestionMark
    end
  else
    local maxDisplay = math.min(#spells, count)
    for i = #spells - maxDisplay + 1, #spells do
      table.insert(displayed, spells[i])
    end
  end

  local total = #displayed
  if total == 0 and not previewActive then
    frame:Hide()
    return
  end

  local width = SpellHistory.PADDING * 2 + total * SpellHistory.ICON_SIZE + math.max(0, total - 1) * SpellHistory.GAP
  local height = SpellHistory.ICON_SIZE + SpellHistory.PADDING * 2
  frame:SetSize(math.max(width, SpellHistory.ICON_SIZE + SpellHistory.PADDING * 2), height)

  for i, entry in ipairs(displayed) do
    local icon = getIcon(i)
    icon:ClearAllPoints()
    local x = SpellHistory.PADDING + (i - 1) * (SpellHistory.ICON_SIZE + SpellHistory.GAP)
    icon:SetPoint("LEFT", frame, "LEFT", x, 0)
    icon.texture:SetTexture(entry.texture)
    icon.rank:SetText(entry.rank or "")
    icon:Show()
  end

  for i = total + 1, #iconPool do
    iconPool[i]:Hide()
  end

  if (ns.db and ns.db.showSpellHistory) or previewActive then
    frame:Show()
  end
end

function SpellHistory.Clear()
  spells = {}
  lastCastGUID = nil
  updateDisplay()
end

function SpellHistory.GetSpells()
  local copy = {}
  for i, s in ipairs(spells) do copy[i] = s end
  return copy
end

function SpellHistory.AddSpell(spellID, castGUID)
  if not spellID or ns.IsSecret(spellID) then return end
  if castGUID and castGUID == lastCastGUID then return end
  lastCastGUID = castGUID

  local texture = getTexture(spellID)
  if not texture then return end

  table.insert(spells, { spellID = spellID, texture = texture, rank = getRank(spellID), time = GetTime() })
  local maxSpells = ns.db and ns.db.spellHistoryCount or 5
  while #spells > maxSpells do
    table.remove(spells, 1)
  end
  updateDisplay()
end

local function onSpellcastSucceeded(_, castGUID, spellID)
  if not ns.db or not ns.db.showSpellHistory then return end
  SpellHistory.AddSpell(spellID, castGUID)
end

local events = ns.NewEventGroup()
events.Add("UNIT_SPELLCAST_SUCCEEDED", "player", onSpellcastSucceeded)

local function setPreview(active)
  previewActive = active
  if active then
    updateDisplay()
    frame:Show()
  else
    if not (ns.db and ns.db.showSpellHistory) or #spells == 0 then
      frame:Hide()
    else
      updateDisplay()
    end
  end
end

-- /lt debug check (nach ein paar Zaubern): roher Untertext und gelesener Rang der letzten Zauber
ns.DebugLog.AddCheck("487.spellHistory.rank", function()
  local getSubtext = C_Spell and C_Spell.GetSpellSubtext or GetSpellSubtext
  local list = {}
  for _, entry in ipairs(spells) do
    local ok, subtext = pcall(getSubtext, entry.spellID)
    table.insert(list, { spellID = entry.spellID, subtext = ok and not ns.IsSecret(subtext) and subtext or nil,
      rank = entry.rank })
  end
  return { hasSubtext = type(getSubtext) == "function", spells = list }
end)

ns.Frames.Register({
  id = "spellHistory",
  frame = frame,
  label = "EDIT_FRAME_SPELL_HISTORY",
  settingsPage = "OPTIONS_TAB_STREAM",
  default = { "BOTTOM", "BOTTOM", 0, 180 },
  preview = setPreview,
})

-- Verblassen / Entfernen alter Zauber
local sinceTick = 0
ns.SetUpdateScript(frame, "SpellHistory", function(_, elapsed)
  sinceTick = sinceTick + elapsed
  if sinceTick < 0.2 then return end
  sinceTick = 0

  local fadeSec = ns.db and ns.db.spellHistoryFadeSeconds or 10
  if fadeSec > 0 and #spells > 0 and not previewActive then
    local now = GetTime()
    local changed = false
    while #spells > 0 and (now - spells[1].time) >= fadeSec do
      table.remove(spells, 1)
      changed = true
    end
    if changed then
      updateDisplay()
    end
  end
end)

ns.RegisterApply(function(db)
  events.SetActive(db.showSpellHistory == true)
  Theme.ApplyBackground(frame, db)
  if db.showSpellHistory or previewActive then
    updateDisplay()
  else
    frame:Hide()
  end
end)

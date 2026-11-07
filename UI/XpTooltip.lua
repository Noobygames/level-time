-- Tooltip des XP-Balkens (alle Layouts mit Balken): genaue XP, Rest bis zum Level-Up, Erholungs-XP absolut und als
-- Anteil am Level, wie viel vom Rest die Erholung abdeckt, dazu die XP der abgabebereiten Quests (QuestLogXp.lua).
-- Aktualisiert wird nur, solange die Maus darauf steht, und nur bei PLAYER_XP_UPDATE/UPDATE_EXHAUSTION.
local _, ns = ...
local L = ns.L
local Format = ns.Format

local XpTooltip = {}
ns.XpTooltip = XpTooltip

local MUTED = { 0.8, 0.8, 0.8 }

local function readable(...)
  for index = 1, select("#", ...) do
    local value = select(index, ...)
    if ns.IsSecret(value) then return false end
  end
  return true
end

-- Zeilen des Tooltips: { title, lines = { Text, ... } }; nil, wenn die Werte geheim sind
function XpTooltip.Build()
  local title = string.format(L.XP_TOOLTIP_TITLE, ns.level or UnitLevel("player"))
  if not ns.Experience.IsLeveling() then return { title = title, lines = { L.XP_TOOLTIP_MAX_LEVEL } } end
  local xp, xpMax, rested = UnitXP("player"), UnitXPMax("player"), GetXPExhaustion()
  if not readable(xp, xpMax, rested) or xpMax <= 0 then return nil end

  local missing = math.max(0, xpMax - xp)
  local lines = {
    string.format(L.XP_TOOLTIP_PROGRESS, Format.Integer(xp), Format.Integer(xpMax), Format.PercentPrecise(xp, xpMax)),
    string.format(L.XP_TOOLTIP_MISSING, Format.Integer(missing)),
  }
  if rested and rested > 0 then
    table.insert(lines, string.format(L.XP_TOOLTIP_RESTED, Format.Integer(rested), Format.PercentPrecise(rested, xpMax)))
    table.insert(lines, string.format(L.XP_TOOLTIP_RESTED_COVERS,
      Format.PercentPrecise(math.min(rested, missing), missing)))
  else
    table.insert(lines, L.XP_TOOLTIP_NO_RESTED)
  end
  local ready = ns.QuestLogXp.Get()
  if ready and ready > 0 then
    table.insert(lines, string.format(L.XP_TOOLTIP_QUESTS, Format.Integer(ready), Format.PercentPrecise(ready, xpMax)))
  end
  return { title = title, lines = lines }
end

local owner  -- Frame, über dem der Tooltip gerade steht

local function show()
  local content = owner and XpTooltip.Build()
  if not content then
    GameTooltip:Hide()
    return
  end
  GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM")
  GameTooltip:SetText(content.title, ns.Theme.RGB("accent"))
  for _, line in ipairs(content.lines) do GameTooltip:AddLine(line, MUTED[1], MUTED[2], MUTED[3]) end
  GameTooltip:Show()
end

-- Nur angemeldet, solange der Tooltip offen ist
local events = ns.NewEventGroup()
events.Add("PLAYER_XP_UPDATE", nil, show)
events.Add("UPDATE_EXHAUSTION", nil, show)

-- Tooltip über frame (Mausfläche über dem Balken) anzeigen
function XpTooltip.Attach(frame)
  frame:HookScript("OnEnter", function(self)
    owner = self
    events.SetActive(true)
    show()
  end)
  frame:HookScript("OnLeave", function()
    owner = nil
    events.SetActive(false)
    GameTooltip:Hide()
  end)
end

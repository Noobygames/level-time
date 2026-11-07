-- Questzeilen aus dem Einheiten-Tooltip (Roadmap 340): zu welcher Quest gehört ein Gegner und wie ist der Stand?
-- Quellen:
--   Retail/Forever  C_TooltipInfo.GetUnit(unit).lines (TooltipInfoDocumentation, Zweige live/forever); Zeilentypen
--                   Enum.TooltipDataLineType.QuestTitle (17), QuestObjective (8), QuestPlayer (18)
--                   (TooltipInfoSharedDocumentation). Felder leftText und completed sind nicht dokumentiert, Blizzards
--                   TooltipDataRules.QuestObjective liest lineData.completed; per /lt debug check prüfen.
--   Classic Era/TBC kein C_TooltipInfo: versteckter GameTooltip mit SetUnit, Zeilen mit "3/8" gelten als Ziele, die
--                   Zeile davor ohne Zähler als Questtitel. Ob Era Questzeilen im Einheiten-Tooltip zeigt, ist ungeprüft.
-- Geheime Zeilen (Retail/Forever im Kampf, in Instanzen) werden übersprungen. Ergebnis je Name zwischengespeichert,
-- verworfen bei jeder Änderung des Questlogs (QUEST_LOG_UPDATE, UNIT_QUEST_LOG_CHANGED für den Spieler).
local _, ns = ...

local QuestTooltip = {}
ns.QuestTooltip = QuestTooltip

local SCAN_TOOLTIP = "LevelTimerQuestScanTooltip"

local cache = {}  -- [Name] = Liste der Ziele (leer = keine Questzeilen)

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function counts(text)
  if type(text) ~= "string" then return nil, nil end
  local have, need = text:match("(%d+)%s*/%s*(%d+)")
  return tonumber(have), tonumber(need)
end

-- Ziel aus einer Zeile: { title, text, have, need, done }
local function objective(title, text, completed)
  local have, need = counts(text)
  local done = completed
  if done == nil and have and need then done = have >= need end
  return { title = title, text = text, have = have, need = need, done = done == true }
end

function QuestTooltip.HasTooltipInfo()
  return C_TooltipInfo ~= nil and type(C_TooltipInfo.GetUnit) == "function"
    and Enum ~= nil and Enum.TooltipDataLineType ~= nil and Enum.TooltipDataLineType.QuestObjective ~= nil
end

-- Retail/Forever: Zeilen nach Typ
local function fromTooltipInfo(unit)
  local ok, data = pcall(C_TooltipInfo.GetUnit, unit)
  if not ok or ns.IsSecret(data) or type(data) ~= "table" or type(data.lines) ~= "table" then return {} end
  local types = Enum.TooltipDataLineType
  local list, title = {}, nil
  for _, line in ipairs(data.lines) do
    local lineType, text = readable(line.type), readable(line.leftText)
    if lineType == types.QuestTitle then
      title = text
    elseif lineType == types.QuestObjective and type(text) == "string" then
      table.insert(list, objective(title, text, readable(line.completed)))
    end
  end
  return list
end

local scanner

-- Classic: versteckter Tooltip; Zeilen mit Zähler sind Ziele, die letzte Zeile ohne Zähler davor der Titel
local function fromScanTooltip(unit)
  if not scanner then
    scanner = CreateFrame("GameTooltip", SCAN_TOOLTIP, UIParent, "GameTooltipTemplate")
  end
  scanner:SetOwner(UIParent, "ANCHOR_NONE")
  scanner:SetUnit(unit)
  local list, title = {}, nil
  local lines = scanner.NumLines and scanner:NumLines() or 0
  for index = 2, lines do  -- Zeile 1 ist der Name
    local fontString = _G[SCAN_TOOLTIP .. "TextLeft" .. index]
    local text = fontString and readable(fontString:GetText())
    if type(text) == "string" then
      if counts(text) then
        table.insert(list, objective(title, (text:gsub("^%s*%-%s*", ""))))
      else
        title = text
      end
    end
  end
  scanner:Hide()
  return list
end

-- Ziele, die der Tooltip der Einheit nennt; leer ohne Questzeilen oder bei geheimem Namen
function QuestTooltip.Objectives(unit)
  local name = readable(UnitName(unit))
  if type(name) ~= "string" then return {} end
  local cached = cache[name]
  if cached then return cached end
  local list = QuestTooltip.HasTooltipInfo() and fromTooltipInfo(unit) or fromScanTooltip(unit)
  cache[name] = list
  return list
end

-- Kurzer Stand für das Symbol: erstes offenes Ziel mit Zähler ("3/8"), sonst nil
function QuestTooltip.ProgressText(unit)
  for _, entry in ipairs(QuestTooltip.Objectives(unit)) do
    if not entry.done and entry.have and entry.need then
      return entry.have .. "/" .. entry.need, entry
    end
  end
  return nil
end

function QuestTooltip.Forget()
  cache = {}
end

ns.RegisterEvent("QUEST_LOG_UPDATE", QuestTooltip.Forget)
ns.RegisterUnitEvent("UNIT_QUEST_LOG_CHANGED", "player", QuestTooltip.Forget)

-- /lt debug check (vor einem Questgegner mit Ziel): rohe Tooltipzeilen (Typ, Text, completed) und die Deutung
ns.DebugLog.AddCheck("quests.unitTooltip", function()
  local unit = "target"
  local info = { hasTooltipInfo = QuestTooltip.HasTooltipInfo(), name = readable(UnitName(unit)), lines = {} }
  if info.hasTooltipInfo then
    local ok, data = pcall(C_TooltipInfo.GetUnit, unit)
    if ok and type(data) == "table" and type(data.lines) == "table" then
      for _, line in ipairs(data.lines) do
        table.insert(info.lines, { type = readable(line.type), text = readable(line.leftText),
          completed = readable(line.completed) })
      end
    end
  end
  QuestTooltip.Forget()
  info.parsed = QuestTooltip.Objectives(unit)
  info.progress = QuestTooltip.ProgressText(unit)
  return info
end)

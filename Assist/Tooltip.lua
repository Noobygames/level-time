-- Einheiten-Tooltip anpassen (Reiter Komfort, Fenster; je Einstellung, Standard aus):
--   tooltipClassColors   Name von Spielern in Klassenfarbe (erste Zeile, GameTooltipTextLeft1).
--   tooltipTarget        Zusatzzeile mit dem Ziel der Einheit ("Ziel: Name", Spieler in Klassenfarbe, du selbst
--                        als "Du").
--   tooltipHideInCombat  Einheiten-Tooltips im Kampf nicht zeigen; Umschalt gedrückt zeigt sie trotzdem.
--   tooltipKillsToLevel  Zeile "Kills bis Level-Up: 12" an angreifbaren Gegnern (MobXp.lua, Roadmap 274), gefärbt nach
--                        Stufenabstand wie Blizzards Gegnerfarben (GetCreatureDifficultyColor, alle Clients), "~" =
--                        nach der Formel geschätzt.
-- Anschluss: TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit) in allen Clients mit dem Tooltip-
-- Datensystem (Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua: Post-Calls laufen vor tooltip:Show(), auch in
-- Classic Era); sonst OnTooltipSetUnit. Verstecken im Kampf über HookScript("OnShow"), weil der Post-Call vor
-- Blizzards Show läuft. Geheime Werte (Forever/Retail im Kampf und in Instanzen) werden übergangen.
local _, ns = ...
local L = ns.L

local Tooltip = {}
ns.Tooltip = Tooltip

local TARGET_SUFFIX = "target"
local NEUTRAL_COLOR = { 1, 1, 1 }
local QUEST_COLOR = { 1, 0.82, 0 }

local function readable(...)
  for index = 1, select("#", ...) do
    if ns.IsSecret((select(index, ...))) then return false end
  end
  return true
end

-- Einheit des Tooltips, nil bei geheimen Werten oder ohne Einheit
local function unitOf(tooltip)
  local _, unit = tooltip:GetUnit()
  if not readable(unit) or type(unit) ~= "string" then return nil end
  return unit
end

local function classColor(unit)
  return ns.ClassColors.ForUnit(unit)
end

-- Text der Zielzeile, nil ohne Ziel
function Tooltip.TargetLine(unit)
  local target = unit .. TARGET_SUFFIX
  local exists = UnitExists(target)
  if not readable(exists) or not exists then return nil end
  local isSelf = UnitIsUnit(target, "player")
  if not readable(isSelf) then return nil end
  if isSelf then return string.format(L.TOOLTIP_TARGET, L.TOOLTIP_TARGET_YOU), NEUTRAL_COLOR end
  local name = UnitName(target)
  if not readable(name) or not name then return nil end
  local color = classColor(target)
  return string.format(L.TOOLTIP_TARGET, name), color and { color.r, color.g, color.b } or NEUTRAL_COLOR
end

-- Text und Farbe der Kills-Zeile, nil ohne Wert
function Tooltip.KillsLine(unit)
  local count, estimated, mobLevel = ns.MobXp.KillsToLevel(unit)
  if not count then return nil end
  local color = NEUTRAL_COLOR
  if mobLevel and GetCreatureDifficultyColor then
    local difficulty = GetCreatureDifficultyColor(mobLevel)
    if type(difficulty) == "table" and difficulty.r then color = { difficulty.r, difficulty.g, difficulty.b } end
  end
  local value = (estimated and "~" or "") .. ns.Format.Number(count)
  return string.format(L.TOOLTIP_KILLS_TO_LEVEL, value), color
end

local function onUnitTooltip(tooltip)
  if tooltip ~= GameTooltip or not ns.db then return end
  local unit = unitOf(tooltip)
  if not unit then return end
  if ns.db.tooltipClassColors then
    local color = classColor(unit)
    if color and GameTooltipTextLeft1 then GameTooltipTextLeft1:SetTextColor(color.r, color.g, color.b) end
  end
  if ns.db.tooltipTarget then
    local text, color = Tooltip.TargetLine(unit)
    if text then tooltip:AddLine(text, unpack(color)) end
  end
  -- Spieler bekommen keine Kills-Zeile: gar nicht erst rechnen und loggen (Roadmap 381)
  local isPlayer = UnitIsPlayer(unit)
  if ns.db.tooltipKillsToLevel and not (readable(isPlayer) and isPlayer) then
    local text, color = Tooltip.KillsLine(unit)
    if text then tooltip:AddLine(text, unpack(color)) end
    if ns.IsDebugging() then
      local name = UnitName(unit)
      ns.Debug("tooltip", "kills line for %s (level %s): %s", name, UnitLevel(unit), text)
    end
  end
  if ns.db.questLearning then
    local text = Tooltip.LearnedQuestLine(unit)
    if text then tooltip:AddLine(text, unpack(QUEST_COLOR)) end
  end
end

-- Gelernte Questzuordnung (QuestMobs.lua) für Ziel und Mouseover, nur wo der Client selbst keine Questzeilen
-- in den Einheiten-Tooltip schreibt (ohne C_TooltipInfo, also Classic Era/TBC): "Quest: Wölfe jagen (3/8)"
function Tooltip.LearnedQuestLine(unit)
  if ns.QuestTooltip.HasTooltipInfo() then return nil end
  local name = UnitName(unit)
  if not readable(name) then return nil end
  local progress, hit = ns.QuestMobs.ProgressOf(name)
  if not hit then return nil end
  local title = hit.title or ""
  return string.format(L.TOOLTIP_QUEST_LINE, progress and string.format("%s (%s)", title, progress) or title)
end

-- Im Kampf ausblenden: nur Einheiten-Tooltips (auch geheime Einheiten zählen als Einheit)
function Tooltip.ShouldHide(tooltip)
  if not ns.db.tooltipHideInCombat or IsShiftKeyDown() then return false end
  local inCombat = UnitAffectingCombat("player")
  if not readable(inCombat) or not inCombat then return false end
  local _, unit = tooltip:GetUnit()
  return ns.IsSecret(unit) or unit ~= nil
end

local hooked = false

local function hook()
  if hooked or not GameTooltip then return end
  hooked = true
  local unitType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and unitType then
    TooltipDataProcessor.AddTooltipPostCall(unitType, onUnitTooltip)
  else
    GameTooltip:HookScript("OnTooltipSetUnit", function(self)
      onUnitTooltip(self)
      self:Show()  -- Größe nach neuen Zeilen anpassen
    end)
  end
  GameTooltip:HookScript("OnShow", function(self)
    if Tooltip.ShouldHide(self) then self:Hide() end
  end)
end

ns.RegisterApply(function(db)
  if db.tooltipClassColors or db.tooltipTarget or db.tooltipHideInCombat or db.tooltipKillsToLevel
    or db.questLearning then hook() end
end)

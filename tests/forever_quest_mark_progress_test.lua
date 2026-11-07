-- Zielstand am Quest-Symbol (Roadmap 340): "3/8" aus den Questzeilen des Einheiten-Tooltips (C_TooltipInfo),
-- je Name zwischengespeichert und erst nach einer Questlog-Änderung neu gelesen.
local QuestTooltip = addon.QuestTooltip

local plates = { nameplate1 = CreateFrame("Frame"), nameplate2 = CreateFrame("Frame") }
C_NamePlate = { GetNamePlateForUnit = function(unit) return plates[unit] end }
C_QuestLog.UnitIsRelatedToActiveQuest = function(unit) return wow.state.units[unit] ~= nil end
Enum = Enum or {}
Enum.TooltipDataLineType = { QuestObjective = 8, QuestTitle = 17, QuestPlayer = 18 }
local tooltipLines = {
  { type = 0, leftText = "Wolf" },
  { type = 17, leftText = "Wölfe jagen" },
  { type = 8, leftText = " - 8/8 Wolfspelz", completed = true },
  { type = 8, leftText = " - 3/8 Wolf getötet", completed = false },
}
local reads = { count = 0 }
C_TooltipInfo = { GetUnit = function()
  reads.count = reads.count + 1
  return { lines = tooltipLines }
end }
wow.state.units.nameplate1 = { name = "Wolf" }
wow.state.units.nameplate2 = { name = "Wolf" }

-- Marken sind Kinder der Plakette
local created = {}
local realCreate = CreateFrame
CreateFrame = function(kind, name, parent)
  local frame = realCreate(kind, name, parent)
  if parent == plates.nameplate1 or parent == plates.nameplate2 then created[parent] = frame end
  return frame
end

wow.login({ level = 10 })
expectTrue("Tooltip-Daten verfügbar", QuestTooltip.HasTooltipInfo())
local objectives = QuestTooltip.Objectives("nameplate1")
expect("zwei Ziele", #objectives, 2)
expect("Titel", objectives[2].title, "Wölfe jagen")
expect("Stand", QuestTooltip.ProgressText("nameplate1"), "3/8")

addon.Set("questMarks", true)
addon.Set("questMarkProgress", true)
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
local mark = created[plates.nameplate1]
expect("Zähler am Symbol", mark.progress:GetText(), "3/8")
expect("zweite Plakette gleicher Name", created[plates.nameplate2].progress:GetText(), "3/8")
local before = reads.count
wow.update(1)
expect("ohne Änderung kein neues Lesen", reads.count, before)

-- Fortschritt: erst nach QUEST_LOG_UPDATE neu gelesen
tooltipLines[4].leftText = " - 4/8 Wolf getötet"
wow.update(1)
expect("ohne Ereignis alter Stand", mark.progress:GetText(), "3/8")
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)
expect("nach Questlog-Änderung", mark.progress:GetText(), "4/8")
expect("je Name einmal gelesen", reads.count, before + 1)

-- Geheime Zeilen: kein Zähler, kein Fehler
tooltipLines[4].leftText = wow.SECRET
wow.fire("UNIT_QUEST_LOG_CHANGED", "player")
wow.update(1)
expect("geheim: kein Zähler", mark.progress:GetText(), "")

-- Aus: kein Zähler
tooltipLines[4].leftText = " - 5/8 Wolf getötet"
addon.Set("questMarkProgress", false)
expect("aus", mark.progress:GetText(), "")
expect("Fehler?", #wow.errors, 0)

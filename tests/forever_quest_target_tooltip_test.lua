-- Zielknopf in WoW Forever: Gegner, von denen man nur etwas looten muss, meldet UnitIsRelatedToActiveQuest nicht als
-- Questgegner; das offene Ziel steht aber im Tooltip (Debug-Log 2026-11-08: Elementarsklave mit
-- "Armschienen der Erdbindung: 0/4", questRelated false). Solche Gegner landen trotzdem im Zielknopf.
local target = LevelTimerQuestTargetButton

Enum = Enum or {}
Enum.TooltipDataLineType = { QuestObjective = 8, QuestTitle = 17, QuestPlayer = 18 }
local TOOLTIPS = {
  Elementarsklave = { { type = 17, leftText = "Armschienen der Bindung" },
    { type = 8, leftText = "Armschienen der Erdbindung: 0/4", completed = false } },
  Erdgeist = { { type = 17, leftText = "Armschienen der Bindung" },
    { type = 8, leftText = "Armschienen der Erdbindung: 4/4", completed = true } },
}
C_TooltipInfo = { GetUnit = function(unit)
  local data = wow.state.units[unit]
  return { lines = data and TOOLTIPS[data.name] or {} }
end }
C_NamePlate = { GetNamePlateForUnit = function() return nil end }
C_QuestLog.UnitIsRelatedToActiveQuest = function(unit) return wow.state.units[unit].quest == true end

wow.state.questLog = { { title = "Arathihochland", isHeader = true }, { title = "Armschienen der Bindung", questID = 80 } }
wow.login({ level = 32 })
wow.state.units.nameplate1 = { name = "Elementarsklave", quest = false }
wow.state.units.nameplate2 = { name = "Erdgeist", quest = false }
wow.state.units.nameplate3 = { name = "Wolf", quest = false }
for index = 1, 3 do wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate" .. index) end
addon.Set("questTargetButton", true)
wow.update(1)
expect("offenes Ziel im Tooltip: im Makro", target:GetAttribute("macrotext"), "/cleartarget\n/targetexact Elementarsklave")
expectTrue("Zielknopf sichtbar", target:IsShown())

-- Ziel erfüllt (5/5), der Tooltip hinkt aber nach und meldet noch 0/4: der Questlog gewinnt, Gegner fällt heraus
wow.state.questLog[2].objectives = { { text = "Armschienen der Erdbindung: 4/4", finished = true } }
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)
expectTrue("erfülltes Ziel laut Questlog: kein Zielknopf", not target:IsShown())
wow.state.questLog[2].objectives = { { text = "Armschienen der Erdbindung: 3/4", finished = false } }
wow.fire("QUEST_LOG_UPDATE")
wow.update(1)
expect("wieder offen: im Makro", target:GetAttribute("macrotext"), "/cleartarget\n/targetexact Elementarsklave")
expect("keine Lua-Fehler", #wow.errors, 0)

-- "x-mal getötet" im Tooltip von Gegnern (Roadmap 499): Zählung je Name aus dem Kill-Journal, neue Kills zählen sofort.
local postCalls = {}
Enum = Enum or {}
Enum.TooltipDataType = { Unit = 2 }
TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) postCalls[kind] = fn end }
local tooltipUnit
function GameTooltip:GetUnit() return tooltipUnit and "Name", tooltipUnit end
local tooltipLines = {}
function GameTooltip:AddLine(text) table.insert(tooltipLines, text) end
local function showTooltip(unit)
  tooltipUnit, tooltipLines = unit, {}
  postCalls[Enum.TooltipDataType.Unit](GameTooltip)
end

local function killWolf()
  wow.fire("CHAT_MSG_COMBAT_XP_GAIN", string.format(COMBATLOG_XPGAIN_EXHAUSTION1, "Wolf", 150, "+50", "Erholung"))
end

wow.login({ level = 10, xp = 0, xpMax = 1000 })
addon.Set("tooltipKillCount", true)
wow.state.units.mouseover = { name = "Wolf", level = 10, hostile = true }

showTooltip("mouseover")
expect("ohne Kill keine Zeile", #tooltipLines, 0)

-- Zählung wird beim ersten Tooltip aufgebaut und danach mit jedem Kill ergänzt
killWolf()
showTooltip("mouseover")
expect("ein Kill", tooltipLines[1], "1-mal getötet")
killWolf()
showTooltip("mouseover")
expect("zweiter Kill sofort gezählt", tooltipLines[1], "2-mal getötet")
expect("Journal unverändert", #addon.Journal.GetEntries(addon.characterKey, "killLog"), 2)

local function noLine(description, unit)
  wow.state.units.mouseover = unit
  showTooltip("mouseover")
  expect(description, #tooltipLines, 0)
end
noLine("Spieler gleichen Namens", { name = "Wolf", level = 10, hostile = true, isPlayer = true })
noLine("freundlich", { name = "Wolf", level = 10 })
noLine("anderer Name", { name = "Bär", level = 10, hostile = true })
noLine("geheimer Name", { name = wow.SECRET, level = 10, hostile = true })
addon.Set("tooltipKillCount", false)
noLine("aus", { name = "Wolf", level = 10, hostile = true })

-- Kills bis Level im Tooltip (Roadmap 274): gelernt aus dem Kill-Journal je Name und Stufe, sonst Classic-Formel.
local MobXp = addon.MobXp

local postCalls = {}
Enum = Enum or {}
Enum.TooltipDataType = { Unit = 2 }
TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) postCalls[kind] = fn end }
local tooltipUnit
function GameTooltip:GetUnit() return tooltipUnit and "Name", tooltipUnit end
local tooltipLines = {}
function GameTooltip:AddLine(text, r, g, b) table.insert(tooltipLines, { text = text, color = { r, g, b } }) end
function GetCreatureDifficultyColor(level)
  if level > 12 then return { r = 1, g = 0.1, b = 0.1 } end
  return { r = 0.25, g = 0.75, b = 0.25 }
end
local function showTooltip(unit)
  tooltipUnit, tooltipLines = unit, {}
  postCalls[Enum.TooltipDataType.Unit](GameTooltip)
end

wow.login({ level = 10, xp = 0, xpMax = 1000 })
addon.Set("tooltipKillsToLevel", true)

-- Formel (warcraft.wiki.gg Mob experience): Stufe 10 gegen 10 = 95, gegen 12 = 95 * 1,1, gegen 8 = 95 * (1 - 2/7)
expect("gleiche Stufe", MobXp.Formula(10, 10, "normal"), 95)
expect("zwei höher", MobXp.Formula(10, 12, "normal"), 104)
expect("rote Gegner gedeckelt", MobXp.Formula(10, 20, "normal"), MobXp.Formula(10, 14, "normal"))
expect("zwei niedriger", MobXp.Formula(10, 8, "normal"), 67)
expect("elite doppelt", MobXp.Formula(10, 10, "elite"), 190)
expect("grau", MobXp.Formula(10, 4, "normal"), 0)
expect("graue Stufe 40", MobXp.GrayLevel(40), 31)

-- Retail (Stub-Standard): ohne Kill keine Schätzung
wow.state.units.mouseover = { name = "Wolf", level = 10, hostile = true }
showTooltip("mouseover")
expect("Retail ohne Kill keine Zeile", #tooltipLines, 0)

-- Classic Era: Formel mit "~"; 1000 XP / 95 = 10,5 -> 11
wow.state.interface = 11509
showTooltip("mouseover")
expect("geschätzte Zeile", tooltipLines[1] and tooltipLines[1].text, "Kills bis Level-Up: ~11")
expectNear("grün gefärbt", tooltipLines[1].color[2], 0.75)

-- Gelernt: Kill mit gesehener Stufe; Basis 100 (ohne Erholungsbonus 50) -> 850 fehlen -> 9 (Journal kennt die Stufe)
wow.fire("UPDATE_MOUSEOVER_UNIT")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", string.format(COMBATLOG_XPGAIN_EXHAUSTION1, "Wolf", 150, "+50", "Erholung"))
local entry = addon.character.killLog[#addon.character.killLog]
expect("Gegnerstufe im Journal", entry.mobLevel, 10)
wow.state.xp = 150
showTooltip("mouseover")
expect("gelernte Zeile", tooltipLines[1] and tooltipLines[1].text, "Kills bis Level-Up: 9")

-- Erholung zählt doppelt: Pool 400 -> 400/200 + 450/100 = 6,5 -> 7
wow.state.rested = 400
showTooltip("mouseover")
expect("mit Erholung", tooltipLines[1].text, "Kills bis Level-Up: 7")
wow.state.rested = 0

-- Andere Stufe desselben Namens: wieder geschätzt; rot gefärbt
wow.state.units.mouseover = { name = "Wolf", level = 13, hostile = true }
showTooltip("mouseover")
expectTrue("andere Stufe geschätzt", tooltipLines[1] and tooltipLines[1].text:find("~", 1, true))
expectNear("rot gefärbt", tooltipLines[1].color[1], 1)

-- Keine Zeile: Spieler, freundlich, tot, geheime Stufe, grau, Max-Level, Einstellung aus
local function noLine(description, unit)
  wow.state.units.mouseover = unit
  showTooltip("mouseover")
  expect(description, #tooltipLines, 0)
end
noLine("Spieler", { name = "Aragorn", level = 10, hostile = true, isPlayer = true })
-- Spieler: gar nicht erst rechnen (Roadmap 400)
local killsToLevel = MobXp.KillsToLevel
local computed = { count = 0 }
MobXp.KillsToLevel = function(...)
  computed.count = computed.count + 1
  return killsToLevel(...)
end
noLine("Spieler ohne Rechnung", { name = "Norfire", level = 10, hostile = true, isPlayer = true })
expect("Spieler: nicht gerechnet", computed.count, 0)
MobXp.KillsToLevel = killsToLevel
noLine("freundlich", { name = "Wache", level = 10 })
noLine("tot", { name = "Wolf", level = 10, hostile = true, dead = true })
noLine("geheime Stufe", { name = "Wolf", level = wow.SECRET, hostile = true })
noLine("grau", { name = "Wolf", level = 3, hostile = true })
wow.state.maxLevel = 10
noLine("Max-Level", { name = "Wolf", level = 10, hostile = true })
wow.state.maxLevel = 60
addon.Set("tooltipKillsToLevel", false)
noLine("aus", { name = "Wolf", level = 10, hostile = true })

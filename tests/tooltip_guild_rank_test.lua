-- Gildenrang im Tooltip (tooltipGuildRank): Rang hinter dem Gildennamen, nur bei Spielern, geheime Werte übergangen
local postCalls = {}
Enum = Enum or {}
Enum.TooltipDataType = { Unit = 2 }
TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) postCalls[kind] = fn end }
local lines = { GameTooltip:CreateFontString(), GameTooltip:CreateFontString() }
GameTooltipTextLeft1, GameTooltipTextLeft2 = lines[1], lines[2]
for _, line in ipairs(lines) do
  function line:SetText(text) self._text = text end
  function line:GetText() return self._text end
end
local tooltipUnit
function GameTooltip:GetUnit() return "Name", tooltipUnit end
function GameTooltip:NumLines() return 2 end
local guilds = { mouseover = { "Die Wächter", "Offizier" } }
function GetGuildInfo(unit)
  local guild = guilds[unit]
  if guild then return guild[1], guild[2], 1 end
end

local function show(unit, guildLine)
  tooltipUnit = unit
  lines[1]:SetText("Name")
  lines[2]:SetText(guildLine)
  postCalls[Enum.TooltipDataType.Unit](GameTooltip)
  return lines[2]:GetText()
end

wow.state.units.mouseover = { name = "Aragorn", isPlayer = true, class = "WARRIOR" }
wow.state.units.target = { name = "Wolf", isPlayer = false }
wow.login()

addon.Set("tooltipGuildRank", true)
expect("Rang ergänzt", show("mouseover", "<Die Wächter>"), "<Die Wächter> (Offizier)")
expect("ohne Gilde unverändert", show("target", "Stufe 12"), "Stufe 12")
guilds.mouseover = { wow.SECRET, "Offizier" }
expect("geheim: unverändert", show("mouseover", "<Die Wächter>"), "<Die Wächter>")
guilds.mouseover = { "Die Wächter", "Offizier" }
addon.Set("tooltipGuildRank", false)
expect("aus: unverändert", show("mouseover", "<Die Wächter>"), "<Die Wächter>")

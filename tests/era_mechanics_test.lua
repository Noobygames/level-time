-- Boss- und Trash-Mechaniken im Einheiten-Tooltip (Classic Era, Assist/InstanceData/mechanics.lua):
-- Zeilen je NPC-ID mit Typ und deutschem Text, höchstens MAX_LINES, nichts ohne Eintrag, bei geheimer GUID oder aus.
local L = addon.L
local Tips = addon.MechanicTips

wow.login({ level = 20 })

expectTrue("Era: verfügbar", Tips.IsAvailable())
expect("Standard an", addon.db.tooltipMechanics, true)

local lines = {}
local tooltip = { AddLine = function(_, text) table.insert(lines, text) end }
local function linesFor(guid)
  lines = {}
  wow.state.units.target = { name = "Gegner", guid = guid }
  Tips.AddUnitLines(tooltip, "target")
  return lines
end

-- Rhahk'Zor (Todesminen, 644): eine Tank-Mechanik mit Zaubersymbol, Text auf Deutsch (Stub-Locale deDE)
local rhahk = linesFor("Creature-0-1-0-36-644-0001")
expect("eine Zeile", #rhahk, 1)
expectTrue("Typ", rhahk[1]:find(L.MECHANIC_TANK .. ":", 1, true) ~= nil)
expectTrue("deutscher Text", rhahk[1]:find("Tank voll geheilt halten", 1, true) ~= nil)
expectTrue("Zaubersymbol", rhahk[1]:find("Spell_6304", 1, true) ~= nil)

-- Trash (LT-11): Defias-Beschwörer (Todesminen, 1729) hat zwei Mechaniken
expect("Trash", #linesFor("Creature-0-1-0-36-1729-0001"), 2)

-- Viele Mechaniken: höchstens MAX_LINES Zeilen
local busy
for npcID, list in pairs(addon.Mechanics) do
  if #list > Tips.MAX_LINES then busy = npcID break end
end
expectTrue("NPC mit vielen Mechaniken", busy ~= nil)
expect("gekappt", #linesFor("Creature-0-1-0-1-" .. busy .. "-0001"), Tips.MAX_LINES)

-- LT-56: Forever-eigene Zeilen fehlen auf Classic Era, Classic-only bleibt, kein Forever-Hinweis
expect("Forever-Boss fehlt", #linesFor("Creature-0-1-0-1-247126-0001"), 0)
expect("Classic-only bleibt", #linesFor("Creature-0-1-0-429-11480-0001"), 1)
expect("kein Hinweis", #linesFor("Creature-0-1-0-36-636-0001"), 1)

expect("unbekannter NPC", #linesFor("Creature-0-1-0-36-99999-0001"), 0)
expect("Spieler", #linesFor("Player-1-00000001"), 0)
expect("geheime GUID", #linesFor(wow.SECRET), 0)

-- Typen der Daten haben Farbe und Text, Texte gefüllt
for npcID, list in pairs(addon.Mechanics) do
  for _, mechanic in ipairs(list) do
    if not Tips.COLORS[mechanic[2]] or not L["MECHANIC_" .. mechanic[2]:upper()] or mechanic[3] == ""
      or mechanic[4] == "" then
      expect("Mechanik von " .. npcID, mechanic[2], "gültig")
    end
  end
end

-- Mechaniken auf WoW Forever (LT-56): nur Zeilen für Forever (Classic-only fällt weg, Forever-eigene Dungeons dazu);
-- Zeilen, die nur aus Classic übernommen sind, bekommen eine graue Hinweiszeile, bestätigte nicht.
local L = addon.L
local Tips = addon.MechanicTips

wow.login({ level = 20 })

expectTrue("Forever: verfügbar", Tips.IsAvailable())

local lines = {}
local tooltip = { AddLine = function(_, text) table.insert(lines, text) end }
local function linesFor(npcID)
  lines = {}
  wow.state.units.target = { name = "Gegner", guid = "Creature-0-1-0-1-" .. npcID .. "-0001" }
  Tips.AddUnitLines(tooltip, "target")
  return lines
end

-- Classic-only (Zauber fehlt im Forever-Build): Arkane Aberration (Düsterbruch) hat keine Zeile mehr
expect("Classic-only weg", #linesFor(11480), 0)
for npcID, list in pairs(addon.Mechanics) do
  for _, mechanic in ipairs(list) do
    if mechanic[5] == "c" then expect("Classic-Zeile bei " .. npcID, mechanic[5], "nicht auf Forever") end
  end
end

-- Forever-Dungeon: Atrexis (Stadt Dalaran) mit drei bestätigten Zeilen, kein Hinweis
local atrexis = linesFor(247126)
expect("Forever-Boss", #atrexis, 3)
expectTrue("Forever-Text", atrexis[1]:find("Unheilige Raserei", 1, true) ~= nil)

-- Vom Wowhead-Forever-Führer bestätigt (Zauber-ID 15496): Oggleflint ohne Hinweis
local oggleflint = linesFor(11517)
expect("bestätigt: kein Hinweis", oggleflint[#oggleflint]:find(L.FOREVER_UNVERIFIED, 1, true), nil)
expect("Typ-Symbol statt Forever-Zauber", oggleflint[1]:find("Spell_15496", 1, true), nil)

-- Nur aus Classic übernommen: Defias-Schwarzwache (Todesminen) mit Hinweis als letzte Zeile
local blackguard = linesFor(636)
expect("Hinweiszeile", blackguard[#blackguard], L.FOREVER_UNVERIFIED)
expectTrue("unbestätigte Zeile mit Sternchen", blackguard[1]:find("*|r", 1, true) ~= nil)
expect("bestätigte Zeile ohne Sternchen", oggleflint[1]:find("*|r", 1, true), nil)
expect("Zeile + Hinweis", #blackguard, 2)

-- Bestätigte Zeilen stehen vor unbestätigten (der Tooltip zeigt nur die ersten MAX_LINES)
for npcID, list in pairs(addon.Mechanics) do
  local unconfirmed = false
  for _, mechanic in ipairs(list) do
    if mechanic[5] == nil then unconfirmed = true
    elseif unconfirmed then expect("bestätigt vor unbestätigt bei " .. npcID, mechanic[5], nil) end
  end
end

-- Textsprache folgt der Addon-Sprache, nicht der Client-Sprache (LT-64)
addon.db.language = "enUS"
expect("englisch bei Addon-Sprache enUS", linesFor(247126)[1]:find("Unheilige Raserei", 1, true), nil)
addon.db.language = "deDE"
expect("keine Fehler", #wow.errors, 0)

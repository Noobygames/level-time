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
-- **Fähigkeitsname** wird farbig, ohne Farbe ohne Sternchen; Text ohne Markierung bleibt unverändert
expect("Highlight", addon.Format.Highlight("**Feuerball** trifft"), addon.Theme.Hex("gold") .. "Feuerball|r trifft")
expect("StripHighlight", addon.Format.StripHighlight("**Feuerball** trifft **hart**"), "Feuerball trifft hart")
expect("ohne Markierung", addon.Format.Highlight("Feuerball trifft"), "Feuerball trifft")
expect("Highlight mit Link: nur erste Markierung", addon.Format.Highlight("**Feuerball** und **Frost**", "spell:133"),
  addon.Theme.Hex("gold") .. "|Hspell:133|hFeuerball|h|r und " .. addon.Theme.Hex("gold") .. "Frost|r")
-- Zauber-Link nur auf Wunsch (Dungeon Guide) und nur mit Zauber-ID
local volley = { 9081, "interrupt", "**Schattenblitzsalve** trifft alle", "**Shadow Bolt Volley** hits all" }
expectTrue("Guide-Zeile verlinkt", Tips.LineText(volley, true):find("|Hspell:9081|hSchattenblitzsalve|h", 1, true) ~= nil)
-- Linktext = Clientname des Zaubers (wie im Tooltip), auch wenn der Guide ihn anders nennt; % im Namen bleibt
wow.state.spellNames[8269] = "Raserei"
local frenzy = { 8269, "dispel", "**Wutanfall** macht ihn schneller", "**Frenzy** makes him faster" }
expectTrue("Clientname als Linktext", Tips.LineText(frenzy, true):find("|Hspell:8269|hRaserei|h", 1, true) ~= nil)
expect("Guide-Name ersetzt", Tips.LineText(frenzy, true):find("Wutanfall", 1, true), nil)
expectTrue("ohne Link Guide-Name", Tips.LineText(frenzy):find("Wutanfall", 1, true) ~= nil)
expect("Prozent im Namen", addon.Format.Highlight("**X** wirkt", "spell:1", "50% Schaden"),
  addon.Theme.Hex("gold") .. "|Hspell:1|h50% Schaden|h|r wirkt")
expect("Einheiten-Tooltip ohne Link", Tips.LineText(volley):find("|H", 1, true), nil)
expect("ohne Zauber-ID kein Link", Tips.LineText({ 0, "avoid", "**Feuer** meiden", "Avoid **fire**" }, true):find("|H", 1, true), nil)
for _, list in pairs(addon.Mechanics) do
  for _, mechanic in ipairs(list) do
    expect("keine rohen Sternchen", Tips.LineText(mechanic):find("**", 1, true), nil)
  end
end
expect("keine Fehler", #wow.errors, 0)

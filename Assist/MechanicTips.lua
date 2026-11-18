-- Boss- und Trash-Mechaniken im Einheiten-Tooltip (LT-10/LT-11, Einstellung tooltipMechanics im Reiter "Komfort",
-- Standard an; nur mit ns.Mechanics, also Classic Era und Forever): Gegner, deren NPC-ID in den Guide-Daten
-- (Assist/InstanceData/mechanics.lua) steht, bekommen bis zu MAX_LINES Zeilen "Symbol Typ: Text". Typ in eigener Farbe,
-- Symbol = bekanntes Spielersymbol des Typs (TYPE_SPELLS, z.B. Magiebannung für "Bannen"), nicht das Symbol des
-- Gegnerzaubers: das sagt, was zu tun ist. Unbekannter Typ: Zaubersymbol der Mechanik, sonst das Fragezeichen.
-- Gilt überall, wo der NPC auftaucht
-- (reine Tabellen-Abfrage per NPC-ID). Angehängt von Assist/Tooltip.lua.
-- NPC-ID aus UnitGUID; ist die GUID geheim (Forever in Instanzen möglich), fehlen die Zeilen (Debug-Check
-- LT10.mechanics.mouseover).
-- Text: deDE-Clients den deutschen, alle anderen den englischen (frFR/esES haben keine eigenen Guide-Texte).
-- Forever (LT-56): die Daten enthalten nur Zeilen dieses Flavors; ist eine gezeigte Zeile nur aus Classic übernommen
-- (ohne Kennung, keine Forever-Quelle bestätigt sie), trägt sie ein Sternchen und es folgt die Hinweiszeile
-- (Lib/UnverifiedHint.lua, wie bei der Bossbeute). Text deutsch nur bei Addon-Sprache deDE, sonst englisch.
local _, ns = ...
local L = ns.L

ns.RegisterDefaults({
  settings = {
    tooltipMechanics = true,
  },
})

local MechanicTips = {}
ns.MechanicTips = MechanicTips

MechanicTips.MAX_LINES = 3
local SPELL_ID, KIND, TEXT_DE, TEXT_EN, TAG = 1, 2, 3, 4, 5
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local TEXT_COLOR = ns.Theme.COLORS.textSecondary

-- Farbe je Typ (Typen wie in tools/mechanics); dispel/tank/adds sind bewusst feste Kategoriefarben ohne Theme-Gegenstück
MechanicTips.COLORS = {
  avoid = ns.Theme.COLORS.warning,
  interrupt = ns.Theme.COLORS.info,
  dispel = { 0.75, 0.5, 1 },
  tank = { 0.8, 0.65, 0.45 },
  survive = ns.Theme.COLORS.bad,
  adds = { 1, 0.85, 0.2 },
  positioning = ns.Theme.COLORS.good,
}

-- Typ -> Spieler-Zauber, dessen Symbol in WoW schon diese Bedeutung trägt (in allen Flavors vorhanden)
local TYPE_SPELLS = {
  dispel = 527,       -- Magiebannung
  interrupt = 1766,   -- Tritt
  tank = 71,          -- Verteidigungshaltung
  avoid = 2983,       -- Sprinten
  survive = 17,       -- Machtwort: Schild
  adds = 845,         -- Spalten (mehrere Gegner)
  positioning = 1494, -- Wildtiere aufspüren (Fußspuren)
}

function MechanicTips.IsAvailable()
  return ns.Mechanics ~= nil
end

-- Mechaniken einer NPC-ID (nicht verändern), nil ohne Eintrag
function MechanicTips.ForNpc(npcID)
  return ns.Mechanics and npcID and ns.Mechanics[npcID]
end

function MechanicTips.NpcOf(unit)
  return ns.QuestBlocklist.NpcId(UnitGUID(unit))
end

-- Tooltip-Text einer Mechanik: "|T...|t Typ: Text", Typ farbig
function MechanicTips.LineText(mechanic)
  local color = MechanicTips.COLORS[mechanic[KIND]] or TEXT_COLOR
  local spellID = TYPE_SPELLS[mechanic[KIND]] or (mechanic[SPELL_ID] > 0 and mechanic[SPELL_ID])
  local icon = spellID and ns.Widgets.SpellTexture(spellID) or FALLBACK_ICON
  local text = ns.Language() == "deDE" and mechanic[TEXT_DE] or mechanic[TEXT_EN]
  text = ns.Format.Highlight(text)
  return string.format("|T%s:0|t |cff%02x%02x%02x%s:|r %s", icon, math.floor(color[1] * 255),
    math.floor(color[2] * 255), math.floor(color[3] * 255), L["MECHANIC_" .. mechanic[KIND]:upper()], text)
end

-- Zeilentexte der ersten maxLines Mechaniken (ohne maxLines alle) und ob eine davon für Forever unbestätigt ist
-- (ohne Kennung, nur im Forever-Client; solche Zeilen tragen das Sternchen). Auch für den Dungeon Guide.
function MechanicTips.Lines(mechanics, maxLines)
  local forever, unverified, lines = ns.Client.IsForever(), false, {}
  for index = 1, math.min(#mechanics, maxLines or #mechanics) do
    local text = MechanicTips.LineText(mechanics[index])
    if forever and mechanics[index][TAG] == nil then
      text = text .. " " .. ns.UnverifiedHint.Mark()
      unverified = true
    end
    lines[index] = text
  end
  return lines, unverified
end

function MechanicTips.AddUnitLines(tooltip, unit)
  local npcID = MechanicTips.NpcOf(unit)
  local mechanics = MechanicTips.ForNpc(npcID)
  -- Spieler (npcID nil) nicht loggen; sonst nur bei Änderung (Tooltip-Refresh alle 0,2 s)
  if npcID then ns.DebugOnChange("mechanics", "mechanicsTooltip", "unit tooltip npc %s: %s lines", npcID, mechanics and #mechanics or 0) end
  if not mechanics then return end
  local lines, unverified = MechanicTips.Lines(mechanics, MechanicTips.MAX_LINES)
  for _, text in ipairs(lines) do
    tooltip:AddLine(text, TEXT_COLOR[1], TEXT_COLOR[2], TEXT_COLOR[3], true)
  end
  if unverified then ns.UnverifiedHint.AddLine(tooltip) end
end

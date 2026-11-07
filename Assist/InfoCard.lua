-- Infokarten (Reiter Komfort, Fenster; infoCards, Standard aus): Taste (Bindings.xml LEVELTIMER_INFO_CARD) zeigt zu
-- dem, was der Tooltip gerade zeigt (Gegenstand, Zauber, NPC oder Spieler), Name, Art, ID und einen Wowhead-Link im
-- Kopierfenster (Export.Show, Strg+C). Gelesen über TooltipUtil.GetDisplayedItem/Spell/Unit
-- (Blizzard_SharedXMLGame/Tooltip/TooltipUtil.lua, alle vier Clients); NPC-ID aus der GUID ("Creature-0-...-ID-...").
-- Ohne Tooltip gilt die Maus-Einheit (mouseover). Geheime Werte = nichts zu zeigen. Die Modell-Vorschau der
-- Leatrix-Idee fehlt (eigenes Modellfenster, später).
local _, ns = ...
local L = ns.L

local InfoCard = {}
ns.InfoCard = InfoCard

-- Wowhead je Client (Client.Flavor); Forever hat keine eigene Wowhead-Seite, dort die Classic-Datenbank (ungeprüft)
InfoCard.WOWHEAD = {
  retail = "https://www.wowhead.com/",
  classic_era = "https://www.wowhead.com/classic/",
  anniversary = "https://www.wowhead.com/tbc/",
  forever = "https://www.wowhead.com/classic/",
}
local CREATURE_TYPES = { Creature = true, Vehicle = true, Pet = true }

local function readable(...)
  for index = 1, select("#", ...) do
    if ns.IsSecret((select(index, ...))) then return false end
  end
  return true
end

function InfoCard.Url(kind, id)
  local base = InfoCard.WOWHEAD[ns.Client.Flavor()] or InfoCard.WOWHEAD.retail
  return string.format("%s%s=%d", base, kind, id)
end

-- NPC-ID aus einer Kreatur-GUID, nil für Spieler und andere Arten
function InfoCard.NpcId(guid)
  if type(guid) ~= "string" then return nil end
  local unitType, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
  if not CREATURE_TYPES[unitType] then return nil end
  return tonumber(id)
end

local function itemId(link)
  return type(link) == "string" and tonumber((link:match("item:(%d+)"))) or nil
end

-- { kind, name, id } des Tooltips oder der Maus-Einheit; nil ohne lesbares Ziel
function InfoCard.Subject()
  local tooltip = GameTooltip
  if TooltipUtil and tooltip and tooltip:IsShown() then
    local name, link, id = TooltipUtil.GetDisplayedItem(tooltip)
    if readable(name, link, id) and (id or itemId(link)) then
      return { kind = "item", name = name, id = id or itemId(link) }
    end
    local spellName, spellId = TooltipUtil.GetDisplayedSpell(tooltip)
    if readable(spellName, spellId) and spellId then return { kind = "spell", name = spellName, id = spellId } end
    local unitName, unit, guid = TooltipUtil.GetDisplayedUnit(tooltip)
    if readable(unitName, unit, guid) and guid then return InfoCard.UnitSubject(unitName, guid) end
  end
  local guid, name = UnitGUID("mouseover"), UnitName("mouseover")
  if readable(guid, name) and guid then return InfoCard.UnitSubject(name, guid) end
  return nil
end

function InfoCard.UnitSubject(name, guid)
  local npcId = InfoCard.NpcId(guid)
  if npcId then return { kind = "npc", name = name, id = npcId } end
  return { kind = "player", name = name }
end

-- Text der Karte (eine Angabe je Zeile)
function InfoCard.Text(subject)
  local lines = { subject.name or "?", string.format(L.INFO_CARD_KIND, L["INFO_CARD_KIND_" .. subject.kind:upper()]) }
  if subject.id then
    table.insert(lines, string.format(L.INFO_CARD_ID, subject.id))
    table.insert(lines, InfoCard.Url(subject.kind, subject.id))
  end
  return table.concat(lines, "\n")
end

function InfoCard.Show()
  if not (ns.db and ns.db.infoCards) then
    ns.Print(L.INFO_CARD_OFF)
    return
  end
  local subject = InfoCard.Subject()
  if not subject then
    ns.Print(L.INFO_CARD_NOTHING)
    return
  end
  ns.Debug("comfort", "info card %s %s", subject.kind, subject.id)
  ns.Export.Show(L.INFO_CARD_TITLE, InfoCard.Text(subject))
end

-- Tastenbelegung (Bindings.xml)
function LevelTimer_InfoCard()
  if ns.character then InfoCard.Show() end
end

ns.RegisterApply(function()
  BINDING_NAME_LEVELTIMER_INFO_CARD = L.INFO_CARD_BINDING
end)

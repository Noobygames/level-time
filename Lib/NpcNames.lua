-- NPC-Namen in der Sprache des Clients aus der NPC-ID (LT-51): die DungeonDB führt keine NPC-Namen.
-- Versteckter GameTooltip mit dem Hyperlink "unit:Creature-0-0-0-0-<npcID>-0000000000"; Zeile 1 ist der Name aus dem
-- Kreaturen-Cache des Clients. Ist der NPC dort noch unbekannt, bleibt die Zeile leer und der Client fragt den Server;
-- ein späterer Aufruf liefert den Namen. Gefundene Namen nur je Sitzung zwischengespeichert: der Client hält seinen
-- Kreaturen-Cache selbst über Sitzungen hinweg. Ob Classic Era/Forever den unit-Link annehmen: Prüfung LT51.npcName.
local _, ns = ...

local NpcNames = {}
ns.NpcNames = NpcNames

local SCAN_TOOLTIP = ns.GlobalName("NpcNameScanTooltip")
local UNIT_LINK = "unit:Creature-0-0-0-0-%d-0000000000"

local names = {}  -- [npcID] = Name
local scanner

local function readable(value)
  if value == nil or ns.IsSecret(value) then return nil end
  return value
end

local function lookup(npcID)
  if not scanner then
    scanner = CreateFrame("GameTooltip", SCAN_TOOLTIP, UIParent, "GameTooltipTemplate")
  end
  scanner:SetOwner(UIParent, "ANCHOR_NONE")
  local ok = pcall(scanner.SetHyperlink, scanner, string.format(UNIT_LINK, npcID))
  local fontString = _G[SCAN_TOOLTIP .. "TextLeft1"]
  local name = ok and fontString and readable(fontString:GetText())
  scanner:Hide()
  if type(name) == "string" and name ~= "" then return name end
  return nil
end

-- Name des NPCs oder nil, solange der Client ihn nicht kennt
function NpcNames.Get(npcID)
  if type(npcID) ~= "number" then return nil end
  if not names[npcID] then
    names[npcID] = lookup(npcID)
    ns.Debug("npcnames", "lookup %s: %s", npcID, names[npcID])
  end
  return names[npcID]
end

-- Einstufung von Gegnern nach Namen (normal, elite, rare, rareelite, worldboss), gemerkt sobald man sie
-- anvisiert, mit der Maus berührt oder ihre Namensplakette sieht. KillCounter schlägt beim Kill den
-- Namen aus der XP-Meldung nach; so geht es ohne Kampflog und damit in allen Clients.
local _, ns = ...

local Classification = {}
ns.Classification = Classification

-- Hinweis: der Name ist der Schlüssel (der Kill-Text nennt nur ihn); gleichnamige Gegner mit anderer Einstufung
-- erben die zuletzt gesehene. Ausnahme: ist das Ziel tot und heißt wie der Kill, gilt dessen Einstufung (der
-- übliche Fall: man hat getötet, was man im Ziel hatte), Roadmap 187.
local MAX_NAMES = 5000  -- danach wird neu begonnen, damit die Tabelle nicht endlos wächst

local byName = {}
local levelByName = {}  -- Stufe des Gegners (UnitLevel), für die XP je Gegner (MobXp.lua)
local nameCount = 0

-- Geheime Werte (Retail/Forever in eingeschränkten Instanzen) zuerst ausschließen: schon ein Wahrheitstest
-- darauf ist für Addons ein Fehler
local function remember(unit)
  if not unit then return end
  local exists, isPlayer = UnitExists(unit), UnitIsPlayer(unit)
  if ns.IsSecret(exists) or not exists or ns.IsSecret(isPlayer) or isPlayer then return end
  local name, classification = UnitName(unit), UnitClassification(unit)
  if ns.IsSecret(name) or ns.IsSecret(classification) or not name then return end
  if not byName[name] then
    nameCount = nameCount + 1
    if nameCount > MAX_NAMES then
      byName, levelByName, nameCount = {}, {}, 1
    end
  end
  byName[name] = classification
  local level = UnitLevel(unit)
  if not ns.IsSecret(level) and type(level) == "number" and level > 0 then levelByName[name] = level end
end

-- Einstufung des toten Ziels, wenn es name heißt; sonst nil
local function deadTargetClassification(name)
  local dead, targetName, isPlayer = UnitIsDead("target"), UnitName("target"), UnitIsPlayer("target")
  if ns.IsSecret(dead) or not dead or ns.IsSecret(targetName) or targetName ~= name then return nil end
  if ns.IsSecret(isPlayer) or isPlayer then return nil end
  local classification = UnitClassification("target")
  if ns.IsSecret(classification) then return nil end
  return classification
end

-- Einstufung eines eben getöteten Gegners: das tote Ziel mit diesem Namen, sonst die zuletzt gesehene; nil = unbekannt
function Classification.Of(name)
  if not name then return nil end
  return deadTargetClassification(name) or byName[name]
end

-- Zuletzt gesehene Stufe eines Gegners oder nil (unbekannt oder "??")
function Classification.LevelOf(name)
  return name and levelByName[name]
end

function Classification.IsElite(classification)
  return classification == "elite" or classification == "rareelite" or classification == "worldboss"
end

function Classification.IsRare(classification)
  return classification == "rare" or classification == "rareelite"
end

ns.RegisterEvent("PLAYER_TARGET_CHANGED", function() remember("target") end)
ns.RegisterEvent("UPDATE_MOUSEOVER_UNIT", function() remember("mouseover") end)
ns.RegisterEvent("NAME_PLATE_UNIT_ADDED", remember)

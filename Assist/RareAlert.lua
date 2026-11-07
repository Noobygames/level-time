-- Seltene Gegner melden (Roadmap 348, Einstellungen alertRareSpotted und alertRareFlash, aus): erscheint ein lebender
-- Gegner mit UnitClassification "rare" oder "rareelite" auf einer Namensplakette, als Ziel oder unter der Maus,
-- Einblendung "Rare gesichtet: Name" mit Ton (alertSound), optional blinkt das WoW-Symbol in der Taskleiste
-- (FlashClientIcon). Je Name einmal pro Session; keine Rare-Liste, der Client sagt es selbst. Geheime Werte = nichts.
-- Die Events sind nur angemeldet, solange die Einstellung an ist (Event-Gruppe).
local _, ns = ...

local RareAlert = {}
ns.RareAlert = RareAlert

local RARE = { rare = true, rareelite = true }

local announced = {}  -- [Name] = true in dieser Session

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

-- Name eines lebenden seltenen Nicht-Spielers, sonst nil
function RareAlert.RareName(unit)
  if not unit or readable(UnitExists(unit)) ~= true then return nil end
  if readable(UnitIsPlayer(unit)) ~= false or readable(UnitIsDead(unit)) ~= false then return nil end
  if not RARE[readable(UnitClassification(unit)) or ""] then return nil end
  local name = readable(UnitName(unit))
  return type(name) == "string" and name ~= "" and name or nil
end

function RareAlert.Check(unit)
  local name = RareAlert.RareName(unit)
  if not name or announced[name] then return end
  announced[name] = true
  ns.Debug("alert", "rare spotted: %s (%s)", name, unit)
  ns.Alerts.Raise("rareSpotted", name)
  if ns.db.alertRareFlash and FlashClientIcon then FlashClientIcon() end
end

local events = ns.NewEventGroup()
events.Add("NAME_PLATE_UNIT_ADDED", nil, RareAlert.Check)
events.Add("PLAYER_TARGET_CHANGED", nil, function() RareAlert.Check("target") end)
events.Add("UPDATE_MOUSEOVER_UNIT", nil, function() RareAlert.Check("mouseover") end)

ns.RegisterApply(function(db) events.SetActive(db.alertRareSpotted) end)
ns.OnLogin(function() announced = {} end)

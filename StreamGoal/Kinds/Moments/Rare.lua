-- Moment "Rare-Gegner sehen": ein lebender Gegner mit UnitClassification "rare" oder "rareelite" auf einer
-- Namensplakette, als Ziel oder unter der Maus (dieselbe Prüfung wie der Rare-Hinweis von Level Time,
-- RareAlert.RareName; alle Clients, geheime Werte = nichts). Jeder Rare zählt einmal je Sitzung (GUID, sonst Name).
local _, ns = ...
local LT = ns.LT
local Moments = ns.Moments

local MODE = "rare"
local seen = {}  -- [GUID oder Name] = true in dieser Sitzung

local function check(unit)
  local name = LT.RareAlert.RareName(unit)
  if not name then return end
  local guid = UnitGUID(unit)
  local key = (guid and not LT.IsSecret(guid)) and guid or name
  if seen[key] then return end
  seen[key] = true
  ns.Debug("moment", "rare seen: %s (%s)", name, unit)
  Moments.Count(MODE, 1)
end

local events = LT.NewEventGroup()
events.Add("NAME_PLATE_UNIT_ADDED", nil, check)
events.Add("PLAYER_TARGET_CHANGED", nil, function() check("target") end)
events.Add("UPDATE_MOUSEOVER_UNIT", nil, function() check("mouseover") end)

Moments.Register(MODE, {
  label = "SG_MOMENT_RARE",
  title = "SG_GOAL_MOMENT_RARE",
  icon = LT.Alerts.ICONS.rare,
  available = function() return UnitClassification ~= nil end,
  events = events,
})

LT.OnLogin(function() seen = {} end)

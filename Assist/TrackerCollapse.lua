-- Zielverfolgung eingeklappt lassen: Blizzards ObjectiveTracker (Retail, WoW Forever) merkt sich nicht, was
-- eingeklappt war; nach Login und /reload ist alles offen. Hier wird der Zustand des Ganzen (ObjectiveTrackerFrame)
-- und jedes Abschnitts (Quests, Erfolge, ...; Rahmenname als Schlüssel) je Charakter gemerkt und beim Login
-- wiederhergestellt. Merken über hooksecurefunc auf SetCollapsed (Klick auf Minimieren, nichts verändert).
-- Wiederherstellen ruft Blizzards SetCollapsed aus Addon-Code und nur außerhalb des Kampfs: Der Tracker zeigt
-- Quest-Gegenstände als geschützte Knöpfe, Taint dort wäre im Kampf sichtbar. Darum abschaltbar
-- (rememberTrackerCollapse). Classic Era hat keinen einklappbaren Tracker: dort nichts.
local _, ns = ...

ns.RegisterDefaults({ settings = { rememberTrackerCollapse = true } })

local TrackerCollapse = {}
ns.TrackerCollapse = TrackerCollapse

local RESTORE_DELAY = 1  -- Sekunden nach dem Login: Blizzard hängt die Abschnitte erst beim Weltbetreten ein
local CONTAINER_KEY = "ObjectiveTrackerFrame"

local hooked = {}
local pending = false

local function tracker()
  local frame = _G[CONTAINER_KEY]
  if type(frame) ~= "table" or type(frame.SetCollapsed) ~= "function" then return nil end
  return frame
end

-- Ganzes und alle Abschnitte mit Namen: Schlüssel -> Rahmen
local function collapsibles()
  local frame = tracker()
  if not frame then return {} end
  local list = { [CONTAINER_KEY] = frame }
  for _, module in ipairs(type(frame.modules) == "table" and frame.modules or {}) do
    local name = module.GetName and module:GetName()
    if name and type(module.SetCollapsed) == "function" then list[name] = module end
  end
  return list
end

local function remember(key, collapsed)
  if not ns.character then return end
  ns.character.trackerCollapsed[key] = collapsed and true or nil
end

local function hookAll()
  for key, frame in pairs(collapsibles()) do
    if not hooked[key] then
      hooked[key] = true
      hooksecurefunc(frame, "SetCollapsed", function(_, collapsed) ns.SafeCall(remember, key, collapsed) end)
    end
  end
end

-- Gemerkten Zustand setzen; nur wo er abweicht (unnötige Blizzard-Aufrufe sparen)
function TrackerCollapse.Restore()
  hookAll()
  if not (ns.db.rememberTrackerCollapse and ns.character) then return end
  if InCombatLockdown() then
    pending = true
    return
  end
  pending = false
  for key, frame in pairs(collapsibles()) do
    local wanted = ns.character.trackerCollapsed[key] == true
    local current = frame.IsCollapsed and frame:IsCollapsed() == true
    if wanted ~= current then
      ns.Debug("tracker", "restore %s collapsed=%s", key, tostring(wanted))
      frame:SetCollapsed(wanted)
    end
  end
end

ns.OnLogin(function()
  C_Timer.After(RESTORE_DELAY, function() ns.SafeCall(TrackerCollapse.Restore) end)
end)
ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if pending then TrackerCollapse.Restore() end
end)

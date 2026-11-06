-- Hinweise beim Leveln, bevor es Zeit kostet; jeder einzeln schaltbar (Standard aus):
--   warnBagsFull   weniger als BAGS_LOW freie Plätze in normalen Taschen (Beute geht verloren)
--   warnDurability ein ausgerüsteter Gegenstand unter DURABILITY_LOW Haltbarkeit
--   warnAmmo       Jäger mit weniger als ammoLow Schuss (Einstellung, Standard 200) im Munitionsplatz (nicht in Retail,
--                  zweite Warnung "fast leer" unter ammoCritical, Wiederholung alle ammoRepeat Minuten;
--                  dort gibt es keine Munition; GearWarnings.HasAmmo)
-- Gewarnt wird einmal, wenn der Zustand eintritt (Einblendung + Chat), und erst wieder, nachdem er
-- vorbei war (Munition: zusätzlich wiederholt, solange sie knapp bleibt). Geprüft wird alle CHECK_INTERVAL Sekunden statt auf viele Einzel-Events zu hören.
-- Freie Plätze: Bags.GetFreeSlots (nur normale Taschen; Köcher und Berufstaschen zählen nicht).
-- APIs in allen Clients: GetInventoryItemDurability(slot) -> aktuell, max (nil bei Gegenständen ohne Haltbarkeit),
-- GetInventoryItemCount("player", INVSLOT_AMMO) wie Blizzards Munitionsplatz im Charakterfenster.
local _, ns = ...
local L = ns.L

local GearWarnings = {}
ns.GearWarnings = GearWarnings

local CHECK_INTERVAL = 5
local SECONDS_PER_MINUTE = 60
local BAGS_LOW = 2              -- freie Plätze, ab denen gewarnt wird
local DURABILITY_LOW = 0.2      -- Anteil der Haltbarkeit, ab dem gewarnt wird
local FIRST_EQUIPPED_SLOT = 1
local DEFAULT_LAST_EQUIPPED_SLOT = 19
GearWarnings.MIN_AMMO = 20      -- Grenzen des Reglers in den Einstellungen
GearWarnings.MAX_AMMO = 1000
GearWarnings.MAX_CRITICAL_AMMO = 500
GearWarnings.MAX_AMMO_REPEAT = 30  -- Minuten
local AMMO_SLOT = INVSLOT_AMMO or 0
local HUNTER = "HUNTER"

-- fn(current, maximum) für jeden ausgerüsteten Gegenstand mit Haltbarkeit
local function forEachDurability(fn)
  for slot = FIRST_EQUIPPED_SLOT, INVSLOT_LAST_EQUIPPED or DEFAULT_LAST_EQUIPPED_SLOT do
    local current, maximum = GetInventoryItemDurability(slot)
    if current and maximum and maximum > 0 then fn(current, maximum) end
  end
end

-- Niedrigste Haltbarkeit aller ausgerüsteten Gegenstände (0..1); 1 ohne Gegenstände mit Haltbarkeit
function GearWarnings.GetLowestDurability()
  local lowest = 1
  forEachDurability(function(current, maximum) lowest = math.min(lowest, current / maximum) end)
  return lowest
end

-- Gesamthaltbarkeit (Summe aktuell / Summe maximal, 0..1); nil ohne Gegenstände mit Haltbarkeit
function GearWarnings.GetOverallDurability()
  local currentSum, maximumSum = 0, 0
  forEachDurability(function(current, maximum)
    currentSum, maximumSum = currentSum + current, maximumSum + maximum
  end)
  if maximumSum == 0 then return nil end
  return currentSum / maximumSum
end

function GearWarnings.HasAmmo()
  return not ns.Client.IsRetail()
end

-- Einstellungen zur Munition zeigen wir nur Jägern (andere Klassen mit Fernkampfwaffe warnen wir nicht)
function GearWarnings.ShowsAmmoOptions()
  return GearWarnings.HasAmmo() and select(2, UnitClass("player")) == HUNTER
end

-- WoW Forever sagt selbst, ob der Charakter Munition nutzt (UnitUsesAmmo, wie Blizzards Munitionsplatz
-- im Charakterfenster); sonst alle Jäger
local function usesAmmo()
  if UnitUsesAmmo then return UnitUsesAmmo("player") end
  return select(2, UnitClass("player")) == HUNTER
end

-- Schuss im Munitionsplatz; nil, wenn der Charakter keine Munition nutzt
local function ammoCount()
  if not GearWarnings.HasAmmo() or not usesAmmo() then return nil end
  return GetInventoryItemCount("player", AMMO_SLOT)
end

-- "Fast leer" gilt unter ammoCritical, höchstens aber unter der normalen Grenze; 0 = aus.
-- "Knapp" gilt zwischen beiden Grenzen, damit beim Absinken nur eine der beiden Warnungen kommt.
local function criticalLimit()
  return math.min(ns.db.ammoCritical, ns.db.ammoLow)
end

local function isAmmoLow()
  local count = ammoCount()
  return count ~= nil and count < ns.db.ammoLow and count >= criticalLimit()
end

local function isAmmoCritical()
  local count = ammoCount()
  return count ~= nil and count < criticalLimit()
end

-- Verbleibende Schuss als Zusatz hinter dem Warntext, z.B. "Munition knapp! (150 Schuss)"
local function ammoDetail()
  local count = ammoCount()
  return count and string.format(L.AMMO_COUNT, count) or nil
end

-- Freie Plätze als Zusatz, z.B. "Taschen fast voll! (1 frei)"
local function bagsDetail()
  return string.format(L.BAGS_FREE_COUNT, ns.Bags.GetFreeSlots())
end

-- Je Hinweis: Einstellung, Prüfung (true = warnen), Text, detail() (optional, Zusatz hinter dem Text); active = Zustand bei der letzten Prüfung;
-- repeatMinutes() (optional) wiederholt den Hinweis in diesem Abstand, solange der Zustand anhält (0 = nie)
local WARNINGS = {
  { setting = "warnBagsFull", message = "WARN_BAGS_FULL", title = "NOTICE_BAGS", icon = "bags",
    isDue = function() return ns.Bags.GetFreeSlots() < BAGS_LOW end, detail = bagsDetail },
  { setting = "warnDurability", message = "WARN_DURABILITY", title = "NOTICE_DURABILITY", icon = "durability",
    isDue = function() return GearWarnings.GetLowestDurability() < DURABILITY_LOW end },
  { setting = "warnAmmo", message = "WARN_AMMO", title = "NOTICE_AMMO", icon = "ammo", isDue = isAmmoLow,
    detail = ammoDetail, repeatMinutes = function() return ns.db.ammoRepeat end },
  { setting = "warnAmmo", message = "WARN_AMMO_CRITICAL", title = "NOTICE_AMMO", icon = "ammo", isDue = isAmmoCritical,
    detail = ammoDetail, repeatMinutes = function() return ns.db.ammoRepeat end },
}

-- Im Kampf nichts prüfen: der Zustand bleibt unbeachtet, die Hinweise kommen nach dem Kampf von selbst
function GearWarnings.Check()
  if not ns.db or ns.InCombat() then return end
  for _, warning in ipairs(WARNINGS) do
    local due = ns.db[warning.setting] and warning.isDue() or false
    local interval = warning.repeatMinutes and warning.repeatMinutes() or 0
    local repeating = due and warning.active and interval > 0
      and GetTime() - warning.lastShown >= interval * SECONDS_PER_MINUTE
    if (due and not warning.active) or repeating then
      ns.Debug("warnings", "%s", warning.message)
      warning.lastShown = GetTime()
      local detail = warning.detail and warning.detail()
      local text = detail and string.format("%s (%s)", L[warning.message], detail) or L[warning.message]
      ns.Alerts.Notify({ title = L[warning.title], text = text, icon = ns.Alerts.ICONS[warning.icon] },
        ns.Alerts.WARNING_COLOR)
    end
    warning.active = due
  end
end

ns.Every(CHECK_INTERVAL, GearWarnings.Check)

ns.OnLogin(function()
  for _, warning in ipairs(WARNINGS) do
    warning.active = false
  end
end)

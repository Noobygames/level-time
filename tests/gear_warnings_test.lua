-- Warnungen beim Leveln: einmal beim Eintreten, wieder erst, nachdem der Zustand vorbei war.
local GearWarnings = addon.GearWarnings
local L = addon.L

local function count(message)
  local found = 0
  for _, line in ipairs(wow.printed) do
    if line:find(message, 1, true) then found = found + 1 end
  end
  return found
end

wow.login()

---------------------------------------------------------------------------
-- Taschen fast voll
---------------------------------------------------------------------------
wow.state.freeSlots = { [0] = { 1, 0 }, [1] = { 20, 4 } }  -- Tasche 1 = Köcher o.ä., zählt nicht
expect("freie Plätze", addon.Bags.GetFreeSlots(), 1)
GearWarnings.Check()
expect("aus: still", count(L.WARN_BAGS_FULL), 0)

addon.Set("warnBagsFull", true)
GearWarnings.Check()
expect("Warnung", count(L.WARN_BAGS_FULL), 1)
expect("Karte: Text mit freien Plätzen", LevelTimerNotice.body:GetText(),
  L.WARN_BAGS_FULL .. " (" .. string.format(L.BAGS_FREE_COUNT, 1) .. ")")
expect("Karte: Titel", LevelTimerNotice.title:GetText(), L.NOTICE_BAGS)
GearWarnings.Check()
expect("nur einmal", count(L.WARN_BAGS_FULL), 1)

wow.state.freeSlots[0] = { 10, 0 }
GearWarnings.Check()
wow.state.freeSlots[0] = { 0, 0 }
GearWarnings.Check()
expect("nach Platz wieder", count(L.WARN_BAGS_FULL), 2)

---------------------------------------------------------------------------
-- Haltbarkeit
---------------------------------------------------------------------------
wow.state.freeSlots[0] = { 10, 0 }
wow.state.durability = { [1] = { 50, 60 }, [5] = { 10, 100 } }
expectNear("niedrigste", GearWarnings.GetLowestDurability(), 0.1, 0.001)
addon.Set("warnDurability", true)
GearWarnings.Check()
expect("Haltbarkeit-Warnung", count(L.WARN_DURABILITY), 1)
GearWarnings.Check()
expect("nur einmal", count(L.WARN_DURABILITY), 1)
wow.state.durability = { [5] = { 100, 100 } }
GearWarnings.Check()
expect("repariert: still", count(L.WARN_DURABILITY), 1)

---------------------------------------------------------------------------
-- Lehrer besuchen: gerade Level, nicht in Retail
---------------------------------------------------------------------------
local function trainerReminders()
  local found = 0
  for _, line in ipairs(wow.printed) do
    if line:find("neue Zauber beim Lehrer", 1, true) then found = found + 1 end
  end
  return found
end

addon.Set("remindTrainer", true)
expect("Retail: nicht verfügbar", addon.TrainerReminder.IsAvailable(), false)
wow.levelUp(12)
expect("Retail: still", trainerReminders(), 0)

wow.state.interface = 11509
wow.levelUp(13)
expect("ungerade: still", trainerReminders(), 0)
addon.Alerts.Clear()
wow.levelUp(14)
expect("gerade: Hinweis", trainerReminders(), 1)
expect("mit Level", LevelTimerNotice.body:GetText(), string.format(L.REMIND_TRAINER, 14))

wow.state.interface = 16001
expect("Forever: verfügbar", addon.TrainerReminder.IsAvailable(), true)

---------------------------------------------------------------------------
-- Munition knapp: nur Jäger, nicht in Retail
---------------------------------------------------------------------------
addon.Set("warnAmmo", true)
wow.state.inventoryCounts = { [0] = 150 }
wow.state.interface = 120105
GearWarnings.Check()
expect("Retail: still", count(L.WARN_AMMO), 0)

wow.state.interface = 11509
GearWarnings.Check()
expect("Krieger: still", count(L.WARN_AMMO), 0)

wow.state.class = "HUNTER"
GearWarnings.Check()
expect("Jäger: Warnung", count(L.WARN_AMMO), 1)
expect("Chat: Text mit Schusszahl", count(L.WARN_AMMO .. " (" .. string.format(L.AMMO_COUNT, 150) .. ")"), 1)
wow.state.inventoryCounts = { [0] = 1000 }
GearWarnings.Check()
wow.state.inventoryCounts = { [0] = 199 }
GearWarnings.Check()
expect("nach Auffüllen wieder", count(L.WARN_AMMO), 2)

-- WoW Forever: UnitUsesAmmo entscheidet (z.B. Jäger mit Waffe ohne Munition)
wow.state.interface = 16001
wow.state.inventoryCounts = { [0] = 1000 }
GearWarnings.Check()
UnitUsesAmmo = function() return false end
wow.state.inventoryCounts = { [0] = 150 }
GearWarnings.Check()
expect("Forever ohne Munitionsbedarf: still", count(L.WARN_AMMO), 2)
UnitUsesAmmo = function() return true end
GearWarnings.Check()
expect("Forever mit Munitionsbedarf: Warnung", count(L.WARN_AMMO), 3)
UnitUsesAmmo = nil

-- Munitions-Einstellungen nur für Jäger, nicht in Retail
wow.state.interface = 11509
wow.state.class = "WARRIOR"
expect("Krieger: keine Munitions-Optionen", GearWarnings.ShowsAmmoOptions(), false)
wow.state.class = "HUNTER"
expect("Jäger: Munitions-Optionen", GearWarnings.ShowsAmmoOptions(), true)
wow.state.interface = 120105
expect("Retail: keine Munitions-Optionen", GearWarnings.ShowsAmmoOptions(), false)
wow.state.interface = 11509

-- Einstellbare Grenze
wow.state.interface = 11509
wow.state.inventoryCounts = { [0] = 1000 }
GearWarnings.Check()
local before = count(L.WARN_AMMO)
addon.Set("ammoLow", 500)
wow.state.inventoryCounts = { [0] = 450 }
GearWarnings.Check()
expect("Grenze 500: bei 450 Warnung", count(L.WARN_AMMO), before + 1)
wow.state.inventoryCounts = { [0] = 1000 }
GearWarnings.Check()
addon.Set("ammoLow", 100)
wow.state.inventoryCounts = { [0] = 150 }
GearWarnings.Check()
expect("Grenze 100: bei 150 still", count(L.WARN_AMMO), before + 1)
expect("Grenze begrenzt", addon.Database.SanitizeSettings({ ammoLow = 5 }).ammoLow, 20)

-- Zweite Schwelle "fast leer" und Wiederholung
addon.Set("ammoLow", 200)
addon.Set("ammoCritical", 50)
addon.Set("ammoRepeat", 5)
wow.state.inventoryCounts = { [0] = 1000 }
GearWarnings.Check()
local low, critical = count(L.WARN_AMMO), count(L.WARN_AMMO_CRITICAL)
wow.state.inventoryCounts = { [0] = 150 }
GearWarnings.Check()
expect("knapp: Warnung", count(L.WARN_AMMO), low + 1)
expect("knapp: noch nicht fast leer", count(L.WARN_AMMO_CRITICAL), critical)
wow.advance(60)
GearWarnings.Check()
expect("nach 1 min noch keine Wiederholung", count(L.WARN_AMMO), low + 1)
wow.advance(5 * 60)
GearWarnings.Check()
expect("nach 5 min Wiederholung", count(L.WARN_AMMO), low + 2)
wow.state.inventoryCounts = { [0] = 40 }
GearWarnings.Check()
expect("fast leer: eigene Warnung", count(L.WARN_AMMO_CRITICAL), critical + 1)
expect("fast leer: nicht zusätzlich knapp", count(L.WARN_AMMO), low + 2)
wow.advance(5 * 60 + 1)
GearWarnings.Check()
expect("fast leer wiederholt", count(L.WARN_AMMO_CRITICAL), critical + 2)
addon.Set("ammoRepeat", 0)
wow.advance(60 * 60)
GearWarnings.Check()
expect("nur einmal: keine Wiederholung", count(L.WARN_AMMO_CRITICAL), critical + 2)

-- Schwelle 0: kein "fast leer"
addon.Set("ammoCritical", 0)
wow.state.inventoryCounts = { [0] = 1000 }
GearWarnings.Check()
wow.state.inventoryCounts = { [0] = 3 }
GearWarnings.Check()
expect("ohne Schwelle: kein fast leer", count(L.WARN_AMMO_CRITICAL), critical + 2)
expect("ohne Schwelle: normal knapp", count(L.WARN_AMMO), low + 3)

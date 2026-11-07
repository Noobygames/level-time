-- Schlafsack-Hinweis (WoW Forever): "Gemütlicher Schlafsack" (Item 211527) in der Tasche, unter Maximallevel und
-- ohne "Gut erholt" (Spell 429959) -> erinnern; mit Buff, auf Maximallevel, ohne Item und in Instanzen nicht
local BuffReminder = addon.BuffReminder
local L = addon.L
local BAG, WELL_RESTED, BAG_ICON = 211527, 429959, 133650

local function reminders()
  local count = 0
  for _, line in ipairs(wow.printed) do
    if line:find(L.REMIND_SLEEPING_BAG, 1, true) then count = count + 1 end
  end
  return count
end

local function remindAfterPause()
  wow.advance(301)
  addon.Alerts.Clear()
  BuffReminder.Check()
end

wow.state.itemIcons[BAG] = BAG_ICON
wow.state.itemCounts = { [BAG] = 1 }
wow.login({ level = 20 })
expectTrue("Forever: Einstellung vorhanden", BuffReminder.HasSleepingBagSystem())
expect("ohne Buff fehlt er", BuffReminder.IsSleepingBagMissing(), true)

BuffReminder.Check()
expect("aus: kein Hinweis", reminders(), 0)
addon.Set("remindSleepingBag", true)
addon.Alerts.Clear()
BuffReminder.Check()
expect("Schlafsack dabei, Buff fehlt: Hinweis", reminders(), 1)
expect("Karte: Text", LevelTimerNotice.body:GetText(), L.REMIND_SLEEPING_BAG)

-- Buff da (Erkennung über die Spell-ID, der Name darf geheim sein)
wow.state.buffs = { { name = "Gut erholt", spellId = WELL_RESTED, duration = 7200,
  expirationTime = GetTime() + 7000 } }
expect("Buff erkannt", BuffReminder.IsSleepingBagMissing(), false)
remindAfterPause()
expect("mit Buff: still", reminders(), 1)
wow.state.buffs = {}

-- Ohne Schlafsack in der Tasche
wow.state.itemCounts[BAG] = 0
expect("ohne Schlafsack: nicht zutreffend", BuffReminder.IsSleepingBagMissing(), nil)
remindAfterPause()
expect("ohne Schlafsack: still", reminders(), 1)
wow.state.itemCounts[BAG] = 1

-- In einer Instanz nicht
wow.state.instance = { name = "Die Todesminen", type = "party" }
remindAfterPause()
expect("Instanz: still", reminders(), 1)
wow.state.instance = nil

-- Maximallevel: nicht mehr
local isLeveling = addon.Experience.IsLeveling
addon.Experience.IsLeveling = function() return false end
remindAfterPause()
expect("Maximallevel: still", reminders(), 1)
addon.Experience.IsLeveling = isLeveling

-- Wieder alles erfüllt: Hinweis mit dem Symbol des Items
remindAfterPause()
expect("wieder erinnert", reminders(), 2)
expect("Symbol des Items", LevelTimerNotice.icon:GetTexture(), BAG_ICON)

-- Client ohne das Item: nichts behaupten
wow.state.itemIcons[BAG] = nil
expect("Item unbekannt: nil", BuffReminder.IsSleepingBagMissing(), nil)

-- Ausgaben nach Art: Reparatur, Händler, Flug (auch kurz nach dem Schließen der Karte), Lehrer, Sonstiges.
local Stats = addon.Stats

local function spend(amount)
  wow.state.money = wow.state.money - amount
  wow.fire("PLAYER_MONEY")
end

local function spent(counter)
  return Stats.Get(Stats.SESSION, counter)
end

wow.login({ money = 100000 })

-- Händler: Kauf und Reparatur (Blizzards Button ruft RepairAllItems)
wow.fire("MERCHANT_SHOW")
spend(300)
expect("Händlerkauf", spent(Stats.SPENT_MERCHANT), 300)
wow.state.merchant.repairCost = 700
RepairAllItems()
wow.runTimers()
expect("Reparatur", spent(Stats.SPENT_REPAIR), 700)
expect("nicht doppelt beim Händler", spent(Stats.SPENT_MERCHANT), 300)
wow.fire("MERCHANT_CLOSED")

-- Flug: Abbuchung kommt nach dem Schließen der Karte
wow.fire("TAXIMAP_OPENED")
wow.fire("TAXIMAP_CLOSED")
wow.advance(1)
spend(150)
expect("Flug", spent(Stats.SPENT_TAXI), 150)

-- Lange nach dem Schließen: Sonstiges (z.B. Post)
wow.advance(10)
spend(30)
expect("Sonstiges", spent(Stats.SPENT_OTHER), 30)

-- Lehrer
wow.fire("TRAINER_SHOW")
spend(1000)
wow.fire("TRAINER_CLOSED")
expect("Lehrer", spent(Stats.SPENT_TRAINER), 1000)

-- Einnahmen bleiben getrennt
local earned = spent(Stats.MONEY_EARNED)
wow.state.money = wow.state.money + 500
wow.fire("PLAYER_MONEY")
wow.runTimers()  -- Einnahme ohne Fenster wird erst nach der Wartezeit gebucht
expect("Einnahme", spent(Stats.MONEY_EARNED), earned + 500)
expect("Lehrer unverändert", spent(Stats.SPENT_TRAINER), 1000)

-- Reparatur ohne Abbuchung (zu wenig Gold): spätere Ausgaben zählen nicht als Reparatur
local repairs = spent(Stats.SPENT_REPAIR)
wow.fire("MERCHANT_SHOW")
wow.state.merchant.repairCost = 0
RepairAllItems()
wow.runTimers()
wow.fire("MERCHANT_CLOSED")
wow.advance(10)
spend(50)
expect("verfallen: Sonstiges statt Reparatur", spent(Stats.SPENT_REPAIR), repairs)

-- Automatische Reparatur und Schrott-Erlös
addon.Set("autoRepair", true)
addon.Set("autoSellJunk", true)
wow.state.sellPrices = { [1] = 40 }
wow.state.bags[0] = { [1] = { itemID = 1, quality = 0, stackCount = 2, hasNoValue = false, isLocked = false } }
wow.state.merchant.canRepair = true
wow.state.merchant.repairCost = 200
wow.fire("MERCHANT_SHOW")
wow.runTimers()
expect("Schrott-Erlös", spent(Stats.MONEY_JUNK), 80)
expect("automatische Reparatur", spent(Stats.SPENT_REPAIR), 900)

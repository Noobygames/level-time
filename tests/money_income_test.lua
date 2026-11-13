-- Geld (Roadmap 276): Einnahmen nach offenem Fenster, geteilte Beute über CHAT_MSG_MONEY, Zeiträume, Gold aller Charaktere.
local Stats = addon.Stats
local Money = addon.Money

-- Mittwoch, 14.10.2026 12:00
wow.state.clock = os.time({ year = 2026, month = 10, day = 14, hour = 12 })
wow.login({ money = 10000 })

local function earn(amount)
  wow.state.money = wow.state.money + amount
  wow.fire("PLAYER_MONEY")
end
local function spend(amount)
  wow.state.money = wow.state.money - amount
  wow.fire("PLAYER_MONEY")
end
local function income(counter) return Stats.Get(Stats.SESSION, counter) end

-- Beute im offenen Beutefenster
wow.fire("LOOT_OPENED")
earn(100)
wow.fire("LOOT_CLOSED")
expect("Beute", income(Stats.INCOME_LOOT), 100)

-- Quest: Gold kurz nach QUEST_TURNED_IN, ohne Fenster
wow.advance(10)
wow.fire("QUEST_TURNED_IN", 5, 0, 200)
earn(200)
expect("Quest", income(Stats.INCOME_QUEST), 200)

-- Händler, Post, Auktionshaus, Handel
wow.advance(10)
for _, case in ipairs({
  { "MERCHANT_SHOW", "MERCHANT_CLOSED", Stats.INCOME_MERCHANT, "Händler" },
  { "MAIL_SHOW", "MAIL_CLOSED", Stats.INCOME_MAIL, "Post" },
  { "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", Stats.INCOME_AUCTION, "Auktionshaus" },
  { "TRADE_SHOW", "TRADE_CLOSED", Stats.INCOME_TRADE, "Handel" },
}) do
  wow.fire(case[1])
  earn(300)
  wow.fire(case[2])
  wow.advance(10)
  expect(case[4], income(case[3]), 300)
end

-- Geteilte Beute: Meldung nach der Einnahme, eingeordnet nach kurzer Wartezeit
earn(50)
expect("noch nicht eingeordnet", income(Stats.INCOME_LOOT), 100)
wow.advance(0.5)
wow.fire("CHAT_MSG_MONEY", "Euer Anteil an der Beute: 50 Kupfer.")
wow.runTimers()
expect("geteilte Beute", income(Stats.INCOME_LOOT), 150)
-- Meldung vor der Einnahme: sofort Beute
wow.fire("CHAT_MSG_MONEY", "Ihr erbeutet 20 Kupfer.")
earn(20)
expect("Meldung vorher", income(Stats.INCOME_LOOT), 170)

-- Ohne Fenster und ohne Meldung: Sonstiges
wow.advance(10)
earn(40)
wow.runTimers()
expect("Sonstiges", income(Stats.INCOME_OTHER), 40)
expect("Summe aller Einnahmen", income(Stats.MONEY_EARNED), 100 + 200 + 4 * 300 + 50 + 20 + 40)
expect("aktuelles Gold gemerkt", addon.character.money, wow.state.money)

-- Ausgaben bleiben wie bisher
wow.fire("TAXIMAP_OPENED")
spend(500)
wow.fire("TAXIMAP_CLOSED")
expect("Flug", income(Stats.SPENT_TAXI), 500)

-- Zeiträume: heute = Woche = Monat; ein alter Tag im Vormonat zählt nur gesamt nicht (Gesamt aus den Leveln)
local daily = addon.character.dailyStats
daily["2026-09-30"] = { seconds = 3600, kills = 0, deaths = 0, xp = 0, moneyIn = 9999, moneyOut = 0 }
daily["2026-10-12"] = { seconds = 3600, kills = 0, deaths = 0, xp = 0, moneyIn = 1000, moneyOut = 100 }  -- Montag
daily["2026-10-11"] = { seconds = 3600, kills = 0, deaths = 0, xp = 0, moneyIn = 2000, moneyOut = 0 }   -- Sonntag davor
local records = Money.GetPeriodRecords(addon.characterKey)
local earnedToday = 100 + 200 + 4 * 300 + 50 + 20 + 40
expect("Zeilen", #records, 4)
expect("heute ein", records[1].moneyIn, earnedToday)
expect("heute aus", records[1].moneyOut, 500)
expect("Woche ab Montag", records[2].moneyIn, earnedToday + 1000)
expect("Monat", records[3].moneyIn, earnedToday + 1000 + 2000)
expect("Gesamt aus den Leveln", records[4].moneyIn, earnedToday)
expect("Gesamt Ausgaben", records[4].moneyOut, 500)
expect("Wochenbeginn Montag", Money.PeriodStart(Money.WEEK, wow.state.clock), os.time({ year = 2026, month = 10, day = 12, hour = 0 }))
expect("Monatsbeginn", Money.PeriodStart(Money.MONTH, wow.state.clock), os.time({ year = 2026, month = 10, day = 1, hour = 0 }))
expectNear("Gold/h", Money.PerHour(20000, 7200), 10000)

-- Gold aller Charaktere: Twink mit gemerktem Stand, einer ohne
LevelTimerStatsDB.characters["Twink-Testrealm"] = { money = 50000 }
LevelTimerStatsDB.characters["Alt-Testrealm"] = {}
local total, count = Money.TotalGold()
expect("Gold aller Charaktere", total, wow.state.money + 50000)
expect("Charaktere mit Stand", count, 2)
LevelTimerStatsDB.characters["Twink-Testrealm"] = nil
LevelTimerStatsDB.characters["Alt-Testrealm"] = nil

-- Stat-Zeilen: Einnahmen nach Art und Gold/h
addon.Set("showIncome", true)
local stat
for _, line in ipairs(addon.STAT_LINES) do if line.setting == "showIncome" then stat = line end end
expect("Beute-Zeile", stat.rows[1].value(Stats.SESSION), "170c")
expect("Gold/h-Zeile", type(stat.rows[8].value(Stats.SESSION)), "string")

-- Historie: Reiter Geld zeigt die Zeiträume und das Gold aller Charaktere
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Geld", wow.click("Geld"))
expectTrue("Geld-Tabelle", wow.shownTable() ~= nil)

-- Level-Up während der Wartezeit: Summe und Art landen im selben Level
wow.advance(10)
earn(30)
wow.levelUp(addon.level + 1)
wow.runTimers()
expect("Summe im neuen Level", Stats.Get(Stats.LEVEL, Stats.MONEY_EARNED), 30)
expect("Art im neuen Level", Stats.Get(Stats.LEVEL, Stats.INCOME_OTHER), 30)

-- Logout während der Wartezeit: die Einnahme geht nicht verloren
earn(20)
wow.logout()
expect("Summe beim Logout gebucht", Stats.Get(Stats.LEVEL, Stats.MONEY_EARNED), 50)
wow.runTimers()
expect("nicht doppelt gebucht", Stats.Get(Stats.LEVEL, Stats.MONEY_EARNED), 50)

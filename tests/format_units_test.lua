-- Roadmap 194: Einheiten von Zeit, Zahlen und Geld in der eingestellten Sprache, Wechsel wirkt sofort.
local Format = addon.Format

wow.login({ level = 10 })
local DAY, HOUR = 86400, 3600

addon.Set("language", "enUS")
expect("en Uhr", Format.Clock(2 * DAY + 3 * HOUR + 4 * 60 + 5), "2d 03h 04m 05s")
expect("en Dauer", Format.Duration(2 * DAY + 3 * HOUR), "2d 3h")
expect("en Tausend", Format.Number(12300), "12.3k")
expect("en Million", Format.Number(1200000), "1.2M")
expect("en Geld", Format.PlainMoney(23005), "2g 30s 5c")
expect("en Gold", Format.Gold(23005), "2g")

addon.Set("language", "deDE")
expect("de Tag", Format.Duration(2 * DAY + 3 * HOUR), "2T 3h")
expect("de Kupfer", Format.PlainMoney(23005), "2g 30s 5k")

addon.Set("language", "frFR")
expect("fr Tag", Format.Clock(DAY), "1j 00h 00m 00s")
expect("fr Geld", Format.PlainMoney(23005), "2po 30pa 5pc")

addon.Set("language", "esES")
expect("es Geld", Format.PlainMoney(23005), "2o 30p 5c")
expect("es Minuten", Format.Duration(65), "1m 05s")

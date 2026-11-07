-- Ruhe-XP der Twinks schätzen (Roadmap 271): Stand beim Logout, Hochrechnung offline, Meldung "voll ausgeruht".
local RestedEstimate = addon.RestedEstimate
local HOUR = 3600

-- Twink im Gasthaus ausgeloggt: 10 % Pool, nach 16 h +10 % -> 20 %
local now = wow.state.clock
LevelTimerStatsDB = { characters = {
  ["Twink-Testrealm"] = { schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = "Twink", realm = "Testrealm",
    currentLevel = { level = 20 },
    restSnapshot = { time = now - 16 * HOUR, rested = 1000, xpMax = 10000, resting = true, full = 1.5 } },
  ["Draussen-Testrealm"] = { schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = "Draussen", realm = "Testrealm",
    currentLevel = { level = 20 },
    restSnapshot = { time = now - 64 * HOUR, rested = 0, xpMax = 10000, resting = false, full = 1.5 } },
  ["Voll-Testrealm"] = { schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = "Voll", realm = "Testrealm",
    currentLevel = { level = 20 },
    restSnapshot = { time = now - 30 * 24 * HOUR, rested = 0, xpMax = 10000, resting = true, full = 1.5 } },
} }

wow.login({ level = 10, xp = 0, xpMax = 1000, rested = 500 })

expectNear("Gasthaus 16 h", (RestedEstimate.Get("Twink-Testrealm")), 0.2, 0.001)
expectNear("draußen 64 h = ein Viertel", (RestedEstimate.Get("Draussen-Testrealm")), 0.1, 0.001)
local share, isFull = RestedEstimate.Get("Voll-Testrealm")
expect("höchstens 150 %", share, 1.5)
expect("voll", isFull, true)
expect("Text voll", RestedEstimate.Text("Voll-Testrealm"), string.format(addon.L.RESTED_FULL_SHORT, "150%"))
expect("Text Twink", RestedEstimate.Text("Twink-Testrealm"), "20%")
expect("eingeloggter Charakter: echter Wert", (RestedEstimate.Get(addon.characterKey)), 0.5)

-- Meldung beim Login nur für volle Twinks, einmal
local function countPrinted(text)
  local count = 0
  for _, line in ipairs(wow.printed) do
    if line:find(text, 1, true) then count = count + 1 end
  end
  return count
end
expect("Meldung voller Twink", countPrinted(string.format(addon.L.RESTED_ALT_FULL, "Voll - Testrealm")), 1)
expect("keine Meldung für halb ausgeruhte", countPrinted(string.format(addon.L.RESTED_ALT_FULL, "Twink - Testrealm")), 0)
wow.logout()
wow.login()
expect("nur einmal je Logout des Twinks", countPrinted(string.format(addon.L.RESTED_ALT_FULL, "Voll - Testrealm")), 1)

-- Logout speichert den eigenen Stand
wow.state.resting = true
wow.logout()
local snapshot = addon.character.restSnapshot
expect("Pool gemerkt", snapshot.rested, 500)
expect("Bedarf gemerkt", snapshot.xpMax, 1000)
expect("im Gasthaus", snapshot.resting, true)
expect("Grenze 150 %", snapshot.full, 1.5)

-- Pandaren (Rassen-ID 24-26): doppelte Grenze
wow.state.race = { "Pandaren", "Pandaren", 26 }
wow.logout()
expect("Pandaren 300 %", addon.character.restSnapshot.full, 3)

-- Vergleich in der Historie hat die Spalte
local found = false
for _, record in ipairs(addon.History.GetCharacterComparison()) do
  if record.key == "Twink-Testrealm" then found = true end
end
expectTrue("Twink im Vergleich", found)

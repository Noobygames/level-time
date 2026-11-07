-- Toleranzband (gelb) und PB nur gegen Charaktere derselben Klasse.
local Splits = addon.Splits

local function otherCharacter(name, class, levels)
  LevelTimerStatsDB.characters[name .. "-Testrealm"] = {
    schemaVersion = addon.Database.CHARACTER_SCHEMA_VERSION, name = name, realm = "Testrealm", class = class,
    currentLevel = { level = 30, counters = {} }, levelHistory = levels, sessionHistory = {}, killLog = {}, deathLog = {},
  }
end

wow.login({ name = "Neu", level = 10, class = "WARRIOR", playedSeconds = 0 })
otherCharacter("Magier", "MAGE", { [10] = { level = 10, seconds = 1000 } })
otherCharacter("Krieger", "WARRIOR", { [10] = { level = 10, seconds = 2000 } })

-- Laufend 2010 s gegen Bestzeit 2000 s (Vergleich "best" ist 1000 s) -> zuerst PB
addon.Set("splitComparison", "pb")
expect("PB über alle Klassen", Splits.GetReference(10), 1000)
addon.Set("pbSameClass", true)
expect("PB nur Krieger", Splits.GetReference(10), 2000)

wow.advance(2010)
wow.fire("TIME_PLAYED_MSG", 2010, 2010)
expect("ohne Band rot", Splits.CurrentDeltaText(), "|cffff4040+10s|r")
addon.Set("splitTolerancePercent", 1)  -- 1 % von 2000 s = 20 s
expect("im Band gelb", Splits.CurrentDeltaText(), "|cffffd040+10s|r")
expect("Band", Splits.IsWithinTolerance(-20, 2000), true)
expect("außerhalb des Bands", Splits.IsWithinTolerance(21, 2000), false)
expect("mindestens 3 s", Splits.IsWithinTolerance(3, 10), true)
addon.Set("splitTolerancePercent", 0)
expect("0 % = aus", Splits.IsWithinTolerance(1, 2000), false)

-- Grenzen beim Import
local sanitized = addon.Database.SanitizeSettings({ splitTolerancePercent = 50 })
expect("Import begrenzt", sanitized.splitTolerancePercent, 10)

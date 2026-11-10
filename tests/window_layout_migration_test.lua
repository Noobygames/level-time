-- Settings-Migration v7: horizontalLayout/compactMode werden zu windowLayout, auch in Profilen; der Import alter
-- Profile zieht ebenfalls um.
LevelTimerDB = {
  schemaVersion = 6,
  horizontalLayout = true,
  compactMode = true,
  profiles = { Klein = { compactMode = true }, Normal = { horizontalLayout = false, compactMode = false } },
  streamBackup = { alertLevelUp = false, compactMode = true },
}
wow.login()
local db = LevelTimerDB
expect("Schema", db.schemaVersion, 8)
expect("Leiste gewinnt", db.windowLayout, "bar")
expect("alter Schlüssel weg", db.horizontalLayout, nil)
expect("alter Schlüssel weg (kompakt)", db.compactMode, nil)
expect("Profil kompakt", db.profiles.Klein.windowLayout, "compact")
expect("Profil ohne Schalter: Standard", db.profiles.Normal.windowLayout, nil)
expect("Profil: alter Schlüssel weg", db.profiles.Normal.compactMode, nil)
expect("Stream-Sicherung ohne alten Schlüssel", db.streamBackup.compactMode, nil)
expect("Fenster als Leiste", addon.TimerWindow.ActiveLayout(), "bar")

-- Import eines alten Profils
local clean = addon.Database.SanitizeSettings({ compactMode = true, showXpRate = false })
expect("Import: kompakt", clean.windowLayout, "compact")
expect("Import: alter Schlüssel weg", clean.compactMode, nil)

-- Unbekanntes Layout (z.B. aus einer neueren Version): Tabelle
addon.Set("windowLayout", "gibtsnicht")
expect("unbekannt: Tabelle", addon.TimerWindow.ActiveLayout(), "table")
expect("Fehlerfrei", #wow.errors, 0)

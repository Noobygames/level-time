-- Einstellungs-Migration v4: Level-Up-Ansage in /sagen gibt es nicht mehr, alte Werte werden "off",
-- auch in gespeicherten Profilen.
LevelTimerDB = {
  schemaVersion = 3,
  levelUpAnnounce = "say",
  lootSparkleStyle = "aura",  -- alter Standard, wurde mit abgespeichert
  transportShare = false,     -- alter Standard
  profiles = {
    Stream = { levelUpAnnounce = "say", lootSparkleStyle = "aura", transportShare = false },
    Gilde = { levelUpAnnounce = "guild", lootSparkleStyle = "beam" },
  },
}
wow.login()
expect("Ansage aus", LevelTimerDB.levelUpAnnounce, "off")
expect("Profil mit /sagen aus", LevelTimerDB.profiles.Stream.levelUpAnnounce, "off")
expect("anderes Profil bleibt", LevelTimerDB.profiles.Gilde.levelUpAnnounce, "guild")
expect("Schema aktuell", LevelTimerDB.schemaVersion, 9)
-- Migration v8: Glitzerstil "aura" (alter Standard) wird zum neuen Standard "finder", andere Wahlen bleiben
expect("Glitzerstil: alter Standard wird Zielsucher", LevelTimerDB.lootSparkleStyle, "finder")
expect("Glitzerstil im Profil: alter Standard wird Zielsucher", LevelTimerDB.profiles.Stream.lootSparkleStyle, "finder")
expect("Glitzerstil im Profil: eigene Wahl bleibt", LevelTimerDB.profiles.Gilde.lootSparkleStyle, "beam")
-- Migration v9: Schiffs- und Zeppelinzeiten teilen ist für alle an, auch in Profilen
expect("Transport teilen an", LevelTimerDB.transportShare, true)
expect("Transport teilen im Profil an", LevelTimerDB.profiles.Stream.transportShare, true)

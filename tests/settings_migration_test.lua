-- Einstellungs-Migration v4: Level-Up-Ansage in /sagen gibt es nicht mehr, alte Werte werden "off",
-- auch in gespeicherten Profilen.
LevelTimerDB = {
  schemaVersion = 3,
  levelUpAnnounce = "say",
  lootSparkleStyle = "aura",  -- alter Standard, wurde mit abgespeichert
  profiles = {
    Stream = { levelUpAnnounce = "say", lootSparkleStyle = "aura" },
    Gilde = { levelUpAnnounce = "guild", lootSparkleStyle = "beam" },
  },
}
wow.login()
expect("Ansage aus", LevelTimerDB.levelUpAnnounce, "off")
expect("Profil mit /sagen aus", LevelTimerDB.profiles.Stream.levelUpAnnounce, "off")
expect("anderes Profil bleibt", LevelTimerDB.profiles.Gilde.levelUpAnnounce, "guild")
expect("Schema aktuell", LevelTimerDB.schemaVersion, 8)
-- Migration v8: Glitzerstil "aura" (alter Standard) wird zum neuen Standard "finder", andere Wahlen bleiben
expect("Glitzerstil: alter Standard wird Zielsucher", LevelTimerDB.lootSparkleStyle, "finder")
expect("Glitzerstil im Profil: alter Standard wird Zielsucher", LevelTimerDB.profiles.Stream.lootSparkleStyle, "finder")
expect("Glitzerstil im Profil: eigene Wahl bleibt", LevelTimerDB.profiles.Gilde.lootSparkleStyle, "beam")

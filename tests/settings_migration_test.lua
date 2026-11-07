-- Einstellungs-Migration v4: Level-Up-Ansage in /sagen gibt es nicht mehr, alte Werte werden "off",
-- auch in gespeicherten Profilen.
LevelTimerDB = {
  schemaVersion = 3,
  levelUpAnnounce = "say",
  profiles = { Stream = { levelUpAnnounce = "say" }, Gilde = { levelUpAnnounce = "guild" } },
}
wow.login()
expect("Ansage aus", LevelTimerDB.levelUpAnnounce, "off")
expect("Profil mit /sagen aus", LevelTimerDB.profiles.Stream.levelUpAnnounce, "off")
expect("anderes Profil bleibt", LevelTimerDB.profiles.Gilde.levelUpAnnounce, "guild")
expect("Schema aktuell", LevelTimerDB.schemaVersion, 6)

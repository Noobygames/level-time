-- Gespeicherte Positionen bleiben beim Laden unverändert, auch bei Größe ungleich 100 %: die Abstände
-- gelten schon in dieser Größe (sonst würden sie bei jedem Login umgerechnet und wanderten).
-- Alte Schlüssel (alertPos/alertScale, campPos/campScale) ziehen dabei nach frames um (Migration v6).
LevelTimerDB = {
  alertScale = 0.5, alertPos = { "TOP", "TOP", 100, -200 },
  campScale = 1.5, campPos = { "TOP", "TOP", 30, -60 },
}
wow.login({ level = 30 })
local frames = LevelTimerDB.frames
expect("alte Schlüssel entfernt", LevelTimerDB.alertPos, nil)
expect("Einblendung: x unverändert", frames.alert.x, 100)
expect("Einblendung: y unverändert", frames.alert.y, -200)
expect("Lagerfeuer: x unverändert", frames.camp.x, 30)
expect("Lagerfeuer: y unverändert", frames.camp.y, -60)
expect("Einblendung: Größe", LevelTimerAlert:GetScale(), 0.5)
expect("Lagerfeuer: Größe", LevelTimerCamp:GetScale(), 1.5)

-- Reload: noch einmal, nichts wandert
wow.logout()
wow.login()
expect("nach Reload: x", LevelTimerDB.frames.alert.x, 100)
expect("nach Reload: Lagerfeuer y", LevelTimerDB.frames.camp.y, -60)

-- Größe ändern bei stehender Position: Abstände werden umgerechnet
addon.Frames.SetScale("camp", 2)
expect("Größe 1,5 -> 2: x umgerechnet", LevelTimerDB.frames.camp.x, 22.5)

-- Profilwechsel: die Position des neuen Profils bleibt, wie sie gespeichert wurde (auch mit alten Schlüsseln)
LevelTimerDB.profiles.Zweit = { campScale = 0.5, campPos = { "TOP", "TOP", 10, -20 } }
addon.Profiles.Switch("Zweit")
expect("Profil: x unverändert", LevelTimerDB.frames.camp.x, 10)
expect("Profil: Größe", LevelTimerCamp:GetScale(), 0.5)

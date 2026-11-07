-- Einstellungs-Profile von Level Time: benannte Sätze von Einstellungen, je Charakter eines gewählt
-- (Logik in Lib/ProfileStore.lua). ns.db (LevelTimerDB) bleibt der aktive Stand; Profile sind Kopien in
-- LevelTimerDB.profiles. Beim Wechsel und beim Logout wird der aktive Stand ins aktive Profil zurückgeschrieben,
-- beim Login lädt jeder Charakter sein Profil (LevelTimerDB.characterProfiles).
local _, ns = ...
local L = ns.L

local Profiles = ns.ProfileStore.New({
  db = function() return ns.db end,
  characterKey = function() return ns.characterKey end,
  normalize = function(db)
    ns.Database.MoveLegacyKeys(db)  -- Profil aus einer älteren Version (Positionen je Anzeige, Anordnung)
    ns.Database.ApplySettingDefaults(db)
  end,
  sanitize = function(settings) return ns.Database.SanitizeSettings(settings) end,
  apply = function() ns.ApplySettings() end,
  -- cvarOriginals: Werte des Spielers vor unseren CVar-Änderungen (CVars.lua), gehören zum Account, nicht zum Profil
  metaKeys = { "cvarOriginals" },
  defaultName = "Default",  -- angezeigt als L.PROFILE_DEFAULT
  defaultLabel = function() return L.PROFILE_DEFAULT end,
  debug = function(fmt, ...) ns.Debug("profiles", fmt, ...) end,
})
ns.Profiles = Profiles

-- Login: Profil des Charakters laden (vor dem ersten ApplySettings, also vor allen Fenstern)
ns.OnLogin(Profiles.LoadForCharacter)

ns.OnLogout(Profiles.StoreActive)

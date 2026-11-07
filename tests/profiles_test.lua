-- Einstellungs-Profile: speichern, wechseln, je Charakter merken, teilen, löschen.
local L = addon.L
local Profiles = addon.Profiles

wow.login({ name = "Erster" })
expect("Standard aktiv", Profiles.GetActive(), "Default")
addon.Set("scale", 1.2)

-- Aktuellen Stand als neues Profil speichern
SlashCmdList.LEVELTIMER("profile save Stream")
expect("neues Profil aktiv", Profiles.GetActive(), "Stream")
addon.Set("windowBackground", "green")
addon.Set("scale", 1.5)

-- Zurück zum Standard: dessen Werte, Stream behält seine
SlashCmdList.LEVELTIMER("profile Default")
expect("Standard: Größe", LevelTimerDB.scale, 1.2)
expect("Standard: Hintergrund", LevelTimerDB.windowBackground, "default")
expect("Fenster folgt", LevelTimerFrame:GetScale(), 1.2)
SlashCmdList.LEVELTIMER("profile Stream")
expect("Stream: Größe", LevelTimerDB.scale, 1.5)
expect("Stream: Hintergrund", LevelTimerDB.windowBackground, "green")

-- Profilwechsel setzt das Fenster an die Stelle des Profils, eine Größenänderung danach behält sie
LevelTimerDB.profiles.Default.pos = { "TOPLEFT", "TOPLEFT", 120, -80 }
SlashCmdList.LEVELTIMER("profile Default")
local anchor = LevelTimerFrame._points[1]
expect("Position des Profils", anchor[1] .. " " .. anchor[4] .. " " .. anchor[5], "TOPLEFT 120 -80")
expect("Position bleibt im Profil", LevelTimerDB.pos[3], 120)
SlashCmdList.LEVELTIMER("profile Stream")

-- Jeder Charakter merkt sich sein Profil
wow.logout()
wow.login({ name = "Zweiter" })
expect("neuer Charakter ohne Wahl: Standardprofil", Profiles.GetActive(), "Default")
SlashCmdList.LEVELTIMER("profile Default")
expect("zweiter Charakter: Standard", LevelTimerDB.scale, 1.2)
wow.logout()
wow.login({ name = "Erster" })
expect("erster lädt Stream", Profiles.GetActive(), "Stream")
expect("mit seinen Werten", LevelTimerDB.windowBackground, "green")
wow.logout()
wow.login({ name = "Zweiter" })
expect("zweiter lädt Standard", Profiles.GetActive(), "Default")
expect("mit Standard-Werten", LevelTimerDB.windowBackground, "default")

-- Profile als Text: in anderem Client importieren, Name wird nicht überschrieben
local text = Profiles.Export("Stream")
local imported = Profiles.Import(text)
expect("vorhandener Name bekommt Zusatz", imported, "Stream 2")
Profiles.Switch(imported)
expect("importierte Werte", LevelTimerDB.windowBackground, "green")
expect("Ungültiges abgelehnt", Profiles.Import("LT1:run:{}"), nil)

-- Löschen: nicht Standard, nicht das aktive
expect("aktives nicht löschbar", Profiles.Delete("Stream 2"), false)
expect("Standard nicht löschbar", Profiles.Delete("Default"), false)
-- Roadmap 200/201: /lt profile delete fragt wie die Oberfläche nach
wow.popup = nil
SlashCmdList.LEVELTIMER("profile delete Stream")
expectTrue("Stream nicht sofort gelöscht", LevelTimerDB.profiles.Stream ~= nil)
expect("Rückfrage per Befehl", wow.popup and wow.popup.data, "Stream")
StaticPopupDialogs[wow.popup.name].OnAccept(nil, wow.popup.data)
expect("Stream gelöscht", LevelTimerDB.profiles.Stream, nil)
expectTrue("Löschen gemeldet", wow.printed[#wow.printed]:find(string.format(L.PROFILE_DELETED, "Stream"), 1, true) ~= nil)
wow.popup = nil
SlashCmdList.LEVELTIMER("profile delete Default")
expect("Standard: keine Rückfrage", wow.popup, nil)
expectTrue("Standard: gemeldet", wow.printed[#wow.printed]:find(L.PROFILE_NOT_DELETED, 1, true) ~= nil)
-- /lt profile save mit vorhandenem Namen fragt vor dem Überschreiben
SlashCmdList.LEVELTIMER("profile save Stream 2")
expect("Überschreiben: Rückfrage", wow.popup and wow.popup.data, "Stream 2")
wow.popup = nil
wow.logout()
wow.login({ name = "Erster" })
expect("Charakter mit gelöschtem Profil: unverändert weiter", LevelTimerDB.profiles.Stream, nil)

-- Reiter in den Einstellungen
SlashCmdList.LEVELTIMER("config")
expectTrue("Reiter Profile", wow.click(L.OPTIONS_TAB_PROFILES))
-- "Standard" heißt auch der Fenster-Hintergrund, daher den Listeneintrag über sein Profil suchen
local defaultEntry = wow.findFrame(function(frame) return rawget(frame, "profileName") == "Default" end)
expect("Standard in der Liste", defaultEntry.label._text, L.PROFILE_DEFAULT)
defaultEntry._scripts.OnClick(defaultEntry, "LeftButton")
expect("Klick wechselt", Profiles.GetActive(), "Default")

-- Rechtsklick löscht nach Rückfrage
local streamEntry = wow.findFrame(function(frame) return rawget(frame, "profileName") == "Stream 2" end)
streamEntry._scripts.OnClick(streamEntry, "RightButton")
expect("Rückfrage", wow.popup.data, "Stream 2")
StaticPopupDialogs[wow.popup.name].OnAccept(nil, wow.popup.data)
expect("per Rechtsklick gelöscht", LevelTimerDB.profiles["Stream 2"], nil)

-- Import prüft Werte: falsche Typen und unbekannte Schlüssel fallen weg
local bad = addon.Serializer.Encode("profile", { name = "Kaputt", settings = {
  scale = "riesig", bgAlpha = 0.5, unknownKey = 1, minimap = { hide = "ja", angle = 90 },
  pos = { "CENTER", "CENTER", "x", 0 }, splitListPos = { "TOPLEFT", "TOPLEFT", 10, -10 },
} })
local badName = Profiles.Import(bad)
local badSettings = LevelTimerDB.profiles[badName]
expect("falscher Typ entfernt", badSettings.scale, nil)
expect("gültiger Wert bleibt", badSettings.bgAlpha, 0.5)
expect("unbekannter Schlüssel entfernt", badSettings.unknownKey, nil)
expect("verschachtelt geprüft", badSettings.minimap.hide, nil)
expect("verschachtelt gültig", badSettings.minimap.angle, 90)
expect("kaputte Position entfernt", badSettings.pos, nil)
expect("gültige Position bleibt", badSettings.splitListPos[3], 10)
Profiles.Switch(badName)
expect("Profil lädt mit Defaults", LevelTimerDB.scale, 1)
expect("leerer Name abgelehnt", Profiles.Import(addon.Serializer.Encode("profile", { name = "", settings = {} })), nil)

-- Der angezeigte Name des Standardprofils funktioniert auch als Befehl (deDE: "Standard")
SlashCmdList.LEVELTIMER("profile Stream")
SlashCmdList.LEVELTIMER("profile standard")
expect("übersetzter Standardname", Profiles.GetActive(), "Default")
expect("kein zweites Standardprofil", LevelTimerDB.profiles.Standard, nil)

-- Mehr Profile als Zeilen: per Mausrad erreichbar
for index = 1, 8 do LevelTimerDB.profiles["Zusatz " .. index] = {} end
SlashCmdList.LEVELTIMER("config")
wow.click(L.OPTIONS_TAB_PROFILES)
local function listed(name)
  return wow.findFrame(function(frame) return rawget(frame, "profileName") == name and frame:IsShown() end) ~= nil
end
expect("Zusatz 8 erst nicht sichtbar", listed("Zusatz 8"), false)
local firstRow = wow.findFrame(function(frame) return rawget(frame, "profileName") == "Default" end)
for _ = 1, 10 do firstRow._scripts.OnMouseWheel(firstRow, -1) end
expect("nach dem Scrollen sichtbar", listed("Zusatz 8"), true)

-- Speichern: leerer Name meldet sich, vorhandener Name fragt vor dem Überschreiben nach
SlashCmdList.LEVELTIMER("config")
wow.click(addon.L.OPTIONS_TAB_PROFILES or "Profile")
local saveButton = wow.findFrame(function(frame)
  local label = rawget(frame, "label")
  return label and label._text == L.PROFILE_SAVE
end)
expectTrue("Speichern-Button", saveButton ~= nil)
local before = #wow.printed
saveButton._scripts.OnClick(saveButton)
expectTrue("leerer Name gemeldet", wow.printed[#wow.printed]:find(L.PROFILE_NAME_EMPTY, 1, true) ~= nil)
expect("Profil-Exists", Profiles.Exists("Default"), true)
expect("Profil-Exists (unbekannt)", Profiles.Exists("Gibtsnicht"), false)

-- Import unter dem Anzeigenamen des Standardprofils ("Standard") wird nicht unerreichbar abgelegt
local fromDefaultName = Profiles.Import(addon.Serializer.Encode("profile", { name = addon.L.PROFILE_DEFAULT, settings = {} }))
expectTrue("Import 'Standard': eigener Name", fromDefaultName ~= nil and fromDefaultName ~= addon.L.PROFILE_DEFAULT)
expectTrue("Import 'Standard': wählbar", Profiles.Exists(fromDefaultName))

-- Positionen: nur gültige Ankerpunkte und endliche Offsets; die Größe der Split-Liste bleibt erhalten (begrenzt)
local sane = addon.Database.SanitizeSettings({
  pos = { "FOO", "CENTER", 0, 0 }, alertPos = { "CENTER", "CENTER", math.huge, 0 },
  campPos = { "TOP", "TOP", 5, -10 }, splitListScale = 9,
})
expect("unbekannter Anker verworfen", sane.pos, nil)
expect("unendlicher Offset verworfen", sane.alertPos, nil)
expect("gültige Position bleibt", sane.campPos[3], 5)
expect("splitListScale bleibt, begrenzt", sane.splitListScale, 2)
expect("splitListScale ohne Zahl verworfen", addon.Database.SanitizeSettings({ splitListScale = "groß" }).splitListScale, nil)

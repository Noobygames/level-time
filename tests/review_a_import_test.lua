-- Review A: Profilimport (streamBackup, tableColumns), 0-s-Level, Profilnutzer gelöschter Charaktere
local addon = wow.addon or addon
wow.login()

local Profiles = addon.Profiles
local name = Profiles.Import(addon.Serializer.Encode("profile", { name = "Boese", settings = {
  streamBackup = { inviteFromWhisper = true },
  tableColumns = { loot = 5, rolls = { Level = true, Bad = "x", [3] = true }, [7] = {} },
} }))
local imported = LevelTimerDB.profiles[name]
expect("streamBackup nicht importiert", imported.streamBackup, nil)
expect("tableColumns Zahl verworfen", imported.tableColumns.loot, nil)
expect("tableColumns Boolean bleibt", imported.tableColumns.rolls.Level, true)
expect("tableColumns Nicht-Boolean verworfen", imported.tableColumns.rolls.Bad, nil)

expectTrue("0 s gültig", addon.Runs.IsValidSeconds(0))
expect("negativ ungültig", addon.Runs.IsValidSeconds(-1), false)

LevelTimerDB.characterProfiles["Geloescht-Realm"] = name
for _, key in ipairs(Profiles.CharactersOf(name)) do
  expectTrue("gelöschter Charakter nicht gezählt", key ~= "Geloescht-Realm")
end
expect("DisplayName unbekannt", addon.History.DisplayName("Geloescht-Realm"), "?")

-- Zu breite festgelegte Spalten werden auf den Platz gekürzt (kein Überstand aus dem Fenster)
local wide = {}
for i = 1, 4 do wide[i] = { header = "TEST_W" .. i, width = 200, value = function() return "x" end } end
local view = addon.TableView.Create({ tab = "REVIEW_A", columns = wide,
  records = function() return { {} } end, footer = function() return {} end })
local frame = view.Create(UIParent, 540, 300)
frame:Render(addon.characterKey, true, true)
local cells = wow.findFrame(function(f) local c = rawget(f, "cells") return c and #c == 4 end).cells
local total = 0
for _, cell in ipairs(cells) do total = total + cell:GetWidth() + 6 end
expectTrue("Tabelle passt ins Fenster", total <= 540 - 6 - 8)

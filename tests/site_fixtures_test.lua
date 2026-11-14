-- Testdaten der Auswertungs-Seite (docs/site): echte Texte aus Serializer und CSV-Export des Addons.
-- docs/site/site.test.js liest dieselben Dateien und prüft, dass die Seite sie wie der Lua-Code versteht.
-- Ändert sich ein Format, schlägt dieser Test fehl; dann die Dateien neu schreiben (WRITE = true, einmal laufen
-- lassen, zurück auf false) und die Seite anpassen.
local WRITE = false
local DIR = wow.ADDON_DIR .. "/docs/site/testdata/"

local function check(file, text)
  local path = DIR .. file
  if WRITE then
    local handle = assert(io.open(path, "wb"))
    handle:write(text)
    handle:close()
  end
  local handle = io.open(path, "rb")
  local stored = handle and handle:read("*a")
  if handle then handle:close() end
  expect("Testdatei " .. file .. " passt zum Addon", stored, text)
end

-- Zwei Läufe im Format von Runs.ExportAll (shareable), mit Sonderzeichen, Kommazahlen und fehlendem Realm
local runs = {
  { name = "Zwergö", realm = "Die Aldor", class = "WARRIOR", reachedLevel = 5, coverage = 0.95,
    category = "solo", check = "a1b2", checkFrom = 1, checkTo = 4,
    times = { [1] = 120, [2] = 300.5, [3] = 480, [4] = 610 } },
  { name = "Elfe | 100% {x=1}", class = "HUNTER", reachedLevel = 4, times = { [1] = 100, [2] = 350, [3] = 420 } },
}
check("runs.lt1", addon.Serializer.Encode("runs", runs))

-- Level-Tabelle wie TableView:BuildCsv (Zellen über Format), einmal mit ";" und einmal mit ","
local Format = addon.Format
local headers = { "Level", "Zeit", "XP/h", "Gold", "Zone" }
local rows = {
  { "1", Format.Duration(95), Format.Number(850), Format.Gold(1234), "Kalimdor; Teldrassil" },
  { "2*", Format.Duration(3725), Format.Number(12345), Format.Gold(567890), 'Zone "Nord"' },
  { "3", Format.Duration(2 * 86400 + 3 * 3600), Format.Number(2500000), Format.Gold(0), "Durotar" },
}
check("levels_semicolon.csv", addon.Export.ToCsv(headers, rows, ";"))
check("levels_comma.csv", addon.Export.ToCsv(headers, rows, ","))

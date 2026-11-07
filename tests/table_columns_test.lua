-- UX 203: Spaltenköpfe werden nicht abgeschnitten: jede Spalte mindestens so breit wie ihr Kopf (samt Sortierzeichen),
-- die Tabelle behält ihre Gesamtbreite (Spalten mit Spielraum geben ab); neu bei Sprachwechsel; Tooltip mit dem Kopf.
addon.locales.deDE.TEST_NARROW = "Eine sehr lange Überschrift"
addon.locales.deDE.TEST_WIDE = "Name"
addon.locales.deDE.TEST_NUMBER = "Zahl"
addon.locales.enUS.TEST_NARROW = "Short"
addon.locales.enUS.TEST_WIDE = "Name"
addon.locales.enUS.TEST_NUMBER = "Number"

wow.login()
local columns = {
  { header = "TEST_NARROW", width = 40, value = function(r) return r.a end },
  { header = "TEST_WIDE", width = 300, align = "LEFT", value = function(r) return r.b end },
  { header = "TEST_NUMBER", width = 60, value = function(r) return r.c end },
}
local view = addon.TableView.Create({
  tab = "TEST_WIDE", columns = columns,
  records = function() return { { a = "1", b = "x", c = "2" } } end,
  footer = function() return {} end,
})
local frame = view.Create(UIParent, 400, 300)
frame:Render(addon.characterKey, true, true)

local function headerCells()
  return wow.findFrame(function(f)
    local cells = rawget(f, "cells")
    return cells and cells[1] and cells[1]._text:find(addon.L.TEST_NARROW, 1, true) ~= nil
  end).cells
end

local cells = headerCells()
local textWidth = cells[1]:GetStringWidth()
expectTrue("schmale Spalte passt ihren Kopf", cells[1]:GetWidth() >= textWidth)
local total = 0
for _, cell in ipairs(cells) do total = total + cell:GetWidth() end
expect("Gesamtbreite bleibt", total, 400 - 3 * 6)
expectTrue("breite Spalte gibt ab", cells[2]:GetWidth() < 300 - 6)

-- Sprachwechsel: neu angepasst
addon.Set("language", "enUS")
frame:Render(addon.characterKey, false, true)
cells = headerCells()
expect("kurzer Kopf: Ausgangsbreite", cells[1]:GetWidth(), math.max(40, #"Short" * 6 + 6 + 10) - 6)

expect("keine Fehler", #wow.errors, 0)

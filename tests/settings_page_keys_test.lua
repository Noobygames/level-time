-- LT-61: Jede Anzeige mit settingsPage (Rechtsklick, Edit-Modus-Knopf) verweist auf einen echten Reiter oder eine
-- echte Unterseite der Einstellungen; ein unbekannter Key öffnete bisher nur die zuletzt gezeigte Seite.
wow.login()
local Frames = addon.Frames

local known = {}
for _, page in ipairs(addon.OptionsWindow.PageKeys()) do
  known[page.tab] = true
  if page.sub then known[page.sub] = true end
end

local checked = { count = 0 }
local regs = Frames.All()
-- Auch flavorabhängige Anzeigen prüfen, die Frames.All in diesem Client ausblendet
for _, id in ipairs({ "swingTimer", "targetRange" }) do table.insert(regs, Frames.Get(id)) end
for _, reg in ipairs(regs) do
  if reg.settingsPage then
    expectTrue(tostring(reg.id) .. ": Seite " .. reg.settingsPage .. " existiert", known[reg.settingsPage])
    checked.count = checked.count + 1
  end
end
expectTrue("Anzeigen geprüft", checked.count > 5)

-- Das Änderungsprotokoll schließt mit Esc
local escFrames = {}
for _, name in ipairs(UISpecialFrames) do escFrames[name] = true end
expectTrue("Änderungsprotokoll schließt mit Esc", escFrames.LevelTimerChangelog)

expect("keine Fehler", #wow.errors, 0)

-- Vorschau-Knöpfe in den Einstellungen (ns.Frames.Preview): Beispielinhalt jeder verschiebbaren Anzeige für ein
-- paar Sekunden, danach wieder aus; im Edit-Modus bleibt die Vorschau stehen
local Frames = addon.Frames

wow.login({ level = 20 })

-- Anmeldung mit mitgezählter Vorschau
local shown = {}
local probe = CreateFrame("Frame", nil, UIParent)
Frames.Register({ id = "previewProbe", frame = probe, label = "EDIT_FRAME_MAIN",
  default = { "CENTER", "CENTER", 0, 0 }, preview = function(on) table.insert(shown, on) end })

expect("ohne Anmeldung keine Vorschau", Frames.Preview("unknown"), false)
expectTrue("Vorschau startet", Frames.Preview("previewProbe"))
expect("an", shown[1], true)
expectTrue("erneuter Klick verlängert", Frames.Preview("previewProbe"))
wow.runTimers()   -- Stub: alle Fristen auf einmal; die erste gehört zum alten Klick und zählt nicht
expect("einmal aus", #shown, 3)
expect("danach aus", shown[3], false)

-- Edit-Modus läuft: die Frist blendet nichts aus
Frames.Preview("previewProbe")
addon.EditMode.Toggle()
wow.runTimers()
expect("im Edit-Modus bleibt die Vorschau", shown[#shown], true)
addon.EditMode.Toggle()

-- Jede Anzeige mit Knopf in den Einstellungen hat eine Vorschau
for _, id in ipairs({ "main", "questItem", "targetRange", "lootRolls", "splitList", "obsSignal", "spellHistory" }) do
  expectTrue("Vorschau für " .. id, Frames.Get(id) ~= nil and Frames.Get(id).preview ~= nil)
end
expect("keine Fehler", #wow.errors, 0)

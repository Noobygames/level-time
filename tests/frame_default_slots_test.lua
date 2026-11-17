-- Standardpositionen: keine zwei Anzeigen starten an derselben Stelle (nie verschobene Anzeigen liegen sonst übereinander)
wow.login({ level = 10 })

local seen = {}
for _, reg in ipairs(addon.Frames.All()) do
  local key = table.concat({ reg.default[1], reg.default[2], reg.default[3], reg.default[4] }, ",")
  expectTrue("Standardposition frei: " .. reg.id .. " (belegt von " .. tostring(seen[key]) .. ")", seen[key] == nil)
  seen[key] = reg.id
end

-- Eine Anzeige aus der Slot-Tabelle nimmt ihren Slot, eine verschobene behält die eigene Stelle
local point, _, x, y = addon.Frames.GetPosition("camp")
expect("Slot: Lagerfeuer", point .. x .. y, "TOP-330-230")

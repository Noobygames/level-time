-- Roadmap 461: Kartenbereiche der WoW Forever (Durotar 1411, Mulgore 1412), ohne Client-API
local Coords = addon.MapCoords
wow.login({ level = 20 })
C_Map = nil

for _, mapID in ipairs({ 1411, 1412 }) do
  local width, height = Coords.Size(mapID)
  expectTrue("Zone " .. mapID .. " hat Größe", width and width > 1000 and height and height > 1000)
  local instance, wx, wy = Coords.MapToWorld(mapID, 0.5, 0.5)
  expectTrue("Zone " .. mapID .. " Instanz", instance == 1)
  local x, y = Coords.WorldToMap(mapID, wx, wy)
  expectNear("Rundreise x " .. mapID, x, 0.5, 1e-6)
  expectNear("Rundreise y " .. mapID, y, 0.5, 1e-6)
end

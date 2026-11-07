-- Leichenpfeil (Roadmap 351): nur als Geist, Richtung relativ zur Blickrichtung, Entfernung in Metern aus der
-- Weltgröße der Karte; ohne Position (Instanz) kein Pfeil.
local L = addon.L
local CorpseArrow = addon.CorpseArrow

local corpse = { 0.5, 0.4 }
local player = { 0.5, 0.5 }
local facing = { value = 0 }
local function vector(x, y) return { GetXY = function() return x, y end } end
function CreateVector2D(x, y) return vector(x, y) end
C_Map = {
  GetBestMapForUnit = function() return 1429 end,
  GetPlayerMapPosition = function() return player and vector(player[1], player[2]) end,
  -- Karte 1000 m breit, 600 m hoch (Weltachsen wie im Client vertauscht)
  GetWorldPosFromMapPos = function(_, position)
    local x, y = position:GetXY()
    return 0, vector(-y * 600, -x * 1000)
  end,
}
C_DeathInfo.GetCorpseMapPosition = function() return corpse and vector(corpse[1], corpse[2]) end
function GetPlayerFacing() return facing.value end

wow.login({ level = 20 })
addon.Set("corpseArrow", true)
expect("lebend: kein Pfeil", LevelTimerCorpseArrow, nil)

-- Freigelassen: Geist
wow.state.ghost = true
wow.fire("PLAYER_ALIVE")
expectTrue("Geist: Pfeil", LevelTimerCorpseArrow:IsShown())
local rotation, distance = CorpseArrow.Direction()
expectNear("Leiche im Norden, Blick nach Norden: geradeaus", rotation, 0)
expectNear("60 Meter", distance, 60)
expect("Entfernung angezeigt", LevelTimerCorpseArrow.distance:GetText(), string.format(L.CORPSE_DISTANCE, 60))

-- Blick nach Westen (pi/2): Leiche liegt rechts, Drehung -pi/2
facing.value = math.pi / 2
rotation = CorpseArrow.Direction()
expectNear("Blick West: nach rechts", rotation, -math.pi / 2)

-- Leiche im Osten, Blick Norden: rechts; Breite 1000 m
facing.value = 0
corpse = { 0.6, 0.5 }
rotation, distance = CorpseArrow.Direction()
expectNear("Osten: -pi/2", rotation, -math.pi / 2)
expectNear("100 Meter", distance, 100)

-- Instanz: keine Position
player = nil
wow.update(0.2)
expect("ohne Position: kein Pfeil", LevelTimerCorpseArrow.arrow:IsShown(), false)
expect("ohne Position: keine Entfernung", LevelTimerCorpseArrow.distance:GetText(), "")

-- Wiederbelebt
wow.state.ghost = false
wow.fire("PLAYER_UNGHOST")
expect("lebend: weg", LevelTimerCorpseArrow:IsShown(), false)
expect("Fehler?", #wow.errors, 0)

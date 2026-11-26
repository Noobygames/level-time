-- LT-412: graue Vorquest-Geber in der Nähe (Horde Stufe 45 bei Fizzle Brassbolts, Quest 1104, Uldaman): Hinweis einmal
-- je Geber und Quest; Filter "Triviale Quests" nur mit Option ein, beim Entfernen zurück, nie gegen den Spieler.
local TG = addon.TrivialChainGivers
local NEAR, FAR = { 0.781, 0.771 }, { 0.1, 0.9 }  -- FAR: weit weg von allen Gebern in Tausend Nadeln
local player = NEAR
local function vector(x, y) return { GetXY = function() return x, y end } end
function CreateVector2D(x, y) return vector(x, y) end
-- Karte 1000 x 600 Yards (Weltachsen wie im Client vertauscht)
C_Map = {
  GetBestMapForUnit = function() return 1441 end,
  GetPlayerMapPosition = function() return vector(player[1], player[2]) end,
  GetWorldPosFromMapPos = function(_, position)
    local x, y = position:GetXY()
    return 0, vector(-y * 600, -x * 1000)
  end,
}
function UnitQuestTrivialLevelRange() return 8 end

local TRIVIAL = 1024
Enum = Enum or {}
Enum.MinimapTrackingFilter = { TrivialQuests = TRIVIAL }
local filtered, setCalls = true, 0
C_Minimap = {
  GetNumTrackingTypes = function() return 3 end,
  GetTrackingFilter = function(index) return { filterID = index == 2 and TRIVIAL or index } end,
  IsFilteredOut = function() return filtered end,
  SetTracking = function(index, on)
    setCalls = setCalls + 1
    expect("Trivial-Index", index, 2)
    filtered = not on
  end,
}

wow.state.class = "WARRIOR"
wow.state.faction = "Horde"
wow.login({ level = 45 })

local hints = 0
local realNotify = addon.Alerts.Notify
addon.Alerts.Notify = function(notices, ...)
  if notices.title == addon.L.NOTICE_TRIVIAL_CHAIN_GIVER then hints = hints + 1 end
  return realNotify(notices, ...)
end
local function tick() wow.update(3) end

expect("Hinweis standardmäßig an", addon.db.dungeonQuestTrivialNearby, true)
expect("Filter schalten standardmäßig aus", addon.db.dungeonQuestTrivialTracking, false)
expectTrue("verfügbar", TG.IsAvailable() and TG.CanTrack())

-- Option aus: Hinweis, aber kein SetTracking
tick()
local firstHints = hints
expectTrue("Hinweis für den grauen Schritt", firstHints >= 1)
tick()
expect("Hinweis nur einmal je Geber und Quest", hints, firstHints)
expect("Option aus: Filter nicht angefasst", setCalls, 0)

-- Option an: Filter an, beim Entfernen zurück
addon.Set("dungeonQuestTrivialTracking", true)
tick()
expect("Filter eingeschaltet", filtered, false)
player = FAR
tick()
expect("zurück ausgeschaltet", filtered, true)
expect("keine weiteren Aufrufe", setCalls, 2)

-- Spieler hatte ihn schon an: unberührt
filtered, setCalls, player = false, 0, NEAR
tick()
player = FAR
tick()
expect("schon an: nie geschaltet", setCalls, 0)
expect("schon an: bleibt an", filtered, false)

-- Spieler schaltet selbst aus: nicht wieder an, nicht fürs Zurückschalten angefasst
filtered, setCalls, player = true, 0, NEAR
tick()
expect("an", filtered, false)
filtered = true  -- Spieler schaltet aus
tick()
expect("nicht gegen den Spieler wieder an", filtered, true)
expect("nur das eine Einschalten", setCalls, 1)
player = FAR
tick()
expect("kein Zurückschalten", setCalls, 1)

-- Spieler schaltet selbst ein, solange wir es an hatten: bleibt an
filtered, setCalls, player = true, 0, NEAR
tick()
expect("wieder an durch uns", filtered, false)
filtered, player = true, FAR  -- Spieler aus und wir sind weg
tick()
expect("kein Zurückschalten nach Spieleränderung", setCalls, 1)

-- Ausloggen stellt zurück
filtered, setCalls, player = true, 0, NEAR
tick()
expect("an vor Logout", filtered, false)
wow.logout()
expect("Logout schaltet zurück", filtered, true)

-- Hinweis aus und Filter aus: nichts
wow.login({ level = 45 })
addon.Set("dungeonQuestTrivialNearby", false)
addon.Set("dungeonQuestTrivialTracking", false)
filtered, setCalls, hints, player = true, 0, 0, NEAR
tick()
expect("alles aus: kein Hinweis", hints, 0)
expect("alles aus: kein SetTracking", setCalls, 0)

-- Ohne Filter-API (Classic Era): nur der Hinweis, keine Fehler
C_Minimap = nil
addon.Set("dungeonQuestTrivialNearby", true)
addon.Set("dungeonQuestTrivialTracking", true)
hints = 0
tick()
expectTrue("ohne API kein Filter-Knopf", not TG.CanTrack())
expect("keine Lua-Fehler", #wow.errors, 0)

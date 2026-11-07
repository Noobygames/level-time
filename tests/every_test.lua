-- ns.Every: wiederkehrende Aufgaben erst nach dem Login, mit der vergangenen Zeit.
local runs = {}
addon.Every(5, function(elapsed) table.insert(runs, elapsed) end)

wow.update(10)
expect("vor dem Login nichts", #runs, 0)

wow.login()
wow.update(3)
expect("noch nicht fällig", #runs, 0)
wow.update(3)
expect("fällig", #runs, 1)
expect("vergangene Zeit", runs[1], 6)
wow.update(5)
expect("wieder fällig", #runs, 2)

-- Ein Fehler in einer Aufgabe stoppt die übrigen nicht
local after = 0
addon.Every(1, function() error("kaputt") end)
addon.Every(1, function() after = after + 1 end)
wow.update(1)
expect("Aufgabe nach dem Fehler läuft", after, 1)
expect("Fehler an den Handler", #wow.errors, 1)
wow.update(1)
expect("auch beim nächsten Tick", after, 2)

-- Login, Level-Up und Events: ein fehlerhafter Callback hält die übrigen nicht auf
local errorsBefore = #wow.errors
addon.OnLevelCompleted(function() error("kaputt beim Level-Up") end)
local started
addon.OnLevelStarted(function(level) started = level end)
wow.levelUp(addon.level + 1)
expect("neues Level trotz Fehler", started, addon.level)
expect("Level-Bereich neu begonnen", addon.character.currentLevel.level, addon.level)
expect("Fehler gemeldet", #wow.errors, errorsBefore + 1)
local handled
addon.RegisterEvent("PLAYER_REGEN_ENABLED", function() error("kaputt im Event") end)
addon.RegisterEvent("PLAYER_REGEN_ENABLED", function() handled = true end)
wow.fire("PLAYER_REGEN_ENABLED")
expect("zweiter Handler läuft", handled, true)
wow.errors = {}  -- absichtlich ausgelöste Fehler

-- ns.SafeCall ohne Tabelle je Aufruf: Argumente (auch nil-Lücken und viele), Rückgaben, verschachtelte Aufrufe
local function pack(...) return { n = select("#", ...), ... } end
local result = pack(addon.SafeCall(function(...) return select("#", ...), ... end, 1, nil, 3, nil))
expect("ok", result[1], true)
expect("Anzahl mit nil am Ende", result[2], 4)
expect("erstes Argument", result[3], 1)
expect("drittes Argument", result[5], 3)
local many = {}
for i = 1, 25 do many[i] = i end
local okMany, count, last = addon.SafeCall(function(...) return select("#", ...), (select(25, ...)) end,
  unpack(many, 1, 25))
expect("mehr als 20 Argumente: ok", okMany, true)
expect("mehr als 20 Argumente", count, 25)
expect("letztes von 25", last, 25)
local outer, inner
addon.SafeCall(function(a, b)
  addon.SafeCall(function(x) inner = x end, "innen")
  outer = a .. b
end, "au", "ßen")
expect("verschachtelt: innen", inner, "innen")
expect("verschachtelt: außen behält seine Argumente", outer, "außen")
local okError = addon.SafeCall(function(value) error(value) end, "kaputt mit Argument")
expect("Fehler: false", okError, false)
expectTrue("Fehler mit Argument beim Handler", tostring(wow.errors[#wow.errors]):find("kaputt mit Argument", 1, true))
wow.errors = {}

-- enabled(db): ausgeschaltete Aufgaben laufen nicht; ausgewertet nach ApplySettings, nicht je Bild
local gated = { runs = 0, checks = 0, elapsed = nil }
addon.Every(1, function(elapsed) gated.runs, gated.elapsed = gated.runs + 1, elapsed end, function(db)
  gated.checks = gated.checks + 1
  return db.foodTimer
end)
addon.Set("foodTimer", false)
local checks = gated.checks
wow.update(1)
wow.update(1)
expect("aus: läuft nicht", gated.runs, 0)
expect("Prädikat nicht je Bild", gated.checks, checks)
wow.update(5)
addon.Set("foodTimer", true)
wow.update(0.5)
expect("an: elapsed beginnt neu", gated.runs, 0)
wow.update(0.5)
expect("an: läuft", gated.runs, 1)
expect("an: elapsed seit dem Einschalten", gated.elapsed, 1)
-- Fehler im Prädikat: Aufgabe läuft weiter (wie ohne Prädikat), Fehler beim Handler
addon.Every(1, function() gated.broken = true end, function() error("kaputtes Prädikat") end)
addon.ApplySettings()
wow.update(1)
expect("kaputtes Prädikat: läuft", gated.broken, true)
expectTrue("kaputtes Prädikat gemeldet", #wow.errors > 0)
wow.errors = {}

-- Prüfcode für Läufe: FNV-1a, Kette beim Level-Up, Export mit Code und Erfassungsquote, /lt runs verify.
local Fnv = addon.Fnv
local RunCheck = addon.RunCheck
local Runs = addon.Runs

-- Bekannte FNV-1a-32-Werte
expect("leer", Fnv.Hex(""), "811c9dc5")
expect("a", Fnv.Hex("a"), "e40c292c")
expect("foobar", Fnv.Hex("foobar"), "bf9cf968")

wow.login({ name = "Neu", level = 5, playedSeconds = 0 })
expect("ohne Level kein Code", addon.character.runCheck.hash, nil)
wow.advance(600)
wow.fire("TIME_PLAYED_MSG", 600, 600)
wow.levelUp(6)
wow.advance(700)
wow.fire("TIME_PLAYED_MSG", 1300, 700)
wow.levelUp(7)
local check = addon.character.runCheck
expect("Kette über 5..6", check.from .. ".." .. check.to, "5..6")
expect("Kette = Neuberechnung", check.hash, RunCheck.Compute({ [5] = 600, [6] = 700 }, 5, 6))

local own = Runs.Get(addon.characterKey)
expect("eigener Lauf ok", RunCheck.Verify(own), RunCheck.OK)

-- Zeit in den SavedVariables geändert: sichtbar
addon.character.levelHistory[5].seconds = 300
expect("geändert erkannt", RunCheck.Verify(Runs.Get(addon.characterKey)), RunCheck.CHANGED)
addon.character.levelHistory[5].seconds = 600

-- Export mit Code und Erfassungsquote, Import prüft nach
local text = Runs.Export(Runs.Get(addon.characterKey))
local decoded = addon.Serializer.Decode("run", text)
expect("Code im Export", decoded.check, check.hash)
LevelTimerStatsDB.characters = { [addon.characterKey] = addon.character }
decoded.name = "Fremd"
expect("Import", Runs.Import(addon.Serializer.Encode("run", decoded)), 1)
local imported = Runs.FindByName("Fremd")
expect("importierter Lauf ok", RunCheck.Verify(imported), RunCheck.OK)
decoded.name, decoded.times[6] = "Schummler", 100
Runs.Import(addon.Serializer.Encode("run", decoded))
expect("veränderter Import", RunCheck.Verify(Runs.FindByName("Schummler")), RunCheck.CHANGED)
decoded.name, decoded.check = "Kaputt", "<script>"
Runs.Import(addon.Serializer.Encode("run", decoded))
expect("ungültiger Code verworfen", RunCheck.Verify(Runs.FindByName("Kaputt")), nil)

-- /lt runs verify: eine Zeile je Lauf
local before = #wow.printed
SlashCmdList.LEVELTIMER("runs verify")
expect("Zeilen", #wow.printed - before, #Runs.GetAll())

-- Alter Charakter ohne Code: beim Login aus den vorhandenen Zeiten
addon.character.runCheck = nil
wow.logout()
wow.login()
expect("nachgetragen", addon.character.runCheck.hash, RunCheck.Compute({ [5] = 600, [6] = 700 }, 5, 6))

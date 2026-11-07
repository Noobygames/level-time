-- Roadmap 337: Stand je Journal-Log. Ein Kill macht Tod-, Quest- und Beute-Ansichten nicht ungültig, der Gesamtstand
-- (Journal.Revision ohne Argument) steigt weiter bei jeder Änderung.
local L = addon.L
local Journal = addon.Journal

wow.login({ level = 20, xp = 0, xpMax = 1000 })
wow.fire("TIME_PLAYED_MSG", 5000, 100)

local function kill(name)
  wow.fire("CHAT_MSG_COMBAT_XP_GAIN", name .. " stirbt, Ihr bekommt 10 Erfahrung.")
end

local total, kills, deaths = Journal.Revision(), Journal.Revision("killLog"), Journal.Revision("deathLog")
kill("Wolf")
expectTrue("Kill: Gesamtstand steigt", Journal.Revision() ~= total)
expectTrue("Kill: Kill-Stand steigt", Journal.Revision("killLog") ~= kills)
expect("Kill: Tod-Stand bleibt", Journal.Revision("deathLog"), deaths)
expect("RevisionOf liefert denselben Stand", Journal.RevisionOf("killLog")(), Journal.Revision("killLog"))

-- Nachgetragene Todesursache ändert nur den Tod-Stand
local entry = Journal.AddDeath({})
local afterDeath, killsNow = Journal.Revision("deathLog"), Journal.Revision("killLog")
Journal.SetDeathCause(entry, { killer = "Wolf" })
expectTrue("Ursache: Tod-Stand steigt", Journal.Revision("deathLog") ~= afterDeath)
expect("Ursache: Kill-Stand bleibt", Journal.Revision("killLog"), killsNow)

-- Herausgenommener Instanz-Lauf ändert nur den Lauf-Stand
addon.character.instanceLog = { { time = time(), name = "Die Todesminen", seconds = 60, level = 18 } }
local runs, deathsNow = Journal.Revision("instanceLog"), Journal.Revision("deathLog")
expectTrue("Lauf herausgenommen", Journal.TakeLastInstanceRun("Die Todesminen") ~= nil)
expectTrue("Lauf-Stand steigt", Journal.Revision("instanceLog") ~= runs)
expect("Tod-Stand bleibt", Journal.Revision("deathLog"), deathsNow)

-- Offene Todesursachen-Rangliste: Kills lösen keine neue Auswertung aus, ein Tod schon
local reads = { count = 0 }
local getEntries = Journal.GetEntries
Journal.GetEntries = function(...)
  reads.count = reads.count + 1
  return getEntries(...)
end
SlashCmdList.LEVELTIMER("history")
wow.click(L.HISTORY_TAB_CHARTS)
expectTrue("Todesursachen", wow.click(L.CHART_DEATH_CAUSES))
local afterOpen = reads.count
kill("Eber")
kill("Bär")
wow.update(1.1)
expect("Kills: Todesursachen nicht neu ausgewertet", reads.count, afterOpen)
Journal.AddDeath({ killer = "Bär" })
wow.update(1.1)
expectTrue("Tod: neu ausgewertet", reads.count > afterOpen)
Journal.GetEntries = getEntries

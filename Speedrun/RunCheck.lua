-- Prüfcode für Läufe: verkettete Prüfsumme über die Level-Zeiten, h = FNV-1a(vorher, Zeit, Art, Text).
-- Beim Level-Up schreibt das Addon den Code fort (character.runCheck = { hash, from, to }, from..to = verkettete
-- Level). Wer danach Zeiten in den SavedVariables ändert, ändert den Code nicht mit: Manipulation wird
-- sichtbar, aber nicht verhindert (der Algorithmus ist offen). Charaktere ohne Code bekommen ihn beim Login aus
-- den vorhandenen Zeiten (ab dann geprüft).
-- Export: Runs.Export nimmt check/checkFrom/checkTo und die Erfassungsquote (Coverage.lua) mit; RunCheck.Verify
-- rechnet den Code aus den Zeiten eines Laufs nach (eigene und importierte), /lt runs verify listet alle.
local _, ns = ...
local L = ns.L
local Fnv = ns.Fnv

local RunCheck = {
  OK = "ok",
  CHANGED = "changed",
}
ns.RunCheck = RunCheck

local START = "LT"
local LEVEL_KIND = "level"

-- Ein Glied der Kette: ganze Sekunden, damit Rundung beim Export nichts verschiebt
function RunCheck.Step(previous, seconds, kind, text)
  return Fnv.Hex(table.concat({ previous, math.floor(seconds), kind, text }, ":"))
end

-- Code über die Level from..to; nil, wenn eines davon keine Zeit hat
function RunCheck.Compute(times, from, to)
  local hash = START
  for level = from, to do
    if not times[level] then return nil end
    hash = RunCheck.Step(hash, times[level], LEVEL_KIND, tostring(level))
  end
  return hash
end

-- Gespeicherte Kette aus den vorhandenen Level-Zeiten neu beginnen (erster Login mit dieser Version)
local function backfill(character)
  local from, to
  for level, record in pairs(character.levelHistory) do
    if record.seconds then
      from, to = math.min(from or level, level), math.max(to or level, level)
    end
  end
  local times = {}
  for level, record in pairs(character.levelHistory) do times[level] = record.seconds end
  local hash = from and RunCheck.Compute(times, from, to)
  character.runCheck = hash and { hash = hash, from = from, to = to } or {}
end

ns.OnLogin(function()
  if not ns.character.runCheck then backfill(ns.character) end
end)

-- Beim Level-Up fortschreiben (läuft nach History.lua, der Eintrag steht schon). Fehlt ein Level dazwischen
-- (Addon war aus), beginnt die Kette neu.
ns.OnLevelCompleted(function(level)
  local record = ns.character.levelHistory[level]
  if not record or not record.seconds then return end
  local check = ns.character.runCheck or {}
  if check.hash and check.to == level - 1 then
    check.hash, check.to = RunCheck.Step(check.hash, record.seconds, LEVEL_KIND, tostring(level)), level
  else
    check = { hash = RunCheck.Step(START, record.seconds, LEVEL_KIND, tostring(level)), from = level, to = level }
  end
  ns.character.runCheck = check
  ns.Debug("runcheck", "level %s -> %s", level, check.hash)
end)

-- Prüfcode-Felder eines Charakters für den Lauf (Runs.lua)
function RunCheck.ForCharacter(character)
  local check = character.runCheck or {}
  return check.hash, check.from, check.to
end

-- RunCheck.OK, RunCheck.CHANGED oder nil ohne Code
function RunCheck.Verify(run)
  if not run.check or not run.checkFrom or not run.checkTo then return nil end
  return RunCheck.Compute(run.times, run.checkFrom, run.checkTo) == run.check and RunCheck.OK or RunCheck.CHANGED
end

function RunCheck.StatusText(run)
  local status = RunCheck.Verify(run)
  if status == RunCheck.OK then return L.RUN_CHECK_OK end
  if status == RunCheck.CHANGED then return L.RUN_CHECK_CHANGED end
  return L.RUN_CHECK_NONE
end

-- /lt runs verify: eine Zeile je Lauf
function RunCheck.PrintAll()
  for _, run in ipairs(ns.Runs.GetAll()) do
    local name = run.imported and (run.name or "?") or ns.History.DisplayName(run.id)
    ns.Print(string.format(L.RUN_CHECK_LINE, name, RunCheck.StatusText(run), ns.Coverage.Text(run.coverage)))
  end
end

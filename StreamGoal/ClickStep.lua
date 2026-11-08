-- Klicks auf Karten und Bingo-Felder (Tracker.lua, BingoView.lua): selbst gezählte Ziele zählen mit Linksklick eins
-- hoch, mit Shift+Linksklick eins zurück. Der Klick, der ein Ziel abschließen würde, schließt nicht sofort ab, sondern
-- merkt das Ziel für CONFIRM_SECONDS vor (Karte/Feld zeigt "Nochmal klicken zum Abhaken"); erst ein zweiter Klick
-- darin schließt ab. Grund: ein Abschluss lässt sich nicht zurücknehmen und die Einblendung ist dann schon im Stream;
-- verhindern ist besser als rückgängig machen. Ein Doppelklick schließt weiterhin sofort ab. Knöpfe im Fenster und
-- /sg count zählen ohne Rückfrage (dort klickt man bewusst).
local _, ns = ...
local Goals = ns.Goals

local ClickStep = {}
ns.ClickStep = ClickStep

ClickStep.CONFIRM_SECONDS = 3
local STEP_UP, STEP_DOWN = 1, -1

local armedId, armedUntil = nil, 0

function ClickStep.IsArmed(goal)
  return goal ~= nil and armedId == goal.id and GetTime() < armedUntil
end

local function disarm()
  local goal = armedId and Goals.Get(armedId)
  armedId, armedUntil = nil, 0
  if goal then Goals.Changed(goal) end
end

-- Linksklick auf ein selbst gezähltes Ziel; down = Shift gehalten. Rückgabe: "armed" (vorgemerkt), "stepped" oder nil
function ClickStep.Click(goal, down)
  if not goal or not Goals.IsManual(goal) or goal.status ~= Goals.ACTIVE then return nil end
  local delta = down and STEP_DOWN or STEP_UP
  if Goals.WouldComplete(goal, delta) and not ClickStep.IsArmed(goal) then
    disarm()
    armedId, armedUntil = goal.id, GetTime() + ClickStep.CONFIRM_SECONDS
    local id = goal.id
    C_Timer.After(ClickStep.CONFIRM_SECONDS, function()
      if armedId == id and GetTime() >= armedUntil then disarm() end
    end)
    Goals.Changed(goal)
    return "armed"
  end
  if armedId == goal.id then armedId, armedUntil = nil, 0 end
  local _, err = Goals.Step(goal.id, delta)
  if err then ns.Print(err) end
  return "stepped"
end

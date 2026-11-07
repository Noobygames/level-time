-- Instanz-Reiter des Hauptfensters (Roadmap 219, aus TimerWindow.lua): automatisch zum Reiter Instanz wechseln
-- (Einstellung autoInstanceTab) und die Rückfrage zum Zurücksetzen des laufenden Instanz-Laufs
-- (Instances.ConfirmReset: Rechtsklick auf den Instanz-Reiter, Button in Statistiken > Instanz, /lt resetinstance).
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Stats = ns.Stats

---------------------------------------------------------------------------
-- Automatisch zum Reiter Instanz wechseln (Einstellung autoInstanceTab): beim Betreten hin, beim Verlassen
-- zurück zum vorigen Reiter, außer man hat inzwischen selbst gewechselt
---------------------------------------------------------------------------
local scopeBeforeInstance

ns.InstanceCopy.OnEnter(function()
  if not ns.db.autoInstanceTab or scopeBeforeInstance or ns.db.windowScope == Stats.INSTANCE then return end
  scopeBeforeInstance = ns.db.windowScope
  ns.Set("windowScope", Stats.INSTANCE)
end)

ns.InstanceCopy.OnLeave(function()
  local previous = scopeBeforeInstance
  scopeBeforeInstance = nil
  if ns.db.windowScope ~= Stats.INSTANCE then return end  -- man hat selbst gewechselt
  if previous then
    ns.Set("windowScope", previous)
  elseif ns.db.autoInstanceTab then
    ns.Set("windowScope", Stats.LEVEL)  -- der Merker ging bei /reload in der Instanz verloren
  end
end)

---------------------------------------------------------------------------
-- Instanz-Lauf zurücksetzen
---------------------------------------------------------------------------
local RESET_INSTANCE_POPUP = ns.PopupKey("RESET_INSTANCE")

local confirmInstanceReset = Widgets.ConfirmPopup(RESET_INSTANCE_POPUP, "INSTANCE_RESET_CONFIRM", function()
  if ns.Instances.ResetCurrent() then ns.Print(L.INSTANCE_RESET_DONE) end
end)

function ns.Instances.ConfirmReset()
  local run = ns.Instances.GetCurrentRun()
  if not run then
    ns.Print(L.INSTANCE_RESET_NONE)
    return
  end
  confirmInstanceReset(run.name)
end

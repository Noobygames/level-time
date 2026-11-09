-- Optionen: Fußknöpfe auf allen Reitern, Fertigstellen des Fensters und die Öffnen-Funktionen.
local _, ns = ...
local O = ns.OptionsCore
local Widgets = ns.Widgets
local builder, addFooterButton = O.builder, O.addFooterButton

addFooterButton("HISTORY", function() ns.ToggleHistory() end)
-- Edit-Modus auf allen Reitern: verschieben, skalieren und zurücksetzen aller Anzeigen (UI/EditMode.lua)
addFooterButton("EDIT_MODE", function()
  builder.panel:Hide()  -- Platz für die Anzeigen
  ns.EditMode.Enter()
end)
addFooterButton("RECAP_TITLE", function() ns.ToggleRecap() end)
-- Neue Session nur nach Rückfrage (archiviert sofort und setzt die Werte zurück); /lt newsession ist schon eindeutig
local NEW_SESSION_POPUP = ns.PopupKey("NEW_SESSION")
local confirmNewSession = Widgets.ConfirmPopup(NEW_SESSION_POPUP, "NEW_SESSION_CONFIRM", function() ns.StartNewSession() end)
addFooterButton("NEW_SESSION", function()
  confirmNewSession(ns.Format.Duration(ns.Stats.GetSeconds(ns.Stats.SESSION) or 0))
end)

builder.Finish()
ns.RegisterApply(builder.RefreshIfShown)
ns.OptionsWindow = builder  -- Seiten, Suche und Hervorhebung (Tests)

-- Einstellungen auf einem Reiter oder einer Unterseite öffnen (Locale-Key wie bei addPage/addSubPage), z.B. aus dem
-- Menü des Edit-Modus; ohne Key bleibt die zuletzt gezeigte Seite
function ns.ShowOptionsPage(pageKey)
  if not ns.db then return end
  builder.Refresh(ns.db)
  builder.panel:Show()
  if pageKey then builder.ShowPage(pageKey) end
end

-- Rechtsklick auf eine Anzeige (Lib/Frames.lua): ihre Seite öffnen; ist genau sie schon offen, schließen
function ns.ToggleOptionsPage(pageKey)
  if not ns.db then return end
  local tab, sub = builder.CurrentPage()
  if builder.panel:IsShown() and (sub or tab) == pageKey then
    builder.panel:Hide()
  else
    ns.ShowOptionsPage(pageKey)
  end
end

function ns.ToggleOptions()
  if not ns.db then return end
  local panel = builder.panel
  if panel:IsShown() then
    panel:Hide()
  else
    builder.Refresh(ns.db)
    panel:Show()
  end
end


-- Position und Größe der Einblendungen (UI/Alerts.lua) über Lib/Frames.lua: Im Edit-Modus bleibt ein Beispiel stehen,
-- Neues wartet und erscheint danach.
local _, ns = ...
local L = ns.L
local Alerts = ns.Alerts

local frame = Alerts.frame
local noticeFrame = Alerts.noticeFrame

local function setEditing(enabled)
  enabled = enabled and true or false
  if enabled == Alerts.IsEditing() then return end
  if not enabled then
    Alerts.SetPaused(false)
    return
  end
  local card = Alerts.IsBanner() and { title = L.ALERT_MOVE_HINT } or nil
  Alerts.ShowPinned(L.ALERT_MOVE_HINT, Alerts.COLORS.levelUp, card)
  Alerts.SetPaused(true)
  if noticeFrame:IsShown() then
    -- Banner-Stil: Das sichtbare Beispiel ist die Karte; der (sonst versteckte) Rahmen bekommt ihre Größe, damit
    -- die Fläche des Edit-Modus sie abdeckt; die Karte hängt an ihm
    noticeFrame:SetAlpha(1)
    frame:SetSize(noticeFrame:GetWidth(), noticeFrame:GetHeight())
    frame:SetAlpha(0)
    frame:Show()
  else
    frame:SetAlpha(1)
  end
end

-- Die Karte folgt der Größe des Rahmens. Kein Rechtsklick zu den Einstellungen: die Einblendung steht mitten im Bild
-- und bleibt klickdurchlässig (sonst schluckte sie im Kampf Klicks auf Gegner)
ns.Frames.Register({
  id = "alert", frame = frame, label = "EDIT_FRAME_ALERT", default = Alerts.DEFAULT_POSITION,
  settingsPage = "OPTIONS_PAGE_ALERT_LOOK", preview = setEditing,
  onScale = function(scale) noticeFrame:SetScale(scale) end,
})

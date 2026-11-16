-- Ersetzt Blizzards Gruppensuche-Fenster durch UI/LFGWindow.lua (nur WoW Forever, Einstellung lfgWindow):
-- Post-Hook auf LFGVanilla_ShowFrame (jeder Weg öffnet darüber: Tastenbelegung, Minikarten-Auge, Warteschlangenknopf)
-- schließt Blizzards LFGParentFrame und öffnet das eigene Fenster; der Reiter Wer (3) bleibt Blizzards.
local _, ns = ...
if not ns.Client.IsForever() then return end

local LFGSearch = ns.LFGSearch
local LFGWindow = ns.LFGWindow

local WHO_TAB = 3
local hooked = false

local function onBlizzardShow(tab)
  if not LFGSearch.IsEnabled() or tab == WHO_TAB then return end
  if LFGParentFrame and LFGParentFrame:IsShown() then HideUIPanel(LFGParentFrame) end
  if LFGWindow.IsShown() and (tab == nil or tab == LFGWindow.State().tab) then
    LFGWindow.Hide()  -- zweiter Aufruf derselben Taste schließt wie bei Blizzard
  else
    LFGWindow.Show(tab)
  end
end

local function hookBlizzard()
  if hooked or not (hooksecurefunc and LFGVanilla_ShowFrame) then return end
  hooked = true
  hooksecurefunc("LFGVanilla_ShowFrame", onBlizzardShow)
end

hookBlizzard()
ns.RegisterEvent("ADDON_LOADED", hookBlizzard)

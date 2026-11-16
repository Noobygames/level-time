-- Gruppensuche in allen Sprachen (Einstellung lfgAllLanguages, aus; nur WoW Forever): stellt Blizzards Sprachfilter
-- (C_LFGList.SaveLanguageSearchFilter, Tabelle Sprache -> true) auf alle verfügbaren Sprachen. Der Filter gilt
-- accountweit und auch für Blizzards eigenes Fenster. Beim Einschalten wird der bisherige Filter in
-- lfgLanguageBackup gemerkt und beim Ausschalten wiederhergestellt. API wie in Blizzards LFGList.lua
-- (LFGListSearchPanel_SetupLanguageFilter): GetLanguageSearchFilter, GetAvailableLanguageSearchFilter (Liste von
-- Sprachkürzeln), GetDefaultLanguageSearchFilter (immer aktive Sprachen).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    lfgAllLanguages = false,
    lfgLanguageBackup = false,  -- gemerkter Filter, solange "alle Sprachen" an ist
  },
})

local LFGLanguages = {}
ns.LFGLanguages = LFGLanguages

function LFGLanguages.IsAvailable()
  local api = C_LFGList
  return ns.Client.IsForever() and api ~= nil and api.SaveLanguageSearchFilter ~= nil
    and api.GetLanguageSearchFilter ~= nil and api.GetAvailableLanguageSearchFilter ~= nil
end

local function copy(filter)
  local result = {}
  for language, enabled in pairs(filter or {}) do result[language] = enabled end
  return result
end

local function allEnabled(current, available)
  for _, language in ipairs(available) do
    if not current[language] then return false end
  end
  return true
end

-- Filter an die Einstellung angleichen (bei jedem Apply; ändert nichts, wenn er schon stimmt)
local function sync(db)
  if not LFGLanguages.IsAvailable() then return end
  local current = copy(C_LFGList.GetLanguageSearchFilter())
  if db.lfgAllLanguages then
    local available = C_LFGList.GetAvailableLanguageSearchFilter() or {}
    if allEnabled(current, available) then return end
    if not db.lfgLanguageBackup then db.lfgLanguageBackup = current end
    local all = copy(current)
    for _, language in ipairs(available) do all[language] = true end
    C_LFGList.SaveLanguageSearchFilter(all)
    ns.Debug("lfg", "language filter widened to %s languages", #available)
  elseif db.lfgLanguageBackup then
    C_LFGList.SaveLanguageSearchFilter(db.lfgLanguageBackup)
    db.lfgLanguageBackup = false
    ns.Debug("lfg", "language filter restored")
  end
end

ns.RegisterApply(sync)

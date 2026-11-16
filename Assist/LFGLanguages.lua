-- Gruppensuche-Sprachen (Einstellung lfgLanguages; nur WoW Forever): setzt Blizzards Sprachfilter
-- (C_LFGList.SaveLanguageSearchFilter, Tabelle Sprache -> true) auf die gewählten Sprachen. Der Filter gilt
-- accountweit und auch für Blizzards eigenes Fenster. Beim ersten Eingriff wird der Blizzard-Filter in
-- lfgLanguageBackup gemerkt; Restore() stellt ihn wieder her. lfgLanguages = false: Blizzards Filter bleibt
-- unberührt. API wie in Blizzards LFGList.lua (LFGListSearchPanel_SetupLanguageFilter): GetLanguageSearchFilter,
-- GetAvailableLanguageSearchFilter (Liste von Sprachkürzeln).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    lfgLanguages = false,       -- gewählte Sprachen { [Kürzel] = true } oder false (Blizzard-Filter)
    lfgLanguageBackup = false,  -- gemerkter Blizzard-Filter, solange lfgLanguages gesetzt ist
  },
})

local LFGLanguages = {}
ns.LFGLanguages = LFGLanguages

-- Falls die API beim Aufbau der Optionen noch keine Liste liefert
local FALLBACK_LANGUAGES = { "deDE", "enUS", "esES", "frFR", "ptBR", "ruRU" }

function LFGLanguages.IsAvailable()
  local api = C_LFGList
  return ns.Client.IsForever() and api ~= nil and api.SaveLanguageSearchFilter ~= nil
    and api.GetLanguageSearchFilter ~= nil and api.GetAvailableLanguageSearchFilter ~= nil
end

function LFGLanguages.Available()
  local list = LFGLanguages.IsAvailable() and C_LFGList.GetAvailableLanguageSearchFilter()
  return list and #list > 0 and list or FALLBACK_LANGUAGES
end

local function copy(filter)
  local result = {}
  for language, enabled in pairs(filter or {}) do result[language] = enabled end
  return result
end

local function equal(a, b)
  for language, enabled in pairs(a) do
    if (b[language] or false) ~= (enabled or false) then return false end
  end
  for language, enabled in pairs(b) do
    if (a[language] or false) ~= (enabled or false) then return false end
  end
  return true
end

-- Immer aktive Sprachen (Blizzards Standardfilter, in Blizzards Fenster nicht abwählbar)
function LFGLanguages.Defaults()
  local api = C_LFGList
  return LFGLanguages.IsAvailable() and api.GetDefaultLanguageSearchFilter and api.GetDefaultLanguageSearchFilter() or {}
end

-- Aktuelle Auswahl inklusive der Standardsprachen: gewählte Sprachen, sonst Blizzards Filter
function LFGLanguages.Selected()
  local selection = {}
  if ns.db and ns.db.lfgLanguages then selection = copy(ns.db.lfgLanguages)
  elseif LFGLanguages.IsAvailable() then selection = copy(C_LFGList.GetLanguageSearchFilter()) end
  for language, enabled in pairs(LFGLanguages.Defaults()) do selection[language] = enabled or nil end
  return selection
end

function LFGLanguages.Toggle(code, checked)
  local selection = LFGLanguages.Selected()
  selection[code] = checked or nil
  ns.Set("lfgLanguages", selection)
end

-- Blizzards Filter wiederherstellen und die eigene Auswahl verwerfen
function LFGLanguages.Restore()
  if not LFGLanguages.IsAvailable() then return end
  local db = ns.db
  if db.lfgLanguageBackup then C_LFGList.SaveLanguageSearchFilter(db.lfgLanguageBackup) end
  db.lfgLanguageBackup = false
  db.lfgLanguages = false
  ns.ApplySettings()
  ns.Debug("lfg", "language filter restored")
end

-- Alter Schalter "alle Sprachen" wird zur Auswahl aller Sprachen
ns.OnLogin(function()
  local db = ns.db
  if db.lfgAllLanguages == nil then return end
  if db.lfgAllLanguages and not db.lfgLanguages then
    db.lfgLanguages = {}
    for _, language in ipairs(LFGLanguages.Available()) do db.lfgLanguages[language] = true end
  end
  db.lfgAllLanguages = nil
end)

-- Filter an die Auswahl angleichen (bei jedem Apply; ändert nichts, wenn er schon stimmt)
ns.RegisterApply(function(db)
  if not (LFGLanguages.IsAvailable() and db.lfgLanguages) then return end
  local current, wanted = copy(C_LFGList.GetLanguageSearchFilter()), LFGLanguages.Selected()
  if equal(current, wanted) then return end
  if not db.lfgLanguageBackup then db.lfgLanguageBackup = current end
  C_LFGList.SaveLanguageSearchFilter(wanted)
  ns.Debug("lfg", "language filter set")
end)

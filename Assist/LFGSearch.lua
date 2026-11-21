-- Suche und eigener Eintrag der Gruppensuche für das eigene Fenster (UI/LFGWindow.lua; nur WoW Forever; Minikarten-Icon
-- mit Einstellung lfgMinimapButton, an). Nur Daten und Aufrufe, keine Anzeige. Forever lädt Blizzards "Vanilla-Stil"-Gruppensuche
-- (Blizzard_GroupFinder_VanillaStyle, Bewerben und Bewerberliste gibt es dort nicht): man flüstert dem Leiter oder
-- lädt einen Einzelspieler ein, der eigene Eintrag besteht aus Aktivitäten, Einsteigerfreundlich und Soloaktionen
-- (C_LFGListRoles). API wie in Blizzard_LFGVanilla_Browse/Listing.lua: GetAvailableCategories, GetLfgCategoryInfo,
-- GetAvailableActivities(categoryID), GetActivityInfoTable, Search(categoryID, filter, preferredFilters, languageFilter,
-- crossFaction, advancedFilter, activityIDs), GetFilteredSearchResults, CreateListing/UpdateListing/RemoveListing.
-- Search, CreateListing, UpdateListing und RemoveListing dürfen nur aus dem Klick eines eigenen Knopfs kommen.
-- Der Sprachfilter der Suche kommt aus eigenen Chips (lfgLanguageChips) und wird Search direkt mitgegeben, Blizzards
-- gespeicherter Filter bleibt unberührt.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    lfgMinimapButton = true,   -- Minikarten-Icon des eigenen Fensters (UI/LFGWindowLaunchers.lua)
    lfgMinimapAngle = 200,
    lfgWhisperTemplate = "",  -- Flüstertext mit {role} {class} {level} {dungeon}; leer = Standardtext der Sprache
    lfgLanguageChips = false,  -- { [Sprache] = true }; false = Blizzards Filter beim ersten Öffnen übernehmen
  },
})

local LFGData = ns.LFGData
local LFGFilters = ns.LFGFilters

local LFGSearch = {}
ns.LFGSearch = LFGSearch

LFGSearch.KIND_ALL, LFGSearch.KIND_GROUPS, LFGSearch.KIND_SOLO = LFGFilters.KIND_ALL, LFGFilters.KIND_GROUPS,
  LFGFilters.KIND_SOLO

local cache = {}  -- resultID -> LFGData.Summary

local function api() return C_LFGList end

function LFGSearch.IsAvailable()
  local lfg = api()
  return ns.Client.IsForever() and lfg ~= nil and lfg.Search ~= nil and lfg.GetAvailableCategories ~= nil
    and lfg.GetAvailableActivities ~= nil and lfg.GetFilteredSearchResults ~= nil
end

-- Kategorien: { { id, name }, ... }
function LFGSearch.Categories()
  local list = {}
  for _, categoryID in ipairs(api().GetAvailableCategories() or {}) do
    local info = api().GetLfgCategoryInfo(categoryID)
    if type(info) == "table" and info.name then table.insert(list, { id = categoryID, name = info.name }) end
  end
  return list
end

-- Aktivitäten einer Kategorie nach Level aufsteigend (Level aus InstanceInfo, sonst Blizzards Vorschlag; Mindestlevel,
-- dann Höchstlevel; Höchstlevel 0 = offen nach oben zählt als höchstes; ohne Mindestlevel ganz am Ende):
--   { { id, name, fullName, minLevel, maxLevel, mapID }, ... }
function LFGSearch.Activities(categoryID)
  local list = {}
  for _, activityID in ipairs(api().GetAvailableActivities(categoryID) or {}) do
    local info = api().GetActivityInfoTable(activityID)
    if type(info) == "table" then
      local name = (info.shortName and info.shortName ~= "" and info.shortName) or info.fullName
      -- Levelbereich aus den eigenen Instanzdaten (für Forever gepflegt), sonst Blizzards Vorschlag (Forever: oft Classic-Werte)
      local known = ns.InstanceInfo.Get(info.mapID)
      local minLevel = known and known.minLevel or info.minLevelSuggestion or 0
      local maxLevel = known and known.maxLevel or info.maxLevelSuggestion or 0
      table.insert(list, { id = activityID, name = name, fullName = info.fullName, mapID = info.mapID,
        minLevel = minLevel, maxLevel = maxLevel })
    end
  end
  local function upper(level) return level == 0 and math.huge or level end
  table.sort(list, function(a, b)
    -- Mindestlevel 0 = ohne Levelangabe: ans Ende
    if a.minLevel ~= b.minLevel then return upper(a.minLevel) < upper(b.minLevel) end
    if a.maxLevel ~= b.maxLevel then return upper(a.maxLevel) < upper(b.maxLevel) end
    if a.name ~= b.name then return a.name < b.name end
    return a.id < b.id
  end)
  return list
end

-- Passt der Level zur empfohlenen Spanne der Aktivität? Eine Grenze 0 heißt unbegrenzt.
function LFGSearch.ActivityFits(activity, level)
  return (activity.minLevel == 0 or activity.minLevel <= level) and (activity.maxLevel == 0 or level <= activity.maxLevel)
end

-- Nur die Aktivitäten, die zum Level passen (Alle Stufen anzeigen aus); passt keine, bleibt die ganze Liste
function LFGSearch.FitActivities(list, level)
  local fitting = {}
  for _, activity in ipairs(list) do
    if LFGSearch.ActivityFits(activity, level) then table.insert(fitting, activity) end
  end
  return #fitting > 0 and fitting or list
end

---------------------------------------------------------------------------
-- Sprachen
---------------------------------------------------------------------------
-- Sprachen des Filters: { { code, enabled, fixed }, ... }; fixed = Pflichtsprache (Blizzards Standardfilter)
function LFGSearch.Languages()
  local lfg = api()
  if not (lfg.GetAvailableLanguageSearchFilter and lfg.GetLanguageSearchFilter) then return {} end
  local chips = ns.db.lfgLanguageChips or lfg.GetLanguageSearchFilter() or {}
  local defaults = lfg.GetDefaultLanguageSearchFilter and lfg.GetDefaultLanguageSearchFilter() or {}
  local list = {}
  for _, code in ipairs(lfg.GetAvailableLanguageSearchFilter() or {}) do
    local fixed = defaults[code] == true
    table.insert(list, { code = code, fixed = fixed, enabled = fixed or chips[code] == true })
  end
  return list
end

function LFGSearch.ToggleLanguage(code)
  local chips = {}
  for _, language in ipairs(LFGSearch.Languages()) do
    chips[language.code] = language.enabled or nil
    if language.code == code and not language.fixed then chips[code] = not language.enabled or nil end
  end
  ns.db.lfgLanguageChips = chips
end

-- Anzahl der zusätzlich zu den Pflichtsprachen eingeschalteten Sprachen
function LFGSearch.ExtraLanguages()
  local count = 0
  for _, language in ipairs(LFGSearch.Languages()) do
    if language.enabled and not language.fixed then count = count + 1 end
  end
  return count
end

local function languageFilter()
  local filter, any = {}, false
  for _, language in ipairs(LFGSearch.Languages()) do
    if language.enabled then filter[language.code], any = true, true end
  end
  return any and filter or nil
end

---------------------------------------------------------------------------
-- Suche (nur aus dem Klick eines eigenen Knopfs aufrufen)
---------------------------------------------------------------------------
-- activityIDs leer = alle Aktivitäten der Kategorie
function LFGSearch.Search(categoryID, activityIDs)
  if not categoryID then return false end
  if not activityIDs or #activityIDs == 0 then
    activityIDs = api().GetAvailableActivities(categoryID) or {}
  end
  cache = {}
  api().Search(categoryID, 0, 0, languageFilter(), false, nil, activityIDs)
  ns.Debug("lfg", "search category %s with %s activities", categoryID, #activityIDs)
  return true
end

function LFGSearch.Invalidate(resultID)
  if resultID then cache[resultID] = nil else cache = {} end
end

function LFGSearch.Summary(resultID)
  if cache[resultID] == nil then cache[resultID] = LFGData.Summary(resultID) or false end
  return cache[resultID] or nil
end

local function isSolo(summary)
  return summary.numMembers == 1
end

-- Ergebnisliste nach { fitOnly, filters = LFGFilters.Get() }, neueste zuerst (mit filters.socialFirst Freunde/Gilde
-- davor): { summary, ... }
function LFGSearch.Results(options)
  local _, ids = api().GetFilteredSearchResults()
  local filters = options.filters
  local list = {}
  for _, resultID in ipairs(ids or {}) do
    local summary = LFGSearch.Summary(resultID)
    local keep = summary ~= nil and LFGFilters.Matches(summary, filters)
      and not (options.fitOnly and summary.fit ~= LFGData.FITS and summary.fit ~= nil)
    if keep then table.insert(list, summary) end
  end
  table.sort(list, function(a, b)
    if filters.socialFirst and LFGFilters.IsSocial(a) ~= LFGFilters.IsSocial(b) then return LFGFilters.IsSocial(a) end
    if (a.age or 0) ~= (b.age or 0) then return (a.age or 0) < (b.age or 0) end
    return a.resultID < b.resultID
  end)
  return list
end

-- Treffer in zwei Abschnitten (LT-326): { { kind = KIND_GROUPS|KIND_SOLO, items = { summary, ... } }, ... }. Wer allein
-- ist, sucht eine Gruppe: Gruppen zuerst; in einer Gruppe sucht man Leute: Einzelspieler zuerst. Gleiche Filter wie Results.
function LFGSearch.Sections(options)
  local groups, solo = {}, {}
  for _, summary in ipairs(LFGSearch.Results(options)) do
    table.insert(isSolo(summary) and solo or groups, summary)
  end
  local groupSection = { kind = LFGSearch.KIND_GROUPS, items = groups }
  local soloSection = { kind = LFGSearch.KIND_SOLO, items = solo }
  if IsInGroup() then return { soloSection, groupSection } end
  return { groupSection, soloSection }
end

-- Einzelspieler kann man einladen (Blizzards Regel: nur allein oder als Leiter/Assistent); Gruppen nur anflüstern
function LFGSearch.CanInvite(summary)
  if not summary or summary.delisted or not isSolo(summary) or not summary.leaderName then return false end
  return not IsInGroup() or UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
end

---------------------------------------------------------------------------
-- Eigener Eintrag
---------------------------------------------------------------------------
-- Aktiver Eintrag: { activityIDs, newPlayerFriendly, categoryID, voiceMode, generalPlaystyle } oder nil
function LFGSearch.ActiveEntry()
  if not (api().HasActiveEntryInfo and api().HasActiveEntryInfo()) then return nil end
  local entry = api().GetActiveEntryInfo()
  if type(entry) ~= "table" or ns.IsSecret(entry) then return nil end
  local info = entry.activityIDs and entry.activityIDs[1] and api().GetActivityInfoTable(entry.activityIDs[1])
  return { activityIDs = entry.activityIDs or {}, newPlayerFriendly = entry.newPlayerFriendly == true,
    voiceMode = entry.voiceMode, generalPlaystyle = entry.generalPlaystyle,
    categoryID = type(info) == "table" and info.categoryID or nil }
end

-- Bearbeiten darf, wer allein ist oder die Gruppe leitet
function LFGSearch.CanEditListing()
  return not IsInGroup() or UnitIsGroupLeader("player")
end

-- Eigene Soloaktionen { tank, healer, dps }
function LFGSearch.GetRoles()
  return C_LFGListRoles and C_LFGListRoles.GetRoles() or {}
end

-- Eintragen oder aktualisieren (nur aus dem Klick eines Knopfs): data = { activityIDs, newPlayerFriendly, roles,
-- generalPlaystyle, voiceMode }. Blizzard schickt den Spielstil nur beim Erstellen mit.
function LFGSearch.Post(data)
  local payload = { activityIDs = data.activityIDs, newPlayerFriendly = data.newPlayerFriendly == true,
    voiceMode = data.voiceMode }
  if data.roles and C_LFGListRoles then C_LFGListRoles.SetRoles(data.roles) end
  if LFGSearch.ActiveEntry() then
    api().UpdateListing(payload)
  else
    payload.generalPlaystyle = data.generalPlaystyle
    api().CreateListing(payload)
  end
  ns.Debug("lfg", "listing posted for %s activities", #data.activityIDs)
end

function LFGSearch.Unlist()
  api().RemoveListing()
end

-- Flüstervorlage (LT-390): {role} {class} {level} {dungeon} aus Spieler und Gruppe; unbekannte Platzhalter bleiben stehen
local CHAT_LIMIT = 255
local ROLE_KEYS = { TANK = "LFG_ROLE_TANK", HEALER = "LFG_ROLE_HEALER", DAMAGER = "LFG_ROLE_DAMAGER" }

function LFGSearch.WhisperTemplate()
  local text = ns.db.lfgWhisperTemplate
  return (type(text) == "string" and strtrim(text) ~= "") and text or ns.L.LFG_WHISPER_DEFAULT
end

function LFGSearch.WhisperText(summary)
  local roleKey = UnitGroupRolesAssigned and ROLE_KEYS[UnitGroupRolesAssigned("player")]
  local values = { role = roleKey and ns.L[roleKey] or "", class = UnitClass("player") or "",
    level = tostring(UnitLevel("player") or ""), dungeon = summary and summary.activityNames and summary.activityNames[1] or "" }
  local text = LFGSearch.WhisperTemplate():gsub("{(%a+)}", function(key) return values[key] end)
  text = strtrim((text:gsub("%s+", " ")))
  if #text > CHAT_LIMIT then  -- Bytegrenze; nicht mitten in einem UTF-8-Zeichen kappen
    -- shortcut: kappt bei sauberer Grenze ein ganzes Zeichen mehr, harmlos
    text = strtrim((text:sub(1, CHAT_LIMIT):gsub("[\192-\255][\128-\191]*$", "")))
  end
  return text
end

-- Nur aus dem Klick auf Flüstern: sendet die Vorlage an den Leiter
function LFGSearch.Whisper(summary)
  if not (summary and summary.leaderName) or ns.IsSecret(summary.leaderName) then return false end
  local text = LFGSearch.WhisperText(summary)
  if text == "" then return false end
  local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
  send(text, "WHISPER", nil, summary.leaderName)
  ns.Debug("lfg", "whisper template sent to %s", summary.leaderName)
  return true
end

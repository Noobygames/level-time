-- Filter der eigenen Gruppensuche (LT-352, nur WoW Forever): gespeichert pro Account (Einstellung lfgFilters), mit
-- Zurücksetzen. Nur Regeln, keine Anzeige (Bedienung: UI/LFGFilterView.lua, Anwendung: LFGSearch.Results).
-- Gruppen: Art, aufgelöste, Rolle frei (Tank/Heiler/Schaden, eine davon reicht) und hat Tank/Heiler (alle gewählten).
-- Einzelspieler: angebotene Rolle (eine reicht) und Level von/bis. Beide: abgewählte Klassen (Einzelspieler dieser
-- Klasse und Gruppen mit einem Mitglied dieser Klasse fallen weg) und Spielstil. Freunde/Gilde zuerst sortiert die Liste.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    lfgFilters = false,  -- Tabelle (siehe defaults); false = Standard beim ersten Zugriff
  },
})

local LFGFilters = {}
ns.LFGFilters = LFGFilters

LFGFilters.KIND_ALL, LFGFilters.KIND_GROUPS, LFGFilters.KIND_SOLO = "all", "groups", "solo"
LFGFilters.ROLES = { "TANK", "HEALER", "DAMAGER" }
LFGFilters.HAS_ROLES = { "TANK", "HEALER" }  -- "hat Tank/Heiler" gibt es nur für diese beiden
LFGFilters.CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
local SOLO_ROLE_KEYS = { TANK = "tank", HEALER = "healer", DAMAGER = "dps" }  -- Felder von lfgRoles

local function defaults()
  return { kind = LFGFilters.KIND_ALL, hideDelisted = true, socialFirst = true, openRoles = {}, hasRoles = {},
    playerRoles = {}, levelMin = false, levelMax = false, hiddenClasses = {}, playstyle = false }
end

-- Gespeicherte Filter; fehlende Felder (ältere Stände) mit dem Standard ergänzt
function LFGFilters.Get()
  -- Auswahllisten fragen schon beim Laden der Datei ab (SetupMenu); ns.db gibt es erst ab PLAYER_LOGIN
  if not ns.db then return defaults() end
  local filters = ns.db.lfgFilters
  if type(filters) ~= "table" then
    filters = defaults()
    ns.db.lfgFilters = filters
  end
  for key, value in pairs(defaults()) do
    if filters[key] == nil then filters[key] = value end
  end
  return filters
end

function LFGFilters.Reset()
  ns.db.lfgFilters = defaults()
  return ns.db.lfgFilters
end

local function anySet(set)
  return next(set) ~= nil
end

-- Zahl der vom Standard abweichenden Filter (je Bereich eins)
function LFGFilters.ActiveCount(filters)
  local count = 0
  local function add(active) if active then count = count + 1 end end
  add(filters.kind ~= LFGFilters.KIND_ALL)
  add(not filters.hideDelisted)
  add(not filters.socialFirst)
  add(anySet(filters.openRoles))
  add(anySet(filters.hasRoles))
  add(anySet(filters.playerRoles))
  add(filters.levelMin or filters.levelMax)
  add(anySet(filters.hiddenClasses))
  add(filters.playstyle)
  return count
end

local function hasHiddenClass(summary, hidden)
  for _, member in ipairs(summary.members) do
    if member.class and hidden[member.class] then return true end
  end
  return false
end

local function hasRole(summary, role)
  for _, member in ipairs(summary.members) do
    if member.role == role then return true end
  end
  return false
end

local function groupMatches(summary, filters)
  if anySet(filters.openRoles) then
    local open = false
    for role in pairs(filters.openRoles) do
      open = open or (summary.open ~= nil and (summary.open[role] or 0) > 0)
    end
    if not open then return false end
  end
  for role in pairs(filters.hasRoles) do
    if not hasRole(summary, role) then return false end
  end
  return true
end

local function soloMatches(summary, filters)
  local member = summary.members[1]
  if anySet(filters.playerRoles) then
    local offers = false
    for role in pairs(filters.playerRoles) do
      offers = offers or (member ~= nil and member.lfgRoles ~= nil and member.lfgRoles[SOLO_ROLE_KEYS[role]] == true)
    end
    if not offers then return false end
  end
  local level = member and member.level
  if filters.levelMin and not (level and level >= filters.levelMin) then return false end
  if filters.levelMax and not (level and level <= filters.levelMax) then return false end
  return true
end

-- Passt ein Treffer (LFGData.Summary) zu den Filtern?
function LFGFilters.Matches(summary, filters)
  local solo = summary.numMembers == 1
  if filters.hideDelisted and summary.delisted then return false end
  if filters.kind == LFGFilters.KIND_SOLO and not solo then return false end
  if filters.kind == LFGFilters.KIND_GROUPS and solo then return false end
  if anySet(filters.hiddenClasses) and hasHiddenClass(summary, filters.hiddenClasses) then return false end
  if filters.playstyle and summary.generalPlaystyle ~= filters.playstyle then return false end
  if solo then return soloMatches(summary, filters) end
  return groupMatches(summary, filters)
end

-- Freund oder Gildenmitglied im Eintrag?
function LFGFilters.IsSocial(summary)
  return (summary.friends or 0) + (summary.guild or 0) > 0
end

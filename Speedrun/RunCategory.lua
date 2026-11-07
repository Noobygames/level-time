-- Kategorie eines Laufs, automatisch bestimmt: jeder neue Charakter startet als SSF und fällt nur nach unten
-- (SSF -> Solo -> Gruppe -> Geboostet), nie zurück.
--   Solo       Handel, Briefkasten oder Auktionshaus geöffnet (Hilfe von außen, für SSF verboten)
--   Gruppe     in einer Gruppe gewesen
--   Geboostet  ein Gruppenmitglied war mindestens BOOST_LEVEL_GAP Level höher
-- character.runCategory; ältere Charaktere (schon Level vor dieser Version) bleiben unbekannt (nil), bis ein
-- Ereignis sie einordnet. Runs.lua gibt die Kategorie an Läufe und Export weiter, die Speedrun-Tabellen zeigen sie
-- als Spalte (das Suchfeld filtert danach). RunCategory.OnOutsideHelp meldet die Fenster auch dem SSF-Helfer.
local _, ns = ...
local L = ns.L

local RunCategory = {
  SSF = "ssf",
  SOLO = "solo",
  GROUP = "group",
  BOOSTED = "boosted",
  BOOST_LEVEL_GAP = 10,
}
ns.RunCategory = RunCategory

local RANK = { ssf = 1, solo = 2, group = 3, boosted = 4 }
local LABELS = { ssf = "RUN_CATEGORY_SSF", solo = "RUN_CATEGORY_SOLO", group = "RUN_CATEGORY_GROUP",
  boosted = "RUN_CATEGORY_BOOSTED" }
local GROUP_CHECK_SECONDS = 5
local MAX_PARTY_MEMBERS = 4
local MAX_RAID_MEMBERS = 40

-- Fenster, die Hilfe von außen bedeuten (auch für SsfRules.lua)
RunCategory.OUTSIDE_HELP_EVENTS = { "TRADE_SHOW", "MAIL_SHOW", "AUCTION_HOUSE_SHOW" }

local helpListeners = {}

function RunCategory.OnOutsideHelp(listener)
  table.insert(helpListeners, listener)
end

function RunCategory.IsValid(category)
  return RANK[category] ~= nil
end

function RunCategory.Label(category)
  return LABELS[category] and L[LABELS[category]] or "-"
end

-- Nur nach unten: eine schlechtere Kategorie ersetzt die bisherige
local function downgrade(category)
  if not ns.character then return end  -- Events vor dem Login
  local current = ns.character.runCategory
  if current and RANK[current] >= RANK[category] then return end
  ns.Debug("runcategory", "%s -> %s", current, category)
  ns.character.runCategory = category
end

ns.OnLogin(function()
  local character = ns.character
  if character.runCategory == nil and ns.level <= 1 and not next(character.levelHistory) then
    character.runCategory = RunCategory.SSF
  end
end)

for _, event in ipairs(RunCategory.OUTSIDE_HELP_EVENTS) do
  ns.RegisterEvent(event, function()
    downgrade(RunCategory.SOLO)
    for _, listener in ipairs(helpListeners) do ns.SafeCall(listener, event) end
  end)
end

local function readableNumber(value)
  if value == nil or ns.IsSecret(value) or type(value) ~= "number" then return nil end
  return value
end

-- Höchstes Level der anderen Gruppenmitglieder; nil ohne lesbares Level
local function highestMemberLevel()
  local raid = IsInRaid and IsInRaid()
  local prefix, count = raid and "raid" or "party", raid and MAX_RAID_MEMBERS or MAX_PARTY_MEMBERS
  local members = GetNumGroupMembers and GetNumGroupMembers() or count
  local highest
  for index = 1, math.min(count, members) do
    local unit = prefix .. index
    if not UnitIsUnit or not UnitIsUnit(unit, "player") then
      local level = readableNumber(UnitLevel(unit))
      if level and level > 0 and (not highest or level > highest) then highest = level end
    end
  end
  return highest
end

local function checkGroup()
  if not IsInGroup or IsInGroup() ~= true then return end
  downgrade(RunCategory.GROUP)
  local highest = highestMemberLevel()
  if highest and highest - ns.level >= RunCategory.BOOST_LEVEL_GAP then downgrade(RunCategory.BOOSTED) end
end

ns.RegisterEvent("GROUP_ROSTER_UPDATE", checkGroup)
ns.Every(GROUP_CHECK_SECONDS, checkGroup)  -- Level der Mitglieder kommen oft erst nach dem Roster-Event

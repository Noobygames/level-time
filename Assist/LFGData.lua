-- Daten einer Gruppe der Gruppensuche (C_LFGList, nur WoW Forever): Mitglieder mit Klasse/Rolle/Level/Zone, Level-Spanne
-- und Passung zum eigenen Level, offene Rollen, besiegte Bosse, Freunde/Gilde und die offenen Dungeonquests des
-- Charakters in dieser Instanz samt Machbarkeit. Nur Daten und Regeln, keine Anzeige (LFGTooltip.lua; das eigene
-- Fenster LT-272 liest dieselben Getter). Alle API-Rückgaben werden auf Secret-Werte und fehlende Felder geprüft.
-- Felder (Blizzard_GroupFinder, Zweig forever): GetSearchResultInfo = { activityIDs (Vanilla-Stil) / activityID,
-- numMembers, numBNetFriends, numCharFriends, numGuildMates, isDelisted }, GetSearchResultPlayerInfo = { name, level,
-- areaName, classFilename, assignedRole, isLeader }, GetSearchResultMemberCounts = { TANK, HEALER, DAMAGER },
-- GetSearchResultEncounterInfo = Liste besiegter Bossnamen (Client-Sprache), GetActivityInfoTable(activityID) =
-- { mapID, maxNumPlayers, fullName }.
local _, ns = ...

local LFGData = {}
ns.LFGData = LFGData

-- Zustände einer Dungeonquest für die Gruppe
LFGData.DOABLE = "doable"        -- Ziele nicht an besiegte Bosse gebunden
LFGData.BOSS_DEAD = "bossDead"   -- alle Ziel-Gegner sind Bosse, die die Gruppe schon besiegt hat
LFGData.UNKNOWN = "unknown"      -- keine Zieldaten oder Bossnamen nicht zuordenbar

-- Level-Passung des eigenen Charakters zur Spanne der Gruppe
LFGData.FITS, LFGData.ABOVE, LFGData.BELOW = "fits", "above", "below"

local FIT_MARGIN = 2           -- so viele Level außerhalb der Spanne gelten noch als passend
local NO_XP_LEVEL_GAP = 13     -- ab diesem Abstand (höchster zu niedrigstem Level der Gruppe) gibt es keine Erfahrung
local MAX_MEMBERS = 40         -- Raidgröße; mehr liest die Gruppensuche nicht
local DUNGEON_SIZE = 5
local ROLE_NEEDS = { TANK = 1, HEALER = 1, DAMAGER = 3 }  -- Standardbesetzung einer 5er-Gruppe

local function readable(value)
  if value == nil or ns.IsSecret(value) then return nil end
  return value
end

local function lfg() return C_LFGList end

function LFGData.IsAvailable()
  return ns.Client.IsForever() and lfg() ~= nil and lfg().GetSearchResultInfo ~= nil
end

local function call(name, ...)
  local api = lfg()
  if not (api and api[name]) then return nil end
  return readable(api[name](...))
end

-- Mitglieder: { { name, class, role, level, area, isLeader }, ... } (Felder ohne lesbaren Wert fehlen)
function LFGData.Members(resultID, count)
  local members = {}
  for index = 1, math.min(readable(count) or 0, MAX_MEMBERS) do
    local player = call("GetSearchResultPlayerInfo", resultID, index)
    if type(player) == "table" then
      local area = readable(player.areaName)
      table.insert(members, { name = readable(player.name), class = readable(player.classFilename),
        role = readable(player.assignedRole), level = readable(player.level), lfgRoles = readable(player.lfgRoles),
        area = (area ~= "" and area) or nil, isLeader = readable(player.isLeader) == true })
    end
  end
  return members
end

-- Niedrigstes und höchstes Level der Mitglieder (nil ohne bekannte Level)
function LFGData.LevelRange(members)
  local low, high
  for _, member in ipairs(members) do
    if member.level and member.level > 0 then
      low = math.min(low or member.level, member.level)
      high = math.max(high or member.level, member.level)
    end
  end
  return low, high
end

-- Passung eines Levels zur Spanne: FITS, ABOVE (zu hoch), BELOW (zu niedrig); nil ohne Spanne
function LFGData.Fit(level, low, high)
  if not (level and low and high) then return nil end
  if level > high + FIT_MARGIN then return LFGData.ABOVE end
  if level < low - FIT_MARGIN then return LFGData.BELOW end
  return LFGData.FITS
end

-- Keine Erfahrung (WoW Forever): liegt irgendein Mitglied, den eigenen Charakter eingerechnet, 13 oder mehr Level über
-- dem niedrigsten, gibt es für niemanden Erfahrung. Rückgabe niedrigstes, höchstes Level oder nil.
function LFGData.NoExperience(members, ownLevel)
  local low, high = LFGData.LevelRange(members)
  if not low then return nil end
  if ownLevel then low, high = math.min(low, ownLevel), math.max(high, ownLevel) end
  if high - low >= NO_XP_LEVEL_GAP then return low, high end
  return nil
end

-- Offene Plätze: { free, TANK, HEALER, DAMAGER } (Rollen nur bei 5er-Gruppen mit Rollenzählung, sonst nur free)
function LFGData.OpenRoles(resultID, numMembers, maxPlayers)
  if not (numMembers and maxPlayers) then return nil end
  local open = { free = math.max(0, maxPlayers - numMembers) }
  local counts = call("GetSearchResultMemberCounts", resultID)
  if maxPlayers == DUNGEON_SIZE and type(counts) == "table" then
    for role, needed in pairs(ROLE_NEEDS) do
      open[role] = math.max(0, needed - (readable(counts[role]) or 0))
    end
  end
  return open
end

-- Namen der besiegten Bosse (Client-Sprache); leer, wenn die Gruppe keine meldet
function LFGData.KilledBosses(resultID)
  local names = {}
  local encounters = call("GetSearchResultEncounterInfo", resultID)
  if type(encounters) == "table" then
    for _, name in ipairs(encounters) do
      if readable(name) and name ~= "" then table.insert(names, name) end
    end
  end
  return names
end

-- NPC-IDs der besiegten Bosse einer Instanz: Bossnamen der Gruppe gegen die Boss-Liste der Karte abgleichen
function LFGData.KilledBossNpcs(mapID, killedNames)
  local killed, wanted = {}, {}
  for _, name in ipairs(killedNames) do wanted[name] = true end
  for _, encounterID in ipairs(ns.InstanceBosses.List(mapID) or {}) do
    local name = ns.InstanceBosses.Name(encounterID)
    local npcID = ns.InstanceBosses.NpcID(encounterID)
    if name and npcID and wanted[name] then killed[npcID] = true end
  end
  return killed
end

-- Machbarkeit einer Quest bei den besiegten Bossen (NPC-ID-Menge): DOABLE, BOSS_DEAD oder UNKNOWN
function LFGData.Feasibility(questID, killedNpcs)
  local targets = ns.DungeonQuests.TargetNpcs(questID)
  if not targets then
    return ns.DungeonQuests.Objectives(questID) and LFGData.DOABLE or LFGData.UNKNOWN
  end
  for npcID in pairs(targets) do
    if not killedNpcs[npcID] then return LFGData.DOABLE end
  end
  return LFGData.BOSS_DEAD
end

-- Offene Dungeonquests des Charakters in den Instanzen der Gruppe:
-- { { questID, title, state, takeable }, ... }; takeable = false: noch nicht annehmbar (Level oder Vorquest fehlt)
function LFGData.Quests(mapIDs, killedNames)
  local list = {}
  if not ns.DungeonQuests.IsAvailable() then return list end
  for _, mapID in ipairs(mapIDs) do
    local killedNpcs = LFGData.KilledBossNpcs(mapID, killedNames)
    for _, quest in ipairs(ns.DungeonQuests.OwnQuests(mapID)) do
      local takeable = quest.inLog or ns.DungeonQuests.CanTake(quest.questID)
      table.insert(list, { questID = quest.questID, title = quest.title, takeable = takeable,
        state = LFGData.Feasibility(quest.questID, killedNpcs) })
    end
  end
  return list
end

-- Alles zu einer Gruppe auf einmal (Listenzeile und Detail des Gruppensuche-Fensters); nil, wenn die Gruppe nicht lesbar ist
function LFGData.Summary(resultID)
  if not LFGData.IsAvailable() or resultID == nil or ns.IsSecret(resultID) then return nil end
  local info = call("GetSearchResultInfo", resultID)
  if type(info) ~= "table" then return nil end
  local numMembers = readable(info.numMembers)
  local activityIDs = readable(info.activityIDs) or { readable(info.activityID) }
  local mapIDs, maxPlayers, activityNames = {}, nil, {}
  for _, activityID in ipairs(activityIDs) do
    local activity = call("GetActivityInfoTable", activityID)
    local activityName = type(activity) == "table" and readable(activity.fullName)
    if activityName and activityName ~= "" then table.insert(activityNames, activityName) end
    local mapID = type(activity) == "table" and readable(activity.mapID)
    if mapID and mapID > 0 then table.insert(mapIDs, mapID) end
    maxPlayers = maxPlayers or (type(activity) == "table" and readable(activity.maxNumPlayers)) or nil
  end
  local ownLevel = readable(UnitLevel("player"))
  local members = LFGData.Members(resultID, numMembers)
  local low, high = LFGData.LevelRange(members)
  local killed = LFGData.KilledBosses(resultID)
  local noXpLow, noXpHigh = LFGData.NoExperience(members, ownLevel)
  return {
    activityNames = activityNames, leaderName = readable(info.leaderName), title = readable(info.name),
    comment = readable(info.comment), voiceChat = readable(info.voiceChat), age = readable(info.age),
    newPlayerFriendly = readable(info.newPlayerFriendly) == true, autoAccept = readable(info.autoAccept) == true,
    crossFaction = readable(info.crossFactionListing) == true, requiredItemLevel = readable(info.requiredItemLevel),
    hasSelf = readable(info.hasSelf) == true,
    resultID = resultID, delisted = readable(info.isDelisted) == true, members = members, numMembers = numMembers,
    levelLow = low, levelHigh = high, ownLevel = ownLevel, fit = LFGData.Fit(ownLevel, low, high),
    open = LFGData.OpenRoles(resultID, numMembers, maxPlayers), killedBosses = killed,
    friends = (readable(info.numBNetFriends) or 0) + (readable(info.numCharFriends) or 0),
    guild = readable(info.numGuildMates) or 0, noXpLow = noXpLow, noXpHigh = noXpHigh,
    quests = #activityIDs == 1 and LFGData.Quests(mapIDs, killed) or {},
  }
end

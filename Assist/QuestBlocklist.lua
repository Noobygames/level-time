-- Sperrliste der Quest-Automatik (Roadmap 260): NPCs und Quests, bei denen QuestAutomation nichts selbst tut,
-- weil die Abgabe Gegenstände verbraucht, die man nicht nebenbei loswerden will.
--   BLOCKED_NPCS    NPC-ID (6. Feld der GUID von "npc"). Eigene Liste, nicht aus einem anderen Addon übernommen:
--                   die Stoff-Quartiermeister der Hauptstädte (Classic/Forever) nehmen für "Spende von Wolle,
--                   Seide, Magiestoff, Runenstoff" je 60 Stoff und danach wiederholbar Runenstoff
--                   (IDs von warcraft.wiki.gg/Wowhead, 14722..14729).
--   BLOCKED_QUESTS  Quest-ID, wo der NPC selbst nicht gesperrt ist; 7820 "Spendet Wolle" aus dem Debug-Log (Forever).
--   questExclude    Einstellung (Komfort > Automatik): eigene Einträge, durch Komma oder Semikolon getrennt;
--                   Zahl = Quest- oder NPC-ID, Text = Name des NPC oder Titel der Quest (Groß-/Kleinschreibung egal).
-- Wiederholbare Quests im offenen Dialog erkennt QuestAutomation selbst (C_QuestLog.IsRepeatableQuest, nur
-- Retail/Forever); in Classic Era/TBC bleiben sie nur in den Gesprächs- und Grußlisten ausgeschlossen.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    questExclude = "",
  },
})

local QuestBlocklist = {}
ns.QuestBlocklist = QuestBlocklist

local NPC_UNIT = "npc"
local SEPARATORS = "[^,;]+"

local BLOCKED_NPCS = {  -- englische Namen wie auf warcraft.wiki.gg
  [14722] = true,  -- Clavicus Knavingham, Stormwind
  [14723] = true,  -- Mistina Steelshield, Ironforge
  [14724] = true,  -- Bubulo Acerbus, Gnomeregan Exiles (Tinkertown)
  [14725] = true,  -- Raedon Duskstriker, Darnassus
  [14726] = true,  -- Rashona Straglash, Orgrimmar
  [14727] = true,  -- Vehena, Darkspear Trolls (Orgrimmar)
  [14728] = true,  -- Rumstag Proudstrider, Thunder Bluff
  [14729] = true,  -- Ralston Farnsley, Undercity
}

local BLOCKED_QUESTS = {
  [7820] = true,  -- Spendet Wolle
}

-- NPC-ID aus einer GUID ("Creature-0-<server>-<instanz>-<zone>-<npcId>-<spawn>"); nil bei Spielern und geheimen Werten
function QuestBlocklist.NpcId(guid)
  if type(guid) ~= "string" or ns.IsSecret(guid) then return nil end
  local id = guid:match("^%a+%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
  return id and tonumber(id)
end

-- Eigene Einträge aus der Einstellung: Zahlen und Texte (klein)
local function exclusions()
  local numbers, names = {}, {}
  local text = ns.db and ns.db.questExclude
  if type(text) ~= "string" then return numbers, names end
  for entry in text:gmatch(SEPARATORS) do
    entry = strtrim(entry)
    local number = tonumber(entry)
    if number then numbers[number] = true elseif entry ~= "" then names[entry:lower()] = true end
  end
  return numbers, names
end

local function matchesName(names, name)
  return type(name) == "string" and not ns.IsSecret(name) and names[name:lower()] == true
end

-- true, wenn die Automatik beim gerade offenen NPC nichts tun soll
function QuestBlocklist.IsBlockedNpc()
  local id = QuestBlocklist.NpcId(UnitGUID(NPC_UNIT))
  local numbers, names = exclusions()
  if id and (BLOCKED_NPCS[id] or numbers[id]) then return true end
  return UnitExists(NPC_UNIT) and matchesName(names, UnitName(NPC_UNIT))
end

-- true, wenn diese Quest (ID und/oder Titel) nie automatisch angenommen oder abgegeben wird
function QuestBlocklist.IsBlockedQuest(questID, title)
  local numbers, names = exclusions()
  if type(questID) == "number" and not ns.IsSecret(questID) and (BLOCKED_QUESTS[questID] or numbers[questID]) then
    return true
  end
  return matchesName(names, title)
end

-- NPC oder Quest gesperrt; mit Debug-Zeile
function QuestBlocklist.Blocks(questID, title)
  if QuestBlocklist.IsBlockedNpc() or QuestBlocklist.IsBlockedQuest(questID, title) then
    ns.Debug("quests", "blocked: quest %s (%s)", questID, title)
    return true
  end
  return false
end

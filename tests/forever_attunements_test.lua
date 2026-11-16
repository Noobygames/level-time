-- Schlüssel- und Einstimmungsreihen (LT-254, WoW Forever): Schritte aus den Vorquests der Dungeon-DB mit Stand,
-- Anzeige im Tooltip des Eingangs mit Hinweis "für Forever unbestätigt".
local L = addon.L
local Attunements = addon.Attunements

local completed = { [3801] = true, [4182] = true }
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end
C_Map = C_Map or {}
C_Map.GetMapInfo = function(uiMapID) return { name = "Karte " .. uiMapID } end
GetRealZoneText = function(mapID) return "Instanz " .. tostring(mapID) end
wow.state.questLog = { { questID = 3802, title = "Dunkeleisernes Vermächtnis", objectives = {} } }
wow.login({ level = 58 })
wow.fire("QUEST_LOG_UPDATE")

local function byMap(list)
  local result = {}
  for _, entry in ipairs(list) do result[entry.mapID] = entry end
  return result
end

local function ids(steps)
  local list = {}
  for _, step in ipairs(steps) do table.insert(list, step.questID) end
  return table.concat(list, ",")
end

-- Schwarzfelstiefen-Eingang: Schattenschmiedeschlüssel (1 von 2, zweiter Schritt im Log) und Geschmolzener Kern
local brd = byMap(Attunements.At(230))
expect("Schlüssel: Schritte", ids(brd[230].steps), "3801,3802")
expect("Schlüssel: erledigt", brd[230].done, 1)
expect("Schlüssel: Stand", brd[230].steps[2].status, "active")
expect("Kern: ein Schritt", brd[409].steps[1].questID .. "/" .. #brd[409].steps, "7848/1")

-- Schwarzfelsspitze: Siegel des Aufstiegs und Onyxia (Allianz, 16 Schritte über preAny)
local ubrs = byMap(Attunements.At(229))
expect("Siegel", ids(ubrs[229].steps), "4742,4743")
expect("Onyxia Allianz: Anzahl", #ubrs[249].steps, 16)
expect("Onyxia Allianz: Anfang", ubrs[249].steps[1].questID, 4182)
expect("Onyxia Allianz: Ende", ubrs[249].steps[16].questID, 6502)

-- Tooltip: Kopf mit Sternchen und Stand, nächster Schritt mit Geber-Ort aus der Dungeon-DB, Rest gekürzt
GameTooltip:SetOwner(UIParent)
Attunements.AddLines(GameTooltip, 229)
local lines = table.concat(GameTooltip._lines, "\n")
local onyxiaTitle = string.format(L.ATTUNEMENT_TITLE, "Instanz 249", 1, 16) .. " " .. addon.UnverifiedHint.Mark()
expectTrue("Kopf Onyxia", lines:find(onyxiaTitle, 1, true) ~= nil)
expectTrue("nächster Schritt mit Ort", lines:find("Karte 1428 (86, 69)", 1, true) ~= nil)
expectTrue("weitere gekürzt", lines:find(string.format(L.DUNGEON_QUESTS_MORE, 11), 1, true) ~= nil)
expect("Hinweiszeile zuletzt", GameTooltip._lines[#GameTooltip._lines], L.FOREVER_UNVERIFIED)

-- Erledigte Reihe: eine Zeile mit "Erledigt"
completed[3802] = true
wow.state.questLog = {}
wow.fire("QUEST_LOG_UPDATE")
GameTooltip:SetOwner(UIParent)
Attunements.AddLines(GameTooltip, 230)
expect("erledigt", GameTooltip._lines[1], string.format(L.ATTUNEMENT_KEY_TITLE, "Instanz 230", 2, 2) .. " "
  .. addon.UnverifiedHint.Mark() .. " = " .. L.ATTUNEMENT_DONE)

-- Horde: eigene Onyxia-Reihe mit den drei parallelen Schädelprüfungen vor Axtroz
wow.state.faction = "Horde"
local horde = byMap(Attunements.At(229))[249]
expect("Onyxia Horde", ids(horde.steps), "4903,4941,4974,6566,6567,6568,6569,6570,6582,6583,6584,6585,6601,6602")

-- Ohne Reihe am Eingang: nichts
GameTooltip:SetOwner(UIParent)
Attunements.AddLines(GameTooltip, 3065)
expect("andere Instanz leer", #GameTooltip._lines, 0)

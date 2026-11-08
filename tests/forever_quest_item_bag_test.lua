-- Quest-Item-Knopf ohne Quest-Item im Questlog (WoW Forever, Mondbrunnen-Quest): benutzbare Gegenstände aus den
-- Taschen, beim Annehmen erhalten, über die Questinfo des Clients oder mit dem Namen im offenen Zieltext. Das
-- Quest-Item des Questlogs gewinnt, fremde benutzbare Gegenstände und gesammelte Zielgegenstände bleiben weg.
local QuestItem = addon.QuestItem
local item = LevelTimerQuestItemButton

local MAPS = {
  [947] = { name = "Azeroth", mapType = 1, parentMapID = 0 },
  [1414] = { name = "Kalimdor", mapType = 2, parentMapID = 947 },
  [1438] = { name = "Teldrassil", mapType = 3, parentMapID = 1414 },
  [1439] = { name = "Darkshore", mapType = 3, parentMapID = 1414 },
}
C_Map = {
  GetBestMapForUnit = function() return wow.state.mapID end,
  GetMapInfo = function(mapID)
    local map = MAPS[mapID]
    return map and { mapID = mapID, name = map.name, mapType = map.mapType, parentMapID = map.parentMapID }
  end,
  GetMapChildrenInfo = function() return {} end,
}
local questMaps = { [80] = 1438, [81] = 1438, [82] = 1438, [83] = 1438, [84] = 1439 }
function GetQuestUiMapID(questID) return questMaps[questID] or 0 end

local function link(id, name) return "|cffffffff|Hitem:" .. id .. "::::|h[" .. name .. "]|h|r" end
local function bagItem(id, name, extra)
  local entry = { itemID = id, itemName = name, hyperlink = link(id, name), iconFileID = 130000 + id, stackCount = 1 }
  for key, value in pairs(extra or {}) do entry[key] = value end
  return entry
end
local function byQuest()
  local found = {}
  for _, candidate in ipairs(QuestItem.Candidates()) do found[candidate.questID] = candidate end
  return found
end
local function bagsChanged()
  wow.fire("BAG_UPDATE_DELAYED")
  wow.update(1)
end

wow.state.questLog = {
  { title = "Teldrassil", isHeader = true },
  { title = "Mondbrunnen", questID = 80, objectives = { { text = "Gefüllte geätzte Phiole: 0/1", finished = false } } },
  { title = "Proben", questID = 82, specialItem = { link(8000, "Probenkasten"), 134000 },
    objectives = { { text = "Gefüllte geätzte Phiole: 0/1", finished = false } } },
  { title = "Spinnen", questID = 81, objectives = { { text = "Spinnenbein: 2/5", finished = false } } },
}
wow.state.itemSpells = {
  [7001] = { name = "Phiole füllen", id = 1 }, [118] = { name = "Heilen", id = 2 },
  [7002] = { name = "Trinken", id = 3 }, [7300] = { name = "Lesen", id = 4 }, [7100] = { name = "Signal", id = 5 },
  [7200] = { name = "Zünden", id = 6 },
}
wow.state.bags[0] = {
  bagItem(7001, "Geätzte Phiole"),
  bagItem(118, "Schwacher Heiltrank"),
  bagItem(7002, "Gefüllte geätzte Phiole"),  -- Zielgegenstand selbst: gesammelt, nicht benutzt
  bagItem(7300, "Spinnenbein"),               -- benutzbar, aber genau ein Ziel
  bagItem(9000, "Leinenstoff"),               -- nicht benutzbar
}
wow.state.zone, wow.state.mapID = "Teldrassil", 1438
wow.login({ level = 10 })
addon.Set("questItemButton", true)

-- Name im offenen Zieltext; das Quest-Item des Questlogs gewinnt bei Quest 82
local found = byQuest()
expect("Mondbrunnen: Phiole aus den Taschen", found[80] and found[80].itemId, 7001)
expect("Quelle Zieltext", found[80] and found[80].source, "objective")
expect("Symbol aus den Taschen", found[80] and found[80].texture, 137001)
expect("Quest-Item gewinnt", found[82] and found[82].itemId, 8000)
expect("Quest-Item-Quelle", found[82] and found[82].source, "special")
expect("Zielgegenstand ist kein Kandidat", found[81], nil)
local count = 0
for _, candidate in ipairs(QuestItem.Candidates()) do
  count = count + 1
  local id = candidate.itemId
  expectTrue("kein fremder Gegenstand", id ~= 118 and id ~= 7002 and id ~= 9000)
end
expect("zwei Kandidaten", count, 2)
expect("Quest-Item zuerst gewählt", item:GetAttribute("item"), "item:8000")

-- Ziel erfüllt: kein Namenstreffer mehr
wow.state.questLog[2].objectives[1].finished = true
wow.fire("QUEST_LOG_UPDATE")
expect("erfülltes Ziel: kein Taschen-Kandidat", byQuest()[80], nil)
wow.state.questLog[2].objectives[1].finished = false
wow.fire("QUEST_LOG_UPDATE")

-- Beim Annehmen erhalten: Questtext offen, Annahme, Gegenstand kommt danach in die Taschen
wow.fire("QUEST_DETAIL")
table.insert(wow.state.questLog, { title = "Signal", questID = 83 })
wow.fire("QUEST_ACCEPTED", 83)
wow.advance(1)
wow.state.bags[0][6] = bagItem(7100, "Signalfackel")
wow.fire("QUEST_LOG_UPDATE")
bagsChanged()
found = byQuest()
expect("übergeben: Kandidat", found[83] and found[83].itemId, 7100)
expect("Quelle Übergabe", found[83] and found[83].source, "handed")
expectTrue("gemerkt je Charakter", addon.character.questStartItems[83][7100] == true)
expect("zuletzt angenommen gewählt", item:GetAttribute("item"), "item:7100")

-- Später Geplündertes gehört nicht zur Quest
wow.advance(10)
wow.state.bags[0][7] = bagItem(7200, "Zündschnur")
bagsChanged()
expect("nach der Übergabezeit nichts gelernt", addon.character.questStartItems[83][7200], nil)

-- Questinfo des Clients: questID einer laufenden Quest ordnet zu; isQuestItem allein nicht
wow.state.bags[0][7].questInfo = { isQuestItem = true, questID = 84, isActive = true }
table.insert(wow.state.questLog, { title = "Darkshore", isHeader = true })
table.insert(wow.state.questLog, { title = "Dunkelküste", questID = 84 })
wow.state.bags[0][2].questInfo = { isQuestItem = true, isActive = false }
wow.fire("QUEST_LOG_UPDATE")
bagsChanged()
found = byQuest()
expect("Questinfo: Kandidat", found[84] and found[84].itemId, 7200)
expect("Quelle Questinfo", found[84] and found[84].source, "questInfo")
for _, candidate in ipairs(QuestItem.Candidates()) do
  expectTrue("isQuestItem allein reicht nicht", candidate.itemId ~= 118)
end

-- Zone: Quest 84 liegt in der Dunkelküste und füllt den Knopf in Teldrassil nicht
wow.fire("QUEST_ACCEPTED", 84)
wow.update(1)
expect("andere Zone: nicht gewählt", item:GetAttribute("item"), "item:7100")
wow.state.zone, wow.state.mapID = "Darkshore", 1439
wow.fire("ZONE_CHANGED_NEW_AREA")
expect("in der Dunkelküste gewählt", item:GetAttribute("item"), "item:7200")

-- Questreste: nur sichere Zuordnungen zählen, nicht der Namenstreffer
addon.Set("questLeftovers", true)
wow.fire("QUEST_LOG_UPDATE")
wow.update(2)
local special = addon.character.questSpecialItems
expect("Quest-Item gemerkt", special[82], 8000)
expect("Übergabe gemerkt", special[83], 7100)
expect("Questinfo gemerkt", special[84], 7200)
expect("Namenstreffer nicht gemerkt", special[80], nil)

-- Quest abgegeben: Übergabe vergessen
wow.fire("QUEST_TURNED_IN", 83, 0, 0)
expect("Übergabe vergessen", addon.character.questStartItems[83], nil)
expect("Fehler?", #wow.errors, 0)

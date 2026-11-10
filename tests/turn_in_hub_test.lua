-- Smart Turn-In Hub (Roadmap 454): Abgabe-Routen nach NPC, Koordinaten und Zone bündeln.
local L = addon.L
local QuestViews = addon.QuestViews
local QuestNpcs = addon.QuestNpcs

-- 1. Unit Tests für QuestNpcs.TurnInHub und QuestNpcs.SameHub
LevelTimerStatsDB = LevelTimerStatsDB or {}
LevelTimerStatsDB.questNpcs = {
  [10] = { turnIn = { name = "Gryan", npcId = 234, mapID = 1429, x = 0.40, y = 0.60 } },
  [11] = { turnIn = { name = "Gryan", npcId = 234, mapID = 1429, x = 0.40, y = 0.60 } },
  [12] = { turnIn = { name = "Danuvin", npcId = 235, mapID = 1429, x = 0.43, y = 0.64 } }, -- dist = 0.05 <= 0.06
  [13] = { turnIn = { name = "Lighthouse Keeper", npcId = 300, mapID = 1429, x = 0.80, y = 0.20 } }, -- dist weit
  [14] = { turnIn = { mapID = 1429, x = 0.50, y = 0.50 } }, -- Ohne NPC-Name
  -- 20, 21: Keine gelernte Abgabe
}

-- TurnInHub
local name, mapID, x, y = QuestNpcs.TurnInHub(10, "Westfall")
expect("TurnInHub mit Name", name, "Gryan")
expect("TurnInHub mapID", mapID, 1429)
expectNear("TurnInHub x", x, 0.40)
expectNear("TurnInHub y", y, 0.60)

local nameNoNpc = QuestNpcs.TurnInHub(14, "Westfall")
expect("TurnInHub ohne NPC-Name nutzt Fallback", nameNoNpc, "Westfall")

local nameUngelernt, mapUngelernt = QuestNpcs.TurnInHub(20, "Dunkelhain")
expect("TurnInHub ungelernt nutzt Fallback", nameUngelernt, "Dunkelhain")
expect("TurnInHub ungelernt mapID", mapUngelernt, nil)

-- SameHub
expectTrue("gleicher NPC", QuestNpcs.SameHub(10, 11, "Westfall", "Westfall"))
expectTrue("nahe Koordinaten auf derselben Karte (<= 0.06)", QuestNpcs.SameHub(10, 12, "Westfall", "Westfall"))
expect("ferne Koordinaten (> 0.06)", QuestNpcs.SameHub(10, 13, "Westfall", "Westfall"), false)
expectTrue("ungelernt in derselben Zone teilt Hub", QuestNpcs.SameHub(20, 21, "Dunkelhain", "Dunkelhain"))
expect("ungelernt in verschiedenen Zonen", QuestNpcs.SameHub(20, 21, "Dunkelhain", "Rotkammgebirge"), false)
expect("gelernt vs ungelernt teilt nicht", QuestNpcs.SameHub(10, 20, "Westfall", "Westfall"), false)

-- 2. QuestViews.TurnInHubs und QuestViews.TurnInRecords Bündelung & Sortierung
wow.state.questLog = {
  { title = "Westfall", isHeader = true },
  { questID = 10, title = "Defias 1", level = 12, isComplete = 1, rewardXp = 600 },
  { questID = 12, title = "Defias 2", level = 13, isComplete = 1, rewardXp = 800 },
  { title = "Dunkelhain", isHeader = true },
  { questID = 20, title = "Spinnen", level = 20, isComplete = 1, rewardXp = 500 },
}

wow.login({ level = 14, xpMax = 2000 })

local hubs = QuestViews.TurnInHubs(addon.characterKey)
expect("zwei Hubs", #hubs, 2)
-- Größter Hub zuerst (count descending, dann xp descending)
expect("Hub 1 Count", hubs[1].count, 2)
expect("Hub 1 XP", hubs[1].xp, 1400)
expect("Hub 1 Quests", #hubs[1].quests, 2)
expect("Hub 2 Count", hubs[2].count, 1)
expect("Hub 2 XP", hubs[2].xp, 500)
expect("Hub 2 Zone", hubs[2].zone, "Dunkelhain")

local records = QuestViews.TurnInRecords(addon.characterKey)
expect("drei Records", #records, 3)

-- Die beiden Quests des 2er-Hubs müssen zuerst kommen mit hubCount = 2, hubXp = 1400
expect("Record 1 gehört zum 2er-Hub", records[1].hubCount, 2)
expect("Record 1 hubXp", records[1].hubXp, 1400)
expect("Record 2 gehört zum 2er-Hub", records[2].hubCount, 2)
expect("Record 2 hubXp", records[2].hubXp, 1400)

-- Single-Quest-Hub in anderer Zone muss danach kommen
expect("Record 3 gehört zum Single-Hub", records[3].hubCount, 1)
expect("Record 3 Zone", records[3].zone, "Dunkelhain")
expect("Record 3 Title", records[3].title, "Spinnen")

-- UI-Spalte HISTORY_TURN_IN_NPC Formatierung (z.B. "Name (2×)")
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Quests", wow.click(L.HISTORY_GROUP_ANALYSIS))
expectTrue("Unterreiter Abgabe", wow.click(L.HISTORY_TAB_TURN_IN))
local shown = wow.shownTable()
expect("Tabelle zeigt 3 Records", #shown:GetVisibleRecords(), 3)

-- Anderer Charakter: leer
expect("anderer Charakter leer", #QuestViews.TurnInHubs("Other-Realm"), 0)
expect("anderer Charakter records leer", #QuestViews.TurnInRecords("Other-Realm"), 0)

expect("Fehler?", #wow.errors, 0)

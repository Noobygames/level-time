-- Level Time Data Extractor (lokal): Datensammler für NPCs, Kill-XP, Beute, Quests (Start, Belohnung, Abgabe,
-- Fortschritt mit Quelle) und Status-Befehl. Das Szenario lädt den Extractor automatisch (Name enthält "extractor").
local X = extractor

-- Ort des Spielers: Karte 1429 bei 45,1 % / 30,2 % = Zelle 45 * 100 + 30
C_Map = {
  GetBestMapForUnit = function() return 1429 end,
  GetPlayerMapPosition = function() return { GetXY = function() return 0.451, 0.302 end } end,
}
local CELL = 4530

local WOLF_GUID = "Creature-0-1-2-3-299-0000ABCDEF"
local WOLF_LINK = "|cff9d9d9d|Hitem:2672::::::::5:::::|h[Zähes Wolfsfleisch]|h|r"
wow.state.questLog = {
  { questID = 50, title = "Pelze", objectives = { { text = "Wolfsfleisch: 1/8", type = "item", numFulfilled = 1,
    numRequired = 8, finished = false } } },
}
wow.login({ level = 6 })
local db = LevelTimerExtractorDB
expect("Speicher angelegt", db.schema, X.SCHEMA)
expectTrue("Build gemerkt", next(db.builds) ~= nil)

-- Ziel: Name, Level, Lebenspunkte, Ort
wow.state.units.target = { guid = WOLF_GUID, name = "Wolf", level = 5, healthMax = 120 }
wow.fire("PLAYER_TARGET_CHANGED")
local wolf = db.npcs[299]
expect("NPC-Name", wolf.names.deDE, "Wolf")
expect("NPC-Level", wolf.levels[5], 1)
expect("Lebenspunkte je Level", wolf.health[5], 120)
expect("Ort", wolf.spots[1429][CELL], 1)
wow.fire("PLAYER_TARGET_CHANGED")
expect("gleiche Einheit kurz danach nicht doppelt", wolf.seen, 1)

-- Kill-XP: nur die reine Grundzeile zählt als XP-Wert, jede Zeile als Kill
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", string.format(COMBATLOG_XPGAIN_FIRSTPERSON, "Wolf", 45))
expect("Kill gezählt", wolf.kills, 1)
expect("Kill-XP je Level", wolf.xp["6:5"], 45)
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", string.format(COMBATLOG_XPGAIN_FIRSTPERSON, "Wolf", 90) .. " (+45 Erholung)")
expect("Bonus-Zeile: XP-Wert bleibt", wolf.xp["6:5"], 45)

-- Questfortschritt: erster Durchlauf = Ausgangsstand
wow.fire("QUEST_LOG_UPDATE")
wow.runTimers()

-- Beute: ein Gegenstand vom Wolf; dasselbe Fenster nochmal zählt nicht doppelt
wow.state.lootSlots = 1
function GetLootSourceInfo() return WOLF_GUID, 1 end
function GetLootSlotType() return 1 end
function GetLootSlotLink() return WOLF_LINK end
function GetLootSlotInfo() return 134000, "Zähes Wolfsfleisch", 1 end
wow.fire("LOOT_READY")
wow.fire("LOOT_READY")
expect("Leiche einmal gezählt", wolf.looted, 1)
expect("Beute je Gegenstand", wolf.loot[2672], 1)

-- Ziel kommt voran: Quelle = letzter Kill und letzte Beute, Ort
wow.state.questLog[1].objectives[1].numFulfilled = 2
wow.fire("QUEST_LOG_UPDATE")
wow.runTimers()
local progress = db.quests[50].progress[1]
expect("Fortschritt vom Wolf", progress.npcs[299], 1)
expect("Fortschritt durch Wolfsfleisch", progress.items[2672], 1)
expect("Fortschritt mit Ort", progress.spots[1429][CELL], 1)

-- Quest-Fenster: Questgeber und Ort; Abgabe mit XP und Geld je Level
wow.state.units.questnpc = { guid = "Creature-0-1-2-3-823-0000000001", name = "Marschall" }
wow.state.questID, wow.state.questTitle = 783, "Eine drohende Gefahr"
wow.fire("QUEST_DETAIL")
local quest = db.quests[783]
expect("Questname", quest.names.deDE, "Eine drohende Gefahr")
expect("Questgeber", quest.starts["npc:823"], 1)
wow.fire("QUEST_TURNED_IN", 783, 80, 25)
expect("Abgabe-XP je Level", quest.turnIns[6].xp, 80)
expect("Abgabe-Geld", quest.turnIns[6].money, 25)

-- Angenommen kurz nach einer Abgabe: Hinweis auf eine Vorquest
wow.state.questLog[2] = { questID = 7, title = "Folgequest", rewardXp = 120, objectives = {} }
wow.fire("QUEST_ACCEPTED", 2, 7)
expect("Vorquest-Hinweis", db.quests[7].after[783], 1)
expect("Questlog-XP je Level", db.quests[7].xpAt[6], 120)

-- Status-Befehl
SlashCmdList.LEVELTIMEREXTRACTOR("")
expectTrue("Status im Chat", wow.printed[#wow.printed]:find("Data Extractor", 1, true) ~= nil)
expect("keine Lua-Fehler", #wow.errors, 0)

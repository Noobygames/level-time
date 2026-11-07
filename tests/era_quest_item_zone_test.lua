-- Quest-Knöpfe nur in der Zone der Quest (Classic Era): Questlog-Überschriften als Zonen, Kategorien filtern nicht,
-- Kleinstkarten zählen zur Zone, Zonenwechsel, Kampf, Einstellung aus
local QuestItem = addon.QuestItem
local item = LevelTimerQuestItemButton
local target = LevelTimerQuestTargetButton

-- Kartendaten wie C_Map in Classic: Welt > Kontinent > Zonen, eine Höhle unter Elwynn
local MAPS = {
  [947] = { name = "Azeroth", mapType = 1, parentMapID = 0 },
  [1415] = { name = "Östliche Königreiche", mapType = 2, parentMapID = 947 },
  [1429] = { name = "Wald von Elwynn", mapType = 3, parentMapID = 1415 },
  [1436] = { name = "Westfall", mapType = 3, parentMapID = 1415 },
  [1431] = { name = "Dämmerwald", mapType = 3, parentMapID = 1415 },
  [9001] = { name = "Jaspismine", mapType = 5, parentMapID = 1429 },
}
C_Map = {
  GetBestMapForUnit = function() return wow.state.mapID end,
  GetMapInfo = function(mapID)
    local map = MAPS[mapID]
    return map and { mapID = mapID, name = map.name, mapType = map.mapType, parentMapID = map.parentMapID }
  end,
  GetMapChildrenInfo = function(root)
    local list = {}
    for mapID in pairs(MAPS) do
      if mapID ~= root then table.insert(list, C_Map.GetMapInfo(mapID)) end
    end
    return list
  end,
}
local function goTo(zone, mapID)
  wow.state.zone, wow.state.mapID = zone, mapID
  wow.fire("ZONE_CHANGED_NEW_AREA")
end

wow.state.questLog = {
  { title = "Wald von Elwynn", isHeader = true },
  { title = "Fackeln", questID = 70, specialItem = { "|cffffffff|Hitem:5000::::|h[Fackel]|h|r", 134000 } },
  { title = "Westfall", isHeader = true },
  { title = "Proben", questID = 72, specialItem = { "|cffffffff|Hitem:6000::::|h[Phiole]|h|r", 134001 } },
  { title = "Krieger", isHeader = true },
  { title = "Klassenquest", questID = 74, specialItem = { "|cffffffff|Hitem:7000::::|h[Horn]|h|r", 134002 } },
}
wow.state.zone, wow.state.mapID = "Wald von Elwynn", 1429
wow.login({ level = 10 })
expect("Standard an", addon.db.questButtonsZoneOnly, true)

-- Elwynn: Westfall-Quest fällt heraus, Kategorie "Krieger" bleibt
expect("Elwynn-Quest hier", (QuestItem.ZoneOf(70)), true)
expect("Westfall-Quest woanders", (QuestItem.ZoneOf(72)), false)
expect("Kategorie unbekannt", (QuestItem.ZoneOf(74)), nil)
addon.Set("questItemButton", true)
expect("erste Quest der Zone", item:GetAttribute("item"), "item:5000")
wow.advance(5)
wow.fire("QUEST_ACCEPTED", 4, 72)
wow.update(1)
expect("zuletzt angenommen, aber woanders", item:GetAttribute("item"), "item:5000")

-- Zonenwechsel: sofort neu bestimmt
goTo("Westfall", 1436)
expect("Westfall: dortige Quest", item:GetAttribute("item"), "item:6000")

-- Höhle unter Elwynn: Kartenkette führt zur Zone
goTo("Jaspismine", 9001)
expect("Höhle zählt zu Elwynn", item:GetAttribute("item"), "item:5000")

-- Ohne Kategorie-Quest in einer fremden Zone: Knopf weg
wow.state.questLog[6].specialItem = nil
wow.fire("QUEST_LOG_UPDATE")
goTo("Dämmerwald", 1431)
expectTrue("fremde Zone: versteckt", not item:IsShown() and not LevelTimerQuestItemBar:IsShown())

-- Im Kampf wartet der Wechsel, danach nachgeholt
wow.state.combatLockdown = true
goTo("Wald von Elwynn", 1429)
expectTrue("Kampf: bleibt versteckt", not item:IsShown())
wow.state.combatLockdown = false
wow.fire("PLAYER_REGEN_ENABLED")
expectTrue("nach dem Kampf: Elwynn-Item", item:IsShown() and item:GetAttribute("item") == "item:5000")

-- Zielknopf: gelernte Namen nur für Quests der Zone, unbekannte bleiben
addon.QuestMobs.OpenMobNames = function() return { "Defias", "Kobold", "Murloc" } end
local learned = { Defias = { { questID = 72 } }, Kobold = { { questID = 70 } } }
addon.QuestMobs.ForMob = function(name) return learned[name] end
addon.Set("questLearning", true)
addon.Set("questTargetButton", true)
expect("Elwynn: ohne Westfall-Gegner", target:GetAttribute("macrotext"),
  "/cleartarget\n/targetexact Kobold\n/targetexact Murloc")

-- Einstellung aus: alle Quests wie bisher
goTo("Dämmerwald", 1431)
expect("Dämmerwald: nur der unbekannte Gegner", target:GetAttribute("macrotext"), "/cleartarget\n/targetexact Murloc")
addon.Set("questButtonsZoneOnly", false)
expectTrue("aus: Item wieder da", item:IsShown())
expect("aus: alle Gegner", target:GetAttribute("macrotext"),
  "/cleartarget\n/targetexact Defias\n/targetexact Kobold\n/targetexact Murloc")
expect("Fehler?", #wow.errors, 0)

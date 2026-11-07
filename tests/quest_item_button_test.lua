-- Quest-Item-Knopf: sicherer Knopf für das Item der nächsten Quest, Zielknopf für Questgegner, nur außerhalb des Kampfs
local L = addon.L
local QuestItem = addon.QuestItem
local item = LevelTimerQuestItemButton
local target = LevelTimerQuestTargetButton
local bar = LevelTimerQuestItemBar

wow.state.questLog = {
  { title = "Elwynn", isHeader = true },
  { title = "Feuer legen", questID = 70, specialItem = { "|cffffffff|Hitem:5000::::|h[Fackel]|h|r", 134000 } },
  { title = "Ohne Item", questID = 71 },
  { title = "Proben", questID = 72, specialItem = { "|cffffffff|Hitem:6000::::|h[Phiole]|h|r", 134001 } },
}
wow.state.itemCounts = { [5000] = 3 }

wow.login({ level = 10 })
expect("Typ Item", item:GetAttribute("type"), "item")
expect("Klick beim Loslassen", item:GetAttribute("useOnKeyDown"), false)
expect("Typ Makro", target:GetAttribute("type"), "macro")

-- Aus: nichts sichtbar
wow.update(1)
expectTrue("aus: versteckt", not bar:IsShown())

-- Kandidaten: nur Quests mit Item
local candidates = QuestItem.Candidates()
expect("zwei Quests mit Item", #candidates, 2)
expect("Item-ID aus dem Link", candidates[1].itemId, 5000)

addon.Set("questItemButton", true)
expectTrue("an: sichtbar", bar:IsShown() and item:IsShown())
expect("ohne Abstand und Annahme: erste Quest", item:GetAttribute("item"), "item:5000")
expect("Anzahl", item.count:GetText(), "3")

-- Zuletzt angenommene Quest gewinnt (Classic ohne Abstand)
wow.advance(5)
wow.fire("QUEST_ACCEPTED", 4, 72)
wow.update(1)
expect("zuletzt angenommen", item:GetAttribute("item"), "item:6000")

-- Retail/Forever: kleinster Abstand gewinnt
C_QuestLog.GetDistanceSqToQuest = function(questID) return questID == 70 and 100 or 900 end
wow.update(1)
expect("nächste Quest", item:GetAttribute("item"), "item:5000")
C_QuestLog.GetDistanceSqToQuest = nil

-- Im Kampf nichts ändern, danach nachholen
wow.state.combatLockdown = true
wow.state.questLog[2].specialItem = nil
wow.update(1)
expect("Kampf: Attribut bleibt", item:GetAttribute("item"), "item:5000")
wow.state.combatLockdown = false
wow.fire("PLAYER_REGEN_ENABLED")
expect("nach dem Kampf: anderes Item", item:GetAttribute("item"), "item:6000")

-- Kein Item mehr: Knopf weg
wow.state.questLog[4].specialItem = nil
wow.update(1)
expectTrue("kein Item: versteckt", not item:IsShown() and not bar:IsShown())

-- Zielknopf: Questgegner auf den Namensplaketten (nur wo UnitIsRelatedToActiveQuest existiert)
expectTrue("ohne Plaketten-API kein Zielknopf", not QuestItem.CanTarget())
C_NamePlate = { GetNamePlateForUnit = function() return nil end }
C_QuestLog.UnitIsRelatedToActiveQuest = function(unit) return wow.state.units[unit].quest == true end
wow.state.units.nameplate1 = { name = "Spieler", isPlayer = true, quest = true }
wow.state.units.nameplate2 = { name = "Toter Kobold", dead = true, quest = true }
wow.state.units.nameplate3 = { name = "Wolf", quest = false }
wow.state.units.nameplate4 = { name = "Kobold", quest = true }
for index = 1, 4 do wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate" .. index) end
addon.Set("questTargetButton", true)
expect("Makro", target:GetAttribute("macrotext"), "/cleartarget\n/targetexact Kobold")
expectTrue("Zielknopf sichtbar", target:IsShown() and bar:IsShown())
wow.state.units.nameplate4.name = wow.SECRET
wow.update(1)
expectTrue("geheimer Name: kein Ziel", not target:IsShown())

-- Gelernte Namen offener Ziele (Roadmap 342): vor den sichtbaren, die Vorrang haben; Marker optional
wow.state.units.nameplate4.name = "Kobold"
addon.QuestMobs.OpenMobNames = function() return { "Kobold", "Wolf" } end
addon.Set("questLearning", true)
expect("gelernt und sichtbar", target:GetAttribute("macrotext"), "/cleartarget\n/targetexact Wolf\n/targetexact Kobold")
addon.Set("questTargetMarker", true)
expect("mit Totenkopf", target:GetAttribute("macrotext"),
  "/cleartarget\n/targetexact Wolf\n/targetexact Kobold\n/tm [exists,nodead] !8")
local long = {}
for index = 1, 30 do long[index] = "Gegner Nummer " .. index end
local macro, count = QuestItem.TargetMacro(long, true)
expectTrue("höchstens 255 Zeichen", #macro <= 255)
expectTrue("letzte Namen bleiben", macro:find("Gegner Nummer 30", 1, true) ~= nil and count < 30)
expectTrue("Marker bleibt", macro:find("/tm", 1, true) ~= nil)
addon.Set("questTargetMarker", false)
addon.Set("questLearning", false)

-- Verschieben: Griff sichtbar, nicht im Kampf
addon.Set("questTargetButton", false)
QuestItem.SetMoving(true)
expectTrue("Verschieben: Halter sichtbar", QuestItem.IsMoving() and bar:IsShown())
expect("Griff beschriftet", bar.label:GetText(), L.QUEST_ITEM_MOVE_LABEL)
QuestItem.SetMoving(false)
wow.state.combatLockdown = true
QuestItem.SetMoving(true)
expectTrue("im Kampf kein Verschieben", not QuestItem.IsMoving())
wow.state.combatLockdown = false

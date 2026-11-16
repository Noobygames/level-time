-- Ziele von Dungeonquests an Namensplaketten (WoW Forever, DungeonDB): annehmbare Quest 959 (NPC 3655) = "take",
-- Quest eines Gruppenmitglieds 204 (Beute-NPCs 940-942) = "party", aktive Quest hat Vorrang; Einstellungen schalten ab.
local Targets = addon.QuestTargets
local plates = { nameplate1 = CreateFrame("Frame"), nameplate2 = CreateFrame("Frame"), nameplate3 = CreateFrame("Frame") }
C_NamePlate = { GetNamePlateForUnit = function(unit) return plates[unit] end }
C_QuestLog.UnitIsRelatedToActiveQuest = function(unit) return wow.state.units[unit].related == true end

local created = {}  -- Marken sind Kinder der Plakette
local realCreate = CreateFrame
CreateFrame = function(kind, name, parent)
  local frame = realCreate(kind, name, parent)
  for _, plate in pairs(plates) do if parent == plate then created[plate] = frame end end
  return frame
end

wow.login({ level = 1 })
addon.Set("questMarks", true)
addon.Set("partyQuestSync", true)
wow.state.inGroup = true
wow.state.party = { "Thrall" }
wow.fire("GROUP_ROSTER_UPDATE")
expect("Standard take", addon.db.questTargetsTake, true)
expect("Standard party", addon.db.questTargetsParty, true)

wow.state.units.nameplate1 = { name = "Takemob", guid = "Creature-0-1-0-0-3655-0001" }
wow.state.units.nameplate2 = { name = "Partymob", guid = "Creature-0-1-0-0-940-0001" }
wow.state.units.nameplate3 = { name = "Fremd", guid = "Creature-0-1-0-0-999999-0001" }
local function add()
  for _, unit in ipairs({ "nameplate1", "nameplate2", "nameplate3" }) do wow.fire("NAME_PLATE_UNIT_ADDED", unit) end
end
expectTrue("zu niedrig: keine take-Marke", Targets.KindOf("nameplate1") == nil)

wow.fire("CHAT_MSG_ADDON", addon.PartyQuestSync.PREFIX, "S:204:1=0/1", "PARTY", "Thrall-Realm")
wow.advance(3)  -- Gruppenkarte ist bis zu 2 s zwischengespeichert
expect("Gruppenquest", Targets.KindOf("nameplate2"), "party")
expectTrue("Fremder Gegner", Targets.KindOf("nameplate3") == nil)

wow.state.level = 14
wow.fire("QUEST_LOG_UPDATE")
expect("annehmbare Quest", Targets.KindOf("nameplate1"), "take")
add()
expectTrue("Plakette 1 markiert", created[plates.nameplate1] ~= nil and created[plates.nameplate1]:IsShown())
expectTrue("Plakette 2 markiert", created[plates.nameplate2] ~= nil and created[plates.nameplate2]:IsShown())
expectTrue("Plakette 3 ohne Marke", created[plates.nameplate3] == nil)

-- Einstellungen schalten die Arten einzeln ab; die aktive Quest markiert unabhängig davon
addon.Set("questTargetsTake", false)
expectTrue("take aus", Targets.KindOf("nameplate1") == nil)
addon.Set("questTargetsParty", false)
expectTrue("party aus", Targets.KindOf("nameplate2") == nil)
wow.state.units.nameplate1.related = true
add()
expectTrue("aktive Quest markiert", created[plates.nameplate1]:IsShown())

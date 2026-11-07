-- Sperrliste der Quest-Automatik: Stoff-Quartiermeister, gesperrte Quests, eigene Einträge, wiederholbare
-- Quests im Dialog (Retail/Forever) und Gesprächsoptionen mit Flags
local Blocklist = addon.QuestBlocklist
local gossip, greeting = wow.state.gossip, wow.state.greeting

local function lastAction()
  local action = wow.questActions[#wow.questActions]
  return action and table.concat(action, " ", 1, #action) or nil
end

local function reset() wow.questActions = {} end

wow.login()
addon.Set("autoAcceptQuests", true)
addon.Set("autoTurnIn", true)
addon.Set("skipGossip", true)

expect("NPC-ID aus GUID", Blocklist.NpcId("Creature-0-7095-0-9-14729-8935AB63FC"), 14729)
expect("Spieler hat keine NPC-ID", Blocklist.NpcId("Player-6937-00271B69"), nil)
expect("geheim", Blocklist.NpcId(wow.SECRET), nil)

-- Stoff-Quartiermeister: nichts automatisch
wow.state.units.npc = { name = "Ralston Farnsley", guid = "Creature-0-1-0-1-14729-0000000001" }
gossip.available = { { questID = 7818, title = "Spende von Wolle" } }
wow.fire("GOSSIP_SHOW")
expect("Quartiermeister: keine Quest geöffnet", lastAction(), nil)
wow.fire("QUEST_DETAIL")
expect("Quartiermeister: nicht angenommen", lastAction(), nil)
wow.state.questID = 7818
wow.fire("QUEST_PROGRESS")
expect("Quartiermeister: nicht abgegeben", lastAction(), nil)

-- Normaler NPC: gesperrte Quest-ID wird übersprungen, die nächste geöffnet
wow.state.units.npc = { name = "Questgeber", guid = "Creature-0-1-0-1-500-0000000002" }
gossip.available = { { questID = 7820, title = "Spendet Wolle" }, { questID = 900, title = "Wölfe jagen" } }
wow.fire("GOSSIP_SHOW")
expect("gesperrte Quest übersprungen", lastAction(), "selectAvailable 900")

-- Eigene Einträge: Titel und NPC-Name, Groß-/Kleinschreibung egal
reset()
addon.Set("questExclude", "wölfe JAGEN; 4242")
wow.fire("GOSSIP_SHOW")
expect("eigener Titel gesperrt", lastAction(), nil)
wow.state.questID = 4242
wow.fire("QUEST_COMPLETE")
expect("eigene ID: keine Belohnung", lastAction(), nil)
addon.Set("questExclude", "Questgeber")
gossip.available = { { questID = 901, title = "Andere Quest" } }
wow.fire("GOSSIP_SHOW")
expect("eigener NPC gesperrt", lastAction(), nil)
greeting.available = { { title = "Alte Quest", isTrivial = false } }
wow.fire("QUEST_GREETING")
expect("auch in der alten Quest-Liste", lastAction(), nil)
addon.Set("questExclude", "Alte Quest")
wow.fire("QUEST_GREETING")
expect("Titel in der alten Quest-Liste", lastAction(), nil)
addon.Set("questExclude", "")
wow.fire("QUEST_GREETING")
expect("ohne Eintrag geöffnet", lastAction(), "greetingAvailable 1")
greeting.available = {}

-- Wiederholbare Quest im Dialog (Retail/Forever): von Hand geöffnet, bleibt die Abgabe manuell
reset()
wow.state.questID = 555
wow.state.repeatableQuests = { [555] = true }
wow.fire("QUEST_PROGRESS")
wow.fire("QUEST_COMPLETE")
expect("wiederholbar: manuell", lastAction(), nil)
wow.state.repeatableQuests = {}
wow.fire("QUEST_PROGRESS")
expect("normale Quest abgegeben", lastAction(), "complete")

-- Gesprächsoption mit Flags oder Belohnungen: nicht überspringen
reset()
gossip.available = {}
gossip.options = { { orderIndex = 0, status = 0, flags = 1, rewards = {}, gossipOptionID = 1 } }
wow.fire("GOSSIP_SHOW")
expect("Option mit Flags manuell", lastAction(), nil)
gossip.options = { { orderIndex = 0, status = 0, flags = 0, rewards = { { id = 1 } }, gossipOptionID = 2 } }
wow.fire("GOSSIP_SHOW")
expect("Option mit Belohnung manuell", lastAction(), nil)
gossip.options = { { orderIndex = 0, status = 0, flags = 0, rewards = {}, gossipOptionID = 3 } }
wow.fire("GOSSIP_SHOW")
expect("normale Option übersprungen", lastAction(), "selectOption 0")
gossip.options = {}
wow.state.units.npc = nil

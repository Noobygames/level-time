-- Level Time Goals, Roadmap 302: Bosse besiegen (ENCOUNTER_END mit Erfolg), optional bestimmter Boss und Instanz;
-- Dungeons abschließen (mindestens ein Boss besiegt je Instanzlauf) und Dungeon-Tour (verschiedene Dungeons).
local Goals = streamGoal.Goals
local L = streamGoal.L

wow.login({ level = 20 })

SlashCmdList.STREAMGOAL("add boss 2")
local any = Goals.Active()[1]
expect("Boss-Art", any.kind, "dungeon")
expect("Titel", Goals.Title(any), string.format(L.SG_GOAL_BOSS_ANY, 2))
SlashCmdList.STREAMGOAL("add boss 1 Bazzalan")
local named = Goals.Active()[2]
expect("bestimmter Boss", named.params.boss, "Bazzalan")

SlashCmdList.STREAMGOAL("")
local Manager = streamGoal.Manager
Manager.SelectKind("dungeon")
Manager.FormWidget("amount"):SetText("1")
Manager.FormWidget("instance"):SetText("Todesmine")
local inMine = Manager.AddFromForm()
StreamGoalWindow:Hide()
expect("Instanz", inMine.params.instance, "Todesmine")
expect("Zeile Instanz", Goals.Body(inMine), string.format(L.SG_DUNGEON_IN, "Todesmine"))

wow.state.instance = { name = "Ragefireabgrund", type = "party" }
wow.fire("ENCOUNTER_END", 2001, "Oggleflint", 1, 5, 0)
expect("Wipe zählt nicht", any.progress, 0)
wow.fire("ENCOUNTER_END", 2001, "Oggleflint", 1, 5, 1)
expect("Sieg zählt", any.progress, 1)
expect("anderer Boss zählt nicht für Bazzalan", named.progress, 0)
expect("andere Instanz zählt nicht", inMine.progress, 0)
wow.fire("ENCOUNTER_END", 2002, "Bazzalan", 1, 5, 1)
expect("alle Bosse erreicht", any.status, Goals.DONE)
expect("Bazzalan erreicht", named.status, Goals.DONE)

wow.state.instance = { name = "Die Todesminen", type = "party" }
wow.fire("ENCOUNTER_END", 2003, "Rhahk'Zor", 1, 5, 1)
expect("Todesmine erreicht", inMine.status, Goals.DONE)

-- Dungeons abschließen und Dungeon-Tour per Befehl
SlashCmdList.STREAMGOAL("add dungeon complete 3 Die Todesminen")
local compGoal = Goals.Active()[#Goals.Active()]
expect("Modus complete", compGoal.params.mode, "complete")
expect("Instanzfilter", compGoal.params.instance, "Die Todesminen")
expect("Titel complete", Goals.Title(compGoal), string.format(L.SG_GOAL_DUNGEON_COMPLETE_NAMED, "Die Todesminen", 3))

SlashCmdList.STREAMGOAL("add dungeon tour 2")
local tourGoal = Goals.Active()[#Goals.Active()]
expect("Modus tour", tourGoal.params.mode, "tour")
expect("Titel tour", Goals.Title(tourGoal), string.format(L.SG_GOAL_DUNGEON_TOUR, 2))

-- Erfassung: erster Boss im Lauf zählt
wow.state.instance = { name = "Die Todesminen", type = "party" }
wow.fire("ENCOUNTER_END", 2004, "Rhahk'Zor", 1, 5, 1)
expect("Complete zählt 1", compGoal.progress, 1)
expect("Tour zählt 1", tourGoal.progress, 1)

-- Zweiter Boss im selben Lauf zählt nicht noch einmal
wow.fire("ENCOUNTER_END", 2005, "Sneed", 1, 5, 1)
expect("Complete zählt nicht doppelt im selben Lauf", compGoal.progress, 1)
expect("Tour zählt nicht doppelt für dieselbe Instanz", tourGoal.progress, 1)

-- Andere Instanz: Tour zählt weiter, Complete für Todesminen nicht
wow.state.instance = { name = "Ragefireabgrund", type = "party" }
wow.fire("ENCOUNTER_END", 2006, "Taragaman", 1, 5, 1)
expect("Complete bleibt 1 bei anderer Instanz", compGoal.progress, 1)
expect("Tour erreicht mit 2 verschiedenen Dungeons", tourGoal.status, Goals.DONE)

-- Neuer Lauf der Todesminen: Complete zählt 2
streamGoal.DungeonGoals.NewRun()
wow.state.instance = { name = "Die Todesminen", type = "party" }
wow.fire("ENCOUNTER_END", 2007, "Rhahk'Zor", 1, 5, 1)
expect("Complete zählt 2 im neuen Lauf", compGoal.progress, 2)

-- Formular-Felder für complete und tour
Manager.SelectKind("dungeon")
local function widget(p) return Manager.FormWidget(p) end
local function nextChoice(p)
  local b = widget(p)
  b._scripts.OnClick(b, "LeftButton")
end

-- Anfangs mode = "boss"
expect("Boss-Feld da bei boss", widget("boss"):IsShown(), true)
expect("Instanz-Feld da bei boss", widget("instance"):IsShown(), true)

nextChoice("mode") -- complete
expect("Boss-Feld versteckt bei complete", widget("boss"):IsShown(), false)
expect("Instanz-Feld da bei complete", widget("instance"):IsShown(), true)

nextChoice("mode") -- tour
expect("Boss-Feld versteckt bei tour", widget("boss"):IsShown(), false)
expect("Instanz-Feld versteckt bei tour", widget("instance"):IsShown(), false)

-- Fertiges Paket Dungeon-Tour
SlashCmdList.STREAMGOAL("pack dungeons")
expect("Paket mit Boss-Ziel", Goals.Active()[1].kind, "dungeon")

-- Reload im selben Lauf: Kennung = Startzeit des Laufs, zählt nicht doppelt; Level-Time-Daten bleiben unberührt
local function enter(name)
  wow.state.instance = name and { name = name, type = "party" } or nil
  wow.fire("PLAYER_ENTERING_WORLD", false, name ~= nil)
end
SlashCmdList.STREAMGOAL("add dungeon complete 5 Burg Schattenfang")
local reloadGoal = Goals.Active()[#Goals.Active()]
enter(nil)
enter("Burg Schattenfang")
wow.advance(60)
wow.fire("ENCOUNTER_END", 3001, "Rethilgore", 1, 5, 1)
expect("erster Boss im Lauf", reloadGoal.progress, 1)
expectTrue("Lauf offen", addon.character.currentRun ~= nil)
expect("kein Feld in Level Times Lauf", addon.character.currentRun._sgToken, nil)
wow.logout()
wow.advance(5)
wow.login()
enter("Burg Schattenfang")
wow.runTimers()
wow.fire("ENCOUNTER_END", 3002, "Razorclaw", 1, 5, 1)
expect("nach Reload derselbe Lauf", reloadGoal.progress, 1)

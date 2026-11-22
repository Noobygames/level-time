-- LT-405 (WoW Forever): Dungeon-Recap schon während des Laufs mit dem Zwischenstand: /lt recap run und Linksklick auf
-- den Live-Tracker nehmen den offenen Lauf, sonst den jüngsten abgeschlossenen; Ziehen ist kein Klick.
local Bosses = addon.InstanceBosses
local Window = addon.DungeonRecapWindow
local Tracker = addon.InstanceRunTracker
local L = addon.L

local DEADMINES = { name = "Die Todesminen", type = "party", difficulty = 1, mapID = 36, maxPlayers = 5 }

local function enter(instance)
  wow.state.instance = nil
  wow.fire("PLAYER_ENTERING_WORLD")
  wow.state.instance = instance
  wow.fire("PLAYER_ENTERING_WORLD")
end
local function panel() return _G[addon.GlobalName("DungeonRecap")] end

wow.login({ level = 21, xp = 0, xpMax = 100000 })
local list = Bosses.List(36, 1)
enter(DEADMINES)
wow.advance(10)
wow.fire("PLAYER_STARTED_MOVING")
wow.advance(60)

-- Ohne Boss: Recap des laufenden Laufs, Status "läuft"
SlashCmdList.LEVELTIMER("recap run")
expectTrue("/lt recap run im Lauf öffnet", Window.IsShown())
local parts = Window.Parts()
local records = addon.History.GetInstanceLog(addon.characterKey)
expect("offener Lauf gewählt", parts.state.time, records[1].time)
expectTrue("Lauf ist offen", records[1].isCurrent)
for _, tab in ipairs({ "loot", "group", "enemies", "overview" }) do Window.SetTab(tab) end

-- Nach dem ersten Boss: neu öffnen zeigt den Fortschritt
panel():Hide()
wow.fire("ENCOUNTER_END", list[1], "Boss", 1, 5, 1)
wow.advance(5)
local card = Tracker.Card()
card.frame._scripts.OnMouseUp(card.frame, "LeftButton")
expectTrue("Linksklick auf den Tracker öffnet", Window.IsShown())
local current = addon.History.GetInstanceLog(addon.characterKey)[1]
expectTrue("erster Boss im offenen Lauf", (current.bosses or ""):find(tostring(list[1]), 1, true) ~= nil)
expect("Kachel Bosse mit Fortschritt", parts.tiles[1].value:GetText(), Bosses.ProgressText(current))

-- Ziehen ist kein Klick, Rechtsklick bleibt den Einstellungen
panel():Hide()
card.frame._scripts.OnDragStart(card.frame)
card.frame._scripts.OnMouseUp(card.frame, "LeftButton")
expect("nach dem Ziehen bleibt es zu", Window.IsShown(), false)
card.frame._scripts.OnMouseUp(card.frame, "LeftButton")
expectTrue("danach wieder per Klick", Window.IsShown())
panel():Hide()

-- Run-Fenster: Recap-Knopf auch für den laufenden Lauf
addon.InstanceRunWindow.Show(addon.characterKey, current.time)
expectTrue("Recap-Knopf im Run-Fenster", wow.click(L.DUNGEON_RECAP_BUTTON))
expectTrue("öffnet den offenen Lauf", Window.IsShown() and parts.state.time == current.time)
panel():Hide()
expectTrue("Tooltip nennt den Klick", L.DUNGEON_RUN_TRACKER_CLICK_TIP ~= "DUNGEON_RUN_TRACKER_CLICK_TIP")
expect("keine Fehler", #wow.errors, 0)

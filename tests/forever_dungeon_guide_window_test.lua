-- Dungeon Guide: öffnet beim Betreten einer neuen Kopie mit Trash- und Bossseiten; "Nicht mehr anzeigen" und /lt guide
local Guide, Window = addon.DungeonGuide, addon.DungeonGuideWindow
local DEADMINES = { name = "Die Todesminen", type = "party", difficulty = 1, mapID = 36, maxPlayers = 5 }
local STOCKADE = { name = "Das Verlies", type = "party", difficulty = 1, mapID = 34, maxPlayers = 5 }

local NAMES = { [36] = "Die Todesminen", [34] = "Das Verlies" }
function GetRealZoneText(mapID) return NAMES[mapID] or ("Instanz " .. tostring(mapID)) end

local function enter(instance)
  wow.state.instance = nil
  wow.fire("PLAYER_ENTERING_WORLD")
  wow.state.instance = instance
  wow.fire("PLAYER_ENTERING_WORLD")
end

wow.login({ level = 20, xp = 0, xpMax = 10000 })
expect("verfügbar in Forever", Guide.IsAvailable(), true)
enter(DEADMINES)
expectTrue("öffnet beim Betreten", Window.IsShown())
local escape = false
for _, name in ipairs(UISpecialFrames) do escape = escape or name == "LevelTimerDungeonGuide" end
expectTrue("mit ESC schließbar", escape)
local index, pages, name = Window.Current()
expect("Instanzname", name, "Die Todesminen")
expect("erste Seite Trash", pages[1].trash, true)
expectTrue("Trash mit Mechaniken", #pages[1].units > 0 and pages[1].units[1].mechanics ~= nil)
expect("je Boss eine Seite", #pages, 1 + #addon.InstanceBosses.List(36, 1))
local vanCleef, sneed
for _, page in ipairs(pages) do
  if page.units[1].npcID == 639 then vanCleef = page end
  if page.units[#page.units].npcID == 643 then sneed = page end
end
expectTrue("VanCleef mit Porträt-NPC und Tipps", vanCleef and vanCleef.units[1].mechanics ~= nil)
expect("Schredder (ohne Encounter) vor Sneed auf seiner Seite", sneed and sneed.units[1].npcID, 642)
expect("Start auf der ersten Seite mit Infos", index, 1)
Window.ShowPage(99)
expect("Blättern bleibt in den Grenzen", (Window.Current()), #pages)

-- Nicht mehr anzeigen: nächste Kopie öffnet nichts, /lt guide trotzdem
Window.Hide()
addon.Set("dungeonGuideAuto", false)
enter(STOCKADE)
expect("aus: öffnet nicht", Window.IsShown(), false)
SlashCmdList.LEVELTIMER("guide")
expectTrue("/lt guide öffnet", Window.IsShown())
expect("Verlies", select(3, Window.Current()), "Das Verlies")
SlashCmdList.LEVELTIMER("guide")
expect("/lt guide schließt wieder", Window.IsShown(), false)

-- Draußen: Vorauswahl nach Level (Level 20: Die Todesminen 15-25 mit dem höchsten Mindestlevel der passenden)
wow.state.instance = nil
wow.fire("PLAYER_ENTERING_WORLD")
Window.Hide()
expectTrue("draußen öffnet die Vorauswahl", Guide.Show(true) == false and (SlashCmdList.LEVELTIMER("guide") or true))
expectTrue("Fenster offen", Window.IsShown())
local list = Guide.Dungeons()
for i = 2, #list do expectTrue("nach Level sortiert", list[i - 1].minLevel <= list[i].minLevel) end
local fitting
for _, d in ipairs(list) do if d.minLevel <= 20 and 20 <= d.maxLevel then fitting = d.mapID end end
expect("Vorauswahl passend", select(4, Window.Current()), fitting)
expect("Vorauswahl = SuggestedMapID", Guide.SuggestedMapID(), fitting)

-- Anderen Dungeon per Auswahlliste und per Name
Guide.ShowMap(36)
expect("Dungeon gewechselt", select(4, Window.Current()), 36)
SlashCmdList.LEVELTIMER("guide Verlies")
expect("/lt guide Name", select(3, Window.Current()), "Das Verlies")
addon.Dropdown.Close()

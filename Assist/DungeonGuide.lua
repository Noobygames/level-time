-- Dungeon Guide: beim Betreten einer neuen Instanzkopie (InstanceCopy.OnEnter mit isNew) ein Fenster mit einer Seite
-- für den Trash und je einer Seite pro Boss (UI/DungeonGuideWindow.lua). Einstellung dungeonGuideAuto (Standard an,
-- "Nicht mehr anzeigen" im Fenster schaltet sie aus); von Hand jederzeit über /lt guide [Name], Strg+Linksklick auf den
-- Minimap-Knopf, den Knopf im Laufübersicht-Fenster und im Reiter Komfort > Dungeons; im Fenster wählt eine Auswahlliste
-- jeden Dungeon (nach Level sortiert). Nur mit Mechanik-Daten (ns.Mechanics, Classic Era und Forever).
-- Seiten aus den Guide-Daten (Assist/InstanceData/mechanics.lua):
--   Trash: Gegner aus ns.MechanicGuide[Karten-ID].trash (auch Rare) mit Mechaniken, Reihenfolge der Recherche.
--   Bosse: Bossliste des Laufs (InstanceBosses.RunList: mit bekanntem Flügel nur dessen Bosse, übersetzte Namen, Level,
--   besiegt), Mechaniken über die NPC-ID (InstanceBosses.NpcID); danach Bosse der Recherche ohne Encounter der Karte
--   (englischer Name). Bosse ohne Mechaniken bekommen trotzdem eine Seite ("keine Infos").
-- shortcut: Trash-Seite zeigt bei Karten mit Flügeln den Trash aller Flügel; bei Bedarf je Flügel in den Daten trennen.
local _, ns = ...
local L = ns.L

ns.RegisterDefaults({
  settings = {
    dungeonGuideAuto = true,
  },
})

local DungeonGuide = {}
ns.DungeonGuide = DungeonGuide

local NPC_ID, NAME = 1, 2

function DungeonGuide.IsAvailable()
  return ns.Mechanics ~= nil
end

-- Lauf der aktuellen Instanz (offener Lauf, sonst Karte und Schwierigkeit aus GetInstanceInfo); nil draußen
local function currentRecord()
  local inInstance = IsInInstance()
  if ns.IsSecret(inInstance) or not inInstance then return nil end
  local run = ns.Instances.IsRunning() and ns.Instances.GetCurrentRun()
  if run and run.mapID then return run end
  local name, _, difficultyID, _, _, _, _, mapID = GetInstanceInfo()
  if ns.IsSecret(mapID) or not mapID then return nil end
  return { name = not ns.IsSecret(name) and name or nil, mapID = mapID,
    difficultyID = not ns.IsSecret(difficultyID) and difficultyID or nil }
end

local function trashPage(guide)
  local units = {}
  for _, unit in ipairs(guide and guide.trash or {}) do
    local mechanics = ns.Mechanics[unit[NPC_ID]]
    if mechanics then units[#units + 1] = { npcID = unit[NPC_ID], name = unit[NAME], mechanics = mechanics } end
  end
  return { trash = true, title = L.DUNGEON_GUIDE_TRASH, units = units }
end

local function bossPage(name, npcID, level, killed)
  return { title = name, units = { { npcID = npcID, name = name, level = level, killed = killed,
    mechanics = npcID and ns.Mechanics[npcID] or nil } } }
end

-- Seiten einer Instanz (record = Lauf oder { mapID, difficultyID }); nil, wenn es weder Bosse noch Mechaniken gibt
function DungeonGuide.Pages(record)
  if not (DungeonGuide.IsAvailable() and record and record.mapID) then return nil end
  local guide = ns.MechanicGuide and ns.MechanicGuide[record.mapID]
  local pages = { trashPage(guide) }
  local killed = ns.InstanceBosses.Killed(record) or {}
  local mapNpcs = {}
  for _, encounterID in ipairs(ns.InstanceBosses.List(record.mapID, record.difficultyID) or {}) do
    mapNpcs[ns.InstanceBosses.NpcID(encounterID) or 0] = true
  end
  for _, encounterID in ipairs(ns.InstanceBosses.RunList(record) or {}) do
    local npcID = ns.InstanceBosses.NpcID(encounterID)
    pages[#pages + 1] = bossPage(ns.InstanceBosses.Name(encounterID) or tostring(encounterID), npcID,
      ns.InstanceBosses.Level(encounterID), killed[encounterID] == true)
  end
  -- Bosse der Recherche ohne eigenen Encounter (z.B. Sneeds Schredder) kommen auf die Seite des nächsten Encounter-Bosses
  -- der Recherche (ist der in einem anderen Flügel, fallen sie weg); übrig gebliebene am Ende bekommen eigene Seiten
  local pageOf, pending = {}, {}
  for _, page in ipairs(pages) do
    local first = page.units[1]  -- Trash-Seite ohne Daten hat keine Einheit
    if first and first.npcID then pageOf[first.npcID] = page end
  end
  for _, unit in ipairs(guide and guide.bosses or {}) do
    local npcID = unit[NPC_ID]
    if mapNpcs[npcID] then
      for offset, extra in ipairs(pending) do table.insert(pageOf[npcID] and pageOf[npcID].units or {}, offset, extra) end
      pending = {}
    elseif ns.Mechanics[npcID] then
      pending[#pending + 1] = { npcID = npcID, name = unit[NAME], mechanics = ns.Mechanics[npcID] }
    end
  end
  for _, extra in ipairs(pending) do pages[#pages + 1] = { title = extra.name, units = { extra } } end
  local hasInfo = false
  for _, page in ipairs(pages) do
    for _, unit in ipairs(page.units) do hasInfo = hasInfo or unit.mechanics ~= nil end
  end
  if not hasInfo then return nil end
  return pages
end

-- Alle Dungeons mit Guide, nach Levelbereich sortiert: { { mapID, name, minLevel, maxLevel }, ... }; Karten mit Flügeln
-- (Stratholme, Düsterbruch, Kloster, Schwarzfelsspitze) sind ein Eintrag. Dungeons ohne bekannten Bereich stehen am Ende.
function DungeonGuide.Dungeons()
  local list = {}
  for mapID in pairs(ns.MechanicGuide or {}) do
    local info = ns.InstanceInfo.Get(mapID)
    list[#list + 1] = { mapID = mapID, name = ns.InstanceInfo.MapName(mapID),
      minLevel = info and info.minLevel or math.huge, maxLevel = info and info.maxLevel or math.huge }
  end
  table.sort(list, function(a, b)
    if a.minLevel ~= b.minLevel then return a.minLevel < b.minLevel end
    if a.maxLevel ~= b.maxLevel then return a.maxLevel < b.maxLevel end
    return a.name < b.name
  end)
  return list
end

-- Vorauswahl ohne Instanz: der passende Dungeon mit dem höchsten Mindestlevel, sonst der nächste höhere, sonst der letzte
function DungeonGuide.SuggestedMapID()
  local list = DungeonGuide.Dungeons()
  local level, fitting, nextHigher = UnitLevel("player"), nil, nil
  for _, dungeon in ipairs(list) do
    if dungeon.minLevel <= level and level <= dungeon.maxLevel then fitting = dungeon.mapID end
    nextHigher = nextHigher or (dungeon.minLevel > level and dungeon.mapID or nil)
  end
  return fitting or nextHigher or (list[#list] and list[#list].mapID)
end

-- Guide eines Dungeons öffnen (ohne Instanz, Bosse alle ohne "besiegt"); false ohne Seiten
function DungeonGuide.ShowMap(mapID)
  local pages = DungeonGuide.Pages({ mapID = mapID, difficultyID = 1 })
  if not pages then return false end
  ns.DungeonGuideWindow.Show(ns.InstanceInfo.MapName(mapID), pages, mapID)
  return true
end

-- Guide der aktuellen Instanz öffnen; false (mit Chatmeldung, wenn manual), wenn es dort keinen gibt
function DungeonGuide.Show(manual)
  local record = currentRecord()
  local pages = DungeonGuide.Pages(record)
  ns.Debug("instances", "dungeon guide %s: %s pages", record and record.mapID, pages and #pages or 0)
  if not pages then
    if manual then ns.Print(L.DUNGEON_GUIDE_NONE) end
    return false
  end
  ns.DungeonGuideWindow.Show(record.name or "", pages, record.mapID)
  return true
end

-- Von Hand öffnen (/lt guide [Name], Knöpfe): mit Namensteil dieser Dungeon, sonst die aktuelle Instanz, draußen die
-- Vorauswahl nach Level; ohne Name schließt es ein offenes Fenster
function DungeonGuide.Open(name)
  name = name and strtrim(name):lower() or ""
  if name == "" then
    if ns.DungeonGuideWindow.IsShown() then return ns.DungeonGuideWindow.Hide() end
    if DungeonGuide.Show(false) then return end
    return DungeonGuide.ShowMap(DungeonGuide.SuggestedMapID())
  end
  for _, dungeon in ipairs(DungeonGuide.Dungeons()) do
    if dungeon.name:lower():find(name, 1, true) and DungeonGuide.ShowMap(dungeon.mapID) then return end
  end
  ns.Print(L.DUNGEON_GUIDE_NONE)
end

ns.InstanceCopy.OnEnter(function(_, _, isNew)
  if isNew and ns.db.dungeonGuideAuto then DungeonGuide.Show(false) end
end)

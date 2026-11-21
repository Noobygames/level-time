-- Debug-Prüfungen für offene Spielprüfungen im Board (Instanzen, Läufe, Speedrun, Historie und Live-Statistik): Datenteil der Vikunja-Tasks
-- „Prüfen: …“, damit im
-- Spiel nur noch das Sichtbare bleibt. Namen "LT<Index>.<Bereich>.<Was>" (Index = Task im Board). Lesen nur öffentliche
-- Funktionen der Module, ändern nichts, rufen keine geschützten Funktionen.
local _, X = ...
local ns = X.LT
if not ns then return end
local DebugLog = X.DebugLog
local Probe, H = DebugLog.Probe, DebugLog.Helpers
local call, safe, api = Probe.call, Probe.safe, Probe.api
local write = DebugLog.Write
local check = DebugLog.AddCheck
local plain, chunked, method, frameState, recentEntries = H.plain, H.chunked, H.method, H.frameState, H.recentEntries
local readable = H.readable

local MAX_SAMPLE = 8                -- Beispiele je Liste
local RECENT_LEVELS = 5             -- letzte Level für die Prognose (LT76)
local FOREVER_ITEM_MIN_ID = 250000  -- Forever-eigene Items (Classic Era kennt sie nicht)
-- GetInstanceInfo im pcall-Paket { ok, Name, Typ, Schwierigkeit, ..., Instanz-ID }
local INSTANCE_TYPE_INDEX, DIFFICULTY_INDEX, INSTANCE_ID_INDEX = 3, 4, 9
local QUEST_CHECK_DELAY = 2         -- Sekunden nach dem Betreten, bis der Lauf steht

---------------------------------------------------------------------------
-- Helfer
---------------------------------------------------------------------------
local function first(list, count)
  local result = {}
  for index = 1, math.min(#list, count or MAX_SAMPLE) do result[index] = list[index] end
  return result
end

-- Instanz-Karten-ID und Schwierigkeit: offener Lauf, sonst GetInstanceInfo (nil außerhalb von Instanzen)
local function currentInstance()
  local run = ns.Instances.GetCurrentRun()
  if run and run.mapID then return run.mapID, run.difficultyID, run end
  local info = { pcall(GetInstanceInfo) }
  local mapID = readable(info[INSTANCE_ID_INDEX])
  if info[INSTANCE_TYPE_INDEX] == "none" or type(mapID) ~= "number" then return nil end
  return mapID, readable(info[DIFFICULTY_INDEX])
end

-- NPC-ID des Ziels (nil ohne Ziel oder bei geheimer GUID)
local function targetNpc()
  return safe(ns.MechanicTips.NpcOf, "target")
end

-- Item-Mixin-Objekt des Clients (nil ohne Mixin)
local function itemMixin(itemID)
  return Item and Item.CreateFromItemID and Item:CreateFromItemID(itemID) or nil
end

-- Ein Drop { itemID, Qualität, Chance, unbestätigt } mit dem, was der Client dazu weiß
local function dropInfo(drop)
  local itemID, item = drop[1], itemMixin(drop[1])
  local known
  if item and type(item.IsItemEmpty) == "function" then known = not item:IsItemEmpty() end
  return { id = itemID, db = drop[2], client = ns.Items.GetQuality(itemID), name = ns.Items.GetName(itemID),
    chance = drop[3], unverified = drop[4] ~= nil, known = known }
end

local function dropList(drops, count)
  local list = {}
  for index = 1, math.min(#drops, count or MAX_SAMPLE) do list[index] = dropInfo(drops[index]) end
  return list
end

-- Zusammenfassung einer Dropliste: Tooltipzeilen (höchstens MAX_LINES + "weitere"), unbestätigte, Forever-Items,
-- dem Client unbekannte Items
local function lootSummary(drops)
  local unverified, forever, unknown = 0, 0, 0
  for _, drop in ipairs(drops) do
    if drop[4] ~= nil then unverified = unverified + 1 end
    if drop[1] >= FOREVER_ITEM_MIN_ID then forever = forever + 1 end
    local item = itemMixin(drop[1])
    if item and type(item.IsItemEmpty) == "function" and item:IsItemEmpty() then unknown = unknown + 1 end
  end
  return { count = #drops, lines = math.min(#drops, ns.BossLoot.MAX_LINES),
    more = math.max(0, #drops - ns.BossLoot.MAX_LINES), unverified = unverified, foreverItems = forever,
    unknownToClient = unknown }
end

-- Textfelder einer Karte (Lib/Card.lua: frame.title/.body/.time)
local function cardText(frame)
  if type(frame) ~= "table" then return nil end
  return { shown = method(frame, "IsShown"), title = method(frame.title, "GetText"), body = method(frame.body, "GetText"),
    time = method(frame.time, "GetText") }
end

---------------------------------------------------------------------------
-- Läufe, Speedrun, Prognose
---------------------------------------------------------------------------
-- LT-73: importierte Läufe (Namen ohne Farbcode?), FindByName; die Aufrufe von Runs.Import schreibt die Probe unten
check("LT73.runs.imported", function()
  local imported = {}
  for _, run in ipairs(ns.Runs.GetAll()) do
    if run.imported then
      imported[#imported + 1] = { id = run.id, name = run.name, short = run.shortName,
        colorCode = type(run.name) == "string" and run.name:find("|c", 1, true) ~= nil }
    end
  end
  local found = ns.Runs.FindByName("cffff0000Testr")
  return { count = #imported, imported = first(imported), testRun = found and { id = found.id, name = found.name } or false }
end)

-- LT-76: Prognose bis Max-Level mit den letzten Level-Zeiten (Gefühl gegen Zahl); beim Levelstart schreibt die Probe
-- unten dieselben Werte, damit sie mit den späteren Level-Zeiten verglichen werden können
local function forecastState()
  local levels = {}
  for _, record in ipairs(ns.History.GetLevelRecords(ns.characterKey)) do
    if not record.isCurrent and #levels < RECENT_LEVELS then levels[#levels + 1] = { record.level, record.seconds } end
  end
  return { level = UnitLevel("player"), max = GetMaxPlayerLevel and GetMaxPlayerLevel() or nil,
    secondsToMax = ns.Forecast.SecondsToMaxLevel(), xpRate = ns.Forecast.AverageLevelXpRate(), recentLevels = levels }
end

-- LT-145: LiveSplit-Datei: Länge, Segmentzahl, ausgewogene Tags, letzte Zeit gegen die Level-Zeiten des Charakters
local function balancedTags(text)
  local stack = {}
  for kind, name, attributes in text:gmatch("<([/?]?)([%w]+)([^>]*)>") do
    if kind == "/" then
      if table.remove(stack) ~= name then return false end
    elseif kind == "" and attributes:sub(-1) ~= "/" then
      stack[#stack + 1] = name
    end
  end
  return #stack == 0
end

local function segmentOf(body)
  return { name = body:match("<Name>(.-)</Name>"), split = body:match("<SplitTime[^>]*>%s*<RealTime>(.-)</RealTime>"),
    best = body:match("<BestSegmentTime>%s*<RealTime>(.-)</RealTime>") }
end

check("LT145.lss.export", function()
  local text = ns.LiveSplitExport.Build(ns.characterKey)
  if not text then return { text = false } end
  local segments = {}
  for body in text:gmatch("<Segment>(.-)</Segment>") do segments[#segments + 1] = segmentOf(body) end
  local times, lowest = ns.Runs.LevelTimes(ns.characterKey), nil
  for level in pairs(times) do lowest = math.min(lowest or level, level) end
  local total, level = 0, lowest
  while level and times[level] do
    total = total + times[level]
    level = level + 1
  end
  local expected, last = ns.LiveSplitExport.TimeSpan(total), segments[#segments]
  return { length = #text, segments = #segments, balanced = balancedTags(text), first = segments[1], last = last,
    expectedLastSplit = expected, lastMatches = last ~= nil and last.split == expected }
end)

---------------------------------------------------------------------------
-- Hauptfenster, Historie
---------------------------------------------------------------------------
-- LT-172: Bereichs-Beschriftung (Tab-Texte, Layout-Einstellungen) und Titel der Split-Liste im aktuellen Vergleich
check("LT172.window.labels", function()
  local model = ns.WindowModel.New()
  model:Build(ns.db, ns.WindowModel.CHOSEN)
  local tabs = {}
  for index, tab in ipairs(model.tabs) do tabs[index] = { tab.text, tab.active } end
  local settings = {}
  for key, value in pairs(ns.db) do
    local name = tostring(key):lower()
    if name:find("layout", 1, true) or name:find("label", 1, true) or name:find("scope", 1, true) then
      settings[tostring(key)] = plain(value)
    end
  end
  return { scopeText = model.scopeText, tabs = tabs, settings = settings, comparison = ns.db.splitComparison,
    splitTitle = ns.SplitList.TitleText(), short = ns.Splits.ComparisonShortName(),
    frame = frameState(_G[ns.GlobalName("Frame")]), splits = frameState(_G[ns.GlobalName("Splits")]) }
end)

-- Reiter der Historie: Titel, Breite, Zeile (y), Tooltip, Unterreiter mit Tooltip und Hinweiszeilen
local function historyEntries()
  local HistoryWindow, entries = ns.HistoryWindow, {}
  for _, entry in ipairs(HistoryWindow.Entries()) do
    local views = {}
    for index, view in ipairs(entry.members) do
      views[index] = { tab = view.tab, text = ns.L[view.tab], tip = safe(HistoryWindow.ViewTip, view) or false,
        allCharacters = view.allCharacters == true, hints = method(view.frame, "HintLines") }
    end
    local point = H.pointOf(entry.tabButton)
    entries[#entries + 1] = { tab = entry.tab, text = ns.L[entry.tab], width = method(entry.tabButton, "GetWidth"),
      y = type(point) == "table" and point[5] or nil, tip = safe(HistoryWindow.EntryTip, entry) or false, views = views }
  end
  return entries
end

-- LT-161: Tooltips der Historie: Spaltenköpfe (Stichprobe der Schlüssel aus den Tabellen; die Spaltenlisten selbst sind
-- nicht öffentlich), Reiter und Unterreiter
local HEADER_SAMPLE = { "HISTORY_TIME", "HISTORY_XP_RATE", "HISTORY_ITEMS_LOOTED", "HISTORY_ITEM_RATE",
  "HISTORY_LOOT_VALUE", "HISTORY_SELL_VALUE", "HISTORY_BOSSES", "HISTORY_QUANTITY" }
check("LT161.history.tooltips", function()
  local headers = {}
  for index, key in ipairs(HEADER_SAMPLE) do
    local text = ns.TableView.HeaderTip({ header = key })
    headers[index] = { key, text, text ~= ns.L.TABLE_SORT_HINT }
  end
  return { headers = headers, entries = chunked(historyEntries()) }
end)

-- LT-171: Hauptreiter je Sprache mit Breite und Zeile (y), Unterreiter je Reiter, Charakter-Auswahl in "Alle Charaktere"
check("LT171.history.tabs", function()
  local HistoryWindow = ns.HistoryWindow
  return { language = ns.Language(), subtabsTop = HistoryWindow.SubtabsTop(), window = frameState(_G[ns.GlobalName("History")]),
    allCharacters = HistoryWindow.IsAllCharacters(), selected = HistoryWindow.SelectedCharacter(),
    entries = chunked(historyEntries()) }
end)

-- LT-203: letzte Beute-Journal-Einträge: gemerkter Wert gegen den Preis, den der Client jetzt kennt
check("LT203.loot.value", function()
  local entries, withoutPrice = {}, 0
  for _, entry in ipairs(recentEntries("lootLog")) do
    local current = entry.link and ns.Items.GetSellPrice(entry.link)
    if not (entry.value or current) then withoutPrice = withoutPrice + 1 end
    entries[#entries + 1] = { link = entry.link or entry.name, quantity = entry.quantity, quality = entry.quality,
      stored = entry.value, client = current }
  end
  return { entries = chunked(entries), withoutPrice = withoutPrice }
end)

---------------------------------------------------------------------------
-- Instanzen und Dungeon-Läufe
---------------------------------------------------------------------------
-- LT-195: Beute im Instanzbericht: Boss-Name je Wurf (rollLog.encounter), API je Client, Berichtsteile des Laufs
check("LT195.report.bossName", function()
  local rolls = {}
  for _, entry in ipairs(recentEntries("rollLog")) do
    rolls[#rolls + 1] = { link = entry.link, winner = entry.winner, encounter = entry.encounter, runStart = entry.runStart,
      instance = entry.instance }
  end
  local run = ns.Instances.GetCurrentRun() or recentEntries("instanceLog", 1)[1]
  return { forever = ns.Client.IsForever(), encounterApi = api("C_LootHistory.GetInfoForEncounter") ~= nil,
    rolls = chunked(rolls), report = run and ns.InstanceReport.LootParts(run) or false,
    settings = { loot = ns.db.instanceReportLoot, quality = ns.db.instanceReportLootQuality, max = ns.db.instanceReportLootMax } }
end)

-- LT-200: Stammdaten der aktuellen Instanz (Spieler, Reset, Level), "Dungeons fürs Level", Werte des letzten Laufs
check("LT200.instance.master", function()
  local mapID, difficultyID = currentInstance()
  local InstanceInfo, last = ns.InstanceInfo, recentEntries("instanceLog", 1)[1]
  local forLevel = {}
  for _, entry in ipairs(InstanceInfo.ForLevel(UnitLevel("player"))) do
    forLevel[#forLevel + 1] = { entry.mapID, InstanceInfo.MapName(entry.mapID), entry.minLevel, entry.maxLevel }
  end
  return { mapID = mapID, difficultyID = difficultyID, name = mapID and InstanceInfo.MapName(mapID),
    info = mapID and InstanceInfo.Get(mapID, difficultyID), text = mapID and InstanceInfo.Describe(mapID, difficultyID),
    hasLevels = InstanceInfo.HasLevels(), forLevel = { total = #forLevel, first = first(forLevel, 3) },
    lastRun = last and { name = last.name, mapID = last.mapID, difficultyID = last.difficultyID, groupSize = last.groupSize,
      info = last.mapID and InstanceInfo.Get(last.mapID, last.difficultyID) } or false }
end)

-- LT-226: Live-Tracker (Karte), neuester Lauf mit Zeit, Splits, XP je Boss, Beute; die Chatzeile "neue Bestzeit!"
-- steht als Bereich "print" im laufenden Log
check("LT226.runs.live", function()
  local run = ns.Instances.GetCurrentRun()
  local card, log = ns.InstanceRunTracker.Card(), ns.History.GetInstanceLog(ns.characterKey)
  local record = log[1]
  local state = { tracker = { setting = ns.db.showRunTracker, card = card and cardText(card.frame),
    frame = card and frameState(card.frame) },
    current = run and { name = run.name, progress = ns.InstanceBosses.ProgressText(run) } or false,
    windowShown = ns.InstanceRunWindow.IsShown(), newBest = ns.InstanceRuns.IsNewBest() }
  if record then
    -- Fensterende wie in UI/InstanceRunWindow.lua (neuester Lauf: bis jetzt)
    local windowEnd = ns.InstanceRuns.WindowEnd(log, 1)
    local xpList = {}
    for id, value in pairs(ns.InstanceRuns.BossXp(ns.characterKey, record, windowEnd)) do
      xpList[#xpList + 1] = id .. "=" .. plain(value)
    end
    table.sort(xpList)
    state.record = { name = record.name, seconds = ns.InstanceRuns.Seconds(record), completed = ns.InstanceRuns.IsCompleted(record),
      progress = ns.InstanceBosses.ProgressText(record), splits = ns.InstanceRuns.Splits(record), bossXp = xpList,
      loot = #ns.InstanceRuns.Loot(ns.characterKey, record, windowEnd), tooltip = ns.InstanceBosses.TooltipLines(record) or false }
  end
  return state
end)

-- Fehlende Dungeonquests einer Instanz wie der Quest-Check beim Betreten (Titel, Annehmbarkeit, Chatzeile, Geist)
local function questState(mapID)
  local missing = {}
  for _, quest in ipairs(ns.InstanceQuestCheck.Missing(mapID)) do
    missing[#missing + 1] = { quest.questID, quest.title, quest.level, quest.minLevel, ns.DungeonQuests.CanTake(quest.questID),
      ns.DungeonEntrances.StartText(quest) or false }
  end
  local all = {}
  for _, quest in ipairs(ns.DungeonQuests.InstanceQuests(mapID)) do
    all[#all + 1] = { quest.questID, quest.level, quest.minLevel, quest.available }
  end
  return { mapID = mapID, name = ns.InstanceInfo.MapName(mapID), missing = chunked(missing),
    line = ns.InstanceQuestCheck.Text(mapID) or false,
    instanceQuests = chunked(all), ghost = call("UnitIsGhost", "player"), faction = (call("UnitFactionGroup", "player")),
    setting = ns.db.instanceQuestCheck }
end

-- LT-227: Quest-Check der aktuellen Instanz; die Probe unten schreibt dasselbe nach dem Betreten (Wiedereintritt als
-- Geist: zweite Chatzeile als Bereich "print" im Log?)
check("LT227.questCheck", function()
  local mapID = currentInstance()
  if not mapID then return { instance = false } end
  return questState(mapID)
end)

---------------------------------------------------------------------------
-- Boss-Beute und Mechaniken
---------------------------------------------------------------------------
-- LT-230: Beute-Tooltip: Drops des Ziels (NPC-ID) und der aktuellen Instanz, Zeilenzahl, Item-Mixin vorhanden, dem
-- Client unbekannte Items (Era: IDs ab 250000)
check("LT230.bossLoot.tooltip", function()
  local mapID, npcID = currentInstance(), targetNpc()
  local mixin = itemMixin(1)
  return { available = ns.BossLoot.IsAvailable(), enabled = ns.db.bossLoot, mixin = mixin ~= nil,
    continueOnLoad = type(mixin) == "table" and type(mixin.ContinueOnItemLoad) == "function",
    target = npcID and { npcID = npcID, summary = lootSummary(ns.BossLoot.Items(npcID)),
      items = dropList(ns.BossLoot.Items(npcID)) } or false,
    instance = mapID and { mapID = mapID, summary = lootSummary(ns.BossLoot.ForInstance(mapID)),
      items = dropList(ns.BossLoot.ForInstance(mapID)) } or false }
end)

---------------------------------------------------------------------------
-- Ereignis-Proben (nur mit laufendem Log)
---------------------------------------------------------------------------
-- LT-73: jeder Import und jedes Öffnen des Import-Fensters (kam der Text an? wie viele Läufe sind danach importiert?)
local function importedCount()
  local count = 0
  for _, run in ipairs(ns.Runs.GetAll()) do
    if run.imported then count = count + 1 end
  end
  return count
end

hooksecurefunc(ns.Runs, "Import", function(text)
  if not DebugLog.IsEnabled() then return end
  write({ area = "event", event = "runs.import",
    extra = { length = type(text) == "string" and #text or plain(text), importedRuns = safe(importedCount) } })
end)

hooksecurefunc(ns.Export, "ShowImport", function(heading)
  if not DebugLog.IsEnabled() then return end
  write({ area = "event", event = "runs.importOpen", extra = { heading = heading } })
end)

-- LT-76: Prognose beim Levelstart (zum Vergleich mit den späteren Level-Zeiten)
ns.OnLevelStarted(function(newLevel)
  if not DebugLog.IsEnabled() then return end
  write({ area = "event", event = "forecast.levelStart", extra = { newLevel = newLevel, forecast = safe(forecastState) } })
end)

-- LT-227: offene Dungeonquests kurz nach dem Betreten einer Instanz (wie die Chatzeile, mit IDs und Titeln)
ns.RegisterEvent("PLAYER_ENTERING_WORLD", function()
  if not DebugLog.IsEnabled() or not (C_Timer and C_Timer.After) then return end
  C_Timer.After(QUEST_CHECK_DELAY, function()
    local mapID = currentInstance()
    if mapID then write({ area = "event", event = "instance.questCheck", extra = safe(questState, mapID) }) end
  end)
end)

-- LT-401: Live-Tracker-Aufbau: Bossanzahl, ausgeklappt (bis COLLAPSE_ABOVE_BOSSES Bosse), Reihenabstand, Porträtrahmen
check("LT401.tracker.layout", function()
  ns.InstanceRunTracker.Refresh()
  return ns.InstanceRunTracker.Layout()
end)

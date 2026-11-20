-- Debug-Prüfungen für offene Spielprüfungen im Board (Quests, Karte, Reisen und Komfort-Module): Datenteil der Vikunja-Tasks „Prüfen: …“,
-- damit im
-- Spiel nur noch das Sichtbare bleibt. Namen "LT<Index>.<Bereich>.<Was>" (Index = Task im Board). Lesen nur öffentliche
-- Funktionen der Module, ändern nichts, rufen keine geschützten Funktionen.
local _, X = ...
local ns = X.LT
if not ns then return end
local DebugLog = X.DebugLog
local Probe, H = DebugLog.Probe, DebugLog.Helpers
local call, api = Probe.call, Probe.api
local write = DebugLog.Write
local check = DebugLog.AddCheck
local frameState = H.frameState
local MAX_SAMPLE = 12      -- so viele Einträge je Liste im Log
local MACRO_LIMIT = 255    -- längstes Makro (Blizzard)

---------------------------------------------------------------------------
-- Helfer
---------------------------------------------------------------------------
-- Einstellungen als { Name = Wert }
local function settings(...)
  local result = {}
  for _, key in ipairs({ ... }) do result[key] = ns.db[key] end
  return result
end

-- Die ersten MAX_SAMPLE Einträge (bei map umgewandelt)
local function sample(list, map)
  local result = {}
  for index = 1, math.min(#list, MAX_SAMPLE) do result[index] = map and map(list[index]) or list[index] end
  return result
end

local function unitName(unit)
  if call("UnitExists", unit) ~= true then return nil end
  return (call("UnitName", unit))
end

-- Anzahl Zeilen des Tooltips, die line enthalten (Doppelzeilen finden); nil ohne Tooltip oder Text
local function countLines(tooltip, line)
  local name = type(tooltip) == "table" and tooltip.GetName and tooltip:GetName()
  if not name or type(line) ~= "string" or type(tooltip.NumLines) ~= "function" then return nil end
  local count = 0
  for index = 1, (tooltip:NumLines() or 0) do
    local text = _G[name .. "TextLeft" .. index]
    local value = text and text:GetText()
    if type(value) == "string" and not ns.IsSecret(value) and value:find(line, 1, true) then count = count + 1 end
  end
  return count
end

local function currentMap()
  return (call("C_Map.GetBestMapForUnit", "player"))
end

local function logging()
  return DebugLog.IsEnabled()
end

---------------------------------------------------------------------------
-- Questgegner: Zielstand, gelernte Namen, Zielknopf
---------------------------------------------------------------------------
-- LT-152, LT-153: Stand je Namensplakette aus dem Questlog (QuestMobs.ProgressOf), offene Questgegner, Tooltipzeile
-- für Ziel und Mouseover (Classic Era), noch unerledigte Zuordnungen
check("LT152.quests.counters", function()
  local plates = {}
  for index = 1, 40 do
    local unit = "nameplate" .. index
    local name = unitName(unit)
    if name then
      local progress, hit = ns.QuestMobs.ProgressOf(name)
      plates[#plates + 1] = { unit = unit, name = name, progress = progress, quest = hit and hit.title,
        related = call("C_QuestLog.UnitIsRelatedToActiveQuest", unit) }
    end
  end
  local names = ns.QuestMobs.OpenMobNames()
  local open = {}
  for _, name in ipairs(sample(names)) do open[name] = (ns.QuestMobs.ProgressOf(name)) end
  return { settings = settings("questMarks", "questMarkProgress", "questLearning"),
    clientQuestUnits = ns.QuestMarks.HasClientQuestUnits(), plates = plates, openMobs = #names, openProgress = open,
    pending = ns.QuestMobs.PendingCount(), tooltip = { mouseover = ns.Tooltip.LearnedQuestLine("mouseover"),
      target = ns.Tooltip.LearnedQuestLine("target"), clientTooltipInfo = ns.QuestTooltip.HasTooltipInfo() } }
end)

-- LT-273 (/lt debug check in einer Instanz, mit Gegnern einer annehmbaren Dungeonquest oder Gruppenquest): sichtbare
-- Plaketten mit UnitIsRelatedToActiveQuest = true, Treffer der Umkehrkarte (take/party) und Plaketten ohne lesbare NPC-ID
check("LT273.questmarks.instance", function()
  local result = { settings = settings("questMarks", "questTargetsTake", "questTargetsParty"),
    inInstance = call("IsInInstance"), plates = 0, related = 0, take = 0, party = 0, secretGuid = 0 }
  for unit in pairs(ns.NamePlates.Active()) do
    if unitName(unit) then
      result.plates = result.plates + 1
      if call("C_QuestLog.UnitIsRelatedToActiveQuest", unit) == true then result.related = result.related + 1 end
      local kind = ns.QuestTargets.KindOf(unit)
      if kind then result[kind] = result[kind] + 1 end
      if not ns.QuestBlocklist.NpcId(UnitGUID(unit)) then result.secretGuid = result.secretGuid + 1 end
    end
  end
  return result
end)

-- LT-154: Zielknopf (Makrotext samt Länge, Sichtbarkeit, Marker auf dem Ziel)
check("LT154.quests.targetButton", function()
  local button = _G[ns.GlobalName("QuestTargetButton")]
  local macro = type(button) == "table" and button.GetAttribute and button:GetAttribute("macrotext") or nil
  local names = ns.QuestItem.TargetNames()
  return { settings = settings("questTargetButton", "questTargetMarker", "questLearning"), button = frameState(button),
    macro = macro, macroLength = type(macro) == "string" and #macro or nil,
    macroOk = type(macro) ~= "string" or #macro <= MACRO_LIMIT, names = sample(names), nameCount = #names,
    openMobs = #ns.QuestMobs.OpenMobNames(), inCombat = call("InCombatLockdown"),
    targetMarker = call("GetRaidTargetIndex", "target") }
end)

-- LT-154: setzt /tm solo einen Marker (Era)?
ns.RegisterEvent("RAID_TARGET_UPDATE", function()
  if not logging() then return end
  write({ area = "event", event = "RAID_TARGET_UPDATE", extra = { target = call("GetRaidTargetIndex", "target"),
    grouped = call("IsInGroup") } })
end)

---------------------------------------------------------------------------
-- Questlog: aufräumen, Effizienz
---------------------------------------------------------------------------
-- LT-156: Abbrechen (Quest danach noch im Log?) und Meldung "Questlog fast voll"
hooksecurefunc(ns.QuestCleanup, "Abandon", function(questID)
  if not logging() then return end
  write({ area = "event", event = "quests.abandon", extra = { questID = questID, stillInLog = ns.QuestLog.Find(questID) ~= nil } })
end)
hooksecurefunc(ns.Alerts, "Notify", function(entry)
  if not logging() or type(entry) ~= "table" or entry.icon ~= ns.Alerts.ICONS.questLog then return end
  write({ area = "event", event = "quests.fullHint", extra = { title = entry.title, text = entry.text,
    count = ns.QuestLog.QuestCount(), max = ns.QuestLog.MaxQuests() } })
end)

-- LT-174: Quest-Effizienz (Tabelle) und Tooltipzeile je Quest im Log
check("LT174.quests.efficiency", function()
  local records = ns.QuestEfficiency.GetRecords()
  local lines = {}
  for _, entry in ipairs(sample(ns.QuestLog.Entries())) do lines[tostring(entry.questID)] = ns.QuestEfficiency.Text(entry.questID) end
  return { setting = ns.db.questEfficiencyTooltip, count = #records, logLines = lines,
    rows = sample(records, function(stat)
      return { questID = stat.questID, count = stat.count, averageSeconds = stat.averageSeconds, averageXp = stat.averageXp,
        xpPerMinute = stat.xpPerMinute }
    end) }
end)

-- LT-174: feuert der Tooltip-Haken für Quest-Links (Chat, Questliste neben der Karte in Retail/Forever)?
if type(GameTooltip) == "table" and type(GameTooltip.SetHyperlink) == "function" then
  hooksecurefunc(GameTooltip, "SetHyperlink", function(tooltip, link)
    if not logging() or ns.IsSecret(link) or type(link) ~= "string" then return end
    local questID = tonumber((link:match("quest:(%d+)")))
    if not questID then return end
    local line = ns.QuestEfficiency.Text(questID)
    write({ area = "event", event = "quests.tooltipLink", extra = { questID = questID, line = line,
      lines = countLines(tooltip, line) } })
  end)
end

---------------------------------------------------------------------------
-- Gegenstände und Reste
---------------------------------------------------------------------------
-- LT-176: Zeile "Für Quest: ..." samt Farbe je Taschengegenstand mit Questbezug
check("LT176.quests.itemTooltip", function()
  local items = {}
  ns.Bags.ForEachItem(function(_, _, info)
    local itemID = info and not ns.IsSecret(info.itemID) and info.itemID
    if itemID and #items < MAX_SAMPLE then
      local text, color = ns.QuestItemTooltip.Line(itemID, ns.Items.GetName(itemID))
      if text then items[#items + 1] = { itemID = itemID, text = text, color = color } end
    end
  end)
  return { settings = settings("questItemTooltip", "questLearning"), items = items }
end)

-- LT-176: Tooltips mit Gegenstand (Tasche, Händler, Beute, Chat-Link): Quelle und Zahl der Zeilen mit dem Zusatztext
local function itemTooltipProbe(source)
  return function(tooltip)
    if not logging() or type(tooltip.GetItem) ~= "function" then return end
    local name, link = tooltip:GetItem()
    local itemID = type(link) == "string" and not ns.IsSecret(link) and tonumber((link:match("item:(%d+)")))
    local text = itemID and ns.QuestItemTooltip.Line(itemID, not ns.IsSecret(name) and name or nil)
    if text then
      write({ area = "event", event = "quests.itemTooltip", extra = { source = source, itemID = itemID, text = text,
        lines = countLines(tooltip, text) } })
    end
  end
end
for _, setter in ipairs({ "SetBagItem", "SetMerchantItem", "SetLootItem", "SetHyperlink" }) do
  if type(GameTooltip) == "table" and type(GameTooltip[setter]) == "function" then
    hooksecurefunc(GameTooltip, setter, itemTooltipProbe(setter))
  end
end

-- LT-179: Questreste in den Taschen, Hinweistext, löschbare Plätze
check("LT179.quests.leftovers", function()
  local found = ns.QuestLeftovers.InBags()
  local deletable = ns.QuestLeftovers.Deletable()
  return { settings = settings("questLeftovers", "questLearning"), text = ns.QuestLeftovers.Text(),
    bagsHint = ns.QuestLeftovers.BagsHint(), deletableCount = #deletable, deletable = sample(deletable),
    inBags = sample(found, function(entry)
      return { itemID = entry.itemID, name = entry.name, count = entry.count, marked = ns.QuestLeftovers.IsMarked(entry.itemID) }
    end) }
end)

-- LT-179: beim Händler: was der Hinweis nennt (kein Text = nichts übrig oder alles für eine offene Quest gebraucht)
ns.RegisterEvent("MERCHANT_SHOW", function()
  if not logging() then return end
  write({ area = "event", event = "quests.merchantLeftovers", extra = { enabled = ns.db.questLeftovers,
    text = ns.QuestLeftovers.Text(), count = #ns.QuestLeftovers.InBags() } })
end)

---------------------------------------------------------------------------
-- Karte: gelernte Orte, Dungeonquest-Geber, Kartensymbole, Minimap
---------------------------------------------------------------------------
-- LT-177: Punkte der offenen Quests auf der aktuellen Karte, gelernte Geber und Abgabe-NPCs je Quest im Log
check("LT177.map.questPoints", function()
  local mapID = currentMap()
  local points = mapID and ns.QuestMap.PointsOn(mapID) or {}
  local quests = {}
  for _, entry in ipairs(sample(ns.QuestLog.Entries())) do
    local record = ns.QuestNpcs.Get(entry.questID)
    quests[#quests + 1] = { questID = entry.questID, ready = entry.ready, giver = record and record.giver,
      turnIn = record and record.turnIn, spots = record and record.spots and #record.spots or 0,
      turnInName = ns.QuestNpcs.TurnInName(entry.questID) }
  end
  return { settings = settings("questMap", "questLearning"), mapID = mapID, pointCount = #points, quests = quests,
    revision = ns.QuestNpcs.Revision(), points = sample(points, function(point)
      return { questID = point.questID, x = point.x, y = point.y, ready = point.ready, npc = point.npc }
    end) }
end)

-- LT-330 (vorher LT-231): keine Geber über dem Levelbereich? Angebote von Mouseover und Ziel, Geber auf der aktuellen Zonenkarte
check("LT330.dungeon.givers", function()
  local units = {}
  for _, unit in ipairs({ "mouseover", "target" }) do
    units[unit] = { name = unitName(unit), offers = sample(ns.DungeonQuests.UnitOffers(unit), function(offer)
      return { questID = offer.questID, title = ns.DungeonQuests.Title(offer.questID),
        line = ns.DungeonQuestGivers.OfferLine(offer), step = offer.step, total = offer.total }
    end) }
  end
  local mapID = currentMap()
  local zone = mapID and ns.QuestLog.ZoneMapOf(mapID)
  local points = zone and ns.DungeonQuests.OffersOnMap(zone) or {}
  return { settings = settings("dungeonQuestGivers"), available = ns.DungeonQuests.IsAvailable(),
    revision = ns.DungeonQuests.Revision(), units = units, mapID = mapID, zone = zone, mapPoints = #points,
    firstPoint = points[1] and { x = points[1].x, y = points[1].y, offers = #points[1].offers } or nil }
end)

-- LT-237: Kartenaddons, Weltkarte (Karte, Skalierung), Geber auf der angezeigten Karte
check("LT237.map.pins", function()
  local map = _G.WorldMapFrame
  local mapID = type(map) == "table" and map.GetMapID and map:GetMapID() or nil
  local canvas = type(map) == "table" and map.GetCanvas and map:GetCanvas() or nil
  local addons = {}
  for _, name in ipairs({ "OpenMap", "Leatrix_Maps", "Mapster", "SexyMap" }) do
    addons[name] = call("C_AddOns.IsAddOnLoaded", name) or call("IsAddOnLoaded", name)
  end
  return { addons = addons, mapID = mapID, map = frameState(map), canvas = frameState(canvas),
    canvasScale = type(canvas) == "table" and canvas.GetScale and canvas:GetScale() or nil,
    givers = mapID and #ns.DungeonQuests.OffersOnMap(mapID) or nil,
    settings = settings("dungeonQuestGivers", "dungeonEntrances", "deathMap") }
end)

-- LT-238: Minimap (Sichtradius, Zoom, Drehen, drinnen) und Versatz dreier Beispielgeber
check("LT238.minimap.givers", function()
  local radius = ns.MinimapPins.Radius()
  local facing = call("GetPlayerFacing") or 0
  local function offset(east, north, square)
    local x, y, edge = ns.MinimapPins.Offset(east, north, radius, facing, square, true)
    return x and { x = x, y = y, edge = edge } or false
  end
  return { settings = settings("dungeonQuestMinimap", "dungeonQuestMinimapEdge", "minimapSquare"),
    available = ns.DungeonQuestMinimap.IsAvailable(), radius = radius, zoom = Minimap and Minimap:GetZoom(),
    indoors = call("IsIndoors"), rotateMinimap = call("C_CVar.GetCVar", "rotateMinimap"), facing = facing,
    sample = { inside = offset(radius / 2, 0), outside = offset(radius * 1.5, 0), outsideSquare = offset(radius * 1.5, 0, true) } }
end)

---------------------------------------------------------------------------
-- Dungeonquests beim Betreten und nach der Annahme
---------------------------------------------------------------------------
-- LT-330 (vorher LT-235): Einträge des Zonen-Hinweises (keine Instanzen unter dem eigenen Level?): Geber, Titel,
-- schon im Log?, Ort gegen die Spielerposition
check("LT330.dungeon.zone", function()
  local mapID = currentMap()
  local zone = mapID and ns.QuestLog.ZoneMapOf(mapID)
  local x, y = H.readXY(mapID and call("C_Map.GetPlayerMapPosition", mapID, "player"))
  local entries = zone and ns.DungeonQuestHints.ZoneEntries(zone) or {}
  return { settings = settings("dungeonQuestZoneHint"), mapID = mapID, zone = zone, player = { x = x, y = y },
    shown = ns.DungeonQuestHint.IsShown(), count = #entries, entries = sample(entries, function(entry)
      return { questID = entry.questID, text = entry.text, detail = entry.detail, giver = ns.DungeonQuestHints.GiverName(entry.questID),
        inLog = ns.QuestLog.Find(entry.questID) ~= nil, x = entry.place and entry.place.x, y = entry.place and entry.place.y }
    end) }
end)

-- LT-330: beim Betreten einer Zone, nachdem die Module reagiert haben
local function zoneProbe(event)
  return function()
    if not logging() then return end
    local mapID = currentMap()
    local zone = mapID and ns.QuestLog.ZoneMapOf(mapID)
    write({ area = "event", event = event, name = "LT330.dungeon.zoneEntered", extra = { zone = zone,
      entries = zone and #ns.DungeonQuestHints.ZoneEntries(zone) or 0, hintShown = ns.DungeonQuestHint.IsShown() } })
  end
end
ns.RegisterEvent("PLAYER_ENTERING_WORLD", zoneProbe("PLAYER_ENTERING_WORLD"))
ns.RegisterEvent("ZONE_CHANGED_NEW_AREA", zoneProbe("ZONE_CHANGED_NEW_AREA"))

-- LT-328 (vorher LT-236): Mindeststufe in Forever, übrige Quests der Instanz je Dungeonquest im Log (annehmbar/später), Wegpunkt-API
check("LT328.dungeon.accept", function()
  local rows = {}
  for _, entry in ipairs(ns.QuestLog.Entries()) do
    local entries = ns.DungeonQuestHints.AcceptEntries(entry.questID)
    if entries and #rows < MAX_SAMPLE then
      local later = 0
      for _, item in ipairs(entries) do if item.muted then later = later + 1 end end
      rows[#rows + 1] = { questID = entry.questID, entries = #entries, later = later,
        first = entries[1] and { text = entries[1].text, detail = entries[1].detail } or nil }
    end
  end
  return { settings = settings("dungeonQuestAcceptHint"), rows = rows, waypoint = ns.DungeonQuestHint.Waypoint(),
    api = { setUserWaypoint = api("C_Map.SetUserWaypoint") ~= nil, canSet = api("C_Map.CanSetUserWaypointOnMap") ~= nil,
      uiMapPoint = type(_G.UiMapPoint) }, hasUserWaypoint = call("C_Map.HasUserWaypoint"), inCombat = call("InCombatLockdown") }
end)

-- LT-236: Klick auf einen Eintrag (Kampf, Blizzard-Wegpunkt gesetzt?)
hooksecurefunc(ns.DungeonQuestHint, "SetWaypoint", function(entry)
  if not logging() then return end
  write({ area = "event", event = "dungeon.setWaypoint", extra = { questID = entry and entry.questID,
    inCombat = call("InCombatLockdown"), hasUserWaypoint = call("C_Map.HasUserWaypoint") } })
end)

---------------------------------------------------------------------------
-- Flug, Bereit-Timer, Chat, Minimap-Leiste, Würfelkarte
---------------------------------------------------------------------------
-- LT-185: Zeile und Quelle je Flugpunkt, über den die Maus fährt (Zeilen mit dem Text im Tooltip: Doppelzeile?)
if type(_G.TaxiNodeOnButtonEnter) == "function" then
  hooksecurefunc("TaxiNodeOnButtonEnter", function(button)
    if not logging() or type(button) ~= "table" then return end
    local slot = button:GetID()
    local text, estimated = ns.FlightTooltip.Line(slot)
    local known = ns.FlightTimer.Lookup(slot)
    write({ area = "event", event = "flight.tooltip", extra = { slot = slot, text = text, estimated = estimated,
      source = known and known.source, seconds = known and known.seconds, origin = known and known.origin,
      lines = countLines(GameTooltip, text) } })
  end)
end

-- LT-84: Bereit-Timer (Text, Frame, Schlachtfeld-Restzeit)
local function readyState()
  local frame = ns.ReadyTimer.Frame()
  return { text = ns.ReadyTimer.Text(GetTime()), line = ns.ReadyTimer.TextLine(),
    battlefield = ns.ReadyTimer.BattlefieldSecondsLeft(), frame = frame and frameState(frame) or false }
end
check("LT84.ready.state", function()
  local state = readyState()
  state.setting = ns.db.readyTimer
  return state
end)
for _, event in ipairs({ "READY_CHECK", "READY_CHECK_FINISHED", "UPDATE_BATTLEFIELD_STATUS" }) do
  ns.RegisterEvent(event, function()
    if not logging() then return end
    write({ area = "event", event = event, name = "LT84.ready.event", extra = readyState() })
  end)
end

-- LT-199: Zurückstellen der Knöpfe (im Kampf aufgeschoben?)
hooksecurefunc(ns.MinimapBar, "RestoreAll", function()
  if not logging() then return end
  write({ area = "event", event = "minimapBar.restoreAll", extra = { inCombat = call("InCombatLockdown"),
    collected = #ns.MinimapBar.Collected() } })
end)

-- LT-252: Stufenbereiche der Zonen aus dem Client (Blizzard zeigt sie selbst auf der Weltkarte; eigene Anzeige nur,
-- wenn Forever hier 0/nil liefert oder die Werte nicht zum Forever-Guide passen)
check("LT252.map.zoneLevels", function()
  local zones, withLevels, missing = {}, 0, {}
  for _, continentID in ipairs({ 1414, 1415 }) do  -- Kalimdor, Östliche Königreiche
    for _, child in ipairs(call("C_Map.GetMapChildrenInfo", continentID, 3) or {}) do
      local minLevel, maxLevel = call("C_Map.GetMapLevels", child.mapID)
      if type(minLevel) == "number" and minLevel > 0 then
        withLevels = withLevels + 1
        if #zones < 40 then zones[#zones + 1] = { child.name, minLevel, maxLevel } end
      elseif #missing < MAX_SAMPLE then
        missing[#missing + 1] = child.name
      end
    end
  end
  return { withLevels = withLevels, zones = zones, withoutLevels = missing }
end)

-- LT-234: Würfelkarte: Symbol-Textur je Wurf (im Wurf gemerkt und frisch aus dem Client) und Kartentext
check("LT234.lootroll.icon", function()
  local rows = {}
  for _, roll in ipairs(ns.LootRolls.All()) do
    if #rows < MAX_SAMPLE then
      local itemID = type(roll.link) == "string" and tonumber((roll.link:match("item:(%d+)")))
      rows[#rows + 1] = { name = roll.name, itemID = itemID, texture = roll.texture,
        fresh = itemID and call("C_Item.GetItemIconByID", itemID), text = ns.LootRollDisplay.ItemText(roll) }
    end
  end
  return { count = #rows, rows = rows }
end)

-- LT-287: gesammelte Bücher des Extractors (Anzahl, Beispiele mit Objekt-IDs und Orten) und gemerkte Bücher von Level Time
check("LT287.books.collected", function()
  local rows, count = {}, 0
  for name, record in pairs(X.db and X.db.books or {}) do
    count = count + 1
    if #rows < MAX_SAMPLE then
      rows[#rows + 1] = { name = name, opened = record.opened, objects = record.objects, maps = record.maps,
        spotMaps = record.spots and next(record.spots) }
    end
  end
  return { extractorBooks = count, rows = rows, readByPlayer = ns.LibraryBooks and ns.LibraryBooks.Count() }
end)

-- LT-412: Minimap-Filter "Triviale Quests": gibt es die API, welcher Index, lässt sich SetTracking aus Addon-Code rufen
-- (Umschalten und sofort zurück, gesichert mit pcall)
check("LT412.trivialTracking.api", function()
  local map = _G.C_Minimap
  local filterID = _G.Enum and _G.Enum.MinimapTrackingFilter and _G.Enum.MinimapTrackingFilter.TrivialQuests
  local result = { filterID = filterID, getNum = type(map and map.GetNumTrackingTypes),
    getFilter = type(map and map.GetTrackingFilter), set = type(map and map.SetTracking),
    isFilteredOut = type(map and map.IsFilteredOut), settings = settings("dungeonQuestTrivialNearby",
      "dungeonQuestTrivialTracking") }
  if not (result.getNum == "function" and result.getFilter == "function" and filterID) then return result end
  for index = 1, map.GetNumTrackingTypes() do
    local filter = map.GetTrackingFilter(index)
    if type(filter) == "table" and filter.filterID == filterID then result.index = index end
  end
  if not (result.index and result.set == "function" and result.isFilteredOut == "function") then return result end
  local before = map.IsFilteredOut(filterID)
  result.filteredBefore = before
  result.setOk, result.setError = pcall(map.SetTracking, result.index, before)  -- gefiltert -> einschalten
  result.filteredAfter = map.IsFilteredOut(filterID)
  pcall(map.SetTracking, result.index, not before)  -- zurück
  result.filteredRestored = map.IsFilteredOut(filterID)
  return result
end)

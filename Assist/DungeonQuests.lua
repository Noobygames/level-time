-- Dungeonquests und ihre Vorquest-Ketten aus ns.DungeonDB (generiert, nur Classic Era und Forever; Aufbau im Kopf von
-- Assist/InstanceData/dungeon_db.lua): welche Quest gehört zu welcher Instanz, welche Geber bieten dem Charakter
-- jetzt eine an. Nur Daten und Regeln, keine Anzeige (DungeonQuestGivers.lua, DungeonQuestTags.lua).
-- Annehmbar = Mindestlevel erreicht, Fraktion und Klassenmaske passen, nicht abgegeben und nicht im Log, alle "pre" und
-- eine aus "preAny" abgegeben, keine aus "excl" abgegeben oder im Log. Abgegeben = QuestItemTooltip.IsQuestDone
-- (C_QuestLog.IsQuestFlaggedCompleted, sonst das globale IsQuestFlaggedCompleted, plus Abgaben dieser Sitzung).
-- Klasse über die 3. Rückgabe von UnitClass (classID, alle Clients), Bit 2^(classID-1) der Klassenmaske.
-- Die Zuordnungen Quest -> Instanz und Karte -> Quests entstehen einmal beim ersten Zugriff; Ergebnisse von CanTake gelten bis zur
-- nächsten Änderung an Questlog, Abgaben oder Level (Revision).
local _, ns = ...

local DungeonQuests = {}
ns.DungeonQuests = DungeonQuests

-- Spalten in questInfo
local LEVEL, MIN_LEVEL, FACTION, CLASS_MASK, GIVER_KIND, GIVER_ID, GIVER_MAP, GIVER_X, GIVER_Y = 1, 2, 3, 4, 5, 6, 7, 8, 9
-- Spalten in questChains
local CHAIN_MAP, CHAIN_TARGET, CHAIN_STEP, CHAIN_TOTAL = 1, 2, 3, 4
local FACTION_CODES = { Alliance = "A", Horde = "H" }
local ALL_CLASSES = 0
local GIVER_KINDS = { n = "npc", o = "object", i = "item" }
local SINGLE_WORD_LENGTH = 3  -- Kurzname einwortiger Instanzen ("Gno")
local UTF8_CHAR = "[\1-\127\194-\244][\128-\191]*"

local instancesOf    -- [questID] = { Karten-ID, ... } aufsteigend; nil = noch nicht aufgebaut
local revision = 0
local takeCache = {}  -- [questID] = true/false für die aktuelle Revision
local shortNames = {}  -- [Karten-ID] = Kurzname

local function db() return ns.DungeonDB end

local function readable(value)
  if value == nil or ns.IsSecret(value) then return nil end
  return value
end

function DungeonQuests.IsAvailable()
  return ns.DungeonDB ~= nil
end

local chainsOf  -- [Karten-ID] = { questID, ... } der Kettenschritte, die zu dieser Instanz führen

local function buildInstances()
  instancesOf, chainsOf = {}, {}
  local mapIDs = {}
  for mapID in pairs(db().quests) do table.insert(mapIDs, mapID) end
  table.sort(mapIDs)
  for _, mapID in ipairs(mapIDs) do
    for _, questID in ipairs(db().quests[mapID]) do
      instancesOf[questID] = instancesOf[questID] or {}
      table.insert(instancesOf[questID], mapID)
    end
  end
  for questID, chain in pairs(db().questChains) do
    local mapID = chain[CHAIN_MAP]
    chainsOf[mapID] = chainsOf[mapID] or {}
    table.insert(chainsOf[mapID], questID)
  end
  for questID, alternatives in pairs(db().questChainAlt or {}) do
    for _, chain in ipairs(alternatives) do
      chainsOf[chain[CHAIN_MAP]] = chainsOf[chain[CHAIN_MAP]] or {}
      table.insert(chainsOf[chain[CHAIN_MAP]], questID)
    end
  end
end

-- Alle Instanz-Karten-IDs einer Dungeonquest, aufsteigend (nicht verändern); nil ohne Instanz
function DungeonQuests.Instances(questID)
  if not db() or type(questID) ~= "number" then return nil end
  if not instancesOf then buildInstances() end
  return instancesOf[questID]
end

-- Instanz-Karten-ID einer Dungeonquest (die kleinste, falls mehrere), sonst nil
function DungeonQuests.Instance(questID)
  local mapIDs = DungeonQuests.Instances(questID)
  return mapIDs and mapIDs[1]
end

-- Kette zu einer Dungeonquest: Karten-ID, Ziel-questID, Stufe, Gesamt; nil, wenn die Quest in keine führt
function DungeonQuests.Chain(questID)
  local chain = db() and type(questID) == "number" and db().questChains[questID]
  if not chain then return nil end
  return chain[CHAIN_MAP], chain[CHAIN_TARGET], chain[CHAIN_STEP], chain[CHAIN_TOTAL]
end

-- Alle Ketten, in denen die Quest ein Schritt ist (mehrere Instanzen): { { Karten-ID, Ziel-questID, Stufe, Gesamt }, ... },
-- die erste ist Chain(questID); nil, wenn die Quest in keine führt (nicht verändern)
function DungeonQuests.Chains(questID)
  local chain = db() and type(questID) == "number" and db().questChains[questID]
  if not chain then return nil end
  local alternatives = db().questChainAlt and db().questChainAlt[questID]
  if not alternatives then return { chain } end
  local all = { chain }
  for _, alternative in ipairs(alternatives) do table.insert(all, alternative) end
  return all
end

-- Questziele { npcs, items = { [itemID] = { npcs, objects } }, objects } (Aufbau: Kopf der Datenbank); nil ohne Zieldaten
-- (nicht verändern)
function DungeonQuests.Objectives(questID)
  local objectives = db() and db().objectives
  return objectives and type(questID) == "number" and objectives[questID] or nil
end

local targetNpcs = {}  -- [questID] = { [npcID] = true } oder false (keine); gecacht, nicht verändern

-- Menge der NPC-IDs, die ein Tötungs- oder Beute-Ziel der Quest braucht (nicht verändern); nil ohne Zieldaten
function DungeonQuests.TargetNpcs(questID)
  local objectives = DungeonQuests.Objectives(questID)
  if not objectives then return nil end
  if targetNpcs[questID] == nil then
    local set = {}
    for _, npcID in ipairs(objectives.npcs or {}) do set[npcID] = true end
    for _, source in pairs(objectives.items or {}) do
      for _, npcID in ipairs(source.npcs or {}) do set[npcID] = true end
    end
    targetNpcs[questID] = next(set) and set or false
  end
  return targetNpcs[questID] or nil
end

-- Revision der annehmbaren Quests (Anzeigen zeichnen nur bei Änderung neu)
function DungeonQuests.Revision()
  return revision
end

local function invalidate()
  revision = revision + 1
  takeCache = {}
end

local function isDone(questID) return ns.QuestItemTooltip.IsQuestDone(questID) end

local function allDone(questIDs)
  for _, questID in ipairs(questIDs or {}) do
    if not isDone(questID) then return false end
  end
  return true
end

local function anyDone(questIDs)
  if not questIDs then return true end
  for _, questID in ipairs(questIDs) do
    if isDone(questID) then return true end
  end
  return false
end

local function excluded(questIDs)
  for _, questID in ipairs(questIDs or {}) do
    if isDone(questID) or ns.QuestLog.Find(questID) then return true end
  end
  return false
end

-- Vorquests erfüllt und keine ausschließende Quest abgegeben oder im Log (auch für den Forever-Führer)
function DungeonQuests.PrerequisitesMet(pre, preAny, excl)
  return allDone(pre) and anyDone(preAny) and not excluded(excl)
end

local function classFits(mask)
  if not mask or mask == ALL_CLASSES then return true end
  local classID = readable(select(3, UnitClass("player")))
  if type(classID) ~= "number" then return false end
  return math.floor(mask / 2 ^ (classID - 1)) % 2 == 1
end

-- Fraktion und Klasse passen zum Charakter
local function fits(info)
  local faction = FACTION_CODES[readable(UnitFactionGroup("player"))]
  if info[FACTION] and info[FACTION] ~= faction then return false end
  return classFits(info[CLASS_MASK])
end

-- Offen für diesen Charakter: Fraktion und Klasse passen, nicht abgegeben, nicht im Log, nicht ausgeschlossen
local function isOpen(questID, info)
  return fits(info) and not isDone(questID) and not ns.QuestLog.Find(questID) and not excluded(info.excl)
end

-- Instanzen, zu denen die Quest führt: ihre eigenen, sonst die Ziele ihrer Vorquest-Ketten
local function targetMaps(questID)
  local maps = DungeonQuests.Instances(questID)
  if maps then return maps end
  local result = {}
  for _, chain in ipairs(DungeonQuests.Chains(questID) or {}) do result[#result + 1] = chain[CHAIN_MAP] end
  return result
end

-- Ist der Charakter über die Höchststufe aller Ziel-Instanzen hinaus? (LT-330; ohne Level-Daten nie)
local function outgrown(questID, level)
  local maps = targetMaps(questID)
  if #maps == 0 then return false end
  for _, mapID in ipairs(maps) do
    local info = ns.InstanceInfo.Get(mapID)
    if not (info and info.maxLevel) or level <= info.maxLevel then return false end
  end
  return true
end

local function computeCanTake(questID)
  local info = db().questInfo[questID]
  if not info or not isOpen(questID, info) then return false end
  local level = UnitLevel("player") or 0
  return level >= info[MIN_LEVEL] and not outgrown(questID, level) and allDone(info.pre) and anyDone(info.preAny)
end

-- Kann der Charakter die Quest jetzt annehmen?
function DungeonQuests.CanTake(questID)
  if not db() then return false end
  local cached = takeCache[questID]
  if cached == nil then
    cached = computeCanTake(questID)
    takeCache[questID] = cached
  end
  return cached
end

-- Angebot einer annehmbaren Quest: { questID, level, mapID, step, total } (step/total nur bei Schritten einer
-- Vorquest-Kette, die selbst keine Dungeonquest sind); nil, wenn nicht annehmbar oder ohne Bezug zu einer Instanz
local function offerOf(questID, wantedMap)
  local info = db().questInfo[questID]
  local mapID = DungeonQuests.Instance(questID)
  if mapID then return { questID = questID, level = info[LEVEL], minLevel = info[MIN_LEVEL], mapID = mapID } end
  local chains = DungeonQuests.Chains(questID)
  if not chains then return nil end
  local chain = chains[1]
  for _, candidate in ipairs(chains) do
    if candidate[CHAIN_MAP] == wantedMap then chain = candidate end
  end
  return { questID = questID, level = info[LEVEL], minLevel = info[MIN_LEVEL], mapID = chain[CHAIN_MAP],
    step = chain[CHAIN_STEP], total = chain[CHAIN_TOTAL] }
end

function DungeonQuests.Offer(questID)
  if not DungeonQuests.CanTake(questID) then return nil end
  return offerOf(questID)
end

-- Offene Quests einer Instanz (ihre Dungeonquests und die Schritte der Ketten dorthin) wie Offer, dazu
-- available = jetzt annehmbar (sonst fehlen Level oder Vorquests); jetzt annehmbare zuerst, dann nach Questlevel
function DungeonQuests.InstanceQuests(mapID)
  local list, seen = {}, {}
  if not db() then return list end
  if not instancesOf then buildInstances() end
  local function add(questID)
    local info = db().questInfo[questID]
    if seen[questID] or not info or not isOpen(questID, info) then return end
    seen[questID] = true
    local entry = offerOf(questID, mapID)
    entry.available = DungeonQuests.CanTake(questID)
    table.insert(list, entry)
  end
  for _, questID in ipairs(db().quests[mapID] or {}) do add(questID) end
  for _, questID in ipairs(chainsOf[mapID] or {}) do add(questID) end
  table.sort(list, function(a, b)
    if a.available ~= b.available then return a.available end
    if a.level ~= b.level then return a.level < b.level end
    return a.questID < b.questID
  end)
  return list
end

-- Dungeonquests der Instanz selbst (ohne Kettenschritte), die zu Fraktion und Klasse passen und nicht abgegeben
-- sind, auch die im Log; nach Questlevel:
-- { { questID, title, level, minLevel, inLog, uiMapID, x, y, pre, preAny, excl }, ... } (Ort fehlt, wenn unbekannt
-- oder in einer Instanz; pre/preAny/excl wie in questInfo, für DungeonQuests.PrerequisitesMet)
function DungeonQuests.OwnQuests(mapID)
  local list = {}
  if not db() then return list end
  for _, questID in ipairs(db().quests[mapID] or {}) do
    local info = db().questInfo[questID]
    if info and fits(info) and not isDone(questID) then
      local place = DungeonQuests.GiverPlace(questID) or {}
      table.insert(list, { questID = questID, title = DungeonQuests.Title(questID), level = info[LEVEL],
        minLevel = info[MIN_LEVEL], inLog = ns.QuestLog.Find(questID) ~= nil, uiMapID = place.uiMapID, x = place.x,
        y = place.y, pre = info.pre, preAny = info.preAny, excl = info.excl })
    end
  end
  table.sort(list, function(a, b)
    if a.level ~= b.level then return a.level < b.level end
    return a.questID < b.questID
  end)
  return list
end

-- Annehmbare Quests eines Gebers (kind = "npc", "object", "item"), nach Questlevel; leer ohne Angebot
function DungeonQuests.GiverOffers(kind, giverID)
  local offers = {}
  local quests = db() and db().givers[kind] and db().givers[kind][giverID]
  if not quests then return offers end
  for _, questID in ipairs(quests) do
    local offer = DungeonQuests.Offer(questID)
    if offer then table.insert(offers, offer) end
  end
  table.sort(offers, function(a, b) return a.level < b.level end)
  return offers
end

-- NPC-ID aus einer GUID ("Creature-0-<server>-<instanz>-<zone>-<npcId>-<spawn>"); nil bei Spielern/geheimen Werten
local function npcIdOf(unit)
  return ns.QuestBlocklist.NpcId(UnitGUID(unit))
end

-- Angebote der Einheit (nur NPCs); leer ohne Angebot
function DungeonQuests.UnitOffers(unit)
  local npcID = db() and npcIdOf(unit)
  if not npcID then return {} end
  return DungeonQuests.GiverOffers("npc", npcID)
end

local questsByMap  -- [uiMapID] = { questID, ... } mit Geber-Ort auf dieser Karte; nil = noch nicht aufgebaut

-- Geber einer Quest: Art, ID, uiMapID, x, y; für die Horde ihr eigener Geber (giverH), falls die Quest einen hat
local function giverOf(info)
  local horde = info.giverH
  if horde and readable(UnitFactionGroup("player")) == "Horde" then
    return horde[1], horde[2], horde[3], horde[4], horde[5]
  end
  return info[GIVER_KIND], info[GIVER_ID], info[GIVER_MAP], info[GIVER_X], info[GIVER_Y]
end

local function addToMap(questID, uiMapID, x)
  if not (uiMapID and x) then return end
  questsByMap[uiMapID] = questsByMap[uiMapID] or {}
  table.insert(questsByMap[uiMapID], questID)
end

-- Beide Geber-Orte (auch giverH): die Fraktion steht beim ersten Aufruf vielleicht noch nicht fest
local function buildQuestsByMap()
  questsByMap = {}
  for questID, info in pairs(db().questInfo) do
    addToMap(questID, info[GIVER_MAP], info[GIVER_X])
    if info.giverH then addToMap(questID, info.giverH[3], info.giverH[4]) end
  end
end

-- Zonenkarten mit Gebern (unabhängig davon, ob sie gerade etwas anbieten; nicht verändern)
local giverMapIDs
function DungeonQuests.GiverMapIDs()
  if giverMapIDs then return giverMapIDs end
  giverMapIDs = {}
  if not db() then return giverMapIDs end
  if not questsByMap then buildQuestsByMap() end
  for uiMapID in pairs(questsByMap) do table.insert(giverMapIDs, uiMapID) end
  table.sort(giverMapIDs)
  return giverMapIDs
end

-- Annehmbare Quests, deren Geber auf der Zonenkarte steht: { { x, y, offers = { Angebot, ... } }, ... }
-- (Geber am selben Ort zusammengefasst; Geber ohne Ort fallen weg)
function DungeonQuests.OffersOnMap(uiMapID)
  local points, byPlace = {}, {}
  if not db() then return points end
  if not questsByMap then buildQuestsByMap() end
  for _, questID in ipairs(questsByMap[uiMapID] or {}) do
    local offer = DungeonQuests.Offer(questID)
    local giver = offer and DungeonQuests.GiverPlace(questID)
    if giver and giver.uiMapID == uiMapID then
      local place = giver.x .. ":" .. giver.y
      if not byPlace[place] then
        byPlace[place] = { x = giver.x, y = giver.y, offers = {} }
        table.insert(points, byPlace[place])
      end
      table.insert(byPlace[place].offers, offer)
    end
  end
  for _, point in ipairs(points) do table.sort(point.offers, function(a, b) return a.level < b.level end) end
  return points
end

-- Art des Gebers einer Quest ("npc", "object", "item") und seine ID; nil, wenn unbekannt
function DungeonQuests.Giver(questID)
  local info = db() and db().questInfo[questID]
  if not info then return nil end
  local kind, giverID = giverOf(info)
  return GIVER_KINDS[kind], giverID
end

-- Ort des Gebers: { uiMapID, x, y } (x, y 0-1); nil, wenn unbekannt oder in einer Instanz
function DungeonQuests.GiverPlace(questID)
  local info = db() and db().questInfo[questID]
  if not info then return nil end
  local _, _, uiMapID, x, y = giverOf(info)
  if not (uiMapID and x) then return nil end
  return { uiMapID = uiMapID, x = x, y = y }
end

-- Questtitel aus dem Client oder dem Log (QuestLog.Title), sonst der englische Name aus der DungeonDB, sonst "#questID"
function DungeonQuests.Title(questID)
  local title = ns.QuestLog.Title(questID)
  if title then return title end
  local info = db() and db().questInfo[questID]
  return info and info.name or ("#" .. questID)
end

-- Kurzname der Instanz aus ihrem Namen in der Spielsprache: Anfangsbuchstaben der Wörter ("Burg Schattenfang" ->
-- "BS"), bei einem Wort dessen erste Buchstaben ("Gnomeregan" -> "Gno")
function DungeonQuests.ShortName(mapID)
  if shortNames[mapID] then return shortNames[mapID] end
  local name = ns.InstanceInfo.MapName(mapID)
  local initials, words = {}, {}
  for word in name:gmatch("[^%s%-]+") do table.insert(words, word) end
  for _, word in ipairs(words) do table.insert(initials, word:match("^" .. UTF8_CHAR)) end
  local short
  if #words == 1 then
    local chars = {}
    for char in name:gmatch(UTF8_CHAR) do
      if #chars < SINGLE_WORD_LENGTH then table.insert(chars, char) end
    end
    short = table.concat(chars)
  else
    short = table.concat(initials):upper()
  end
  shortNames[mapID] = short
  return short
end

ns.RegisterEvent("QUEST_LOG_UPDATE", invalidate)
ns.RegisterEvent("QUEST_TURNED_IN", invalidate)
ns.OnLevelStarted(invalidate)
ns.OnLogin(invalidate)

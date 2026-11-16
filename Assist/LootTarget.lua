-- Was ist das Interaktionsziel des Soft-Targetings ("softinteract") und kann der Spieler es gerade benutzen?
-- Grundlage für die Beute-Glitzer (LootSparkles.lua). Quellen (wow-ui-source, Zweige forever/live/classic_era):
--   UnitIsGameObject(unit)         Welt-Objekt (Erz, Kraut, Kiste); UnitExists ist für Objekte false
--   SetUnitCursorTexture(tex, unit) setzt das Mauszeiger-Symbol des Ziels auf eine Textur (so macht es auch
--                                  Blizzards Namensplakette, NamePlateDriverMixin:UpdateSoftTargetIconInternal);
--                                  die Textur liefert danach eine Datei-ID, einen Pfad oder einen Atlas-Namen
--   UnitIsInInteractRange(unit)    nur WoW Forever (UnitDocumentation); fehlt = Entfernung unbekannt
--   CanLootUnit(guid)              hasLoot, canLoot; alle Clients (warcraft.wiki.gg API_CanLootUnit)
--   UNIT_SKINNABLE_LEATHER/_ROCK/_HERB  Zeile im Einheiten-Tooltip toter Gegner ("Häutbar", "Benötigt Bergbau",
--                                  "Benötigt Kräutersammeln"; GlobalStrings live und classic_era); gelesen über
--                                  C_TooltipInfo.GetUnit, in Era (ohne C_TooltipInfo) über einen versteckten Tooltip
-- Alle Werte können geheim sein oder fehlen; das zählt als "unbekannt" und führt nie zu einem Glitzern.
local _, ns = ...

local LootTarget = {}
ns.LootTarget = LootTarget

LootTarget.UNIT = "softinteract"
LootTarget.ORE, LootTarget.HERB, LootTarget.QUEST, LootTarget.CORPSE = "ore", "herb", "quest", "corpse"
LootTarget.CHEST, LootTarget.BOBBER, LootTarget.SKIN = "chest", "bobber", "skin"
LootTarget.READY, LootTarget.FAR, LootTarget.LOCKED = "ready", "far", "locked"

local OTHER = "other"
local SKIP = "skip"
local BLOCKED_MARK = "unable"  -- ausgegraute Zeiger heißen "Unable..." (z.B. Fertigkeit zu niedrig)
local MIN_OBJECTIVE_LENGTH = 4  -- kürzere Namen und Ziele passen zu leicht zufällig

-- Zeiger-Dateien unter Interface\Cursor; jeweils auch mit "Unable" davor
local CURSOR_FILES = {
  Mine = LootTarget.ORE,
  GatherHerbs = LootTarget.HERB,
  Quest = LootTarget.QUEST,
  QuestRepeatable = LootTarget.QUEST,
  QuestTurnIn = LootTarget.QUEST,
  QuestInteract = LootTarget.QUEST,
  CampaignQuest = LootTarget.QUEST,
  CampaignQuestTurnIn = LootTarget.QUEST,
  LegendaryQuest = LootTarget.QUEST,
  LegendaryQuestTurnIn = LootTarget.QUEST,
  PickLock = LootTarget.CHEST,
  LootAll = LootTarget.CHEST,
  Fishing = LootTarget.BOBBER,
  FishingCursor = LootTarget.BOBBER,
  Mail = SKIP,
  Speak = SKIP,
  Buy = SKIP,
  Trainer = SKIP,
  Taxi = SKIP,
  Innkeeper = SKIP,
  Repair = SKIP,
  RepairNPC = SKIP,
  Stablemaster = SKIP,
  Transmogrify = SKIP,
  Inspect = SKIP,
  Attack = SKIP,
  Directions = SKIP,
}

-- Stichwörter im Pfad oder Atlas-Namen, in dieser Reihenfolge geprüft
local CURSOR_WORDS = {
  { "gatherherbs", LootTarget.HERB },
  { "herb", LootTarget.HERB },
  { "mine", LootTarget.ORE },
  { "quest", LootTarget.QUEST },
  { "campaign", LootTarget.QUEST },
  { "legendary", LootTarget.QUEST },
  { "important", LootTarget.QUEST },
  { "recurring", LootTarget.QUEST },
  { "wrapper", LootTarget.QUEST },
  { "picklock", LootTarget.CHEST },
  { "openhand", LootTarget.CHEST },
  { "fishing", LootTarget.BOBBER },
  { "mail", SKIP },
  { "speak", SKIP },
  { "buy", SKIP },
  { "trainer", SKIP },
  { "taxi", SKIP },
  { "innkeeper", SKIP },
  { "repair", SKIP },
}

local CHEST_KEYWORDS = {
  "truhe", "kiste", "kassette", "schatzkiste", "vorratskiste",
  "chest", "crate", "footlocker", "strongbox", "lockbox",
  "coffre", "caisse",
  "cofre", "arqueta",
}

-- Ruft fn geschützt auf; Fehler, geheime oder fehlende Werte = nil
local function read(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, value = pcall(fn, ...)
  if not ok or ns.IsSecret(value) then return nil end
  return value
end

function LootTarget.IsAvailable()
  return type(UnitIsGameObject) == "function" and type(SetUnitCursorTexture) == "function"
    and C_NamePlate ~= nil and type(C_NamePlate.GetNamePlateForUnit) == "function"
end

---------------------------------------------------------------------------
-- Zeiger-Symbol
---------------------------------------------------------------------------
local probe       -- unsichtbare Textur, in die das Zeiger-Symbol gesetzt wird
local cursorIds   -- Datei-ID -> { Art, ausgegraut, file }

local function buildCursorIds()
  cursorIds = {}
  if type(GetFileIDFromPath) ~= "function" then return end
  for file, kind in pairs(CURSOR_FILES) do
    for _, blocked in ipairs({ false, true }) do
      local path = "Interface\\Cursor\\" .. (blocked and "Unable" or "") .. file
      local id = read(GetFileIDFromPath, path)
      if type(id) == "number" then cursorIds[id] = { kind, blocked, file } end
    end
  end
end

local function kindFromName(name)
  if type(name) ~= "string" then return nil, false end
  name = name:lower()
  local blocked = name:find(BLOCKED_MARK, 1, true) ~= nil
  for _, word in ipairs(CURSOR_WORDS) do
    if name:find(word[1], 1, true) then return word[2], blocked end
  end
  for file, kind in pairs(CURSOR_FILES) do
    if name:find(file:lower(), 1, true) then return kind, blocked end
  end
  return OTHER, blocked
end

-- Art laut Zeiger und ob er ausgegraut ist; nil = kein Zeiger lesbar
local function readCursor(unit)
  if not probe then
    probe = UIParent:CreateTexture(nil, "BACKGROUND")
    probe:Hide()
  end
  if read(SetUnitCursorTexture, probe, unit, nil, true) ~= true then return nil, false end
  local texture = read(probe.GetTexture, probe)
  if not cursorIds then buildCursorIds() end
  local known = type(texture) == "number" and cursorIds[texture]
  if known then return known[1], known[2] end
  if type(texture) == "string" then return kindFromName(texture) end
  return kindFromName(read(probe.GetAtlas, probe))
end

-- Für die Fehlersuche: Art und ausgegraut laut Zeiger, dazu die rohe Textur (Datei-ID oder Pfad) und der Atlas
function LootTarget.ReadCursor(unit)
  local kind, blocked = readCursor(unit)
  return kind, blocked, probe and read(probe.GetTexture, probe), probe and read(probe.GetAtlas, probe)
end

---------------------------------------------------------------------------
-- Behälter-Lernen & Schlüsselwörter
---------------------------------------------------------------------------
function LootTarget.IsChestName(name)
  if type(name) ~= "string" then return false end
  name = name:lower()
  for _, kw in ipairs(CHEST_KEYWORDS) do
    if name:find(kw, 1, true) then return true end
  end
  return false
end

function LootTarget.ObjectIdFromGUID(guid)
  if type(guid) ~= "string" then return nil end
  local id = guid:match("^GameObject%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
  return id and tonumber(id) or nil
end

local function getContainersDB()
  if type(LevelTimerStatsDB) ~= "table" then
    if LevelTimerStatsDB == nil then LevelTimerStatsDB = {} end
    if type(LevelTimerStatsDB) ~= "table" then return nil end
  end
  LevelTimerStatsDB.containers = LevelTimerStatsDB.containers or {}
  return LevelTimerStatsDB.containers
end

function LootTarget.LearnContainerFromGUID(guid)
  local id = LootTarget.ObjectIdFromGUID(guid)
  if id then
    local db = getContainersDB()
    if db then db[id] = true end
    return id
  end
  return nil
end

local function isLearnedContainer(id)
  if not id then return false end
  local db = LevelTimerStatsDB and LevelTimerStatsDB.containers
  return type(db) == "table" and db[id] == true
end

local function onLootOpenedOrReady()
  if type(GetLootSourceInfo) ~= "function" then return end
  local count = (type(GetNumLootItems) == "function" and GetNumLootItems()) or 0
  for slot = 1, count do
    local guid = GetLootSourceInfo(slot)
    if type(guid) == "string" then
      LootTarget.LearnContainerFromGUID(guid)
    end
  end
end

ns.RegisterEvent("LOOT_OPENED", onLootOpenedOrReady)
ns.RegisterEvent("LOOT_READY", onLootOpenedOrReady)

---------------------------------------------------------------------------
-- Quest-Objekte
---------------------------------------------------------------------------
local objectiveTexts  -- offene Questziele, klein geschrieben ohne Zähler; nil = neu lesen
local normalize = ns.QuestLog.NormalizeObjective

local function readObjectives()
  objectiveTexts = {}
  for _, entry in ipairs(ns.QuestLog.Entries()) do
    for _, objective in ipairs(ns.QuestLog.Objectives(entry.questID)) do
      local objType = objective.kind or objective.type
      local isKill = objType and (objType == "monster" or objType == "slay")
      if not isKill and objective.finished == false and objective.name and #objective.name >= MIN_OBJECTIVE_LENGTH then
        table.insert(objectiveTexts, objective.name)
      end
    end
  end
end

-- Name steckt in einem offenen Ziel ("Säge" in "Durchnässte Säge: 0/1") oder umgekehrt ("Vorräte" in "Kiste mit Vorräten")
local function matchesObjective(name)
  if type(name) ~= "string" or #name < MIN_OBJECTIVE_LENGTH then return false end
  if not objectiveTexts then readObjectives() end
  name = normalize(name)
  for _, text in ipairs(objectiveTexts) do
    if text:find(name, 1, true) or name:find(text, 1, true) then return true end
  end
  return false
end

-- Zeile "Questziel" im Tooltip des Ziels (Retail/Forever, C_TooltipInfo)
local function hasObjectiveLine(unit)
  local lineType = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.QuestObjective
  if not lineType or not (C_TooltipInfo and C_TooltipInfo.GetUnit) then return false end
  local data = read(C_TooltipInfo.GetUnit, unit)
  for _, line in ipairs(type(data) == "table" and type(data.lines) == "table" and data.lines or {}) do
    if not ns.IsSecret(line.type) and line.type == lineType then return true end
  end
  return false
end

local function matchesTooltipQuest()
  if not (C_TooltipInfo and C_TooltipInfo.GetWorldCursor) then return false end
  local data = read(C_TooltipInfo.GetWorldCursor)
  if type(data) ~= "table" or type(data.lines) ~= "table" then return false end
  local entries = ns.QuestLog.Entries()
  if not entries or #entries == 0 then return false end
  for _, line in ipairs(data.lines) do
    local text = not ns.IsSecret(line.leftText) and line.leftText
    if type(text) == "string" and #text >= MIN_OBJECTIVE_LENGTH then
      for _, entry in ipairs(entries) do
        local title = entry.title
        if type(title) == "string" and #title >= MIN_OBJECTIVE_LENGTH then
          if text:find(title, 1, true) or title:find(text, 1, true) then
            return true
          end
        end
      end
    end
  end
  return false
end

local function isQuestObject(unit)
  if C_QuestLog and read(C_QuestLog.UnitIsRelatedToActiveQuest, unit) == true then return true end
  return hasObjectiveLine(unit) or matchesTooltipQuest() or matchesObjective(read(UnitName, unit))
end

function LootTarget.ForgetObjectives()
  objectiveTexts = nil
end

ns.RegisterEvent("QUEST_LOG_UPDATE", LootTarget.ForgetObjectives)

---------------------------------------------------------------------------
-- Berufe-Filter (Erz & Kräuter)
---------------------------------------------------------------------------
-- je Beruf: Zauber (IsPlayerSpell), Fertigkeitslinie (GetProfessionInfo, Retail/Forever) und Namensteile der
-- Fertigkeit (GetSkillLineInfo, Classic) in allen vier Sprachen
local GATHERING = {
  [LootTarget.ORE] = {
    spells = { 2575, 2576, 3564, 10248, 29354, 50310, 74517, 102161, 158754, 265837, 2656 },
    skillLine = 186, words = { "bergbau", "mining", "minage", "minería" },
  },
  [LootTarget.HERB] = { spells = { 2366, 2383 }, skillLine = 182, words = { "kräuter", "herb" } },
  [LootTarget.SKIN] = {
    spells = { 8613, 8617, 8618, 10768 }, skillLine = 393, words = { "kürschner", "skinning", "dépeçage", "desuello" },
  },
}

local function hasWord(name, words)
  if type(name) ~= "string" then return false end
  name = name:lower()
  for _, word in ipairs(words) do
    if name:find(word, 1, true) then return true end
  end
  return false
end

function LootTarget.IsGatheringTrained(kind)
  local gathering = GATHERING[kind]
  if not gathering then return false end
  if type(IsPlayerSpell) == "function" then
    for _, id in ipairs(gathering.spells) do
      if IsPlayerSpell(id) == true then return true end
    end
  end
  if type(GetProfessions) == "function" and type(GetProfessionInfo) == "function" then
    local prof1, prof2 = GetProfessions()
    for _, prof in ipairs({ prof1, prof2 }) do
      if prof then
        local name, _, _, _, _, _, skillLine = GetProfessionInfo(prof)
        if skillLine == gathering.skillLine or hasWord(name, gathering.words) then return true end
      end
    end
  end
  if type(GetNumSkillLines) == "function" and type(GetSkillLineInfo) == "function" then
    for i = 1, GetNumSkillLines() do
      if hasWord(GetSkillLineInfo(i), gathering.words) then return true end
    end
  end
  return false
end

---------------------------------------------------------------------------
-- Einordnung
---------------------------------------------------------------------------

-- Leiche mit Beute, die dieser Charakter nehmen darf (UnitIsCorpse ist für tote Gegner false)
local function isCorpseWithLoot(unit)
  if read(UnitIsDead, unit) ~= true or type(CanLootUnit) ~= "function" then return false end
  local guid = read(UnitGUID, unit)
  if not guid then return false end
  local ok, hasLoot, canLoot = pcall(CanLootUnit, guid)
  if not ok or ns.IsSecret(hasLoot) or ns.IsSecret(canLoot) then return false end
  return hasLoot == true and canLoot ~= false
end

-- Tooltip-Zeile toter Gegner -> Beruf, der sie nutzt (Ingenieurskunst, UNIT_SKINNABLE_BOLTS, bleibt außen vor)
local GATHER_LINES = {
  UNIT_SKINNABLE_LEATHER = LootTarget.SKIN, UNIT_SKINNABLE_ROCK = LootTarget.ORE, UNIT_SKINNABLE_HERB = LootTarget.HERB,
}
local SCAN_TOOLTIP = ns.GlobalName("LootScanTooltip")
local scanner

-- Linke Tooltip-Zeilen der Einheit (geheime übersprungen)
local function tooltipTexts(unit)
  local texts = {}
  if C_TooltipInfo and C_TooltipInfo.GetUnit then
    local data = read(C_TooltipInfo.GetUnit, unit)
    for _, line in ipairs(type(data) == "table" and type(data.lines) == "table" and data.lines or {}) do
      if not ns.IsSecret(line.leftText) then table.insert(texts, line.leftText) end
    end
    return texts
  end
  if not scanner then
    scanner = CreateFrame("GameTooltip", SCAN_TOOLTIP, UIParent, "GameTooltipTemplate")
  end
  scanner:SetOwner(UIParent, "ANCHOR_NONE")
  scanner:SetUnit(unit)
  for index = 2, read(scanner.NumLines, scanner) or 0 do  -- Zeile 1 ist der Name
    local fontString = _G[SCAN_TOOLTIP .. "TextLeft" .. index]
    local text = fontString and read(fontString.GetText, fontString)
    if text then table.insert(texts, text) end
  end
  scanner:Hide()
  return texts
end
LootTarget.TooltipTexts = tooltipTexts

-- Leiche, die der Spieler häuten, abbauen oder sammeln kann (auch leergeplündert); Beruf muss erlernt sein
local function isGatherableCorpse(unit)
  if read(UnitIsDead, unit) ~= true then return false end
  for _, text in ipairs(tooltipTexts(unit)) do
    for global, kind in pairs(GATHER_LINES) do
      if text == _G[global] then return LootTarget.IsGatheringTrained(kind) end
    end
  end
  return false
end

-- Art (ORE, HERB, QUEST, CHEST, BOBBER, CORPSE) und ob das Spiel die Interaktion gerade verweigert; nil = nichts zum Glitzern
function LootTarget.Classify(unit)
  if read(UnitIsGameObject, unit) == true then
    local kind, blocked = readCursor(unit)
    if kind == SKIP then return nil, false end

    local guid = read(UnitGUID, unit)
    local objId = LootTarget.ObjectIdFromGUID(guid)
    if objId == 35591 or kind == LootTarget.BOBBER then
      return LootTarget.BOBBER, blocked
    end

    if kind == LootTarget.ORE or kind == LootTarget.HERB then
      return kind, blocked
    end

    if kind == LootTarget.QUEST or isQuestObject(unit) then
      return LootTarget.QUEST, blocked
    end

    if kind == LootTarget.CHEST then
      return LootTarget.CHEST, blocked
    end

    if (objId and isLearnedContainer(objId)) or LootTarget.IsChestName(read(UnitName, unit)) then
      return LootTarget.CHEST, blocked
    end

    return nil, blocked
  end
  if isCorpseWithLoot(unit) or isGatherableCorpse(unit) then return LootTarget.CORPSE, false end
  return nil, false
end

-- READY = erreichbar, FAR = zu weit (oder unbekannt bei ausgegrautem Zeiger), LOCKED = in Reichweite, aber gesperrt
function LootTarget.State(unit, blocked)
  local inRange = read(UnitIsInInteractRange, unit)
  if inRange == false then return LootTarget.FAR end
  if blocked then return inRange == true and LootTarget.LOCKED or LootTarget.FAR end
  return LootTarget.READY
end

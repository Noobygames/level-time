-- Was ist das Interaktionsziel des Soft-Targetings ("softinteract") und kann der Spieler es gerade benutzen?
-- Grundlage für die Beute-Glitzer (LootSparkles.lua). Quellen (wow-ui-source, Zweige forever/live/classic_era):
--   UnitIsGameObject(unit)         Welt-Objekt (Erz, Kraut, Kiste); UnitExists ist für Objekte false
--   SetUnitCursorTexture(tex, unit) setzt das Mauszeiger-Symbol des Ziels auf eine Textur (so macht es auch
--                                  Blizzards Namensplakette, NamePlateDriverMixin:UpdateSoftTargetIconInternal);
--                                  die Textur liefert danach eine Datei-ID, einen Pfad oder einen Atlas-Namen
--   UnitIsInInteractRange(unit)    nur WoW Forever (UnitDocumentation); fehlt = Entfernung unbekannt
--   CanLootUnit(guid)              hasLoot, canLoot; alle Clients (warcraft.wiki.gg API_CanLootUnit)
-- Alle Werte können geheim sein oder fehlen; das zählt als "unbekannt" und führt nie zu einem Glitzern.
local _, ns = ...

local LootTarget = {}
ns.LootTarget = LootTarget

LootTarget.UNIT = "softinteract"
LootTarget.ORE, LootTarget.HERB, LootTarget.QUEST, LootTarget.CORPSE = "ore", "herb", "quest", "corpse"
LootTarget.READY, LootTarget.FAR, LootTarget.LOCKED = "ready", "far", "locked"

local OTHER = "other"
local BLOCKED_MARK = "unable"  -- ausgegraute Zeiger heißen "Unable..." (z.B. Fertigkeit zu niedrig)
local MIN_OBJECTIVE_LENGTH = 4  -- kürzere Namen und Ziele passen zu leicht zufällig

-- Zeiger-Dateien unter Interface\Cursor; jeweils auch mit "Unable" davor
local CURSOR_FILES = {
  Mine = LootTarget.ORE, GatherHerbs = LootTarget.HERB,
  Quest = LootTarget.QUEST, QuestRepeatable = LootTarget.QUEST, QuestTurnIn = LootTarget.QUEST,
}
-- Stichwörter im Pfad oder Atlas-Namen, in dieser Reihenfolge geprüft
local CURSOR_WORDS = {
  { "gatherherbs", LootTarget.HERB },
  { "herb", LootTarget.HERB },
  { "mine", LootTarget.ORE },
  { "quest", LootTarget.QUEST },
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
local cursorIds   -- Datei-ID -> { Art, ausgegraut }

local function buildCursorIds()
  cursorIds = {}
  if type(GetFileIDFromPath) ~= "function" then return end
  for file, kind in pairs(CURSOR_FILES) do
    for _, blocked in ipairs({ false, true }) do
      local path = "Interface\\Cursor\\" .. (blocked and "Unable" or "") .. file
      local id = read(GetFileIDFromPath, path)
      if type(id) == "number" then cursorIds[id] = { kind, blocked } end
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
  return OTHER, blocked
end

-- Art laut Zeiger (ore, herb, quest, other) und ob er ausgegraut ist; nil = kein Zeiger lesbar
local function readCursor(unit)
  if not probe then
    probe = UIParent:CreateTexture(nil, "BACKGROUND")
    probe:Hide()
  end
  if read(SetUnitCursorTexture, probe, unit) ~= true then return nil, false end
  local texture = read(probe.GetTexture, probe)
  if not cursorIds then buildCursorIds() end
  local known = type(texture) == "number" and cursorIds[texture]
  if known then return known[1], known[2] end
  if type(texture) == "string" then return kindFromName(texture) end
  return kindFromName(read(probe.GetAtlas, probe))
end

---------------------------------------------------------------------------
-- Quest-Objekte
---------------------------------------------------------------------------
local objectiveTexts  -- offene Questziele, klein geschrieben ohne Zähler; nil = neu lesen
local normalize = ns.QuestLog.NormalizeObjective

local function readObjectives()
  objectiveTexts = {}
  for _, entry in ipairs(ns.QuestLog.Entries()) do
    for _, objective in ipairs(ns.QuestLog.Objectives(entry.questID)) do
      if objective.finished == false and #objective.name >= MIN_OBJECTIVE_LENGTH then
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

local function isQuestObject(unit)
  if C_QuestLog and read(C_QuestLog.UnitIsRelatedToActiveQuest, unit) == true then return true end
  return hasObjectiveLine(unit) or matchesObjective(read(UnitName, unit))
end

function LootTarget.ForgetObjectives()
  objectiveTexts = nil
end

ns.RegisterEvent("QUEST_LOG_UPDATE", LootTarget.ForgetObjectives)

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

-- Art (ORE, HERB, QUEST, CORPSE) und ob das Spiel die Interaktion gerade verweigert; nil = nichts zum Glitzern
function LootTarget.Classify(unit)
  if read(UnitIsGameObject, unit) == true then
    local kind, blocked = readCursor(unit)
    if kind ~= LootTarget.ORE and kind ~= LootTarget.HERB then
      kind = (kind == LootTarget.QUEST or isQuestObject(unit)) and LootTarget.QUEST or nil
    end
    return kind, blocked
  end
  if isCorpseWithLoot(unit) then return LootTarget.CORPSE, false end
  return nil, false
end

-- READY = erreichbar, FAR = zu weit (oder unbekannt bei ausgegrautem Zeiger), LOCKED = in Reichweite, aber gesperrt
function LootTarget.State(unit, blocked)
  local inRange = read(UnitIsInInteractRange, unit)
  if inRange == false then return LootTarget.FAR end
  if blocked then return inRange == true and LootTarget.LOCKED or LootTarget.FAR end
  return LootTarget.READY
end

-- /lt debug check (vor einem Erz, Kraut oder einer Leiche stehen): was der Client über das Ziel verrät, roh
-- (Datei-ID, Pfad oder Atlas des Zeigers sind nicht dokumentiert) und eingeordnet; dazu die beteiligten CVars
ns.DebugLog.AddCheck("lootSparkles.target", function()
  local unit = LootTarget.UNIT
  local info = { available = LootTarget.IsAvailable(), cvars = {} }
  for _, name in ipairs({ "SoftTargetInteract", "SoftTargetIconGameObject", "SoftTargetInteractRange",
    "SoftTargetInteractArc", "SoftTargetInteractOnlyInRange", "SoftTargetNameplateInteract",
    "outlineModeShowLootEffectWhenDisabled", "graphicsOutlineMode" }) do
    info.cvars[name] = ns.CVars.Get(name) or "<missing>"
  end
  if not info.available then return info end
  info.exists, info.isObject, info.name = read(UnitExists, unit), read(UnitIsGameObject, unit), read(UnitName, unit)
  info.dead, info.inRange = read(UnitIsDead, unit), read(UnitIsInInteractRange, unit)
  info.related = C_QuestLog and read(C_QuestLog.UnitIsRelatedToActiveQuest, unit)
  info.cursorKind = readCursor(unit)
  info.cursorTexture, info.cursorAtlas = read(probe.GetTexture, probe), read(probe.GetAtlas, probe)
  info.kind, info.blocked = LootTarget.Classify(unit)
  info.plate = read(C_NamePlate.GetNamePlateForUnit, unit) ~= nil
  return info
end)

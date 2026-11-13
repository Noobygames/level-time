-- Würfeln um Beute (Roadmap 364): wer hat bei welchem Gegenstand Bedarf, Gier, Entzaubern, Transmog oder Passen
-- gewählt, wer fehlt noch, wer gewinnt mit welchem Wurf. Nur Daten; Anzeige in UI/LootRollDisplay.lua, Chatzeile
-- und Journal in Assist/LootRollReport.lua.
--
-- Quellen (Blizzard-Code und Doku je Zweig geprüft, Gethe/wow-ui-source):
--   Start/Ende  START_LOOT_ROLL(rollID, rollTime in ms), CANCEL_LOOT_ROLL(rollID) kommt, sobald die Wahl für den
--               Spieler vorbei ist (eigene Wahl oder Zeit um; danach würfeln die anderen weiter),
--               CANCEL_ALL_LOOT_ROLLS (Retail/Forever). GetLootRollItemLink/GetLootRollItemInfo(rollID),
--               GetActiveLootRollIDs() in allen Clients.
--   Classic     Era/TBC: altes C_LootHistory (Blizzard_FrameXML/Classic/LootHistory.lua): GetNumItems, GetItem(i) ->
--               rollID, itemLink, numPlayers, isDone, winnerIdx; GetPlayerInfo(i, p) -> name, class, rollType, roll,
--               isWinner; rollType 0 Passen, 1 Bedarf, 2 Gier, 3 Entzaubern, nil = noch keine Wahl. Events
--               LOOT_HISTORY_ROLL_CHANGED(itemIdx, playerIdx), LOOT_HISTORY_ROLL_COMPLETE, LOOT_HISTORY_FULL_UPDATE.
--   Retail      und WoW Forever: neues C_LootHistory (LootHistoryDocumentation): GetSortedInfoForDrop(encounterID,
--               lootListID) -> { itemHyperlink, rollInfos = { playerName, playerClass, state, roll, isWinner },
--               winner, allPassed }; state 0/1 Bedarf, 2 Transmog, 3 Gier, 4 keine Wahl, 5 Passen. Events
--               LOOT_HISTORY_UPDATE_DROP(encounterID, lootListID), LOOT_HISTORY_UPDATE_ENCOUNTER(encounterID).
--               Dass das auch für Würfe außerhalb von Bossbegegnungen (Trash) gilt, ist nicht dokumentiert.
--   Chat        immer als Ersatz: CHAT_MSG_LOOT mit den lokalisierten LOOT_ROLL_*-Formaten (GlobalStrings je Client,
--               Ketho/BlizzardInterfaceResources). Classic und Forever beginnen mit "|HlootHistory:%d|h[Beute]|h: ",
--               Retail teils ohne. Die Zahl im Link gehört zu einem Wurf; Zeilen mit bekannter Zahl landen bei
--               diesem Wurf, sonst beim ältesten offenen Wurf mit diesem Gegenstand, der die Wahl dieses Spielers
--               noch nicht hat (gleiche Gegenstände mehrfach). Geheime Zeilen (Forever, Instanzen) fallen weg.
-- Liefert die Historie Daten zu einem Wurf, ersetzt sie dessen Stand ganz (Chatzeilen zählen dann nicht mehr dazu),
-- damit nichts doppelt zählt. Die Events sind nur angemeldet, solange eine der Einstellungen an ist (Event-Gruppe).
local _, ns = ...

-- Einstellungen (LootRolls.lua, LootRollDisplay.lua, LootRollReport.lua, RollLog.lua): Zähler am Würfelfenster, Namen im
-- Tooltip, Chatzeile mit Ergebnis, Ergebnis im Beute-Journal (alle aus) und Wurf-Historie (an)
ns.Database.RegisterDefaults({
  settings = { lootRollCounts = false, lootRollNames = false, lootRollSummary = false, lootRollJournal = false,
    lootRollHistory = true },
})
local ChatPatterns = ns.ChatPatterns

local LootRolls = {}
ns.LootRolls = LootRolls

LootRolls.NEED = "need"
LootRolls.GREED = "greed"
LootRolls.DISENCHANT = "disenchant"
LootRolls.TRANSMOG = "transmog"
LootRolls.PASS = "pass"
LootRolls.WAITING = "waiting"
-- Anzeige-Reihenfolge der Wahlen
LootRolls.KINDS = { LootRolls.NEED, LootRolls.GREED, LootRolls.DISENCHANT, LootRolls.TRANSMOG, LootRolls.PASS }

-- Blizzards Symbole der Würfel-Knöpfe (Dateien in allen Clients, z.B. LootHistory.lua, AlertFrameSystems.lua);
-- Transmog gibt es nur als Atlas (Retail/Forever, LootHistory.lua Mainline)
LootRolls.ICONS = {
  need = "Interface\\Buttons\\UI-GroupLoot-Dice-Up",
  greed = "Interface\\Buttons\\UI-GroupLoot-Coin-Up",
  disenchant = "Interface\\Buttons\\UI-GroupLoot-DE-Up",
  pass = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
  waiting = "Interface\\Common\\mini-hourglass",  -- Sanduhr (Minimap Classic, InstanceDifficulty Mainline)
}
LootRolls.ATLASES = { transmog = "lootroll-icon-transmog" }

local LINGER_SECONDS = 60        -- so lange nach Ablauf der Würfelzeit wartet ein Wurf noch auf die Gewinnerzeile
local DEFAULT_ROLL_SECONDS = 60
local MS_PER_SECOND = 1000
local MAX_PARTY_UNITS = 4
local MAX_RAID_UNITS = 40

-- Altes C_LootHistory: rollType -> Wahl (LOOT_ROLL_TYPE_* in Blizzard_FrameXMLBase/Constants.lua)
local LEGACY_KINDS = { [0] = LootRolls.PASS, [1] = LootRolls.NEED, [2] = LootRolls.GREED, [3] = LootRolls.DISENCHANT }
-- Neues C_LootHistory: Enum.EncounterLootDropRollState -> Wahl; NoRoll (4) = wartet noch
local DROP_KINDS = { [0] = LootRolls.NEED, [1] = LootRolls.NEED, [2] = LootRolls.TRANSMOG, [3] = LootRolls.GREED,
  [5] = LootRolls.PASS }
local DROP_NO_ROLL = 4

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function api(namespace, name)
  return namespace and type(namespace[name]) == "function" and namespace[name] or nil
end

local legacyHistory = api(C_LootHistory, "GetItem") and api(C_LootHistory, "GetPlayerInfo") and C_LootHistory or nil
local dropHistory = api(C_LootHistory, "GetSortedInfoForDrop") and C_LootHistory or nil

---------------------------------------------------------------------------
-- Gegenstände vergleichen: Item-String aus dem Link, notfalls Item-ID oder Name
---------------------------------------------------------------------------
local function itemString(link)
  return type(link) == "string" and link:match("|H(item:[^|]+)|h") or nil
end

local function itemId(link)
  return type(link) == "string" and tonumber((link:match("item:(%d+)"))) or nil
end

local function itemName(link)
  return type(link) == "string" and link:match("%[(.-)%]") or nil
end

-- Passt der Gegenstand (Link aus Chat oder Historie) zum Wurf? 2 = gleicher Item-String, 1 = gleiche ID/Name
local function itemMatch(roll, link)
  local text = itemString(link)
  if text and roll.itemString == text then return 2 end
  local id = itemId(link)
  if id and roll.itemId == id then return 1 end
  local name = itemName(link)
  if not id and name and roll.name == name then return 1 end
  return 0
end

---------------------------------------------------------------------------
-- Spieler: Namen ohne eigenen Realm, Klasse aus der Gruppe
---------------------------------------------------------------------------
local function ownRealm()
  local realm = GetNormalizedRealmName and readable(GetNormalizedRealmName())
  if type(realm) == "string" and realm ~= "" then return realm end
  realm = readable(GetRealmName and GetRealmName())
  return type(realm) == "string" and realm:gsub("%s", "") or nil
end

function LootRolls.ShortName(name)
  if type(name) ~= "string" then return nil end
  local base, realm = name:match("^(.-)%-(.+)$")
  if base and realm == ownRealm() then return base end
  return name
end

local function playerName()
  return readable(UnitName("player"))
end

-- Einheiten der Gruppe samt Spieler (Schlachtzug raid1..n, sonst player und party1..n)
local function groupUnits()
  local units = {}
  local count = readable(GetNumGroupMembers and GetNumGroupMembers()) or 0
  if readable(IsInRaid and IsInRaid()) then
    for index = 1, math.min(count, MAX_RAID_UNITS) do units[#units + 1] = "raid" .. index end
  else
    units[1] = "player"
    for index = 1, math.min(math.max(count - 1, 0), MAX_PARTY_UNITS) do units[#units + 1] = "party" .. index end
  end
  return units
end

local function unitFullName(unit)
  local name, realm = ns.Client.UnitNameAndRealm(unit)
  name, realm = readable(name), readable(realm)
  if type(name) ~= "string" then return nil end
  if type(realm) == "string" and realm ~= "" then return LootRolls.ShortName(name .. "-" .. realm) end
  return name
end

-- Namen der Gruppenmitglieder (für "wartet noch" ohne Historie); nur auf Abruf (Tooltip)
function LootRolls.GroupNames()
  local names = {}
  for _, unit in ipairs(groupUnits()) do
    local name = unitFullName(unit)
    if name then names[#names + 1] = name end
  end
  return names
end

local function classOfMember(name)
  for _, unit in ipairs(groupUnits()) do
    if unitFullName(unit) == name then
      local _, classToken = UnitClass(unit)
      return readable(classToken)
    end
  end
end

---------------------------------------------------------------------------
-- Würfe: rolls in Startreihenfolge, byId je rollID
-- Wurf = { id, link, itemString, itemId, name, quality, texture, startedAt, seconds, groupSize,
--          choices = { [Name] = Wahl }, order = { Namen in Reihenfolge der Wahl }, rolls = { [Name] = Zahl },
--          classes = { [Name] = Klasse }, eligible (Historie), waitingNames (Historie), historyId (Chat-Link),
--          fromHistory, closed (keine Wahl mehr für den Spieler), completed, winner, winnerRoll, allPassed }
---------------------------------------------------------------------------
local rolls, byId = {}, {}
local changeListeners, completeListeners = {}, {}

function LootRolls.OnChange(listener)
  ns.RememberSource(listener, "LootRolls.lua")
  table.insert(changeListeners, listener)
end

function LootRolls.OnComplete(listener)
  ns.RememberSource(listener, "LootRolls.lua")
  table.insert(completeListeners, listener)
end

local function changed(roll)
  for _, listener in ipairs(changeListeners) do ns.SafeCall(listener, roll) end
end

function LootRolls.Get(rollID)
  return byId[rollID]
end

-- Alle bekannten Würfe in Startreihenfolge (nicht verändern)
function LootRolls.All()
  return rolls
end

local function remove(roll)
  byId[roll.id] = nil
  for index = #rolls, 1, -1 do
    if rolls[index] == roll then table.remove(rolls, index) end
  end
end

-- Würfe ohne Gewinnerzeile weit nach Ablauf der Würfelzeit vergessen
local function prune()
  local now = GetTime()
  for index = #rolls, 1, -1 do
    local roll = rolls[index]
    if now - roll.startedAt > roll.seconds + LINGER_SECONDS then
      ns.Debug("lootroll", "roll %s (%s) expired without result", roll.id, roll.link)
      byId[roll.id] = nil
      table.remove(rolls, index)
    end
  end
end

local function newRoll(rollID, link, seconds)
  local roll = { id = rollID, startedAt = GetTime(), seconds = seconds or DEFAULT_ROLL_SECONDS,
    choices = {}, order = {}, rolls = {}, classes = {},
    groupSize = readable(GetNumGroupMembers and GetNumGroupMembers()) or 0 }
  local texture, name, _, quality = GetLootRollItemInfo(rollID)
  roll.texture, roll.quality = readable(texture), readable(quality)
  link = link or readable(GetLootRollItemLink and GetLootRollItemLink(rollID))
  roll.link = type(link) == "string" and link or nil
  roll.itemString, roll.itemId = itemString(roll.link), itemId(roll.link)
  roll.name = itemName(roll.link) or readable(name)
  table.insert(rolls, roll)
  byId[rollID] = roll
  return roll
end

function LootRolls.Start(rollID, rollTime)
  rollID = readable(rollID)
  if type(rollID) ~= "number" or byId[rollID] then return byId[rollID] end
  prune()
  rollTime = readable(rollTime)
  local seconds = type(rollTime) == "number" and rollTime / MS_PER_SECOND or nil
  local roll = newRoll(rollID, nil, seconds)
  ns.Debug("lootroll", "start %s: %s, %s s, group %s", rollID, roll.link, roll.seconds, roll.groupSize)
  changed(roll)
  return roll
end

local function close(roll)
  if roll.closed then return end
  roll.closed = true
  ns.Debug("lootroll", "closed %s (%s)", roll.id, roll.link)
  changed(roll)
end

function LootRolls.Close(rollID)
  local roll = byId[readable(rollID)]
  if roll then close(roll) end
end

function LootRolls.CloseAll()
  for _, roll in ipairs(rolls) do close(roll) end
end

local function complete(roll)
  if roll.completed then return end
  roll.completed = true
  ns.Debug("lootroll", "complete %s (%s): winner %s, roll %s, all passed %s", roll.id, roll.link, roll.winner,
    roll.winnerRoll, roll.allPassed)
  remove(roll)
  changed(roll)
  for _, listener in ipairs(completeListeners) do ns.SafeCall(listener, roll) end
end

local function setChoice(roll, name, kind, class)
  if not roll.choices[name] then table.insert(roll.order, name) end
  roll.choices[name] = kind
  if class then roll.classes[name] = class end
end

---------------------------------------------------------------------------
-- Auswertung
---------------------------------------------------------------------------
-- Wie viele Spieler dürfen würfeln? Historie weiß es; sonst die Gruppengröße beim Start (best effort: im
-- Schlachtzug sind Entfernte nicht dabei), mindestens so viele, wie schon gewählt haben
local function eligibleOf(roll)
  if roll.eligible then return math.max(roll.eligible, #roll.order) end
  return math.max(roll.groupSize, #roll.order, 1)
end

-- { need = n, greed = n, disenchant = n, transmog = n, pass = n, waiting = n }
function LootRolls.Counts(roll)
  local counts = { waiting = 0 }
  for _, kind in ipairs(LootRolls.KINDS) do counts[kind] = 0 end
  for _, name in ipairs(roll.order) do
    local kind = roll.choices[name]
    counts[kind] = counts[kind] + 1
  end
  if not roll.completed then counts.waiting = math.max(eligibleOf(roll) - #roll.order, 0) end
  return counts
end

-- Namen mit dieser Wahl (oder LootRolls.WAITING) in Reihenfolge der Wahl
function LootRolls.NamesOf(roll, kind)
  local names = {}
  if kind == LootRolls.WAITING then
    if roll.completed then return names end
    for _, name in ipairs(roll.waitingNames or LootRolls.GroupNames()) do
      if not roll.choices[name] then names[#names + 1] = name end
    end
    return names
  end
  for _, name in ipairs(roll.order) do
    if roll.choices[name] == kind then names[#names + 1] = name end
  end
  return names
end

-- Name der Begegnung, bei der der Gegenstand fiel (nur Retail/Forever: C_LootHistory.GetInfoForEncounter ->
-- { encounterName, encounterID, startTime, duration }); nil auf Classic oder wenn nicht lesbar
function LootRolls.EncounterName(roll)
  local id = roll and roll.encounterID
  if not id or not C_LootHistory or not C_LootHistory.GetInfoForEncounter then return nil end
  local info = readable(C_LootHistory.GetInfoForEncounter(id))
  local name = type(info) == "table" and readable(info.encounterName) or nil
  return type(name) == "string" and name ~= "" and name or nil
end

-- Klasse eines Spielers (Klassen-Kürzel für RAID_CLASS_COLORS): aus der Historie, sonst aus der Gruppe
function LootRolls.ClassOf(roll, name)
  local class = roll and roll.classes[name]
  if class then return class end
  return classOfMember(name)
end

-- Wahl des Gewinners
function LootRolls.WinnerKind(roll)
  return roll.winner and roll.choices[roll.winner] or nil
end

---------------------------------------------------------------------------
-- Chat: Formate mit Rollen der Argumente
---------------------------------------------------------------------------
-- Rollen der %s-Argumente in Argument-Reihenfolge (enUS); %d ist der Wurf, außer direkt nach "lootHistory:" (Link-
-- Nummer). Speziellere Formate stehen vorn ("You passed" vor "%s passed", "automatically" vor "passed").
local CHOICE, ROLLED, WON, ALL_PASSED, STARTED = "choice", "rolled", "won", "allPassed", "started"
local PLAYER_ITEM, ITEM, ITEM_PLAYER = { "player", "item" }, { "item" }, { "item", "player" }
local FORMATS = {
  { "LOOT_ROLL_YOU_WON_NO_SPAM_NEED_OFF_SPEC", WON, LootRolls.NEED, ITEM, true },
  { "LOOT_ROLL_YOU_WON_NO_SPAM_NEED", WON, LootRolls.NEED, ITEM, true },
  { "LOOT_ROLL_YOU_WON_NO_SPAM_GREED", WON, LootRolls.GREED, ITEM, true },
  { "LOOT_ROLL_YOU_WON_NO_SPAM_DE", WON, LootRolls.DISENCHANT, ITEM, true },
  { "LOOT_ROLL_YOU_WON_NO_SPAM_TRANSMOG", WON, LootRolls.TRANSMOG, ITEM, true },
  { "LOOT_ROLL_WON_NO_SPAM_NEED_OFF_SPEC", WON, LootRolls.NEED, PLAYER_ITEM },
  { "LOOT_ROLL_WON_NO_SPAM_NEED", WON, LootRolls.NEED, PLAYER_ITEM },
  { "LOOT_ROLL_WON_NO_SPAM_GREED", WON, LootRolls.GREED, PLAYER_ITEM },
  { "LOOT_ROLL_WON_NO_SPAM_DE", WON, LootRolls.DISENCHANT, PLAYER_ITEM },
  { "LOOT_ROLL_WON_NO_SPAM_TRANSMOGRIFICATION", WON, LootRolls.TRANSMOG, PLAYER_ITEM },
  { "LOOT_ROLL_YOU_WON", WON, nil, ITEM, true },
  { "LOOT_ROLL_WON", WON, nil, PLAYER_ITEM },
  { "LOOT_ROLL_ALL_PASSED", ALL_PASSED, nil, ITEM },
  { "LOOT_ROLL_PASSED_SELF_AUTO", CHOICE, LootRolls.PASS, ITEM, true },
  { "LOOT_ROLL_PASSED_SELF", CHOICE, LootRolls.PASS, ITEM, true },
  { "LOOT_ROLL_NEED_SELF_OFF_SPEC", CHOICE, LootRolls.NEED, ITEM, true },
  { "LOOT_ROLL_NEED_SELF", CHOICE, LootRolls.NEED, ITEM, true },
  { "LOOT_ROLL_GREED_SELF", CHOICE, LootRolls.GREED, ITEM, true },
  { "LOOT_ROLL_DISENCHANT_SELF", CHOICE, LootRolls.DISENCHANT, ITEM, true },
  { "LOOT_ROLL_PASSED_AUTO_FEMALE", CHOICE, LootRolls.PASS, PLAYER_ITEM },
  { "LOOT_ROLL_PASSED_AUTO", CHOICE, LootRolls.PASS, PLAYER_ITEM },
  { "LOOT_ROLL_PASSED", CHOICE, LootRolls.PASS, PLAYER_ITEM },
  { "LOOT_ROLL_NEED", CHOICE, LootRolls.NEED, PLAYER_ITEM },
  { "LOOT_ROLL_GREED", CHOICE, LootRolls.GREED, PLAYER_ITEM },
  { "LOOT_ROLL_DISENCHANT", CHOICE, LootRolls.DISENCHANT, PLAYER_ITEM },
  { "LOOT_ROLL_ROLLED_NEED_ROLE_BONUS", ROLLED, LootRolls.NEED, ITEM_PLAYER },
  { "LOOT_ROLL_ROLLED_NEED", ROLLED, LootRolls.NEED, ITEM_PLAYER },
  { "LOOT_ROLL_ROLLED_GREED", ROLLED, LootRolls.GREED, ITEM_PLAYER },
  { "LOOT_ROLL_ROLLED_DE", ROLLED, LootRolls.DISENCHANT, ITEM_PLAYER },
  { "LOOT_ROLL_ROLLED_TRANSMOG", ROLLED, LootRolls.TRANSMOG, ITEM_PLAYER },
  { "LOOT_ROLL_LOST_ROLL", ROLLED, nil, { "kindText", "item" }, true },
  { "LOOT_ROLL_STARTED", STARTED, nil, ITEM },  -- passt auf jede Zeile mit Link-Nummer: zuletzt
}

LootRolls.FORMAT_NAMES = {}  -- Namen der Formate (Debug-Prüfung 364.lootRoll.api)
for index, spec in ipairs(FORMATS) do LootRolls.FORMAT_NAMES[index] = spec[1] end

local HISTORY_LINK_TAG = "lootHistory:"

-- Rolle je Argument-Nummer aus dem Format (Platzhalter wie in ChatPatterns.Compile gezählt)
function LootRolls.ArgumentRoles(format, stringRoles)
  local placeholders, start = {}, 1
  while true do
    local first, last, position, kind = format:find("%%(%d?)%$?([sd])", start)
    if not first then break end
    local before = format:sub(math.max(1, first - #HISTORY_LINK_TAG), first - 1)
    placeholders[#placeholders + 1] = { position = tonumber(position) or #placeholders + 1, kind = kind,
      historyId = before == HISTORY_LINK_TAG }
    start = last + 1
  end
  table.sort(placeholders, function(a, b) return a.position < b.position end)
  local roles, stringIndex, seenId = {}, 0, false
  for _, placeholder in ipairs(placeholders) do
    if placeholder.kind == "s" then
      stringIndex = stringIndex + 1
      roles[placeholder.position] = stringRoles[stringIndex]
    elseif placeholder.historyId then
      roles[placeholder.position] = not seenId and "historyId" or nil  -- zweiter Link ("Würfe ansehen") egal
      seenId = true
    else
      roles[placeholder.position] = "roll"
    end
  end
  return roles
end

local compiledFormats
local function compileFormats()
  compiledFormats = {}
  for _, spec in ipairs(FORMATS) do
    local format = _G[spec[1]]
    if type(format) == "string" and not ns.IsSecret(format) then
      table.insert(compiledFormats, { global = spec[1], kind = spec[2], choice = spec[3], self = spec[5],
        compiled = ChatPatterns.Compile(format), roles = LootRolls.ArgumentRoles(format, spec[4]) })
    end
  end
end

-- Chatzeile auswerten: { kind, choice, player, item, roll, historyId, global } oder nil
function LootRolls.ParseChat(message)
  if not compiledFormats then compileFormats() end
  for _, format in ipairs(compiledFormats) do
    local args = ChatPatterns.Match(message, format.compiled)
    if args then
      local line = { kind = format.kind, choice = format.choice, global = format.global }
      for position, role in pairs(format.roles) do line[role] = args[position] end
      line.roll = tonumber(line.roll)
      line.historyId = tonumber(line.historyId)
      if format.self then line.player = playerName() end
      -- "Wurf gestartet" nur, wenn der Rest wirklich nur ein Gegenstandslink ist
      if format.kind ~= STARTED or (type(line.item) == "string" and line.item:match("^|c.-|r$")) then
        return line
      end
    end
  end
  return nil
end

-- Wurf zu einer Chatzeile: Link-Nummer, sonst ältester passender Gegenstand (accept(roll) filtert weiter)
local function rollForLine(line, accept)
  if line.historyId then
    for _, roll in ipairs(rolls) do
      if roll.historyId == line.historyId then return roll end
    end
  end
  local best, bestMatch = nil, 0
  for _, roll in ipairs(rolls) do
    local match = itemMatch(roll, line.item)
    if match > bestMatch and not (line.historyId and roll.historyId) and (not accept or accept(roll)) then
      best, bestMatch = roll, match
      if match == 2 then break end
    end
  end
  if best and line.historyId then best.historyId = line.historyId end
  return best
end

local function applyChat(line)
  local player = line.player and LootRolls.ShortName(line.player)
  if line.kind == STARTED then
    rollForLine(line, function(roll) return roll.historyId == nil end)
    return
  end
  if line.kind == CHOICE then
    local roll = rollForLine(line, function(roll) return not roll.choices[player] end)
    if not roll or roll.fromHistory or not player then return end
    setChoice(roll, player, line.choice)
    changed(roll)
  elseif line.kind == ROLLED then
    local roll = rollForLine(line, function(roll)
      return roll.rolls[player] == nil and (line.choice == nil or roll.choices[player] == nil
        or roll.choices[player] == line.choice)
    end)
    if not roll or roll.fromHistory or not player then return end
    roll.rolls[player] = line.roll
    if line.choice and not roll.choices[player] then setChoice(roll, player, line.choice) end
    changed(roll)
  elseif line.kind == WON then
    local roll = rollForLine(line)
    if not roll then return end
    -- Die Gewinnerzeile gilt auch, wenn die Wahlen aus der Beute-Historie stammen: Forever liest die Historie oft,
    -- bevor sie einen Gewinner kennt (Debug-Log 2026-11-08: "winner nil" trotz LOOT_ROLL_WON), sonst stand dann
    -- "alle haben gepasst" da
    if player and not roll.winner then
      roll.winner = player
      if line.choice and not roll.choices[player] then setChoice(roll, player, line.choice) end
      roll.winnerRoll = line.roll or roll.rolls[player]
      roll.allPassed = false
    end
    complete(roll)
  elseif line.kind == ALL_PASSED then
    local roll = rollForLine(line)
    if not roll then return end
    if not roll.winner then roll.allPassed = true end
    complete(roll)
  end
end

local function onChat(message)
  if #rolls == 0 then return end  -- häufigster Fall im Schlachtzug: keine Würfe offen
  if ns.IsSecret(message) then
    ns.Debug("lootroll", "secret loot chat line skipped")
    return
  end
  local line = LootRolls.ParseChat(message)
  if not line then return end
  ns.Debug("lootroll", "chat %s: %s %s %s roll %s id %s", line.global, line.player, line.choice, line.item,
    line.roll, line.historyId)
  prune()
  applyChat(line)
end

---------------------------------------------------------------------------
-- Classic: altes C_LootHistory
---------------------------------------------------------------------------
local function readLegacyItem(itemIndex)
  local rollID, link, numPlayers, isDone, winnerIndex = legacyHistory.GetItem(itemIndex)
  rollID, link, numPlayers = readable(rollID), readable(link), readable(numPlayers)
  isDone, winnerIndex = readable(isDone), readable(winnerIndex)
  local roll = type(rollID) == "number" and byId[rollID]
  if not roll or type(numPlayers) ~= "number" then return end
  roll.fromHistory = true
  roll.choices, roll.order, roll.rolls, roll.waitingNames = {}, {}, {}, {}
  roll.eligible = numPlayers
  roll.winner, roll.winnerRoll = nil, nil
  for playerIndex = 1, numPlayers do
    local name, class, rollType, value, isWinner = legacyHistory.GetPlayerInfo(itemIndex, playerIndex)
    name, class, rollType, value = readable(name), readable(class), readable(rollType), readable(value)
    name = LootRolls.ShortName(name)
    if name then
      if class then roll.classes[name] = class end
      local kind = LEGACY_KINDS[rollType]
      if kind then setChoice(roll, name, kind, class) else table.insert(roll.waitingNames, name) end
      if type(value) == "number" then roll.rolls[name] = value end
      if readable(isWinner) or playerIndex == winnerIndex then roll.winner, roll.winnerRoll = name, value end
    end
  end
  if isDone then
    roll.allPassed = roll.winner == nil
    complete(roll)
  else
    changed(roll)
  end
end

local function readLegacyAll()
  if #rolls == 0 then return end
  local count = readable(legacyHistory.GetNumItems and legacyHistory.GetNumItems()) or 0
  for itemIndex = 1, count do readLegacyItem(itemIndex) end
end

local function onLegacyChanged(itemIndex)
  itemIndex = readable(itemIndex)
  if #rolls == 0 or type(itemIndex) ~= "number" then return end
  readLegacyItem(itemIndex)
end

---------------------------------------------------------------------------
-- Retail/Forever: neues C_LootHistory (Beute je Begegnung)
---------------------------------------------------------------------------
local function dropKey(encounterID, lootListID)
  return encounterID .. ":" .. lootListID
end

local function rollForDrop(key, link)
  for _, roll in ipairs(rolls) do
    if roll.dropKey == key then return roll end
  end
  local best, bestMatch = nil, 0
  for _, roll in ipairs(rolls) do
    local match = roll.dropKey == nil and itemMatch(roll, link) or 0
    if match > bestMatch then best, bestMatch = roll, match end
  end
  if best then best.dropKey = key end
  return best
end

local function readDrop(encounterID, lootListID)
  encounterID, lootListID = readable(encounterID), readable(lootListID)
  if #rolls == 0 or type(encounterID) ~= "number" or type(lootListID) ~= "number" then return end
  local drop = readable(dropHistory.GetSortedInfoForDrop(encounterID, lootListID))
  if type(drop) ~= "table" then return end
  local link = readable(drop.itemHyperlink)
  local roll = rollForDrop(dropKey(encounterID, lootListID), link)
  local infos = readable(drop.rollInfos)
  if not roll or type(infos) ~= "table" then return end
  roll.fromHistory = true
  roll.encounterID = encounterID
  roll.choices, roll.order, roll.rolls, roll.waitingNames = {}, {}, {}, {}
  roll.eligible = #infos
  for _, info in ipairs(infos) do
    local name = LootRolls.ShortName(readable(info.playerName))
    local state, class, value = readable(info.state), readable(info.playerClass), readable(info.roll)
    if name then
      if class then roll.classes[name] = class end
      local kind = DROP_KINDS[state]
      if kind then setChoice(roll, name, kind, class)
      elseif state == DROP_NO_ROLL then table.insert(roll.waitingNames, name) end
      if type(value) == "number" then roll.rolls[name] = value end
    end
  end
  local winner = readable(drop.winner)
  local winnerName = type(winner) == "table" and LootRolls.ShortName(readable(winner.playerName)) or nil
  if winnerName then
    roll.winner, roll.winnerRoll = winnerName, readable(winner.roll)
  elseif roll.winner then
    roll.winnerRoll = roll.winnerRoll or roll.rolls[roll.winner]
  end
  roll.allPassed = roll.winner == nil and readable(drop.allPassed) == true
  if roll.winner or roll.allPassed then complete(roll) else changed(roll) end
end

local function readEncounter(encounterID)
  encounterID = readable(encounterID)
  if #rolls == 0 or type(encounterID) ~= "number" then return end
  local drops = readable(dropHistory.GetSortedDropsForEncounter and dropHistory.GetSortedDropsForEncounter(encounterID))
  if type(drops) ~= "table" then return end
  for _, drop in ipairs(drops) do
    -- Forever nennt das Feld lootListKey (LootHistoryDocumentation forever), Retail lootListID
    local lootListID = readable(drop.lootListID) or readable(drop.lootListKey)
    if type(lootListID) == "number" then readDrop(encounterID, lootListID) end
  end
end

---------------------------------------------------------------------------
-- Anmelden, solange eine Einstellung die Daten braucht
---------------------------------------------------------------------------
local events = ns.NewEventGroup()
events.Add("START_LOOT_ROLL", nil, LootRolls.Start)
events.Add("CANCEL_LOOT_ROLL", nil, LootRolls.Close)
events.Add("CANCEL_ALL_LOOT_ROLLS", nil, LootRolls.CloseAll)
events.Add("CHAT_MSG_LOOT", nil, onChat)
if legacyHistory then
  events.Add("LOOT_HISTORY_ROLL_CHANGED", nil, onLegacyChanged)
  events.Add("LOOT_HISTORY_ROLL_COMPLETE", nil, readLegacyAll)
  events.Add("LOOT_HISTORY_FULL_UPDATE", nil, readLegacyAll)
end
if dropHistory then
  events.Add("LOOT_HISTORY_UPDATE_DROP", nil, readDrop)
  events.Add("LOOT_HISTORY_UPDATE_ENCOUNTER", nil, readEncounter)
end

function LootRolls.IsWanted(db)
  return db.lootRollCounts or db.lootRollSummary or db.lootRollJournal or db.lootRollHistory
end

function LootRolls.HistorySource()
  return legacyHistory and "legacy" or dropHistory and "drops" or "chat"
end

-- Schon laufende Würfe übernehmen (Einschalten mitten im Würfeln, /reload)
local function adoptActive()
  local ids = readable(GetActiveLootRollIDs and GetActiveLootRollIDs())
  if type(ids) ~= "table" then return end
  for _, rollID in ipairs(ids) do
    rollID = readable(rollID)
    if type(rollID) == "number" and not byId[rollID] then
      local time = readable(GetLootRollTimeLeft and GetLootRollTimeLeft(rollID))
      LootRolls.Start(rollID, type(time) == "number" and time or nil)
    end
  end
end

ns.RegisterApply(function(db)
  local wanted = LootRolls.IsWanted(db) and true or false
  if wanted == events.IsActive() then return end
  events.SetActive(wanted)
  compiledFormats = nil  -- Sprache/Formate neu lesen
  if wanted then
    adoptActive()
  else
    rolls, byId = {}, {}
  end
end)

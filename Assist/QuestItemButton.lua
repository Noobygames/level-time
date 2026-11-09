-- Quest-Item-Knopf (Roadmap 268, Einstellungen questItemButton und questTargetButton, Standard aus), wie Guidelime/RXP:
-- ein sicherer Knopf benutzt das Quest-Item der nächsten Quest, ein zweiter wählt einen Questgegner als Ziel.
-- Quellen:
--   Quest-Item  GetQuestLogSpecialItemInfo(questLogIndex) -> link, Symbol, Ladungen, showItemWhenComplete
--               (warcraft.wiki.gg: alle Clients; Blizzards ObjectiveTracker nutzt es in Retail/Forever). Benutzt wird
--               über SecureActionButtonTemplate type "item" mit "item:<ID>" (SECURE_ACTIONS.item ->
--               SecureCmdItemParse, Blizzard_FrameXML/SecureTemplates.lua in allen Zweigen); UseQuestLogSpecialItem
--               selbst ist geschützt.
--               Quests ohne solches Item: benutzbare Gegenstände aus den Taschen (QuestBagItems.lua: beim Annehmen
--               erhalten, GetContainerItemQuestInfo, Name im offenen Zieltext, gelernt). Das Quest-Item des
--               Questlogs gewinnt immer; candidate.source sagt, woher der Kandidat stammt ("special" oder die Quelle
--               aus QuestBagItems.SOURCES).
--   "Nächste"   Retail/Forever C_QuestLog.GetDistanceSqToQuest (kleinster lesbarer Abstand); Classic kennt keinen
--               Abstand: die zuletzt angenommene Quest mit Item, sonst die erste im Log.
--   Ziel        Namensplaketten, die C_QuestLog.UnitIsRelatedToActiveQuest als Questgegner meldet (wie QuestMarks.lua,
--               nur wo es das gibt) oder deren Tooltip ein offenes Questziel nennt (Lib/QuestTooltip.lua; Forever
--               meldet Gegner, von denen man nur etwas looten muss, nicht als quest-related, Debug-Log 2026-11-08:
--               Elementarsklave mit "Armschienen der Erdbindung: 0/4" im Tooltip, questRelated false), dazu gelernte Gegner offener Ziele (QuestMobs.lua, Roadmap 342; erfüllte Ziele
--               fallen heraus). Knopf type "macro": "/cleartarget", je Name "/targetexact <Name>" (sichtbare Plaketten
--               zuletzt, sie gewinnen), höchstens MAX_MACRO Zeichen. Optional (questTargetMarker) danach
--               "/tm [exists,nodead] !8": Totenkopf, ohne ihn wieder abzunehmen (Präfix "!" in SlashCommands.lua aller
--               Zweige). SetRaidTarget direkt ist in Retail/Forever für Addons gesperrt; der sichere Knopf geht überall.
--   Zone        Einstellung questButtonsZoneOnly (Standard an): Item und gelernte Zielnamen nur für Quests der
--               aktuellen Zone (QuestLog.ZoneStatus: Questkarte, Questlog-Überschrift, gelernte QuestNpcs-Orte).
--               Unbekannte Zone (Kategorie-Überschrift, fehlende Daten) zählt als "hier", damit nichts zu Unrecht
--               verschwindet. Sichtbare Questgegner auf Namensplaketten sind ohnehin in der Nähe und bleiben.
--               Ort und Entscheidungen werden zwischengespeichert und bei Zonenwechsel (ZONE_CHANGED*,
--               PLAYER_ENTERING_WORLD) bzw. Questlog-Änderung (QUEST_LOG_UPDATE) verworfen.
-- Aktualisiert wird ereignisgesteuert (Roadmap 390): Questlog, Taschen, Zone, Namensplaketten, Kampfende und
-- Einstellungen setzen Merker; der Sekundentakt arbeitet nur, wenn ein Merker steht. Die Item-Kandidaten bleiben bis
-- zur nächsten Questlog- oder Taschenänderung gespeichert (C_QuestLog.GetInfo erzeugt je Eintrag eine Tabelle).
-- Ohne Ereignis neu gewählt wird nur nach Abstand (Retail/Forever, alle DISTANCE_SECONDS, nur bei mindestens zwei
-- Kandidaten) und der Zielknopf, solange Plaketten stehen (Gegner sterben, ohne dass die Plakette verschwindet) oder
-- sich die gelernten Namen ändern; beides ohne neue Tabellen, das Makro entsteht nur bei geänderten Namen.
-- Attribute, Anzeigen und Verstecken der sicheren Knöpfe nur außerhalb des Kampfs; im Kampf wird es gemerkt und bei
-- PLAYER_REGEN_ENABLED nachgeholt. Der Halter (Position und Größe über Lib/Frames.lua, Edit-Modus) wird
-- durch die sicheren Kinder selbst geschützt und deshalb ebenfalls nur außerhalb des Kampfs angefasst.
-- Klicks: RegisterForClicks("AnyUp", "AnyDown") und useOnKeyDown = false, damit genau ein Klick beim Loslassen auslöst
-- (SecureActionButton_OnClick in allen Zweigen).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    questItemButton = false,
    questTargetButton = false,
    questTargetMarker = false,
    questButtonsZoneOnly = true,
  },
})
local L = ns.L

local QuestItem = {}
ns.QuestItem = QuestItem

local BUTTON_SIZE = 36
local GAP = 4
local TITLE_PADDING = 8   -- Luft links und rechts neben dem Titel
local LABEL_HEIGHT = 14  -- Titel "Ziele & Items" über den Knöpfen
local REFRESH_SECONDS = 1
local DISTANCE_SECONDS = 3     -- Abstand zur Quest neu vergleichen (nur mit mehreren Kandidaten)
local MAX_MACRO = 255          -- Länge eines Makros
local MARKER_LINE = "\n/tm [exists,nodead] !8"  -- 8 = Totenkopf
local DEFAULT_POS = { "CENTER", "CENTER", 0, -180 }
local MOVE_BACKGROUND = { 0, 0, 0, 0.6 }

local holder, itemButton, targetButton
local editing = false  -- Edit-Modus: Halter mit Grund und Beschriftung sichtbar
local shown = { itemId = nil, target = nil, texture = nil }  -- zuletzt gesetzte Attribute und Symbol
local pending = false                         -- im Kampf aufgeschoben
local acceptedAt = {}                         -- [questID] = GetTime() der Annahme
local here                                    -- QuestLog.Here(), bis zum nächsten Zonenwechsel
local zoneCache = {}                          -- [questID] = { inZone, signals }
local headers                                 -- [questID] = Questlog-Überschrift, bis zur nächsten Questlog-Änderung
local candidates                              -- QuestItem.Candidates(), bis zur nächsten Questlog-/Taschenänderung
local itemDirty, targetDirty = true, true     -- Item bzw. Zielknopf neu bestimmen
local nextDistanceAt = 0                      -- GetTime(), ab wann der Abstand wieder verglichen wird
local inZoneCount = 0                         -- Kandidaten der Zone bei der letzten Wahl
local shownMobNames                           -- zuletzt gelesene QuestMobs.OpenMobNames()-Liste (Identität)

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function inCombat()
  return InCombatLockdown and InCombatLockdown()
end

function QuestItem.CanTarget()
  return ns.QuestMarks.IsAvailable() and ns.QuestMarks.HasClientQuestUnits()
end

-- Quests mit benutzbarem Item, unabhängig von der Zone (QuestLeftovers braucht alle):
-- { questID, index, header, link, itemId, texture, source }; erst die Quest-Items des Questlogs, dann die aus den
-- Taschen für die übrigen Quests
function QuestItem.Candidates()
  local list, taken = {}, {}
  local entries = ns.QuestLog.Entries()
  for _, entry in ipairs(entries) do
    local link, texture
    if GetQuestLogSpecialItemInfo then link, texture = GetQuestLogSpecialItemInfo(entry.index) end
    link, texture = readable(link), readable(texture)
    local itemId = type(link) == "string" and tonumber((link:match("item:(%d+)")))
    if itemId then
      taken[entry.questID] = true
      table.insert(list, { questID = entry.questID, index = entry.index, header = entry.header, link = link,
        itemId = itemId, texture = texture, source = "special" })
    end
  end
  for _, candidate in ipairs(ns.QuestBagItems.Find(entries, taken)) do table.insert(list, candidate) end
  return list
end

local function markAll()
  itemDirty, targetDirty = true, true
end

local function forgetZones()
  here, zoneCache = nil, {}
  markAll()
end

local function forgetQuestLog()
  headers, zoneCache, candidates = nil, {}, nil
  markAll()
end

local function forgetItems()
  candidates = nil
  itemDirty = true
end

local function cachedCandidates()
  if not candidates then candidates = QuestItem.Candidates() end
  return candidates
end

function QuestItem.Here()
  if not here then here = ns.QuestLog.Here() end
  return here
end

local function headerOf(questID)
  if not headers then
    headers = {}
    for _, entry in ipairs(ns.QuestLog.Entries()) do headers[entry.questID] = entry.header or false end
  end
  return headers[questID] or nil
end

-- Karten, auf denen Ziele der Quest vorankamen (QuestNpcs, Roadmap 350)
local function learnedMaps(questID)
  local record = ns.QuestNpcs.Get(questID)
  if not (record and record.spots) then return nil end
  local maps = {}
  for _, spot in ipairs(record.spots) do
    if type(spot.mapID) == "number" then maps[#maps + 1] = spot.mapID end
  end
  return maps
end

-- Zone der Quest: true/false, nil = unbekannt; dazu die Einzelhinweise (QuestLog.ZoneStatus)
function QuestItem.ZoneOf(questID)
  local cached = zoneCache[questID]
  if not cached then
    local status, signals = ns.QuestLog.ZoneStatus(questID, headerOf(questID), QuestItem.Here(), learnedMaps(questID))
    cached = { inZone = status, signals = signals }
    zoneCache[questID] = cached
    ns.Debug("questitem", "quest %s zone %s (map %s, header %s %s, learned %s) player map %s zone %s", questID,
      status, signals.map, headerOf(questID), signals.header, signals.learned, here.mapID, here.zone)
  end
  return cached.inZone, cached.signals
end

-- Darf die Quest die Knöpfe füllen? Ohne questButtonsZoneOnly immer; unbekannte Zone zählt als hier
function QuestItem.IsInZone(questID)
  if not (ns.db and ns.db.questButtonsZoneOnly) then return true end
  return QuestItem.ZoneOf(questID) ~= false
end

local function distanceOf(questID)
  if not (C_QuestLog and C_QuestLog.GetDistanceSqToQuest) then return nil end
  local distance = readable(C_QuestLog.GetDistanceSqToQuest(questID))
  return type(distance) == "number" and distance or nil
end

-- Nächste Quest der Zone (Abstand), sonst die zuletzt angenommene, sonst die erste
function QuestItem.Pick()
  local best, bestDistance, bestAccepted
  local count = 0
  for _, candidate in ipairs(cachedCandidates()) do
    if QuestItem.IsInZone(candidate.questID) then
      count = count + 1
      local distance = distanceOf(candidate.questID)
      local accepted = acceptedAt[candidate.questID] or 0
      local better
      if not best then
        better = true
      elseif distance and bestDistance then
        better = distance < bestDistance
      elseif distance or bestDistance then
        better = distance ~= nil
      else
        better = accepted > bestAccepted
      end
      if better then best, bestDistance, bestAccepted = candidate, distance, accepted end
    end
  end
  inZoneCount = count
  return best
end

local function isLivingMob(unit)
  return UnitExists(unit) and readable(UnitIsPlayer(unit)) == false and readable(UnitIsDead(unit)) == false
end

-- Wiederverwendete Listen des Sekundentakts (keine neuen Tabellen, solange sich nichts ändert)
local plateList, nameList, seenNames, visibleSet = {}, {}, {}, {}

local function clearList(list)
  for index = #list, 1, -1 do list[index] = nil end
end

local function clearSet(set)
  for key in pairs(set) do set[key] = nil end
end

-- Nennt der Tooltip der Einheit ein offenes Questziel? (je Name zwischengespeichert, siehe QuestTooltip)
local function hasOpenTooltipObjective(unit)
  for _, entry in ipairs(ns.QuestTooltip.Objectives(unit)) do
    if not entry.done then return true end
  end
  return false
end

local function isQuestUnit(unit)
  local related = C_QuestLog.UnitIsRelatedToActiveQuest(unit)
  if not ns.IsSecret(related) and related == true then return true end
  return hasOpenTooltipObjective(unit)
end

-- Namen lebender Questgegner auf den Namensplaketten (nur wo der Client sie kennt), alphabetisch in plateList
local function plateNames()
  clearList(plateList)
  if not QuestItem.CanTarget() then return plateList end
  for unit in pairs(ns.NamePlates.Active()) do
    if isLivingMob(unit) then
      local name = readable(UnitName(unit))
      if type(name) == "string" and name ~= "" and isQuestUnit(unit) then
        plateList[#plateList + 1] = name
      end
    end
  end
  table.sort(plateList)
  return plateList
end

-- Gehört ein gelernter Gegner zu einer offenen Quest dieser Zone? Ohne bekannte Quest: ja
local function learnedHere(name)
  local hits = ns.QuestMobs.ForMob(name)
  if not hits or #hits == 0 then return true end
  for _, hit in ipairs(hits) do
    if QuestItem.IsInZone(hit.questID) then return true end
  end
  return false
end

local function addName(name)
  if not seenNames[name] then
    seenNames[name] = true
    nameList[#nameList + 1] = name
  end
end

-- Wie QuestItem.TargetNames, aber in die wiederverwendete nameList (nicht festhalten)
local function collectTargetNames()
  clearList(nameList)
  clearSet(seenNames)
  clearSet(visibleSet)
  local visible = plateNames()
  for _, name in ipairs(visible) do visibleSet[name] = true end
  shownMobNames = nil
  if ns.db.questLearning then
    shownMobNames = ns.QuestMobs.OpenMobNames()
    for _, name in ipairs(shownMobNames) do
      if not visibleSet[name] and learnedHere(name) then addName(name) end
    end
  end
  for _, name in ipairs(visible) do addName(name) end
  return nameList
end

-- Namen für den Zielknopf: gelernte Gegner offener Ziele (nur Quests der Zone), danach die sichtbaren Questgegner
-- (ohne Doppelte); eigene Liste
function QuestItem.TargetNames()
  local names = {}
  for index, name in ipairs(collectTargetNames()) do names[index] = name end
  return names
end

-- Makrotext: /cleartarget, /targetexact je Name (die letzten haben Vorrang, daher vorne gekürzt), optional Marker
function QuestItem.TargetMacro(names, marker)
  if #names == 0 then return nil end
  local tail = marker and MARKER_LINE or ""
  local lines = {}
  local length = #"/cleartarget" + #tail
  for index = #names, 1, -1 do
    local line = "\n/targetexact " .. names[index]
    if length + #line > MAX_MACRO then break end
    length = length + #line
    table.insert(lines, 1, line)
  end
  return "/cleartarget" .. table.concat(lines) .. tail, #lines
end

local function createSecureButton(name, actionType)
  local button = CreateFrame("Button", name, holder, "SecureActionButtonTemplate")
  button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
  button:RegisterForClicks("AnyUp", "AnyDown")
  button:SetAttribute("useOnKeyDown", false)
  button:SetAttribute("type", actionType)
  button.icon = button:CreateTexture(nil, "ARTWORK")
  button.icon:SetAllPoints()
  button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  button:Hide()
  return button
end

local function showTooltip(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  if self == itemButton and self.link then
    GameTooltip:SetHyperlink(self.link)
  elseif self == targetButton and shown.names then
    GameTooltip:AddLine(string.format(L.QUEST_TARGET_TIP_LINE, table.concat(shown.names, ", ")), 1, 1, 1, true)
  end
  GameTooltip:Show()
end

local function create()
  holder = CreateFrame("Frame", ns.GlobalName("QuestItemBar"), UIParent)
  holder:SetSize(BUTTON_SIZE * 2 + GAP, BUTTON_SIZE + LABEL_HEIGHT)
  holder.background = holder:CreateTexture(nil, "BACKGROUND")
  holder.background:SetAllPoints()
  holder.background:SetColorTexture(unpack(MOVE_BACKGROUND))
  holder.label = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  holder.label:SetPoint("TOP", 0, -1)

  itemButton = createSecureButton(ns.GlobalName("QuestItemButton"), "item")
  itemButton:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
  itemButton.count = itemButton:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  itemButton.count:SetPoint("BOTTOMRIGHT", -2, 2)
  targetButton = createSecureButton(ns.GlobalName("QuestTargetButton"), "macro")
  targetButton:SetPoint("LEFT", itemButton, "RIGHT", GAP, 0)
  targetButton.icon:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
  for _, button in ipairs({ itemButton, targetButton }) do
    button:SetScript("OnEnter", showTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  end

  ns.Frames.Register({
    id = "questItem", frame = holder, label = "EDIT_FRAME_QUEST_ITEM", default = DEFAULT_POS, protected = true,
    settingsPage = "COMFORT_PAGE_QUEST_DISPLAY",
    -- Rahmen mit Titel immer sichtbar; am Titel/Rand ziehbar, solange "Anzeigen fixieren" aus ist (nie im Kampf:
    -- protected, die sicheren Knöpfe hängen am Halter)
    clickable = true, dragWhenUnlocked = true, actionsTip = true,
    preview = function(on)
      if inCombat() then return end
      editing = on
      QuestItem.Refresh()
    end,
    hide = function()
      ns.SetBatch(function(db) db.questItemButton, db.questTargetButton = false, false end)
    end,
  })
  holder:Hide()
end

local function itemCount(itemId)
  local count = C_Item and C_Item.GetItemCount and C_Item.GetItemCount(itemId)
  count = readable(count)
  return type(count) == "number" and count or 0
end

local function setItem(candidate)
  local itemId = candidate and candidate.itemId
  if itemId then
    if itemId ~= shown.itemId then itemButton:SetAttribute("item", "item:" .. itemId) end
    itemButton.link = candidate.link
    if candidate.texture ~= shown.texture then
      shown.texture = candidate.texture
      itemButton.icon:SetTexture(candidate.texture)
    end
    local count = itemCount(itemId)
    ns.Widgets.SetTextIfChanged(itemButton.count, count > 1 and tostring(count) or "")
    itemButton:Show()
  else
    itemButton.link = nil
    itemButton:Hide()
  end
  shown.itemId = itemId
end

local NO_NAMES = {}
local builtNames, builtMarker = {}, nil  -- Namen und Marker, aus denen das gezeigte Makro entstand

-- Gleiche Namen und gleicher Marker wie beim letzten Makro? (Vergleich ohne neue Tabellen)
local function sameNames(names, marker)
  if marker ~= builtMarker or #names ~= #builtNames then return false end
  for index = 1, #names do
    if names[index] ~= builtNames[index] then return false end
  end
  return true
end

local function setTarget(names)
  names = names or NO_NAMES
  local marker = ns.db and ns.db.questTargetMarker or false
  if sameNames(names, marker) then return end
  clearList(builtNames)
  for index = 1, #names do builtNames[index] = names[index] end
  builtMarker = marker
  local macro, count = QuestItem.TargetMacro(names, marker)
  if macro then
    if macro ~= shown.target then targetButton:SetAttribute("macrotext", macro) end
    targetButton:Show()
  else
    targetButton:Hide()
  end
  shown.target = macro
  shown.names = macro and { unpack(names, #names - count + 1) } or nil
end

-- Stand neu bestimmen; nur außerhalb des Kampfs (sichere Knöpfe)
function QuestItem.Refresh()
  if not holder then return end
  if inCombat() then
    if not pending then ns.Debug("questitem", "in combat, update waits") end
    pending = true
    return
  end
  pending = false
  local db = ns.db
  local itemBefore, targetBefore = shown.itemId, shown.target
  itemDirty, targetDirty = false, false
  nextDistanceAt = GetTime() + DISTANCE_SECONDS
  setItem(db and db.questItemButton and QuestItem.Pick() or nil)
  setTarget(db and db.questTargetButton and collectTargetNames() or nil)
  if shown.itemId ~= itemBefore or shown.target ~= targetBefore then
    ns.Debug("questitem", "item %s (link %s), target %s", shown.itemId, itemButton.link, shown.target)
  end
  holder:SetShown(editing or shown.itemId ~= nil or shown.target ~= nil)
end

create()

ns.RegisterEvent("QUEST_ACCEPTED", function(...)
  local questID = readable((select(select("#", ...), ...)))  -- Era: questIndex, questID; Retail/Forever: questID
  if type(questID) == "number" then acceptedAt[questID] = GetTime() end
  forgetQuestLog()
end)
-- Einstellungen anwenden: Text, Position (Profilwechsel) und Knöpfe; im Kampf aufgeschoben
local function apply()
  markAll()
  if inCombat() then
    pending = true
    return
  end
  holder.label:SetText(L.QUEST_ITEM_MOVE_LABEL)
  -- Titel in jeder Sprache ganz im Rahmen (fr/es länger als die zwei Knöpfe)
  holder:SetWidth(math.max(BUTTON_SIZE * 2 + GAP, math.ceil(holder.label:GetStringWidth() or 0) + TITLE_PADDING))
  QuestItem.Refresh()
end

ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if pending then apply() end
end)

local function buttonsWanted()
  return ns.db and (ns.db.questItemButton or ns.db.questTargetButton)
end

-- Zonenwechsel: Ort neu lesen und die Knöpfe sofort neu bestimmen (im Kampf aufgeschoben)
local function onZoneChanged()
  forgetZones()
  if buttonsWanted() then QuestItem.Refresh() end
end
for _, event in ipairs({ "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "PLAYER_ENTERING_WORLD" }) do
  ns.RegisterEvent(event, onZoneChanged)
end
-- Questlog geändert: Überschriften, Kandidaten und Zonen-Entscheidungen verwerfen; die Knöpfe folgen mit dem
-- Sekundentakt (QUEST_LOG_UPDATE kommt oft mehrmals hintereinander, eingelesen wird höchstens einmal je Takt)
ns.RegisterEvent("QUEST_LOG_UPDATE", forgetQuestLog)
ns.RegisterEvent("QUEST_REMOVED", forgetQuestLog)
ns.RegisterUnitEvent("UNIT_QUEST_LOG_CHANGED", "player", forgetQuestLog)
-- Taschen: Anzahl auf dem Knopf, Quest-Items können dazukommen oder wegfallen
ns.RegisterEvent("BAG_UPDATE_DELAYED", forgetItems)
local function plateChanged() targetDirty = true end
ns.RegisterEvent("NAME_PLATE_UNIT_ADDED", plateChanged)
ns.RegisterEvent("NAME_PLATE_UNIT_REMOVED", plateChanged)

-- Ohne Ereignis: nach Abstand neu wählen (nur mit mehreren Kandidaten, wo der Client Abstände kennt)
local function distanceDue(db)
  return db.questItemButton and inZoneCount >= 2 and C_QuestLog ~= nil and C_QuestLog.GetDistanceSqToQuest ~= nil
    and GetTime() >= nextDistanceAt
end

-- Zielknopf: stehende Plaketten (Gegner sterben, Namen werden lesbar) und neu gelernte Namen
local function targetMayChange(db)
  if not db.questTargetButton then return false end
  if next(ns.NamePlates.Active()) ~= nil and QuestItem.CanTarget() then return true end
  return db.questLearning and ns.QuestMobs.OpenMobNames() ~= shownMobNames
end

local function tick()
  local db = ns.db
  if itemDirty or targetDirty or distanceDue(db) or targetMayChange(db) then QuestItem.Refresh() end
end

ns.Every(REFRESH_SECONDS, tick, function() return buttonsWanted() or (holder ~= nil and holder:IsShown()) end)

ns.RegisterApply(apply)

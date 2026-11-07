-- Was das Debug-Log (DebugLog.lua) sammelt: Daten für die Fehlersuche und für geplante Funktionen der Roadmap, damit
-- deren API-Annahmen je Client mit echten Spieldaten geprüft werden können, bevor sie gebaut werden.
--   - Zustand (playerState) bei vielen Ereignissen, im Schnappschuss jede SNAPSHOT_SECONDS und beim Logout;
--   - Ereignis-Proben (EVENT_PROBES): Argumente, optional Zustand und Zusatzdaten (extra) im Moment des Ereignisses;
--   - Flugrouten über einen Hook auf TakeTaxiNode (258), gewirkte Zauber als Zählung je Minute (300, 316);
--   - beim Login/Einschalten API- und Text-Proben (gibt es die Funktion, wie lautet der globale Text);
--   - Prüfungen für /lt debug check (CHECKS).
-- Die Nummern in Kommentaren sind die Roadmap-Punkte, für die die Daten gedacht sind. Alles läuft geschützt: ein
-- fehlendes API landet als Fehlertext im Log, nie als Lua-Fehler. Neue Fragen ans Spiel kommen hier dazu.
local _, ns = ...
local DebugLog = ns.DebugLog
local write, pack, packCount = DebugLog.Write, DebugLog.Pack, DebugLog.PackCount

local SNAPSHOT_SECONDS = 60
local MAX_EVENT_ARGS = 10    -- mehr Argumente einer Ereignis-Probe werden nicht geschrieben
local MAX_LIST = 30          -- Einträge je Liste (Quests, Ruf, Lehrer, Beute, ...)
local MAX_ACTION_SLOT = 180  -- Aktionsplätze, die nach Items durchsucht werden (267)
local INVENTORY_SLOTS = 19   -- Ausrüstungsplätze (300 "nackt")
local HEARTHSTONE_ITEM = 6948
local WELL_FED_SPELL = 19705
local HONOR_CURRENCY = 1792  -- Retail
local SAMPLE_QUEST = 783     -- erste Menschen-Quest, für IsQuestFlaggedCompleted (296)

-- Ergebnis von pcall: Fehler als Text, ein Wert als Wert, mehrere als Liste (nil darin als JSON null)
local function collect(ok, ...)
  if not ok then return "error: " .. tostring((...)) end
  local count = select("#", ...)
  if count <= 1 then return (...) end
  return packCount(count, ...)
end

-- fn(...) geschützt; fehlende Funktion = nil
local function safe(fn, ...)
  if type(fn) ~= "function" then return nil end
  return collect(pcall(fn, ...))
end

local function api(path)
  local value = _G
  for part in path:gmatch("[^%.]+") do
    if type(value) ~= "table" then return nil end
    value = value[part]
  end
  return value
end

-- Rückgabe von api(path)(...) oder Fehlertext; nil, wenn es die Funktion nicht gibt
local function call(path, ...)
  return safe(api(path), ...)
end

---------------------------------------------------------------------------
-- Zustand
---------------------------------------------------------------------------
local function mapPosition()
  local mapId = call("C_Map.GetBestMapForUnit", "player")
  if type(mapId) ~= "number" then return { mapId = mapId } end
  local position = call("C_Map.GetPlayerMapPosition", mapId, "player")
  if type(position) ~= "table" or not position.GetXY then return { mapId = mapId } end
  local x, y = position:GetXY()
  return { mapId = mapId, x = x, y = y }  -- 280: Ort beim Tod
end

local function playerState()
  return {
    level = call("UnitLevel", "player"),
    xp = call("UnitXP", "player"),
    xpMax = call("UnitXPMax", "player"),
    rested = call("GetXPExhaustion"),
    resting = call("IsResting"),
    combat = call("UnitAffectingCombat", "player"),
    dead = call("UnitIsDeadOrGhost", "player"),
    taxi = call("UnitOnTaxi", "player"),
    mounted = call("IsMounted"),
    group = call("GetNumGroupMembers"),
    money = call("GetMoney"),
    zone = call("GetRealZoneText"),
    subzone = call("GetSubZoneText"),
    instance = (call("IsInInstance")),
    map = mapPosition(),
  }
end

---------------------------------------------------------------------------
-- Zusatzdaten zu Ereignissen
---------------------------------------------------------------------------
local function upTo(count, limit)
  if type(count) ~= "number" then return 0 end
  return math.min(count, limit or MAX_LIST)
end

local function listOf(count, item)
  local list = {}
  for index = 1, upTo(count) do list[index] = item(index) end
  return list
end

local function unitInfo(unit)
  return {
    exists = call("UnitExists", unit),
    name = call("UnitName", unit),
    level = call("UnitLevel", unit),
    classification = call("UnitClassification", unit),
    guid = call("UnitGUID", unit),  -- 302: NPC-ID im 6. Feld
    creatureType = call("UnitCreatureType", unit),
    player = call("UnitIsPlayer", unit),
    questRelated = call("C_QuestLog.UnitIsRelatedToActiveQuest", unit),
  }
end

-- 257: Lehrer-Dienste mit Kosten (Rückgabereihenfolge je Client)
local function trainerServices()
  return listOf(call("GetNumTrainerServices"), function(index)
    return { info = (call("GetTrainerServiceInfo", index)), cost = call("GetTrainerServiceCost", index) }
  end)
end

-- 254: Inhalt des Beutefensters
local function lootSlots()
  return {
    autoLoot = call("GetCVar", "autoLootDefault"),
    slots = listOf(call("GetNumLootItems"), function(slot)
      return { hasItem = call("LootSlotHasItem", slot), slotType = call("GetLootSlotType", slot),
        info = (call("GetLootSlotInfo", slot)) }
    end),
  }
end

-- 259/260: Quests in Gesprächen (Retail-API) und Grußfenstern (alte API), mit Level und ID; 181: Optionen mit Flags
local function gossipInfo()
  return {
    available = call("C_GossipInfo.GetAvailableQuests"),
    active = call("C_GossipInfo.GetActiveQuests"),
    options = call("C_GossipInfo.GetOptions"),
  }
end

local function greetingInfo()
  return {
    available = listOf(call("GetNumAvailableQuests"), function(index)
      return { title = call("GetAvailableTitle", index), level = call("GetAvailableLevel", index),
        info = (call("GetAvailableQuestInfo", index)) }
    end),
    active = listOf(call("GetNumActiveQuests"), function(index)
      return { title = call("GetActiveTitle", index), level = call("GetActiveLevel", index) }
    end),
  }
end

local function questFrameInfo()
  return {
    questId = call("GetQuestID"), title = call("GetTitleText"), rewardXp = call("GetRewardXP"),
    rewardMoney = call("GetRewardMoney"), choices = call("GetNumQuestChoices"),
  }
end

-- 256: wer beschwört wohin, wie lange noch
local function summonInfo()
  return {
    summoner = call("C_SummonInfo.GetSummonConfirmSummoner") or call("GetSummonConfirmSummoner"),
    area = call("C_SummonInfo.GetSummonConfirmAreaName") or call("GetSummonConfirmAreaName"),
    timeLeft = call("C_SummonInfo.GetSummonConfirmTimeLeft") or call("GetSummonConfirmTimeLeft"),
  }
end

-- 258: Flugkarte beim Öffnen: Knoten, aktueller Ort
local function taxiMapInfo()
  return listOf(call("NumTaxiNodes"), function(index)
    return { name = call("TaxiNodeName", index), nodeType = call("TaxiNodeGetType", index),
      position = (call("TaxiNodePosition", index)) }
  end)
end

-- 291: Gruppe (Größe, Level und Klasse der Mitglieder)
local function groupInfo()
  return listOf(call("GetNumSubgroupMembers"), function(index)
    local unit = "party" .. index
    return { level = call("UnitLevel", unit), class = (call("UnitClass", unit)) }
  end)
end

local function instanceInfo()
  return (call("GetInstanceInfo"))
end

local function equipmentSlot(slot)
  return { slot = slot, itemId = call("GetInventoryItemID", "player", slot) }
end

local function mirrorProgress(timer)
  return call("GetMirrorTimerProgress", timer)
end

---------------------------------------------------------------------------
-- Ereignis-Proben: Ereignisse, deren Argumente, Reihenfolge oder Inhalt für offene oder geplante Punkte im Spiel
-- geprüft werden müssen. state = Zustand mitschreiben, extra(...) = Zusatzdaten (bekommt die Argumente).
---------------------------------------------------------------------------
local EVENT_PROBES = {
  -- XP, Kills, Level (251, 175, 270, 273, 275)
  { event = "CHAT_MSG_COMBAT_XP_GAIN", state = true },
  { event = "PLAYER_XP_UPDATE", state = true },
  { event = "PLAYER_LEVEL_UP", state = true },
  { event = "UPDATE_EXHAUSTION", state = true },
  { event = "PLAYER_REGEN_DISABLED" },
  { event = "PLAYER_REGEN_ENABLED" },
  { event = "PLAYER_TARGET_CHANGED", extra = function() return unitInfo("target") end },
  { event = "CHAT_MSG_OPENING" },
  -- Quests (259, 260, 264, 270, 288, 289, 296)
  { event = "QUEST_ACCEPTED" },
  { event = "QUEST_TURNED_IN", state = true },
  { event = "QUEST_DETAIL", extra = questFrameInfo },
  { event = "QUEST_PROGRESS", extra = questFrameInfo },
  { event = "QUEST_COMPLETE", extra = questFrameInfo },
  { event = "QUEST_GREETING", extra = greetingInfo },
  { event = "GOSSIP_SHOW", extra = gossipInfo },
  { event = "UI_INFO_MESSAGE" },
  { event = "UI_ERROR_MESSAGE" },
  -- Tod, Zonen, Instanzen, Bosse (280, 282, 287, 302, 307, 322)
  { event = "PLAYER_DEAD", state = true },
  { event = "PLAYER_ALIVE" },
  { event = "PLAYER_UNGHOST" },
  { event = "ZONE_CHANGED_NEW_AREA", state = true, extra = instanceInfo },
  { event = "PLAYER_ENTERING_WORLD", state = true, extra = instanceInfo },
  { event = "ENCOUNTER_START" },
  { event = "ENCOUNTER_END", state = true },
  { event = "BOSS_KILL" },
  { event = "CHAT_MSG_SYSTEM" },
  -- Beute, Geld, Berufe, Ruf, Ehre, Erfolge (254, 262, 276, 278, 295, 297, 303, 309)
  { event = "LOOT_READY", extra = lootSlots },
  { event = "LOOT_BIND_CONFIRM" },
  { event = "CONFIRM_LOOT_ROLL" },
  { event = "DELETE_ITEM_CONFIRM" },
  { event = "CHAT_MSG_LOOT" },
  { event = "CHAT_MSG_MONEY" },
  { event = "PLAYER_MONEY", state = true },
  { event = "MERCHANT_SHOW" },
  { event = "MAIL_SHOW" },
  { event = "AUCTION_HOUSE_SHOW" },
  { event = "TRADE_SHOW" },
  { event = "CHAT_MSG_SKILL" },
  { event = "CHAT_MSG_COMBAT_FACTION_CHANGE" },
  { event = "UPDATE_FACTION" },
  { event = "CHAT_MSG_COMBAT_HONOR_GAIN" },
  { event = "ACHIEVEMENT_EARNED" },
  { event = "TIME_PLAYED_MSG" },
  -- Komfort (255, 256, 257, 258, 261, 265, 291, 294, 300)
  { event = "MIRROR_TIMER_START", extra = function(timer) return mirrorProgress(timer) end },
  { event = "MIRROR_TIMER_STOP" },
  { event = "CONFIRM_SUMMON", extra = summonInfo },
  { event = "RESURRECT_REQUEST" },
  { event = "TRAINER_SHOW", extra = trainerServices },
  { event = "TAXIMAP_OPENED", extra = taxiMapInfo },
  { event = "PLAYER_CONTROL_LOST", state = true },
  { event = "PLAYER_CONTROL_GAINED", state = true },
  { event = "CINEMATIC_START" },
  { event = "PLAY_MOVIE" },
  { event = "PARTY_INVITE_REQUEST" },
  { event = "GROUP_ROSTER_UPDATE", extra = groupInfo },
  { event = "PLAYER_EQUIPMENT_CHANGED", extra = function(slot) return equipmentSlot(slot) end },
  { event = "SCREENSHOT_SUCCEEDED" },
}

local function probeEvent(probe, ...)
  if not DebugLog.IsEnabled() then return end
  local count = math.min(select("#", ...), MAX_EVENT_ARGS)
  while count > 0 and select(count, ...) == nil do count = count - 1 end
  local entry = { area = "event", event = probe.event, args = packCount(count, ...) }
  if probe.state then entry.state = playerState() end
  if probe.extra then entry.extra = safe(probe.extra, ...) end
  write(entry)
end

-- Alle Proben-Events hängen nur, solange das Log läuft, am Client (sonst kostet jedes dieser Events einen Aufruf,
-- der sofort abbricht); angemeldet wird am Ende der Datei. unknownEvents = Events, die der Client nicht kennt.
local probeEvents = ns.NewEventGroup()
local unknownEvents = {}
local unknownEventsKnown = false
for _, probe in ipairs(EVENT_PROBES) do
  probeEvents.Add(probe.event, nil, function(...) probeEvent(probe, ...) end)
end

-- 258: Flugroute beim Abflug (Start, Ziel, Zwischenhalte); die Landung zeigt PLAYER_CONTROL_GAINED mit Zustand
if hooksecurefunc and TakeTaxiNode then
  hooksecurefunc("TakeTaxiNode", function(index)
    if not DebugLog.IsEnabled() then return end
    write({
      area = "taxi", node = index, name = call("TaxiNodeName", index), position = (call("TaxiNodePosition", index)),
      routes = listOf(call("GetNumRoutes", index), function(hop)
        return { x = call("TaxiGetDestX", index, hop), y = call("TaxiGetDestY", index, hop) }
      end),
      map = taxiMapInfo(), state = playerState(),
    })
  end)
end

---------------------------------------------------------------------------
-- Kampf-Proben: sind Mana, Bedrohung, Kontrollverlust und Debuffs auf dem Spieler lesbar oder geheim (Ansagen
-- "wenig Mana", "Aggro auf mir", "CC auf mir")? Geheime Werte erscheinen als "<secret>", Fehler (z.B. gesperrte
-- Auren) als Text. Im Kampf alle COMBAT_SAMPLE_SECONDS und bei den Ereignissen unten, außerhalb in /lt debug check.
---------------------------------------------------------------------------
local COMBAT_SAMPLE_SECONDS = 5
local MANA, RAGE, ENERGY = 0, 1, 3
local MAX_HARMFUL_AURAS = 5
local RESTRICTION_CHAT, RESTRICTION_MAP = 5, 4  -- Enum.AddOnRestrictionType (Recherche, im Spiel prüfen)
local CC_FILTER = "HARMFUL|CROWD_CONTROL"

-- Anzahl der CC-Auren. Im Spiel geprüft (Forever 1.60.1): bei geheimen Auren (im Kampf) wirft
-- GetUnitAuraInstanceIDs "Auras cannot be accessed when secret while tainted"; dann nur "secret" loggen.
local function crowdControlCount()
  if call("C_Secrets.ShouldAurasBeSecret") == true then return "secret" end
  local ids = call("C_UnitAuras.GetUnitAuraInstanceIDs", "player", CC_FILTER)
  if type(ids) == "table" then return #ids end
  return ids
end

-- Kontrollverlust: priority und displayType sind laut Doku nie geheim, locType/spellID in Forever schon
local function lossOfControl()
  local data = call("C_LossOfControl.GetActiveLossOfControlData", 1)
  if type(data) ~= "table" then return data end
  return { locType = data.locType, spellID = data.spellID, displayText = data.displayText, priority = data.priority,
    displayType = data.displayType, timeRemaining = data.timeRemaining }
end

local function harmfulAuras()
  if call("C_Secrets.ShouldAurasBeSecret") == true then return "secret" end
  local auras = {}
  for index = 1, MAX_HARMFUL_AURAS do
    local aura = call("C_UnitAuras.GetAuraDataByIndex", "player", index, "HARMFUL")
    if aura == nil then break end
    if type(aura) == "table" then
      aura = { spellId = aura.spellId, name = aura.name, dispelName = aura.dispelName, duration = aura.duration }
    end
    auras[index] = aura
  end
  return auras
end

-- 327: Klassen-Buffs per Spell-ID im Kampf lesbar? Je Zauber der eigenen Klasse: ShouldSpellAuraBeSecret und ob
-- GetPlayerAuraBySpellID eine Aura liefert (true/false, geheim oder Fehlertext)
local function classBuffAuras()
  local result = {}
  for _, reminder in ipairs(ns.ClassBuffs and ns.ClassBuffs.ForPlayerClass() or {}) do
    for _, spellId in ipairs(reminder.spells or {}) do
      local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellId)
      local found = aura
      if ok and not ns.IsSecret(aura) then found = aura ~= nil elseif not ok then found = "error: " .. tostring(aura) end
      result[tostring(spellId)] = { secret = call("C_Secrets.ShouldSpellAuraBeSecret", spellId), found = found }
    end
  end
  return result
end

local function combatSample()
  return {
    combat = call("UnitAffectingCombat", "player"),
    instance = (call("IsInInstance")),
    lockdown = call("C_ChatInfo.InChatMessagingLockdown"),
    restriction = { chat = call("C_RestrictedActions.GetAddOnRestrictionState", RESTRICTION_CHAT),
      map = call("C_RestrictedActions.GetAddOnRestrictionState", RESTRICTION_MAP) },
    mana = { value = call("UnitPower", "player", MANA), max = call("UnitPowerMax", "player", MANA),
      percent = call("UnitPowerPercent", "player", MANA),
      shouldBeSecret = call("C_Secrets.ShouldUnitPowerBeSecret", "player", MANA),
      secrecy = { mana = call("C_Secrets.GetPowerTypeSecrecy", MANA), rage = call("C_Secrets.GetPowerTypeSecrecy", RAGE),
        energy = call("C_Secrets.GetPowerTypeSecrecy", ENERGY) } },
    health = { value = call("UnitHealth", "player"), percent = call("UnitHealthPercent", "player") },
    threat = { situation = call("UnitThreatSituation", "player"),
      onTarget = call("UnitThreatSituation", "player", "target"),
      detailed = call("UnitDetailedThreatSituation", "player", "target"),
      targetsMe = call("UnitIsUnit", "targettarget", "player"), targetTargetGuid = call("UnitGUID", "targettarget"),
      shouldBeSecret = call("C_Secrets.ShouldUnitThreatStateBeSecret", "player") },
    control = { fullControl = call("HasFullControl"), count = call("C_LossOfControl.GetActiveLossOfControlDataCount"),
      first = lossOfControl(), crowdControlAuras = crowdControlCount(), speed = call("GetUnitSpeed", "player") },
    auras = { secret = call("C_Secrets.ShouldAurasBeSecret"), harmful = harmfulAuras() },
    classBuffs = classBuffAuras(),
  }
end

local function writeCombatSample(reason, ...)
  if not DebugLog.IsEnabled() then return end
  write({ area = "combat", reason = reason, args = packCount(math.min(select("#", ...), MAX_EVENT_ARGS), ...),
    sample = combatSample() })
end

ns.Every(COMBAT_SAMPLE_SECONDS, function()
  if ns.InCombat() then writeCombatSample("tick") end
end, DebugLog.IsEnabled)

for _, event in ipairs({ "LOSS_OF_CONTROL_ADDED", "LOSS_OF_CONTROL_UPDATE", "PLAYER_REGEN_DISABLED" }) do
  probeEvents.Add(event, nil, function(...) writeCombatSample(event, ...) end)
end
probeEvents.Add("UNIT_THREAT_SITUATION_UPDATE", "player", function(...)
  writeCombatSample("UNIT_THREAT_SITUATION_UPDATE", ...)
end)

-- 300/316: gewirkte Zauber des Spielers, als Zählung je Spell-ID im Schnappschuss (einzeln wären es zu viele Zeilen)
local castCounts = {}
probeEvents.Add("UNIT_SPELLCAST_SUCCEEDED", "player", function(_, _, spellId)
  if not DebugLog.IsEnabled() or ns.IsSecret(spellId) or spellId == nil then return end
  local key = tostring(spellId)
  castCounts[key] = (castCounts[key] or 0) + 1
end)

ns.Every(SNAPSHOT_SECONDS, function()
  if not DebugLog.IsEnabled() then return end
  write({ area = "snapshot", state = playerState(), casts = castCounts })
  castCounts = {}
end, DebugLog.IsEnabled)

ns.OnLogout(function()
  if DebugLog.IsEnabled() then write({ area = "snapshot", reason = "logout", state = playerState() }) end
end)

---------------------------------------------------------------------------
-- API- und Text-Proben, beim Login, Einschalten und vor jeder Prüfung
---------------------------------------------------------------------------
local API_PROBES = {
  -- Komfort
  "C_SummonInfo.ConfirmSummon", "C_SummonInfo.GetSummonConfirmSummoner", "ConfirmSummon", "GetSummonConfirmSummoner",
  "AcceptResurrect", "GetMirrorTimerProgress", "GetMirrorTimerInfo", "StopCinematic", "CinematicFrame_CancelCinematic",
  "MovieFrame", "FlashClientIcon", "Screenshot", "LootSlot", "GetNumLootItems", "ConfirmLootSlot", "ConfirmLootRoll",
  "BuyTrainerService", "GetTrainerServiceInfo", "GetTrainerServiceCost", "C_TaxiMap.GetAllTaxiNodes",
  "TaxiNodePosition", "GetNumRoutes", "TakeTaxiNode", "GetPlayerInfoByGUID", "C_PartyInfo.InviteUnit", "InviteUnit",
  "SecureActionButtonTemplate", "GetActionInfo", "C_Container.GetContainerItemQuestInfo", "GetQuestLogSpecialItemInfo",
  -- Quests
  "C_QuestLog.GetInfo", "C_QuestLog.GetNumQuestLogEntries", "GetQuestLogTitle", "GetNumQuestLogEntries",
  "GetQuestLogRewardXP", "C_QuestLog.ReadyForTurnIn", "C_QuestLog.IsQuestFlaggedCompleted", "IsQuestFlaggedCompleted",
  "GetQuestsCompleted", "C_QuestLog.UnitIsRelatedToActiveQuest", "C_GossipInfo.SelectAvailableQuest",
  "C_GossipInfo.GetAvailableQuests", "C_GossipInfo.GetOptions", "GetAvailableLevel",
  -- Statistik
  "C_Reputation.GetFactionDataByID", "C_Reputation.GetFactionDataByIndex", "GetFactionInfo", "GetNumFactions",
  "C_MapExplorationInfo.GetExploredMapTextures", "C_MapExplorationInfo.GetExploredAreaIDsAtPosition",
  "C_Map.GetPlayerMapPosition", "C_Map.GetBestMapForUnit", "C_Item.GetItemCount", "GetItemCount", "GetRestState",
  "TooltipDataProcessor.AddTooltipPostCall", "C_TooltipInfo.GetUnit", "GameTooltip.HookScript",
  "C_CurrencyInfo.GetCurrencyInfo", "GetPVPLifetimeStats", "GetAchievementInfo", "GetTotalAchievementPoints",
  "GetProfessions", "GetProfessionInfo", "GetNumSkillLines", "GetSkillLineInfo", "GetNumSavedInstances",
  "GetSavedInstanceInfo", "C_DeathRecap.GetRecapEvents", "GetGuildBankWithdrawMoney", "CanGuildBankRepair",
  -- Austausch und Sonstiges
  "C_ChatInfo.SendAddonMessage", "C_ChatInfo.RegisterAddonMessagePrefix", "C_ChatInfo.InChatMessagingLockdown",
  "C_Spell.GetSpellInfo", "GetSpellInfo", "C_Secrets", "C_Secrets.GetPowerTypeSecrecy", "C_Secrets.ShouldAurasBeSecret",
  "issecretvalue", "UnitPowerPercent", "UnitHealthPercent", "C_CurveUtil.CreateCurve", "C_LossOfControl",
  "C_LossOfControl.GetActiveLossOfControlData", "C_LossOfControl.GetActiveLossOfControlDataCount",
  "UnitThreatSituation", "UnitDetailedThreatSituation", "HasFullControl", "C_UnitAuras.GetUnitAuraInstanceIDs",
  "C_RestrictedActions.GetAddOnRestrictionState", "C_Secrets.ShouldUnitPowerBeSecret",
  "C_Secrets.ShouldUnitThreatStateBeSecret", "Enum.AddOnRestrictionType",
}

local GLOBAL_STRING_PROBES = {
  "COMBATLOG_XPGAIN_FIRSTPERSON", "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED", "ERR_ZONE_EXPLORED", "ERR_ZONE_EXPLORED_XP",
  "SKILL_RANK_UP", "FACTION_STANDING_INCREASED", "FACTION_STANDING_DECREASED", "LOOT_ITEM_SELF",
  "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_CREATED_SELF", "LOOT_ITEM_CREATED_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF",
  "LOOT_MONEY_SPLIT", "YOU_LOOT_MONEY", "OPEN_LOCK_SELF", "COMBATLOG_HONORGAIN", "INSTANCE_RESET_SUCCESS",
  "ERR_INV_FULL", "ERR_OUT_OF_MANA", "ERR_ITEM_MAX_COUNT", "ERR_LOOT_ROLL_PENDING", "ERR_QUEST_OBJECTIVE_COMPLETE_S",
  "ERR_QUEST_ADD_KILL_SII", "ERR_QUEST_ADD_ITEM_SII", "ERR_QUEST_ACCEPTED_S", "ERR_QUEST_COMPLETE_S",
  "ACHIEVEMENT_BROADCAST",
}

DebugLog.OnHeader(function()
  local apis = {}
  for _, path in ipairs(API_PROBES) do apis[path] = type(api(path)) end
  local strings = {}
  for _, name in ipairs(GLOBAL_STRING_PROBES) do strings[name] = _G[name] or false end
  if not unknownEventsKnown then
    -- /lt debug check bei ausgeschaltetem Log: einmal kurz anmelden, um unbekannte Events festzustellen
    unknownEvents, unknownEventsKnown = probeEvents.SetActive(true), true
    probeEvents.SetActive(false)
  end
  write({ area = "probe", apis = apis, strings = strings, unknownEvents = unknownEvents, state = playerState() })
end)

---------------------------------------------------------------------------
-- Prüfungen für /lt debug check (offene "im Spiel prüfen"-Punkte und geplante Funktionen)
---------------------------------------------------------------------------
local check = DebugLog.AddCheck

-- 259/268/270: alle Quests mit Level, XP, Abgabebereitschaft und Quest-Item (Retail-API und alte API)
local function questLog()
  local count = call("C_QuestLog.GetNumQuestLogEntries")
  if type(count) == "number" then
    return listOf(count, function(index)
      local info = call("C_QuestLog.GetInfo", index)
      if type(info) ~= "table" or info.isHeader then return { header = true } end
      return { info = info, xp = call("GetQuestLogRewardXP", info.questID),
        ready = call("C_QuestLog.ReadyForTurnIn", info.questID), item = (call("GetQuestLogSpecialItemInfo", index)) }
    end)
  end
  return listOf(call("GetNumQuestLogEntries"), function(index)
    return { title = (call("GetQuestLogTitle", index)), item = (call("GetQuestLogSpecialItemInfo", index)) }
  end)
end

-- 278/303: Fraktionen mit Stand (Retail-API und alte API)
local function factions()
  local byIndex = api("C_Reputation.GetFactionDataByIndex")
  if byIndex then
    return listOf(call("C_Reputation.GetNumFactions"), function(index) return call("C_Reputation.GetFactionDataByIndex", index) end)
  end
  return listOf(call("GetNumFactions"), function(index) return (call("GetFactionInfo", index)) end)
end

-- 297: Berufe (Retail: GetProfessions, Classic: Fertigkeitenliste)
local function professions()
  local list = call("GetProfessions")
  if type(list) ~= "table" then list = { list } end  -- ein Beruf = ein Wert, keiner/fehlend = nil
  local infos = {}
  for _, index in ipairs(list) do
    if type(index) == "number" then infos[#infos + 1] = (call("GetProfessionInfo", index)) end
  end
  return { professions = infos,
    skillLines = listOf(call("GetNumSkillLines"), function(index) return (call("GetSkillLineInfo", index)) end) }
end

-- 267: Items auf den Aktionsleisten (Tränke, Gesundheitssteine)
local function actionItems()
  local items = {}
  for slot = 1, MAX_ACTION_SLOT do
    local kind, id = call("GetActionInfo", slot), nil
    if type(kind) == "table" then kind, id = kind[1], kind[2] end
    if kind == "item" and #items < MAX_LIST then items[#items + 1] = { slot = slot, itemId = id } end
  end
  return items
end

local function equipment()
  local equipped = {}
  for slot = 1, INVENTORY_SLOTS do equipped[slot] = call("GetInventoryItemID", "player", slot) or false end
  return equipped
end

check("secret.powerSecrecy", function() return C_Secrets.GetPowerTypeSecrecy(0) end)
check("secret.aurasSecret", function() return C_Secrets.ShouldAurasBeSecret() end)
check("unit.power", function() return UnitPower("player"), UnitPowerMax("player") end)
check("unit.health", function() return UnitHealth("player"), UnitHealthMax("player") end)
check("unit.stats", function() return pack(UnitStat("player", 1)), pack(UnitStat("player", 3)) end)
check("unit.player", function() return pack(UnitRace("player")), pack(UnitClass("player")), UnitGUID("player") end)
check("unit.target", function() return unitInfo("target") end)                       -- 273, 274, 302
check("unit.targetTooltip", function() return C_TooltipInfo.GetUnit("target") end) -- 274
check("xp.state", function() return UnitXP("player"), UnitXPMax("player"), GetXPExhaustion() end)
check("xp.tableTrusted", function() return ns.XpTable.XpBetween(ns.level, ns.level + 1), UnitXPMax("player") end)  -- nil = Tabelle passt nicht
check("rest.state", function() return GetRestState() end)                               -- 271
check("deathRecap.withoutId", function() return C_DeathRecap.GetRecapEvents() end)     -- 180
check("deathRecap.hasEvents", function() return C_DeathRecap.HasRecapEvents() end)
check("guild.repair", function() return CanGuildBankRepair(), GetGuildBankWithdrawMoney() end)  -- 179
check("chat.lockdown", function() return C_ChatInfo.InChatMessagingLockdown() end)
check("chat.addonPrefixes", function() return C_ChatInfo.GetRegisteredAddonMessagePrefixes() end)  -- 293, 311
check("quest.log", questLog)
check("quest.flaggedSample", function()
  return call("C_QuestLog.IsQuestFlaggedCompleted", SAMPLE_QUEST), call("IsQuestFlaggedCompleted", SAMPLE_QUEST)
end)
check("gossip.current", gossipInfo)                                                     -- nur bei offenem Gespräch
check("greeting.current", greetingInfo)
check("reputation.factions", factions)
check("skill.professions", professions)
check("map.position", mapPosition)
check("map.exploredTextures", function()
  local textures = C_MapExplorationInfo.GetExploredMapTextures(C_Map.GetBestMapForUnit("player"))
  return textures and #textures
end)
check("instance.info", instanceInfo)
check("instance.saved", function()
  return listOf(call("GetNumSavedInstances"), function(index) return (call("GetSavedInstanceInfo", index)) end)
end)
check("item.hearthstoneCount", function() return call("C_Item.GetItemCount", HEARTHSTONE_ITEM), call("GetItemCount", HEARTHSTONE_ITEM) end)
check("item.equipment", equipment)                                                      -- 300
check("actionbar.items", actionItems)                                                   -- 267
check("mirror.timers", function()
  return { (call("GetMirrorTimerInfo", 1)), (call("GetMirrorTimerInfo", 2)), (call("GetMirrorTimerInfo", 3)) }
end)
check("summon.pending", summonInfo)
check("achievement.points", function() return GetTotalAchievementPoints() end)
check("honor", function()
  return call("C_CurrencyInfo.GetCurrencyInfo", HONOR_CURRENCY), (call("GetPVPLifetimeStats"))
end)
check("trainer.services", trainerServices)                                              -- nur bei offenem Lehrer
check("taxi.nodes", taxiMapInfo)                                                        -- nur bei offener Flugkarte
check("loot.current", lootSlots)                                                        -- nur bei offener Beute
check("spell.info", function() return call("C_Spell.GetSpellInfo", WELL_FED_SPELL), (call("GetSpellInfo", WELL_FED_SPELL)) end)
check("cvars", function()
  return { autoLoot = call("GetCVar", "autoLootDefault"), cameraZoom = call("GetCVar", "cameraDistanceMaxZoomFactor") }
end)
-- Roadmap 329, Schritt 5 (System): gibt es die CVars und APIs, welche Werte stehen, was haben wir gemerkt
check("system.comfort", function()
  local values = {}
  for _, name in ipairs({ "ffxGlow", "ffxDeath", "ffxNether", "weatherDensity", "RAIDweatherDensity",
    "nameplateShowEnemies", "Sound_EnableEmoteSounds" }) do
    values[name] = call("GetCVar", name)
  end
  return {
    cvars = values, defaults = { weather = call("C_CVar.GetCVarDefault", "weatherDensity") },
    originals = LevelTimerDB and LevelTimerDB.cvarOriginals, characterOriginals = ns.character and ns.character.cvarOriginals,
    muteSoundFile = MuteSoundFile ~= nil, lowLevelRaid = call("GetAllowLowLevelRaid"),
    addonListUpdate = AddonList_Update ~= nil, addonListProvider = AddonList ~= nil and AddonList.ScrollBox ~= nil,
    raidColor = ChatTypeInfo and ChatTypeInfo.RAID and { ChatTypeInfo.RAID.r, ChatTypeInfo.RAID.g, ChatTypeInfo.RAID.b },
  }
end)
check("frames", function()
  return { levelUpDisplay = LevelUpDisplay ~= nil, eventToast = EventToastManagerFrame ~= nil,
    movieFrame = MovieFrame ~= nil, cinematicFrame = CinematicFrame ~= nil }
end)
check("group", groupInfo)
-- Klassen-Hinweise (ClassBuffs.lua): je Zauber-ID der eigenen Klasse Name im Client, bekannt, Ergebnis der Prüfung
check("class.reminders", function()
  local result = {}
  for _, reminder in ipairs(ns.ClassBuffs.ForPlayerClass()) do
    local spells = {}
    for _, spellId in ipairs(reminder.known or reminder.spells) do
      spells[#spells + 1] = { id = spellId, name = call("C_Spell.GetSpellName", spellId), known = call("IsPlayerSpell", spellId) }
    end
    result[reminder.setting] = { spells = spells, missing = safe(ns.ClassBuffs.IsMissing, reminder) }
  end
  return result
end)
check("combat.sample", combatSample)  -- außerhalb des Kampfs; im Kampf schreibt das Log alle 5 s
check("enum.restrictionTypes", function() return Enum.AddOnRestrictionType end)
check("secret.functions", function()
  local names = {}
  for name in pairs(C_Secrets) do names[#names + 1] = name end
  table.sort(names)
  return names
end)

-- 327: Sind die entfernten Aura-IDs von UNIT_AURA im Kampf lesbar (Wasserschild-Ladungen verbraucht)? Einmal je Kampf.
local auraRemovalLogged = false
probeEvents.Add("UNIT_AURA", "player", function(_, updateInfo)
  if auraRemovalLogged or not DebugLog.IsEnabled() or not InCombatLockdown() then return end
  if type(updateInfo) ~= "table" or ns.IsSecret(updateInfo) then return end
  local removed = updateInfo.removedAuraInstanceIDs
  if removed == nil then return end
  auraRemovalLogged = true
  write({ area = "probe", name = "unitAura.removedInCombat", secretList = ns.IsSecret(removed),
    first = type(removed) == "table" and not ns.IsSecret(removed) and removed[1] or nil, state = playerState() })
end)
probeEvents.Add("PLAYER_REGEN_ENABLED", nil, function() auraRemovalLogged = false end)

-- Proben an- und abmelden, wenn das Log an- oder ausgeht (auch beim Login, vor der Kopfzeile)
DebugLog.OnStateChanged(function(enabled)
  if enabled and not probeEvents.IsActive() then
    auraRemovalLogged = false
    unknownEvents, unknownEventsKnown = probeEvents.SetActive(true), true
  elseif not enabled then
    probeEvents.SetActive(false)
  end
end)

-- Helfer für weitere Proben und Prüfungen (DebugChecks.lua, lädt nach allen Modulen)
DebugLog.Probe = {
  api = api, call = call, safe = safe, listOf = listOf, playerState = playerState, unitInfo = unitInfo,
  MAX_EVENT_ARGS = MAX_EVENT_ARGS,
}

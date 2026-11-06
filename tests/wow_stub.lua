-- Nachgebaute WoW-API für die Addon-Tests (ausgeführt von tools/addontest).
-- Lädt das Addon in .toc-Reihenfolge. Jede *_test.lua läuft danach in einem frischen Lua-Zustand.
--
-- Für Tests verfügbar:
--   addon                  Namespace des Addons (ns)
--   wow.state              Spielzustand, den die API-Funktionen zurückgeben
--   wow.login(options)     Login simulieren (options überschreiben wow.state, playedSeconds = /played-Antwort)
--   wow.logout()           Logout oder /reload simulieren (PLAYER_LOGOUT)
--   wow.levelUp(level, xpMax, gains)  Level-Up wie im Client; gains = { health, power, talents, strength, agility, stamina, intellect }
--   wow.fire(event, ...)   Event an alle registrierten Frames senden
--   wow.advance(seconds)   Spielzeit (GetTime) und Uhrzeit (time) vorstellen
--   wow.runTimers()        geplante C_Timer.After-Callbacks ausführen
--   wow.printed            alle Chat-Ausgaben (print)
--   expect, expectNear, expectTrue   Prüfungen; Fehlschläge landen in TEST_FAILURES

local ADDON_DIR = ADDON_DIR  -- von tools/addontest gesetzt
local UNKNOWN_EVENT = "EVENT_NOT_IN_THIS_CLIENT"

wow = {
  state = {
    name = "Testchar",
    realm = "Testrealm",
    class = "WARRIOR",
    race = { "Orc", "Orc", 2 },  -- UnitRace: Name, Kürzel, Rassen-ID
    level = 10,
    xp = 0,
    xpMax = 1000,
    maxLevel = 60,
    rested = 0,
    money = 0,
    now = 1000,             -- GetTime()
    clock = 1700000000,     -- time()
    dead = false,
    honorableKills = 0,
    shiftDown = false,
    cursorX = 0,
    cursorY = 0,
    guid = "Player-1-0001",
    zone = "Wald von Elwynn",
    combatLog = {},          -- Rückgabewerte von C_CombatLog.GetCurrentEventInfo
    questTitle = nil,        -- Titel im offenen Quest-Abgabe-Dialog (GetTitleText)
    questTitles = {},        -- C_QuestLog.GetTitleForQuestID je Quest-ID
    instance = nil,          -- { name, type } wenn in einer Instanz (IsInInstance)
    faction = "Alliance",    -- UnitFactionGroup("player")
    battlefieldWinner = nil, -- GetBattlefieldWinner: nil = läuft noch, 0 Horde, 1 Allianz, 255 Unentschieden
    units = {},              -- weitere Einheiten: units.target = { name, classification, isPlayer }
    inGuild = false,
    inGroup = false,         -- Gruppe (IsInGroup)
    chatLockdown = false,    -- C_ChatInfo.InChatMessagingLockdown
    inCombat = false,
    onTaxi = false,          -- UnitOnTaxi
    afk = false,             -- UnitIsAFK
    resting = false,
    buffs = {},              -- aktive Buffs: Name oder { name, spellId } (C_UnitAuras.GetAuraDataByIndex)
    spellNames = { [433] = "Essen", [19705] = "Satt", [1229741] = "Lagervorteile" },  -- C_Spell.GetSpellName
    interface = (SCENARIO or ""):match("^forever_") and 16001 or 120105,  -- Interface-Version (GetBuildInfo); Szenarien forever_* laden als WoW Forever (16001)
    health = 1000,
    healthMax = 1000,
    powerMax = 0,
    trainer = { services = {} },  -- Klassenlehrer (GetTrainerServiceInfo)
    statBuffs = {},          -- UnitStat: Buff (+) oder Debuff (-) je Wert
    stats = {},              -- UnitStat: Gesamtwerte 1 = Stärke, 2 = Beweglichkeit, 3 = Ausdauer, 4 = Intelligenz
    -- Händler: Reparatur (CanMerchantRepair, GetRepairAllCost) und Gildenbank
    merchant = { canRepair = false, repairCost = 0, guildRepair = false, guildFunds = 0 },
    -- Taschen: bags[bag][slot] = { itemID, quality, stackCount, hasNoValue, isLocked } (C_Container)
    bags = { [0] = {} },
    bagSlots = 16,
    freeSlots = { [0] = { 16, 0 } },  -- je Tasche { frei, bagFamily } (GetContainerNumFreeSlots)
    durability = {},         -- je Ausrüstungsplatz { aktuell, max } (GetInventoryItemDurability)
    inventoryCounts = {},    -- Anzahl je Ausrüstungsplatz (GetInventoryItemCount), 0 = Munition
    sellPrices = {},         -- Verkaufspreis je itemID (C_Item.GetItemInfo)
    itemIcons = {},          -- Symbol (Datei-ID) je itemID (C_Item.GetItemInfoInstant); fehlt = unbekanntes Item
    -- Quest-NPC: Listen im Gespräch (GossipQuestUIInfo) und in der alten Quest-Liste (QUEST_GREETING)
    gossip = { available = {}, active = {}, options = {} },
    greeting = { available = {}, active = {} },  -- { title, isTrivial } bzw. { title, isComplete }
    questPvp = false,        -- QuestFlagsPVP
    questID = nil,           -- GetQuestID im offenen Quest-Text
    trivialQuests = {},      -- C_QuestLog.IsQuestTrivial je Quest-ID
    questAutoAccept = false, -- QuestGetAutoAccept
    questCompletable = true, -- IsQuestCompletable
    questMoney = 0,          -- GetQuestMoneyToGet
    questChoices = {},       -- Belohnungen zur Auswahl: Item-Links (GetQuestItemLink("choice", i))
  },
  printed = {},
  UNKNOWN_EVENT = UNKNOWN_EVENT,
  ADDON_DIR = ADDON_DIR,
}

---------------------------------------------------------------------------
-- Prüfungen
---------------------------------------------------------------------------
TEST_FAILURES = {}

local function fail(message)
  table.insert(TEST_FAILURES, message)
end

function expect(description, actual, expected)
  if actual ~= expected then
    fail(string.format("%s: erwartet %s, bekommen %s", description, tostring(expected), tostring(actual)))
  end
end

function expectNear(description, actual, expected, tolerance)
  if type(actual) ~= "number" or math.abs(actual - expected) > (tolerance or 0.01) then
    fail(string.format("%s: erwartet ~%s, bekommen %s", description, tostring(expected), tostring(actual)))
  end
end

function expectTrue(description, value)
  if not value then
    fail(description .. ": Bedingung nicht erfüllt")
  end
end

---------------------------------------------------------------------------
-- Frames: unbekannte Methoden sind No-Ops, damit nur das Nötige nachgebaut werden muss
---------------------------------------------------------------------------
local frames = {}

local frameMethods = {
  GetFont = function() return "Fonts\\FRIZQT__.TTF", 12, "" end,
  GetStringWidth = function(self) return #self._text * 6 end,
  GetTextWidth = function(self) return #self._text * 6 end,
  GetWidth = function(self) return self._width end,
  SetWidth = function(self, width) self._width = width end,
  SetSize = function(self, width, height) self._width, self._height = width, height or self._height end,
  GetHeight = function(self) return self._height end,
  SetHeight = function(self, height) self._height = height end,
  GetFrameLevel = function(self) return rawget(self, "_level") or 1 end,
  SetFrameLevel = function(self, level) self._level = level end,
  GetAlpha = function(self) return rawget(self, "_alpha") or 1 end,
  SetAlpha = function(self, alpha) self._alpha = alpha end,
  GetScale = function(self) return self._scale end,
  SetScale = function(self, scale) self._scale = scale end,
  GetLeft = function() return 100 end,
  GetTop = function() return 500 end,
  SetNormalTexture = function(self, texture) self._normalTexture = texture end,
  GetPoint = function() return "CENTER", nil, "CENTER", 0, 0 end,
  SetBackdropColor = function(self, r, g, b, a) self._backdropColor = { r, g, b, a } end,
  SetBackdropBorderColor = function(self, r, g, b, a) self._borderColor = { r, g, b, a } end,
  -- Anker werden nur gemerkt (frame._points), nicht ausgewertet
  SetPoint = function(self, ...) table.insert(self._points, { ... }) end,
  ClearAllPoints = function(self) self._points = {} end,
  GetCenter = function() return 0, 0 end,
  GetEffectiveScale = function() return 1 end,
  IsShown = function(self) return self._shown end,
  GetParent = function(self) return self._parent end,
  Show = function(self) self._shown = true end,
  Hide = function(self)
    local wasShown = self._shown
    self._shown = false
    local onHide = self._scripts and self._scripts.OnHide
    if wasShown and onHide then onHide(self) end
  end,
  SetShown = function(self, shown) self._shown = shown and true or false end,
  SetText = function(self, text) self._text = tostring(text) end,
  GetText = function(self) return self._text end,
  SetFocus = function(self) wow.focus = self end,
  ClearFocus = function(self) if wow.focus == self then wow.focus = nil end end,
  HasFocus = function(self) return wow.focus == self end,
  GetChecked = function(self) return self._checked end,
  SetChecked = function(self, checked) self._checked = checked end,
  SetScript = function(self, name, handler) self._scripts[name] = handler end,
  -- Wie im Client: vorhandenen Handler behalten und den neuen danach aufrufen
  HookScript = function(self, name, handler)
    local previous = self._scripts[name]
    self._scripts[name] = previous and function(...) previous(...); handler(...) end or handler
  end,
  AddLine = function(self, text) self._lines = self._lines or {}; table.insert(self._lines, text) end,
  ClearLines = function(self) self._lines = {} end,
  SetOwner = function(self) self._lines = {} end,
  SetHyperlink = function(self, link) self._hyperlink = link end,
  RegisterEvent = function(self, event)
    if event == UNKNOWN_EVENT then error("Attempt to register unknown event") end
    self._events[event] = true
  end,
  UnregisterEvent = function(self, event) self._events[event] = nil end,
  IsEventRegistered = function(self, event) return self._events[event] == true end,
}

local function noop() end

local function newFrame()
  local frame = {
    _shown = true, _scripts = {}, _events = {}, _text = "",
    _width = 200, _height = 100, _scale = 1, _checked = false, _normalTexture = "", _points = {},
  }
  frame.CreateFontString = function() return newFrame() end
  frame.CreateTexture = function() return newFrame() end
  table.insert(frames, frame)
  return setmetatable(frame, {
    __index = function(_, key) return frameMethods[key] or noop end,
  })
end

function wow.fire(event, ...)
  for _, frame in ipairs(frames) do
    if frame._events[event] and frame._scripts.OnEvent then
      frame._scripts.OnEvent(frame, event, ...)
    end
  end
end

function wow.advance(seconds)
  wow.state.now = wow.state.now + seconds
  wow.state.clock = wow.state.clock + seconds
end

function wow.login(options)
  for key, value in pairs(options or {}) do
    wow.state[key] = value
  end
  wow.fire("PLAYER_LOGIN")
  if wow.state.playedSeconds then
    wow.fire("TIME_PLAYED_MSG", wow.state.playedSeconds + 100000, wow.state.playedSeconds)
  end
end

-- Klickt den Button/Reiter mit dieser Beschriftung (Text-Buttons aus Widgets.CreateTab/CreateButton);
-- gleiche Beschriftungen auf mehreren Seiten: der erste Treffer, mit last = true der letzte
function wow.click(text, last)
  for i = 1, #frames do
    local frame = frames[last and #frames - i + 1 or i]
    local label = rawget(frame, "label")
    local caption = label and label._text or frame._text
    if caption == text and frame._scripts.OnClick then
      frame._scripts.OnClick(frame, "LeftButton")
      return true
    end
  end
  return false
end

-- Erster Frame, für den predicate(frame) true liefert (z.B. ein Ziehgriff ohne Namen)
function wow.findFrame(predicate)
  for _, frame in ipairs(frames) do
    if predicate(frame) then return frame end
  end
end

-- Kampflog-Event in der Feldreihenfolge von C_CombatLog.GetCurrentEventInfo senden
-- (Zeit, Event, hideCaster, Quelle GUID/Name/Flags/RaidFlags, Ziel GUID/Name/Flags/RaidFlags, Zusatzfelder)
function wow.combatLog(subevent, sourceName, destGUID, ...)
  wow.state.combatLog = { wow.state.now, subevent, false, "Creature-1", sourceName, 0, 0, destGUID, "Ziel", 0, 0, ... }
  wow.fire("COMBAT_LOG_EVENT_UNFILTERED")
end

-- Die gerade sichtbare Tabellen-Ansicht der Historie (TableView.lua)
function wow.shownTable()
  return wow.findFrame(function(frame)
    return rawget(frame, "GetVisibleRecords") ~= nil and frame:IsShown()
  end)
end

-- Alle bisher mit C_Timer.After geplanten Callbacks ausführen (Verzögerung egal)
function wow.runTimers()
  local due = wow.timers
  wow.timers = {}
  for _, callback in ipairs(due) do callback() end
end

-- Ein Bild weiter: OnUpdate aller sichtbaren Frames mit elapsed Sekunden (ns.Every, Fenster, ...)
function wow.update(elapsed)
  for _, frame in ipairs(frames) do
    if frame._scripts.OnUpdate and frame._shown then frame._scripts.OnUpdate(frame, elapsed) end
  end
end

function wow.logout()
  wow.fire("PLAYER_LOGOUT")
end

-- Level-Up wie im Client: Event mit neuem Level, danach neue XP-Werte
function wow.levelUp(newLevel, newXpMax, gains)
  gains = gains or {}
  wow.fire("PLAYER_LEVEL_UP", newLevel, gains.health, gains.power, gains.talents, gains.pvpSlots,
    gains.strength, gains.agility, gains.stamina, gains.intellect)
  wow.state.level = newLevel
  wow.state.xp = 0
  wow.state.xpMax = newXpMax or wow.state.xpMax
end

---------------------------------------------------------------------------
-- WoW-Globals
---------------------------------------------------------------------------
local state = wow.state

-- Benannte Frames landen wie im Client als Global (z.B. LevelTimerFrame)
CreateFrame = function(_, name, parent)
  local frame = newFrame()
  frame._parent = parent
  if name then _G[name] = frame end
  return frame
end
UIParent, Minimap, GameTooltip, GameFontNormalLarge = newFrame(), newFrame(), newFrame(), newFrame()
UISpecialFrames, SlashCmdList = {}, {}
StaticPopupDialogs, YES, NO = {}, "Ja", "Nein"
-- Dialog nicht anzeigen, sondern merken; Tests bestätigen mit StaticPopupDialogs[name].OnAccept
function StaticPopup_Show(name, textArg1, textArg2, data)
  wow.popup = { name = name, text = textArg1, data = data }
end
COMBATLOG_XPGAIN_FIRSTPERSON = "%s stirbt, Ihr bekommt %d Erfahrung."
COMBATLOG_HONORGAIN = "%s stirbt, ehrenhafter Sieg Rang: %s (Geschätzte Ehrenpunkte: %d)"
-- Texte wie im deutschen Client (WoW Forever, per /dump geprüft)
INSTANCE_RESET_SUCCESS = "'%s' wurde zurückgesetzt."
INSTANCE_RESET_FAILED = "'%s' kann nicht zurückgesetzt werden. Es halten sich noch Spieler in der Instanz auf."
TRANSFER_ABORT_TOO_MANY_INSTANCES = "Ihr habt in letzter Zeit zu viele Instanzen betreten."
LOOT_ITEM_SELF = "Ihr erhaltet Beute: %s."
LOOT_ITEM_SELF_MULTIPLE = "Ihr erhaltet Beute: %sx%d."
LOOT_ITEM_PUSHED_SELF = "Ihr erhaltet einen Gegenstand: %s."
LOOT_ITEM_CREATED_SELF = "Ihr stellt her: %s."
LOOT_ITEM_CREATED_SELF_MULTIPLE = "Ihr stellt her: %sx%d."
-- Timer laufen nicht von selbst; Tests starten sie mit wow.runTimers()
wow.timers = {}
C_Timer = { After = function(_, callback) table.insert(wow.timers, callback) end }
-- Chatfenster wie im Client: schreiben /played in ihrem TIME_PLAYED_MSG-Handler (wow.playedLines)
-- Wie im Client ohne loadDeprecationFallbacks: nur die Konstante, nicht der Alias NUM_CHAT_WINDOWS
Constants = { ChatFrameConstants = { MaxChatWindows = 2 } }
wow.playedLines = 0
-- Zeilen wie Blizzards ScrollingMessageFrame: GetMessageInfo(1) ist die älteste (chatFrame._messages)
for index = 1, Constants.ChatFrameConstants.MaxChatWindows do
  local chatFrame = newFrame()
  chatFrame._events.TIME_PLAYED_MSG = true
  chatFrame._scripts.OnEvent = function() wow.playedLines = wow.playedLines + 1 end
  chatFrame._messages = {}
  chatFrame.GetNumMessages = function(self) return #self._messages end
  chatFrame.GetMessageInfo = function(self, messageIndex) return self._messages[messageIndex], 1, 1, 1 end
  _G["ChatFrame" .. index] = chatFrame
end
DEFAULT_CHAT_FRAME, SELECTED_CHAT_FRAME = ChatFrame1, ChatFrame1
date = os.date

function print(...)
  local parts = {}
  for i = 1, select("#", ...) do
    parts[i] = tostring((select(i, ...)))
  end
  table.insert(wow.printed, table.concat(parts, " "))
end

function GetLocale() return "deDE" end
function UnitLevel() return state.level end
function UnitXP() return state.xp end
function UnitXPMax() return state.xpMax end
function GetMaxPlayerLevel() return state.maxLevel end
function GetXPExhaustion() return state.rested > 0 and state.rested or nil end
function GetMoney() return state.money end
function GetTime() return state.now end
-- Geheime Werte (Retail/Forever): Tests setzen wow.SECRET als Rückgabe einer API
wow.SECRET = setmetatable({}, { __tostring = function() return "<secret>" end })
function issecretvalue(value) return value == wow.SECRET end
-- Fehler-Handler des Clients: merkt sich Fehler, statt sie anzuzeigen
wow.errors = {}
function geterrorhandler() return function(message) table.insert(wow.errors, message) end end
function GetCursorPosition() return state.cursorX, state.cursorY end
function UnitGUID(unit)
  if state.units[unit] and state.units[unit].guid then return state.units[unit].guid end
  return state.guid
end
function GetZoneText() return state.zone end
-- Nur die C_CombatLog-Variante: das globale CombatLogGetCurrentEventInfo ist im Client ein
-- Kompatibilitäts-Alias, der ohne CVar loadDeprecationFallbacks fehlt
C_CombatLog = { GetCurrentEventInfo = function() return unpack(state.combatLog) end }
function time(dateTable)
  if dateTable then return os.time(dateTable) end
  return state.clock
end
function UnitName(unit)
  if unit == nil or unit == "player" then return state.name end
  return state.units[unit] and state.units[unit].name
end
function UnitExists(unit) return unit == "player" or state.units[unit] ~= nil end
function UnitIsPlayer(unit) return unit == "player" or (state.units[unit] and state.units[unit].isPlayer) or false end
function UnitClassification(unit) return state.units[unit] and state.units[unit].classification or "normal" end
function GetRealmName() return state.realm end
function UnitClass() return state.class, state.class end
function UnitRace() return state.race[1], state.race[2], state.race[3] end
function UnitIsDeadOrGhost() return state.dead end
function UnitHealth() return state.health end
function IsInGuild() return state.inGuild end
function GetBuildInfo() return "12.1.5", "1", "2026-01-01", state.interface end
function UnitAffectingCombat() return state.inCombat end
function UnitOnTaxi() return state.onTaxi end
-- Bekannte Zauber (IsPlayerSpell): state.knownSpells[spellId] = true
function IsPlayerSpell(spellId) return (state.knownSpells or {})[spellId] == true end
function UnitIsDead(unit) return state.units[unit] ~= nil and state.units[unit].dead == true end
-- Temporäre Waffen-Verzauberung der Haupthand: state.mainHandEnchant = true
function GetWeaponEnchantInfo() return state.mainHandEnchant == true end
function GetInventoryItemCount(_, slot) return state.inventoryCounts[slot] or 0 end
function GetInventoryItemDurability(slot)
  local entry = state.durability[slot]
  if not entry then return nil end
  return entry[1], entry[2]
end
function UnitIsAFK() return state.afk end
function IsResting() return state.resting end
C_Spell = {
  GetSpellName = function(spellID) return state.spellNames[spellID] end,
  GetSpellTexture = function(spellID) return "Interface\Icons\Spell_" .. spellID end,
}
-- Beschränkte Auren (Retail/Forever, z.B. Bosskampf): wie im Client bricht die Abfrage mit Fehler ab
C_Secrets = { ShouldAurasBeSecret = function() return state.aurasSecret == true end }
C_UnitAuras = {
  GetAuraDataByIndex = function(_, index)
    if state.aurasSecret then
      error("GetAuraDataByIndex(): Auras cannot be accessed when secret while tainted by 'LevelTimer'")
    end
    local buff = state.buffs[index]
    if type(buff) == "string" then return { name = buff } end
    return buff
  end,
}
function IsInGroup() return state.inGroup end
-- Bedrohung des Spielers (UnitThreatSituation): state.threat = 0..3 oder nil; Rolle: state.role
function UnitThreatSituation(unit) if unit == "player" then return state.threat end end
function UnitGroupRolesAssigned() return state.role or "NONE" end
-- Gesendete Chat-Nachrichten landen in wow.sentChat als { message, chatType }
wow.sentChat = {}
-- Load-on-Demand-Addons (LevelTimer_Archive): LoadAddOn führt die Dateien der .toc aus und meldet ADDON_LOADED.
-- state.addOnsUnavailable[name] = true wie ein fehlendes oder ausgeschaltetes Addon; wow.addOnLoads zählt Ladevorgänge.
wow.addOnLoads = {}
local loadedAddOns = {}
C_AddOns = {
  IsAddOnLoaded = function(name) return loadedAddOns[name] == true end,
  LoadAddOn = function(name)
    if loadedAddOns[name] then return true end
    if (state.addOnsUnavailable or {})[name] then return false, "DISABLED" end
    local toc = io.open(ADDON_DIR .. "/" .. name .. "/" .. name .. ".toc")
    if not toc then return false, "MISSING" end
    local namespace = {}
    for line in toc:lines() do
      line = line:gsub("\r", ""):gsub("\\", "/")
      if line ~= "" and not line:match("^#") then
        local chunk, err = loadfile(ADDON_DIR .. "/" .. name .. "/" .. line)
        if not chunk then error(err, 0) end
        chunk(name, namespace)
      end
    end
    toc:close()
    loadedAddOns[name] = true
    wow.addOnLoads[name] = (wow.addOnLoads[name] or 0) + 1
    wow.fire("ADDON_LOADED", name)
    return true
  end,
}

C_ChatInfo = {
  SendChatMessage = function(message, chatType) table.insert(wow.sentChat, { message = message, chatType = chatType }) end,
  InChatMessagingLockdown = function() return state.chatLockdown end,
}
-- Klassenlehrer: state.trainer.services = { { name, serviceType, texture, reqLevel, subText } }
-- Forever liefert name, serviceType, texture, reqLevel, subText; Era/TBC name, subText, serviceType und Level/Symbol einzeln
function GetNumTrainerServices() return #state.trainer.services end
function GetTrainerServiceInfo(index)
  local service = state.trainer.services[index]
  if state.interface == 16001 then
    return service.name, service.serviceType, service.texture, service.reqLevel, service.subText
  end
  return service.name, service.subText, service.serviceType, false
end
function GetTrainerServiceLevelReq(index) return state.trainer.services[index].reqLevel end
function GetTrainerServiceIcon(index) return state.trainer.services[index].texture end
function IsTradeskillTrainer() return state.trainer.tradeskill or false end
function UnitHealthMax() return state.healthMax end
function UnitPowerMax() return state.powerMax end
-- UnitStat: Basiswert, Gesamtwert, positive und negative Buffs
function UnitStat(_, index)
  local value = state.stats[index] or 0
  local buff = state.statBuffs[index] or 0
  return value, value + buff, math.max(buff, 0), math.min(buff, 0)
end
function GetPVPSessionStats() return state.honorableKills end
function IsShiftKeyDown() return state.shiftDown end
function RequestTimePlayed() end
-- Nur C_CurrencyInfo: das globale GetCoinTextureString ist im Client ein Kompatibilitäts-Alias
C_CurrencyInfo = { GetCoinTextureString = function(copper) return copper .. "c" end }
function GetTitleText() return state.questTitle end
function IsInInstance()
  if state.instance then return true, state.instance.type end
  return false, "none"
end
function UnitFactionGroup() return state.faction end
function GetBattlefieldWinner() return state.battlefieldWinner end
function GetInstanceInfo()
  if not state.instance then return GetZoneText() end
  return state.instance.name, state.instance.type, state.instance.difficulty or 1
end
C_QuestLog = {
  GetTitleForQuestID = function(questID) return state.questTitles[questID] end,
  IsQuestTrivial = function(questID) return state.trivialQuests[questID] or false end,
}
function GetQuestID() return state.questID or 0 end
function strtrim(text) return (text:gsub("^%s+", ""):gsub("%s+$", "")) end
-- Wie im Client: Funktion ersetzen, Original zuerst, dann der Hook
function hooksecurefunc(target, nameOrHook, maybeHook)
  local owner, name, hook = _G, target, nameOrHook
  if type(target) == "table" then owner, name, hook = target, nameOrHook, maybeHook end
  local original = owner[name]
  owner[name] = function(...)
    local results = { original(...) }
    hook(...)
    return unpack(results)
  end
end

-- Geldänderung durch den Server: kommt wie im Client erst später, mit PLAYER_MONEY (wow.runTimers)
local function serverMoneyUpdate(delta)
  C_Timer.After(0, function()
    state.money = state.money + delta
    wow.fire("PLAYER_MONEY")
  end)
end

-- Händler; RepairAllItems bucht die Kosten ab (mit PLAYER_MONEY) und merkt sich die Reparatur in wow.repairs
wow.repairs = {}
function CanMerchantRepair() return state.merchant.canRepair end
function GetRepairAllCost() return state.merchant.repairCost, state.merchant.repairCost > 0 end
-- Gildenreparatur gelingt nur, wenn das, was die Gilde dem Charakter zahlt (merchant.guildFunds:
-- Abhebelimit bzw. Bankstand), die Kosten deckt; sonst bleibt alles kaputt wie im Client
function RepairAllItems(useGuildBank)
  local merchant = state.merchant
  local cost = merchant.repairCost
  if useGuildBank then
    if merchant.guildFunds < cost then return end
    merchant.guildFunds = merchant.guildFunds - cost
  else
    serverMoneyUpdate(-cost)
  end
  table.insert(wow.repairs, { cost = cost, guild = useGuildBank and true or false })
  merchant.repairCost = 0
end
function CanGuildBankRepair() return state.merchant.guildRepair end
-- Nur bekannt, wenn die Gildenbank in dieser Sitzung offen war; das Addon verlässt sich nicht darauf
function GetGuildBankMoney() return 0 end

-- Taschen; UseContainerItem verkauft (Händler offen angenommen): Gegenstand weg, Geld dazu (PLAYER_MONEY)
C_Container = {
  GetContainerNumSlots = function(bag) return state.bags[bag] and state.bagSlots or 0 end,
  GetContainerItemInfo = function(bag, slot) return state.bags[bag] and state.bags[bag][slot] end,
  GetContainerNumFreeSlots = function(bag)
    local entry = state.freeSlots[bag]
    if not entry then return 0, 0 end
    return entry[1], entry[2]
  end,
  UseContainerItem = function(bag, slot)
    local info = state.bags[bag][slot]
    state.bags[bag][slot] = nil
    serverMoneyUpdate((state.sellPrices[info.itemID] or 0) * info.stackCount)
  end,
}
-- Quest-Aktionen landen in wow.questActions, z.B. { "accept" } oder { "selectAvailable", 123 }
wow.questActions = {}
local function questAction(...) table.insert(wow.questActions, { ... }) end
function QuestFlagsPVP() return state.questPvp end
function QuestGetAutoAccept() return state.questAutoAccept end
function AcceptQuest() questAction("accept") end
function AcknowledgeAutoAcceptQuest() questAction("acknowledge") end
function ConfirmAcceptQuest() questAction("confirm") end
function StaticPopup_Hide(name) questAction("hidePopup", name) end
-- Abgelehnte Anfragen landen in wow.declined (Name der Funktion)
wow.declined = {}
for _, name in ipairs({ "CancelTrade", "DeclineGroup", "DeclineGuild", "CancelDuel" }) do
  _G[name] = function() table.insert(wow.declined, name) end
end
C_GossipInfo = {
  GetAvailableQuests = function() return state.gossip.available end,
  GetActiveQuests = function() return state.gossip.active end,
  GetOptions = function() return state.gossip.options end,
  GetNumAvailableQuests = function() return #state.gossip.available end,
  GetNumActiveQuests = function() return #state.gossip.active end,
  ForceGossip = function() return false end,
  SelectAvailableQuest = function(questID) questAction("selectAvailable", questID) end,
  SelectActiveQuest = function(questID) questAction("selectActive", questID) end,
  SelectOptionByIndex = function(index) questAction("selectOption", index) end,
}
function GetNumAvailableQuests() return #state.greeting.available end
function GetAvailableQuestInfo(index)
  local quest = state.greeting.available[index]
  return quest.isTrivial, quest.frequency, quest.isRepeatable
end
function SelectAvailableQuest(index) questAction("greetingAvailable", index) end
function GetNumActiveQuests() return #state.greeting.active end
function GetActiveTitle(index)
  local quest = state.greeting.active[index]
  return quest.title, quest.isComplete
end
function SelectActiveQuest(index) questAction("greetingActive", index) end
function IsQuestCompletable() return state.questCompletable end
function CompleteQuest() questAction("complete") end
function GetQuestMoneyToGet() return state.questMoney end
function GetNumQuestChoices() return #state.questChoices end
function GetQuestItemLink(kind, index) return kind == "choice" and state.questChoices[index] or nil end
function GetQuestReward(choice) questAction("reward", choice) end

C_Item = {
  -- itemID oder Link; Verkaufspreis aus state.sellPrices
  GetItemInfo = function(itemID)
    return "Item " .. itemID, nil, nil, nil, nil, nil, nil, nil, nil, nil, state.sellPrices[itemID]
  end,
  -- Wie im Client: nichts für unbekannte IDs, sonst itemID, Typ, Untertyp, Platz, Symbol, Klasse, Unterklasse
  GetItemInfoInstant = function(itemID)
    local icon = state.itemIcons[itemID]
    if not icon then return nil end
    return itemID, "Rüstung", "Leder", "INVTYPE_FEET", icon, 4, 2
  end,
}

---------------------------------------------------------------------------
-- Addon laden
---------------------------------------------------------------------------
addon = {}
for line in io.lines(ADDON_DIR .. "/LevelTimer.toc") do
  line = line:gsub("\r", ""):gsub("\\", "/")  -- .toc-Pfade mit \ wie bei Blizzard
  if line ~= "" and not line:match("^#") then
    local chunk, err = loadfile(ADDON_DIR .. "/" .. line)
    if not chunk then error(err, 0) end
    chunk("LevelTimer", addon)
  end
end

-- Schwester-Addon StreamGoal (Szenarien streamgoal_*): eigener Namespace, hängt wie im Client von LevelTimer ab
if (SCENARIO or ""):match("^streamgoal_") then
  streamGoal = {}
  for line in io.lines(ADDON_DIR .. "/StreamGoal/StreamGoal.toc") do
    line = line:gsub("\r", ""):gsub("\\", "/")
    if line ~= "" and not line:match("^#") then
      local chunk, err = loadfile(ADDON_DIR .. "/StreamGoal/" .. line)
      if not chunk then error(err, 0) end
      chunk("StreamGoal", streamGoal)
    end
  end
end

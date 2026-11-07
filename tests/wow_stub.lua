-- Nachgebaute WoW-API für die Addon-Tests (ausgeführt von tools/addontest).
-- Lädt das Addon in .toc-Reihenfolge. Jede *_test.lua läuft danach in einem frischen Lua-Zustand.
-- Die WoW-Globals stehen nach API-Bereichen in tests/stub/*.lua (Oberfläche, Chat, Einheiten, Addons, Spieler,
-- Komfort, Geld/Händler/Quests, Sozial/NPCs); neue API-Funktionen in den passenden Bereich.
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
    -- Interface-Version (GetBuildInfo): Szenarien forever_* laden als WoW Forever (16001), era_* als Classic Era
    -- (11509), alle anderen als Retail
    interface = (SCENARIO or ""):match("^forever_") and 16001 or (SCENARIO or ""):match("^era_") and 11509 or 120105,
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
    -- Sozial: Charakter-Freunde (Name oder GUID), Battle.net-Freunde (GUID), Gildenmitglieder (Name),
    -- offene Battle.net-Freundschaftsanfragen { inviteID, accountName }, Battle.net-Konten je ID (accountInfo)
    friends = {}, bnetFriends = {}, guildMembers = {}, friendInvites = {}, bnetAccounts = {},
    clubs = {},              -- Communities { clubId, clubType, members = { { name, guid, isSelf } } }
    groupLeader = false,     -- UnitIsGroupLeader("player")
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
  -- Scrollbereiche: Position wird gemerkt; Bereich = frame._scrollRange (Standard groß genug für jede Seite)
  SetVerticalScroll = function(self, offset) self._verticalScroll = offset end,
  GetVerticalScroll = function(self) return rawget(self, "_verticalScroll") or 0 end,
  GetVerticalScrollRange = function(self) return rawget(self, "_scrollRange") or 10000 end,
  GetAlpha = function(self) return rawget(self, "_alpha") or 1 end,
  SetAlpha = function(self, alpha) self._alpha = alpha end,
  GetScale = function(self) return self._scale end,
  SetScale = function(self, scale) self._scale = scale end,
  GetLeft = function() return 100 end,
  GetTop = function() return 500 end,
  SetNormalTexture = function(self, texture) self._normalTexture = texture end,
  -- Mit Nummer: gemerkter Anker (SetPoint), ohne wie bisher ein fester Mittelpunkt
  GetPoint = function(self, index)
    if index then return unpack(self._points[index] or {}) end
    return "CENTER", nil, "CENTER", 0, 0
  end,
  GetNumPoints = function(self) return #self._points end,
  SetParent = function(self, parent) self._parent = parent end,
  EnableMouse = function(self, enabled) self._mouse = enabled and true or false end,
  IsMouseEnabled = function(self) return rawget(self, "_mouse") == true end,
  EnableMouseWheel = function(self, enabled) self._mouseWheel = enabled and true or false end,
  IsMouseWheelEnabled = function(self) return rawget(self, "_mouseWheel") == true end,
  -- Chatfenster und Eingabezeilen: Standard wie im Client an (Verblassen, Alt für Pfeiltasten)
  GetFading = function(self) return rawget(self, "_fading") ~= false end,
  SetFading = function(self, fading) self._fading = fading and true or false end,
  GetAltArrowKeyMode = function(self) return rawget(self, "_altArrows") ~= false end,
  SetAltArrowKeyMode = function(self, mode) self._altArrows = mode and true or false end,
  -- Texturfarbe (z.B. Symbole der Aktionsknöpfe); Standard weiß
  SetVertexColor = function(self, r, g, b, a) self._vertexColor = { r, g, b, a or 1 } end,
  GetVertexColor = function(self) return unpack(rawget(self, "_vertexColor") or { 1, 1, 1, 1 }) end,
  SetBackdropColor = function(self, r, g, b, a) self._backdropColor = { r, g, b, a } end,
  SetBackdropBorderColor = function(self, r, g, b, a) self._borderColor = { r, g, b, a } end,
  SetColorTexture = function(self, r, g, b, a) self._colorTexture = { r, g, b, a or 1 } end,
  SetTextColor = function(self, r, g, b, a) self._textColor = { r, g, b, a or 1 } end,
  -- Anker werden nur gemerkt (frame._points), nicht ausgewertet
  SetPoint = function(self, ...) table.insert(self._points, { ... }) end,
  ClearAllPoints = function(self) self._points = {} end,
  GetCenter = function() return 0, 0 end,
  GetEffectiveScale = function() return 1 end,
  IsShown = function(self) return self._shown end,
  -- Sichtbar = gezeigt samt aller Eltern (UIParent gilt als sichtbar)
  IsVisible = function(self)
    local parent = rawget(self, "_parent")
    return self._shown and (parent == nil or parent == UIParent or parent:IsVisible()) or false
  end,
  GetParent = function(self) return rawget(self, "_parent") end,
  -- Wie im Client: OnShow beim Wechsel von versteckt zu gezeigt
  Show = function(self)
    local wasShown = self._shown
    self._shown = true
    local onShow = self._scripts and self._scripts.OnShow
    if not wasShown and onShow then onShow(self) end
  end,
  Hide = function(self)
    local wasShown = self._shown
    self._shown = false
    local onHide = self._scripts and self._scripts.OnHide
    if wasShown and onHide then onHide(self) end
  end,
  SetShown = function(self, shown) self._shown = shown and true or false end,
  SetText = function(self, text) self._text = tostring(text) end,
  SetFontObject = function(self, font) self._fontObject = font end,
  GetText = function(self) return self._text end,
  SetFocus = function(self) wow.focus = self end,
  ClearFocus = function(self) if wow.focus == self then wow.focus = nil end end,
  HasFocus = function(self) return wow.focus == self end,
  GetChecked = function(self) return self._checked end,
  SetChecked = function(self, checked) self._checked = checked end,
  SetScript = function(self, name, handler) self._scripts[name] = handler end,
  -- Attribute sicherer Knöpfe; im Kampf wie im Client verboten (Fehler), Tests prüfen so die Kampfsperre
  SetAttribute = function(self, name, value)
    if wow.state.combatLockdown then error("ADDON_ACTION_BLOCKED: SetAttribute in combat") end
    self._attributes = rawget(self, "_attributes") or {}
    self._attributes[name] = value
  end,
  GetAttribute = function(self, name) return (rawget(self, "_attributes") or {})[name] end,
  -- Wie im Client: vorhandenen Handler behalten und den neuen danach aufrufen
  HookScript = function(self, name, handler)
    local previous = self._scripts[name]
    self._scripts[name] = previous and function(...) previous(...); handler(...) end or handler
  end,
  AddLine = function(self, text) self._lines = rawget(self, "_lines") or {}; table.insert(self._lines, text) end,
  ClearLines = function(self) self._lines = {} end,
  SetOwner = function(self) self._lines = {} end,
  SetHyperlink = function(self, link) self._hyperlink = link end,
  RegisterEvent = function(self, event)
    if event == UNKNOWN_EVENT then error("Attempt to register unknown event") end
    self._events[event] = true
  end,
  -- Wie im Client: das Event kommt nur noch für diese Einheiten (wow.fire prüft das erste Argument)
  RegisterUnitEvent = function(self, event, ...)
    if event == UNKNOWN_EVENT then error("Attempt to register unknown event") end
    self._events[event] = true
    self._unitEvents = rawget(self, "_unitEvents") or {}
    self._unitEvents[event] = { ... }
    wow.unitEventRegistrations = (wow.unitEventRegistrations or 0) + 1
    return true
  end,
  UnregisterEvent = function(self, event)
    self._events[event] = nil
    if rawget(self, "_unitEvents") then self._unitEvents[event] = nil end
  end,
  IsEventRegistered = function(self, event) return self._events[event] == true end,
}

local function noop() end

-- Texturen merken Datei oder Atlas (SetUnitCursorTexture im Test schreibt so das Zeiger-Symbol)
frameMethods.SetTexture = function(self, texture) self._texture = texture end
frameMethods.GetTexture = function(self) return rawget(self, "_texture") end
frameMethods.GetAtlas = function(self) return rawget(self, "_atlas") end

-- Animationen: nur Abspielzustand (group:IsPlaying) und Skripte (OnLoop, OnFinished); Werte werden nicht ausgewertet.
-- frame._animationGroups listet die Gruppen eines Frames bzw. einer Textur für Prüfungen.
local function newAnimationGroup()
  local group = { _playing = false, _scripts = {}, _animations = {} }
  group.Play = function(self) self._playing = true end
  group.Stop = function(self) self._playing = false end
  group.IsPlaying = function(self) return self._playing end
  group.SetScript = function(self, name, handler) self._scripts[name] = handler end
  group.GetScript = function(self, name) return self._scripts[name] end
  group.CreateAnimation = function(self, kind)
    local animation = setmetatable({ _kind = kind }, { __index = function() return noop end })
    table.insert(self._animations, animation)
    return animation
  end
  return setmetatable(group, { __index = function() return noop end })
end

frameMethods.CreateAnimationGroup = function(self)
  local group = newAnimationGroup()
  self._animationGroups = rawget(self, "_animationGroups") or {}
  table.insert(self._animationGroups, group)
  return group
end

local function newFrame()
  local frame = {
    _shown = true, _scripts = {}, _events = {}, _text = "",
    _width = 200, _height = 100, _scale = 1, _checked = false, _normalTexture = "", _points = {},
  }
  -- Font-Objekt (Name) gemerkt: frame._fontObject, auch nach SetFontObject
  frame.CreateFontString = function(_, _, _, font)
    local fontString = newFrame()
    fontString._fontObject = font
    return fontString
  end
  frame.CreateTexture = function() return newFrame() end
  frame.CreateLine = function() return newFrame() end
  table.insert(frames, frame)
  return setmetatable(frame, {
    -- false in frameMethods = Methode fehlt in diesem Client (nil statt No-Op)
    __index = function(_, key)
      local method = frameMethods[key]
      if method == false then return nil end
      return method or noop
    end,
  })
end

-- Szenarien no_unit_events*: Client ohne Frame:RegisterUnitEvent (Rückfall: selbst nach Einheit filtern)
if (SCENARIO or ""):match("^no_unit_events") then frameMethods.RegisterUnitEvent = false end

-- Unit-Event für eine andere Einheit als angemeldet?
local function filteredUnitEvent(frame, event, unit)
  local unitEvents = rawget(frame, "_unitEvents")
  local units = unitEvents and unitEvents[event]
  if not units then return false end
  for _, wanted in ipairs(units) do
    if wanted == unit then return false end
  end
  return true
end

function wow.fire(event, ...)
  for _, frame in ipairs(frames) do
    if frame._events[event] and frame._scripts.OnEvent and not filteredUnitEvent(frame, event, ...) then
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

-- Steuerelement der Einstellungen zu einem Locale-Key klicken, eindeutig über den Suchindex (Tooltip <KEY>_TIP),
-- auch wenn mehrere Buttons denselben Text haben (z.B. "Vorschau")
function wow.clickOption(labelKey)
  for _, entry in ipairs(addon.OptionsWindow.Search(addon.L[labelKey])) do
    local onClick = entry.tipKey == labelKey .. "_TIP" and entry.left._scripts.OnClick
    if onClick then
      onClick(entry.left, "LeftButton")
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

-- Nachgebaute API nach Bereichen (tests/stub/*.lua), in dieser Reihenfolge wie zuvor in einer Datei
local stub = { state = state, newFrame = newFrame, ADDON_DIR = ADDON_DIR }
for _, part in ipairs({ "ui", "chat", "units", "addons", "player", "comfort", "economy", "social" }) do
  local chunk, err = loadfile(ADDON_DIR .. "/tests/stub/" .. part .. ".lua")
  if not chunk then error(err, 0) end
  chunk(stub)
end

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

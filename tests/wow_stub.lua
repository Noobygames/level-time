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
  GetParent = function(self) return self._parent end,
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

-- Buffs ändern sich im Client nie ohne UNIT_AURA: wow.state.buffs = { ... } meldet das Event für den Spieler
-- (der Aura-Schnappschuss in Lib/Auras.lua liest erst danach neu)
do
  local buffs = state.buffs
  state.buffs = nil
  setmetatable(state, {
    __index = function(_, key) if key == "buffs" then return buffs end end,
    __newindex = function(self, key, value)
      if key ~= "buffs" then return rawset(self, key, value) end
      buffs = value
      wow.fire("UNIT_AURA", "player")
    end,
  })
end

-- Benannte Frames landen wie im Client als Global (z.B. LevelTimerFrame)
CreateFrame = function(_, name, parent)
  local frame = newFrame()
  frame._parent = parent
  if name then _G[name] = frame end
  return frame
end
UIParent, Minimap, GameTooltip, GameFontNormalLarge = newFrame(), newFrame(), newFrame(), newFrame()
-- Font-Objekte: CreateFont legt ein benanntes an; SetFont/GetFont merken Schrift, Größe und Flags, CopyFontObject
-- übernimmt sie (Blizzards Objekte haben im Stub FRIZQT__ in 12)
local function newFont()
  local font = newFrame()
  font._font = { "Fonts\FRIZQT__.TTF", 12, "" }
  font.SetFont = function(self, face, size, flags) self._font = { face, size, flags } end
  font.GetFont = function(self) return unpack(self._font) end
  font.CopyFontObject = function(self, source) self._font = { source:GetFont() } end
  return font
end
function CreateFont(name)
  local font = newFont()
  if name then _G[name] = font end
  return font
end
GameFontNormal, GameFontHighlight, GameFontNormalSmall = newFont(), newFont(), newFont()
GameFontHighlightSmall, GameFontNormalHuge = newFont(), newFont()
-- Fehlerfenster und Zonentext; UIErrorsFrame merkt Meldungen in _messages
UIErrorsFrame, ZoneTextFrame, SubZoneTextFrame = newFrame(), newFrame(), newFrame()
UIErrorsFrame._events.UI_ERROR_MESSAGE = true
UIErrorsFrame._messages = {}
-- Lösch-Dialog und Filme: StaticPopup1 (.which, Eingabefeld), CinematicFrame mit Bestätigung
StaticPopup1, StaticPopup1EditBox = newFrame(), newFrame()
StaticPopup1.GetName = function() return "StaticPopup1" end
StaticPopup1._shown = false
CinematicFrame, CinematicFrameCloseDialogConfirmButton = newFrame(), newFrame()
CinematicFrameCloseDialogConfirmButton.Click = function(self) self._clicks = (rawget(self, "_clicks") or 0) + 1 end
DELETE_ITEM_CONFIRM_STRING = "LÖSCHEN"

UIErrorsFrame.AddMessage = function(self, text) table.insert(self._messages, text) end
ERR_INV_FULL = "Inventar ist voll."

UISpecialFrames, SlashCmdList = {}, {}
StaticPopupDialogs, YES, NO = {}, "Ja", "Nein"
-- Dialog nicht anzeigen, sondern merken; Tests bestätigen mit StaticPopupDialogs[name].OnAccept
function StaticPopup_Show(name, textArg1, textArg2, data)
  wow.popup = { name = name, text = textArg1, data = data }
end
COMBATLOG_XPGAIN_FIRSTPERSON = "%s stirbt, Ihr bekommt %d Erfahrung."
COMBATLOG_XPGAIN_EXHAUSTION1 = "%s stirbt, Ihr bekommt %d Erfahrung. (%s EP-Bonus durch %s)"
ERR_ZONE_EXPLORED_XP = "%1$s entdeckt: %2$d Erfahrung erhalten."
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
-- Würfeln um Beute wie im deutschen Classic-Era-Client (Ketho/BlizzardInterfaceResources classic_era deDE)
LOOT_ROLL_ALL_PASSED = "|HlootHistory:%d|h[Beute]|h: Alle haben gepasst auf: %s"
LOOT_ROLL_DISENCHANT = "%s hat für '%s' Entzauberung gewählt."
LOOT_ROLL_DISENCHANT_SELF = "|HlootHistory:%d|h[Beute]|h: Ihr habt für %s Entzauberung gewählt."
LOOT_ROLL_GREED = "|HlootHistory:%d|h[Beute]|h: %s hat für %s Gier ausgewählt"
LOOT_ROLL_GREED_SELF = "|HlootHistory:%d|h[Beute]|h: Ihr habt für %s Gier ausgewählt"
LOOT_ROLL_LOST_ROLL = "|HlootHistory:%d|h[Beute]|h: Ihr habt %s - %d gewürfelt auf: %s"
LOOT_ROLL_NEED = "|HlootHistory:%d|h[Beute]|h: %s hat für %s Bedarf ausgewählt"
LOOT_ROLL_NEED_SELF = "|HlootHistory:%d|h[Beute]|h: Ihr habt für %s Bedarf ausgewählt"
LOOT_ROLL_PASSED = "|HlootHistory:%d|h[Beute]|h: %s passt auf: %s"
LOOT_ROLL_PASSED_AUTO = "|HlootHistory:%d|h[Beute]|h: %s passt automatisch auf %s, weil er den Gegenstand nicht benutzen kann."
LOOT_ROLL_PASSED_SELF = "|HlootHistory:%d|h[Beute]|h: Ihr habt gepasst auf: %s"
LOOT_ROLL_ROLLED_GREED = "|HlootHistory:%d|h[Beute]|h: Wurf für Gier: %d für %s von %s"
LOOT_ROLL_ROLLED_NEED = "|HlootHistory:%d|h[Beute]|h: Wurf für Bedarf: %d für %s von %s"
LOOT_ROLL_STARTED = "|HlootHistory:%d|h[Beute]|h: %s"
LOOT_ROLL_WON = "|HlootHistory:%d|h[Beute]|h: %s gewinnt: %s"
LOOT_ROLL_WON_NO_SPAM_NEED = "|HlootHistory:%d|h[Beute]|h: %s hat gewonnen: %s |cff818181(Bedarf - %d)|r"
LOOT_ROLL_YOU_WON = "|HlootHistory:%d|h[Beute]|h: Ihr gewinnt: %s"
LOOT_ROLL_YOU_WON_NO_SPAM_NEED = "|HlootHistory:%d|h[Beute]|h: Ihr habt gewonnen: %s |cff818181(Bedarf - %d)|r"
-- Rufmeldungen (Retail-Form; Classic: "Your %s reputation has increased by %d.")
FACTION_STANDING_INCREASED = "Euer Ruf bei der Fraktion '%s' hat sich um %d verbessert."
FACTION_STANDING_INCREASED_ACCOUNT_WIDE = "Der Ruf Eurer Kriegsmeute bei der Fraktion '%s' hat sich um %d verbessert."
FACTION_STANDING_INCREASED_ACH_BONUS = "Euer Ruf bei der Fraktion '%s' hat sich um %d verbessert. (+%.1f Bonus)"
FACTION_STANDING_INCREASED_GENERIC = "Euer Ruf bei der Fraktion '%s' hat sich verbessert."
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
  chatFrame.AddMessage = function(self, text) table.insert(self._messages, text) end
  chatFrame.GetName = function() return "ChatFrame" .. index end
  -- Eingabezeile, Knopfleiste und Reiter wie in FloatingChatFrame.xml
  chatFrame.editBox = newFrame()
  chatFrame.editBox:SetPoint("TOPLEFT", chatFrame, "BOTTOMLEFT", -5, -2)
  chatFrame.buttonFrame = newFrame()
  chatFrame.buttonFrame._parent = chatFrame
  _G["ChatFrame" .. index] = chatFrame
  _G["ChatFrame" .. index .. "Tab"] = newFrame()
end
CHAT_FRAMES = { "ChatFrame1", "ChatFrame2" }
-- Nachrichtenfilter wie Blizzards ChatFrameUtil; wow.chatFiltered(event, ...) = true, wenn ein Filter verwirft
wow.chatFilters = {}
ChatFrameUtil = {
  AddMessageEventFilter = function(event, filter)
    wow.chatFilters[event] = wow.chatFilters[event] or {}
    table.insert(wow.chatFilters[event], filter)
  end,
}
function wow.chatFiltered(event, ...)
  for _, filter in ipairs(wow.chatFilters[event] or {}) do
    if filter(ChatFrame1, event, ...) then return true end
  end
  return false
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
-- Andere Einheiten: units[unit].level, sonst die Stufe des Spielers
function UnitLevel(unit)
  local other = unit and unit ~= "player" and state.units[unit]
  if other and other.level then return other.level end
  return state.level
end
function UnitXP() return state.xp end
function UnitXPMax() return state.xpMax end
function GetMaxPlayerLevel() return state.maxLevel end
function GetXPExhaustion() return state.rested > 0 and state.rested or nil end
function GetMoney() return state.money end
function GetTime() return state.now end
-- Profiler-Uhr in Millisekunden: läuft mit GetTime; wow.profileMs schiebt sie zusätzlich vor (teurer Handler)
wow.profileMs = 0
function debugprofilestop() return state.now * 1000 + wow.profileMs end
-- Aufrufstapel wie im Client ("Datei.lua:Zeile: in function ...", ab dem Aufrufer), aus gopher-luas traceback
function debugstack()
  local trace = debug and debug.traceback and debug.traceback() or ""
  return (trace:gsub("^stack traceback:%s*[^\n]*\n", ""))
end
-- Geheime Werte (Retail/Forever): Tests setzen wow.SECRET als Rückgabe einer API
wow.SECRET = setmetatable({}, { __tostring = function() return "<secret>" end })
function issecretvalue(value) return value == wow.SECRET end
-- xpcall wie im WoW-Client (reicht Argumente durch) für Szenarien native_xpcall_*; sonst Lua 5.1 wie gopher-lua
if (SCENARIO or ""):match("^native_xpcall") then
  local luaXpcall = xpcall
  function xpcall(fn, handler, ...)
    local count, args = select("#", ...), { ... }
    return luaXpcall(function() return fn(unpack(args, 1, count)) end, handler)
  end
end
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
-- Andere Einheiten: units[unit].class, sonst die Klasse des Spielers
function UnitClass(unit)
  local other = unit and unit ~= "player" and state.units[unit]
  local class = other and other.class or state.class
  return class, class
end
function UnitIsUnit(a, b) return a == b or (state.units[a] ~= nil and state.units[a] == state.units[b]) end
-- Reaktionsfarbe (UnitSelectionColor): units[unit].selection oder gelb
function UnitSelectionColor(unit)
  local color = state.units[unit] and state.units[unit].selection or { 1, 1, 0 }
  return color[1], color[2], color[3]
end
RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 }, MAGE = { r = 0.25, g = 0.78, b = 0.92 } }
function UnitRace() return state.race[1], state.race[2], state.race[3] end
function UnitIsDeadOrGhost() return state.dead end
function UnitHealth() return state.health end
function IsInGuild() return state.inGuild end
function GetBuildInfo() return "12.1.5", "1", "2026-01-01", state.interface end
-- Spieler: state.inCombat; andere Einheiten: state.units[unit].combat
function UnitAffectingCombat(unit)
  if unit == nil or unit == "player" then return state.inCombat end
  return state.units[unit] ~= nil and state.units[unit].combat == true
end
function UnitIsGhost() return state.ghost == true end
function UnitOnTaxi() return state.onTaxi end
-- Kampfsperre für geschützte Frames (InCombatLockdown); unabhängig von inCombat, damit ältere Szenarien gleich bleiben
function InCombatLockdown() return state.combatLockdown == true end
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
-- Einzelne Auren per Spell-ID: state.secretSpellAuras[id] = true sperrt sie; aktiv ist eine Spell-ID, wenn ein Buff
-- in state.buffs sie trägt
C_Secrets = {
  ShouldAurasBeSecret = function() return state.aurasSecret == true end,
  ShouldSpellAuraBeSecret = function(spellId) return (state.secretSpellAuras or {})[spellId] == true end,
}
C_UnitAuras = {
  GetPlayerAuraBySpellID = function(spellId)
    for _, buff in ipairs(state.buffs) do
      if type(buff) == "table" and buff.spellId == spellId then return buff end
    end
    return nil
  end,
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
-- Gruppengröße samt Spieler (state.groupSize), Schlachtzug (state.inRaid)
function GetNumGroupMembers() return state.groupSize or (state.inGroup and 2 or 0) end
function IsInRaid() return state.inRaid == true end
-- Bedrohung des Spielers (UnitThreatSituation): state.threat = 0..3 oder nil; Rolle: state.role
function UnitThreatSituation(unit) if unit == "player" then return state.threat end end
function UnitGroupRolesAssigned() return state.role or "NONE" end
-- Gegner: units[unit].hostile (UnitCanAttack), units[unit].tanking (1. Wert von UnitDetailedThreatSituation),
-- Ziel des Gegners als units[unit .. "target"]
function UnitCanAttack(_, unit) return state.units[unit] ~= nil and state.units[unit].hostile == true end
function UnitDetailedThreatSituation(_, unit)
  local enemy = state.units[unit]
  if enemy == nil then return nil end
  return enemy.tanking
end
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

-- Addon-Nachrichten: wow.addonMessages = { { prefix, message, chatType, target } }, wow.addonPrefixes
wow.addonMessages = {}
wow.addonPrefixes = {}
function NotifyInspect() end
-- Screenshot(): wow.screenshots zählt die Aufnahmen
wow.screenshots = 0
function Screenshot() wow.screenshots = wow.screenshots + 1 end
function GetUnitName(unit, showServer)
  local name = UnitName(unit)
  local realm = state.units[unit] and state.units[unit].realm
  if showServer and name and realm then return name .. "-" .. realm end
  return name
end
C_ChatInfo = {
  RegisterAddonMessagePrefix = function(prefix) wow.addonPrefixes[prefix] = true; return 0 end,
  SendAddonMessage = function(prefix, message, chatType, target)
    table.insert(wow.addonMessages, { prefix = prefix, message = message, chatType = chatType, target = target })
    return 0
  end,
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
-- Kosten je Zeile (service.cost); gekaufte Zeilen in wow.trained (Nummer)
wow.trained = {}
function GetTrainerServiceCost(index) return state.trainer.services[index].cost or 0 end
function BuyTrainerService(index) table.insert(wow.trained, index) end
function UnitHealthMax() return state.healthMax end
function UnitPowerMax() return state.powerMax end
-- Mana: state.power (aktuell), state.powerMax
function UnitPower() return state.power or 0 end
-- Spiegel-Leisten (Atem, Erschöpfung): state.mirrorProgress[timer] = Rest in ms; Blinken zählt wow.flashes
function GetMirrorTimerProgress(timer) return (state.mirrorProgress or {})[timer] end
wow.flashes = 0
function FlashClientIcon() wow.flashes = wow.flashes + 1 end
ERR_OUT_OF_MANA = "Nicht genug Mana"
-- Kontrollverlust: state.lossOfControl = { { locType, displayText, timeRemaining, displayType }, ... }
C_LossOfControl = {
  GetActiveLossOfControlDataCount = function() return #(state.lossOfControl or {}) end,
  GetActiveLossOfControlData = function(index) return (state.lossOfControl or {})[index] end,
}

-- UnitStat: Basiswert, Gesamtwert, positive und negative Buffs
function UnitStat(_, index)
  local value = state.stats[index] or 0
  local buff = state.statBuffs[index] or 0
  return value, value + buff, math.max(buff, 0), math.min(buff, 0)
end
function GetPVPSessionStats() return state.honorableKills end
function IsShiftKeyDown() return state.shiftDown end
function IsControlKeyDown() return state.controlDown == true end
-- Aktionsplätze: state.actions[platz] = { "item"/"spell"/"macro", id } (GetActionInfo)
function GetActionInfo(slot)
  local action = (state.actions or {})[slot]
  if action then return action[1], action[2] end
end
function IsModifiedClick() return state.modifiedClick == true end
-- CVars: state.cvars[name] (Text); GetCVarBool wie im Client "1" = true
function GetCVar(name) return (state.cvars or {})[name] end
function SetCVar(name, value) state.cvars = state.cvars or {}; state.cvars[name] = tostring(value) end
function GetCVarBool(name) return GetCVar(name) == "1" end
-- Beschwörung: state.summon = { summoner, area }; Aufrufe landen in wow.comfortActions
wow.comfortActions = {}
local function comfortAction(...) table.insert(wow.comfortActions, { ... }) end
C_SummonInfo = {
  GetSummonConfirmSummoner = function() return state.summon and state.summon.summoner end,
  GetSummonConfirmAreaName = function() return state.summon and state.summon.area end,
  ConfirmSummon = function() comfortAction("confirmSummon") end,
}
function AcceptResurrect() comfortAction("acceptResurrect") end
function RepopMe() comfortAction("repop") end
C_DeathInfo = { GetSelfResurrectOptions = function() return state.selfResurrect or {} end }
-- Beute: state.lootSlots = Anzahl; LootSlot merkt den Platz
-- Flugkarte: state.taxiNodes = { { name, type, x, y, id, hops } } (type "CURRENT", "REACHABLE", ...; x/y wie
-- TaxiNodePosition; id = nodeID aus C_TaxiMap.GetAllTaxiNodes, ohne id liefert der Client den Knoten dort nicht;
-- hops = { { vonSlot, nachSlot }, ... } Teilstrecken, Standard eine direkte vom CURRENT-Knoten); state.taxiMapID
function NumTaxiNodes() return #(state.taxiNodes or {}) end
function TaxiNodeName(index) return state.taxiNodes[index].name end
function TaxiNodeGetType(index) return state.taxiNodes[index].type end
function TaxiNodePosition(index) local node = state.taxiNodes[index]; return node.x or 0, node.y or 0 end
function TakeTaxiNode() end
function GetTaxiMapID() return state.taxiMapID or 0 end
local function taxiHops(index)
  local node = state.taxiNodes[index]
  if node.hops then return node.hops end
  for slot, other in ipairs(state.taxiNodes) do
    if other.type == "CURRENT" then return { { slot, index } } end
  end
  return {}
end
function GetNumRoutes(index) return #taxiHops(index) end
function TaxiGetNodeSlot(index, hop, source)
  local part = taxiHops(index)[hop]
  return source and part[1] or part[2]
end
C_TaxiMap = {
  GetAllTaxiNodes = function()
    local nodes = {}
    for slot, node in ipairs(state.taxiNodes or {}) do
      if node.id then table.insert(nodes, { nodeID = node.id, slotIndex = slot, name = node.name }) end
    end
    return nodes
  end,
}
-- Blizzards Tooltip der Flugpunkte (TaxiFrame), damit Hooks darauf greifen
function TaxiNodeOnButtonEnter(button)
  GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
  GameTooltip:AddLine(TaxiNodeName(button:GetID()))
end
function GetNumLootItems() return state.lootSlots or 0 end
function LootSlot(slot) comfortAction("loot", slot) end
function ConfirmLootRoll(rollID, rollType) comfortAction("confirmRoll", rollID, rollType) end
-- Würfeln um Beute: state.lootRolls[rollID] = { link, name, texture, quality }, state.activeLootRolls = { rollID, ... }
function GetLootRollItemLink(rollID) return ((state.lootRolls or {})[rollID] or {}).link end
function GetLootRollItemInfo(rollID)
  local roll = (state.lootRolls or {})[rollID]
  if not roll then return nil end
  return roll.texture or 134400, roll.name, 1, roll.quality or 2, false, true, true, false
end
function GetActiveLootRollIDs() return state.activeLootRolls or {} end
function GetLootRollTimeLeft() return 60000 end
-- Würfel-Historie wie im Client: Classic Era (era_*) das alte C_LootHistory (state.lootHistory = { { rollID, link,
-- isDone, winnerIdx, players = { { name, class, rollType, roll, isWinner } } } }), sonst das neue je Beute
-- (state.lootDrops["encounterID:lootListID"] = EncounterLootDropInfo, state.encounterDrops[encounterID] = Liste)
if state.interface < 20000 then
  C_LootHistory = {
    GetNumItems = function() return #(state.lootHistory or {}) end,
    GetItem = function(index)
      local item = state.lootHistory[index]
      return item.rollID, item.link, #item.players, item.isDone == true, item.winnerIdx
    end,
    GetPlayerInfo = function(index, playerIndex)
      local player = state.lootHistory[index].players[playerIndex]
      return player.name, player.class, player.rollType, player.roll, player.isWinner == true
    end,
  }
else
  C_LootHistory = {
    GetSortedInfoForDrop = function(encounterID, lootListID)
      return (state.lootDrops or {})[encounterID .. ":" .. lootListID]
    end,
    GetSortedDropsForEncounter = function(encounterID) return (state.encounterDrops or {})[encounterID] end,
  }
end
-- Blizzards Würfelfenster (GroupLootFrame1..4, versteckt; Tests setzen rollID und zeigen sie)
for index = 1, 4 do
  local frame = CreateFrame("Frame", "GroupLootFrame" .. index, UIParent)
  frame._shown = false
end
function ConfirmLootSlot(slot) comfortAction("confirmBind", slot) end
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
  IsRepeatableQuest = function(questID) return (state.repeatableQuests or {})[questID] == true end,
  -- Ziele je Quest: state.questLog[i] = { questID, title, isHeader, objectives = { { text, finished } } }
  GetQuestObjectives = function(questID)
    for _, quest in ipairs(state.questLog or {}) do
      if quest.questID == questID then return quest.objectives end
    end
  end,
}
-- Questlog wie in Classic Era/TBC (GetQuestLogTitle: 2. Level, 3. suggestedGroup, 8. questID); C_QuestLog.GetInfo
-- fehlt im Stub. Beobachtete Quests (Tracker): state.questWatches = { Log-Index, ... }
function GetNumQuestLogEntries() return #(state.questLog or {}) end
function GetQuestLogTitle(index)
  local quest = state.questLog[index]
  return quest.title, quest.level or 1, quest.suggestedGroup or 0, quest.isHeader or false, false, quest.isComplete, 0, quest.questID
end
-- Belohnungs-XP je Quest-ID: questLog[i].rewardXp
function GetQuestLogRewardXP(questID)
  for _, quest in ipairs(state.questLog or {}) do
    if quest.questID == questID then return quest.rewardXp or 0, quest.rewardXp or 0 end
  end
  return 0, 0
end
-- Quest-Item je Logeintrag: questLog[i].specialItem = { link, Symbol }
function GetQuestLogSpecialItemInfo(index)
  local item = ((state.questLog or {})[index] or {}).specialItem
  if item then return item[1], item[2], 0, false end
end
function GetNumQuestWatches() return #(state.questWatches or {}) end
function GetQuestIndexForWatch(index) return (state.questWatches or {})[index] end
function GetNumQuestLeaderBoards(index)
  local quest = (state.questLog or {})[index]
  return quest and #(quest.objectives or {}) or 0
end
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
function DeclineQuest() questAction("decline") end
-- Sichtbarer Dialog (StaticPopup_FindVisible): wow.visiblePopups[name] = Dialog-Frame
wow.visiblePopups = {}
function StaticPopup_FindVisible(name) return wow.visiblePopups[name] end
-- Abgelehnte Anfragen landen in wow.declined (Name der Funktion)
wow.declined = {}
for _, name in ipairs({ "CancelTrade", "DeclineGroup", "DeclineGuild", "CancelDuel" }) do
  _G[name] = function() table.insert(wow.declined, name) end
end
-- Sozial: Annahmen, Einladungen und abgelehnte Freundschaftsanfragen landen in wow.socialActions
wow.socialActions = {}
local function socialAction(...) table.insert(wow.socialActions, { ... }) end
function AcceptGroup() socialAction("acceptGroup") end
C_FriendList = {
  IsFriend = function(guid) return state.friends[guid] == true end,
  GetFriendInfo = function(name) if state.friends[name] then return { name = name } end end,
}
C_BattleNet = {
  GetAccountInfoByGUID = function(guid) if state.bnetFriends[guid] then return { isFriend = true } end end,
  GetAccountInfoByID = function(id) return state.bnetAccounts[id] end,
  GetFriendInviteInfo = function(index) return state.friendInvites[index] end,
  InviteFriend = function(gameAccountID) socialAction("bnetInvite", gameAccountID) end,
}
C_GuildInfo = { MemberExistsByName = function(name) return state.guildMembers[name] == true end }
C_PartyInfo = { InviteUnit = function(name) socialAction("invite", name) end }
function BNGetNumFriendInvites() return #state.friendInvites end
function BNDeclineFriendInvite(inviteID)
  for index, invite in ipairs(state.friendInvites) do
    if invite.inviteID == inviteID then table.remove(state.friendInvites, index) end
  end
  socialAction("declineFriend", inviteID)
end
function UnitIsGroupLeader() return state.groupLeader end
-- Spieler-Infos je GUID: state.playerInfo[guid] = { localizedClass, englishClass, localizedRace, englishRace, ... }
function GetPlayerInfoByGUID(guid)
  local info = (state.playerInfo or {})[guid]
  if info then return unpack(info) end
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
function GetAvailableTitle(index) return state.greeting.available[index].title end
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
-- 5. Wert isUsable: state.questChoiceUnusable[i] = true für nicht benutzbare Wahlen
function GetQuestItemInfo(kind, index)
  if kind ~= "choice" or not state.questChoices[index] then return nil end
  return "Wahl " .. index, 134000, 1, 2, not (state.questChoiceUnusable or {})[index]
end
-- Angelegte Ausrüstung: state.equipped[platz] = Link
function GetInventoryItemLink(_, slot) return (state.equipped or {})[slot] end
function GetQuestReward(choice) questAction("reward", choice) end

C_Item = {
  GetItemCount = function(itemID) return (state.itemCounts or {})[itemID] or 0 end,
  -- itemID oder Link; Verkaufspreis aus state.sellPrices
  GetItemInfo = function(itemID)
    return "Item " .. itemID, nil, nil, nil, nil, nil, nil, nil, nil, nil, state.sellPrices[itemID]
  end,
  -- Wie im Client: nichts für unbekannte IDs, sonst itemID, Typ, Untertyp, Platz, Symbol, Klasse, Unterklasse
  GetItemInfoInstant = function(item)
    local itemID = type(item) == "string" and tonumber(item:match("item:(%d+)")) or item
    local icon = state.itemIcons[itemID]
    if not icon then return nil end
    return itemID, "Rüstung", "Leder", (state.equipLocs or {})[itemID] or "INVTYPE_FEET", icon, 4, 2
  end,
  GetItemIconByID = function(itemID) return state.itemIcons[itemID] end,
  -- Itemlevel je itemID: state.itemLevels
  GetDetailedItemLevelInfo = function(item)
    local itemID = type(item) == "string" and tonumber(item:match("item:(%d+)")) or item
    return (state.itemLevels or {})[itemID]
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

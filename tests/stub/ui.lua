-- Teil der nachgebauten WoW-API (tests/wow_stub.lua):
-- Oberfläche: Buffs, benannte Frames, Schriften, Blizzard-Rahmen, Dialoge, Einstellungsmenü, Texte der Clients.
-- Gemeinsame Helfer kommen über stub (Spielzustand, Frames).
local stub = ...
local state = stub.state
local newFrame = stub.newFrame


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
CreateFrame = function(kind, name, parent)
  local frame = newFrame()
  frame._type = kind or "Frame"
  frame._name = name
  frame._parent = parent
  if name then _G[name] = frame end
  return frame
end
function CooldownFrame_Set(self, start, duration, enable, forceShowDrawEdge, modRate)
  if self then
    self._cdStart = start
    self._cdDuration = duration
    self._cdEnable = enable
  end
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
-- Spielerrahmen: Classic-Rahmen (Szenarien era_classic_frame*) mit PlayerFrameTexture und PlayerName wie PlayerFrame.xml
if (SCENARIO or ""):match("^era_classic_frame") then
  PlayerFrame = newFrame()
  PlayerFrameTexture = PlayerFrame:CreateTexture()
  PlayerName = PlayerFrame:CreateFontString()
  PlayerFrameManaBar = newFrame()
end
-- Quest-Schriften (Blizzard_Fonts_Shared/Shared, alle Clients)
QuestFont, QuestFontLeft, QuestFontNormalSmall = newFont(), newFont(), newFont()
QuestTitleFont, QuestTitleFontBlackShadow = newFont(), newFont()
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
-- Blizzards Einstellungsmenü (alle vier Clients haben Settings): Anmeldungen in wow.settingsCategories.
-- Szenarien legacy_options*: Client ohne Settings, nur InterfaceOptions_AddCategory (wow.interfaceOptions)
wow.settingsCategories, wow.interfaceOptions = {}, {}
if (SCENARIO or ""):match("^legacy_options") then
  InterfaceOptions_AddCategory = function(frame) table.insert(wow.interfaceOptions, frame) end
else
  Settings = {
    RegisterCanvasLayoutCategory = function(frame, name)
      return { frame = frame, name = name, GetID = function() return name end }
    end,
    RegisterAddOnCategory = function(category) table.insert(wow.settingsCategories, category) end,
  }
end
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
LOOT_ITEM_PUSHED_SELF_MULTIPLE = "Ihr erhaltet einen Gegenstand: %sx%d."
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

function GetCurrentKeyBoardFocus() return wow.focus end

wow.overrideBindings = {}
function SetOverrideBindingClick(owner, isPriority, key, buttonName, mouseClick)
  wow.overrideBindings[owner] = wow.overrideBindings[owner] or {}
  wow.overrideBindings[owner][key] = { buttonName = buttonName, mouseClick = mouseClick or "LeftButton" }
end
function ClearOverrideBindings(owner)
  if owner then
    wow.overrideBindings[owner] = nil
  else
    wow.overrideBindings = {}
  end
end

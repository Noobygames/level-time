-- Schwungbalken (Roadmap 452, Reiter Komfort > Fenster; swingTimer, Standard aus): verschiebbare Leiste mit der
-- Restzeit bis zum nächsten Schlag für Haupthand, Nebenhand und Fernkampf (Automatischer Schuss, Zauberstab).
-- Nur Classic-Clients (Era, TBC, Forever); in Retail ist das Kampflog geheim.
--   Nahkampf   COMBAT_LOG_EVENT_UNFILTERED: SWING_DAMAGE (Feld 21 = isOffHand) und SWING_MISSED (Feld 13 = isOffHand)
--              des Spielers starten den Schwung neu; "beim nächsten Schlag"-Fähigkeiten (Heldenhafter Stoß, Spalten,
--              Raptorstoß, Zermalmen) kommen als SPELL_DAMAGE/SPELL_MISSED und ersetzen den Haupthand-Schlag.
--              Dauer aus UnitAttackSpeed("player") (Haupthand, Nebenhand oder nil).
--   Ersatz     Liefert das Kampflog nichts (Client sperrt es), läuft der Haupthand-Schwung ab PLAYER_ENTER_COMBAT im
--              Takt der Angriffsgeschwindigkeit weiter, bis PLAYER_LEAVE_COMBAT (Automatischer Angriff aus).
--   Fernkampf  UNIT_SPELLCAST_SUCCEEDED (player) mit Automatischer Schuss (75) oder Schießen (5019, Zauberstab),
--              Dauer aus UnitRangedDamage("player") (erster Wert).
-- shortcut: Tempo-Änderungen mitten im Schwung (Hast, Parieren) passen die laufende Restzeit nicht an; erst der
-- nächste Schlag nimmt die neue Geschwindigkeit, nachrüsten bei Rückmeldungen über ungenaue Balken.
-- Anpassbar (Roadmap 489, WoW Forever bringt eigene Schwungbalken mit): Breite/Höhe, Farbe je Hand (Akzentfarben
-- des Themes), Textur aus dem Theme (themeBarTexture), Text, Hände einzeln, nur im Kampf, Anordnung; in Forever
-- blendet swingTimerHideBlizzard Blizzards Balken über die CVar showSwingTimer (Blizzard_SwingTimer) aus.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    swingTimer = false,
    swingTimerWidth = 180,
    swingTimerHeight = 12,
    swingTimerText = "remaining",
    swingTimerLayout = "vertical",
    swingTimerMain = true,
    swingTimerOff = true,
    swingTimerRanged = true,
    swingTimerCombatOnly = false,
    swingTimerColorMain = "",
    swingTimerColorOff = "",
    swingTimerColorRanged = "",
    swingTimerHideBlizzard = false,
  },
  ranges = {
    swingTimerWidth = { 60, 400 },
    swingTimerHeight = { 6, 40 },
  },
})

local SwingTimer = {}
ns.SwingTimer = SwingTimer

SwingTimer.MAIN, SwingTimer.OFF, SwingTimer.RANGED = "main", "off", "ranged"
local HANDS = { SwingTimer.MAIN, SwingTimer.OFF, SwingTimer.RANGED }

local AUTO_SHOT, WAND_SHOOT = 75, 5019
-- Grundränge der Fähigkeiten "beim nächsten Schlag"; das Kampflog nennt den Namen, der für alle Ränge gleich ist
local NEXT_SWING_SPELLS = { 78, 845, 2973, 6807 }

SwingTimer.MIN_WIDTH, SwingTimer.MAX_WIDTH = 60, 400    -- Grenzen der Regler in den Einstellungen
SwingTimer.MIN_HEIGHT, SwingTimer.MAX_HEIGHT = 6, 40
SwingTimer.TEXT_MODES = { "remaining", "both", "none" }
SwingTimer.LAYOUTS = { "vertical", "horizontal" }
SwingTimer.COLOR_ORDER = { "", "blue", "green", "purple", "class" }  -- "" = Standardfarbe der Hand
SwingTimer.BLIZZARD_CVAR = "showSwingTimer"
-- Einstellungsschlüssel je Hand: sichtbar und Farbe
local SHOW_SETTING = { main = "swingTimerMain", off = "swingTimerOff", ranged = "swingTimerRanged" }
SwingTimer.COLOR_SETTING = { main = "swingTimerColorMain", off = "swingTimerColorOff", ranged = "swingTimerColorRanged" }

local BAR_GAP = 2
local BACKGROUND = { 0, 0, 0, 0.5 }
local COLORS = {
  main = { 0.9, 0.75, 0.2 },
  off = { 0.75, 0.55, 0.15 },
  ranged = { 0.35, 0.7, 1 },
}
local PREVIEW_PROGRESS = { main = 0.6, off = 0.3, ranged = 0.8 }
local PREVIEW_DURATION = 2

local swings = {}           -- hand -> { startedAt, duration }
local nextSwingNames = {}   -- Name -> true
local playerGUID
local autoAttacking = false
local combatLogSeen = false -- true, sobald ein eigener Schlag im Kampflog ankam
local previewing = false
local frame
local bars = {}
local shownHands = {}       -- hand -> true, wenn die Hand in den Einstellungen an ist
local textMode, combatOnly = "remaining", false

-- Spieler-Zauber verträgt keine geheimen oder fehlenden Werte: nur positive Zahlen
local function positive(value)
  if type(value) ~= "number" or ns.IsSecret(value) or value <= 0 then return nil end
  return value
end

local function meleeSpeed(hand)
  if not UnitAttackSpeed then return nil end
  local mainSpeed, offSpeed = UnitAttackSpeed("player")
  return positive(hand == SwingTimer.OFF and offSpeed or mainSpeed)
end

local function rangedSpeed()
  if not UnitRangedDamage then return nil end
  return positive((UnitRangedDamage("player")))
end

-- Schwung einer Hand starten; ohne lesbare Geschwindigkeit bleibt die Hand leer
function SwingTimer.Start(hand, now)
  local duration = hand == SwingTimer.RANGED and rangedSpeed() or meleeSpeed(hand)
  if not duration then
    swings[hand] = nil
    return
  end
  swings[hand] = { startedAt = now or GetTime(), duration = duration }
  if frame and ns.db and ns.db.swingTimer then frame:Show() end
end

-- Restzeit in Sekunden und Anteil 0..1 (1 = Schlag fällig); nil ohne laufenden Schwung
function SwingTimer.Remaining(hand, now)
  local swing = swings[hand]
  if not swing then return nil end
  local elapsed = (now or GetTime()) - swing.startedAt
  return math.max(swing.duration - elapsed, 0), math.min(elapsed / swing.duration, 1)
end

function SwingTimer.IsAvailable()
  return not ns.Client.IsRetail()
end

-- Für den Debug-Check: Kam das Kampflog an, läuft der automatische Angriff?
function SwingTimer.Status()
  return { combatLogSeen = combatLogSeen, autoAttacking = autoAttacking }
end

function SwingTimer.Frame()
  return frame
end

function SwingTimer.Bar(hand)
  return bars[hand]
end

---------------------------------------------------------------------------
-- Anzeige
---------------------------------------------------------------------------
local function createBar()
  local bar = CreateFrame("StatusBar", nil, frame)
  bar:SetMinMaxValues(0, 1)
  local background = bar:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints()
  background:SetColorTexture(unpack(BACKGROUND))
  bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  bar.text:SetPoint("CENTER")
  bar:Hide()
  return bar
end

local function barText(remaining, duration)
  if textMode == "none" then return "" end
  if textMode == "both" then return string.format("%.1f / %.1f", remaining, duration) end
  return string.format("%.1f", remaining)
end

-- Farbe einer Hand: gewählte Akzentfarbe (Theme), sonst die Standardfarbe der Hand
local function handColor(db, hand)
  local key = db[SwingTimer.COLOR_SETTING[hand]]
  if key == "class" then return ns.Theme.ClassColor(UnitClass and select(2, UnitClass("player")), COLORS[hand]) end
  return ns.Theme.ACCENTS[key] or COLORS[hand]
end

-- Größe, Anordnung, Textur und Farben aus den Einstellungen; nur eingeschaltete Hände bekommen einen Platz
local function layout(db)
  local width, height = db.swingTimerWidth, db.swingTimerHeight
  local horizontal = db.swingTimerLayout == "horizontal"
  local texture = ns.Theme.BarTexturePath(db.themeBarTexture)
  local slot = 0
  for _, hand in ipairs(HANDS) do
    local bar = bars[hand]
    shownHands[hand] = db[SHOW_SETTING[hand]] == true
    bar:SetSize(width, height)
    bar:SetStatusBarTexture(texture)
    bar:SetStatusBarColor(unpack(handColor(db, hand)))
    bar:ClearAllPoints()
    if shownHands[hand] then
      if horizontal then
        bar:SetPoint("TOPLEFT", frame, "TOPLEFT", slot * (width + BAR_GAP), 0)
      else
        bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -slot * (height + BAR_GAP))
      end
      slot = slot + 1
    end
  end
  local span = math.max(slot, 1)
  if horizontal then
    frame:SetSize(span * width + (span - 1) * BAR_GAP, height)
  else
    frame:SetSize(width, span * height + (span - 1) * BAR_GAP)
  end
  textMode, combatOnly = db.swingTimerText, db.swingTimerCombatOnly == true
end

-- Balken neu setzen; Schwünge, die abgelaufen sind, enden (Ersatzschleife: Haupthand läuft im Kampf weiter)
local function refresh()
  local now, anyShown = GetTime(), false
  -- "nur im Kampf": außerhalb des Kampfes laufen die Schwünge weiter, nur die Anzeige ruht
  local hidden = combatOnly and not previewing and not UnitAffectingCombat("player")
  for _, hand in ipairs(HANDS) do
    local bar = bars[hand]
    local remaining, progress
    local duration = PREVIEW_DURATION
    if previewing then
      progress = PREVIEW_PROGRESS[hand]
      remaining = (1 - progress) * duration
    else
      remaining, progress = SwingTimer.Remaining(hand, now)
      if remaining == 0 then
        if hand == SwingTimer.MAIN and autoAttacking and not combatLogSeen then
          SwingTimer.Start(hand, now)
          remaining, progress = SwingTimer.Remaining(hand, now)
        else
          swings[hand], remaining = nil, nil
        end
      end
      duration = swings[hand] and swings[hand].duration
    end
    if remaining and shownHands[hand] and not hidden then
      bar:SetValue(progress)
      ns.Widgets.SetTextIfChanged(bar.text, barText(remaining, duration))
      bar:Show()
      anyShown = true
    else
      bar:Hide()
    end
  end
  if not anyShown then frame:Hide() end
end

local function create()
  frame = CreateFrame("Frame", ns.GlobalName("SwingTimer"), UIParent)
  frame:Hide()
  for _, hand in ipairs(HANDS) do bars[hand] = createBar() end
  -- jedes Bild, solange sichtbar: der Balken soll flüssig laufen, drei SetValue-Aufrufe sind billig
  ns.SetUpdateScript(frame, "SwingTimer", refresh)
end
create()

ns.Frames.Register({
  id = "swingTimer",
  frame = frame,
  label = "SWING_TIMER",
  labelKey = "SWING_TIMER",
  default = { "CENTER", "CENTER", 0, -180 },
  defaultScale = 1,
  settingsPage = "comfort",
  clickable = true,
  dragWhenUnlocked = true,
  actionsTip = true,
  preview = function(editing)
    previewing = editing == true
    if previewing then frame:Show() end
    refresh()
  end,
  hide = function() ns.Set("swingTimer", false) end,
})

---------------------------------------------------------------------------
-- Ereignisse
---------------------------------------------------------------------------
local getCombatLogEventInfo = (C_CombatLog and C_CombatLog.GetCurrentEventInfo) or CombatLogGetCurrentEventInfo
local isSecret = issecretvalue  -- nil in Clients ohne geheime Werte

-- Läuft für jedes Kampflog-Event: zuerst der billigste Abbruch (Quelle ist nicht der Spieler)
local function onCombatLogEvent()
  local ok, _, subevent, _, sourceGUID, _, _, _, _, _, _, _, arg12, arg13, _, _, _, _, _, _, _, arg21 =
    pcall(getCombatLogEventInfo)
  if not ok or (isSecret and isSecret(sourceGUID)) or sourceGUID ~= playerGUID or not playerGUID then return end
  if subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED" then
    local offHand = subevent == "SWING_DAMAGE" and arg21 or arg13
    if isSecret and isSecret(offHand) then return end
    combatLogSeen = true
    SwingTimer.Start(offHand == true and SwingTimer.OFF or SwingTimer.MAIN)
  elseif (subevent == "SPELL_DAMAGE" or subevent == "SPELL_MISSED")
    and not (isSecret and isSecret(arg13)) and nextSwingNames[arg13] then
    combatLogSeen = true
    SwingTimer.Start(SwingTimer.MAIN)
  end
end

local combatLogFrame = CreateFrame("Frame")
ns.SetEventScript(combatLogFrame, "COMBAT_LOG_EVENT_UNFILTERED SwingTimer", onCombatLogEvent)

local function setCombatLog(active)
  if not getCombatLogEventInfo then return end
  if active then
    pcall(combatLogFrame.RegisterEvent, combatLogFrame, "COMBAT_LOG_EVENT_UNFILTERED")
  else
    combatLogFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  end
end

local events = ns.NewEventGroup()
events.Add("PLAYER_ENTER_COMBAT", nil, function()
  autoAttacking = true
  ns.Debug("swing", "auto attack on, combat log seen %s", combatLogSeen)
  if not combatLogSeen then SwingTimer.Start(SwingTimer.MAIN) end
end)
events.Add("PLAYER_LEAVE_COMBAT", nil, function()
  autoAttacking = false
end)
events.Add("UNIT_SPELLCAST_SUCCEEDED", "player", function(_, _, spellId)
  if ns.IsSecret(spellId) then return end
  if spellId == AUTO_SHOT or spellId == WAND_SHOOT then SwingTimer.Start(SwingTimer.RANGED) end
end)

ns.OnLogin(function()
  playerGUID = UnitGUID("player")
  if ns.IsSecret(playerGUID) then playerGUID = nil end
  for _, spellId in ipairs(NEXT_SWING_SPELLS) do
    local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellId)
    if type(name) == "string" and not ns.IsSecret(name) then nextSwingNames[name] = true end
  end
end)

ns.RegisterApply(function(db)
  local active = db.swingTimer == true and SwingTimer.IsAvailable()
  layout(db)
  events.SetActive(active)
  setCombatLog(active)
  -- Blizzards eigene Schwungbalken (nur Forever kennt die CVar; anderswo übergeht CVars sie)
  if active and db.swingTimerHideBlizzard then
    ns.CVars.Override(SwingTimer.BLIZZARD_CVAR, "0")
  else
    ns.CVars.Restore(SwingTimer.BLIZZARD_CVAR)
  end
  if not active then
    swings[SwingTimer.MAIN], swings[SwingTimer.OFF], swings[SwingTimer.RANGED] = nil, nil, nil
    autoAttacking = false
    if not previewing then frame:Hide() end
  end
end)

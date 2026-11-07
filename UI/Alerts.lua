-- Große Einblendungen oben in der Bildschirmmitte für Stream-Momente: Level-Up, Rare- und Elite-Kill,
-- epische Beute, Beinahe-Tod. Jede Art ist einzeln schaltbar (Einstellungen alert*), alle aus.
-- Aussehen: alertStyle (Text oder Banner = Karte mit Symbol, Lib/Card.lua), alertScale, alertDuration, alertSound; Position alertPos
-- (ziehen im Verschiebemodus, Alerts.SetMoving). Dieselbe Einblendung zeigt auch Hinweise (Alerts.Notify).
-- Quellen: ns.OnLevelStarted und neue Journal-Einträge (Journal.OnAdd), kein eigenes Event-Parsing.
-- In Dungeons und Raids ist fast jeder Gegner Elite: dort keine Elite-Einblendung (IsInInstance).
-- In Raids ist epische Beute normal: dort keine Beute-Einblendung.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Journal = ns.Journal
local Classification = ns.Classification

local Alerts = {}
ns.Alerts = Alerts

local FADE_IN_SECONDS = 0.25  -- weich einblenden
local FADE_SECONDS = 1       -- nach der Anzeigedauer ausblenden
local DEFAULT_POSITION = { "TOP", "TOP", 0, -160 }
local EPIC_QUALITY = 4
local GROUP_INSTANCES = { party = true, raid = true }  -- Instanzarten von IsInInstance mit Elite-Gegnern
local RAID_WARNING_SOUND = 8959  -- SOUNDKIT.RAID_WARNING, in allen Clients gleich
-- Einstellung alertStyle: nur Text oder Banner (Karte mit Symbol wie die Hinweise)
Alerts.STYLE_TEXT = "text"
Alerts.STYLE_BANNER = "banner"
Alerts.MIN_SCALE = 0.5
Alerts.MAX_SCALE = 2
Alerts.MIN_DURATION = 1
Alerts.MAX_DURATION = 10
local MAX_TEXT_WIDTH = 520   -- längere Texte brechen um
local MAX_QUEUE = 4          -- wartende Einblendungen; bei mehr fällt die älteste weg
local QUEUED_HOLD = 1.5      -- Anzeigedauer, solange weitere warten
local COLORS = {
  levelUp = { 1, 0.82, 0 },
  rare = { 0.75, 0.75, 1 },
  elite = { 1, 0.5, 0.1 },
  loot = { 0.64, 0.21, 0.93 },
  nearDeath = { 1, 0.25, 0.25 },
  quest = { 0.45, 1, 0.45 },
}
Alerts.WARNING_COLOR = { 1, 0.6, 0.2 }   -- Hinweise beim Leveln (fehlende Buffs, Taschen, ...)
Alerts.REMINDER_COLOR = COLORS.levelUp   -- Hinweise zum Level-Up (Lehrer)

local frame = CreateFrame("Frame", "LevelTimerAlert", UIParent)
frame:SetSize(1, 1)
frame:SetPoint(DEFAULT_POSITION[1], UIParent, DEFAULT_POSITION[2], DEFAULT_POSITION[3], DEFAULT_POSITION[4])
frame:SetFrameStrata("HIGH")
frame:SetClampedToScreen(true)

frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
frame.text:SetPoint("CENTER")
frame:Hide()

-- Hinweise (Buffs, Taschen, Haltbarkeit, ...) erscheinen als Karte mit Symbol, Titel und Text (Lib/Card.lua) an
-- derselben Stelle wie das Banner; Größe, Dauer, Position und Warteschlange sind gemeinsam
local notice = ns.Card.Create("LevelTimerNotice")
notice.frame:SetFrameStrata("HIGH")
notice.frame:SetPoint("TOP", frame, "TOP")

local function iconPath(name)
  return "Interface\\Icons\\" .. name
end

-- Symbole der Hinweise: Zahl = Spell-ID (Textur aus dem Client), sonst Pfad eines Symbols, das es in allen Clients gibt
Alerts.ICONS = {
  food = 19705,   -- Satt
  camp = 1229741, -- Lagervorteile (WoW Forever)
  charged = 1270893, -- Aufgeladen (Himmelsgeborene, WoW Forever)
  bags = iconPath("INV_Misc_Bag_08"),
  durability = iconPath("INV_Misc_Gear_01"),
  aggro = iconPath("Ability_Warrior_Charge"),
  ammo = iconPath("INV_Ammo_Arrow_02"),
  trainer = iconPath("INV_Misc_Book_09"),
  instanceLimit = iconPath("INV_Misc_PocketWatch_01"),
  levelUp = iconPath("Spell_Holy_HolyBolt"),
  rare = iconPath("INV_Misc_Eye_01"),
  elite = iconPath("INV_Misc_Head_Dragon_01"),
  loot = iconPath("INV_Misc_Gem_Amethyst_02"),
  nearDeath = iconPath("INV_Misc_Bone_HumanSkull_01"),
  breath = iconPath("Spell_Shadow_DemonBreath"),
  fatigue = iconPath("Spell_Nature_Sleep"),
  rest = iconPath("INV_Misc_PocketWatch_02"),
  questComplete = iconPath("INV_Misc_Note_01"),
  questObjective = iconPath("INV_Misc_Note_01"),
  questLog = iconPath("INV_Misc_Book_09"),
  rareSpotted = iconPath("INV_Misc_Eye_01"),
}

local shownAt
local moving  -- Verschiebemodus: bleibt stehen und lässt sich ziehen

local function isBanner()
  return ns.db and ns.db.alertStyle == Alerts.STYLE_BANNER
end

-- Text-Stil: der Rahmen ist nur so groß wie der Text
local function layout()
  frame.text:SetWidth(0)  -- erst natürliche Breite, dann bei Bedarf umbrechen
  local width = frame.text:GetStringWidth() or 0
  if width > MAX_TEXT_WIDTH then
    frame.text:SetWidth(MAX_TEXT_WIDTH)
    width = MAX_TEXT_WIDTH
  end
  frame.text:SetShadowOffset(2, -2)
  frame:SetSize(math.max(1, width), math.max(1, frame.text:GetStringHeight() or 0))
end

local function setColor(color)
  frame.text:SetTextColor(unpack(color))
end

local function duration()
  return math.max(Alerts.MIN_DURATION, math.min(Alerts.MAX_DURATION, ns.db and ns.db.alertDuration or 3))
end

local queue = {}  -- { message, color, sound, notice, sample } der wartenden Einblendungen, älteste zuerst
local current     -- die gerade sichtbare echte Einblendung (gleicher Aufbau), nil bei Beispielen oder nichts
local held = {}   -- Einblendungen aus dem Kampf: { message, color, options }, kommen nach dem Kampf

-- Der Raid-Warnton; auch für andere Anzeigen (z.B. Lagerfeuer), wenn der Spieler Ton eingeschaltet hat
function Alerts.PlaySound()
  if PlaySound then PlaySound(RAID_WARNING_SOUND) end
end

local function isShowing()
  return frame:IsShown() or notice.frame:IsShown()
end

-- spec = { icon, texture, title, body }: als Karte statt als Banner (texture siehe Card.Set)
local function display(message, color, sound, spec, sample)
  current = not sample and { message, color, sound, spec } or nil
  local shown
  if spec then
    frame:Hide()
    notice.Set({ color = color, icon = spec.icon, texture = spec.texture, title = spec.title, body = spec.body })
    shown = notice.frame
  else
    notice.frame:Hide()
    frame.text:SetText(message)
    setColor(color)
    layout()
    shown = frame
  end
  shownAt = GetTime()
  shown:SetAlpha(0)
  shown:Show()
  local playSound = sound and ns.db and ns.db.alertSound
  ns.Debug("alert", "shown %s: card %s, icon %s, sample %s, sound %s, waiting %s, duration %s, scale %s",
    message, spec ~= nil, spec and (spec.icon or spec.texture), sample == true, playSound and true or false, #queue,
    duration(), shown:GetScale())
  if playSound then Alerts.PlaySound() end
end

-- Einblenden, halten, ausblenden; danach die nächste wartende (Banner und Karte teilen sich den Ablauf)
local function fade(self)
  if moving then return end
  local age = GetTime() - shownAt
  -- Warten weitere Einblendungen, ist die laufende kürzer zu sehen
  local hold = #queue > 0 and math.min(duration(), QUEUED_HOLD) or duration()
  if age >= hold + FADE_SECONDS then
    local nextAlert = table.remove(queue, 1)
    if nextAlert then
      display(unpack(nextAlert, 1, 5))
    else
      current = nil
      self:Hide()
    end
  elseif age > hold then
    self:SetAlpha(1 - (age - hold) / FADE_SECONDS)
  elseif age < FADE_IN_SECONDS then
    self:SetAlpha(age / FADE_IN_SECONDS)
  else
    self:SetAlpha(1)
  end
end

ns.SetUpdateScript(frame, "Alerts", fade)
ns.SetUpdateScript(notice.frame, "AlertNotice", fade)

-- Einblendung zeigen; läuft schon eine, wartet die neue (höchstens MAX_QUEUE). options = { immediate = ersetzt die
-- laufende und leert die Warteschlange, sound = Ton, falls eingeschaltet, notice = { icon, title, body } zeigt eine
-- Karte statt des Banners, combat = "hold" (im Kampf zurückhalten, nach dem Kampf zeigen) oder "skip" (im Kampf
-- verwerfen) }. Im Verschiebemodus erscheint nichts Neues.
function Alerts.Show(message, color, options)
  ns.Debug("alert", "%s", message)
  options = options or {}
  if options.combat and ns.InCombat() then
    if options.combat == "hold" then
      if #held >= MAX_QUEUE then table.remove(held, 1) end
      table.insert(held, { message, color, options })
    end
    ns.Debug("alert", "in combat: %s", options.combat)
    return
  end
  if options.immediate then queue = {} end
  -- Im Verschiebemodus wartet alles Neue (auch die erste Einblendung) und erscheint nach dem Verschieben
  if moving or (isShowing() and not options.immediate) then
    if #queue >= MAX_QUEUE then table.remove(queue, 1) end
    table.insert(queue, { message, color, options.sound, options.notice })
    ns.Debug("alert", "queued (%s waiting, moving %s)", #queue, moving or false)
    return
  end
  display(message, color, options.sound, options.notice)
end

-- Laufende und wartende Einblendungen verwerfen
function Alerts.Clear()
  queue = {}
  held = {}
  current = nil
  if not moving then
    frame:Hide()
    notice.frame:Hide()
  end
end

---------------------------------------------------------------------------
-- Position: ziehen im Verschiebemodus, gespeichert in alertPos
---------------------------------------------------------------------------
local mover = Widgets.CreateMover(frame, {
  default = DEFAULT_POSITION,
  get = function() return ns.db and ns.db.alertPos end,
  set = function(pos) ns.db.alertPos = pos end,
  onMovingChanged = function(isMoving)
    moving = isMoving
    if isMoving then
      if notice.frame:IsShown() then
        -- Banner-Stil: Das sichtbare Beispiel ist die Karte; der (sonst versteckte) Rahmen bekommt ihre Größe und
        -- unsichtbar die Ziehgriffe, die Karte hängt an ihm
        notice.frame:SetAlpha(1)
        frame:SetSize(notice.frame:GetWidth(), notice.frame:GetHeight())
        frame:SetAlpha(0)
        frame:Show()
      else
        frame:SetAlpha(1)
      end
      return
    end
    frame:SetSize(1, 1)
    frame:Hide()
    notice.frame:Hide()
    current = nil
    local waiting = table.remove(queue, 1)
    if waiting then display(unpack(waiting, 1, 5)) end
  end,
})

function Alerts.IsMoving()
  return moving or false
end

-- Verschiebemodus: Beispiel bleibt stehen, Ziehen verschiebt, Rechtsklick oder erneuter Aufruf beendet
function Alerts.SetMoving(enabled)
  enabled = enabled and true or false
  if enabled == (moving or false) then return end
  if enabled then
    local card = isBanner() and { title = L.ALERT_MOVE_HINT } or nil
    Alerts.Show(L.ALERT_MOVE_HINT, COLORS.levelUp, { immediate = true, notice = card })  -- noch nicht im Modus: wird gezeigt
  end
  mover.SetMoving(enabled)
end

function Alerts.ResetPosition()
  mover.Reset()
end

-- Karte zu einem Hinweis: mit Titel steht der Text als Zeile darunter, ohne Titel ist der Text der Titel
local function noticeCard(entry)
  return { icon = entry.icon, title = entry.title or entry.text, body = entry.title and entry.text or nil }
end

-- Hinweis an den Spieler: jede Nachricht als Chatzeile und als Karte (mehrere warten nacheinander).
-- notices = Text, { text, title, icon } oder eine Liste davon; icon siehe Alerts.ICONS
function Alerts.Notify(notices, color)
  if type(notices) == "string" or notices.text then notices = { notices } end
  for _, entry in ipairs(notices) do
    if type(entry) == "string" then entry = { text = entry } end
    ns.Print(entry.text)
    Alerts.Show(entry.text, color, { notice = noticeCard(entry) })
  end
end

-- Arten: Einstellung, inCombat ("hold" = im Kampf zurückhalten und danach zeigen), Farbe, Symbol (Alerts.ICONS), Text aus einem Wert (Level, Name, Link, Prozent) und Beispielwert
-- für /lt debug alert
Alerts.KINDS = {
  levelUp = { setting = "alertLevelUp", color = COLORS.levelUp, format = "ALERT_LEVEL_UP", inCombat = "hold",
    sample = function() return ns.level + 1 end,
    sampleBody = function() local gains = ns.LevelGains.Sample(); return gains and table.concat(ns.LevelGains.Lines(gains), "\n") end },
  rare = { setting = "alertRareKill", color = COLORS.rare, format = "ALERT_RARE_KILL",
    sample = function() return "Hogger" end },
  elite = { setting = "alertEliteKill", color = COLORS.elite, format = "ALERT_ELITE_KILL",
    sample = function() return "Hogger" end },
  loot = { setting = "alertEpicLoot", color = COLORS.loot, format = "ALERT_EPIC_LOOT",
    sample = function() return "[Thunderfury]" end },
  nearDeath = { setting = "alertNearDeath", color = COLORS.nearDeath, format = "ALERT_NEAR_DEATH",
    sample = function() return 4 end },
  questComplete = { setting = "alertQuestComplete", color = COLORS.quest, format = "ALERT_QUEST_COMPLETE", inCombat = "hold",
    sample = function() return "Hogger" end },
  rareSpotted = { setting = "alertRareSpotted", color = COLORS.rare, format = "ALERT_RARE_SPOTTED",
    sample = function() return "Mor'Ladim" end },
  questObjective = { setting = "alertQuestObjective", color = COLORS.quest, format = "ALERT_QUEST_OBJECTIVE", inCombat = "hold",
    sample = function() return "Hogger: 1/1" end },
}

-- Text und Karte einer Art: im Stil "Banner" als Karte mit Symbol (wie die Hinweise), im Stil "Text" nur als Schrift
local function kindMessage(kind, value, body)
  local message = string.format(L[Alerts.KINDS[kind].format], value)
  return message, isBanner() and { icon = Alerts.ICONS[kind], title = message, body = body } or nil
end

-- Nur, wenn die Art eingeschaltet ist
local function alert(kind, value, body)
  local definition = Alerts.KINDS[kind]
  if not ns.db[definition.setting] then return end
  local message, card = kindMessage(kind, value, body)
  Alerts.Show(message, definition.color, { sound = true, notice = card, combat = definition.inCombat })
end

-- Einblendung einer Art für andere Module (Quest fertig, ...), nur wenn die Art eingeschaltet ist
function Alerts.Raise(kind, value, body)
  alert(kind, value, body)
end

-- Beispiel (Vorschau, /lt debug alert) sofort zeigen, ohne wartende echte Einblendungen zu verwerfen: eine gerade
-- sichtbare echte kommt vorne zurück in die Warteschlange und erscheint nach dem Beispiel noch einmal ganz
local function showSample(message, color, card, sound)
  if moving then
    -- Im Verschiebemodus wartet auch das Beispiel und erscheint nach dem Verschieben
    if #queue >= MAX_QUEUE then table.remove(queue, 1) end
    table.insert(queue, { message, color, sound, card, true })
    return
  end
  if current then table.insert(queue, 1, current) end
  while #queue > MAX_QUEUE do table.remove(queue) end
  display(message, color, sound, card, true)
end

-- Beispiel unabhängig von der Einstellung (Fehlersuche); false bei unbekannter Art
function Alerts.ShowSample(kind)
  local definition = Alerts.KINDS[kind]
  if not definition then return false end
  local body = ns.db.levelUpGains and definition.sampleBody and definition.sampleBody() or nil
  local message, card = kindMessage(kind, definition.sample(), body)
  showSample(message, definition.color, card, true)
  return true
end

-- Erst wenn der Zuwachs feststeht (LevelGains), damit die Karte Leben und Werte zeigen kann
ns.LevelGains.OnReady(function(level, gains)
  if ns.db.levelUpWindow then return end  -- das Level-Up-Fenster zeigt dieselben Zuwächse
  local lines = ns.db.levelUpGains and gains and ns.LevelGains.Lines(gains)
  alert("levelUp", level, lines and table.concat(lines, "\n") or nil)
end)

local function instanceType()
  local inInstance, kind = IsInInstance()
  return inInstance and kind or nil
end

local handlers = {
  killLog = function(entry)
    local name = entry.name or L.UNKNOWN_NAME
    if Classification.IsRare(entry.classification) and ns.db.alertRareKill then
      alert("rare", name)
    elseif Classification.IsElite(entry.classification) and not GROUP_INSTANCES[instanceType()] then
      alert("elite", name)
    end
  end,
  lootLog = function(entry)
    if (entry.quality or 0) >= EPIC_QUALITY and instanceType() ~= "raid" then
      alert("loot", entry.link or entry.name or "?")
    end
  end,
  nearDeathLog = function(entry)
    alert("nearDeath", entry.lowestPercent)
  end,
}

Journal.OnAdd(function(logName, entry)
  local handler = handlers[logName]
  if handler then handler(entry) end
end)

-- Vorschau: eine Beispiel-Einblendung mit den aktuellen Einstellungen
local PREVIEW_ORDER = { "levelUp", "rare", "elite", "loot", "nearDeath", "notice" }
local previewIndex = 0

-- Beispiel einer Hinweis-Karte (wie "Taschen fast voll"), ohne Chatzeile
local function showNoticeSample()
  local sample = { icon = Alerts.ICONS.bags, title = L.NOTICE_BAGS, text = L.WARN_BAGS_FULL }
  showSample(sample.text, Alerts.WARNING_COLOR, noticeCard(sample))
end

function Alerts.Preview()
  if moving then Alerts.SetMoving(false) end
  previewIndex = previewIndex % #PREVIEW_ORDER + 1
  local kind = PREVIEW_ORDER[previewIndex]
  if kind == "notice" then showNoticeSample() else Alerts.ShowSample(kind) end
end

ns.RegisterApply(function(db)
  local scale = math.max(Alerts.MIN_SCALE, math.min(Alerts.MAX_SCALE, db.alertScale))
  mover.SetScale(scale)
  notice.frame:SetScale(scale)
  mover.Sync()
  layout()
end)

ns.OnLogin(mover.Restore)
ns.OnLogout(function() moving = false end)

-- Kampf vorbei: zurückgehaltene Einblendungen zeigen (Reihenfolge bleibt)
ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
  local waiting = held
  held = {}
  if #waiting > 0 then ns.Debug("alert", "combat over, showing %s held", #waiting) end
  for _, entry in ipairs(waiting) do
    local options = entry[3]
    Alerts.Show(entry[1], entry[2], { sound = options.sound, notice = options.notice })
  end
end)

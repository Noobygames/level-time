-- Große Einblendungen oben in der Bildschirmmitte: Warteschlange, Anzeige (Banner oder Karte) und Hinweise
-- (Alerts.Notify). Aussehen: alertStyle (Text oder Banner = Karte mit Symbol, Lib/Card.lua), alertDuration, alertSound.
-- Die Arten samt Auslösern (Level-Up, Rare, Elite, Beute, ...) stehen in UI/AlertTriggers.lua, Position und
-- Edit-Modus in UI/AlertPosition.lua.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    alertLevelUp = false,
    alertRareKill = false,
    alertEliteKill = false,
    alertEpicLoot = false,
    alertNearDeath = false,
    alertStyle = "banner",
    alertDuration = 3,
    alertSound = false,
  },
  ranges = {
    alertDuration = { 1, 10 },
  },
})

local Alerts = {}
ns.Alerts = Alerts

local FADE_IN_SECONDS = 0.25  -- weich einblenden
local FADE_SECONDS = 1       -- nach der Anzeigedauer ausblenden
local RAID_WARNING_SOUND = SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959  -- in allen Clients gleich
-- Einstellung alertStyle: nur Text oder Banner (Karte mit Symbol wie die Hinweise)
Alerts.STYLE_TEXT = "text"
Alerts.STYLE_BANNER = "banner"
Alerts.MIN_DURATION = 1
Alerts.MAX_DURATION = 10
local MAX_TEXT_WIDTH = 520   -- längere Texte brechen um
local MAX_QUEUE = 4          -- wartende Einblendungen; bei mehr fällt die älteste weg
local QUEUED_HOLD = 1.5      -- Anzeigedauer, solange weitere warten
local Theme = ns.Theme
Alerts.COLORS = {
  levelUp = Theme.COLORS.gold,
  rare = { 0.75, 0.75, 1 },
  elite = { 1, 0.5, 0.1 },
  loot = { 0.64, 0.21, 0.93 },
  nearDeath = Theme.COLORS.bad,
  quest = Theme.COLORS.success,
}
Alerts.WARNING_COLOR = Theme.COLORS.warning   -- Hinweise beim Leveln (fehlende Buffs, Taschen, ...)
Alerts.REMINDER_COLOR = Alerts.COLORS.levelUp   -- Hinweise zum Level-Up (Lehrer)

Alerts.DEFAULT_POSITION = { "TOP", "TOP", 0, -160 }
local DEFAULT_POSITION = Alerts.DEFAULT_POSITION

local frame = CreateFrame("Frame", ns.GlobalName("Alert"), UIParent)
Alerts.frame = frame  -- Banner-Rahmen; an ihm hängen Position und Größe (UI/AlertPosition.lua)
frame:SetSize(1, 1)
frame:SetPoint(DEFAULT_POSITION[1], UIParent, DEFAULT_POSITION[2], DEFAULT_POSITION[3], DEFAULT_POSITION[4])
frame:SetFrameStrata("HIGH")
frame:SetClampedToScreen(true)

frame.text = frame:CreateFontString(nil, "OVERLAY", Theme.Font("huge"))
frame.text:SetPoint("CENTER")
frame:Hide()

-- Hinweise (Buffs, Taschen, Haltbarkeit, ...) erscheinen als Karte mit Symbol, Titel und Text (Lib/Card.lua) an
-- derselben Stelle wie das Banner; Größe, Dauer, Position und Warteschlange sind gemeinsam
local notice = ns.Card.Create(ns.GlobalName("Notice"))
notice.frame:SetFrameStrata("HIGH")
notice.frame:SetPoint("TOP", frame, "TOP")
Alerts.noticeFrame = notice.frame

local function iconPath(name)
  return "Interface\\Icons\\" .. name
end

-- Symbole der Hinweise: Zahl = Spell-ID (Textur aus dem Client), sonst Pfad eines Symbols, das es in allen Clients gibt
Alerts.ICONS = {
  food = 19705,   -- Satt
  camp = 1229741, -- Lagervorteile (WoW Forever)
  charged = 1270893, -- Aufgeladen (Himmelsgeborene, WoW Forever)
  sleepingBag = iconPath("INV_Misc_Bag_10"),  -- Rückfall, falls der Client das Schlafsack-Symbol nicht liefert
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
local moving  -- Edit-Modus: ein Beispiel bleibt stehen

function Alerts.IsBanner()
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
  local seconds = ns.db and ns.db.alertDuration or ns.Database.SettingDefault("alertDuration")
  return math.max(Alerts.MIN_DURATION, math.min(Alerts.MAX_DURATION, seconds))
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
-- verwerfen) }. Im Edit-Modus erscheint nichts Neues.
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
  -- Im Edit-Modus wartet alles Neue (auch die erste Einblendung) und erscheint danach
  if moving or (isShowing() and not options.immediate) then
    if #queue >= MAX_QUEUE then table.remove(queue, 1) end
    table.insert(queue, { message, color, options.sound, options.notice })
    ns.Debug("alert", "queued (%s waiting, moving %s)", #queue, moving or false)
    return
  end
  display(message, color, options.sound, options.notice)
end

-- Sofort zeigen und die Warteschlange leeren, auch im Edit-Modus (Beispiel beim Einschalten des Edit-Modus)
function Alerts.ShowPinned(message, color, card)
  ns.Debug("alert", "%s", message)
  queue = {}
  display(message, color, nil, card)
end

-- Beispiel (Vorschau, /lt debug alert) sofort zeigen, ohne wartende echte Einblendungen zu verwerfen: eine gerade
-- sichtbare echte kommt vorne zurück in die Warteschlange und erscheint nach dem Beispiel noch einmal ganz
function Alerts.ShowSampleMessage(message, color, card, sound)
  if moving then
    -- Im Edit-Modus wartet auch das Beispiel und erscheint danach
    if #queue >= MAX_QUEUE then table.remove(queue, 1) end
    table.insert(queue, { message, color, sound, card, true })
    return
  end
  if current then table.insert(queue, 1, current) end
  while #queue > MAX_QUEUE do table.remove(queue) end
  display(message, color, sound, card, true)
end

-- Edit-Modus: Das sichtbare Beispiel bleibt stehen, Neues wartet. Beim Beenden verschwindet das Beispiel und die
-- erste wartende Einblendung erscheint.
function Alerts.SetPaused(paused)
  moving = paused
  if paused then return end
  frame:SetSize(1, 1)
  frame:Hide()
  notice.frame:Hide()
  current = nil
  local waiting = table.remove(queue, 1)
  if waiting then display(unpack(waiting, 1, 5)) end
end

function Alerts.IsEditing()
  return moving or false
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

-- Karte zu einem Hinweis: mit Titel steht der Text als Zeile darunter, ohne Titel ist der Text der Titel
function Alerts.NoticeCard(entry)
  return { icon = entry.icon, texture = entry.texture, title = entry.title or entry.text,
    body = entry.title and entry.text or nil }
end

-- Hinweis an den Spieler: jede Nachricht als Chatzeile und als Karte (mehrere warten nacheinander).
-- notices = Text, { text, title, icon } oder eine Liste davon; icon siehe Alerts.ICONS
function Alerts.Notify(notices, color)
  if type(notices) == "string" or notices.text then notices = { notices } end
  for _, entry in ipairs(notices) do
    if type(entry) == "string" then entry = { text = entry } end
    ns.Print(entry.text)
    Alerts.Show(entry.text, color, { notice = Alerts.NoticeCard(entry) })
  end
end

ns.RegisterApply(function()
  layout()
end)

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

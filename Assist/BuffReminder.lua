-- Hinweise auf fehlende Buffs beim Leveln, jeder einzeln schaltbar:
--   remindFood  "Satt" (Well Fed); in WoW Forever 5 % mehr XP aus Kills
--   remindCamp  "Lagervorteile" (Camp-Buff, nur WoW Forever, Spell 1229741)
--   remindCharged "Aufgeladen" der Himmelsgeborenen (Rassen-ID 96, nur WoW Forever, Spell 1270893,
--               kommt von "Himmelssicht" an einer Elementarkonvergenz)
--   remindSleepingBag "Gut erholt" (Spell 429959, nur WoW Forever), nur mit "Gemütlicher Schlafsack" (Item 211527)
--               in den Taschen
-- Erinnert wird nur, wenn es sich lohnt: beim Leveln, außerhalb von Kampf und Ruhegebiet, lebendig,
-- und je Buff wiederholt im Abstand von reminderInterval Minuten (Einstellung), solange er fehlt.
-- Lagervorteile und Aufgeladen nur in der offenen Welt (outdoorsOnly): in Dungeons, Schlachtzügen und
-- Schlachtfeldern gibt es weder Lagerfeuer noch Elementarkonvergenzen.
-- "Satt" wird über den Namen erkannt, den der Client für Zauber WELL_FED_SPELL_ID in seiner Sprache
-- liefert: Die vielen Essens-Buffs heißen alle so, haben aber verschiedene Spell-IDs.
-- Der Camp-Buff hat eine feste Spell-ID und gibt es nur in WoW Forever (BuffReminder.HasCampSystem);
-- in anderen Clients gibt es weder Hinweis noch Einstellung. Ebenso "Aufgeladen": Die Einstellung gibt es
-- in Forever für alle (die Optionen entstehen beim Laden, wenn UnitRace noch nicht sicher bekannt ist),
-- erinnert wird nur ein Charakter mit Rassen-ID SKYBORNE_RACE_ID.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    remindFood = false,
    remindCamp = false,
    remindCharged = false,
    remindSleepingBag = false,
    reminderInterval = 5,
  },
  ranges = {
    reminderInterval = { 1, 30 },
  },
})
local L = ns.L

local BuffReminder = {}
ns.BuffReminder = BuffReminder

local WELL_FED_SPELL_ID = 19705    -- "Well Fed" (Classic), liefert den übersetzten Buff-Namen
local CAMP_SPELL_ID = 1229741      -- "Lagervorteile" (WoW Forever), im Spiel per /dump ermittelt
local CHARGED_SPELL_ID = 1270893   -- "Aufgeladen" (Himmelsgeborene, WoW Forever), im Spiel ermittelt
local SKYBORNE_RACE_ID = 96        -- 3. Wert von UnitRace: "Himmelsgeborene der Windformer" (Kürzel "Skyborne")
local SLEEPING_BAG_ITEM_ID = 211527  -- "Gemütlicher Schlafsack" (WoW Forever)
local WELL_RESTED_SPELL_ID = 429959  -- "Gut erholt" (WoW Forever, 7200 s), im Spiel gesehen
BuffReminder.SLEEPING_BAG_ITEM_ID = SLEEPING_BAG_ITEM_ID  -- auch für den Schlafsack-Timer (SleepTimer.lua)
BuffReminder.WELL_RESTED_SPELL_ID = WELL_RESTED_SPELL_ID
local CHECK_INTERVAL = 2           -- Sekunden zwischen zwei Prüfungen (Schild weg im Kampf: schnell merken)
local SECONDS_PER_MINUTE = 60
BuffReminder.MIN_INTERVAL = 1      -- Minuten; Grenzen des Reglers in den Einstellungen
BuffReminder.MAX_INTERVAL = 30

local function spellName(spellID)
  return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
end

-- true, wenn der Buff fehlt; nil, wenn sich das nicht feststellen lässt (Auren gesperrt, siehe Lib/Auras.lua).
-- found = Ergebnis von Auras.FindByName/FindBySpellId (Aura, false oder nil)
local function missing(found)
  if found == nil then return nil end
  return not found
end

function BuffReminder.IsFoodMissing()
  local name = spellName(WELL_FED_SPELL_ID)
  if not name then return nil end
  return missing(ns.Auras.FindByName(name))
end

function BuffReminder.HasCampSystem()
  return ns.Client.IsForever()
end

function BuffReminder.IsCampMissing()
  if not BuffReminder.HasCampSystem() or not spellName(CAMP_SPELL_ID) then return nil end
  return missing(ns.Auras.FindBySpellId(CAMP_SPELL_ID))
end

function BuffReminder.HasChargedSystem()
  return ns.Client.IsForever()
end

function BuffReminder.IsSkyborne()
  local _, _, raceID = UnitRace("player")
  return raceID == SKYBORNE_RACE_ID
end

function BuffReminder.IsChargedMissing()
  if not BuffReminder.HasChargedSystem() or not BuffReminder.IsSkyborne() or not spellName(CHARGED_SPELL_ID) then
    return nil
  end
  return missing(ns.Auras.FindBySpellId(CHARGED_SPELL_ID))
end

-- Schlafsack (WoW Forever): Item SLEEPING_BAG_ITEM_ID "Gemütlicher Schlafsack" gibt beim Ausruhen den Buff
-- WELL_RESTED_SPELL_ID "Gut erholt" (2 h, +3 % XP; beides im Spiel gesehen). Erinnert wird nur mit dem Item in den
-- Taschen; Clients ohne das Item (GetItemInfoInstant nil) bekommen nichts.
function BuffReminder.HasSleepingBagSystem()
  return ns.Client.IsForever()
end

function BuffReminder.SleepingBagExists()
  return C_Item ~= nil and C_Item.GetItemInfoInstant ~= nil and C_Item.GetItemInfoInstant(SLEEPING_BAG_ITEM_ID) ~= nil
end

function BuffReminder.SleepingBagCount()
  local count = C_Item and C_Item.GetItemCount and C_Item.GetItemCount(SLEEPING_BAG_ITEM_ID)
  if ns.IsSecret(count) or type(count) ~= "number" then return nil end
  return count
end

-- true = Schlafsack dabei und "Gut erholt" fehlt; false = Buff da; nil = kein Schlafsack, anderer Client, unlesbar
function BuffReminder.IsSleepingBagMissing()
  if not BuffReminder.HasSleepingBagSystem() or not BuffReminder.SleepingBagExists() then return nil end
  local count = BuffReminder.SleepingBagCount()
  if not count or count < 1 then return nil end
  return missing(ns.Auras.FindBySpellId(WELL_RESTED_SPELL_ID))
end

-- Symbol des Schlafsacks (Datei-ID aus dem Client); ohne das Item das allgemeine Symbol aus Alerts.ICONS
local function sleepingBagTexture()
  local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(SLEEPING_BAG_ITEM_ID)
  if ns.IsSecret(icon) then return nil end
  return icon
end

-- Je Hinweis: Einstellung, Prüfung, Text (Schlüssel oder Funktion), Symbol (Schlüssel aus Alerts.ICONS oder
-- Funktion, die eine Spell-ID oder einen Pfad liefert) und Zeitpunkt des letzten Hinweises
local REMINDERS = {
  -- Essen auch auf Maximallevel in Dungeons und Raids (Buff-Essen gehört dort dazu)
  { setting = "remindFood", isMissing = BuffReminder.IsFoodMissing, message = "REMIND_FOOD", icon = "food",
    anyLevelInInstance = true, auraOnly = true },
  { setting = "remindCamp", isMissing = BuffReminder.IsCampMissing, message = "REMIND_CAMP", icon = "camp",
    outdoorsOnly = true, auraOnly = true },
  {
    setting = "remindCharged",
    isMissing = BuffReminder.IsChargedMissing,
    message = function() return string.format(L.REMIND_CHARGED, spellName(CHARGED_SPELL_ID)) end,
    icon = "charged",
    outdoorsOnly = true,
    auraOnly = true,
  },
  -- Hängt auch an den Taschen (Schlafsack dabei), daher nicht auraOnly
  { setting = "remindSleepingBag", isMissing = BuffReminder.IsSleepingBagMissing, message = "REMIND_SLEEPING_BAG",
    icon = "sleepingBag", texture = sleepingBagTexture, outdoorsOnly = true },
}

-- Weitere Hinweise anderer Module (ClassBuffs.lua): { setting, isMissing() -> true/false/nil, message, icon,
-- optional: outdoorsOnly, inCombat (auch im Kampf), anyLevel (auch ohne Leveln), anyLevelInInstance (in Instanzen
-- auch ohne Leveln), remindOnLoss (sofort, sobald der Buff wegfällt, ohne die Pause abzuwarten), auraOnly
-- (isMissing hängt nur am Aura-Schnappschuss, Ergebnis gilt bis zur nächsten Änderung) }
function BuffReminder.Register(reminder)
  table.insert(REMINDERS, reminder)
end

local function iconOf(reminder)
  if type(reminder.icon) == "function" then return reminder.icon() end
  return ns.Alerts.ICONS[reminder.icon]
end

local function messageText(reminder)
  if type(reminder.message) == "function" then return reminder.message() end
  return L[reminder.message]
end

-- Standardbedingungen der Hinweise (Satt, Lagervorteile, ...): beim Leveln, nicht im Kampf, lebendig, nicht ruhend
function BuffReminder.WorthReminding()
  return ns.Experience.IsLeveling()
    and not UnitAffectingCombat("player")
    and not UnitIsDeadOrGhost("player")
    and not IsResting()
end

-- Spielerzustand einer Prüfung, einmal gelesen statt je Hinweis (wiederverwendet)
local context = {}

local function readContext()
  context.dead = UnitIsDeadOrGhost("player")
  context.resting = IsResting()
  context.combat = UnitAffectingCombat("player")
  context.instance = IsInInstance()
  context.leveling = ns.Experience.IsLeveling()
end

-- Darf dieser Hinweis gerade kommen? Tot und im Ruhegebiet nie; Kampf, Leveln und Instanzen je nach Hinweis
local function allowedNow(reminder)
  if context.dead or context.resting then return false end
  if context.combat and not reminder.inCombat then return false end
  local anyLevel = reminder.anyLevel or (reminder.anyLevelInInstance and context.instance)
  if not anyLevel and not context.leveling then return false end
  return not (reminder.outdoorsOnly and context.instance)
end

local function pauseOver(reminder)
  return not reminder.lastShown or GetTime() - reminder.lastShown >= ns.db.reminderInterval * SECONDS_PER_MINUTE
end

-- Fehlt der Buff? Hinweise mit auraOnly hängen nur am Aura-Schnappschuss: bei gleichem Auras.Version() gilt das
-- letzte Ergebnis (Roadmap 393)
local function missingNow(reminder)
  if not reminder.auraOnly then return reminder.isMissing() end
  local version = ns.Auras.Snapshot() and ns.Auras.Version() or nil
  if version and reminder.missingVersion == version then return reminder.missing end
  local missing = reminder.isMissing()
  reminder.missing, reminder.missingVersion = missing, version
  return missing
end

-- Fällig: fehlt und die Pause ist um, oder (remindOnLoss) war bei der letzten Prüfung noch da. Ohne remindOnLoss
-- wird während der Pause gar nicht erst nachgesehen (das Ergebnis würde nichts ändern).
local function isDue(reminder)
  if not ns.db[reminder.setting] or not allowedNow(reminder) then return false end
  if not reminder.remindOnLoss and not pauseOver(reminder) then return false end
  local missing = missingNow(reminder)
  local wasPresent = reminder.present
  if missing ~= nil then reminder.present = not missing end
  if missing ~= true then return false end
  if reminder.remindOnLoss and wasPresent then return true end
  return pauseOver(reminder)
end

-- Fällige Hinweise als Chatzeilen und gemeinsam in einer Einblendung
function BuffReminder.Check()
  if not ns.db then return end
  readContext()
  local messages
  for _, reminder in ipairs(REMINDERS) do
    if isDue(reminder) then
      ns.Debug("reminder", "%s missing, reminding", reminder.setting)
      reminder.lastShown = GetTime()
      messages = messages or {}
      table.insert(messages, { title = L.NOTICE_BUFF, text = messageText(reminder), icon = iconOf(reminder),
        texture = reminder.texture and reminder.texture() or nil })
    end
  end
  if messages then
    ns.Alerts.Notify(messages, ns.Alerts.WARNING_COLOR)
  end
end

-- Regelmäßig prüfen statt auf UNIT_AURA zu hören: Ablauf, Kampfende und Ruhegebiet ändern sich
-- auch ohne Aura-Event, und die Prüfung ist billig
ns.Every(CHECK_INTERVAL, BuffReminder.Check)

-- Neuer Login: sofort erinnern dürfen
ns.OnLogin(function()
  for _, reminder in ipairs(REMINDERS) do
    reminder.lastShown, reminder.present, reminder.missingVersion = nil, nil, nil
  end
end)

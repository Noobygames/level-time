-- Kontrollverlust-Ansage für Heiler (Einstellung announceControlLoss, Standard aus): mit der Rolle Heiler in Dungeons
-- und Schlachtzügen geht eine Nachricht an die Gruppe, wenn man nicht heilen kann (Betäubung, Schlaf, Furcht,
-- Verwandlung, Stille, Unterbrechung einer Zauberschule).
--   Genau      LOSS_OF_CONTROL_ADDED: C_LossOfControl.GetActiveLossOfControlData(i) liefert locType, displayText
--              (Blizzards Text, z.B. "Betäubt") und timeRemaining; gezählt werden HEALER_BLOCKING_TYPES.
--   Notlösung  WoW Forever (Debug-Log mit Schlaf, 1.60.1): locType, displayText, timeRemaining und spellID sind
--              geheim, lesbar nur displayType und priority; HasFullControl() blieb im Schlaf true. Ein Eintrag mit
--              displayType FULL_DISPLAY (Blizzards große Kontrollverlust-Anzeige) meldet "kann nicht heilen", aber erst ab
--              priority MIN_SECRET_PRIORITY: Wurzeln kamen in Forever ebenfalls mit displayType 2, aber priority 1
--              (Debug-Log 2026-11-08, Heiler im Dungeon von Wucherwurzeln festgehalten, heilen ging weiter);
--              andere Einträge hatten 3 und 5. Was die Stufen genau bedeuten, dokumentiert Blizzard nicht.
-- Je Kontrollverlust eine Nachricht, höchstens alle REPEAT_SECONDS; bei gesperrtem Chat (GroupChat.Locked) nicht.
-- Entwarnung (eigene Einstellung announceControlOver): fällt die Anzahl (lesbar, auch in Forever) auf 0, folgt
-- "wieder frei (nach N s)", gemessen ab Beginn (auch ohne Warnung, solange man Heiler in der Instanz ist); die
-- Restdauer selbst ist in Forever geheim, gemessen wird deshalb selbst (LOSS_OF_CONTROL_UPDATE).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    announceControlLoss = false,
    announceControlOver = false,
  },
})
local L = ns.L
local GroupChat = ns.GroupChat

local ControlCallout = {}
ns.ControlCallout = ControlCallout

local HEALER_BLOCKING_TYPES = {
  STUN = true, STUN_MECHANIC = true, FEAR = true, FEAR_MECHANIC = true, CONFUSE = true, CHARM = true,
  POSSESS = true, SILENCE = true, PACIFYSILENCE = true, SCHOOL_INTERRUPT = true,
}
local REPEAT_SECONDS = 3
local FULL_DISPLAY = 2   -- displayType der großen Anzeige (Schlaf und Wurzeln)
local MIN_SECRET_PRIORITY = 2  -- Forever: priority 1 = Wurzeln (heilen geht), darüber zählt als "kann nicht heilen"

local lastSent
local controlledSince  -- GetTime(), seit dem ein heilverhindernder Kontrollverlust läuft

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

local function active()
  return (ns.db.announceControlLoss or ns.db.announceControlOver) and ns.GroupRole.IsHealerInGroupInstance()
end

local function send(text)
  if lastSent and GetTime() - lastSent < REPEAT_SECONDS then return false end
  local chatType = GroupChat.PartyChannel()
  if not chatType or GroupChat.Locked() then return false end
  ns.Debug("announce", "control: %s", text)
  GroupChat.Send(text, chatType)
  lastSent = GetTime()
  return true
end

local function lossData(index)
  if not C_LossOfControl then return nil end
  local get = C_LossOfControl.GetActiveLossOfControlData
  if get then return get(index) end
  if C_LossOfControl.GetActiveLossOfControlDataByUnit then
    return C_LossOfControl.GetActiveLossOfControlDataByUnit("player", index)
  end
  return nil
end

local function lossCount()
  if not C_LossOfControl then return 0 end
  local count = C_LossOfControl.GetActiveLossOfControlDataCount and C_LossOfControl.GetActiveLossOfControlDataCount()
    or (C_LossOfControl.GetActiveLossOfControlDataCountByUnit
      and C_LossOfControl.GetActiveLossOfControlDataCountByUnit("player"))
  return readable(count) or 0
end

-- Text für einen lesbaren Kontrollverlust, nil wenn er das Heilen nicht verhindert oder geheim ist
function ControlCallout.Describe(data)
  if type(data) ~= "table" then return nil end
  local locType = readable(data.locType)
  if not locType or not HEALER_BLOCKING_TYPES[locType] then return nil end
  local what = readable(data.displayText) or locType
  local remaining = readable(data.timeRemaining)
  if type(remaining) == "number" and remaining > 0 then
    return string.format(L.CC_ANNOUNCE, what, math.ceil(remaining))
  end
  return string.format(L.CC_ANNOUNCE_NO_TIME, what)
end

-- Art geheim, aber große Anzeige: verhindert das Heilen
local function isSecretFullDisplay(data)
  if type(data) ~= "table" or readable(data.locType) ~= nil or readable(data.displayType) ~= FULL_DISPLAY then
    return false
  end
  local priority = readable(data.priority)
  ns.Debug("announce", "secret control: displayType %s, priority %s", data.displayType, priority)
  return type(priority) ~= "number" or priority >= MIN_SECRET_PRIORITY
end

-- Nur bei neuem Kontrollverlust (ADDED); UPDATE kommt laufend, solange er anhält
local function onLossOfControlAdded()
  if not active() then return end
  local secretFound = false
  for index = 1, lossCount() do
    local data = lossData(index)
    local text = ControlCallout.Describe(data)
    if text then
      controlledSince = controlledSince or GetTime()
      if ns.db.announceControlLoss then send(text) end
      return
    end
    secretFound = secretFound or isSecretFullDisplay(data)
  end
  if not secretFound then return end
  controlledSince = controlledSince or GetTime()
  if ns.db.announceControlLoss then send(L.CC_ANNOUNCE_GENERIC) end
end

-- Alle Kontrollverluste vorbei: "wieder frei" mit der gemessenen Dauer (nicht über send: keine Pause)
local function onLossOfControlUpdate()
  if not controlledSince or lossCount() > 0 then return end
  local seconds = math.floor(GetTime() - controlledSince + 0.5)
  controlledSince = nil
  local chatType = GroupChat.PartyChannel()
  if not ns.db.announceControlOver or not chatType or GroupChat.Locked() then return end
  ns.Debug("announce", "control over after %s s", seconds)
  GroupChat.Send(string.format(L.CC_ANNOUNCE_OVER, seconds), chatType)
end

ns.RegisterEvent("LOSS_OF_CONTROL_ADDED", onLossOfControlAdded)
ns.RegisterEvent("LOSS_OF_CONTROL_UPDATE", onLossOfControlUpdate)
ns.OnLogin(function() lastSent, controlledSince = nil, nil end)

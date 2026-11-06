-- Mana-Ansage für Heiler (Einstellung announceLowMana, Standard aus): in Dungeons und Schlachtzügen, mit der Rolle
-- Heiler (UnitGroupRolesAssigned), eine Nachricht an die Gruppe, wenn das Mana unter die Grenze lowManaPercent
-- (Einstellung, Prozent) fällt. Wieder scharf erst REARM_MARGIN Prozentpunkte darüber (sonst bei jedem Schwanken
-- eine Nachricht). Sperrt Blizzard gerade den Chat
-- (Bosskampf, GroupChat.Locked), wartet die Ansage, bis er wieder offen ist, solange das Mana noch niedrig ist.
-- WoW Forever sperrt das Mana des Spielers immer, auch außerhalb des Kampfs (Debug-Log 1.60.1: UnitPower und
-- UnitPowerPercent geheim, nur das Maximum lesbar). Dort gibt es keine Prozent-Ansage, nur die Notlösung: kommt
-- die Fehlermeldung "Nicht genug Mana" (ERR_OUT_OF_MANA, UI_ERROR_MESSAGE), geht "Kein Mana mehr!" an die Gruppe,
-- höchstens alle OUT_OF_MANA_REPEAT Sekunden.
local _, ns = ...
local L = ns.L
local GroupChat = ns.GroupChat

local ManaCallout = {}
ns.ManaCallout = ManaCallout

ManaCallout.MIN_PERCENT = 5    -- Grenzen des Reglers in den Einstellungen
ManaCallout.MAX_PERCENT = 60
local REARM_MARGIN = 15
local CHECK_SECONDS = 1
local OUT_OF_MANA_REPEAT = 30
local MANA = (Enum and Enum.PowerType and Enum.PowerType.Mana) or 0

local armed = true          -- nächste Unterschreitung wird angesagt
local pending               -- angesagter Prozentwert, der auf einen offenen Chat wartet
local lastOutOfMana

local isHealerInDungeon = ns.GroupRole.IsHealerInGroupInstance

-- Mana in Prozent; nil, wenn der Client es sperrt (WoW Forever immer) oder kein Mana da ist
function ManaCallout.ManaPercent()
  local current, maximum = UnitPower("player", MANA), UnitPowerMax("player", MANA)
  if ns.IsSecret(current) or ns.IsSecret(maximum) or type(maximum) ~= "number" or maximum <= 0 then return nil end
  return current / maximum * 100
end

local function send(text)
  local chatType = GroupChat.PartyChannel()
  if not chatType or GroupChat.Locked() then return false end
  ns.Debug("announce", "mana: %s", text)
  GroupChat.Send(text, chatType)
  return true
end

function ManaCallout.Check()
  if not ns.db.announceLowMana or not isHealerInDungeon() then
    pending = nil
    return
  end
  local percent = ManaCallout.ManaPercent()
  if not percent then return end
  local low = ns.db.lowManaPercent
  if percent >= low + REARM_MARGIN then
    armed, pending = true, nil
    return
  end
  if percent < low and armed then
    armed, pending = false, math.floor(percent)
  end
  -- Wartende Ansage mit dem aktuellen Wert, solange das Mana niedrig bleibt
  if pending and percent < low then
    if send(string.format(L.LOW_MANA_ANNOUNCE, math.floor(percent))) then pending = nil end
  end
end

local function onError(_, message)
  if not ns.db.announceLowMana or not ERR_OUT_OF_MANA or ns.IsSecret(message) or message ~= ERR_OUT_OF_MANA then
    return
  end
  if ManaCallout.ManaPercent() or not isHealerInDungeon() then return end  -- lesbares Mana: Prozent-Ansage
  if lastOutOfMana and GetTime() - lastOutOfMana < OUT_OF_MANA_REPEAT then return end
  if send(L.OUT_OF_MANA_ANNOUNCE) then lastOutOfMana = GetTime() end
end

ns.Every(CHECK_SECONDS, ManaCallout.Check)
ns.RegisterEvent("UI_ERROR_MESSAGE", onError)
ns.OnLogin(function()
  armed, pending, lastOutOfMana = true, nil, nil
end)

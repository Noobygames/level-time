-- Instanz-Kopien: in welcher Kopie eines Dungeons, Raids oder Szenarios man ist. Die API liefert für
-- 5er-Dungeons keine Instanz-ID; erkennbar ist die Kopie an der zoneUID in den GUIDs ihrer Gegner
-- (Creature-0-Server-InstanzID-zoneUID-NpcID-SpawnUID, siehe warcraft.wiki.gg/wiki/GUID), so wie es
-- auch Nova Instance Tracker macht. Beim Betreten wird deshalb zuerst geschätzt, später bestätigt:
--   Schätzung    neue Kopie, wenn der Charakter die Instanz nicht kennt, sie seitdem zurückgesetzt wurde
--                oder er sie vor mehr als REUSE_SECONDS verlassen hat; sonst dieselbe
--   Bestätigung  sobald CONFIRM_SIGHTINGS verschiedene Gegner (Ziel, Maus, Namensplakette) dieselbe
--                zoneUID zeigen. Weicht sie von der gemerkten ab, war es eine andere Kopie (Reset, den
--                man nicht gesehen hat, oder Kopie eines anderen Gruppenleiters).
-- In Retail und WoW Forever kann UnitGUID geheim sein (SecretWhenUnitIdentityRestricted); dann bleibt
-- es bei der Schätzung.
-- Als Geist zurück zur Leiche ist es sicher dieselbe Kopie (die Leiche liegt dort): wer die Instanz als Geist
-- verlassen hat und als Geist wieder betritt, kommt zurück in den gemerkten Besuch, auch wenn Schwierigkeit oder
-- Zeit etwas anderes nahelegen. In WoW Forever sind die GUIDs in Instanzen geheim, dort gibt es keine Bestätigung.
-- Reset: INSTANCE_RESET_SUCCESS oder INSTANCE_RESET_FAILED im Systemchat. Beide bekommt nur der
-- Gruppenleiter; FAILED ("noch Spieler drin") setzt die Instanz für alle draußen trotzdem zurück.
-- Je Charakter gemerkt: character.instanceVisits[Schlüssel] = { zoneUID, leftAt, pending }. Schlüssel =
-- Name und Schwierigkeit ("Name#difficultyID"): Normal und Heroisch sind verschiedene Kopien gleichen
-- Namens. Abonnenten bekommen den Namen; ob es eine neue Kopie ist, sagt ihnen isNew.
--
-- Abonnenten (Instances.lua, InstanceLimit.lua):
--   OnEnter(fn(name, instanceType, isNew))                     isNew = Schätzung
--   OnLeave(fn(name))
--   OnCorrected(fn(name, instanceType, isNew, enteredAt))     die zoneUID widerspricht der Schätzung
--   OnConfirmed(fn(name, zoneUID))                            Kopie steht fest
--   OnReset(fn(name))                                         alte Kopie ist weg
local _, ns = ...
local ChatPatterns = ns.ChatPatterns

local InstanceCopy = {}
ns.InstanceCopy = InstanceCopy

local TRACKED_TYPES = { party = true, raid = true, scenario = true }
local REUSE_SECONDS = 30 * 60  -- so lange nach dem Verlassen gilt die Instanz als dieselbe Kopie
local CONFIRM_SIGHTINGS = 2    -- so viele verschiedene Gegner müssen dieselbe zoneUID zeigen

local resetPatterns = ChatPatterns.CompileGlobals({ "INSTANCE_RESET_SUCCESS", "INSTANCE_RESET_FAILED" })

-- Aktueller Aufenthalt: { name, instanceType, enteredAt, guessNew, expectedZoneUID,
-- candidate, sightings, lastGuid, confirmed }; nil draußen
local inside
-- Zuletzt als Geist verlassene Instanz: { key, name }; nil, sobald man sie lebend verlassen hat
local leftAsGhost

local listeners = { enter = {}, leave = {}, corrected = {}, confirmed = {}, reset = {} }

local function notify(kind, ...)
  for _, listener in ipairs(listeners[kind]) do
    ns.SafeCall(listener, ...)
  end
end

function InstanceCopy.OnEnter(fn) table.insert(listeners.enter, fn) end
function InstanceCopy.OnLeave(fn) table.insert(listeners.leave, fn) end
function InstanceCopy.OnCorrected(fn) table.insert(listeners.corrected, fn) end
function InstanceCopy.OnConfirmed(fn) table.insert(listeners.confirmed, fn) end
function InstanceCopy.OnReset(fn) table.insert(listeners.reset, fn) end

-- Name der Instanz, in der man gerade ist; nil draußen
function InstanceCopy.GetInsideName()
  return inside and inside.name
end

-- zoneUID aus der GUID eines Gegners; nil für Spieler, Begleiter, geheime oder unbekannte GUIDs
function InstanceCopy.ZoneUIDOf(guid)
  if ns.IsSecret(guid) or not guid then return nil end
  local digits = guid:match("^Creature%-%d+%-%d+%-%d+%-(%d+)%-")
  local zoneUID = digits and tonumber(digits)
  return zoneUID and zoneUID > 0 and zoneUID or nil
end

local function visits()
  return ns.character.instanceVisits
end

local function copyKey(name, difficultyID)
  return name .. "#" .. (difficultyID or 0)
end

-- Besuch zu einem Schlüssel; Besuche aus v2.8 hießen nur nach der Instanz und werden übernommen
local function visitOf(key, name)
  local all = visits()
  if not all[key] and all[name] then
    all[key], all[name] = all[name], nil
  end
  return all[key]
end

local function isNewCopy(visit, now)
  return not visit or (visit.leftAt ~= nil and now - visit.leftAt > REUSE_SECONDS)
end

local function stay(key, name, instanceType, enteredAt, guessNew, expectedZoneUID)
  return { key = key, name = name, instanceType = instanceType, enteredAt = enteredAt, guessNew = guessNew,
    expectedZoneUID = expectedZoneUID, sightings = 0 }
end

-- Als Geist zurück in die Instanz, die man als Geist verlassen hat: Besuch unter dem neuen Schlüssel weiterführen
local function ghostReturn(key, name)
  local ghost = leftAsGhost
  leftAsGhost = nil
  if not ghost or ghost.name ~= name or not UnitIsDeadOrGhost("player") then return false end
  local visit = visits()[ghost.key]
  if ghost.key ~= key then
    visits()[ghost.key], visits()[key] = nil, visit
  end
  ns.Debug("instances", "ghost back in %s (left as %s)", key, ghost.key)
  if visit then visit.leftAt = nil end
  return true
end

-- Bis zur Bestätigung merkt sich der Besuch die Schätzung (pending = { guessNew, expected, enteredAt }),
-- damit /reload oder kurzes Rausgehen sie nicht verlieren: sonst fehlte später der Vergleichswert.
local function enter(key, name, instanceType)
  local now = time()
  local ghost = ghostReturn(key, name)
  local visit = visitOf(key, name)
  local pending = visit and visit.pending
  local guessNew = not ghost and isNewCopy(visit, now)
  ns.Debug("instances", "enter %s: visit %s, left %s s ago, zoneUID %s, pending %s, ghost %s", key, visit ~= nil,
    visit and visit.leftAt and (now - visit.leftAt), visit and visit.zoneUID, pending ~= nil, UnitIsDeadOrGhost("player"))
  if pending and not guessNew then
    -- Dieselbe, noch unbestätigte Kopie wie beim letzten Aufenthalt: deren Schätzung gilt weiter
    inside = stay(key, name, instanceType, pending.enteredAt, pending.guessNew, pending.expected)
    visit.leftAt = nil
    ns.Debug("instances", "back in unconfirmed %s", name)
    notify("enter", name, instanceType, false)
    return
  end
  local expected = visit and (visit.zoneUID or (pending and pending.expected))
  inside = stay(key, name, instanceType, now, guessNew, expected)
  -- Bis zur Bestätigung gilt die gemerkte zoneUID nur, wenn es dieselbe Kopie sein dürfte
  visits()[key] = {
    zoneUID = not guessNew and visit and visit.zoneUID or nil,
    pending = { guessNew = guessNew, expected = expected, enteredAt = now },
  }
  ns.Debug("instances", "enter %s, new copy guessed: %s", name, guessNew)
  notify("enter", name, instanceType, guessNew)
end

local function leave()
  local name = inside.name
  local visit = visits()[inside.key]
  if visit then visit.leftAt = time() end
  local ghost = UnitIsDeadOrGhost("player")
  leftAsGhost = ghost and { key = inside.key, name = name } or nil
  ns.Debug("instances", "leave %s, ghost %s", inside.key, ghost)
  inside = nil
  notify("leave", name)
end

local function confirm(zoneUID)
  inside.confirmed = true
  local visit = visits()[inside.key] or {}
  visits()[inside.key] = visit
  visit.zoneUID = zoneUID
  visit.pending = nil
  local expected = inside.expectedZoneUID
  ns.Debug("instances", "confirmed %s: zoneUID %s, expected %s, guessed new %s", inside.key, zoneUID, expected,
    inside.guessNew)
  if expected then
    local isNew = zoneUID ~= expected
    if isNew ~= inside.guessNew then
      ns.Debug("instances", "%s: zoneUID %s vs %s, new copy: %s", inside.name, zoneUID, expected, isNew)
      notify("corrected", inside.name, inside.instanceType, isNew, inside.enteredAt)
    end
  end
  notify("confirmed", inside.name, zoneUID)
end

-- Gegner gesehen: zoneUID zählt erst, wenn CONFIRM_SIGHTINGS verschiedene Gegner sie zeigen
local function sighted(unit)
  if not inside or inside.confirmed or not unit then return end
  local guid = UnitGUID(unit)
  local zoneUID = InstanceCopy.ZoneUIDOf(guid)
  if not zoneUID or guid == inside.lastGuid then return end
  inside.lastGuid = guid
  if zoneUID == inside.candidate then
    inside.sightings = inside.sightings + 1
  else
    inside.candidate, inside.sightings = zoneUID, 1
  end
  ns.Debug("instances", "sighted %s: zoneUID %s (%s/%s), guid %s", unit, zoneUID, inside.sightings, CONFIRM_SIGHTINGS, guid)
  if inside.sightings >= CONFIRM_SIGHTINGS then
    confirm(zoneUID)
  end
end

-- Schlüssel, Name und Art der verfolgten Instanz, in der man gerade ist; nil in der offenen Welt.
-- difficultyID = 3. Rückgabe von GetInstanceInfo in allen Clients.
local function trackedInstance()
  local inInstance, instanceType = IsInInstance()
  if not inInstance or not TRACKED_TYPES[instanceType] then return nil end
  local name, _, difficultyID = GetInstanceInfo()
  if ns.IsSecret(name) or ns.IsSecret(difficultyID) then
    ns.Debug("instances", "instance info secret, not tracked")
    return nil
  end
  return copyKey(name, difficultyID), name, instanceType
end

local function onWorldChanged()
  local key, name, instanceType = trackedInstance()
  if key == (inside and inside.key) then return end
  if inside then leave() end
  if key then enter(key, name, instanceType) end
end

-- "Die Todesminen wurde zurückgesetzt.": die alte Kopie gibt es nicht mehr
local function onSystemMessage(message)
  if ns.IsSecret(message) then return end
  local args = ChatPatterns.MatchAny(message, resetPatterns)
  if not args then return end
  local name = args[1]
  -- Die Kopie, in der man steht, wird nicht zurückgesetzt (der Reset trifft nur Leere bzw. die draußen)
  if name == InstanceCopy.GetInsideName() then return end
  ns.Debug("instances", "reset %s", name)
  -- Alle Schwierigkeiten dieses Namens (und ein Besuch im Format aus v2.8)
  local prefix = name .. "#"
  for key in pairs(visits()) do
    if key == name or key:sub(1, #prefix) == prefix then visits()[key] = nil end
  end
  notify("reset", name)
end

-- Nach dem Login die aktuelle Instanz einlesen. Normal kommt danach ohnehin PLAYER_ENTERING_WORLD;
-- nötig ist es beim Neustart nach dem Löschen des eingeloggten Charakters mitten in einer Instanz.
-- Verzögert, damit alle Login-Callbacks (z.B. Instances) vorher gelaufen sind.
ns.OnLogin(function()
  inside, leftAsGhost = nil, nil
  C_Timer.After(0, onWorldChanged)
end)

-- Logout in der Instanz gilt als Verlassen, damit der nächste Login die Pause sieht
ns.OnLogout(function()
  if inside then leave() end
end)

ns.RegisterEvent("PLAYER_ENTERING_WORLD", onWorldChanged)
ns.RegisterEvent("ZONE_CHANGED_NEW_AREA", onWorldChanged)
ns.RegisterEvent("CHAT_MSG_SYSTEM", onSystemMessage)
ns.RegisterEvent("PLAYER_TARGET_CHANGED", function() sighted("target") end)
ns.RegisterEvent("UPDATE_MOUSEOVER_UNIT", function() sighted("mouseover") end)
ns.RegisterEvent("NAME_PLATE_UNIT_ADDED", sighted)

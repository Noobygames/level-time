-- Mitspieler-Gedächtnis der Gruppensuche (LT-392; nur WoW Forever): letzte Mitspieler aus der Gruppenliste, eigene
-- Bewertung (+/-) und Abbrecher (verließen die Gruppe, während man in einer Instanz war). Account-weit in
-- ns.db.lfgPlayers, Schlüssel = kleingeschriebener Name ohne Realm.
-- shortcut: Realm wird ignoriert (gleichnamige Spieler anderer Realms teilen sich einen Eintrag), Notiz fehlt noch.
-- Namen aus der Gruppenliste können geheim sein (ns.IsSecret): dann wird der Spieler übersprungen.
local _, ns = ...
if not ns.Client.IsForever() then return end

ns.RegisterDefaults({ settings = { lfgPlayers = {} } })  -- { [key] = { name, time, rating = 1|-1|nil, leaves } }

local LFGPlayers = {}
ns.LFGPlayers = LFGPlayers

LFGPlayers.MAX_PLAYERS = 60
LFGPlayers.UP, LFGPlayers.DOWN = 1, -1

local roster = {}     -- Schlüssel der letzten Gruppenliste -> Name
local rosterReads, rosterSecret = 0, 0  -- für die Prüfung: Namen der Gruppenliste gelesen / davon geheim
local listeners = {}

local function keyOf(name) return (name:match("^[^-]+") or name):lower() end

local function players() return ns.db and ns.db.lfgPlayers or {} end

local function changed() for _, fn in ipairs(listeners) do fn() end end

function LFGPlayers.OnChange(fn) table.insert(listeners, fn) end

local function entryFor(name)
  local all = players()
  local key = keyOf(name)
  all[key] = all[key] or { name = name:match("^[^-]+") or name, time = time() }
  return all[key]
end

-- Behält die jüngsten MAX_PLAYERS; bewertete und Abbrecher fliegen erst nach allen anderen raus
local function prune()
  local all, list = players(), {}
  for key, entry in pairs(all) do table.insert(list, { key = key, entry = entry }) end
  if #list <= LFGPlayers.MAX_PLAYERS then return end
  local function weight(item) return (item.entry.rating or item.entry.leaves) and 1 or 0 end
  table.sort(list, function(a, b)
    if weight(a) ~= weight(b) then return weight(a) > weight(b) end
    return a.entry.time > b.entry.time
  end)
  for index = LFGPlayers.MAX_PLAYERS + 1, #list do all[list[index].key] = nil end
end

local function readRoster()
  local current, incomplete = {}, false
  local count = GetNumGroupMembers and GetNumGroupMembers() or 0
  local prefix = IsInRaid and IsInRaid() and "raid" or "party"
  for index = 1, prefix == "raid" and count or count - 1 do
    local name = UnitName(prefix .. index)
    rosterReads = rosterReads + 1
    if ns.IsSecret(name) then
      rosterSecret = rosterSecret + 1
    elseif type(name) ~= "string" or name == "" or name == UNKNOWNOBJECT then
      incomplete = true  -- Ladebildschirm/Zonenwechsel: Name noch nicht bekannt
    else
      current[keyOf(name)] = name
    end
  end
  return current, incomplete
end

local function onRosterUpdate()
  if not ns.db then return end
  if not (IsInGroup and IsInGroup()) then roster = {}; return end  -- selbst gegangen: niemand ist Abbrecher
  local current, incomplete = readRoster()
  local inInstance = IsInInstance and IsInInstance()
  for key, name in pairs(roster) do
    if incomplete and not current[key] then
      current[key] = name  -- unvollständige Liste: niemanden als Abbrecher zählen
    elseif not current[key] and inInstance then
      local entry = entryFor(name)
      entry.leaves = (entry.leaves or 0) + 1
      ns.Debug("lfg", "player left the group in an instance: %s", name)
    end
  end
  for _, name in pairs(current) do entryFor(name).time = time() end
  roster = current
  prune()
  changed()
end
ns.RegisterEvent("GROUP_ROSTER_UPDATE", onRosterUpdate)

-- Neueste zuerst
function LFGPlayers.GetList()
  local list = {}
  for _, entry in pairs(players()) do table.insert(list, entry) end
  table.sort(list, function(a, b) return a.time > b.time end)
  return list
end

function LFGPlayers.Get(name)
  if type(name) ~= "string" or ns.IsSecret(name) then return nil end
  return players()[keyOf(name)]
end

-- Keine -> Daumen hoch -> Daumen runter -> keine
function LFGPlayers.CycleRating(name)
  local entry = LFGPlayers.Get(name)
  if not entry then return end
  if entry.rating == nil then entry.rating = LFGPlayers.UP
  elseif entry.rating == LFGPlayers.UP then entry.rating = LFGPlayers.DOWN
  else entry.rating = nil end
  changed()
end

-- Kurzzeichen vor dem Namen: "+" gut, "-" schlecht, "!" Abbrecher (ASCII: jede Schrift kann es)
function LFGPlayers.Marker(name)
  local entry = LFGPlayers.Get(name)
  if not entry then return "" end
  local text = ""
  if entry.rating == LFGPlayers.UP then text = "|cff40ff40+|r"
  elseif entry.rating == LFGPlayers.DOWN then text = "|cffff5050-|r" end
  if entry.leaves then text = text .. "|cffff9a3c!|r" end
  return text ~= "" and (text .. " ") or ""
end

-- Für die Prüfung (LT392.lfg.players)
function LFGPlayers.Stats()
  local rated, leavers, total = 0, 0, 0
  for _, entry in pairs(players()) do
    total = total + 1
    if entry.rating then rated = rated + 1 end
    if entry.leaves then leavers = leavers + 1 end
  end
  return { total = total, rated = rated, leavers = leavers, rosterReads = rosterReads, rosterSecret = rosterSecret }
end

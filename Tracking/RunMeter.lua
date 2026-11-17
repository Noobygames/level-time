-- Schadensmesser-Zahlen für den Dungeon-Recap (LT-334): fällt der Endboss (InstanceBosses.OnCompleted), fasst dieses
-- Modul nach dem Kampf (PLAYER_REGEN_ENABLED) alle Kampfsitzungen von C_DamageMeter je Spieler zusammen und legt sie am
-- offenen Lauf ab: run.recapPlayers = "Name:KLASSE:Schaden:Heilung:Unterbrechungen:Schaden erlitten:Tode:Bossschaden;..."
-- (alle Zahlen ganz, Name ohne ":" und ";"), run.recapMobs = "Gegner:Schaden an dir;..." (die gefährlichsten, nur für
-- den eigenen Spieler). Im Kampf passiert nichts; C_DamageMeter gibt es nur in Clients mit dem Schadensmesser, sonst
-- bleibt der Recap ohne Zahlen (IsAvailable = false). Namen und Zahlen können geheim sein (ns.IsSecret): solche Zeilen
-- fallen weg. Beim Abschluss melden sich die Hörer von RunMeter.OnReady(listener(run)), auch ohne Zahlen.
-- shortcut: Tode je Spieler = Zahl der Quellen in den "Deaths"-Sitzungen mit seinem Namen (Prüfung LT334.recap.deaths),
-- Bossschaden = Sitzungen, deren Name ein besiegter Boss ist; fehlt der Treffer, bleibt der Wert 0.
local _, ns = ...
local InstanceBosses = ns.InstanceBosses

local RunMeter = {}
ns.RunMeter = RunMeter

local MAX_SESSIONS = 60  -- neueste Kampfsitzungen; ein Lauf hat selten mehr
local MAX_MOBS = 5
local FIELD_SEPARATOR, ROW_SEPARATOR = ":", ";"

local pending     -- Lauf, dessen Zahlen nach dem Kampf eingesammelt werden
local listeners = {}

function RunMeter.OnReady(listener)
  ns.RememberSource(listener, "RunMeter.lua")
  table.insert(listeners, listener)
end

function RunMeter.IsAvailable()
  if type(C_DamageMeter) ~= "table" or not Enum or not Enum.DamageMeterType then return false end
  local fn = C_DamageMeter.IsDamageMeterAvailable
  if type(fn) ~= "function" or type(C_DamageMeter.GetAvailableCombatSessions) ~= "function" then return false end
  local ok, available = pcall(fn)
  return ok and available == true
end

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

-- Tabelle aus einem Aufruf oder nil (Fehler, geheim, kein Ergebnis)
local function tableOf(fn, ...)
  local ok, value = pcall(fn, ...)
  if not ok or ns.IsSecret(value) or type(value) ~= "table" then return nil end
  return value
end

local function clean(text)
  return (text:gsub("[" .. FIELD_SEPARATOR .. ROW_SEPARATOR .. "]", ""))
end

local function sourceName(source)
  local name = readable(source.name)
  return type(name) == "string" and name ~= "" and clean(name) or nil
end

local function row(players, order, name)
  if not players[name] then
    players[name] = { name = name, class = "", damage = 0, healing = 0, interrupts = 0, taken = 0, deaths = 0, bossDamage = 0 }
    table.insert(order, name)
  end
  return players[name]
end

-- Quellen einer Sitzung für einen Messwert: visit(source) für jede lesbare Tabelle
local function eachSource(sessionID, meterType, visit)
  local session = tableOf(C_DamageMeter.GetCombatSessionFromID, sessionID, meterType)
  local sources = session and readable(session.combatSources)
  if type(sources) ~= "table" then return end
  for _, source in ipairs(sources) do
    if type(source) == "table" and not ns.IsSecret(source) then visit(source) end
  end
end

local function amountOf(source)
  local amount = readable(source.totalAmount)
  return type(amount) == "number" and math.floor(amount) or 0
end

-- Gehört die Sitzung zu einem besiegten Boss des Laufs? (Sitzungsname = Bossname)
local function bossNames(run)
  local names = {}
  for id in pairs(InstanceBosses.Killed(run)) do
    local name = InstanceBosses.Name(id)
    if name then names[name:lower()] = true end
  end
  return names
end

-- Gegner, die dem eigenen Spieler in dieser Sitzung Schaden zufügten: damage[name] += Betrag
local function addMobDamage(sessionID, source, damage)
  local guid = readable(source.sourceGUID)
  local detail = tableOf(C_DamageMeter.GetCombatSessionSourceFromID, sessionID, Enum.DamageMeterType.DamageTaken, guid)
  local spells = detail and readable(detail.combatSpells)
  if type(spells) ~= "table" then return end
  for _, spell in ipairs(spells) do
    local name = type(spell) == "table" and readable(spell.creatureName)
    if type(name) == "string" and name ~= "" then
      damage[clean(name)] = (damage[clean(name)] or 0) + amountOf(spell)
    end
  end
end

-- Alle Sitzungen zusammenzählen: { players = { {name, class, damage, ...} nach Schaden }, mobs = { {name, damage} } }
function RunMeter.Collect(run)
  local types = Enum.DamageMeterType
  local sessions = tableOf(C_DamageMeter.GetAvailableCombatSessions) or {}
  local bosses = bossNames(run)
  local players, order, mobDamage = {}, {}, {}
  for index = math.max(1, #sessions - MAX_SESSIONS + 1), #sessions do
    local session = sessions[index]
    local id = type(session) == "table" and readable(session.sessionID)
    if id then
      local sessionName = readable(session.name)
      local isBoss = type(sessionName) == "string" and bosses[sessionName:lower()] or false
      eachSource(id, types.DamageDone, function(source)
        local name = sourceName(source)
        if not name then return end
        local player = row(players, order, name)
        player.class = readable(source.classFilename) or player.class
        player.damage = player.damage + amountOf(source)
        if isBoss then player.bossDamage = player.bossDamage + amountOf(source) end
      end)
      eachSource(id, types.HealingDone, function(source)
        local name = sourceName(source)
        if name then local player = row(players, order, name); player.healing = player.healing + amountOf(source) end
      end)
      eachSource(id, types.Interrupts, function(source)
        local name = sourceName(source)
        if name then local player = row(players, order, name); player.interrupts = player.interrupts + amountOf(source) end
      end)
      eachSource(id, types.Deaths, function(source)
        local name = sourceName(source)
        if name then local player = row(players, order, name); player.deaths = player.deaths + 1 end
      end)
      eachSource(id, types.DamageTaken, function(source)
        local name = sourceName(source)
        if not name then return end
        local player = row(players, order, name)
        player.taken = player.taken + amountOf(source)
        if readable(source.isLocalPlayer) == true then addMobDamage(id, source, mobDamage) end
      end)
    end
  end
  local list = {}
  for _, name in ipairs(order) do table.insert(list, players[name]) end
  table.sort(list, function(a, b) return a.damage > b.damage end)
  local mobs = {}
  for name, amount in pairs(mobDamage) do table.insert(mobs, { name = name, damage = amount }) end
  table.sort(mobs, function(a, b) if a.damage ~= b.damage then return a.damage > b.damage end return a.name < b.name end)
  while #mobs > MAX_MOBS do table.remove(mobs) end
  return { players = list, mobs = mobs }
end

function RunMeter.EncodePlayers(players)
  local rows = {}
  for _, p in ipairs(players) do
    rows[#rows + 1] = table.concat({ p.name, p.class, p.damage, p.healing, p.interrupts, p.taken, p.deaths, p.bossDamage },
      FIELD_SEPARATOR)
  end
  return #rows > 0 and table.concat(rows, ROW_SEPARATOR) or nil
end

function RunMeter.EncodeMobs(mobs)
  local rows = {}
  for _, mob in ipairs(mobs) do rows[#rows + 1] = mob.name .. FIELD_SEPARATOR .. mob.damage end
  return #rows > 0 and table.concat(rows, ROW_SEPARATOR) or nil
end

-- Zahlen am Lauf ablegen und die Hörer rufen (auch ohne Zahlen)
local function finish(run)
  if RunMeter.IsAvailable() then
    local ok, result = pcall(RunMeter.Collect, run)
    if ok then
      run.recapPlayers, run.recapMobs = RunMeter.EncodePlayers(result.players), RunMeter.EncodeMobs(result.mobs)
    end
    ns.Debug("recap", "meter collected: %s, players %s, mobs %s", ok, run.recapPlayers and "yes" or "none",
      run.recapMobs and "yes" or "none")
  else
    ns.Debug("recap", "damage meter not available")
  end
  for _, listener in ipairs(listeners) do ns.SafeCall(listener, run) end
end

InstanceBosses.OnCompleted(function(run)
  if InCombatLockdown() then
    pending = run
  else
    finish(run)
  end
end)

ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
  local run = pending
  pending = nil
  if run then finish(run) end
end)

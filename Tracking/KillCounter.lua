-- Zählt Kills (PvE, PvP, Elite, Rare) und schreibt jeden Kill mit Namen und Einstufung ins Journal.
local _, ns = ...
local L = ns.L
local Stats = ns.Stats
local Journal = ns.Journal
local ChatPatterns = ns.ChatPatterns
local Classification = ns.Classification

-- Fehlersuche (/lt debug): jede XP-Meldung mit ihrer Wertung in den Chat schreiben
local function debugXpMessage(verdictKey, message)
  if not ns.debug then return end
  if message then
    ns.Print(L[verdictKey] .. ": " .. message)
  else
    ns.Print(L[verdictKey])
  end
end

---------------------------------------------------------------------------
-- PvE: Kills, die Erfahrung gegeben haben (Chatmeldung "X stirbt, Ihr bekommt Y Erfahrung").
-- Gruppen-Kills zählen mit; graue Gegner ohne XP und Kills auf Max-Level nicht.
-- Die XP-Menge aus der Meldung fließt in die XP-Quellen ein.
---------------------------------------------------------------------------
local function countKill(name, xp)
  local classification = name and Classification.Of(name) or nil
  Stats.Increment(Stats.PVE_KILLS)
  Stats.Increment(Stats.XP_KILLS, xp or 0)
  if Classification.IsElite(classification) then Stats.Increment(Stats.ELITE_KILLS) end
  if Classification.IsRare(classification) then Stats.Increment(Stats.RARE_KILLS) end
  Journal.AddKill(Journal.PVE, name, classification)
end

---------------------------------------------------------------------------
-- Geheime XP-Meldungen (Retail/Forever seit Midnight, im Kampf und in Instanzen): Text, Name und Menge sind
-- nicht lesbar. Eine solche Meldung im Kampf oder kurz danach gilt als Kill ohne Namen, außer es wurde gerade
-- eine Quest abgegeben. Die XP kommt aus den XP-Gewinnen kurz vor und nach der Meldung (die Reihenfolge der
-- Ereignisse ist nicht festgelegt), daher wird erst nach CLASSIFY_DELAY entschieden. Jeder Gewinn wird nur
-- einem Kill zugeordnet; bei mehreren Kills auf einmal stimmt so die Summe, nicht die Verteilung.
---------------------------------------------------------------------------
local CLASSIFY_DELAY = 0.6        -- s nach der Meldung, bis die zugehörige XP-Änderung sicher da ist
local GAIN_BEFORE_SECONDS = 2     -- s: so lange vor der Meldung darf die XP-Änderung gekommen sein
local AFTER_COMBAT_SECONDS = 3    -- s nach Kampfende zählt eine geheime Meldung noch als Kill
local QUEST_GRACE_SECONDS = 2     -- s um eine Questabgabe herum: Meldung und XP gehören zur Quest
local GAIN_MAX_AGE = GAIN_BEFORE_SECONDS + CLASSIFY_DELAY + 1

local lastCombatEndAt, lastQuestAt
local recentGains = {}  -- { at, amount }, älteste zuerst

local function nearQuest(at)
  return lastQuestAt ~= nil and math.abs(at - lastQuestAt) <= QUEST_GRACE_SECONDS
end

local function inOrJustAfterCombat(now)
  return ns.InCombat() or (lastCombatEndAt ~= nil and now - lastCombatEndAt <= AFTER_COMBAT_SECONDS)
end

local function pruneGains(now)
  while recentGains[1] and now - recentGains[1].at > GAIN_MAX_AGE do
    table.remove(recentGains, 1)
  end
end

-- Summe der noch nicht vergebenen Gewinne im Fenster um die Meldung; vergebene fallen heraus
local function claimGains(messageAt)
  local total, kept = 0, {}
  for _, gain in ipairs(recentGains) do
    local inWindow = gain.at >= messageAt - GAIN_BEFORE_SECONDS and gain.at <= messageAt + CLASSIFY_DELAY
    if inWindow and not nearQuest(gain.at) then
      total = total + gain.amount
    else
      kept[#kept + 1] = gain
    end
  end
  recentGains = kept
  return total
end

local function classifySecretMessage(messageAt)
  if nearQuest(messageAt) then
    ns.Debug("xp", "secret XP message near quest turn-in, not a kill")
    return
  end
  local xp = claimGains(messageAt)
  countKill(nil, xp)
  ns.Debug("xp", "secret XP message counted as kill, %s XP", xp)
end

local function onSecretMessage()
  local now = GetTime()
  if not inOrJustAfterCombat(now) then
    ns.Debug("xp", "secret XP message out of combat, not a kill")
    return
  end
  C_Timer.After(CLASSIFY_DELAY, function() classifySecretMessage(now) end)
end

ns.Experience.OnGain(function(amount)
  local now = GetTime()
  pruneGains(now)
  recentGains[#recentGains + 1] = { at = now, amount = amount }
end)

ns.RegisterEvent("PLAYER_REGEN_ENABLED", function() lastCombatEndAt = GetTime() end)
ns.RegisterEvent("QUEST_TURNED_IN", function() lastQuestAt = GetTime() end)

if COMBATLOG_XPGAIN_FIRSTPERSON then
  local killFormat = ChatPatterns.Compile(COMBATLOG_XPGAIN_FIRSTPERSON)

  ns.RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN", function(message)
    if ns.IsSecret(message) then
      debugXpMessage("DEBUG_XP_SECRET")  -- Inhalt nicht lesbar, daher auch nicht ausgeben
      onSecretMessage()
      return
    end
    local args = ChatPatterns.Match(message, killFormat)
    if args then
      countKill(args[1], tonumber(args[2]))
      debugXpMessage("DEBUG_XP_KILL", message)
    else
      debugXpMessage("DEBUG_XP_OTHER", message)
    end
  end)
end

---------------------------------------------------------------------------
-- PvP-Zähler: ehrenhafte Siege. Der Client liefert nur die Summe seit Login bzw.
-- Tagesbeginn, daher wird die Differenz zum zuletzt gesehenen Wert gezählt.
---------------------------------------------------------------------------
if GetPVPSessionStats then
  local lastHonorableKills = 0

  local function sessionHonorableKills()
    local honorableKills = GetPVPSessionStats()
    if ns.IsSecret(honorableKills) then return nil end
    return honorableKills or 0
  end

  ns.OnLogin(function()
    lastHonorableKills = sessionHonorableKills() or 0
  end)

  ns.RegisterEvent("PLAYER_PVP_KILLS_CHANGED", function()
    local current = sessionHonorableKills()
    if not current then return end
    if current < lastHonorableKills then
      lastHonorableKills = 0  -- Tageswechsel hat die Summe zurückgesetzt
    end
    Stats.Increment(Stats.PVP_KILLS, current - lastHonorableKills)
    lastHonorableKills = current
  end)
end

---------------------------------------------------------------------------
-- PvP-Namen: Ehre-Meldung "X stirbt, ehrenhafter Sieg ...". Liefert nur den Namen fürs
-- Journal; gezählt wird oben, weil die Summe zuverlässiger ist als Chatmeldungen.
---------------------------------------------------------------------------
local honorFormats = ChatPatterns.CompileGlobals({ "COMBATLOG_HONORGAIN", "COMBATLOG_HONORGAIN_NO_RANK" })

if #honorFormats > 0 then
  ns.RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN", function(message)
    if ns.IsSecret(message) then return end
    local args = ChatPatterns.MatchAny(message, honorFormats)
    if args then
      Journal.AddKill(Journal.PVP, args[1])
    end
  end)
end

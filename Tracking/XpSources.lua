-- Weitere XP-Quellen und Kontext (Roadmap 275), als Zähler je Level, Session und Instanz-Lauf:
--   xpExplore  Entdecken: Systemmeldung ERR_ZONE_EXPLORED_XP ("Goldhain entdeckt: 30 Erfahrung erhalten.") mit der Menge
--   xpGather   Sammeln (Kräuter, Erz, Truhen): XP-Gewinn kurz nach CHAT_MSG_OPENING (OPEN_LOCK_SELF "Ihr führt Kräuter
--              sammeln auf ... aus."), außerhalb des Kampfs und nicht bei einer Questabgabe oder Entdeckung
--   xpWorld/xpDungeon/xpRaid/xpBattleground  jeder XP-Gewinn nach Ort (IsInInstance: none, party/scenario, raid, pvp/arena)
-- Die Meldungen gibt es in allen Clients (GlobalStrings, Ketho/BlizzardInterfaceResources); in Classic Era gibt Sammeln
-- keine XP. Geheime Meldungen (Retail/Forever) werden übersprungen. Kills und Quests zählen KillCounter/QuestCounter.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    showXpSources = false,
    showXpContext = false,
  },
  counters = {
    xpExplore = 0,
    xpGather = 0,
    xpWorld = 0,
    xpDungeon = 0,
    xpRaid = 0,
    xpBattleground = 0,
  },
})
local Stats = ns.Stats
local ChatPatterns = ns.ChatPatterns

local XpSources = {}
ns.XpSources = XpSources

local GATHER_WINDOW = 5         -- s nach der Sammel-Meldung, in denen ein XP-Gewinn zum Sammeln gehört
local OTHER_SOURCE_GRACE = 2    -- s um eine Questabgabe/Entdeckung: der Gewinn gehört dorthin

-- Ort eines XP-Gewinns: Zähler je Instanztyp
local CONTEXT_COUNTERS = {
  none = Stats.XP_WORLD,
  party = Stats.XP_DUNGEON,
  scenario = Stats.XP_DUNGEON,
  raid = Stats.XP_RAID,
  pvp = Stats.XP_BATTLEGROUND,
  arena = Stats.XP_BATTLEGROUND,
}

local lastOpeningAt, lastQuestAt, lastExploreAt

local function within(at, seconds, now)
  return at ~= nil and math.abs(now - at) <= seconds
end

local function contextCounter()
  local inInstance, instanceType = IsInInstance()
  if ns.IsSecret(inInstance) or ns.IsSecret(instanceType) then return nil end
  if not inInstance then return Stats.XP_WORLD end
  return CONTEXT_COUNTERS[instanceType]
end

local function isGatherGain(now)
  if not within(lastOpeningAt, GATHER_WINDOW, now) or ns.InCombat() then return false end
  return not within(lastQuestAt, OTHER_SOURCE_GRACE, now) and not within(lastExploreAt, OTHER_SOURCE_GRACE, now)
end

ns.Experience.OnGain(function(amount)
  local now = GetTime()
  local context = contextCounter()
  if context then Stats.Increment(context, amount) end
  if isGatherGain(now) then
    lastOpeningAt = nil  -- je Sammeln nur ein Gewinn
    Stats.Increment(Stats.XP_GATHER, amount)
    ns.Debug("xp", "gathering XP %s", amount)
  end
end)

-- Nur eigenes Sammeln; CHAT_MSG_OPENING meldet auch andere Spieler (OPEN_LOCK_OTHER)
if OPEN_LOCK_SELF then
  local openSelfFormat = ChatPatterns.Compile(OPEN_LOCK_SELF)

  ns.RegisterEvent("CHAT_MSG_OPENING", function(message)
    if ns.IsSecret(message) or not ChatPatterns.Match(message, openSelfFormat) then return end
    lastOpeningAt = GetTime()
  end)
end
ns.RegisterEvent("QUEST_TURNED_IN", function() lastQuestAt = GetTime() end)

if ERR_ZONE_EXPLORED_XP then
  local exploreFormat = ChatPatterns.Compile(ERR_ZONE_EXPLORED_XP)

  ns.RegisterEvent("CHAT_MSG_SYSTEM", function(message)
    if ns.IsSecret(message) then return end
    local args = ChatPatterns.Match(message, exploreFormat)
    local xp = args and tonumber(args[2])
    if not xp then return end
    lastExploreAt = GetTime()
    Stats.Increment(Stats.XP_EXPLORE, xp)
    ns.Debug("xp", "exploration XP %s (%s)", xp, args[1])
  end)
end

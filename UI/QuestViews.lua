-- Quest-Ansichten der Historie (Gruppe "Quests"):
--   Abgabe (Roadmap 345)  alle abgabebereiten Quests des eingeloggten Charakters mit Zone (Überschrift im Questlog),
--                         XP je Quest (QuestLog.RewardXp) und Anteil am aktuellen Level; Summe in der Fußzeile
--                         ("bringt N % Level"). Hilft beim Bündeln vor dem Ruhestein. Andere Charaktere: leer, weil
--                         nur der eigene Questlog lesbar ist. Spalte NPC: gelernter Abgabe-NPC (QuestNpcs.lua).
--   Effizienz (Roadmap 347) je Quest über alle Charaktere: Abgaben, Ø Dauer, Ø XP, XP/min
--                         (History/QuestEfficiency.lua); sortierbar, zeigt Twinks, welche Quests sich lohnen.
local _, ns = ...
local L = ns.L
local Format = ns.Format
local QuestLog = ns.QuestLog
local HistoryTables = ns.HistoryTables

local QuestViews = {}
ns.QuestViews = QuestViews

local GROUP = ns.HistoryTables.ANALYSIS  -- Hauptreiter Auswertung
local LEFT = "LEFT"

local revision = 0  -- Stand des Questlogs: Tabelle filtert und sortiert nur nach Änderungen neu
local function bump() revision = revision + 1 end
ns.RegisterEvent("QUEST_LOG_UPDATE", bump)
ns.RegisterEvent("QUEST_TURNED_IN", bump)
ns.OnLevelStarted(bump)

local function levelXp()
  local max = UnitXPMax("player")
  return not ns.IsSecret(max) and type(max) == "number" and max or 0
end

-- Bündelt abgabebereite Quests zu Hubs (Roadmap 454)
function QuestViews.TurnInHubs(characterKey)
  local hubs = {}
  if characterKey ~= ns.characterKey then return hubs end
  local max = levelXp()
  local ready = {}
  for _, entry in ipairs(QuestLog.Entries()) do
    if entry.ready then
      local xp = QuestLog.RewardXp(entry.questID) or 0
      local npc = ns.QuestNpcs and ns.QuestNpcs.TurnInName and ns.QuestNpcs.TurnInName(entry.questID) or ""
      table.insert(ready, {
        questID = entry.questID,
        title = entry.title,
        zone = entry.header,
        xp = xp,
        share = max > 0 and xp / max or 0,
        level = entry.level,
        npc = npc,
      })
    end
  end

  if #ready == 0 then return hubs end

  local n = #ready
  local parent = {}
  for i = 1, n do parent[i] = i end
  local function find(i)
    local root = i
    while parent[root] ~= root do
      root = parent[root]
    end
    local curr = i
    while curr ~= root do
      local nxt = parent[curr]
      parent[curr] = root
      curr = nxt
    end
    return root
  end

  for i = 1, n do
    for j = i + 1, n do
      if ns.QuestNpcs and ns.QuestNpcs.SameHub
        and ns.QuestNpcs.SameHub(ready[i].questID, ready[j].questID, ready[i].zone, ready[j].zone) then
        local rootI = find(i)
        local rootJ = find(j)
        if rootI ~= rootJ then
          parent[rootJ] = rootI
        end
      end
    end
  end

  local groups = {}
  local groupOrder = {}
  for i = 1, n do
    local root = find(i)
    if not groups[root] then
      groups[root] = {}
      table.insert(groupOrder, root)
    end
    table.insert(groups[root], ready[i])
  end

  for _, root in ipairs(groupOrder) do
    local list = groups[root]
    local totalXp, totalShare = 0, 0
    local npcName, zoneName = "", ""
    for _, q in ipairs(list) do
      totalXp = totalXp + q.xp
      totalShare = totalShare + q.share
      if npcName == "" and q.npc and q.npc ~= "" then
        npcName = q.npc
      end
      if zoneName == "" and q.zone and q.zone ~= "" then
        zoneName = q.zone
      end
    end
    local hubName = npcName ~= "" and npcName or (zoneName ~= "" and zoneName or "")
    local count = #list
    for _, q in ipairs(list) do
      q.hub = hubName
      q.hubCount = count
      q.hubXp = totalXp
      q.hubShare = totalShare
    end
    table.insert(hubs, {
      hub = hubName,
      zone = zoneName,
      npc = npcName,
      count = count,
      xp = totalXp,
      share = totalShare,
      quests = list,
    })
  end

  table.sort(hubs, function(a, b)
    if a.count ~= b.count then
      return a.count > b.count
    end
    if a.xp ~= b.xp then
      return a.xp > b.xp
    end
    if (a.zone or "") ~= (b.zone or "") then
      return (a.zone or "") < (b.zone or "")
    end
    return (a.hub or "") < (b.hub or "")
  end)

  return hubs
end

-- Abgabebereite Quests mit Bündel-Informationen:
-- { questID, title, zone, xp, share, level, npc, hubCount, hubXp }
function QuestViews.TurnInRecords(characterKey)
  local hubs = QuestViews.TurnInHubs(characterKey)
  local records = {}
  for _, hub in ipairs(hubs) do
    for _, q in ipairs(hub.quests) do
      table.insert(records, q)
    end
  end

  table.sort(records, function(a, b)
    local ac, bc = a.hubCount or 0, b.hubCount or 0
    if ac ~= bc then
      return ac > bc
    end
    local ax, bx = a.hubXp or 0, b.hubXp or 0
    if ac > 1 and ax ~= bx then
      return ax > bx
    end
    local az, bz = a.zone or "", b.zone or ""
    if az ~= bz then
      return az < bz
    end
    if ax ~= bx then
      return ax > bx
    end
    return (a.title or "") < (b.title or "")
  end)

  return records
end

local function percent(share)
  return Format.Percent(share, 1)
end

local TURN_IN_COLUMNS = {
  { header = "HISTORY_ZONE", width = 110, align = LEFT, value = function(r) return r.zone or "" end },
  { header = "HISTORY_QUEST", width = 170, align = LEFT, value = function(r) return r.title or L.UNKNOWN_NAME end },
  { header = "HISTORY_LEVEL", width = 40, value = function(r) return r.level or "" end,
    sort = function(r) return r.level end },
  { header = "HISTORY_XP", width = 64, value = function(r) return r.xp > 0 and Format.Number(r.xp) or "-" end,
    sort = function(r) return r.xp end },
  { header = "HISTORY_LEVEL_SHARE", width = 64, value = function(r) return percent(r.share) end,
    sort = function(r) return r.share end },
  { header = "HISTORY_TURN_IN_NPC", width = 110, align = LEFT, value = function(r)
      local npc = r.npc or (ns.QuestNpcs and ns.QuestNpcs.TurnInName and ns.QuestNpcs.TurnInName(r.questID)) or ""
      if r.hubCount and r.hubCount > 1 then
        return npc ~= "" and string.format("%s (%d×)", npc, r.hubCount)
          or string.format("%s (%d×)", r.zone or "", r.hubCount)
      end
      return npc
    end,
    sort = function(r) return r.hubCount or 0 end },
}

-- Fußzeile: Anzahl, XP-Summe, Anteil am Level
local function turnInFooter(columns, records)
  local cells = HistoryTables.CountCells(columns, records)
  local xp, share = 0, 0
  for _, record in ipairs(records) do
    xp, share = xp + record.xp, share + record.share
  end
  cells[4] = Format.Number(xp)
  cells[5] = percent(share)
  return cells
end

ns.HistoryWindow.AddView(ns.TableView.Create({
  tab = "HISTORY_TAB_TURN_IN",
  group = GROUP,
  columns = TURN_IN_COLUMNS,
  records = QuestViews.TurnInRecords,
  footer = turnInFooter,
  revision = function()
    return revision + (ns.QuestNpcs and ns.QuestNpcs.Revision and ns.QuestNpcs.Revision() or 0)
  end,
  rowLink = function(r) return "quest:" .. r.questID end,
  hint = "TURN_IN_HINT",
  -- Andere Charaktere: leer, weil nur der eigene Questlog lesbar ist (nicht "noch nichts aufgezeichnet")
  empty = function(characterKey)
    return characterKey == ns.characterKey and L.TURN_IN_EMPTY or L.TURN_IN_OTHER_CHARACTER
  end,
}))

local EFFICIENCY_COLUMNS = {
  { header = "HISTORY_QUEST", width = 170, align = LEFT, value = function(r) return r.name or L.UNKNOWN_NAME end },
  { header = "HISTORY_TURN_INS", width = 56, value = function(r) return r.count end, sort = function(r) return r.count end },
  { header = "HISTORY_AVERAGE_TIME", width = 64, value = function(r)
      return r.averageSeconds and Format.Duration(r.averageSeconds) or "-"
    end, sort = function(r) return r.averageSeconds end },
  { header = "HISTORY_AVERAGE_XP", width = 64, value = function(r)
      return r.averageXp and Format.Number(math.floor(r.averageXp + 0.5)) or "-"
    end, sort = function(r) return r.averageXp end },
  { header = "HISTORY_XP_PER_MINUTE", width = 64, value = function(r)
      return r.xpPerMinute and Format.Number(math.floor(r.xpPerMinute + 0.5)) or "-"
    end, sort = function(r) return r.xpPerMinute end },
}

ns.HistoryWindow.AddView(ns.TableView.Create({
  tab = "HISTORY_TAB_QUEST_EFFICIENCY",
  group = GROUP,
  allCharacters = true,
  columns = EFFICIENCY_COLUMNS,
  records = function() return ns.QuestEfficiency.GetRecords() end,
  footer = HistoryTables.CountCells,
  revision = ns.Journal.Revision,
  rowLink = function(r) return "quest:" .. r.questID end,
  hint = "QUEST_EFFICIENCY_HINT",
}))

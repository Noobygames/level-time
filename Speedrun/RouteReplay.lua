-- Eigene Route nachspielen (LT-262): die Reihenfolge der abgegebenen Quests des besten eigenen Laufs (anderer
-- Charakter: höchstes erreichtes Level, bei Gleichstand die geringste Summe der Level-Zeiten) als Checkliste für den
-- eingeloggten Charakter. Schritte = Journal questLog dieses Charakters (Journal.GetEntries), jede Quest einmal, in
-- der Reihenfolge der Abgaben. Erledigt = QuestItemTooltip.IsQuestDone; die nächsten NEXT_COUNT offenen Schritte
-- sind "next". Anzeige: UI/RouteReplayWindow.lua (Einstellung routeReplay, /lt route).
-- shortcut: Quelle immer automatisch, Klasse/Fraktion nicht abgeglichen; Vorsprung/Rückstand je Schritt fehlt.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    routeReplay = false,
  },
})

local RouteReplay = {
  NEXT_COUNT = 3,
}
ns.RouteReplay = RouteReplay

local function totalSeconds(run)
  local sum = 0
  for _, seconds in pairs(run.times) do sum = sum + seconds end
  return sum
end

local function isBetter(run, best)
  if not best then return true end
  if run.reachedLevel ~= best.reachedLevel then return run.reachedLevel > best.reachedLevel end
  return totalSeconds(run) < totalSeconds(best)
end

-- Bester eigener Lauf eines anderen Charakters mit abgegebenen Quests; nil ohne
function RouteReplay.SourceRun()
  local best
  for _, run in ipairs(ns.Runs.GetAll()) do
    if not run.imported and run.id ~= ns.characterKey and #ns.Journal.GetEntries(run.id, "questLog") > 0
        and isBetter(run, best) then
      best = run
    end
  end
  return best
end

-- { run, steps = { { questID, name, level, status = "done"|"next"|"open" }, ... }, done = Anzahl erledigt }; nil ohne Quelle
function RouteReplay.Get()
  local run = RouteReplay.SourceRun()
  if not run then return nil end
  local steps, seen, done, open = {}, {}, 0, 0
  for _, entry in ipairs(ns.Journal.GetEntries(run.id, "questLog")) do
    local questID = entry.questID
    if type(questID) == "number" and not seen[questID] then
      seen[questID] = true
      local status = "open"
      if ns.QuestItemTooltip.IsQuestDone(questID) then
        status, done = "done", done + 1
      elseif open < RouteReplay.NEXT_COUNT then
        status, open = "next", open + 1
      end
      steps[#steps + 1] = { questID = questID, name = entry.name or ("#" .. questID), level = entry.level, status = status }
    end
  end
  return { run = run, steps = steps, done = done }
end

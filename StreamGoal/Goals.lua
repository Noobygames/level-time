-- Ziel-Modell: anlegen, Fortschritt buchen, abschließen, abbrechen, Historie. Welche Zielarten es gibt, steht in
-- Kinds.lua; welche Ereignisse sie füttern, in Tracking.lua.
--
-- Ziel: { id, kind, character, createdAt, target, start, progress, params, status, finishedAt }
--   character = Schlüssel "Name-Realm" von Level Time; ein Ziel läuft nur, solange dieser Charakter eingeloggt ist.
--   start/progress: Zählerstand beim Anlegen und jetzt (Level: das Level, sonst 0 und gezählte Stücke).
--   status: "active", "done" oder "cancelled"; finishedAt = Zeitpunkt des Abschlusses (Historie).
-- Zielarten mit manual = true zählt der Spieler selbst (Klick auf die Karte, Fenster, /sg count), siehe Goals.Step.
local _, ns = ...
local LT = ns.LT

local Goals = {}
ns.Goals = Goals

Goals.ACTIVE, Goals.DONE, Goals.CANCELLED = "active", "done", "cancelled"
Goals.MAX_ACTIVE = 6    -- gleichzeitig laufende Ziele je Charakter (so viele Zeilen zeigt das Fenster)
Goals.MAX_HISTORY = 500  -- abgeschlossene Ziele; die ältesten fallen weg

local kinds = {}
local listeners = {}

-- Laufende Ziele des eingeloggten Charakters, insgesamt und je Art: jeder Kill und jede Beute fragt danach, die Liste
-- aller Ziele samt Historie hat bis zu MAX_HISTORY Einträge. Neu gebaut, wenn sich die Ziele ändern (Anlegen,
-- Abschließen, Abbrechen: stamp) oder die Liste selbst (andere Tabelle, andere Länge, anderer Charakter).
local stamp = 0
local active = {}  -- { goals, count, character, stamp, list, byKind = { [Art] = { Ziele } }, byId }
local NO_GOALS = {}

local function changed()
  stamp = stamp + 1
end

local function index()
  local goals = ns.db.goals
  local cached = active
  if cached.goals == goals and cached.count == #goals and cached.character == LT.characterKey
    and cached.stamp == stamp then
    return cached
  end
  local list, byKind, byId = {}, {}, {}
  for _, goal in ipairs(goals) do
    byId[goal.id] = byId[goal.id] or goal
    if goal.status == Goals.ACTIVE and goal.character == LT.characterKey then
      table.insert(list, goal)
      byKind[goal.kind] = byKind[goal.kind] or {}
      table.insert(byKind[goal.kind], goal)
    end
  end
  active = { goals = goals, count = #goals, character = LT.characterKey, stamp = stamp, list = list,
    byKind = byKind, byId = byId }
  return active
end

-- Zielart anmelden; def siehe Kinds.lua
function Goals.RegisterKind(name, def)
  kinds[name] = def
end

function Goals.GetKind(name)
  return kinds[name]
end

-- Auf Änderungen reagieren: listener(event, goal) mit event = "added", "progress", "done" oder "cancelled"
function Goals.OnChange(listener)
  table.insert(listeners, listener)
end

local function notify(event, goal)
  ns.Debug("goals", "%s #%s %s %s/%s", event, goal.id, goal.kind, goal.progress, goal.target)
  for _, listener in ipairs(listeners) do
    LT.SafeCall(listener, event, goal)
  end
end

-- Neues Ziel für den eingeloggten Charakter. Rückgabe: Ziel, oder nil und eine Fehlermeldung (übersetzt)
function Goals.Create(kind, params, target)
  local def = kinds[kind]
  if not def then return nil, string.format(ns.L.SG_ERR_UNKNOWN_KIND, tostring(kind)) end
  params = params or {}
  if def.prepare then target = def.prepare(params, target) end
  local err = def.validate(params, target)
  if err then return nil, err end
  if #Goals.Active() >= Goals.MAX_ACTIVE then return nil, string.format(ns.L.SG_ERR_TOO_MANY, Goals.MAX_ACTIVE) end

  local start = def.initial and def.initial() or 0
  local goal = {
    id = ns.db.nextId,
    kind = kind,
    character = LT.characterKey,
    createdAt = time(),
    target = target,
    start = start,
    progress = start,
    params = params,
    status = Goals.ACTIVE,
  }
  ns.db.nextId = goal.id + 1
  table.insert(ns.db.goals, goal)
  changed()
  notify("added", goal)
  return goal
end

function Goals.Get(id)
  return index().byId[id]
end

-- Laufende Ziele des eingeloggten Charakters, älteste zuerst (zwischengespeichert, nicht verändern)
function Goals.Active()
  return index().list
end

-- Abgeschlossene und abgebrochene Ziele aller Charaktere, neueste zuerst
function Goals.History()
  local list = {}
  for _, goal in ipairs(ns.db.goals) do
    if goal.status ~= Goals.ACTIVE then table.insert(list, goal) end
  end
  table.sort(list, function(a, b) return (a.finishedAt or 0) > (b.finishedAt or 0) end)
  return list
end

-- Anteil 0..1 zwischen Startstand und Ziel
function Goals.Fraction(goal)
  local span = goal.target - goal.start
  if span <= 0 then return 1 end
  return math.max(0, math.min(1, (goal.progress - goal.start) / span))
end

function Goals.Title(goal)
  return kinds[goal.kind].title(goal)
end

-- Zeigt das Ziel einen Zählerstand "4 / 5"? Nein bei Arten, die nur erledigt oder offen sind (eigenes Ziel ohne Zähler)
function Goals.HasCount(goal)
  local def = kinds[goal.kind]
  return not def.hasCount or def.hasCount(goal)
end

-- Darf der Spieler den Stand selbst ändern?
function Goals.IsManual(goal)
  return kinds[goal.kind].manual == true
end

-- Älteste abgeschlossene Ziele verwerfen, wenn es mehr als MAX_HISTORY gibt
local function trimHistory()
  local history = Goals.History()
  local excess = #history - Goals.MAX_HISTORY
  if excess <= 0 then return end
  local doomed = {}
  for i = 0, excess - 1 do doomed[history[#history - i]] = true end
  local kept = {}
  for _, goal in ipairs(ns.db.goals) do
    if not doomed[goal] then table.insert(kept, goal) end
  end
  ns.db.goals = kept
end

local function finish(goal, status)
  goal.status = status
  goal.finishedAt = time()
  changed()
  trimHistory()
  notify(status, goal)
end

function Goals.Cancel(id)
  local goal = Goals.Get(id)
  if not goal or goal.status ~= Goals.ACTIVE then return nil end
  finish(goal, Goals.CANCELLED)
  return goal
end

-- Fortschritt buchen und bei Erreichen des Ziels abschließen
local function advance(goal, progress)
  if progress == goal.progress then return end
  goal.progress = progress
  if progress >= goal.target then
    goal.progress = goal.target
    finish(goal, Goals.DONE)
  else
    notify("progress", goal)
  end
end

-- Stand eines selbst gezählten Ziels um delta ändern (nie unter den Startstand). Rückgabe: Ziel oder nil und
-- Fehlertext (unbekannte Nummer, Ziel zählt automatisch)
function Goals.Step(id, delta)
  local goal = Goals.Get(id)
  if not goal or goal.status ~= Goals.ACTIVE or goal.character ~= LT.characterKey then
    return nil, string.format(ns.L.SG_ERR_NO_GOAL, tostring(id or "?"))
  end
  if not Goals.IsManual(goal) then return nil, string.format(ns.L.SG_ERR_NOT_MANUAL, goal.id) end
  advance(goal, math.max(goal.start, goal.progress + delta))
  return goal
end

-- amount dazuzählen bei allen laufenden Zielen dieser Art, für die matches(goal) stimmt. Abschließen baut den Index
-- neu (neue Listen), die durchlaufene Liste bleibt dabei unverändert.
function Goals.Add(kind, matches, amount)
  for _, goal in ipairs(index().byKind[kind] or NO_GOALS) do
    if goal.status == Goals.ACTIVE and matches(goal) then
      advance(goal, goal.progress + amount)
    end
  end
end

-- Stand setzen (z.B. das Level) bei allen laufenden Zielen dieser Art
function Goals.Set(kind, value)
  for _, goal in ipairs(index().byKind[kind] or NO_GOALS) do
    if goal.status == Goals.ACTIVE then advance(goal, value) end
  end
end

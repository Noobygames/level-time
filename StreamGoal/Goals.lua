-- Ziel-Modell: anlegen, Fortschritt buchen, abschließen, abbrechen, Historie. Welche Zielarten es gibt, steht in
-- Kinds.lua; welche Ereignisse sie füttern, in Tracking.lua.
--
-- Ziel: { id, kind, character, createdAt, target, start, progress, params, status, finishedAt, source }
--   character = Schlüssel "Name-Realm" von Level Time; ein Ziel läuft nur, solange dieser Charakter eingeloggt ist.
--   start/progress: Zählerstand beim Anlegen und jetzt (Level: das Level, sonst 0 und gezählte Stücke).
--   status: "active", "done", "cancelled" oder "failed"; finishedAt = Zeitpunkt des Abschlusses (Historie).
-- Zielarten mit manual = true zählt der Spieler selbst (Klick auf die Karte, Fenster, /sg count), siehe Goals.Step.
local _, ns = ...
local LT = ns.LT
local L = ns.L

local Goals = {}
ns.Goals = Goals

Goals.ACTIVE, Goals.DONE, Goals.CANCELLED, Goals.FAILED = "active", "done", "cancelled", "failed"
Goals.MAX_ACTIVE = 6    -- gleichzeitig laufende Ziele je Charakter (so viele Zeilen zeigt das Fenster)
Goals.MAX_HISTORY = 500  -- abgeschlossene Ziele; die ältesten fallen weg

local kinds = {}
local kindOrder = {}  -- Reihenfolge der Anmeldung = Reihenfolge der Reiter im Fenster
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
  local list, byKind, byId, slots = {}, {}, {}, 0
  for _, goal in ipairs(goals) do
    byId[goal.id] = byId[goal.id] or goal
    if goal.status == Goals.ACTIVE and goal.character == LT.characterKey then
      table.insert(list, goal)
      byKind[goal.kind] = byKind[goal.kind] or {}
      table.insert(byKind[goal.kind], goal)
      if not goal.cell then slots = slots + 1 end
    end
  end
  active = { goals = goals, count = #goals, character = LT.characterKey, stamp = stamp, list = list,
    byKind = byKind, byId = byId, slots = slots }
  return active
end

-- Zielart anmelden; def siehe Kinds.lua
function Goals.RegisterKind(name, def)
  if not kinds[name] then table.insert(kindOrder, name) end
  def.name = name
  kinds[name] = def
end

-- Namen aller Zielarten in Anmelde-Reihenfolge (nicht verändern), auch der im Client nicht verfügbaren
function Goals.KindOrder()
  return kindOrder
end

-- Gruppen der Zielarten: Reihenfolge der Kacheln im Fenster (Window/KindPicker.lua), verwandte Arten stehen so
-- nebeneinander; eine Art nennt ihre Gruppe in def.group. Arten ohne bekannte Gruppe stehen in der letzten.
Goals.KIND_GROUPS = {
  { key = "progress" },
  { key = "combat" },
  { key = "loot" },
  { key = "quests" },
  { key = "fun" },
}

-- Gruppe (key) einer Art
function Goals.GroupOf(kind)
  local group = kinds[kind] and kinds[kind].group
  for _, entry in ipairs(Goals.KIND_GROUPS) do
    if entry.key == group then return group end
  end
  return Goals.KIND_GROUPS[#Goals.KIND_GROUPS].key
end

-- Arten einer Gruppe in Anmelde-Reihenfolge (neue Liste), auch die im Client nicht verfügbaren
function Goals.KindsOfGroup(group)
  local list = {}
  for _, kind in ipairs(kindOrder) do
    if Goals.GroupOf(kind) == group then table.insert(list, kind) end
  end
  return list
end

-- Gibt es die Art in diesem Client? def.available() optional (z.B. Erfolge nicht in Classic Era)
function Goals.IsAvailable(kind)
  local def = kinds[kind]
  return def ~= nil and (not def.available or def.available() and true or false)
end

function Goals.GetKind(name)
  return kinds[name]
end

-- Auf Änderungen reagieren: listener(event, goal) mit event = "added", "progress", "changed", "done", "cancelled",
-- "failed" oder "removed" (Aufräumen, goal = nil)
function Goals.OnChange(listener)
  table.insert(listeners, listener)
end

local function notify(event, goal)
  ns.Debug("goals", "%s #%s %s %s/%s", event, goal.id, goal.kind, goal.progress, goal.target)
  for _, listener in ipairs(listeners) do
    LT.SafeCall(listener, event, goal)
  end
end

-- Flache Kopie mit nur Texten, Zahlen und Wahrheitswerten (Eingaben, Vorlagen, Import); andere Werte fallen weg
function Goals.CopyFlat(values)
  local copy = {}
  for key, value in pairs(values or {}) do
    local kind = type(value)
    if type(key) == "string" and (kind == "string" or kind == "number" or kind == "boolean") then copy[key] = value end
  end
  return copy
end

-- Zusätze, die jede Zielart haben kann (Frist, Belohnung, Punkte): Goals.RegisterExtra(name, { fields = Formularfelder
-- (wie def.form.fields, unter dem Formular jeder Art), validate(extras) -> Fehlertext oder nil, apply(goal, extras),
-- line(goal) optional: Zeile auf der Karte, fill(goal) -> { param = Wert } und update(goal, extras, changed) optional:
-- Bearbeiten eines laufenden Ziels, siehe Goals.Edit });
-- extras = Tabelle aus Formular oder Befehl (Felder je Zusatz)
local extraHandlers = {}
local extraFields = {}

function Goals.RegisterExtra(name, handler)
  handler.name = name
  table.insert(extraHandlers, handler)
  for _, field in ipairs(handler.fields or {}) do table.insert(extraFields, field) end
end

-- Formularfelder aller Zusätze (nicht verändern)
function Goals.ExtraFields()
  return extraFields
end

local function validateExtras(extras)
  for _, handler in ipairs(extraHandlers) do
    local err = handler.validate(extras)
    if err then return err end
  end
end

-- Belegte Plätze (höchstens MAX_ACTIVE): laufende Ziele ohne Felder eines Bingo-Scheins (goal.cell)
function Goals.UsedSlots()
  return index().slots
end

-- Eingabe prüfen, ohne ein Ziel anzulegen (Vorlagen für Bingo und Glücksrad): Art bekannt, prepare und validate
-- auf Kopien. Bestand (def.current) und freie Plätze prüft erst Goals.Create. Rückgabe: Fehlertext oder nil
function Goals.Check(kind, params, target)
  local def = kinds[kind]
  if not def or not Goals.IsAvailable(kind) then return string.format(L.SG_ERR_UNKNOWN_KIND, tostring(kind)) end
  local copy = Goals.CopyFlat(params)
  if def.prepare then target = def.prepare(copy, target) end
  return def.validate(copy, target)
end

-- Neues Ziel für den eingeloggten Charakter; extras optional (Goals.RegisterExtra), parent optional: Feld eines
-- Bingo-Scheins (goal.parentId, goal.cell; belegt keinen Platz). Rückgabe: Ziel, oder nil und Fehlertext (übersetzt)
function Goals.Create(kind, params, target, extras, parent)
  local def = kinds[kind]
  if not def or not Goals.IsAvailable(kind) then return nil, string.format(L.SG_ERR_UNKNOWN_KIND, tostring(kind)) end
  params = params or {}
  extras = extras or {}
  local source = { kind = kind, params = Goals.CopyFlat(params), target = target, extras = Goals.CopyFlat(extras) }
  if def.prepare then target = def.prepare(params, target) end
  local err = def.validate(params, target) or validateExtras(extras)
  if err then return nil, err end
  if not parent and Goals.UsedSlots() >= Goals.MAX_ACTIVE then
    return nil, string.format(L.SG_ERR_TOO_MANY, Goals.MAX_ACTIVE)
  end

  local start = def.initial and def.initial(params) or 0
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
    source = source,  -- Eingabe vor prepare: daraus baut Packs.lua Vorlagen und Export
  }
  -- Bestands-Ziele (Gold besitzen, Items in den Taschen): der Stand ist der Bestand, schon erreicht = kein Ziel
  if def.current then
    local now = def.current(goal) or 0
    if now >= target then return nil, L.SG_ERR_ALREADY_REACHED end
    goal.progress = now
    if def.startAtCurrent then goal.start = now end
  end
  for _, handler in ipairs(extraHandlers) do handler.apply(goal, extras) end
  if parent then goal.parentId, goal.cell = parent.id, true end
  ns.db.nextId = goal.id + 1
  table.insert(ns.db.goals, goal)
  changed()
  if def.afterCreate then def.afterCreate(goal) end  -- z.B. Bingo legt seine Felder an
  notify("added", goal)
  return goal
end

---------------------------------------------------------------------------
-- Laufendes Ziel bearbeiten (Fenster, UX G17)
---------------------------------------------------------------------------
-- Was sich an einem laufenden Ziel ändern lässt: def.editable = { "amount" (das Ziel), param, ... }. Nur Angaben,
-- die den bisherigen Stand nicht entwerten (Text, Notiz, Zielzahl); Item, Modus oder Filter ändern hieße ein neues Ziel.
function Goals.IsEditable(kind, param)
  local def = kinds[kind]
  for _, name in ipairs(def and def.editable or NO_GOALS) do
    if name == param then return true end
  end
  return false
end

-- Zusätze eines laufenden Ziels als Eingabe fürs Formular (fill(goal) je Zusatz): { param = Wert }
function Goals.ExtraValues(goal)
  local values = {}
  for _, handler in ipairs(extraHandlers) do
    if handler.fill then
      for param, value in pairs(handler.fill(goal)) do values[param] = value end
    end
  end
  return values
end

-- Eingabe auf ein laufendes Ziel anwenden: params/target wie aus dem Formular (nur die in def.editable genannten
-- zählen; def.editDerived = Werte, die prepare daraus ableitet, z.B. counted beim Freitext), extras die Zusätze,
-- changedExtras[param] = true für jeden geänderten Zusatz (update(goal, extras, changedExtras) je Zusatz). Erst wird
-- alles geprüft, dann geändert. Arten ohne editable behalten ihre Angaben (keine erneute Prüfung, die z.B. beim Ruf
-- vom Zustand des Spiels abhinge). Rückgabe: Fehlertext oder nil
local function editKindData(goal, def, params, target)
  local editable = def.editable or NO_GOALS
  if #editable == 0 then return nil end
  local source = goal.source
  local input = Goals.CopyFlat(source.params)
  for _, name in ipairs(editable) do
    if name ~= "amount" then input[name] = params and params[name] end
  end
  local editTarget = Goals.IsEditable(goal.kind, "amount")
  local inputTarget = editTarget and target or source.target
  local prepared = Goals.CopyFlat(input)
  local preparedTarget = inputTarget
  if def.prepare then preparedTarget = def.prepare(prepared, inputTarget) end
  local err = def.validate(prepared, preparedTarget)
  if err then return err end
  if editTarget and preparedTarget ~= goal.target and preparedTarget <= goal.progress then
    return string.format(L.SG_ERR_EDIT_TARGET, Goals.CountText(goal))
  end
  return nil, function()
    for _, name in ipairs(editable) do
      if name ~= "amount" then goal.params[name] = prepared[name] end
    end
    for _, name in ipairs(def.editDerived or NO_GOALS) do goal.params[name] = prepared[name] end
    if editTarget then goal.target = preparedTarget end
    source.params, source.target = input, inputTarget
  end
end

function Goals.Edit(goal, params, target, extras, changedExtras)
  if not goal or goal.status ~= Goals.ACTIVE or goal.character ~= LT.characterKey then
    return string.format(L.SG_ERR_NO_GOAL, tostring(goal and goal.id or "?"))
  end
  local def = kinds[goal.kind]
  goal.source = goal.source or { kind = goal.kind, params = {}, target = goal.target }
  goal.source.extras = goal.source.extras or {}
  extras = extras or {}
  local err, apply = editKindData(goal, def, params, target)
  err = err or validateExtras(extras)
  if err then return err end
  if apply then apply() end
  for _, handler in ipairs(extraHandlers) do
    if handler.update then handler.update(goal, extras, changedExtras or {}) end
  end
  changed()
  notify("changed", goal)
  return nil
end

-- Ein Zusatz (Frist, Belohnung) wurde nachträglich geändert: Anzeigen neu aufbauen
function Goals.Changed(goal)
  notify("changed", goal)
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

-- Anteil 0..1 zwischen Startstand und Ziel; Arten mit partial(goal) (0..1 bis zum nächsten Stand, z.B. XP im
-- laufenden Level) füllen den Balken auch zwischen zwei Ständen
function Goals.Fraction(goal)
  local span = goal.target - goal.start
  if span <= 0 then return 1 end
  local def = kinds[goal.kind]
  local partial = def and def.partial and def.partial(goal) or 0
  return math.max(0, math.min(1, (goal.progress - goal.start + partial) / span))
end

function Goals.Title(goal)
  return kinds[goal.kind].title(goal)
end

-- Zweite Zeile der Karte (nil = keine): Zeile der Art, darunter die der Zusätze (line(goal) einer Anmeldung)
function Goals.Body(goal)
  local def = kinds[goal.kind]
  local body = def.body and def.body(goal) or nil
  for _, handler in ipairs(extraHandlers) do
    local line = handler.line and handler.line(goal)
    if line then body = body and (body .. "\n" .. line) or line end
  end
  return body
end

-- Stand als Text "12 / 100"; Arten mit eigener Einheit (Gold) formatieren selbst
function Goals.CountText(goal)
  local def = kinds[goal.kind]
  if def.countText then return def.countText(goal) end
  return string.format("%d / %d", goal.progress, goal.target)
end

-- Zeigt das Ziel einen Zählerstand "4 / 5"? Nein bei Arten, die nur erledigt oder offen sind (Freitext ohne Zähler)
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

-- Erreicht ohne Zählerereignis (Regel bis zum Ende der Frist gehalten)
function Goals.Complete(goal)
  if goal.status ~= Goals.ACTIVE then return end
  goal.progress = math.max(goal.progress, goal.target)
  finish(goal, Goals.DONE)
end

-- Gescheitert (Frist abgelaufen, Regel gebrochen); reason = Text für Historie und Meldung (optional)
function Goals.Fail(goal, reason)
  if goal.status ~= Goals.ACTIVE then return end
  goal.failReason = reason
  finish(goal, Goals.FAILED)
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
    return nil, string.format(L.SG_ERR_NO_GOAL, tostring(id or "?"))
  end
  if not Goals.IsManual(goal) then return nil, string.format(L.SG_ERR_NOT_MANUAL, goal.id) end
  local step = kinds[goal.kind].step
  advance(goal, step and step(goal, delta) or math.max(goal.start, goal.progress + delta))
  return goal
end

-- Würde ein Schritt um delta das Ziel abschließen? (Klick-Bestätigung, ClickStep.lua). Ohne den Schritt der Art
-- aufzurufen (der der Checkliste hakt schon ab); auch dort zählt ein Schritt genau eins.
function Goals.WouldComplete(goal, delta)
  return goal.status == Goals.ACTIVE and delta > 0 and goal.progress + delta >= goal.target
end

-- Ziel (Stand und/oder Ziel) neu bewerten, z.B. eine Checkliste nach einem neuen Teilziel; schließt bei Erreichen ab
function Goals.Update(goal, progress)
  if goal.status ~= Goals.ACTIVE then return end
  if progress == goal.progress then
    notify("changed", goal)
    return
  end
  advance(goal, progress)
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

-- Stand je Ziel setzen: valueOf(goal) -> neuer Stand oder nil (unverändert), z.B. Bestand in den Taschen je Item
function Goals.SetEach(kind, valueOf)
  for _, goal in ipairs(index().byKind[kind] or NO_GOALS) do
    if goal.status == Goals.ACTIVE then
      local value = valueOf(goal)
      if value then advance(goal, value) end
    end
  end
end

-- Läuft gerade ein Ziel dieser Art? (Erfassung meldet sich nur dann für teure Ereignisse an)
function Goals.HasActive(kind)
  return (index().byKind[kind] or NO_GOALS)[1] ~= nil
end

---------------------------------------------------------------------------
-- Aufräumen (Einstellungen > Daten)
---------------------------------------------------------------------------
-- Gehört das Ziel einem Charakter, den Level Time nicht mehr kennt (gelöscht)?
local function isOrphan(goal, characters)
  return characters[goal.character] == nil
end

-- Ziele (laufende und Historie) von Charakteren, die es in Level Time nicht mehr gibt
function Goals.CountOrphans()
  local characters = LT.Database.GetCharacters()
  local count = 0
  for _, goal in ipairs(ns.db.goals) do
    if isOrphan(goal, characters) then count = count + 1 end
  end
  return count
end

local function removeWhere(predicate)
  local kept, removed = {}, 0
  for _, goal in ipairs(ns.db.goals) do
    if predicate(goal) then removed = removed + 1 else table.insert(kept, goal) end
  end
  if removed == 0 then return 0 end
  ns.db.goals = kept
  changed()
  for _, listener in ipairs(listeners) do LT.SafeCall(listener, "removed") end
  return removed
end

function Goals.RemoveOrphans()
  local characters = LT.Database.GetCharacters()
  return removeWhere(function(goal) return isOrphan(goal, characters) end)
end

-- Ganze Historie (abgeschlossene, abgebrochene, gescheiterte Ziele aller Charaktere) löschen
function Goals.ClearHistory()
  return removeWhere(function(goal) return goal.status ~= Goals.ACTIVE end)
end

-- Level Time löscht einen Charakter (Historie > Löschen): seine laufenden Ziele gelten als abgebrochen, sonst
-- blieben sie unsichtbar aktiv (Roadmap 312)
LT.Database.OnCharacterDeleted(function(characterKey)
  if not ns.db then return end
  for _, goal in ipairs(ns.db.goals) do
    if goal.character == characterKey and goal.status == Goals.ACTIVE then
      goal.status = Goals.CANCELLED
      goal.finishedAt = time()
      goal.orphaned = true
    end
  end
  changed()
end)

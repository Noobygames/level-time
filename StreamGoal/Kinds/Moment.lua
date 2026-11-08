-- Zielart Momente (Roadmap 439): kleine Erlebnisse, die das Spiel selbst erkennt und die früher Freitexte im Bingo
-- waren ("Einen Rare-Gegner sehen", "Schwimmen gehen", ...). Eine Art mit einer Auswahl "Was"; jede Erkennung steht in
-- einer eigenen Datei unter Kinds/Moments/ und meldet sich mit Moments.Register an:
--   Moments.Register(mode, { label, title, icon, available(), events, task = { seconds, fn } })
--     label      Locale-Key in der Auswahl (Tooltip-Erklärung der Auswahl: SG_FORM_MOMENT_TIP nennt alle)
--     title      Locale-Key des Kartentitels mit %d (Einzahl <title>_ONE, Kinds.Counted)
--     icon       Symbol der Karte (Pfad)
--     available  (optional) false = der Client kann es nicht erkennen: der Modus fehlt in Auswahl, Befehl und Pool
--     events     (optional) LT.NewEventGroup(): nur angemeldet, solange ein Ziel dieses Modus läuft
--     task       (optional) { seconds, fn }: regelmäßige Prüfung, nur solange ein Ziel dieses Modus läuft
--     onActive   (optional) onActive(isActive) nach jeder Änderung der Ziele (Zustand zurücksetzen, Fenster schon offen)
--   Moments.Count(mode, amount) zählt bei allen laufenden Zielen dieses Modus.
-- params: { mode = Name }
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local Kinds = ns.Kinds
local L = ns.L

local Moments = {}
ns.Moments = Moments

Moments.MODES = {}   -- verfügbare Modi in Anmelde-Reihenfolge (Werte der Auswahl im Formular)
local LABELS = {}    -- Modus -> Locale-Key der Auswahl
local defs = {}
local active = {}    -- [Modus] = true, solange ein Ziel dieses Modus läuft
local ICON = "Interface\\Icons\\Spell_Holy_MindVision"

-- Modus anmelden; Rückgabe: true, wenn der Client ihn erkennen kann
function Moments.Register(mode, def)
  if def.available and not def.available() then return false end
  def.mode = mode
  defs[mode] = def
  LABELS[mode] = def.label
  table.insert(Moments.MODES, mode)
  if def.task then
    LT.Every(def.task.seconds, def.task.fn, function() return active[mode] == true end)
  end
  return true
end

function Moments.Get(mode)
  return defs[mode]
end

-- Läuft ein Ziel dieses Modus?
function Moments.IsActive(mode)
  return active[mode] == true
end

function Moments.Count(mode, amount)
  if not ns.db or not active[mode] then return end
  ns.Debug("moment", "%s +%s", mode, amount or 1)
  Goals.Add("moment", function(goal) return goal.params.mode == mode end, amount or 1)
end

Goals.RegisterKind("moment", {
  label = "SG_KIND_MOMENT",
  group = "fun",
  usage = "SG_USAGE_MOMENT",
  color = LT.Theme.COLORS.success,
  icon = ICON,
  available = function() return #Moments.MODES > 0 end,
  texture = function(goal)
    local def = defs[goal.params.mode]
    return def and def.icon or nil
  end,
  editable = { "amount" },  -- nur die Zielzahl; was gezählt wird, gilt ab dem Anlegen
  -- Auswahl zuerst, darunter die Anzahl
  form = { fields = {
    { type = "choice", param = "mode", label = "SG_FORM_MOMENT", values = Moments.MODES, labels = LABELS },
    { type = "amount", label = "SG_FORM_AMOUNT" },
  } },
  -- "add moment swim [Anzahl]"
  parse = function(args)
    local params, amount = {}, nil
    for _, word in ipairs(args) do
      local lower = word:lower()
      if defs[lower] then params.mode = lower else amount = amount or tonumber(word) end
    end
    return params, amount
  end,
  prepare = function(_, target) return target or Kinds.DEFAULT_AMOUNT end,
  validate = function(params, target)
    if not defs[params.mode] then return string.format(L.SG_ERR_MOMENT, table.concat(Moments.MODES, ", ")) end
    return Kinds.ValidAmount(target)
  end,
  title = function(goal)
    local def = defs[goal.params.mode]
    if not def then return L.SG_KIND_MOMENT end
    return Kinds.Counted(def.title, goal.target)
  end,
})

---------------------------------------------------------------------------
-- Erfassung nur für die Modi laufender Ziele
---------------------------------------------------------------------------
local function update()
  for mode in pairs(active) do active[mode] = nil end
  if ns.db then
    for _, goal in ipairs(Goals.Active()) do
      if goal.kind == "moment" and goal.params.mode then active[goal.params.mode] = true end
    end
  end
  for mode, def in pairs(defs) do
    if def.events then def.events.SetActive(active[mode] == true) end
    if def.onActive then def.onActive(active[mode] == true) end
  end
  LT.RefreshTasks()
end

Goals.OnChange(update)
LT.OnLogin(update)

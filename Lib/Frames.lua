-- Ein Positionssystem für alle verschiebbaren Anzeigen (Hauptfenster, Split-Liste, Einblendungen, Level-Up-Fenster,
-- Zeit-Anzeigen, Quest-Item-Leiste, Stream-Goal-Tracker). Jede Anzeige meldet sich mit Frames.Register an;
-- gespeichert wird je Anzeige db.frames[id] = { point, relPoint, x, y, scale } (fehlende Position = Standard,
-- fehlende Größe = Standard bzw. fallbackScale). Der Edit-Modus (UI/EditMode.lua) arbeitet nur über diese Liste.
--   Frames.Register({
--     id, frame, label (Locale-Key für den Edit-Modus), default = { Punkt, Bezugspunkt, x, y },
--     defaultScale (Standard 1), fallbackScale() optional (z.B. Split-Liste: Größe des Hauptfensters),
--     keepTopLeft (Größenwechsel hält die linke obere Ecke fest statt des Ankers), dragWhenUnlocked (auch außerhalb
--     des Edit-Modus ziehbar, solange "locked" aus ist), store = { get(), set(entry) } (eigener Speicher, z.B. Stream
--     Goal), onScale(scale) (weitere Rahmen mitskalieren), available() (gibt es die Anzeige in diesem Client),
--     preview(on) (Beispielinhalt im Edit-Modus), hide() (Anzeige ausschalten), settingsPage (Locale-Key des Reiters),
--     protected (sichere Kinder: nicht im Kampf ändern)
--   })
-- Ein Profilwechsel bringt neue Tabellen mit: daran erkennt das Apply, dass eine Anzeige an ihre neue Stelle muss.
local _, ns = ...
local Widgets = ns.Widgets

local Frames = {
  MIN_SCALE = 0.5,
  MAX_SCALE = 2,
}
ns.Frames = Frames

local SCALE_EPSILON = 0.001
local registry = {}  -- id -> Anmeldung
local order = {}     -- Anmeldungen in Reihenfolge

function Frames.ClampScale(scale)
  return math.max(Frames.MIN_SCALE, math.min(Frames.MAX_SCALE, scale))
end

function Frames.Get(id)
  return registry[id]
end

-- Alle Anmeldungen, die es in diesem Client gibt, in Anmeldereihenfolge
function Frames.All()
  local list = {}
  for _, reg in ipairs(order) do
    if not reg.available or reg.available() then table.insert(list, reg) end
  end
  return list
end

---------------------------------------------------------------------------
-- Speicher
---------------------------------------------------------------------------
local function entryOf(reg)
  if reg.store then return reg.store.get() end
  local frames = ns.db and ns.db.frames
  return frames and frames[reg.id]
end

-- Eintrag anlegen, falls es noch keinen gibt; gilt sofort als angewendet (kein Sprung zum Standard)
local function ensureEntry(reg)
  local entry = entryOf(reg)
  if entry then return entry end
  entry = {}
  if reg.store then
    reg.store.set(entry)
  else
    ns.db.frames = ns.db.frames or {}
    ns.db.frames[reg.id] = entry
  end
  reg.applied = entry
  return entry
end

local function hasPosition(entry)
  return entry ~= nil and entry.point ~= nil
end

function Frames.GetScale(id)
  local reg = registry[id]
  local entry = entryOf(reg)
  local scale = entry and entry.scale or (reg.fallbackScale and reg.fallbackScale()) or reg.defaultScale or 1
  return Frames.ClampScale(scale)
end

-- Gespeicherte Position { point, relPoint, x, y } oder die Standardposition
function Frames.GetPosition(id)
  local reg = registry[id]
  local entry = entryOf(reg)
  if hasPosition(entry) then return entry.point, entry.relPoint, entry.x, entry.y end
  return unpack(reg.default)
end

local function blocked(reg)
  if reg.protected and InCombatLockdown() then
    reg.pending = true  -- nach dem Kampf nachholen
    return true
  end
  return false
end

---------------------------------------------------------------------------
-- Anwenden
---------------------------------------------------------------------------
local function placeAt(reg)
  local point, relPoint, x, y = Frames.GetPosition(reg.id)
  reg.frame:ClearAllPoints()
  reg.frame:SetPoint(point, UIParent, relPoint, x, y)
end

-- Gespeicherte Abstände gelten in der Skalierung des Rahmens, daher zuerst skalieren, dann setzen
function Frames.Restore(id)
  local reg = registry[id]
  if blocked(reg) then return end
  reg.applied, reg.positioned = entryOf(reg), true
  local scale = Frames.GetScale(id)
  reg.frame:SetScale(scale)
  placeAt(reg)
  if reg.onScale then reg.onScale(scale) end
end

local function savePosition(reg)
  local point, _, relPoint, x, y = reg.frame:GetPoint()
  local entry = ensureEntry(reg)
  entry.point, entry.relPoint, entry.x, entry.y = point, relPoint, x, y
end

-- Neue Größe bei stehender Position: Ankerabstände umrechnen, damit die Anzeige stehen bleibt (bzw. ihre linke
-- obere Ecke bei keepTopLeft)
local function rescale(reg, scale)
  local frame = reg.frame
  local old = frame:GetScale()
  if math.abs(old - scale) <= SCALE_EPSILON then return end
  if reg.keepTopLeft then
    Widgets.SetScaleKeepingTopLeft(frame, scale)
    savePosition(reg)
  else
    local entry = entryOf(reg)
    frame:SetScale(scale)
    if hasPosition(entry) then
      entry.x, entry.y = entry.x * old / scale, entry.y * old / scale
      placeAt(reg)
    end
  end
  if reg.onScale then reg.onScale(scale) end
end

-- Nach einer Einstellungsänderung: anderes Profil (neue Tabelle) = neu setzen, sonst nur die Größe nachführen
local function sync(reg)
  if blocked(reg) then return end
  if not reg.positioned or entryOf(reg) ~= reg.applied then
    Frames.Restore(reg.id)
  else
    rescale(reg, Frames.GetScale(reg.id))
  end
end

-- Größe setzen (Regler, Mausrad im Edit-Modus, Ziehgriff); die Anzeige folgt sofort, das Apply der übrigen
-- Module (Regler-Anzeige) läuft verzögert
function Frames.SetScale(id, scale)
  local reg = registry[id]
  if blocked(reg) then return end
  ensureEntry(reg).scale = Frames.ClampScale(scale)
  rescale(reg, Frames.GetScale(id))
  for _, other in ipairs(order) do
    if other ~= reg and other.fallbackScale then sync(other) end  -- z.B. Split-Liste ohne eigene Größe
  end
  ns.RequestApply()
end

-- Position übernehmen, wie sie der Rahmen gerade hat (nach dem Ziehen)
function Frames.SavePosition(id)
  savePosition(registry[id])
end

-- Position setzen (Edit-Modus: Einrasten, Pfeiltasten)
function Frames.SetPosition(id, point, relPoint, x, y)
  local reg = registry[id]
  if blocked(reg) then return end
  local entry = ensureEntry(reg)
  entry.point, entry.relPoint, entry.x, entry.y = point, relPoint, x, y
  placeAt(reg)
end

-- Position und Größe auf Standard
function Frames.Reset(id)
  local reg = registry[id]
  if blocked(reg) then return end
  if reg.store then
    reg.store.set(nil)
  elseif ns.db.frames then
    ns.db.frames[id] = nil
  end
  Frames.Restore(id)
end

-- /lt reset: alle Anzeigen
function Frames.ResetAll()
  for _, reg in ipairs(order) do Frames.Reset(reg.id) end
  ns.ApplySettings()
end

-- Ziehen außerhalb des Edit-Modus nur bei Anzeigen mit dragWhenUnlocked und ohne "locked"
function Frames.CanDrag(reg)
  if ns.EditMode and ns.EditMode.IsActive() then return true end
  return reg.dragWhenUnlocked == true and not (ns.db and ns.db.locked)
end

---------------------------------------------------------------------------
-- Anmeldung
---------------------------------------------------------------------------
function Frames.Register(config)
  assert(not registry[config.id], "frame id registered twice: " .. config.id)
  local reg = config
  registry[reg.id] = reg
  table.insert(order, reg)
  local frame = reg.frame
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  if reg.dragWhenUnlocked then
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
      if Frames.CanDrag(reg) then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
      self:StopMovingOrSizing()
      savePosition(reg)
    end)
  end
  return reg
end

ns.OnLogin(function()
  for _, reg in ipairs(order) do
    reg.positioned = false  -- auch nach ns.DeleteCharacter neu setzen
    Frames.Restore(reg.id)
  end
end)

ns.RegisterApply(function()
  for _, reg in ipairs(order) do sync(reg) end
end)

ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
  for _, reg in ipairs(order) do
    if reg.pending then
      reg.pending = false
      sync(reg)
    end
  end
end)

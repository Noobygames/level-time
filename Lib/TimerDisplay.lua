-- Gemeinsamer Baustein für Zeit-Anzeigen als Karte (Lib/Card.lua): Lagerfeuer (UI/CampDisplay.lua),
-- Essen (UI/FoodDisplay.lua). Eine Anzeige kennt Zustände (kind), jeder mit Farbe und Titel:
--   countdown  Restzeit als Zahl und leerlaufender Balken
--   hint       Hinweis ohne Zeit, pulsiert leicht (config.pulseKind)
--   done       steht kurz mit "fertig" und verschwindet (endsAt)
-- config: { name, default (Position), scaleKey, posKey, soundKey, minScale, maxScale, colors[kind],
--   titleFor(kind), previewKinds, demoSpell(kind), movingSpell() (Zauber für den Verschiebemodus), pulseKind,
--   formatTime(remaining) optional (Standard "42 s") }. Ein Zustand darf eigenen Titel (title) mitbringen.
-- spellId darf auch ein Texturpfad sein (Card nimmt beides).
-- Einstellungen: db[scaleKey], db[posKey] (verschiebbar, Vorschau), db[soundKey] (bei "done").
local _, ns = ...
local Widgets = ns.Widgets

local TimerDisplay = {}
ns.TimerDisplay = TimerDisplay

local FADE_IN_SECONDS = 0.2
local UPDATE_INTERVAL = 0.05
local DONE_SECONDS = 4          -- "fertig" bleibt so lange stehen
local PREVIEW_SECONDS = 8
local DEMO_DURATION = 60
local DEMO_REMAINING = 42
local PULSE_SPEED = 3

function TimerDisplay.Create(config)
  local Display = {}
  local card = ns.Card.Create(config.name)
  local frame = card.frame
  frame:SetFrameStrata("HIGH")

  local current   -- angezeigter Zustand: { kind, spellId, expiration, duration, frozen, endsAt }
  local override  -- Vorschau oder Verschiebemodus; solange gesetzt, ignoriert die Anzeige die echten Zustände
  local shownAt

  local function remainingOf(state)
    if state.frozen then return state.frozen end
    return math.max(0, state.expiration - GetTime())
  end

  -- Zahl, Balken und Pulsieren; läuft im OnUpdate, solange die Anzeige steht
  local function refresh()
    if not current then return end
    local now = GetTime()
    if current.kind == "countdown" then
      local remaining = remainingOf(current)
      local seconds = math.ceil(remaining)
      card.SetTime(config.formatTime and config.formatTime(seconds) or string.format(ns.L.SECONDS_SHORT, seconds))
      card.SetFraction(current.duration > 0 and remaining / current.duration or 0)
    end
    local alpha = math.min(1, (now - shownAt) / FADE_IN_SECONDS)
    if current.kind == config.pulseKind then alpha = alpha * (0.8 + 0.2 * math.sin(now * PULSE_SPEED)) end
    frame:SetAlpha(alpha)
  end

  local function hide()
    current = nil
    frame:Hide()
  end

  local function setCard(state)
    card.Set({
      color = config.colors[state.kind],
      icon = state.spellId,
      title = state.title or config.titleFor(state.kind),
      time = state.kind == "countdown",
    })
  end

  local function display(state)
    current = state
    setCard(state)
    shownAt = GetTime()
    frame:SetAlpha(0)
    frame:Show()
    refresh()
  end

  local sinceUpdate = 0
  ns.SetUpdateScript(frame, config.name or "TimerDisplay", function(_, elapsed)
    sinceUpdate = sinceUpdate + elapsed
    if sinceUpdate < UPDATE_INTERVAL then return end
    sinceUpdate = 0
    if not current then return end
    if current.endsAt and GetTime() >= current.endsAt then
      if override == current then override = nil end
      hide()
      return
    end
    refresh()
  end)

  -- Zustand aus der Prüfung: nil blendet aus, ein laufender "done" bleibt bis zum Ende stehen.
  -- state = { kind, spellId, remaining, duration }
  function Display.Show(state)
    if override then return end
    if not state then
      if not (current and current.kind == "done") then hide() end
      return
    end
    if current and current.kind == state.kind and current.title == state.title then
      if state.kind == "countdown" then  -- nur nachführen, ohne Neuaufbau
        current.expiration = GetTime() + state.remaining
        current.duration = state.duration
      end
      if state.kind ~= "done" then return end
    end
    display({
      kind = state.kind,
      spellId = state.spellId,
      title = state.title,
      expiration = state.remaining and GetTime() + state.remaining or nil,
      duration = state.duration,
    })
  end

  function Display.ShowDone(spellId, title)
    if override then return end
    display({ kind = "done", spellId = spellId, title = title, endsAt = GetTime() + DONE_SECONDS })
    if ns.db and ns.db[config.soundKey] then ns.Alerts.PlaySound() end
  end

  ---------------------------------------------------------------------------
  -- Position, Größe, Vorschau
  ---------------------------------------------------------------------------
  local mover = Widgets.CreateMover(frame, {
    default = config.default,
    get = function() return ns.db and ns.db[config.posKey] end,
    set = function(pos) ns.db[config.posKey] = pos end,
    onMovingChanged = function(moving)
      if not moving then
        override = nil
        hide()
      end
    end,
  })

  local function demoState(kind)
    return {
      kind = kind,
      spellId = config.demoSpell(kind),
      expiration = GetTime() + DEMO_REMAINING,
      duration = DEMO_DURATION,
      endsAt = GetTime() + PREVIEW_SECONDS,
    }
  end

  local previewIndex = 0

  -- Vorschau: jeder Aufruf zeigt den nächsten Zustand ein paar Sekunden
  function Display.Preview()
    if mover.IsMoving() then Display.SetMoving(false) end
    previewIndex = previewIndex % #config.previewKinds + 1
    override = demoState(config.previewKinds[previewIndex])
    display(override)
  end

  -- Verschiebemodus: der Countdown steht still (42 s), Ziehen verschiebt, Rechtsklick oder erneuter Aufruf beendet
  function Display.SetMoving(enabled)
    enabled = enabled and true or false
    if enabled == mover.IsMoving() then return end
    if enabled then
      override = { kind = "countdown", spellId = config.movingSpell(), frozen = DEMO_REMAINING, duration = DEMO_DURATION }
      display(override)
      frame:SetAlpha(1)
    end
    mover.SetMoving(enabled)
  end

  function Display.IsMoving()
    return mover.IsMoving()
  end

  function Display.ResetPosition()
    mover.Reset()
  end

  ns.OnLogin(mover.Restore)

  ns.RegisterApply(function(db)
    mover.SetScale(math.max(config.minScale, math.min(config.maxScale, db[config.scaleKey])))
    mover.Sync()
    if current then setCard(current) end  -- Sprache kann gewechselt haben
  end)

  return Display
end

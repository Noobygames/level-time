-- Gemeinsamer Baustein für Zeit-Anzeigen als Karte (Lib/Card.lua): Lagerfeuer (UI/CampDisplay.lua),
-- Essen (UI/FoodDisplay.lua). Eine Anzeige kennt Zustände (kind), jeder mit Farbe und Titel:
--   countdown  Restzeit als Zahl und leerlaufender Balken
--   hint       Hinweis ohne Zeit, pulsiert leicht (config.pulseKind)
--   done       steht kurz mit "fertig" und verschwindet (endsAt)
-- config: { name, id und label (Edit-Modus, Lib/Frames.lua), default (Position), soundKey, colors[kind],
--   titleFor(kind), previewKinds, demoSpell(kind), movingSpell() (Zauber im Edit-Modus), pulseKind,
--   toggleKey (Einstellung, die "Ausblenden" im Edit-Modus abschaltet), available() optional,
--   formatTime(remaining, state) optional (Standard "42 s") }. Ein Zustand darf eigenen Titel (title) mitbringen,
--   estimated (geschätzte Restzeit: Farbe config.colors.estimated, formatTime sieht den Zustand).
-- spellId darf auch ein Texturpfad sein (Card nimmt beides).
-- Einstellungen: db[soundKey] (bei "done"); Position und Größe in db.frames[id].
local _, ns = ...

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
  local shownSeconds  -- zuletzt angezeigte Sekunde: die Zahl ändert sich nur einmal pro Sekunde, der Balken öfter
  local override  -- Vorschau oder Edit-Modus; solange gesetzt, ignoriert die Anzeige die echten Zustände
  local shownAt
  local faded = false  -- Einblenden fertig (Alpha 1), solange der Zustand steht

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
      if seconds ~= shownSeconds then
        shownSeconds = seconds
        card.SetTime(config.formatTime and config.formatTime(seconds, current)
          or string.format(ns.L.SECONDS_SHORT, seconds))
      end
      card.SetFraction(current.duration > 0 and remaining / current.duration or 0)
    end
    local pulsing = current.kind == config.pulseKind
    if faded and not pulsing then return end  -- eingeblendet und ohne Pulsieren: Alpha steht schon auf 1
    local alpha = math.min(1, (now - shownAt) / FADE_IN_SECONDS)
    faded = alpha >= 1
    if pulsing then alpha = alpha * (0.8 + 0.2 * math.sin(now * PULSE_SPEED)) end
    frame:SetAlpha(alpha)
  end

  local function hide()
    if current then ns.Debug("timer", "%s hides %s", config.name, current.kind) end
    current = nil
    frame:Hide()
  end

  local function setCard(state)
    shownSeconds = nil  -- Card.Set misst mit einem Platzhalter-Text, die Zahl kommt danach neu
    card.Set({
      color = state.estimated and config.colors.estimated or config.colors[state.kind],
      icon = state.spellId,
      title = state.title or config.titleFor(state.kind),
      time = state.kind == "countdown",
    })
  end

  local function display(state)
    ns.Debug("timer", "%s shows %s (remaining %s, duration %s, preview %s)", config.name, state.kind,
      state.expiration and state.expiration - GetTime(), state.duration, override ~= nil)
    current = state
    setCard(state)
    shownAt = GetTime()
    faded = false
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
  -- state = { kind, spellId, remaining, duration, title, estimated }
  function Display.Show(state)
    if override then return end
    if not state then
      if not (current and current.kind == "done") then hide() end
      return
    end
    if current and current.kind == state.kind and current.title == state.title
      and current.estimated == state.estimated then
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
      estimated = state.estimated,
      expiration = state.remaining and GetTime() + state.remaining or nil,
      duration = state.duration,
    })
  end

  -- Art des gezeigten echten Zustands: nil = nichts, "override" = Vorschau oder Edit-Modus
  function Display.ShownKind()
    if override then return "override" end
    return current and current.kind or nil
  end

  function Display.ShowDone(spellId, title)
    if override then return end
    display({ kind = "done", spellId = spellId, title = title, endsAt = GetTime() + DONE_SECONDS })
    local sound = ns.db and ns.db[config.soundKey]
    ns.Debug("timer", "%s done, sound %s", config.name, sound and true or false)
    if sound then ns.Alerts.PlaySound() end
  end

  ---------------------------------------------------------------------------
  -- Vorschau und Edit-Modus; Position und Größe über Lib/Frames.lua
  ---------------------------------------------------------------------------
  local editing = false

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
    if editing then return end
    previewIndex = previewIndex % #config.previewKinds + 1
    override = demoState(config.previewKinds[previewIndex])
    display(override)
  end

  -- Edit-Modus: der Countdown steht still (42 s), bis der Modus endet
  local function setEditing(enabled)
    if enabled == editing then return end
    editing = enabled
    if enabled then
      override = { kind = "countdown", spellId = config.movingSpell(), frozen = DEMO_REMAINING, duration = DEMO_DURATION }
      display(override)
      frame:SetAlpha(1)
    else
      override = nil
      hide()
    end
  end

  ns.Frames.Register({
    id = config.id, frame = frame, label = config.label, default = config.default,
    settingsPage = "OPTIONS_TAB_TIMERS", available = config.available, preview = setEditing,
    hide = config.toggleKey and function() ns.Set(config.toggleKey, false) end or nil,
  })

  ns.RegisterApply(function()
    if current then setCard(current) end  -- Sprache kann gewechselt haben
  end)

  return Display
end

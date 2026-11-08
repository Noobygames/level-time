-- Glücksrad am Bildschirm (Roadmap 432): ein echtes Rad aus SLICES farbigen Stücken (eigene Texturen aus
-- tools/artwork -wheel: Media/WheelSlice, WheelRim, WheelHub, WheelPointer), fester Zeiger oben, Nabe in der Mitte.
-- Drehen: schneller Start, weich auslaufend über SPIN_SECONDS und mehrere volle Umdrehungen; es bleibt so stehen,
-- dass der Zeiger auf einem Stück des gezogenen Eintrags steht. Jedes Stück ist eine eigene Textur, gedreht per
-- Texture:SetRotation um ihre Mitte (gegen den Uhrzeigersinn, wie Assist/CorpseArrow.lua von Level Time); Texte
-- drehen sich nicht mit (FontStrings lassen sich nicht in jedem Client drehen): die Zeile unter dem Rad zeigt live
-- das Stück unter dem Zeiger. OnUpdate (über LT.SetUpdateScript, im Profiler messbar) läuft nur, solange der Rahmen
-- sichtbar ist, und tut nur während des Drehens etwas. Tick-Ton je passiertem Stück (settings.wheelTickSound).
-- Verschiebbar über den Edit-Modus von Level Time (Vorschau mit Beispiel-Stücken).
-- Winkel: Rad-Drehung r (Bogenmaß, gegen den Uhrzeigersinn); Stück i (1..SLICES) liegt bei r + (i-1) * STEP und
-- steht unter dem Zeiger, wenn dieser Winkel ein Vielfaches von 2 pi ist (WheelDisplay.SliceAt).
local _, ns = ...
local LT = ns.LT
local L = ns.L
local Theme = LT.Theme

local WheelDisplay = {}
ns.WheelDisplay = WheelDisplay

WheelDisplay.FRAME_ID = "streamGoalWheel"
WheelDisplay.SLICES = 12          -- muss zu wheelSlices in tools/artwork/draw_wheel.go passen
WheelDisplay.SPIN_SECONDS = 4
WheelDisplay.MIN_TURNS = 3        -- volle Umdrehungen mindestens (dazu ein zufälliger Rest)
local TWO_PI = 2 * math.pi
local STEP = TWO_PI / WheelDisplay.SLICES
local LANDING_SPREAD = 0.35       -- Anteil eines Stücks, um den die Landung zufällig von der Mitte abweicht
local WHEEL_SIZE = 220
local POINTER_SIZE = 28
local HUB_SIZE = 36
local PADDING = 8
local TITLE_HEIGHT = 18
local LABEL_HEIGHT = 32
local MEDIA = "Interface\\AddOns\\StreamGoal\\Media\\"
local DEFAULT_POSITION = { "CENTER", "CENTER", 0, 120 }
-- Farben der Stücke reihum (Theme-Tokens, ein Theme-Wechsel färbt mit um); Nachbarn unterscheiden sich immer
local SLICE_COLORS = { "accent", "info", "success", "bad", "best", "warning" }
local DIM_ALPHA = 0.45            -- andere Stücke nach dem Halt
local TICK_SOUND = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON

---------------------------------------------------------------------------
-- Winkel (reine Funktionen, auch für die Tests)
---------------------------------------------------------------------------
-- Stück unter dem Zeiger bei Drehung rotation (1..count)
function WheelDisplay.SliceAt(rotation, count)
  count = count or WheelDisplay.SLICES
  local step = TWO_PI / count
  local position = (-rotation / step) % count  -- Stück-Nummer - 1, dessen Mitte oben steht (mit Bruchteil)
  return math.floor(position + 0.5) % count + 1
end

-- Drehung am Ende: mindestens turns volle Umdrehungen weiter als start, Zeiger auf Stück index; offset = Abweichung
-- von der Mitte des Stücks in Stück-Anteilen (-0.5..0.5)
function WheelDisplay.TargetRotation(start, index, count, turns, offset)
  count = count or WheelDisplay.SLICES
  local step = TWO_PI / count
  local wanted = -(index - 1 + (offset or 0)) * step
  local minimum = start + turns * TWO_PI
  return wanted + math.ceil((minimum - wanted) / TWO_PI) * TWO_PI
end

-- Auslaufen: schnell los, weich zum Stillstand (kubisch), progress 0..1
function WheelDisplay.Ease(progress)
  local rest = 1 - math.max(0, math.min(1, progress))
  return 1 - rest * rest * rest
end

---------------------------------------------------------------------------
-- Rahmen
---------------------------------------------------------------------------
local frame = CreateFrame("Frame", "StreamGoalWheel", UIParent)
frame:SetSize(WHEEL_SIZE + 2 * PADDING, WHEEL_SIZE + 2 * PADDING + TITLE_HEIGHT + LABEL_HEIGHT)
frame:SetFrameStrata("HIGH")
frame:Hide()
Theme.RegisterCard(frame)
WheelDisplay.frame = frame

local title = frame:CreateFontString(nil, "OVERLAY", Theme.Font("title"))
title:SetPoint("TOP", 0, -PADDING)

local disc = CreateFrame("Frame", nil, frame)
disc:SetSize(WHEEL_SIZE, WHEEL_SIZE)
disc:SetPoint("TOP", 0, -PADDING - TITLE_HEIGHT)

local slices = {}
for index = 1, WheelDisplay.SLICES do
  local texture = disc:CreateTexture(nil, "ARTWORK")
  texture:SetAllPoints()
  texture:SetTexture(MEDIA .. "WheelSlice")
  slices[index] = texture
end

local rim = disc:CreateTexture(nil, "OVERLAY")
rim:SetAllPoints()
rim:SetTexture(MEDIA .. "WheelRim")
local hub = disc:CreateTexture(nil, "OVERLAY")
hub:SetSize(HUB_SIZE, HUB_SIZE)
hub:SetPoint("CENTER")
hub:SetTexture(MEDIA .. "WheelHub")
local pointer = disc:CreateTexture(nil, "OVERLAY")
pointer:SetSize(POINTER_SIZE, POINTER_SIZE)
pointer:SetPoint("CENTER", disc, "TOP", 0, 0)
pointer:SetTexture(MEDIA .. "WheelPointer")

local label = frame:CreateFontString(nil, "OVERLAY", Theme.Font("body"))
label:SetPoint("TOPLEFT", disc, "BOTTOMLEFT", 0, -4)
label:SetPoint("TOPRIGHT", disc, "BOTTOMRIGHT", 0, -4)
label:SetHeight(LABEL_HEIGHT)
label:SetJustifyH("CENTER")
label:SetJustifyV("MIDDLE")

local state = {
  titles = {},      -- [Stück] = Text
  rotation = 0,
  spin = nil,       -- { from, to, elapsed, onStop } während des Drehens
  under = nil,      -- Stück unter dem Zeiger (Tick-Ton bei Wechsel)
  landed = nil,     -- Stück, auf dem das Rad zuletzt stand (hervorgehoben)
  editing = false,
}

local function paintColors()
  local r, g, b = Theme.RGB("border")
  rim:SetVertexColor(r, g, b, 1)
  hub:SetVertexColor(Theme.RGB("surface"))
  pointer:SetVertexColor(Theme.RGB("text"))
  for index, texture in ipairs(slices) do
    local color = Theme.COLORS[SLICE_COLORS[(index - 1) % #SLICE_COLORS + 1]]
    local alpha = (state.landed and state.landed ~= index) and DIM_ALPHA or 1
    texture:SetVertexColor(color[1], color[2], color[3], alpha)
  end
end

local function applyRotation(rotation)
  state.rotation = rotation
  for index, texture in ipairs(slices) do
    texture:SetRotation(rotation + (index - 1) * STEP)
  end
  local under = WheelDisplay.SliceAt(rotation)
  if under ~= state.under then
    if state.spin and state.under and TICK_SOUND and PlaySound and ns.db.settings.wheelTickSound then
      PlaySound(TICK_SOUND)
    end
    state.under = under
    LT.Widgets.SetTextIfChanged(label, state.titles[under] or "")
  end
end

local function update(_, elapsed)
  local spin = state.spin
  if not spin then return end
  spin.elapsed = spin.elapsed + elapsed
  local progress = spin.elapsed / WheelDisplay.SPIN_SECONDS
  applyRotation(spin.from + (spin.to - spin.from) * WheelDisplay.Ease(progress))
  if progress < 1 then return end
  state.spin = nil
  state.landed = state.under
  label:SetTextColor(Theme.RGB("good"))
  paintColors()
  LT.SafeCall(spin.onStop)
end
LT.SetUpdateScript(frame, "StreamGoalWheel", update)

-- Stücke beschriften: titles = { [Stück] = Text } (genau SLICES Einträge)
local function setSlices(titles)
  for index = 1, WheelDisplay.SLICES do state.titles[index] = titles[index] end
  state.under, state.landed = nil, nil
  title:SetText(L.SG_WHEEL)
  label:SetTextColor(Theme.RGB("text"))
  paintColors()
  applyRotation(state.rotation % TWO_PI)
end

-- Drehen und auf Stück target landen; onStop() danach. Ohne Animation (settings.wheelAnimation aus) sofort.
function WheelDisplay.Spin(titles, target, onStop)
  setSlices(titles)
  frame:Show()
  local from = state.rotation
  local turns = WheelDisplay.MIN_TURNS + math.random()
  local offset = (math.random() - 0.5) * LANDING_SPREAD
  state.spin = { from = from, to = WheelDisplay.TargetRotation(from, target, WheelDisplay.SLICES, turns, offset),
    elapsed = 0, onStop = onStop }
  if not ns.db.settings.wheelAnimation then update(frame, WheelDisplay.SPIN_SECONDS) end
end

function WheelDisplay.IsSpinning()
  return state.spin ~= nil
end

function WheelDisplay.Hide()
  if state.spin or state.editing then return end
  frame:Hide()
end

-- Für Tests: Drehung, Stück unter dem Zeiger, Beschriftung eines Stücks
function WheelDisplay.Rotation()
  return state.rotation
end

function WheelDisplay.SliceUnderPointer()
  return WheelDisplay.SliceAt(state.rotation)
end

function WheelDisplay.SliceTitle(index)
  return state.titles[index]
end

-- Textur eines Stücks (Debug-Check: kann der Client sie drehen?)
function WheelDisplay.SliceTexture(index)
  return slices[index]
end

---------------------------------------------------------------------------
-- Edit-Modus: Beispiel-Rad
---------------------------------------------------------------------------
local function preview(on)
  state.editing = on
  if on then
    if not state.spin then
      local titles = {}
      for index = 1, WheelDisplay.SLICES do titles[index] = L.SG_BINGO_SAMPLE end
      setSlices(titles)
    end
    frame:Show()
  elseif not state.spin then
    frame:Hide()
  end
end

LT.Frames.Register({
  id = WheelDisplay.FRAME_ID, frame = frame, label = "SG_EDIT_WHEEL", default = DEFAULT_POSITION,
  settingsPage = ns.SETTINGS_PAGES.WHEEL,
  store = {
    get = function() return ns.db and ns.db.settings.wheelFrame end,
    set = function(entry) ns.db.settings.wheelFrame = entry end,
  },
  preview = preview,
})

ns.RegisterApply(function()
  title:SetText(L.SG_WHEEL)
  paintColors()
end)
LT.OnLogin(function() LT.Frames.Restore(WheelDisplay.FRAME_ID) end)

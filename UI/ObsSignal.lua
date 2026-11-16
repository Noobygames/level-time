-- OBS-Signalfeld (Roadmap 313): einfarbiges Feld für OBS-Plugins (z.B. Advanced Scene Switcher, Streamer.bot),
-- das bei Level-Up (grün), Tod (rot) und erreichtem Ziel (blau) aufblinkt.
local _, ns = ...

ns.Database.RegisterDefaults({
  settings = {
    obsSignal = false,
    obsSignalSize = 16,
  },
  ranges = {
    obsSignalSize = { 8, 64 },
  },
})

local ObsSignal = {
  DURATION = 1.5,
}
ns.ObsSignal = ObsSignal

local COLORS = {
  idle = { 0, 0, 0, 1 },
  levelup = { 0, 1, 0, 1 },
  death = { 1, 0, 0, 1 },
  goal = { 0, 0, 1, 1 },
}

local frame = CreateFrame("Frame", "LevelTimerObsSignal", UIParent)
frame:SetSize(16, 16)
frame:Hide()
ObsSignal.frame = frame

local texture = frame:CreateTexture(nil, "BACKGROUND")
-- Eigener Kind-Frame nur für den Countdown: OnUpdate läuft nur, solange ein Signal aktiv ist
local timer = CreateFrame("Frame", nil, frame)
timer:Hide()
texture:SetAllPoints()
texture:SetColorTexture(unpack(COLORS.idle))

local currentSignal = nil
local signalRemaining = 0
local previewActive = false

local function setSignalColor(color)
  texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

local function resetSignal()
  currentSignal = nil
  signalRemaining = 0
  timer:Hide()
  setSignalColor(COLORS.idle)
  if not ns.db or not ns.db.obsSignal then
    if not previewActive then frame:Hide() end
  end
end

ns.SetUpdateScript(timer, "ObsSignal", function(_, elapsed)
  signalRemaining = signalRemaining - elapsed
  if signalRemaining <= 0 then
    resetSignal()
  end
end)

function ObsSignal.Trigger(kind)
  if not (ns.db and ns.db.obsSignal) and not previewActive then return end
  local color = COLORS[kind]
  if not color then return end
  currentSignal = kind
  signalRemaining = ObsSignal.DURATION
  setSignalColor(color)
  frame:Show()
  timer:Show()
end

function ObsSignal.CurrentSignal()
  return currentSignal
end

local function setPreview(active)
  previewActive = active
  if active then
    local size = ns.db and ns.db.obsSignalSize or 16
    frame:SetSize(size, size)
    frame:Show()
    if not currentSignal then
      setSignalColor(COLORS.idle)
    end
  else
    if not (ns.db and ns.db.obsSignal) and not currentSignal then
      frame:Hide()
    end
  end
end

ns.Frames.Register({
  id = "obsSignal",
  frame = frame,
  label = "EDIT_FRAME_OBS_SIGNAL",
  settingsPage = "OPTIONS_TAB_STREAM",
  default = { "TOPLEFT", "TOPLEFT", 0, 0 },
  preview = setPreview,
})

ns.RegisterApply(function(db)
  local size = db.obsSignalSize or 16
  frame:SetSize(size, size)
  if not currentSignal then
    setSignalColor(COLORS.idle)
  end
  if db.obsSignal or previewActive or currentSignal then
    frame:Show()
  else
    frame:Hide()
  end
end)

ns.OnLevelStarted(function()
  ObsSignal.Trigger("levelup")
end)

ns.RegisterEvent("PLAYER_DEAD", function()
  ObsSignal.Trigger("death")
end)

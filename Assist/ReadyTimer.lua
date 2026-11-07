-- Bereit-Timer (Reiter Komfort, Fenster; readyTimer, Standard aus): Restzeit zum Antworten als eigene Textzeile
--   Bereitschaftscheck   READY_CHECK(initiator, readyCheckTimeLeft) bis READY_CHECK_FINISHED (PartyInfoDocumentation,
--                        alle Clients); unter ReadyCheckFrame, wenn er zu sehen ist.
--   Schlachtfeld         UPDATE_BATTLEFIELD_STATUS: Warteschlange mit GetBattlefieldStatus(i) == "confirm", Restzeit aus
--                        GetBattlefieldPortExpiration(i) (Sekunden, wie Blizzards Minimap-Tooltip in Classic);
--                        Schlangen 1..GetMaxBattlefieldID() bzw. MAX_BATTLEFIELD_QUEUES.
-- Dungeon-Einladungen (LFG_PROPOSAL_SHOW) haben keine Restzeit-API und sind deshalb nicht dabei. Eigener Rahmen
-- (LevelTimerReadyTimer), OnUpdate nur solange eine Restzeit läuft; Blizzards Dialoge bleiben unberührt.
local _, ns = ...
local L = ns.L

local ReadyTimer = {}
ns.ReadyTimer = ReadyTimer

local UPDATE_INTERVAL = 0.2
local DEFAULT_QUEUES = 3
local CONFIRM = "confirm"
local FALLBACK_OFFSET_Y = -160
local GAP = 4

local frame, text
local readyCheckEndsAt   -- GetTime(), nil = kein Check offen
local battlefieldEndsAt  -- GetTime(), nil = keine Einladung offen
local sinceUpdate = 0

local function maxQueues()
  return (GetMaxBattlefieldID and GetMaxBattlefieldID()) or MAX_BATTLEFIELD_QUEUES or DEFAULT_QUEUES
end

-- Restzeit der Schlachtfeld-Einladung in Sekunden, nil ohne Einladung
function ReadyTimer.BattlefieldSecondsLeft()
  if not (GetBattlefieldStatus and GetBattlefieldPortExpiration) then return nil end
  for index = 1, maxQueues() do
    if GetBattlefieldStatus(index) == CONFIRM then
      local seconds = GetBattlefieldPortExpiration(index)
      if type(seconds) == "number" and not ns.IsSecret(seconds) and seconds > 0 then return seconds end
    end
  end
  return nil
end

-- Text der Zeile, nil wenn nichts läuft
function ReadyTimer.Text(now)
  local parts = {}
  if readyCheckEndsAt and readyCheckEndsAt > now then
    table.insert(parts, string.format(L.READY_TIMER_CHECK, math.ceil(readyCheckEndsAt - now)))
  end
  if battlefieldEndsAt and battlefieldEndsAt > now then
    table.insert(parts, string.format(L.READY_TIMER_BATTLEFIELD, ns.Format.Duration(math.ceil(battlefieldEndsAt - now))))
  end
  if #parts == 0 then return nil end
  return table.concat(parts, "  ")
end

local function anchor()
  frame:ClearAllPoints()
  if ReadyCheckFrame and ReadyCheckFrame:IsShown() and readyCheckEndsAt then
    frame:SetPoint("TOP", ReadyCheckFrame, "BOTTOM", 0, -GAP)
  else
    frame:SetPoint("TOP", UIParent, "TOP", 0, FALLBACK_OFFSET_Y)
  end
end

local function refresh()
  local line = ReadyTimer.Text(GetTime())
  if not line then
    readyCheckEndsAt, battlefieldEndsAt = nil, nil
    frame:Hide()
    return
  end
  ns.Widgets.SetTextIfChanged(text, line)
end

local function create()
  frame = CreateFrame("Frame", "LevelTimerReadyTimer", UIParent)
  frame:SetSize(1, 1)
  frame:SetFrameStrata("DIALOG")
  frame:Hide()
  text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  text:SetPoint("TOP")
  ns.SetUpdateScript(frame, "ReadyTimer", function(_, elapsed)
    sinceUpdate = sinceUpdate + elapsed
    if sinceUpdate < UPDATE_INTERVAL then return end
    sinceUpdate = 0
    refresh()
  end)
end

local function start()
  if not frame then create() end
  anchor()
  sinceUpdate = 0
  frame:Show()
  refresh()
end

function ReadyTimer.Frame()
  return frame
end

function ReadyTimer.TextLine()
  return text and text:GetText()
end

local events = ns.NewEventGroup()
events.Add("READY_CHECK", nil, function(_, timeLeft)
  if type(timeLeft) ~= "number" or ns.IsSecret(timeLeft) or timeLeft <= 0 then return end
  readyCheckEndsAt = GetTime() + timeLeft
  start()
end)
events.Add("READY_CHECK_FINISHED", nil, function()
  readyCheckEndsAt = nil
  if frame and frame:IsShown() then refresh() end
end)
events.Add("UPDATE_BATTLEFIELD_STATUS", nil, function()
  local seconds = ReadyTimer.BattlefieldSecondsLeft()
  battlefieldEndsAt = seconds and GetTime() + seconds or nil
  if seconds then start() elseif frame and frame:IsShown() then refresh() end
end)

ns.RegisterApply(function(db)
  events.SetActive(db.readyTimer == true)
  if not db.readyTimer then
    readyCheckEndsAt, battlefieldEndsAt = nil, nil
    if frame then frame:Hide() end
  end
end)

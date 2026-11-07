-- Spielzeit gesamt und auf dem aktuellen Level. Quelle ist der Server (/played),
-- zwischen zwei Abfragen wird lokal hochgezählt.
local _, ns = ...

local PlayedTime = {}
ns.PlayedTime = PlayedTime

local LOGIN_SYNC_DELAY = 3     -- Sekunden nach Login bis zur ersten Abfrage
local LEVEL_UP_SYNC_DELAY = 5  -- Sekunden nach Level-Up bis zum Abgleich
local REQUEST_TIMEOUT = 10     -- Sekunden, nach denen die Chatfenster auch ohne Antwort wieder hören

-- Stand beim letzten Abgleich (nil bis zur ersten Antwort des Servers)
local totalSeconds
local levelSeconds
local syncedAt  -- GetTime() beim letzten Abgleich

local function sinceSync()
  return GetTime() - syncedAt
end

-- Sekunden auf aktuellem Level oder nil, solange der Server noch nicht geantwortet hat
function PlayedTime.GetLevelSeconds()
  if not levelSeconds then return nil end
  return levelSeconds + sinceSync()
end

-- Gesamte Spielzeit des Charakters oder nil, solange der Server noch nicht geantwortet hat
function PlayedTime.GetTotalSeconds()
  if not totalSeconds then return nil end
  return totalSeconds + sinceSync()
end

---------------------------------------------------------------------------
-- Eigene Abfragen erscheinen nicht im Chat: Blizzards Chatfenster schreiben /played in ihrem
-- TIME_PLAYED_MSG-Handler (ChatFrameUtil.DisplayTimePlayed, in allen Clients). Statt diese Funktion
-- zu ersetzen (Taint), hören die Chatfenster das Event nur während der eigenen Abfrage nicht.
---------------------------------------------------------------------------
local mutedFrames  -- Chatfenster, denen TIME_PLAYED_MSG gerade abgemeldet ist

local function unmuteChat()
  if not mutedFrames then return end
  for _, frame in ipairs(mutedFrames) do
    frame:RegisterEvent("TIME_PLAYED_MSG")
  end
  mutedFrames = nil
end

local function muteChat()
  if mutedFrames then return end
  mutedFrames = {}
  for _, frame in ipairs(ns.ChatFrames()) do
    if frame:IsEventRegistered("TIME_PLAYED_MSG") then
      frame:UnregisterEvent("TIME_PLAYED_MSG")
      table.insert(mutedFrames, frame)
    end
  end
end

local answerListeners = {}  -- Rückrufe einzelner Abfragen (z.B. /lt sync), einmalig bei der nächsten Antwort

-- /played beim Server abfragen, ohne dass die Antwort im Chat erscheint; onAnswer(total, thisLevel) optional
function PlayedTime.Sync(onAnswer)
  if type(onAnswer) == "function" then table.insert(answerListeners, onAnswer) end
  muteChat()
  RequestTimePlayed()
  C_Timer.After(REQUEST_TIMEOUT, unmuteChat)
end

ns.RegisterEvent("TIME_PLAYED_MSG", function(total, thisLevel)
  ns.Debug("played", "server total %s s, level %s s", total, thisLevel)
  totalSeconds = total
  levelSeconds = thisLevel
  syncedAt = GetTime()
  -- Erst nach dieser Event-Runde wieder anmelden, damit die Chatfenster die Antwort nicht doch bekommen
  C_Timer.After(0, unmuteChat)
  local listeners = answerListeners
  answerListeners = {}
  for _, listener in ipairs(listeners) do ns.SafeCall(listener, total, thisLevel) end
end)

-- Neues Level beginnt bei 0; die Gesamtzeit läuft weiter
ns.OnLevelStarted(function()
  if totalSeconds then
    totalSeconds = totalSeconds + sinceSync()
  end
  levelSeconds = 0
  syncedAt = GetTime()
  C_Timer.After(LEVEL_UP_SYNC_DELAY, PlayedTime.Sync)
end)

ns.OnLogin(function()
  C_Timer.After(LOGIN_SYNC_DELAY, PlayedTime.Sync)
end)

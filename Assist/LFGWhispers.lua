-- Flüster-Verlauf der Gruppensuche (LT-389; nur WoW Forever): Flüstern, die über das eigene Fenster an Leiter gingen
-- (LFGSearch.Whisper), und die Antworten dieser Spieler. Nur diese Spieler werden mitgeschrieben, nie fremde Flüster.
-- Nur pro Sitzung, neueste zuerst, höchstens MAX_ENTRIES (kein SavedVariable). CHAT_MSG_WHISPER(_INFORM): text und
-- playerName können im Chat-Lockdown geheim sein, dann wird die Zeile ausgelassen.
local _, ns = ...
if not ns.Client.IsForever() then return end

local LFGWhispers = {}
ns.LFGWhispers = LFGWhispers

LFGWhispers.MAX_ENTRIES = 15

local entries = {}    -- { name, text, outgoing, time }, neueste zuerst
local contacted = {}  -- normalisierter Name -> true (über die Gruppensuche angeflüstert)
local listeners = {}
local seen = 0        -- Zähler für die Prüfung: wie viele Flüster-Ereignisse kamen an, wie viele mit lesbarem Namen
local readable = 0

local function normalize(name) return (name:match("^[^-]+") or name):lower() end

-- Vom Flüstern-Knopf gerufen: ab jetzt zählt dieser Spieler zum Verlauf
function LFGWhispers.Contact(name)
  if type(name) == "string" and not ns.IsSecret(name) then contacted[normalize(name)] = true end
end

local function record(name, text, outgoing)
  seen = seen + 1
  if ns.IsSecret(name) or ns.IsSecret(text) or type(name) ~= "string" or type(text) ~= "string" then return end
  readable = readable + 1
  if not contacted[normalize(name)] then return end
  table.insert(entries, 1, { name = name, text = text, outgoing = outgoing, time = time() })
  while #entries > LFGWhispers.MAX_ENTRIES do table.remove(entries) end
  ns.Debug("lfg", "whisper log: %s %s", outgoing and "to" or "from", name)
  for _, fn in ipairs(listeners) do fn() end
end

ns.RegisterEvent("CHAT_MSG_WHISPER", function(text, name) record(name, text, false) end)
ns.RegisterEvent("CHAT_MSG_WHISPER_INFORM", function(text, name) record(name, text, true) end)

function LFGWhispers.OnChange(fn) table.insert(listeners, fn) end

function LFGWhispers.GetEntries() return entries end

-- Für die Prüfung (LT389.lfg.whisperLog)
function LFGWhispers.Stats()
  local count = 0
  for _ in pairs(contacted) do count = count + 1 end
  return { seen = seen, readable = readable, contacted = count }
end

-- Session-Vergleich beim Login (Roadmap 281): wurde beim Login die vorige Session archiviert (Session.lua), eine
-- Chatzeile "Letzte Session: 2h 10m, 48.0k XP (+12 % XP/h zur vorherigen)". Einstellung sessionCompareLogin.
-- XP/h nach denselben Regeln wie die Historie (Experience.RecordRate, ohne AFK/Leerlauf, wenn eingestellt).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    sessionCompareLogin = true,
  },
})
local L = ns.L
local Format = ns.Format

local SessionCompare = {}
ns.SessionCompare = SessionCompare

-- Änderung in Prozent mit Vorzeichen, z.B. "+12%" oder "-5%"
local function signedPercent(change)
  local rounded = math.floor(change * 100 + 0.5)
  return (rounded > 0 and "+" or "") .. rounded .. "%"
end

-- Text zur Session last (Historien-Eintrag), verglichen mit previous (darf nil sein)
function SessionCompare.Text(last, previous)
  local text = string.format(L.SESSION_COMPARE, Format.Duration(last.seconds or 0), Format.Number(last.xp or 0))
  local rate = ns.Experience.RecordRate(last)
  local previousRate = previous and ns.Experience.RecordRate(previous)
  if rate and previousRate and previousRate > 0 then
    text = text .. " " .. string.format(L.SESSION_COMPARE_RATE, signedPercent(rate / previousRate - 1))
  end
  return text
end

-- Vorschau (Testen-Knopf): die letzte archivierte Session verglichen mit der davor, sonst ein Beispiel
function SessionCompare.Preview()
  local history = ns.character.sessionHistory or {}
  local last = history[#history] or { seconds = 7800, xp = 48000 }
  ns.Print(SessionCompare.Text(last, history[#history - 1]))
end

-- Läuft nach Session.lua (lädt früher), das beim Login archiviert
ns.OnLogin(function()
  if not ns.db.sessionCompareLogin or not ns.Session.ArchivedAtLogin() then return end
  local history = ns.character.sessionHistory
  ns.Print(SessionCompare.Text(history[#history], history[#history - 1]))
end)

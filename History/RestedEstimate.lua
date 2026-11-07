-- Ruhe-XP der Twinks schätzen (Roadmap 271). Beim Logout merkt sich jeder Charakter Erholungs-Pool, XP-Bedarf,
-- ob er im Gasthaus/in der Stadt steht, und die Uhrzeit (character.restSnapshot). Offline kommen laut warcraft.wiki.gg
-- (Rest) 5 % des Balkens je 8 h beim Ausruhen dazu, draußen ein Viertel davon, höchstens 150 % (Pandaren mit
-- „Innerer Friede“ das Doppelte). Die Historie zeigt die Schätzung im Vergleich; beim Login meldet eine Chatzeile
-- Twinks, die inzwischen voll ausgeruht sind (Einstellung restedAltNotice), einmal je Logout des Twinks.
-- APIs in allen Clients: GetXPExhaustion, UnitXPMax, IsResting, UnitRace (3. Wert = Rassen-ID).
local _, ns = ...

local RestedEstimate = {}
ns.RestedEstimate = RestedEstimate

local SECONDS_PER_BUBBLE_STEP = 8 * 3600  -- in dieser Zeit ...
local RESTING_SHARE = 0.05                -- ... kommen beim Ausruhen 5 % des Balkens dazu
local OUTSIDE_FACTOR = 0.25               -- draußen ausgeloggt: ein Viertel davon
local FULL_SHARE = 1.5                    -- höchstens anderthalb Level
local PANDAREN_FULL_SHARE = 3             -- Pandaren speichern doppelt so viel
local PANDAREN_RACE_IDS = { [24] = true, [25] = true, [26] = true }

local function readable(value)
  if value == nil or ns.IsSecret(value) then return nil end
  return value
end

local function fullShare()
  local raceId = readable(select(3, UnitRace("player")))
  return PANDAREN_RACE_IDS[raceId] and PANDAREN_FULL_SHARE or FULL_SHARE
end

-- Stand des eingeloggten Charakters; nil, wenn er nicht levelt oder die Werte nicht lesbar sind
local function takeSnapshot()
  if not ns.Experience.IsLeveling() then return nil end
  local xpMax = readable(UnitXPMax("player"))
  local pool = readable(GetXPExhaustion())
  if type(xpMax) ~= "number" or xpMax <= 0 then return nil end
  local resting = readable(IsResting())
  return { time = time(), rested = type(pool) == "number" and pool or 0, xpMax = xpMax,
    resting = resting and true or false, full = fullShare() }
end

-- Schätzung aus dem Stand beim Logout: Anteil am Balken und ob er voll ist; nil ohne brauchbaren Stand
local function estimateFrom(snapshot)
  if type(snapshot) ~= "table" or not snapshot.xpMax or snapshot.xpMax <= 0 then return nil end
  local elapsed = math.max(0, time() - (snapshot.time or time()))
  local perSecond = RESTING_SHARE / SECONDS_PER_BUBBLE_STEP * (snapshot.resting and 1 or OUTSIDE_FACTOR)
  local full = snapshot.full or FULL_SHARE
  local share = math.min(full, (snapshot.rested or 0) / snapshot.xpMax + elapsed * perSecond)
  return share, share >= full
end

-- Geschätzter Erholungs-Pool als Anteil am Balken (1 = ein Level) und ob er voll ist; nil ohne Daten.
-- Für den eingeloggten Charakter der echte Wert.
function RestedEstimate.Get(characterKey)
  if characterKey == ns.characterKey then
    local snapshot = takeSnapshot()
    if not snapshot then return nil end
    local share = snapshot.rested / snapshot.xpMax
    return share, share >= snapshot.full
  end
  local character = ns.Database.GetCharacters()[characterKey]
  return estimateFrom(character and character.restSnapshot)
end

-- Text für die Historie: "85%" bzw. "150% (voll)"
function RestedEstimate.Text(characterKey)
  local share, isFull = RestedEstimate.Get(characterKey)
  if not share then return "-" end
  local percent = ns.Format.Percent(share, 1)
  return isFull and string.format(ns.L.RESTED_FULL_SHORT, percent) or percent
end

-- Beim Login: Twinks, die seit ihrem Logout voll geworden sind, einmal melden
local function announceFullAlts()
  if not ns.db.restedAltNotice then return end
  for key, character in pairs(ns.Database.GetCharacters()) do
    local snapshot = character.restSnapshot
    if key ~= ns.characterKey and type(snapshot) == "table" and not snapshot.announced then
      local _, isFull = RestedEstimate.Get(key)
      if isFull then
        snapshot.announced = true
        ns.Print(string.format(ns.L.RESTED_ALT_FULL, ns.History.DisplayName(key)))
        ns.Debug("rested", "%s estimated fully rested", key)
      end
    end
  end
end

ns.OnLogin(announceFullAlts)

-- Wie gut war die Schätzung für diesen Charakter? Schätzung aus dem Stand beim letzten Logout gegen den echten Wert
ns.OnLogin(function()
  local estimated = estimateFrom(ns.character.restSnapshot)
  if estimated then ns.Debug("rested", "login: estimated %s, actual %s", estimated, RestedEstimate.Get(ns.characterKey)) end
end)

ns.OnLogout(function()
  ns.character.restSnapshot = takeSnapshot()
end)

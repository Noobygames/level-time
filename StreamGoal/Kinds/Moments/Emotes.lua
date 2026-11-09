-- Momente aus Emotes: "Spieler grüßen" und "Vor einem NPC tanzen".
-- Quelle: C_ChatInfo.PerformEmote(token, targetName), so rufen alle vier Clients Emotes aus dem Chat-Eingabefeld
-- (/winken, ChatFrameEditBox.lua) und dem Emote-Menü (ChatFrameMenuButton.lua) auf (geprüft in Gethe/wow-ui-source,
-- Zweige live, classic_era, classic_anniversary, forever); DoEmote nur, wo PerformEmote fehlt (wie der Schlafsack-Timer
-- von Level Time). Ziel des Emotes: ohne Namen das aktuelle Ziel, mit Namen das Ziel oder ein Gruppenmitglied dieses
-- Namens (andere Namen sind nicht prüfbar und zählen nicht).
--   greet  Gruß-Emote (GREET_TOKENS) an einen anderen Spieler
--   dance  DANCE mit einem NPC als Ziel (kein Spieler, kein Begleiter). Ob man wirklich davor steht, prüft das Addon
--          nicht (Entfernungen zu NPCs sind in Retail eingeschränkt); das Ziel muss es aber sein.
-- Jeder Spieler bzw. NPC zählt einmal je Sitzung (GUID, sonst Name): zehnmal dieselbe Person grüßen ist ein Gruß.
local _, ns = ...
local LT = ns.LT
local Moments = ns.Moments

local Emotes = {}
ns.EmoteMoments = Emotes

-- Gruß-Emotes (Tokens aus ChatEmoteConstants.lua, in allen vier Clients gleich)
Emotes.GREET_TOKENS = { WAVE = true, HELLO = true, GREET = true, HAIL = true, WELCOME = true, BOW = true,
  SALUTE = true }
Emotes.DANCE_TOKEN = "DANCE"
local GROUP_UNITS = {}
for index = 1, 4 do table.insert(GROUP_UNITS, "party" .. index) end
for index = 1, 40 do table.insert(GROUP_UNITS, "raid" .. index) end

local greeted, dancedFor = {}, {}

local function readable(value)
  if LT.IsSecret(value) then return nil end
  return value
end

local function nameMatches(unit, name)
  local unitName = readable(UnitName(unit))
  return type(unitName) == "string" and unitName:lower() == name:lower()
end

-- Einheit, an die das Emote geht; nil = keine prüfbare
function Emotes.TargetUnit(targetName)
  if targetName == nil or targetName == "" then
    return readable(UnitExists("target")) == true and "target" or nil
  end
  if type(targetName) ~= "string" then return nil end
  local name = strtrim(targetName):match("^(%S+)") or ""
  if name == "" then return nil end
  if readable(UnitExists("target")) == true and nameMatches("target", name) then return "target" end
  for _, unit in ipairs(GROUP_UNITS) do
    if readable(UnitExists(unit)) == true and nameMatches(unit, name) then return unit end
  end
end

local function keyOf(unit)
  local guid = readable(UnitGUID(unit))
  return guid or readable(UnitName(unit))
end

-- Wahrheitswert einer Einheiten-Abfrage: true, false oder nil (geheim). Manche Clients liefern statt false nil
-- (Classic-Stil 1/nil), darum zählt alles außer true als nein.
local function flag(value)
  if LT.IsSecret(value) then return nil end
  return value == true or value == 1
end

local function isOtherPlayer(unit)
  return flag(UnitIsPlayer(unit)) == true and flag(UnitIsUnit(unit, "player")) == false
end

local function isNpc(unit)
  if flag(UnitIsPlayer(unit)) ~= false then return false end
  return not UnitPlayerControlled or flag(UnitPlayerControlled(unit)) == false
end

local function countOnce(mode, seen, unit)
  local key = keyOf(unit)
  if not key or seen[key] then return end
  seen[key] = true
  Moments.Count(mode, 1)
end

function Emotes.OnEmote(token, targetName)
  if not ns.db or type(token) ~= "string" or LT.IsSecret(token) or LT.IsSecret(targetName) then return end
  token = token:upper()
  local greet = Emotes.GREET_TOKENS[token] and Moments.IsActive("greet")
  local dance = token == Emotes.DANCE_TOKEN and Moments.IsActive("dance")
  if not greet and not dance then return end
  local unit = Emotes.TargetUnit(targetName)
  ns.Debug("moment", "emote %s at %s (unit %s)", token, targetName, unit)
  if not unit then return end
  if greet and isOtherPlayer(unit) then countOnce("greet", greeted, unit) end
  if dance then
    ns.Debug("moment", "dance target npc %s (player %s, controlled %s)", isNpc(unit), UnitIsPlayer(unit),
      UnitPlayerControlled and UnitPlayerControlled(unit))
    if isNpc(unit) then countOnce("dance", dancedFor, unit) end
  end
end

local function emotesAvailable()
  return (C_ChatInfo and C_ChatInfo.PerformEmote) ~= nil or DoEmote ~= nil
end

if emotesAvailable() then
  if C_ChatInfo and C_ChatInfo.PerformEmote then
    hooksecurefunc(C_ChatInfo, "PerformEmote", Emotes.OnEmote)
  else
    hooksecurefunc("DoEmote", Emotes.OnEmote)
  end
end

Moments.Register("greet", {
  label = "SG_MOMENT_GREET",
  title = "SG_GOAL_MOMENT_GREET",
  icon = "Interface\\Icons\\INV_Misc_Head_Human_01",
  available = emotesAvailable,
})

Moments.Register("dance", {
  label = "SG_MOMENT_DANCE",
  title = "SG_GOAL_MOMENT_DANCE",
  available = emotesAvailable,
})

LT.OnLogin(function() greeted, dancedFor = {}, {} end)

-- Einladungen mit Infos (Roadmap 265, Einstellung inviteInfo, Standard aus): bei einer Gruppeneinladung eine Chatzeile
-- mit Name (Klassenfarbe), Level, Rasse und Klasse des Einladenden, dazu "Freund/Gilde" (Friends.lua).
-- PARTY_INVITE_REQUEST(name, isTank, isHealer, isDamage, isNativeRealm, allowMultipleRoles, inviterGUID, ...): die GUID
-- ist das 7. Argument in Classic Era (PartyInfoDocumentation) und Forever (Debug-Log). GetPlayerInfoByGUID(guid)
-- liefert localizedClass, englishClass, localizedRace, englishRace, sex, name, realm (alle Clients, kann leer sein,
-- solange der Client den Spieler nicht kennt). Das Level steht nicht darin: nur wenn der Einladende gerade Ziel, Fokus
-- oder unter der Maus ist (UnitLevel). Blizzards Dialog PARTY_INVITE bleibt unberührt (kein Taint), deshalb Chat.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    inviteInfo = false,
  },
})
local L = ns.L

local InviteInfo = {}
ns.InviteInfo = InviteInfo

local LEVEL_UNITS = { "target", "focus", "mouseover" }

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

-- Level des Spielers mit dieser GUID, wenn er gerade als Einheit greifbar ist
local function levelOf(guid)
  for _, unit in ipairs(LEVEL_UNITS) do
    if readable(UnitGUID(unit)) == guid then
      local level = readable(UnitLevel(unit))
      if type(level) == "number" and level > 0 then return level end
    end
  end
end

-- Farbanteil 0..1 als Byte für |cffRRGGBB
local function byte(part) return math.floor(part * 255) end

local function classColored(name, classToken)
  local color = RAID_CLASS_COLORS and classToken and RAID_CLASS_COLORS[classToken]
  if not color then return name end
  return string.format("|cff%02x%02x%02x%s|r", byte(color.r), byte(color.g), byte(color.b), name)
end

-- Chatzeile zu einer Einladung; nil ohne lesbaren Namen
function InviteInfo.Describe(name, guid)
  name, guid = readable(name), readable(guid)
  if type(name) ~= "string" then return nil end
  local className, classToken, raceName
  if type(guid) == "string" and guid ~= "" and GetPlayerInfoByGUID then
    className, classToken, raceName = GetPlayerInfoByGUID(guid)
    className, classToken, raceName = readable(className), readable(classToken), readable(raceName)
  end
  local parts = {}
  local level = guid and levelOf(guid)
  if level then table.insert(parts, string.format(L.INVITE_INFO_LEVEL, level)) end
  if raceName and raceName ~= "" then table.insert(parts, raceName) end
  if className and className ~= "" then table.insert(parts, className) end
  local details = #parts > 0 and table.concat(parts, " ") or L.INVITE_INFO_UNKNOWN
  if ns.Friends.IsTrusted(name, guid) then details = details .. " " .. L.INVITE_INFO_TRUSTED end
  return string.format(L.INVITE_INFO, classColored(name, classToken), details)
end

ns.RegisterEvent("PARTY_INVITE_REQUEST", function(name, ...)
  if not ns.db.inviteInfo then return end
  local text = InviteInfo.Describe(name, (select(6, ...)))
  if text then ns.Print(text) end
end)

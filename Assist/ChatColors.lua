-- Eine Gruppenfarbe (Reiter Komfort, Chat; universalGroupColor, Standard aus): Schlachtzug- und Instanzchat in den
-- Farben des Gruppenchats (Leiter-Zeilen wie der Gruppenleiter). Gesetzt mit ChangeChatColor(chatType, r, g, b), wie
-- Blizzards Chat-Einstellungen (ChatConfigFrame, alle Clients); der Client meldet die Farbe per UPDATE_CHAT_COLOR,
-- Blizzards Chatfenster tragen sie dann in ChatTypeInfo ein. Die Farben des Spielers werden beim ersten Umfärben je
-- Charakter gemerkt (character.chatColorOriginals; der Client speichert Chatfarben je Charakter) und beim
-- Ausschalten zurückgesetzt. Ändert der Spieler die Gruppenfarbe, ziehen die anderen nach (UPDATE_CHAT_COLOR).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    universalGroupColor = false,
  },
})

local ChatColors = {}
ns.ChatColors = ChatColors

-- Chat-Art -> Chat-Art, deren Farbe sie bekommt
ChatColors.SAME_AS = {
  RAID = "PARTY",
  RAID_LEADER = "PARTY_LEADER",
  INSTANCE_CHAT = "PARTY",
  INSTANCE_CHAT_LEADER = "PARTY_LEADER",
}

-- Farbe einer Chat-Art; nil, solange der Client sie noch nicht gemeldet hat
local function colorOf(chatType)
  local info = ChatTypeInfo and ChatTypeInfo[chatType]
  if not info or type(info.r) ~= "number" then return nil end
  return info.r, info.g, info.b
end

-- Toleranz eine Farbstufe (1/255): der Client kann Farben gerundet zurückmelden, sonst würde jedes
-- UPDATE_CHAT_COLOR erneut umfärben
local COLOR_TOLERANCE = 1 / 255

local function sameColor(chatType, r, g, b)
  local currentR, currentG, currentB = colorOf(chatType)
  if not currentR then return false end
  return math.abs(currentR - r) <= COLOR_TOLERANCE and math.abs(currentG - g) <= COLOR_TOLERANCE
    and math.abs(currentB - b) <= COLOR_TOLERANCE
end

function ChatColors.IsAvailable()
  return ChangeChatColor ~= nil and ChatTypeInfo ~= nil
end

local function recolor(character)
  character.chatColorOriginals = character.chatColorOriginals or {}
  local originals = character.chatColorOriginals
  for chatType, source in pairs(ChatColors.SAME_AS) do
    local r, g, b = colorOf(source)
    local ownR, ownG, ownB = colorOf(chatType)
    if r and ownR then
      if not originals[chatType] then originals[chatType] = { ownR, ownG, ownB } end
      if not sameColor(chatType, r, g, b) then ChangeChatColor(chatType, r, g, b) end
    end
  end
end

local function restore(character)
  local originals = character.chatColorOriginals
  if not originals then return end
  for chatType, color in pairs(originals) do
    if not sameColor(chatType, color[1], color[2], color[3]) then
      ChangeChatColor(chatType, color[1], color[2], color[3])
    end
  end
  character.chatColorOriginals = nil
  ns.Debug("comfort", "group chat colors restored")
end

local function update()
  local character = ns.character
  if not ChatColors.IsAvailable() or not character or not ns.db then return end
  if ns.db.universalGroupColor == true then recolor(character) else restore(character) end
end

ns.RegisterApply(update)
ns.RegisterEvent("UPDATE_CHAT_COLOR", update)

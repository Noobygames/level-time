-- Nachrichten an Gruppe oder Gilde senden (Level-Up-Ansage, Mana-Ansage):
--   GroupChat.PartyChannel()  "INSTANCE_CHAT" für Gruppen aus Dungeonsuche/Schlachtfeld, sonst "PARTY", nil allein
--   GroupChat.GuildChannel()  "GUILD" oder nil ohne Gilde
--   GroupChat.Locked()        Blizzard sperrt Chat-Nachrichten von Addons (z.B. Bosskämpfe in Retail/WoW Forever,
--                             im Debug-Log in Forever-Dungeons gesehen); dann nichts senden statt "Aktion blockiert"
--   GroupChat.Send(text, chatType)  mit Präfix "Level Time: ", Farbcodes und Links entfernt
--   GroupChat.SendWithLinks(text, chatType)  ebenso, aber Links vom Client (z.B. GetQuestLink) bleiben; der Aufrufer
--                             gibt alle anderen Teile schon als reinen Text (Format.PlainText) hinein
--   GroupChat.Sanitize(text)  Links unverändert und unteilbar, sonst Farbcodes weg, freie | verdoppelt, auf MAX_TEXT an Teilgrenzen gekappt
--   GroupChat.Preview(text)   Vorschau aus den Einstellungen: nur lokal in den eigenen Chat mit Kennzeichnung, nie gesendet
--   GroupChat.MAX_TEXT        so viele Bytes darf text haben (Chat-Grenze 255 Bytes samt Präfix, Links zählen voll)
--   GroupChat.IsOwnSender(sender)  true, wenn eine Addon-Nachricht vom eigenen Charakter stammt
-- C_ChatInfo.SendChatMessage ersetzt seit 11.2 die globale Funktion; ältere Clients haben nur diese.
local _, ns = ...

local GroupChat = {}
ns.GroupChat = GroupChat

local PREFIX = ns.DISPLAY_NAME .. ": "
local MAX_MESSAGE_BYTES = 255
GroupChat.MAX_TEXT = MAX_MESSAGE_BYTES - #PREFIX

function GroupChat.PartyChannel()
  if not IsInGroup then return nil end
  if LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
  if IsInGroup() then return "PARTY" end
  return nil
end

function GroupChat.GuildChannel()
  return IsInGuild and IsInGuild() and "GUILD" or nil
end

function GroupChat.Locked()
  return C_ChatInfo ~= nil and C_ChatInfo.InChatMessagingLockdown ~= nil
    and C_ChatInfo.InChatMessagingLockdown() == true
end

function GroupChat.Send(text, chatType)
  local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
  ns.Debug("groupchat", "%s: %s", chatType, text)
  send(PREFIX .. ns.Format.PlainText(text), chatType)
end

-- Text ohne Link: Farbcodes weg, freie "|" verdoppelt
local function plainToken(text)
  text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[^:|]*:", ""):gsub("|r", "")
  return (text:gsub("|", "||"))
end

-- Kürzt Text auf höchstens max Bytes, ohne ein "||"-Paar oder ein UTF-8-Zeichen zu zerschneiden
local function cutPlain(text, max)
  local cut = text:sub(1, max)
  while #cut > 0 and cut:byte(-1) >= 0x80 and cut:byte(-1) < 0xC0 do cut = cut:sub(1, -2) end
  if #cut > 0 and cut:byte(-1) >= 0xC0 then cut = cut:sub(1, -2) end
  if #(cut:match("|*$")) % 2 == 1 then cut = cut:sub(1, -2) end
  return cut
end

-- Für den Chat zulässig machen: ein ganzer Link (|c…|H…|h[…]|h|r, auch |cnIQ3:) bleibt unverändert und unteilbar,
-- sonstige Farbcodes fallen weg, freie "|" werden verdoppelt; über MAX_TEXT hinaus wird an Teilgrenzen gekappt
function GroupChat.Sanitize(text)
  local tokens, pos = {}, 1
  while pos <= #text do
    local from, to = text:find("|H[^|]*|h[^|]*|h", pos)
    local plain = text:sub(pos, (from or #text + 1) - 1)
    local link
    if from then
      local color = plain:match("|c%x%x%x%x%x%x%x%x$") or plain:match("|cn[^:|]*:$")
      if color then plain = plain:sub(1, -#color - 1) end
      link = (color or "") .. text:sub(from, to)
      if color and text:sub(to + 1, to + 2) == "|r" then link, to = link .. "|r", to + 2 end
    end
    if plain ~= "" then tokens[#tokens + 1] = { text = plainToken(plain), plain = true } end
    if not from then break end
    tokens[#tokens + 1] = { text = link }
    pos = to + 1
  end
  local out, size = {}, 0
  for _, token in ipairs(tokens) do
    local room = GroupChat.MAX_TEXT - size
    if #token.text <= room then
      out[#out + 1] = token.text
      size = size + #token.text
    else
      if token.plain then out[#out + 1] = cutPlain(token.text, room) end
      break
    end
  end
  return table.concat(out)
end

function GroupChat.SendWithLinks(text, chatType)
  local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
  text = GroupChat.Sanitize(text)
  ns.Debug("groupchat", "%s: %s", chatType, text)
  local message = PREFIX .. text
  local ok, err = pcall(send, message, chatType)
  if not ok then ns.Debug("chat", "send failed: %s | %s", tostring(err), (message:gsub("|", "||"))) end
end

-- Vorschau (Testen-Knöpfe in den Einstellungen): dieselbe Zeile, die gesendet würde, aber nur im eigenen Chat
function GroupChat.Preview(text)
  ns.Print(ns.L.PREVIEW_TAG .. " " .. text)
end

-- Eigene Addon-Nachrichten kommen zurück: Absender "Name" oder "Name-Realm" mit normalisiertem Realm
-- (ohne Leerzeichen und Bindestriche, z.B. "AzjolNerub"). GetNormalizedRealmName fehlt evtl. in manchen Clients
-- und liefert früh beim Login nil; dann aus Database.RealmName nachbilden (Client oder gespeicherter Realm).
local function ownRealm()
  local realm = GetNormalizedRealmName and GetNormalizedRealmName()
  if type(realm) == "string" and realm ~= "" then return realm end
  return (ns.Database.RealmName():gsub("[%s%-]", ""))
end

function GroupChat.IsOwnSender(sender)
  if type(sender) ~= "string" then return false end
  local name, realm = sender:match("^([^-]+)-?(.*)$")
  if name ~= UnitName("player") then return false end
  return realm == "" or realm == ownRealm()
end

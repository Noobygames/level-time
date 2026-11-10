-- Nachrichten an Gruppe oder Gilde senden (Level-Up-Ansage, Mana-Ansage):
--   GroupChat.PartyChannel()  "INSTANCE_CHAT" für Gruppen aus Dungeonsuche/Schlachtfeld, sonst "PARTY", nil allein
--   GroupChat.GuildChannel()  "GUILD" oder nil ohne Gilde
--   GroupChat.Locked()        Blizzard sperrt Chat-Nachrichten von Addons (z.B. Bosskämpfe in Retail/WoW Forever,
--                             im Debug-Log in Forever-Dungeons gesehen); dann nichts senden statt "Aktion blockiert"
--   GroupChat.Send(text, chatType)  mit Präfix "Level Time: ", Farbcodes und Links entfernt
--   GroupChat.SendWithLinks(text, chatType)  ebenso, aber Links vom Client (z.B. GetQuestLink) bleiben; der Aufrufer
--                             gibt alle anderen Teile schon als reinen Text (Format.PlainText) hinein
--   GroupChat.Preview(text)   Vorschau aus den Einstellungen: nur lokal in den eigenen Chat mit Kennzeichnung, nie gesendet
--   GroupChat.MAX_TEXT        so viele Bytes darf text haben (Chat-Grenze 255 Bytes samt Präfix, Links zählen voll)
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

function GroupChat.SendWithLinks(text, chatType)
  local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
  ns.Debug("groupchat", "%s: %s", chatType, text)
  send(PREFIX .. text, chatType)
end

-- Vorschau (Testen-Knöpfe in den Einstellungen): dieselbe Zeile, die gesendet würde, aber nur im eigenen Chat
function GroupChat.Preview(text)
  ns.Print(ns.L.PREVIEW_TAG .. " " .. text)
end

-- Nachrichten an Gruppe oder Gilde senden (Level-Up-Ansage, Mana-Ansage):
--   GroupChat.PartyChannel()  "INSTANCE_CHAT" für Gruppen aus Dungeonsuche/Schlachtfeld, sonst "PARTY", nil allein
--   GroupChat.GuildChannel()  "GUILD" oder nil ohne Gilde
--   GroupChat.Locked()        Blizzard sperrt Chat-Nachrichten von Addons (z.B. Bosskämpfe in Retail/WoW Forever,
--                             im Debug-Log in Forever-Dungeons gesehen); dann nichts senden statt "Aktion blockiert"
--   GroupChat.Send(text, chatType)  mit Präfix "Level Time: ", Farbcodes und Links entfernt
--   GroupChat.SendWithLinks(text, chatType)  ebenso, aber Links vom Client (z.B. GetQuestLink) bleiben; der Aufrufer
--                             gibt alle anderen Teile schon als reinen Text (Format.PlainText) hinein
-- C_ChatInfo.SendChatMessage ersetzt seit 11.2 die globale Funktion; ältere Clients haben nur diese.
local _, ns = ...

local GroupChat = {}
ns.GroupChat = GroupChat

local PREFIX = ns.DISPLAY_NAME .. ": "

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

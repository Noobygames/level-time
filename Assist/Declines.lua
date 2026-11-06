-- Anfragen anderer Spieler automatisch ablehnen, jede Art einzeln schaltbar (Reiter "Komfort", aus):
-- Handel (declineTrades), Gruppeneinladungen (declineGroupInvites), Gildeneinladungen
-- (declineGuildInvites; Retail zeigt dafür GuildInviteFrame statt eines Dialogs), Duelle (declineDuels).
-- Abläufe wie in Blizzards UIParent/StaticPopup aller Clients: das Event zeigt den Dialog, die
-- Ablehnen-Taste ruft die Funktion; wir lehnen ab und schließen den Dialog. Eine Chatzeile nennt,
-- wer gefragt hat. Anders als die übrigen Komfort-Funktionen ohne Comfort.IsActive: Die Anfrage kommt
-- vom anderen Spieler, eine gedrückte Umschalttaste in dem Moment wäre Zufall.
-- Gruppeneinladungen von Freunden und Gilde lehnt declineGroupInvites nicht ab, solange acceptFriendInvites an ist
-- (Social.lua nimmt sie an): je Art optional keep(Event-Argumente) -> true = nicht ablehnen.
local _, ns = ...
local L = ns.L

local Declines = {}
ns.Declines = Declines

-- Je Art: Einstellung, Event (erstes Argument = Name), Ablehnen, Dialog, Chatzeile
Declines.KINDS = {
  { setting = "declineTrades", event = "TRADE_REQUEST", decline = function() CancelTrade() end,
    popup = "TRADE", message = "DECLINED_TRADE" },
  -- Einladungen mit Rollenwahl zeigen in Retail/Forever statt des Dialogs LFGInvitePopup
  { setting = "declineGroupInvites", event = "PARTY_INVITE_REQUEST", decline = function() DeclineGroup() end,
    popup = "PARTY_INVITE", message = "DECLINED_GROUP",
    -- PARTY_INVITE_REQUEST(name, isTank, isHealer, isDamage, isNativeRealm, allowMultipleRoles, inviterGUID, ...)
    keep = function(name, ...) return ns.Social.TrustsInviter(name, (select(6, ...))) end,
    hide = function()
      if LFGInvitePopup and StaticPopupSpecial_Hide then StaticPopupSpecial_Hide(LFGInvitePopup) end
    end },
  { setting = "declineGuildInvites", event = "GUILD_INVITE_REQUEST", decline = function() DeclineGuild() end,
    popup = "GUILD_INVITE", message = "DECLINED_GUILD",
    hide = function() if GuildInviteFrame then GuildInviteFrame:Hide() end end },
  { setting = "declineDuels", event = "DUEL_REQUESTED", decline = function() CancelDuel() end,
    popup = "DUEL_REQUESTED", message = "DECLINED_DUEL" },
  -- Duell bis zum Tod (Hardcore-Realms; Event fehlt in anderen Clients, dann bleibt es unregistriert)
  { setting = "declineDuels", event = "DUEL_TO_THE_DEATH_REQUESTED", decline = function() CancelDuel() end,
    popup = "DUEL_TO_THE_DEATH_REQUESTED", message = "DECLINED_DUEL" },
}

for _, kind in ipairs(Declines.KINDS) do
  ns.RegisterEvent(kind.event, function(name, ...)
    if not ns.db or not ns.db[kind.setting] then return end
    if kind.keep and kind.keep(name, ...) then return end
    ns.Debug("declines", "%s from %s", kind.event, name)
    kind.decline()
    StaticPopup_Hide(kind.popup)
    if kind.hide then kind.hide() end
    ns.Print(string.format(L[kind.message], name or L.UNKNOWN_NAME))
  end)
end

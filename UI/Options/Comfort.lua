-- Optionen, Reiter Komfort: Automatik, Sozial, Chat, Plündern, System.
local _, ns = ...
local O = ns.OptionsCore
local builder, addPage, addSection, addSlider, addToggles = O.builder, O.addPage, O.addSection, O.addSlider, O.addToggles
local finishPage, finishSubPages = O.finishPage, O.finishSubPages
local addHint, addSubPage, toggle, advanced, requires = O.addHint, O.addSubPage, O.toggle, O.advanced, O.requires

-- Komfort: Seitenleiste mit Kategorien wie bei Leatrix Plus
addPage("OPTIONS_TAB_COMFORT")
addHint("COMFORT_HINT")
addSubPage("COMFORT_PAGE_AUTOMATION")
addHint("AUTOMATION_QUESTS_HINT")  -- Quest-Automatik steht bei den Quests
addSection("SECTION_MERCHANT")
addToggles({
  toggle("AUTO_REPAIR", "autoRepair"),
  requires(toggle("AUTO_REPAIR_GUILD", "autoRepairGuild", ns.Client.HasGuildBank), "autoRepair"),
  toggle("AUTO_SELL_JUNK", "autoSellJunk"),
  toggle("DELETE_CHEAPEST_JUNK", "deleteCheapestJunk"),
  toggle("TRAIN_ALL_TOGGLE", "trainAllButton", ns.TrainerCache.IsAvailable),
})
addSection("SECTION_CHARACTER")
addToggles({
  toggle("AUTO_ACCEPT_SUMMON", "autoAcceptSummon"),
  toggle("AUTO_ACCEPT_RESURRECT", "autoAcceptResurrect"),
  advanced(toggle("AUTO_RELEASE_PVP", "autoReleasePvP")),
  toggle("MAIL_ASSIST_TOGGLE", "mailAssist"),
})
addSubPage("COMFORT_PAGE_SOCIAL")
addSection("SECTION_DECLINE")
addToggles({
  toggle("DECLINE_TRADES", "declineTrades"),
  toggle("DECLINE_GROUP_INVITES", "declineGroupInvites"),
  toggle("DECLINE_GUILD_INVITES", "declineGuildInvites"),
  toggle("DECLINE_DUELS", "declineDuels"),
  toggle("DECLINE_SHARED_QUESTS", "declineSharedQuests"),
  advanced(toggle("BLOCK_FRIEND_REQUESTS", "blockFriendRequests", ns.Social.CanBlockFriendRequests)),
})
-- Einladungen: Vertraute = Freunde, Gilde und wahlweise Communities (Friends.lua); declineGroupInvites lehnt sie dann nicht ab
addSection("SECTION_INVITES")
addToggles({
  toggle("ACCEPT_FRIEND_INVITES", "acceptFriendInvites"),
  toggle("INVITE_INFO_TOGGLE", "inviteInfo"),
  toggle("INVITE_FROM_WHISPER", "inviteFromWhisper"),
  advanced(toggle("FRIENDLY_COMMUNITIES", "friendlyCommunities", ns.Friends.CanUseCommunities)),
})
builder.AddTextInput({
  label = "INVITE_KEYWORD",
  advanced = true,
  setting = "inviteKeyword",
  get = function(db) return db.inviteKeyword end,
  set = function(text) ns.Set("inviteKeyword", strtrim(text)) end,
})
addSubPage("COMFORT_PAGE_CHAT")
addSection("SECTION_CHAT")
addToggles({
  toggle("CHAT_COPY_TOGGLE", "chatCopyButton"),
  toggle("RESTORE_CHAT", "restoreChat"),
  toggle("FILTER_DRUNK_SPAM", "filterDrunkSpam"),
  toggle("FILTER_SPELL_LINKS", "filterSpellLinks"),
  advanced(toggle("UNIVERSAL_GROUP_COLOR", "universalGroupColor", ns.ChatColors.IsAvailable)),
})
addSection("SECTION_CHAT_WINDOWS")
addToggles({
  toggle("HIDE_COMBAT_LOG_TAB", "hideCombatLogTab"),
  toggle("HIDE_CHAT_BUTTONS", "hideChatButtons"),
  advanced(toggle("CHAT_EDIT_BOX_TOP", "chatEditBoxTop")),
  advanced(toggle("CHAT_ARROW_KEYS", "chatArrowKeys")),
  toggle("NO_CHAT_FADE", "noChatFade"),
  advanced(toggle("UNCLAMP_CHAT", "unclampChat")),
  advanced(toggle("CHAT_FONT_OVERRIDE", "chatFontOverride", ns.ChatFontSize.IsAvailable)),
})
if ns.ChatFontSize.IsAvailable() then
  addSlider({
    label = "CHAT_FONT_SIZE",
    advanced = true,
    min = ns.ChatFontSize.MIN,
    max = ns.ChatFontSize.MAX,
    step = 1,
    get = function(db) return db.chatFontSize end,
    set = function(value) ns.SetDeferred("chatFontSize", value) end,
    format = function(value) return tostring(value) end,
    enabled = function(db) return db.chatFontOverride end,
  })
end
-- Plündern: schneller plündern und Bestätigungen überspringen (Würfeln um Beute: Dungeons)
addSubPage("COMFORT_PAGE_LOOT")
addSection("SECTION_LOOT")
addToggles({
  toggle("FASTER_LOOT", "fasterLoot"),
  toggle("SKIP_LOOT_CONFIRM", "skipLootConfirm"),
})
addSubPage("COMFORT_PAGE_SYSTEM")
addSection("SECTION_DIALOGS")
addToggles({
  toggle("EASY_DELETE", "easyDelete"),
  toggle("FASTER_MOVIE_SKIP", "fasterMovieSkip"),
})
addSection("SECTION_COMBAT_GROUP")
addToggles({
  toggle("COMBAT_PLATES", "combatPlates"),
  toggle("COMFORT_THREAT_NUMERIC", "threatShowNumeric"),
  advanced(toggle("NO_RAID_RESTRICTIONS", "noRaidRestrictions", ns.RaidRestrictions.IsAvailable)),
  toggle("READY_TIMER", "readyTimer"),
})
if ns.AddonListSort.IsAvailable() then
  addSection("SECTION_ADDON_LIST")
  addToggles({ advanced(toggle("SORT_ADDON_LIST", "sortAddonList")) })
end
finishSubPages()
finishPage()

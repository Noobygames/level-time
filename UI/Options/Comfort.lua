-- Optionen, Reiter Komfort (1/3): Automatik, Soziales, Chat, Oberfläche, Blizzard ausblenden.
local _, ns = ...
local O = ns.OptionsCore
local builder, addPage, addSection, addSlider, addToggles, addHint, addSubPage, toggle, advanced, requires = O.builder, O.addPage, O.addSection, O.addSlider, O.addToggles, O.addHint, O.addSubPage, O.toggle, O.advanced, O.requires

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
  toggle("TRAIN_ALL_TOGGLE", "trainAllButton", ns.TrainerCache.IsAvailable),
})
addSection("SECTION_CHARACTER")
addToggles({
  toggle("AUTO_ACCEPT_SUMMON", "autoAcceptSummon"),
  toggle("AUTO_ACCEPT_RESURRECT", "autoAcceptResurrect"),
  advanced(toggle("AUTO_RELEASE_PVP", "autoReleasePvP")),
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
addSubPage("COMFORT_PAGE_INTERFACE")
addSection("SECTION_SCREEN_TEXT")
addToggles({
  toggle("HIDE_ERRORS", "hideErrors"),
  toggle("HIDE_ZONE_TEXT", "hideZoneText"),
})
-- Schwarze Ränder über der Spielwelt (unter der Oberfläche)
addSection("SECTION_SCREEN_BORDERS")
addToggles({ toggle("SCREEN_BORDERS", "screenBorders") })
addSlider({
  label = "SCREEN_BORDER_TOP",
  advanced = true,
  min = 0,
  max = ns.ScreenBorders.MAX_SIZE,
  step = ns.ScreenBorders.STEP,
  get = function(db) return db.screenBorderTop end,
  set = function(value) ns.SetDeferred("screenBorderTop", value) end,
  format = function(value) return tostring(value) end,
  enabled = function(db) return db.screenBorders end,
})
addSlider({
  label = "SCREEN_BORDER_BOTTOM",
  advanced = true,
  min = 0,
  max = ns.ScreenBorders.MAX_SIZE,
  step = ns.ScreenBorders.STEP,
  get = function(db) return db.screenBorderBottom end,
  set = function(value) ns.SetDeferred("screenBorderBottom", value) end,
  format = function(value) return tostring(value) end,
  enabled = function(db) return db.screenBorders end,
})
addSlider({
  label = "SCREEN_BORDER_SIDES",
  advanced = true,
  min = 0,
  max = ns.ScreenBorders.MAX_SIZE,
  step = ns.ScreenBorders.STEP,
  get = function(db) return db.screenBorderSides end,
  set = function(value) ns.SetDeferred("screenBorderSides", value) end,
  format = function(value) return tostring(value) end,
  enabled = function(db) return db.screenBorders end,
})
addSection("SECTION_ACTION_BARS")
addToggles({
  toggle("HIDE_KEYBIND_TEXT", "hideKeybindText"),
  toggle("HIDE_MACRO_TEXT", "hideMacroText"),
  toggle("RANGE_COLOR", "rangeColor"),
  toggle("COMFORT_COOLDOWN_NUMBERS", "cooldownNumbers"),
})
-- Ausblenden (UX S15: alles an einem Ort): ein Schalter je Element der Liste in BlizzardHide.lua, auch die mit eigener
-- Einstellung (Erfahrungs-, Ruf- und Haltungsleiste, Kalender, Chat-Knöpfe; Kalender und Chat-Knöpfe stehen zusätzlich
-- bei Minimap und Chat); auch im Edit-Modus direkt am Element schaltbar. In Gruppen mit einklappbaren Überschriften
-- (Roadmap 406); unbekannte Einträge landen unter "Weitere"
local BLIZZARD_GROUPS = {
  { section = "SECTION_BLIZZ_UNIT_FRAMES", labels = { "BLIZZ_FRAME_PLAYER", "BLIZZ_FRAME_TARGET", "BLIZZ_FRAME_FOCUS",
    "BLIZZ_FRAME_PARTY", "BLIZZ_FRAME_PET", "BLIZZ_FRAME_BOSS", "BLIZZ_FRAME_ARENA", "BLIZZ_FRAME_CAST_BAR" } },
  { section = "SECTION_BLIZZ_MINIMAP_BUFFS", labels = { "BLIZZ_FRAME_MINIMAP", "BLIZZ_FRAME_ZONE_TEXT", "BLIZZ_FRAME_CLOCK",
    "BLIZZ_FRAME_CALENDAR", "BLIZZ_FRAME_BUFFS", "BLIZZ_FRAME_DEBUFFS", "BLIZZ_FRAME_TRACKER" } },
  { section = "SECTION_BLIZZ_BARS", labels = { "BLIZZ_FRAME_MAIN_BAR", "BLIZZ_FRAME_BAR", "BLIZZ_FRAME_BAR_ART",
    "BLIZZ_FRAME_STANCE", "BLIZZ_FRAME_PET_BAR", "BLIZZ_FRAME_MICRO_MENU", "BLIZZ_FRAME_BAGS", "BLIZZ_FRAME_XP_BAR",
    "BLIZZ_FRAME_REP_BAR" } },
}

-- Blizzard-Meldungen und -Effekte (HideFrames.lua): nur Schalter für Frames, die es im Client gibt (z.B. Boss-Banner
-- und Ereignis-Einblendungen nicht in Classic)
local function addBlizzardMessages()
  local HideFrames = ns.HideFrames
  addSection("SECTION_HIDE_FRAMES", { collapsible = true })
  addToggles({
    toggle("HIDE_BOSS_BANNER", "hideBossBanner", HideFrames.HasBossBanner),
    toggle("HIDE_EVENT_TOASTS", "hideEventToasts", HideFrames.HasEventToasts),
    toggle("HIDE_ALERTS", "hideAlerts", HideFrames.HasAlerts),
    advanced(toggle("HIDE_REST_ANIMATION", "hideRestAnimation", HideFrames.HasRestAnimation)),
    advanced(toggle("HIDE_PORTRAIT_NUMBERS", "hidePortraitNumbers", HideFrames.HasPortraitNumbers)),
  })
end
local function addBlizzardHideGroups()
  local groupOf = {}
  for index, group in ipairs(BLIZZARD_GROUPS) do
    for _, label in ipairs(group.labels) do groupOf[label] = index end
  end
  local lists, rest = {}, {}
  for _, entry in ipairs(ns.BlizzardHide.Toggles()) do
    if not entry.setting then entry.resetKeys = { "hiddenBlizzardFrames" } end
    local index = groupOf[entry.label]
    if index then
      lists[index] = lists[index] or {}
      table.insert(lists[index], entry)
    else
      table.insert(rest, entry)
    end
  end
  for index, group in ipairs(BLIZZARD_GROUPS) do
    if lists[index] then
      addSection(group.section, { collapsible = true })
      addToggles(lists[index])
    end
  end
  if #rest > 0 then
    addSection("SECTION_BLIZZ_OTHER", { collapsible = true })
    addToggles(rest)
  end
end

addSubPage("COMFORT_PAGE_HIDE")
addSection("SECTION_BLIZZARD_FRAMES")
addHint("BLIZZARD_FRAMES_HINT")
addBlizzardHideGroups()
addBlizzardMessages()

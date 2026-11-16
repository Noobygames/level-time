-- Strenge luacheck-Konfiguration (LT-250). Aufruf: make lint
-- Neue WoW-API-Funktionen oder FrameXML-Globals in read_globals eintragen (alphabetisch);
-- eigene Globals (SavedVariables, Slash-Befehle, Keybindings) nur in globals.
std = "lua51"
max_line_length = 140
-- Methoden (obj:Name()) behalten self, auch wenn sie es nicht nutzen (Schnittstelle wie bei Blizzard-Mixins).
self = false
exclude_files = { "tools/**", "dist/**", "docs/**", "curseforge/**", ".claude/**", ".cache/**" }

-- Eigene Globals: SavedVariables, Slash-Befehle, Keybinding-Texte, vom Client gerufene Funktionen,
-- und WoW-Tabellen, in die Addons eintragen (SlashCmdList, StaticPopupDialogs, UISpecialFrames).
globals = {
  "BINDING_HEADER_LEVELTIMER", "BINDING_NAME_LEVELTIMER_CUSTOM_SPLIT", "BINDING_NAME_LEVELTIMER_INFO_CARD",
  "GetMinimapShape", "LevelTimer_CustomSplit", "LevelTimer_InfoCard", "LevelTimer_OnAddonCompartmentClick",
  "LevelTimerAPI", "LevelTimerArchiveDB", "LevelTimerCharDB", "LevelTimerDB", "LevelTimerDebugLog",
  "LevelTimerExtractorDB", "LevelTimerStatsDB", "SLASH_LEVELTIMEREXTRACTOR1", "SLASH_STREAMGOAL1",
  "SLASH_STREAMGOAL2", "SlashCmdList", "StaticPopupDialogs", "StreamGoalDB",
  "UISpecialFrames", "UIPanelWindows",
}

-- WoW-Client-API, FrameXML und fremde Addons (nur lesen)
read_globals = {
  "C_EncounterJournal", "EJ_GetCurrentInstance", "EJ_GetEncounterInfoByIndex", "EJ_GetNumLoot", "EJ_SelectEncounter",
  "EJ_SelectInstance", "EncounterJournal",
  "AbandonQuest", "AcceptGroup", "AcceptQuest", "AcceptResurrect", "AcknowledgeAutoAcceptQuest",
  "ActionButton_UpdateRangeIndicator", "AddonList", "AddonList_Update", "AlertFrame", "Auctionator",
  "AutoLootMailItem", "BNDeclineFriendInvite", "BNET_CLIENT_WOW", "BNGetFriendInviteInfo", "BNGetNumFriendInvites",
  "BNInviteFriend", "BossBanner", "BuffFrame", "BuybackItem", "BuyTrainerService", "C_AddOns", "C_BattleNet",
  "C_ChatInfo", "C_Club", "C_CombatLog", "C_Container", "C_CurrencyInfo", "C_CVar", "C_DeathInfo", "C_DeathRecap",
  "C_FriendList", "C_GossipInfo", "C_GuildInfo", "C_Item", "C_LFGList", "C_LFGListRoles", "C_LootHistory", "C_LossOfControl", "C_Map",
  "C_ChatInfo", "C_Club", "C_CombatLog", "C_Container", "C_CurrencyInfo", "C_DamageMeter", "C_CVar", "C_DeathInfo", "C_DeathRecap",
  "C_FriendList", "C_GossipInfo", "C_GuildInfo", "C_Item", "C_LFGList", "C_LootHistory", "C_LossOfControl", "C_Map",
  "C_MapExplorationInfo", "C_MerchantFrame", "C_NamePlate", "C_PartyInfo", "C_PlayerInfo", "C_PvP", "C_QuestLog",
  "C_Reputation", "C_Secrets", "C_Spell", "C_SpellBook", "C_SummonInfo", "C_SwingTimer", "C_TaxiMap", "C_Texture", "C_Timer",
  "C_TooltipInfo",
  "C_UnitAuras", "CancelDuel", "CancelTrade", "CanGuildBankRepair", "CanLootUnit", "CanMerchantRepair",
  "ChangeChatColor", "CharacterMainHandSlot", "CharacterRangedSlot", "CharacterSecondaryHandSlot", "CHAT_FRAMES",
  "ChatEdit_InsertLink", "ChatFrame_AddMessageEventFilter", "ChatFrame_SendTell", "ChatFrame2", "ChatFrame2Tab", "ChatFrameUtil",
  "ChatTypeInfo", "CheckInteractDistance", "CinematicFrame", "CinematicFrameCloseDialogConfirmButton",
  "ClassTrainerFrame", "ClassTrainerTrainButton", "ClearOverrideBindings", "ClickSendMailItemButton",
  "COMBATLOG_HONORAWARD", "COMBATLOG_HONORGAIN", "COMBATLOG_HONORGAIN_NO_RANK", "COMBATLOG_XPGAIN_FIRSTPERSON",
  "CombatLogGetCurrentEventInfo", "CompleteQuest", "ConfirmAcceptQuest", "ConfirmLootRoll", "ConfirmLootSlot",
  "Constants", "ContainerFrameItemButton_OnModifiedClick", "CooldownFrame_Set", "CreateFont", "CreateFrame",
  "CreateVector2D", "date", "debugprofilestop", "debugstack", "DeclineGroup", "DeclineGuild", "DeclineQuest",
  "DEFAULT_CHAT_FRAME", "DELETE_ITEM_CONFIRM_STRING", "DeleteCursorItem", "CursorHasItem", "ClearCursor", "DoEmote", "DressUpFrame",
  "DressUpFrameResetButton", "DressUpModelFrame", "EditModeManagerFrame", "Enum", "ERR_INV_FULL", "ERR_OUT_OF_MANA",
  "ERR_ZONE_EXPLORED", "ERR_ZONE_EXPLORED_XP", "EventToastManagerFrame", "FauxScrollFrame_GetOffset",
  "FCF_OpenTemporaryWindow", "FCF_SelectDockFrame", "FCF_SetChatWindowFontSize", "FCFDock_GetSelectedWindow",
  "FCFDock_UpdateTabs", "FlashClientIcon", "FlightMap_FlightPointPinMixin",
  "FloatingChatFrame_UpdateBackgroundAnchors", "HideUIPanel", "GameFontNormalLarge", "GameRulesUtil", "GameTimeFrame",
  "GameTooltip", "GameTooltip_SetDefaultAnchor", "GameTooltipTextLeft1", "GENERAL_CHAT_DOCK",
  "GetAchievementCriteriaInfo", "GetAchievementInfo", "GetAchievementLink", "GetAchievementNumCriteria",
  "GetActionInfo", "GetActiveLevel", "GetActiveLootRollIDs", "GetActiveTitle", "GetAddOnMetadata",
  "GetAllowLowLevelRaid", "GetAvailableLevel", "GetAvailableQuestInfo", "GetAvailableTitle",
  "GetBattlefieldPortExpiration", "GetBattlefieldStatus", "GetBattlefieldWinner", "GetBuildInfo",
  "GetBuybackItemLink", "GetChatWindowInfo", "GetCoinTextureString", "GetCreatureDifficultyColor",
  "GetCurrentKeyBoardFocus", "GetCursorPosition", "GetCVar", "GetCVarBool", "GetDetailedItemLevelInfo",
  "geterrorhandler", "GetFactionInfo", "GetFileIDFromPath", "GetGuildBankWithdrawMoney", "GetGuildInfo",
  "GetInboxHeaderInfo", "GetInboxNumItems", "GetInstanceInfo", "GetInventoryItemCount", "GetInventoryItemDurability",
  "GetInventoryItemLink", "GetItemCount", "GetItemIcon", "GetItemInfo", "GetItemInfoInstant", "GetItemSpell",
  "GetLocale", "GetLootRollItemInfo", "GetLootRollItemLink", "GetLootRollTimeLeft", "GetLootSlotInfo",
  "GetLootSlotLink", "GetLootSlotType", "GetLootSourceInfo", "GetMaxBattlefieldID", "GetMaxPlayerLevel",
  "GetMerchantItemInfo", "GetMerchantItemLink", "GetMerchantNumItems", "GetMinimapZoneText", "GetMirrorTimerInfo",
  "GetMirrorTimerProgress", "GetMoney", "GetNormalizedRealmName", "GetNumActiveQuests", "GetNumAvailableQuests",
  "GetNumBuybackItems", "GetNumFactions", "GetNumGroupMembers", "GetNumLootItems", "GetNumQuestChoices",
  "GetNumQuestLeaderBoards", "GetNumQuestLogEntries", "GetNumQuestRewards", "GetNumQuestWatches", "GetNumRoutes",
  "GetNumSkillLines", "GetNumSpellTabs",
  "GetNumTrainerServices", "GetPlayerFacing", "GetPlayerInfoByGUID", "GetProfessionInfo",
  "GetProfessions", "GetPVPSessionStats", "GetQuestGreenRange", "GetQuestID", "ItemTextGetItem","GetQuestIDFromLogIndex",
  "GetQuestIndexForWatch", "GetQuestItemInfo", "GetQuestItemLink", "GetQuestLink", "GetQuestLogChoiceInfo",
  "GetQuestLogItemLink", "GetQuestLogLeaderBoard", "GetQuestLogRewardMoney", "GetQuestLogRewardXP",
  "GetQuestLogSpecialItemInfo", "GetQuestLogTitle", "GetQuestMoneyToGet", "GetQuestReward", "GetQuestUiMapID",
  "GetRealmName", "GetRealZoneText", "GetRepairAllCost", "GetRestState", "GetServerTime", "GetSkillLineInfo",
  "GetSpellBookItemName", "GetSpellInfo", "GetSpellLink", "GetSpellSubtext", "GetSpellTabInfo", "GetSpellTexture",
  "GetSubZoneText", "GetTaxiMapID", "GetTime",
  "GetTitleText", "GetTotalAchievementPoints", "GetTrainerServiceCost", "GetTrainerServiceIcon",
  "GetTrainerServiceInfo", "GetTrainerServiceLevelReq", "GetTrainerServiceSkillReq", "GetUnitName",
  "GetWeaponEnchantInfo", "GetXPExhaustion", "GetZoneText", "GuildInviteFrame", "HandleModifiedItemClick",
  "hooksecurefunc", "InboxFrame", "InCombatLockdown", "InterfaceOptions_AddCategory", "InviteUnit", "INVSLOT_AMMO",
  "INVSLOT_LAST_EQUIPPED", "INVSLOT_TABARD", "IsAddOnLoaded", "IsAltKeyDown", "IsControlKeyDown", "IsFalling",
  "IsIndoors", "IsInGroup", "IsInGuild", "IsInInstance", "IsInRaid", "IsModifiedClick",
  "IsPlayerAtEffectiveMaxLevel", "IsPlayerMoving", "IsPlayerSpell", "IsQuestCompletable", "IsQuestFlaggedCompleted",
  "IsResting", "issecretvalue", "IsShiftKeyDown", "IsSpellKnown", "IsSwimming", "IsTradeskillTrainer",
  "IsXPUserDisabled", "Item", "ITEM_QUALITY_COLORS", "ItemRefTooltip", "LE_PARTY_CATEGORY_INSTANCE",
  "LevelUpDisplay", "GetGeneralPlaystyleString", "LFGBrowseSearchEntry_Update", "LFGBrowseSearchEntryTooltip", "LFGBrowseSearchEntryTooltip_UpdateAndShow", "LFGInvitePopup",
  "LFGListUtil_SetSearchEntryTooltip", "LFGParentFrame", "LFGVanilla_ShowFrame", "LibStub", "LoadAddOn", "LOCALIZED_CLASS_NAMES_MALE", "Logout", "LootSlot",
  "LOSS_OF_CONTROL_DISPLAY_STUN", "MailFrame", "MAX_BATTLEFIELD_QUEUES", "MAX_BOSS_FRAMES", "MAX_NUM_QUESTS",
  "MAX_QUESTS", "Menu", "MerchantFrame", "Minimap", "Minimap_ZoomIn", "Minimap_ZoomOut", "MinimapBackdrop", "MinimapCluster",
  "MinimapZoomIn", "MinimapZoomOut", "MovieFrame", "MuteSoundFile", "NO", "NotifyInspect", "NUM_BAG_SLOTS",
  "NUM_CHAT_WINDOWS", "NUM_TOTAL_EQUIPPED_BAG_SLOTS", "NumberFontNormal", "NumTaxiNodes", "OPEN_LOCK_SELF",
  "OpenWorldMap", "PaperDollFrame", "PetHitIndicator", "PickupContainerItem", "PlayerFrame",
  "PlayerFrame_GetAlternatePowerBar", "PlayerFrameManaBar", "PlayerFrameTexture", "PlayerHitIndicator", "PlayerName",
  "PlayerRestGlow", "PlayerRestIcon", "PlaySound", "QuestFlagsPVP", "QuestFrameGreetingPanel", "QuestGetAutoAccept",
  "QuestInfo_Display", "QuestInfoFrame", "QuestLogListScrollFrame", "QuestLogQuests_Update",
  "QuestLogTitleButton_OnClick", "QuestLogTitleButton_OnEnter", "QuestMapLogTitleButton_OnEnter", "QUESTS_DISPLAYED",
  "QuestScrollFrame", "QuestWatchFrame", "RAID_CLASS_COLORS", "ReadyCheckFrame", "RepairAllItems", "RepopMe",
  "RequestTimePlayed", "ResetInstances", "Screenshot", "SelectActiveQuest", "SelectAvailableQuest",
  "SELECTED_CHAT_FRAME", "SelectQuestLogEntry", "SendChatMessage", "SendMailFrame", "SendMailNameEditBox",
  "SetAbandonQuest", "SetAllowLowLevelRaid", "SetCVar", "SetItemRef", "SetOverrideBindingClick", "Settings",
  "SetUnitCursorTexture", "SKILL_RANK_UP", "SOUNDKIT", "StanceBar", "StaticPopup_FindVisible", "StaticPopup_Hide",
  "StaticPopup_Show", "StaticPopupSpecial_Hide", "StatusTrackingBarInfo", "StatusTrackingBarManager", "strlenutf8",
  "strtrim", "SubZoneTextFrame", "TakeInboxItem", "TakeInboxMoney", "TakeTaxiNode", "TargetFrame", "TaxiGetNodeSlot",
  "TaxiNodeGetType", "TaxiNodeName", "TaxiNodeOnButtonEnter", "TaxiNodePosition", "time", "TooltipDataProcessor",
  "TooltipUtil", "TRANSFER_ABORT_TOO_MANY_INSTANCES", "UIErrorsFrame", "UiMapPoint", "UIParent",
  "UNIT_SKINNABLE_LEATHER", "UnitAffectingCombat", "UnitAttackSpeed", "UnitCanAssist", "UnitCanAttack",
  "UnitChannelInfo", "UnitClass", "UnitClassification", "UnitCreatureFamily", "UnitCreatureType",
  "UnitDetailedThreatSituation", "UnitExists", "UnitFactionGroup", "UnitGroupRolesAssigned", "UnitGUID",
  "UnitHealth", "UnitHealthMax", "UnitIsAFK", "UnitIsDead", "UnitIsDeadOrGhost", "UnitIsFeignDeath",
  "UnitIsGameObject", "UnitIsGhost", "UnitIsGroupAssistant", "UnitIsGroupLeader", "UnitIsInInteractRange",
  "UnitIsPlayer", "UnitIsUnit", "UnitLevel", "UnitName", "UnitOnTaxi", "UnitPlayerControlled", "UnitPower",
  "UnitPowerMax", "UnitPowerType", "UnitRace", "UnitRangedDamage", "UnitReaction", "UnitSelectionColor", "UnitStat",
  "UnitThreatSituation", "UnitTokenFromGUID", "UnitUsesAmmo", "UnitXP", "UnitXPMax", "UnmuteSoundFile",
  "WillAcceptInviteRemoveQueues", "WorldMapFrame", "WOW_PROJECT_ID", "YES", "ZoneTextFrame",
}

-- Datendateien: generiert oder lange Texte, Zeilenlänge egal
local DATA = { "Locales/**", "StreamGoal/Locales/**", "Assist/*Data/**", "UI/ChangelogData.lua" }
for _, pattern in ipairs(DATA) do
  files[pattern] = { max_line_length = false }
end

-- Tests: der Stub baut die WoW-API als Globals nach; Tippfehler findet dort der Testlauf selbst.
files["tests/**"] = { ignore = { "111", "112", "113", "121", "122" } }

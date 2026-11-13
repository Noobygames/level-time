# Notizen: Quests (Log, Tracking, Tasten, Sperrliste)

Wortgetreu aus CLAUDE.md ausgelagert. Vor dem Aendern eines Moduls hier nach dem Dateinamen suchen und nur den passenden Abschnitt lesen.

### Quest-Sperrliste (aus Data sources)

- `Assist/QuestBlocklist.lua`: NPC/quest blocklist for QuestAutomation (`IsBlockedNpc`, `IsBlockedQuest`, `Blocks`, `NpcId(guid)`), user list in setting `questExclude`; repeatable dialogs stay manual via `C_QuestLog.IsRepeatableQuest` (Retail/Forever). Further Assist modules: `BreathWarning` (MIRROR_TIMER_*, `warnBreath`/`breathWarnSeconds`), `BreakReminder` (`remindBreak`/`breakMinutes`, baseline in `currentSession.breakBaseline`), `QuestProgress` (`announceQuestProgress` via GroupChat, dropped during lockdown; last objective of a quest only as "Quest fertig", like QuestCompleteAlert, both via `QuestLog.AllFinished`), `InviteInfo` (`inviteInfo`, chat line only).

### Quest support (roadmap 340-352)

- `Tracking/QuestWatch.lua`: single quest log scan; features subscribe via `QuestWatch.Subscribe({ enabled, onObjective, onComplete, onReady, onAccepted })` instead of reading the log themselves (QuestProgress uses it).
- `QuestMobs` (`ForMob`, `IsQuestMob`, `ForItem`, `ItemsOf`, `QuestsOfItem`, `OpenMobNames`, `ProgressOf`; `MIN_HITS` = 2) in `LevelTimerStatsDB.questMobs`; `QuestNpcs` in `LevelTimerStatsDB.questNpcs`; per character `questLeftovers`, `questSpecialItems`.
- Helpers: `Lib/QuestLog.lua` (`Objectives`, `NormalizeObjective`, `QuestCount`, `MaxQuests`, `entry.header`), `Lib/QuestTooltip.lua` (cached per name), `Lib/QuestRewards.lua` (also QuestAutomation), `Lib/MapPins.lua` (`Create({ name, label, points, revision, onEnter })`, DeathMap uses it), `Alerts.Raise(kind, value, body)`, `Loot.OnSelfLoot`, `Items.GetName`. `QuestItem.TargetNames()` (plural). Raid marker only via secure macro `/tm`, never `SetRaidTarget`.
- Comfort sub page "Quests" holds quest display/marks/learning/log options; alerts `alertQuestComplete/Objective`, `alertRareSpotted/Flash`; History group "Quests" (Turn-in, Efficiency).
- Gotchas: gopher-lua `tonumber(s:match(...))` without match errors, write `tonumber((s:match(...)))`; new textures/fontstrings are shown by default (hide overlays right away); tests using `ns.NamePlates.Active()` must fire `NAME_PLATE_UNIT_ADDED`.
- Instance difficulty: a same-name difficulty change while inside is the same visit (`difficultySettled`); difficulty 0 counts as unsettled (`unsettledSibling` matches a visit of the same name with difficulty 0 on either side). Forever reports 0 right after entering.

### Party quest sync (roadmap 453)

- `Assist/PartyQuestSync.lua` (`partyQuestSync`, off by default): addon messages with prefix `ns.ADDON_ID .. "Q"` in party only (not in raids > 5): only accepted on PARTY/RAID/INSTANCE_CHAT; `Q` request (on roster update, 30 s cooldown; answered with a snapshot at most once per cooldown), `S:<id>:<idx>=<have>/<need>,...;...` snapshot (max 240 chars per message), `U:<id>:<idx>:<have>:<need>`, `C:<id>` ready, `R:<id>` removed/turned in. Producers via `QuestWatch.Subscribe`; peers per short name, cleared on leaving the group. Tooltip line "Party progress: Name (2/5), ..." on quest hyperlinks (`GameTooltip:SetHyperlink` post-hook). Queue flushed every second while the setting is on, respects `GroupChat.Locked`. Debug check `453.partyQuestSync`.
- QuestLeftovers junk marks (roadmap 352): Alt+right-click on a bag slot (`Bags.OnModifiedClick`, Classic only: hooks `ContainerFrameItemButton_OnModifiedClick`; Mail uses the same hook, skipped while SendMailFrame is shown) toggles `character.junkMarks[itemID]`; marked items count in `InBags` and `Merchant` `isJunk`. Delete button on `MerchantFrame` (`Widgets.ConfirmPopup`) deletes only leftovers without sell value (`Deletable`, `Bags.Pickup` + `DeleteCursorItem`).

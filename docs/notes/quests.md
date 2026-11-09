# Notizen: Quests (Log, Tracking, Tasten, Sperrliste)

Wortgetreu aus CLAUDE.md ausgelagert. Vor dem Aendern eines Moduls hier nach dem Dateinamen suchen und nur den passenden Abschnitt lesen.

### Quest-Sperrliste (aus Data sources)

- `Assist/QuestBlocklist.lua`: NPC/quest blocklist for QuestAutomation (`IsBlockedNpc`, `IsBlockedQuest`, `Blocks`, `NpcId(guid)`), user list in setting `questExclude`; repeatable dialogs stay manual via `C_QuestLog.IsRepeatableQuest` (Retail/Forever). Further Assist modules: `BreathWarning` (MIRROR_TIMER_*, `warnBreath`/`breathWarnSeconds`), `BreakReminder` (`remindBreak`/`breakMinutes`, baseline in `currentSession.breakBaseline`), `QuestProgress` (`announceQuestProgress` via GroupChat, dropped during lockdown), `InviteInfo` (`inviteInfo`, chat line only).

### Quest support (roadmap 340-352)

- `Tracking/QuestWatch.lua`: single quest log scan; features subscribe via `QuestWatch.Subscribe({ enabled, onObjective, onComplete, onReady, onAccepted })` instead of reading the log themselves (QuestProgress uses it).
- `QuestMobs` (`ForMob`, `IsQuestMob`, `ForItem`, `ItemsOf`, `QuestsOfItem`, `OpenMobNames`, `ProgressOf`; `MIN_HITS` = 2) in `LevelTimerStatsDB.questMobs`; `QuestNpcs` in `LevelTimerStatsDB.questNpcs`; per character `questLeftovers`, `questSpecialItems`.
- Helpers: `Lib/QuestLog.lua` (`Objectives`, `NormalizeObjective`, `QuestCount`, `MaxQuests`, `entry.header`), `Lib/QuestTooltip.lua` (cached per name), `Lib/QuestRewards.lua` (also QuestAutomation), `Lib/MapPins.lua` (`Create({ name, label, points, revision, onEnter })`, DeathMap uses it), `Alerts.Raise(kind, value, body)`, `Loot.OnSelfLoot`, `Items.GetName`. `QuestItem.TargetNames()` (plural). Raid marker only via secure macro `/tm`, never `SetRaidTarget`.
- Comfort sub page "Quests" holds quest display/marks/learning/log options; alerts `alertQuestComplete/Objective`, `alertRareSpotted/Flash`; History group "Quests" (Turn-in, Efficiency).
- Gotchas: gopher-lua `tonumber(s:match(...))` without match errors, write `tonumber((s:match(...)))`; new textures/fontstrings are shown by default (hide overlays right away); tests using `ns.NamePlates.Active()` must fire `NAME_PLATE_UNIT_ADDED`.
- Instance difficulty: a same-name difficulty change while inside is the same visit (`difficultySettled`); difficulty 0 counts as unsettled (`unsettledSibling` matches a visit of the same name with difficulty 0 on either side). Forever reports 0 right after entering.

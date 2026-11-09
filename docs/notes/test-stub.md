# Notizen: Test-Stub-Zeilen (aus den Modulabschnitten)

Wortgetreu aus CLAUDE.md ausgelagert. Vor dem Aendern eines Moduls hier nach dem Dateinamen suchen und nur den passenden Abschnitt lesen.

### Stub: v2.20 modules

- Stub: `SetAttribute` errors under `state.combatLockdown`; `state.actions`, `state.controlDown`, `state.questWatches`, `questLog[i].level/suggestedGroup/specialItem`, `state.itemCounts`.

### Stub: v2.21 modules

- Stub: `COMBATLOG_XPGAIN_EXHAUSTION1`, `ERR_ZONE_EXPLORED_XP`, `GetQuestLogRewardXP` (`questLog[i].rewardXp`), `GetQuestLogTitle` 6th value `isComplete`. Layout test checks General > Window toggle pairs per row: add new window toggles at the end.
- Stub: `UnitLevel(unit)` reads `units[unit].level`, frames `CreateLine`, `FACTION_STANDING_INCREASED*`. Gotcha: gopher-lua `select(n, ...)` in a closure forwarding event varargs crashed ("nil pointer dereference"); register the handler directly.

### Stub: v2.22 modules

- Stub: `GetNumGroupMembers`, `IsInRaid`, `NotifyInspect`, `GetUnitName`, `Screenshot` (`wow.screenshots`), `C_ChatInfo.RegisterAddonMessagePrefix/SendAddonMessage` (`wow.addonMessages`, `wow.addonPrefixes`).

### Stub: Loot sparkles (roadmap 330)

- Stub: `CreateAnimationGroup` (`frame._animationGroups`, `IsPlaying`, `GetScript`), texture `SetTexture/GetTexture/_atlas`. Per-client CVar lists: Ketho/BlizzardInterfaceResources `<branch>/Resources/CVars.lua`.

### Stub: Loot rolls (roadmap 364)

- Stub: `state.lootRolls`, `activeLootRolls`, `lootHistory` (Era), `lootDrops`/`encounterDrops` (Retail/Forever), hidden `GroupLootFrame1..4`, frame `IsVisible`. Gotcha: many `LOOT_ROLL_*` strings start with `|HlootHistory:%d|h[Loot]|h: `; Forever reorders no-spam winner strings (roles by argument position).

### Stub: Flight times (roadmap 370)

- Stub: `state.taxiNodes[i] = { name, type, x, y, id, hops }`, `state.taxiMapID`, taxi APIs.

### Stub: Leatrix rest (roadmap 329 done)

- Stub: `state.clubs` (C_Club fake), chat frames `GetID`/clamp insets `_clamp`/`GetChatWindowInfo`/`FCF_SetChatWindowFontSize` via `wow.chatWindowSizes`, `QuestFont*` objects, scenarios `era_classic_frame*` get a Classic PlayerFrame. Gotcha: in Bash heredocs feeding Python, `\` arrives as `\`; check Lua backslash strings afterwards.

## Aus der alten CLAUDE.md (Token-Refactor, wortgetreu)

### Tests (stub gotchas)

- Scenarios named `era_*` load as Classic Era (11509), `forever_*` as Forever (16001), others Retail; `streamgoal_*` also loads the Goals addon (global `streamGoal`). Other prefixes (`native_xpcall*`, `no_unit_events*`, `legacy_options*`) and per-module stub additions: `docs/notes/test-stub.md`.
- gopher-lua: `select(n, ...)` in a closure forwarding event varargs crashed (register the handler directly); `tonumber(s:match(...))` without match errors (write `tonumber((s:match(...)))`); nested `gmatch` inside a `for ... in gmatch` crashes (split with `find`); after a pcall error, number locals of the main chunk captured by closures stop updating (keep counters in tables); Bash heredocs starting with `cat >` without input hang (write scripts to files).
- `wow.click(text, last)` matches the first button with that text and ignores visibility ("Standard", "Rückgängig", "Fertig", "Grün" collide): use `wow.clickOption(labelKey)` (clicks uniquely via `<KEY>_TIP`) or `last = true`; open the options (and `OptionsWindow.ShowPage(...)`) before clicking controls on hidden sub pages. Tests needing every control: `addon.Set("optionsAdvanced", true)`. New textures/fontstrings are shown by default in the stub.
- `C_Timer.After` callbacks only run on `wow.runTimers()`; `wow.update(seconds)` drives OnUpdate and `ns.Every`; assigning `wow.state.buffs` fires UNIT_AURA; tests using `ns.NamePlates.Active()` must fire `NAME_PLATE_UNIT_ADDED`; `wow.login({ level = 10 })` keeps the previous name (pass `name =`).

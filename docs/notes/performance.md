# Notizen: Performance- und Big-O-Regeln im Detail

Wortgetreu aus CLAUDE.md ausgelagert. Vor dem Aendern eines Moduls hier nach dem Dateinamen suchen und nur den passenden Abschnitt lesen.

### Performance rules (roadmap 331-336)

- `/lt debug perf [on|off|report [n]|reset]` (`Core/Profiler.lua`, `ns.SetProfiler`): total/calls/max ms per handler, task, listener, window OnUpdate plus GC growth; zero cost when off. Window OnUpdates via `ns.SetUpdateScript(frame, label, fn)`, own high-frequency event frames via `ns.SetEventScript(frame, label, fn)`; never `SetScript` directly for these. Registration functions call `ns.RememberSource(fn, skipFile)`.
- `ns.SafeCall` doesn't allocate (native xpcall args in the client, slot trampoline in the stub). Don't cache `ns.SafeCall` in a local (profiler swaps it).
- UNIT_* events where only the player/few units matter: `ns.RegisterUnitEvent(event, "player" | {u1, u2}, fn)`, never `RegisterEvent` + `if unit ~= "player"`. `ns.UnregisterEvent(event, fn)`. `ns.NewEventGroup()` (`Add`, `SetActive`, `IsActive`) for handlers only registered while a setting or the debug log is on (toggle in `RegisterApply` or `DebugLog.OnStateChanged`); don't register where a feature can't work.
- Very frequent events (CLEU) get their own frame, cheapest early-out first.
- Player buffs only through `Lib/Auras.lua` (`Snapshot`, `FindByName`, `FindBySpellId`, `ForEachBuff`, `Has`); never scan `C_UnitAuras.GetAuraDataByIndex` yourself. In tests assigning `wow.state.buffs` fires UNIT_AURA.
- `ns.Every(seconds, fn, enabled)`: predicate when the task would return immediately while its feature is off; evaluated after Apply and on `ns.RefreshTasks()`; reset state belongs in Apply.
- Debug-only preparation behind `ns.DebugActive()`. Text set several times per second: `Widgets.SetTextIfChanged(fs, text)` (only on FontStrings set exclusively through it). Nameplates: `ns.NamePlates.Active()`, `UNITS`, `TARGET_OF` instead of looping 40 slots or concatenating unit strings.
- Tests: gopher-lua gotcha: after a pcall error, number locals in the test's main chunk captured by closures stop updating; keep counters in tables. Stub: `RegisterUnitEvent` filtering, `debugprofilestop` (`wow.profileMs`), `debugstack`, `frameMethods[key] = false` = method missing, scenario prefixes `native_xpcall*`, `no_unit_events*`.

### Big-O rules (roadmap 337-339, 353-355)

- `ns.Set` skips unchanged non-table values; force an apply with `ns.ApplySettings()`. Sliders use `ns.SetDeferred` (value now, one apply next frame). Options refresh via `builder.RefreshIfShown` (catch-up in OnShow); in tests open the options before clicking controls (stub `Show()` fires OnShow). Texts measured by `fitWidth` must be set via `setMeasuredText`.
- `Journal.Revision(log)` / `RevisionOf(log)` / `EditRevision(log)`; in-place edits of entries must bump the edit revision. `Journal.GetEntries` lists grow in place: memoize on list plus `#list`, never identity alone. Archive decode stays cached across history open/close. `Journal.INBOX_SLACK`, `Journal.DropOldest` (batched trim).
- `TableView` `appendOnly` / `edits()` epoch / column `volatile`; footer gets `(columns, records, count)` (records nil in appendOnly). `Lib/TableOrder.lua`: `FilterAndSort` (full) and `NewAppendOnly` (cached keys and search text, binary-search insert, narrowing filter).
- `Runs.GetAll` cached (don't mutate runs except display fields; `Runs.Invalidate()` after changing level data outside normal events); `Runs.Get` id index. `History.GetCharacterKeys` cached (don't mutate). `Experience.RecentBaseXp(log, n)` ring of 50. StreamGoal `Goals.Active()` returns a cached list.

### Perf round 2 (roadmap 390-401) and sleeping bag (394)

- `Auras.Version()`: compare after `Auras.Snapshot()` to skip work when buffs didn't change. BuffReminder entries may set `auraOnly` (result cached per version) and `texture` (file ID, wins over `icon`); `Alerts.Notify` entries accept `texture`. `remindSleepingBag` (Forever: item 211527, buff 429959 "Gut erholt").
- `TimerDisplay.ShownKind()` ("override" in preview/edit mode). `QuestMobs.OpenMobNames()` cached (don't mutate; new identity = changed). `QuestLog.NormalizeObjective` memoized. QuestItem: tests fire QUEST_LOG_UPDATE / BAG_UPDATE_DELAYED after changing `questLog`/`itemCounts`; distance re-pick needs `wow.advance(3)`.
- OptionsBuilder refreshers belong to their page; `addRefresher(fn, nil)` for always-visible widgets; hidden pages catch up on show. `CVars.IsWriting()` during our own SetCVar (CVars captures SetCVar at load; wrapping later in tests has no effect). MapPins `revision()` may return two values; hooks `OnMapChanged`/`OnSizeChanged`. `TimerWindow.MarkDirty()`; tests `wow.advance(1)` or fire a value event before expecting a new read. `Card.Set` keeps the same icon; `card.frame.icon`. Stub `C_Item.GetItemIconByID`.

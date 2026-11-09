# Notizen: Speedrun, Splits, Rekorde, Runs

Wortgetreu aus CLAUDE.md ausgelagert. Vor dem Aendern eines Moduls hier nach dem Dateinamen suchen und nur den passenden Abschnitt lesen.

### Split-Liste (aus Module wiring)

- `SplitList.lua` (`/lt splits`): separate panel `LevelTimerSplits` with the running and last `splitListRows` levels and their split deltas, then `SplitList.BuildFooterLines()` (total, /played, record brackets filtered by `WorldRecords.IsBracketShown`, records date/age), each switchable on the Speedrun tab; own scale `splitListScale` (falls back to `scale`), background (`TimerWindow.ApplyBackground`) and lock follow the main window, position in `splitListPos`. Colored deltas via `Format.SplitDelta`.

### Speedrun-Ansichten (aus Historie)

- `SpeedrunViews.lua`: group "Speedrun" with the Runs view (`Runs.GetAll`, favorites first; left click = `Splits.SetReferenceRun`, right click = favorite) and the Records view (fastest time per level over own characters, own time and delta), built with `TableView.Create` (`onRowClick(record, button)`, `hint`).

### Serializer (aus Conventions)

- `Serializer.lua`: `Serializer.Encode(kind, value)` / `Decode(kind, text)` for tables, strings, numbers, booleans as `LT1:<kind>:...` (percent-encoded strings, no `|` or line breaks, parsed without `loadstring`; invalid text = nil). Used for shared runs (`Runs.Export/ExportAll/Import`, imported runs in `LevelTimerStatsDB.importedRuns`, validated before anything is stored).

### v2.22 modules

- Commands: `split [name]/undo/template`, `runs verify/lss`. `Bindings.xml` (repo root) installed via `autoloadNames` (`tools/installer/addon.go`); labels set in `RegisterApply` (`BINDING_HEADER_LEVELTIMER`, `BINDING_NAME_LEVELTIMER_CUSTOM_SPLIT` -> `LevelTimer_CustomSplit()`).
- Split deltas: `Format.SplitDelta(seconds, style)` (`SPLIT_GOLD`, `SPLIT_EVEN`); `Splits.GetBestTime/IsGoldSplit/IsWithinTolerance/LevelDeltaText/CurrentDeltaText`; Splits cache per kind (`cached(name, build)`). Split list rows have a 4th `friend` cell; footer extras `SplitList.AddForecastLines`, `AddCustomSplitLines`, `SsfRules.BuildLines()`.
- `Speedrun/BracketForecast.lua` (`Get`, `PersonalBest`, `SumOfBest`), `SsfRules.lua` (`Session.LoggedInAfterLogout()`), `RunCategory.lua` (only downgrades ssf -> solo -> group -> boosted; `RunCategory.OnOutsideHelp(listener(event))`), `CustomSplits.lua`, `QuestSplits.lua` (questLog fields `duration`/`delta` via `Journal.OnAdd`).
- `Lib/Fnv.lua` (FNV-1a 32, `Hash`, `Hex`), `Speedrun/RunCheck.lua` (`Step`, `Compute(times, from, to)`, `Verify(run)`, `StatusText`; extended in `OnLevelCompleted`, backfilled at login); `LT1:` run export carries `check`, `checkFrom`, `checkTo`, `coverage`, `category`.
- `Speedrun/LiveSplitExport.lua` (`TimeSpan`, `Build(key)`, `Show`), `FriendRace.lua` (prefix "LevelTimer", messages Q/I/T/L, own 1 msg/s queue, held during `GroupChat.Locked()`), `MilestoneScreenshots.lua`.

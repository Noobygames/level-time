# Notizen: Debug-Log, Befehle, Checks

Wortgetreu aus CLAUDE.md ausgelagert. Vor dem Aendern eines Moduls hier nach dem Dateinamen suchen und nur den passenden Abschnitt lesen.

### Befehle und Debug-Log (aus Build / test / run)

- In-game commands: `/lt` or `/leveltimer` (no args opens settings) with `config | history | lock | unlock | reset | compact | bar | newsession | recap | copy | splits | stream | goal <level> | compare best/pb/<name> | runs import/backup | profile [name/save/delete/export/import] | sync | show | hide | minimap | debug` (`debug` toggles extended logging until /reload: every XP chat message and its classification plus `ns.Debug(area, fmt, ...)` lines from stats, journal, session, played time, deaths, announcements, reminders, splits and alerts; `debug state | levelup | alert <kind> | remind | death | splits | help` are test commands in `DebugTools.lua` that never change saved statistics).
- Persistent debug log (`Core/DebugLog.lua`: storage, JSON, commands; SavedVariable `LevelTimerDebugLog`, account): `/lt debug log` (stays on across /reload; `clear`, `status`) records every `ns.Debug` line and errors caught by `ns.SafeCall` (with stack). What else is collected lives in `Core/DebugProbes.lua`, also for roadmap features not built yet (comments name the item numbers): `EVENT_PROBES` (args, optional `state` = player state, optional `extra(...)` data), a `TakeTaxiNode` hook, a snapshot every 60 s with spell cast counts, API/global-string probes via `DebugLog.OnHeader`, and checks via `DebugLog.AddCheck(name, run)` that `/lt debug check` runs once (even with the log off). Each entry is one JSON line (`DebugLog.Encode`, secrets as `<secret>`, max `MAX_LINES` = 25000, about one evening). Written to disk on /reload or logout; `make debuglog` (installer `-debuglog`, read-only, `ARGS="-flavors forever -tail 200"`) prints the lines as JSON Lines (headers on stderr). New open in-game question = add a `CHECKS` entry or an event probe instead of asking for `/dump`.

### Debug checks instead of manual checks

- `Core/DebugChecks.lua` (loads after all modules, before `DebugTools.lua`) holds checks and event probes for open ManualToCheck items; names `<roadmap>.<area>.<what>`; ManualToCheck.md section "Per Debug-Log abgedeckt" maps items to names. Helpers from `DebugProbes.lua` exported as `DebugLog.Probe` (`api`, `call`, `safe`, `listOf`, `playerState`, `unitInfo`). Results with more than `DebugLog.MAX_TABLE_ITEMS` entries must be chunked (`chunked`).
- `ns.Print` lines also go to the persistent log (area `print`); replies of `/lt debug log|check` excluded (`feedback`). `ns.IsDebugging` = `ns.DebugActive`.
- New in-game question answerable by data = check/probe/`ns.Debug` line + entry in "Per Debug-Log abgedeckt". Taint shows up as `ADDON_ACTION_BLOCKED`/`ADDON_ACTION_FORBIDDEN` probe entries.
- Scenarios `debug_checks`, `era_debug_checks`, `forever_debug_checks`: add new check names to their `CHECKS` lists.

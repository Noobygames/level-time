# Notizen: Historie, Auswertung, Export

Wortgetreu aus CLAUDE.md ausgelagert. Vor dem Aendern eines Moduls hier nach dem Dateinamen suchen und nur den passenden Abschnitt lesen.

### Historie und Auswertung

- `HistoryWindow.lua` is only the frame (character selector, tab row, sub-tab row, content area of `CONTENT_WIDTH` x `CONTENT_HEIGHT`). Views register via `HistoryWindow.AddView({ tab, group, Create(parent, width, height) -> frame })`; the frame needs `Render(characterKey, selectionChanged)`. Views with the same `group` share one tab and appear as sub-tabs (groups: Levels, Journal, Charts); order = registration order (`.toc`).
- `Lib/TableView.lua` (`TableView.Create(definition)`, the generic table) and `UI/HistoryTables.lua` (only columns and footers, `ClassColor`, `CountCells`): table views with filter box (`frame:SetFilter`), header sorting (`frame:SortBy`, column `sort(record)` key for formatted cells) and `GetVisibleRecords()` (Levels, Timeline, Sessions, Kills, Deaths, Compare; `rowColor` optional, Compare uses class colors) from `TableView.Create({ tab, columns, records(key), footer(columns, records) })`. Lazy load: only `visibleRows` row widgets exist; mouse wheel / `Widgets.CreateScrollBar` change `frame.offset` and the rows are refilled. Text columns set `align = "LEFT"`. `selectionChanged` resets the scroll offset.
- `HistoryCharts.lua`: one view per chart in group "Charts" (`createChartView(tab, kind, data, axis)`: `kind` column or rank, `data` from `Analysis`, `axis` formatter). `Analysis.lua` turns history/journal into `items = { { label, value, text, highlight } }`; `Charts.lua` draws column charts (tooltip on hover, every n-th axis label) and rank charts from plain textures, no library.
- Level record `{ level, seconds, xp, counters, completedAt }`, written in `OnLevelCompleted`. Session record `{ startedAt, endedAt, seconds, startLevel, endLevel, xp, counters }` (`Session.ToRecord`).
- `History.GetLevelRecords(key)` / `GetSessionRecords(key)`: newest first, the running entry first with `isCurrent`. For the logged-in character the running entries are live values; for others the state saved at their last logout (`Stats` saves `currentLevel.seconds/xp` on logout).
- Character names in the UI always go through `History.DisplayName(key)`: setting `streamerPrivacy` hides the realm and shows other characters as "Character N" (CSV export included).
- `History.Summarize(records)` sums seconds, XP and all counters (footer "Total" row). `HistoryWindow` has a character selector (arrows over `History.GetCharacterKeys()`, logged-in first), tabs Levels/Sessions, and one column list per view (`LEVEL_COLUMNS`, `SESSION_COLUMNS`); a column's `value(record)` must also handle summary records (no level/date).

### Export (aus Conventions)

- `Export.lua`: `Export.ToCsv(headers, rows, separator)` and a copy window (`Export.Show`; `Export.ShowImport(heading, onImport(text) -> message, ok)` reuses it for pasting); tables build CSV from their visible rows (`frame:BuildCsv`, separator `L.CSV_SEPARATOR`). Addons cannot write files, so copying via Ctrl+C is the only way out.

### Loot value column (roadmap 463)

- `lootLog` entries carry `value` (vendor price per piece, copper) from `Items.GetSellPrice` at loot time (nil if the client does not know the item yet); the Loot table column "Wert" shows `value * quantity`, falling back to a live lookup for old entries, "-" if unknown. No item/faction master data is shipped: `ItemSparse` is 19k-176k rows per flavor (>1 MB Lua for retail even with id+price only); faction names are already stored by name in `reputationGains`.

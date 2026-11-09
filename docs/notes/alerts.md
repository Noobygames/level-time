# Notizen: Einblendungen und Karten

Wortgetreu aus CLAUDE.md ausgelagert. Vor dem Aendern eines Moduls hier nach dem Dateinamen suchen und nur den passenden Abschnitt lesen.

### Einblendungen (aus Module wiring)

- Notices: `Alerts.Notify({ text, title, icon }, color)` shows a card (`Lib/Card.lua`: accent bar, icon (spell ID or path from `Alerts.ICONS`), title, body, optional big time + bar) in frame `LevelTimerNotice` at the banner's position; cards and banners share queue, duration, scale and position. `CampDisplay` uses the same card. Tests read `LevelTimerNotice.title/.body`.
- `Alerts.lua` look and position (Options tab "Alerts"): `alertStyle` banner/text (dark background + color bars from plain textures), `alertScale`, `alertDuration`, `alertSound`, `alertPos` (optional setting, `isPosition`); `Alerts.SetMoving(true)` = move mode (sample stays, drag saves, right-click ends), `Alerts.Preview()`, `Alerts.ResetPosition()`. Also shows `Alerts.Notify` warnings. It skips elite alerts in party/raid instances and epic loot alerts in raids (`IsInInstance`). `StreamMode.PRESET` no longer touches scale, bgAlpha or windowBackground.
